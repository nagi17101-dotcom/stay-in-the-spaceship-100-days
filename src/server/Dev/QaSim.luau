-- QaSim (Studio only): accelerated full-voyage QA run on the REAL server loop.
-- Compresses day phases, plays a "competent crew" autopilot (resolves incident steps through the same
-- notifyRepair / ApplyRepair / inventory paths real tasks use), salvages each Prepare, drives the Day-100
-- finale + vote into Endless, and records per-day metrics, errors and reward-grant idempotency.
-- Profile grants are intercepted while it runs (no writes to real profiles).
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local Config = require(ReplicatedStorage.Shared.Config.GameConfig)
local Registry = require(ServerScriptService.Server.Minigames.Registry)
local ProfileService = require(ServerScriptService.Server.Progression.ProfileService)
local Director = require(ServerScriptService.Server.CrisisDirector.Director)

local QaSim = {}
local state = nil

local REACT = 2 -- seconds before the crew starts on a new incident step
local REPAIR_BELOW = 55 -- crew maintenance threshold
local MAINT_COOLDOWN = 4

local function repairMinigameFor(system)
	for id, mg in pairs(Registry) do
		if mg.System == system and mg.RepairAmount > 0 then return id, mg.RepairAmount end
		if mg.AlsoRepairs and mg.AlsoRepairs[system] then return id, mg.AlsoRepairs[system] end
	end
	return nil
end

