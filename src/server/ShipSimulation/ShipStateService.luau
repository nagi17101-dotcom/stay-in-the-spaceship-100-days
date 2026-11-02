-- ShipStateService: authoritative ship systems, dependency chain, hysteresis modes, deltas.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.GameConfig)

local ShipStateService = {}
ShipStateService.__index = ShipStateService

local clamp = math.clamp
local DEP = Config.Dependencies
local POWERED = { "Drive", "Navigation", "Comms", "Shields", "Cargo", "Cooling" }

function ShipStateService.new(difficulty: string, seed: number)
	local self = setmetatable({}, ShipStateService)
	self.difficulty = difficulty
	self.tuning = Config.Difficulty[difficulty] or Config.Difficulty[Config.DefaultDifficulty]
	self.rng = Random.new(seed)
	self.revision = 0
	self.crewCount = 1
	self.systems = {}
	for _, name in ipairs(Config.Systems) do
		self.systems[name] = {
			health = 100, output = 100, capacity = 100,
			mode = "Nominal", faults = {}, revision = 0,
			wear = Config.SystemDefaults[name].wear,
		}
	end
	self.appliedTransactions = {}
	self.lastSent = {}
	self.ModeChanged = Instance.new("BindableEvent") -- (systemName, oldMode, newMode)
	return self
end

function ShipStateService:_nextMode(sys, value)
	local t = Config.Thresholds
	local m = sys.mode
	if m == "Nominal" then
		if value < t.Critical then return "Critical" elseif value < t.Warning then return "Warning" end
	elseif m == "Warning" then
		if value < t.Critical then return "Critical" elseif value >= t.Warning + t.Hysteresis then return "Nominal" end
	elseif m == "Critical" then
		if value >= t.Warning + t.Hysteresis then return "Nominal" elseif value >= t.Critical + t.Hysteresis then return "Warning" end
	end
	return m
end

function ShipStateService:Step(dt: number, wearActive: boolean)
	local s = self.systems
	local wf = self.tuning.wearFactor

	if wearActive then
		for _, sys in pairs(s) do
			sys.health = clamp(sys.health - sys.wear * wf * dt, 0, 100)
		end
		-- Cooling deficit overheats the reactor
		local coolingDeficit = math.max(0, DEP.CoolingSafe - s.Cooling.health) / DEP.CoolingSafe
		s.Reactor.health = clamp(s.Reactor.health - coolingDeficit * DEP.ReactorHeatWear * wf * dt, 0, 100)
	end

	-- Dependency chain: Reactor -> Power -> (Life support, powered systems)
	s.Reactor.output = s.Reactor.health
	s.Power.output = math.min(s.Power.health, s.Reactor.output)
	s.Hull.output = s.Hull.health

	local powerFactor = clamp(s.Power.output / DEP.LifeSupportPowerNeed, 0, 1)
	local leak = math.max(0, DEP.HullLeakBelow - s.Hull.health) / DEP.HullLeakBelow * DEP.HullLeakRate
	local scrub = DEP.OxygenRegen * powerFactor * (s.Oxygen.health / 100)
	local use = DEP.OxygenUsePerCrew * self.crewCount
	s.Oxygen.output = clamp(s.Oxygen.output + (scrub - leak - use) * dt, 0, 100)

	for _, name in ipairs(POWERED) do
		s[name].output = math.min(s[name].health, s.Power.output)
	end
	local coolingFactor = clamp(s.Cooling.health / DEP.CoolingSafe, 0, 1)
	s.Drive.output = math.min(s.Drive.output, 100 * coolingFactor)

	for _, name in ipairs(Config.Systems) do
		local sys = s[name]
		local newMode = self:_nextMode(sys, math.min(sys.health, sys.output))
		if newMode ~= sys.mode then
			local old = sys.mode
			sys.mode = newMode
			sys.revision += 1
			self.ModeChanged:Fire(name, old, newMode)
		end
	end
	self.revision += 1
end

-- Returns a reason string if a catastrophe condition is active (grace handled by caller)
function ShipStateService:GetCatastrophe(): string?
	if self.systems.Hull.health <= 0 then return "HullBreach" end
	if self.systems.Oxygen.output <= 0 then return "OxygenDepleted" end
	return nil
end

-- Exactly-once repair entry point for future TaskService (txId must be server-generated)
function ShipStateService:ApplyRepair(systemName: string, amount: number, txId: string): boolean
	if self.appliedTransactions[txId] then return false end
	local sys = self.systems[systemName]
	if not sys or type(amount) ~= "number" or amount <= 0 then return false end
	self.appliedTransactions[txId] = true
	sys.health = clamp(sys.health + amount, 0, 100)
	sys.revision += 1
	return true
end

-- Exactly-once change to health or output (quick actions)
function ShipStateService:ApplyDelta(systemName: string, field: string, amount: number, txId: string): boolean
	if self.appliedTransactions[txId] then return false end
	local sys = self.systems[systemName]
	if not sys or (field ~= "health" and field ~= "output") or type(amount) ~= "number" then return false end
	self.appliedTransactions[txId] = true
	sys[field] = clamp(sys[field] + amount, 0, 100)
	sys.revision += 1
	return true
end

function ShipStateService:SetDifficulty(difficulty: string)
	self.difficulty = difficulty
	self.tuning = Config.Difficulty[difficulty] or Config.Difficulty[Config.DefaultDifficulty]
end

function ShipStateService:Reset()
	for _, name in ipairs(Config.Systems) do
		local sys = self.systems[name]
		sys.health, sys.output, sys.faults = 100, 100, {}
		sys.revision += 1
		if sys.mode ~= "Nominal" then
			local old = sys.mode
			sys.mode = "Nominal"
			self.ModeChanged:Fire(name, old, "Nominal")
		end
	end
	self.appliedTransactions, self.lastSent = {}, {}
	self.revision += 1
end

local function wire(sys)
	return { h = math.floor(sys.health + 0.5), o = math.floor(sys.output + 0.5), m = sys.mode }
end

function ShipStateService:Serialize()
	local out = {}
	for name, sys in pairs(self.systems) do out[name] = wire(sys) end
	return out
end

function ShipStateService:CollectDelta()
	local delta, any = {}, false
	for name, sys in pairs(self.systems) do
		local e = wire(sys)
		local last = self.lastSent[name]
		if not last or last.h ~= e.h or last.o ~= e.o or last.m ~= e.m then
			self.lastSent[name] = e
			delta[name] = e
			any = true
		end
	end
	return any and delta or nil
end

-- Most urgent ROOT CAUSE: rank by the system's own health (O2 by stock), so a dead
-- Power bus is reported instead of every downstream system it starves. Ties -> Config order.
function ShipStateService:GetWorstSystem(): string?
	local worst, worstVal = nil, Config.Thresholds.Warning
	for _, name in ipairs(Config.Systems) do
		local sys = self.systems[name]
		local v = name == "Oxygen" and sys.output or sys.health
		if v < worstVal then worst, worstVal = name, v end
	end
	return worst
end

return ShipStateService
