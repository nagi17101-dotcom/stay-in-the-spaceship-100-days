-- DayCycleService: server-owned phase state machine. Lobby -> Prepare -> Active -> Transition -> (next day | Finale)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.GameConfig)

local DayCycle = {}
DayCycle.__index = DayCycle

local TERMINAL = { Finale = true, Complete = true, Failed = true }

function DayCycle.new()
	local self = setmetatable({}, DayCycle)
	self.day = 0
	self.phase = "Lobby"
	self.phaseStartedAt = 0
	self.phaseEndsAt = 0
	self.PhaseChanged = Instance.new("BindableEvent") -- (phaseInfo)
	return self
end

function DayCycle:GetInfo()
	return {
		day = self.day,
		phase = self.phase,
		sector = Config.SectorFor(math.max(self.day, 1)),
		phaseStartedAt = self.phaseStartedAt,
		phaseEndsAt = self.phaseEndsAt,
	}
end

function DayCycle:_enter(phase: string, duration: number?)
	local now = workspace:GetServerTimeNow()
	self.phase = phase
	self.phaseStartedAt = now
	self.phaseEndsAt = duration and (now + duration) or 0
	self.PhaseChanged:Fire(self:GetInfo())
end

function DayCycle:IsTerminal(): boolean return TERMINAL[self.phase] == true end
function DayCycle:IsActive(): boolean return self.phase == "Active" end

function DayCycle:Begin()
	self.day = 1
	self:_enter("Prepare", Config.Day.PrepareSeconds)
end

function DayCycle:Update(now: number)
	if self.phaseEndsAt == 0 or now < self.phaseEndsAt then return end
	if self.phase == "Prepare" then
		self:_enter("Active", Config.Day.ActiveSeconds)
	elseif self.phase == "Active" then
		self:_enter("Transition", Config.Day.TransitionSeconds)
	elseif self.phase == "Transition" then
		if self.day >= Config.DayMilestone and self.day == Config.DayMilestone then
			self:_enter("Finale", nil) -- Day 100 finale gameplay: M4
		else
			self.day += 1
			self:_enter("Prepare", Config.Day.PrepareSeconds)
		end
	end
end

function DayCycle:Reset()
	self.day = 0
	self:_enter("Lobby", nil)
end

function DayCycle:SkipPhase() -- Studio dev only
	if self.phaseEndsAt > 0 then self.phaseEndsAt = workspace:GetServerTimeNow() end
end

function DayCycle:Fail()
	self:_enter("Failed", nil)
end

return DayCycle
