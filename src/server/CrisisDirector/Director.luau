-- CrisisDirector v1: budgeted, feasibility-checked incidents during the Active phase.
-- Resolution comes only from validated server events (TaskService / QuickActionService -> OnRepaired).
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)
local Templates = require(script.Parent.IncidentTemplates)
local Feasibility = require(script.Parent.Feasibility)

local Director = {}
Director.__index = Director

local QUIET_START, QUIET_END = 10, 10   -- no spawns in first/last seconds of Active
local CHECK_EVERY = 8
local RECOVERY_WINDOW = 25
local BUDGET_CAP = 4

local function alertAll(severity, text)
	Remotes.Get(Remotes.Names.Alert):FireAllClients({ severity = severity, text = text })
end

function Director.new(run)
	local self = setmetatable({ run = run }, Director)
	self:Reset()
	return self
end

function Director:Reset()
	self.active = {}
	self.cooldownUntil = {}
	self.budget, self.spent = 0, 0
	self.nextCheckAt = math.huge
	self.recoveryUntil = 0
	self.activeEndsAt = 0
	self.log = {}
end

function Director:_crew(): number
	local n = 0
	for _, p in ipairs(Players:GetPlayers()) do if self.run.crew[p.UserId] then n += 1 end end
	return n
end

function Director:ComputeBudget(): number
	local run = self.run
	local day = run.day.day
	local base = math.min(1 + day * 0.15, BUDGET_CAP)
	local crew = math.max(1, self:_crew())
	local team = math.clamp(1 + 0.15 * (crew - 2), 1, 1.6) -- small crews never get less than the base
	local sum, n = 0, 0
	for _, sys in pairs(run.ship.systems) do sum += math.min(sys.health, sys.output) n += 1 end
	local avg = sum / n
	local relief = avg < 50 and 0.5 or (avg < 70 and 0.75 or 1) -- hurt ship => fewer incidents
	return math.min(BUDGET_CAP, base * run.ship.tuning.incidentBudgetFactor * team * relief)
end

function Director:_context()
	local run = self.run
	local stations, actions = {}, {}
	for _, s in ipairs(CollectionService:GetTagged("RepairStation")) do
		local id = s:GetAttribute("MinigameId") if id then stations[id] = true end
	end
	for _, s in ipairs(CollectionService:GetTagged("QuickAction")) do
		local id = s:GetAttribute("ActionId") if id then actions[id] = true end
	end
	return {
		day = run.day.day, crew = self:_crew(), systems = run.ship.systems,
		hasMaterials = function(cost) return run.inventory:Has(cost) end,
		stations = stations, actions = actions, quickActions = Config.QuickActions,
		active = self.active, maxCritical = run.ship.tuning.maxConcurrentCritical, graceFactor = run.ship.tuning.graceFactor,
	}
end

function Director:_apply(effects, txId)
	for i, e in ipairs(effects) do
		self.run.ship:ApplyDelta(e.system, e.field, e.amount, txId .. ":" .. i)
	end
end

function Director:Spawn(t, now)
	local inc = {
		id = string.sub(HttpService:GenerateGUID(false), 1, 8),
		template = t, step = 1, escalations = 0,
		startedAt = now, nextEscalateAt = now + t.escalate.every * self.run.ship.tuning.graceFactor,
	}
	table.insert(self.active, inc)
	self:_apply(t.effects, "inc:" .. inc.id)
	alertAll(t.severity == "Critical" and "Critical" or "Warning", t.alert)
	print(("[Director] day=%d spawn %s (%s) id=%s budget=%.2f spent=%.2f"):format(self.run.day.day, t.id, t.severity, inc.id, self.budget, self.spent))
	return inc
end

function Director:ForceSpawn(templateId: string): string
	for _, t in ipairs(Templates) do
		if t.id == templateId then
			local ok, why = Feasibility.Check(t, self:_context())
			if not ok then return "rejected: " .. why end
			self:Spawn(t, workspace:GetServerTimeNow())
			return "spawned " .. t.id
		end
	end
	return "unknown template"