function QaSim.Status(): string
	if not state then return "idle" end
	local s = state
	local lines = { ("running=%s day=%d phase=%s seed=%d elapsed=%.0fs | incidents spawned=%d resolvedSteps=%d unaffordable=%d emergencies=%d maint=%d errors=%d grants=%d dupGrants=%d"):format(
		tostring(s.running), s.run.day.day, s.run.day.phase, s.seed, os.clock() - s.t0, s.spawned, s.steps, s.unaffordable, s.emergencies, s.maint, #s.errors, s.grants, s.dupGrants) }
	if s.result then table.insert(lines, "RESULT: " .. s.result) end
	return table.concat(lines, "\n")
end

function QaSim.Report(): string
	if not state then return "idle" end
	local out = { QaSim.Status() }
	for _, d in ipairs(state.days) do table.insert(out, d) end
	local ids = {}
	for id, n in pairs(state.byTemplate) do table.insert(ids, id .. "=" .. n) end
	table.sort(ids)
	table.insert(out, "templates: " .. table.concat(ids, " "))
	for i = 1, math.min(8, #state.errors) do table.insert(out, "ERR " .. state.errors[i]) end
	return table.concat(out, "\n")
end

function QaSim.Start(run, opts): string
	if not RunService:IsStudio() then return "studio only" end
	if state and state.running then return "already running" end
	opts = opts or {}
	if run.day.phase == "Lobby" or run.day:IsTerminal() then return "launch a voyage first" end

	local s = {
		run = run, running = true, t0 = os.clock(), seed = opts.seed or 1337, untilDay = opts.untilDay or 103,
		spawned = 0, steps = 0, unaffordable = 0, emergencies = 0, maint = 0, errors = {}, grants = 0, dupGrants = 0,
		seenInc = {}, stepStart = {}, lastMaint = {}, days = {}, byTemplate = {}, tx = 0, grantIds = {},
		minH = {}, conns = {},
	}
	state = s
	run.rng = Random.new(s.seed)

	-- compress the day (restored on stop)
	s.savedDay = table.clone(Config.Day)
	Config.Day.PrepareSeconds = opts.prepare or 0.5
	Config.Day.ActiveSeconds = opts.active or 22
	Config.Day.TransitionSeconds = opts.transition or 0.5
	s.savedTiming = table.clone(Director.Timing)
	Director.Timing.quietStart, Director.Timing.quietEnd, Director.Timing.checkEvery, Director.Timing.recovery = 3, 3, 4, 8
	s.savedVote = Config.Finale.VoteSeconds
	Config.Finale.VoteSeconds = 3

	-- intercept profile grants (count + idempotency check), never touch real profiles
	s.realGrant = ProfileService.Grant
	ProfileService.Grant = function(_player, grantId, _reward)
		s.grants += 1
		if s.grantIds[grantId] then s.dupGrants += 1 end
		s.grantIds[grantId] = true
		return true
	end

	table.insert(s.conns, LogService.MessageOut:Connect(function(msg, kind)
		if kind == Enum.MessageType.MessageError then table.insert(s.errors, string.sub(msg, 1, 200)) end
	end))

	local function nextTx() s.tx += 1 return ("qa:%d:%d"):format(s.seed, s.tx) end
	local function resetMin() for name, sys in pairs(run.ship.systems) do s.minH[name] = sys.health end end
	resetMin()

	local function salvageAll()
		for _, point in ipairs(CollectionService:GetTagged("SalvagePoint")) do
			local cfg = Config.SalvageLoot[point:GetAttribute("SalvageType")]
			if cfg then
				for _ = 1, cfg.charges do
					local loot = {}
					for _, entry in ipairs(cfg.loot) do
						local n = run.rng:NextInteger(entry.min, entry.max)
						if n > 0 then loot[entry.id] = (loot[entry.id] or 0) + n end
					end
					run.inventory:Credit(loot, nextTx())
				end
			end
		end
	end

	-- resolve one incident step the way a crew would: free task paths first, then material paths
	local function tryPath(p)
		if p.kind == "task" then
			local mg = Registry[p.id]
			if not mg then return false end
			if mg.Commit then -- material-consuming task (fabricator): needs an affordable blueprint
				local ok = mg.CanOpen == nil or (mg.CanOpen(run))
				if not ok then return false end
				local pub = mg.Generate("Basic", run.rng:NextInteger(1, 1e9), mg.Context and mg.Context(run))
				local tx = nextTx()
				if not run.inventory:TryDebit(pub.blueprint.cost, tx) then return false end
				run.ship:ApplyRepair(pub.blueprint.system, pub.blueprint.amount, tx)
			elseif mg.RepairAmount > 0 then
				run.ship:ApplyRepair(mg.System, mg.RepairAmount, nextTx())
			end
			run.notifyRepair(mg.System, "task:" .. p.id)
			return true
		else
			local qa = Config.QuickActions[p.id]
			if not qa then return false end
			local tx = nextTx()
			if not run.inventory:TryDebit(qa.cost, tx) then return false end
			run.ship:ApplyDelta(qa.system, qa.field, qa.amount, tx)
			run.notifyRepair(qa.system, "action:" .. p.id)
			return true
		end
	end

	local function autopilot()
		local now = workspace:GetServerTimeNow()
		local dir = run.director
		for _, inc in ipairs(dir.active) do
			if not s.seenInc[inc.id] then
				s.seenInc[inc.id] = true
				s.spawned += 1
				s.byTemplate[inc.template.id] = (s.byTemplate[inc.template.id] or 0) + 1
			end
		end
		for _, inc in ipairs(table.clone(dir.active)) do
			local key = inc.id .. ":" .. inc.step
			s.stepStart[key] = s.stepStart[key] or now
			if now - s.stepStart[key] >= REACT then
				local step = inc.template.steps[inc.step]
				local done = false
				local ordered = {}
				for _, p in ipairs(step.paths) do if p.kind == "task" and not (Registry[p.id] and Registry[p.id].Commit) then table.insert(ordered, p) end end
				for _, p in ipairs(step.paths) do if not table.find(ordered, p) then table.insert(ordered, p) end end
				for _, p in ipairs(ordered) do
					if tryPath(p) then done = true break end
				end
				if done then s.steps += 1 elseif not s.stepStart[key .. ":blocked"] then
					s.stepStart[key .. ":blocked"] = true
					s.unaffordable += 1
				end
			end
		end
		-- emergencies: use the reserve actions like a crew would
		if run.emergency then
			if not s.inEmergency then s.inEmergency = true s.emergencies += 1 end
			local id = run.emergency.reason == "OxygenDepleted" and "EmergencyO2" or "HullPatch"
			tryPath({ kind = "action", id = id })
			local sys = run.emergency and (run.emergency.reason == "OxygenDepleted" and "Power" or "Hull")
			if sys then run.ship:ApplyRepair(sys, 25, nextTx()) end
		else
			s.inEmergency = false
		end
		-- routine maintenance at stations
		for name, sys in pairs(run.ship.systems) do
			s.minH[name] = math.min(s.minH[name] or 100, sys.health)
			if sys.health < REPAIR_BELOW and (now - (s.lastMaint[name] or 0)) >= MAINT_COOLDOWN then
				local id, amount = repairMinigameFor(name)
				if id then
					s.lastMaint[name] = now
					s.maint += 1
					run.ship:ApplyRepair(name, amount, nextTx())
					run.notifyRepair(name, "task:" .. id)
				end
			end
		end
	end

	local function stop(result)
		if not s.running then return end
		s.running = false
		s.result = result
		for _, c in ipairs(s.conns) do c:Disconnect() end
		for k, v in pairs(s.savedDay) do Config.Day[k] = v end
		Config.Finale.VoteSeconds = s.savedVote
		for k, v in pairs(s.savedTiming) do Director.Timing[k] = v end
		ProfileService.Grant = s.realGrant
		print("[QaSim] " .. result)
	end
	s.stop = stop

	table.insert(s.conns, run.day.PhaseChanged.Event:Connect(function(info)
		if info.phase == "Prepare" then
			salvageAll()
			resetMin()
		elseif info.phase == "Transition" then
			local inv = run.inventory:Snapshot()
			local worst, worstV = "-", 101
			for name, v in pairs(s.minH) do if v < worstV then worst, worstV = name, v end end
			table.insert(s.days, ("D%03d %-18s inc=%d active=%d min=%s %.0f | inv S%d F%d Fi%d Co%d Se%d"):format(info.day, info.sector or "?", s.spawned, #run.director.active, worst, worstV,
				inv.ScrapAlloy, inv.FilterMembrane, inv.ConductiveFilament, inv.CoolantCartridge, inv.SealantFoam))
			if info.day >= s.untilDay then stop(("reached day %d"):format(info.day)) end
		elseif info.phase == "Failed" then
			stop(("FAILED day %d reason %s"):format(info.day, tostring(run.lossReason)))
		elseif info.phase == "Complete" then
			stop("run completed (extracted)")
		elseif info.phase == "Lobby" then
			stop("returned to lobby")
		end
	end))

	task.spawn(function()
		while s.running do
			local ok, err = pcall(function()
				local phase = run.day.phase
				if phase == "Active" or phase == "Prepare" or phase == "Transition" then
					autopilot()
				elseif phase == "Finale" then
					autopilot()
					local cur = run.finale.active and run.finale:_current()
					if cur and cur.kind == "task" then
						run.notifyRepair(Registry[cur.id].System, "task:" .. cur.id)
					elseif cur and cur.kind == "craft" then
						if run.inventory:TryDebit(Config.Finale.TransmitterCost, "finale:craft:" .. run.runId) then
							run.finale:DevAdvance()
						elseif not s.craftBlocked then
							s.craftBlocked = true
							table.insert(s.errors, "finale craft unaffordable")
						end
					end -- hold: FinaleService:Tick counts it down while condition >= HoldMinCondition
				elseif phase == "Vote" and run.finale.voteOpen then
					for userId in pairs(run.crew) do run.finale.votes[userId] = "Continue" end
					run.finale:_resolveVote("qasim")
				end
			end)
			if not ok then table.insert(s.errors, "autopilot: " .. tostring(err)) end
			task.wait(0.5)
		end
	end)

	-- jump straight to the requested start day (keeps Day 1 rewards path honest when startDay = 1)
	if opts.startDay and opts.startDay > run.day.day then run.day.day = opts.startDay end
	return ("started seed=%d untilDay=%d active=%ss"):format(s.seed, s.untilDay, tostring(Config.Day.ActiveSeconds))
end

function QaSim.Stop(): string
	if state and state.running then state.stop("stopped by dev") end
	return QaSim.Status()
end

return QaSim
