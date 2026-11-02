-- RunRewards: per-run, per-day stats and rewards. Crew materials credited once per day (txId).
-- Persistent XP/profile saving arrives in M3 (ProfileService); this is run-scoped.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.GameConfig)

local RunRewards = {}
RunRewards.__index = RunRewards

local function blank() return { tasks = 0, salvage = 0, actions = 0 } end

function RunRewards.new()
	local self = setmetatable({}, RunRewards)
	self:Reset()
	return self
end

function RunRewards:Reset()
	self.players = {}
	self.crewDay = blank()
	self.crewTotal = blank()
	self.closedDays = {}
end

function RunRewards:_get(userId: number)
	local p = self.players[userId]
	if not p then
		p = { xp = 0, total = blank(), day = blank() }
		self.players[userId] = p
	end
	return p
end

function RunRewards:Record(player: Player, key: string, n: number)
	local p = self:_get(player.UserId)
	p.total[key] += n
	p.day[key] += n
	self.crewDay[key] += n
	self.crewTotal[key] += n
end

function RunRewards:CloseDay(run)
	local key = run.runId .. ":" .. run.day.day
	if self.closedDays[key] then return nil end
	self.closedDays[key] = true

	local sum, count = 0, 0
	for _, sys in pairs(run.ship.systems) do
		sum += math.min(sys.health, sys.output)
		count += 1
	end
	local condition = math.floor(sum / count + 0.5)

	local crewReward = table.clone(Config.Rewards.CrewBonus)
	if condition >= Config.Rewards.HealthyThreshold then
		for id, n in pairs(Config.Rewards.HealthyBonus) do crewReward[id] = (crewReward[id] or 0) + n end
	end
	run.inventory:Credit(crewReward, "dayreward:" .. key)

	local R = Config.Rewards
	local personal = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if not (run.crew and run.crew[player.UserId]) then continue end
		local p = self:_get(player.UserId)
		local xp = R.BaseXP + R.TaskXP * p.day.tasks + R.SalvageXP * p.day.salvage + R.ActionXP * p.day.actions
		p.xp += xp
		personal[player] = { xp = xp, totalXp = p.xp, tasks = p.day.tasks, salvage = p.day.salvage, actions = p.day.actions }
		p.day = blank()
	end

	local common = {
		day = run.day.day,
		sector = Config.SectorFor(run.day.day),
		crewTasks = self.crewDay.tasks,
		crewSalvage = self.crewDay.salvage,
		condition = condition,
		crewReward = Config.FormatItems(crewReward),
	}
	self.crewDay = blank()
	return common, personal
end

return RunRewards