end

function Director:OnPhase(info)
	local now = workspace:GetServerTimeNow()
	if info.phase == "Active" then
		self.budget, self.spent = self:ComputeBudget(), 0
		self.activeEndsAt = info.phaseEndsAt
		self.nextCheckAt = now + QUIET_START
	elseif info.phase == "Lobby" or info.phase == "Failed" then
		self:Reset()
	else
		self.nextCheckAt = math.huge -- Prepare/Transition: no new incidents; active ones persist (no magic reset)
	end
end

function Director:OnEmergencyEnded()
	self.recoveryUntil = workspace:GetServerTimeNow() + RECOVERY_WINDOW
	alertAll("Info", ("RECOVERY WINDOW: no new incidents for %ds."):format(RECOVERY_WINDOW))
end

function Director:Tick(now: number)
	-- Escalations (bounded, never instant loss)
	for _, inc in ipairs(self.active) do
		local esc = inc.template.escalate
		if now >= inc.nextEscalateAt and inc.escalations < esc.max then
			inc.escalations += 1
			inc.nextEscalateAt = now + esc.every * self.run.ship.tuning.graceFactor
			self:_apply(esc.effects, ("inc:%s:esc%d"):format(inc.id, inc.escalations))
			alertAll("Warning", ("%s (%d/%d)"):format(esc.text, inc.escalations, esc.max))
		end
	end

	if now < self.nextCheckAt then return end
	self.nextCheckAt = now + CHECK_EVERY
	if now < self.recoveryUntil or now > self.activeEndsAt - QUIET_END then return end

	local ctx = self:_context()
	local candidates, total = {}, 0
	for _, t in ipairs(Templates) do
		if self.spent + t.cost <= self.budget + 1e-6 and now >= (self.cooldownUntil[t.id] or 0) then
			local ok = Feasibility.Check(t, ctx)
			if ok then table.insert(candidates, t) total += t.weight end
		end
	end
	if total == 0 then return end -- invalid/unsafe data => choose no incident
	local roll = self.run.rng:NextNumber(0, total)
	for _, t in ipairs(candidates) do
		roll -= t.weight
		if roll <= 0 then
			self.spent += t.cost
			self.cooldownUntil[t.id] = now + t.cooldown
			self:Spawn(t, now)
			return
		end
	end
end

-- source: "task:<MinigameId>" | "action:<ActionId>"
function Director:OnRepaired(system: string, source: string)
	local kind, id = string.match(source, "^(%w+):(.+)$")
	for i = #self.active, 1, -1 do
		local inc = self.active[i]
		local step = inc.template.steps[inc.step]
		local matched = false
		for _, p in ipairs(step.paths) do
			if p.kind == kind and p.id == id then matched = true break end
		end
		if matched then
			inc.step += 1
			if inc.step > #inc.template.steps then
				table.remove(self.active, i)
				alertAll("Info", "Resolved: " .. inc.template.title .. ".")
				print(("[Director] resolved %s id=%s via %s after %.0fs"):format(inc.template.id, inc.id, source, workspace:GetServerTimeNow() - inc.startedAt))
			else
				alertAll("Info", inc.template.title .. ": step " .. (inc.step - 1) .. " done.")
			end
			return
		end
	end
end

function Director:Objective(): string?
	local inc = self.active[1]
	if not inc then return nil end
	return inc.template.steps[inc.step].objective
end

function Director:Status(): string
	local parts = {}
	for _, inc in ipairs(self.active) do
		table.insert(parts, ("%s(step %d/%d, esc %d)"):format(inc.template.id, inc.step, #inc.template.steps, inc.escalations))
	end
	return ("budget=%.2f spent=%.2f active=[%s]"):format(self.budget, self.spent, table.concat(parts, ","))
end

return Director
