-- QaSim v2 (Studio only): accelerated full-voyage QA on the REAL server loop with a TIME-FAITHFUL scale.
-- Everything time-based is divided by `scale` (day phases, ship simulation dt, Director pacing, escalations,
-- cooldowns, catastrophe grace, finale hold), so a compressed day plays like a real 75 s day.
-- The crew is modelled as `crew` workers: every job (minigame, quick action, salvage) occupies one worker for its
-- real duration (in game seconds), so worker utilisation is the difficulty signal.
-- Profile grants are intercepted (counted, never written).
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local Config = require(ReplicatedStorage.Shared.Config.GameConfig)
local Registry = require(ServerScriptService.Server.Minigames.Registry)
local ProfileService = require(ServerScriptService.Server.Progression.ProfileService)
local Director = require(ServerScriptService.Server.CrisisDirector.Director)
local UpkeepService = require(ServerScriptService.Server.World.UpkeepService)

local QaSim = {}
local state = nil

-- Job durations in GAME seconds (walk + interact/solve). Basic tier ~ 25 s solve + walk.
local DUR = { task = 30, action = 10, salvage = 8, craft = 10 }
local MAINT_BELOW = 60 -- crew repairs a system proactively below this health
local MATS = { "ScrapAlloy", "SealantFoam", "FilterMembrane", "ConductiveFilament", "CoolantCartridge" }
local SHORT = { ScrapAlloy = "S", SealantFoam = "Se", FilterMembrane = "F", ConductiveFilament = "Fi", CoolantCartridge = "Co" }

local function repairFor(system)
	for id, mg in pairs(Registry) do
		if mg.System == system and mg.RepairAmount > 0 then return id, mg.RepairAmount end
		if mg.AlsoRepairs and mg.AlsoRepairs[system] then return id, mg.AlsoRepairs[system] end
	end
	return nil
end

local function invLine(inv)
	local parts = {}
	for _, id in ipairs(MATS) do table.insert(parts, SHORT[id] .. (inv[id] or 0)) end
	return table.concat(parts, " ")
end

function QaSim.Status(): string
	if not state then return "idle" end
	local s = state
	local busy = s.busyTime / math.max(1, (os.clock() - s.t0) * #s.workers)
	local line = ("running=%s day=%d phase=%s seed=%d scale=%.1f crew=%d elapsed=%.0fs | inc=%d steps=%d blocked=%d emerg=%d maint=%d salv=%d util=%.0f%% spent[%s] upkeepMissed=%d errors=%d dupGrants=%d"):format(
		tostring(s.running), s.run.day.day, s.run.day.phase, s.seed, s.scale, #s.workers, os.clock() - s.t0, s.spawned, s.steps, s.blocked,
		s.emergencies, s.maint, s.salvaged, busy * 100, invLine(s.spent), s.upkeepMissed, #s.errors, s.dupGrants)
	if s.result then line ..= "\nRESULT: " .. s.result end
	return line
end

function QaSim.Report(every: number?): string
	if not state then return "idle" end
	local out = { QaSim.Status() }
	for i, d in ipairs(state.days) do
		if not every or i % every == 0 or i == #state.days then table.insert(out, d) end
	end
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
	local k = opts.scale or 4

	local s = {
		run = run, running = true, t0 = os.clock(), seed = opts.seed or 1337, untilDay = opts.untilDay or 103, scale = k,
		spawned = 0, steps = 0, blocked = 0, emergencies = 0, maint = 0, salvaged = 0, busyTime = 0,
		errors = {}, grants = 0, dupGrants = 0, grantIds = {}, seenInc = {}, blockedKeys = {}, assigned = {},
		days = {}, byTemplate = {}, tx = 0, minH = {}, conns = {}, spent = {}, charges = {}, workers = {}, upkeepMissed = 0,
	}
	for _, id in ipairs(MATS) do s.spent[id] = 0 end
	for i = 1, opts.crew or 2 do s.workers[i] = { busyUntil = 0 } end
	state = s
	run.rng = Random.new(s.seed)
	if opts.difficulty and Config.Difficulty[opts.difficulty] then
		run.difficulty = opts.difficulty
		run.ship:SetDifficulty(opts.difficulty)
	end

	-- time compression (all restored on stop)
	s.saved = {
		day = table.clone(Config.Day), timing = table.clone(Director.Timing),
		vote = Config.Finale.VoteSeconds, hold = Config.Finale.HoldSeconds, grace = Config.CatastropheGraceSeconds,
	}
	for key, v in pairs(s.saved.day) do Config.Day[key] = v / k end
	for key, v in pairs(s.saved.timing) do Director.Timing[key] = (key == "scale") and k or v / k end
	Config.Finale.HoldSeconds = s.saved.hold / k
	Config.Finale.VoteSeconds = 3
	Config.CatastropheGraceSeconds = s.saved.grace / k
	run.ship.timeScale = k

	s.realGrant = ProfileService.Grant
	ProfileService.Grant = function(_player, grantId, _reward)
		s.grants += 1
		if s.grantIds[grantId] then s.dupGrants += 1 end
		s.grantIds[grantId] = true
		return true
	end
	-- count day-end upkeep (paid amounts join `spent`, misses are a difficulty signal)
	s.realUpkeep = UpkeepService.Run
	UpkeepService.Run = function(r, day)
		local paid, missed = s.realUpkeep(r, day)
		for id, n in pairs(paid) do s.spent[id] = (s.spent[id] or 0) + n end
		s.upkeepMissed += #missed
		return paid, missed
	end
	table.insert(s.conns, LogService.MessageOut:Connect(function(msg, kind)
		if kind == Enum.MessageType.MessageError then table.insert(s.errors, string.sub(msg, 1, 200)) end
	end))

	local function nextTx() s.tx += 1 return ("qa:%d:%d"):format(s.seed, s.tx) end
	local function debit(cost)
		if not run.inventory:TryDebit(cost, nextTx()) then return false end
		for id, n in pairs(cost) do s.spent[id] = (s.spent[id] or 0) + n end
		return true
	end
	local function refillCharges()
		for _, point in ipairs(CollectionService:GetTagged("SalvagePoint")) do
			local cfg = Config.SalvageLoot[point:GetAttribute("SalvageType")]
			if cfg then s.charges[point] = cfg.charges end
		end
	end
	local function resetMin() for name, sys in pairs(run.ship.systems) do s.minH[name] = sys.health end end
	refillCharges()
	resetMin()

	-- path planning: fastest affordable path (actions are quick but cost materials)
	local function planPath(step)
		local best
		for _, p in ipairs(step.paths) do
			if p.kind == "action" then
				local qa = Config.QuickActions[p.id]
				if qa and run.inventory:Has(qa.cost) then return p, DUR.action end
			elseif p.kind == "task" then
				local mg = Registry[p.id]
				if mg and not best then
					if mg.Commit then
						if (mg.CanOpen == nil or mg.CanOpen(run)) then best = p end
					else
						best = p
					end
				end
			end
		end
		if best then return best, DUR.task end
		return nil
	end

	local function applyTask(id)
		local mg = Registry[id]
		if mg.Commit then
			local pub = mg.Generate("Basic", run.rng:NextInteger(1, 1e9), mg.Context and mg.Context(run))
			if not debit(pub.blueprint.cost) then return false end
			run.ship:ApplyRepair(pub.blueprint.system, pub.blueprint.amount, nextTx())
		else
			if mg.RepairAmount > 0 then run.ship:ApplyRepair(mg.System, mg.RepairAmount, nextTx()) end
			for name, amount in pairs(mg.AlsoRepairs or {}) do run.ship:ApplyRepair(name, amount, nextTx()) end
		end
		run.notifyRepair(mg.System, "task:" .. id)
		return true
	end
	local function applyAction(id)
		local qa = Config.QuickActions[id]
		if not debit(qa.cost) then return false end
		run.ship:ApplyDelta(qa.system, qa.field, qa.amount, nextTx())
		run.notifyRepair(qa.system, "action:" .. id)
		return true
	end

	-- candidate jobs in priority order; each = { key, dur (game s), apply() }
	local function jobs(now)
		local list = {}
		if run.emergency then
			local reason = run.emergency.reason
			local action = reason == "OxygenDepleted" and "EmergencyO2" or "HullPatch"
			table.insert(list, { key = "emerg:" .. reason, dur = DUR.action, apply = function()
				if not applyAction(action) then
					-- no kit: repair the root system the slow way
					applyTask(reason == "OxygenDepleted" and "PowerBus" or "HullSeal")
				end
			end })
		end
		local f = run.finale
		if run.day.phase == "Finale" and f.active then
			local cur = f:_current()
			if cur.kind == "task" then
				table.insert(list, { key = "finale:" .. f.stage .. ":" .. f.step, dur = DUR.task, apply = function()
					run.notifyRepair(Registry[cur.id].System, "task:" .. cur.id)
				end })
			elseif cur.kind == "craft" then
				table.insert(list, { key = "finale:craft", dur = DUR.craft, apply = function()
					if debit(Config.Finale.TransmitterCost) then f:DevAdvance() else table.insert(s.errors, "finale craft unaffordable") end
				end })
			end
		end
		for _, inc in ipairs(run.director.active) do
			if not s.seenInc[inc.id] then
				s.seenInc[inc.id] = true
				s.spawned += 1
				s.byTemplate[inc.template.id] = (s.byTemplate[inc.template.id] or 0) + 1
			end
			local key = "inc:" .. inc.id .. ":" .. inc.step
			local step = inc.template.steps[inc.step]
			local p, dur = planPath(step)
			if p then
				local incRef, stepNo = inc, inc.step
				table.insert(list, { key = key, dur = dur, apply = function()
					if incRef.step ~= stepNo or not table.find(run.director.active, incRef) then return end -- solved meanwhile
					local ok = (p.kind == "action") and applyAction(p.id) or applyTask(p.id)
					if ok then s.steps += 1 end
				end })
			elseif not s.blockedKeys[key] then
				s.blockedKeys[key] = true
				s.blocked += 1
			end
		end
		local low = {}
		for name, sys in pairs(run.ship.systems) do
			if sys.health < MAINT_BELOW and repairFor(name) then table.insert(low, name) end
		end
		table.sort(low, function(a, b) return run.ship.systems[a].health < run.ship.systems[b].health end)
		for _, name in ipairs(low) do
			table.insert(list, { key = "maint:" .. name, dur = DUR.task, apply = function()
				local id = repairFor(name)
				s.maint += 1
				applyTask(id)
			end })
		end
		-- salvage when stock is short (keep a working stock, do not hoard past the cap)
		for point, n in pairs(s.charges) do
			if n > 0 then
				local cfg = Config.SalvageLoot[point:GetAttribute("SalvageType")]
				local want = false
				for _, entry in ipairs(cfg.loot) do
					local cap = Config.MaterialCap and Config.MaterialCap[entry.id]
					if (run.inventory.items[entry.id] or 0) < (cap or 8) then want = true end
				end
				if want then
					table.insert(list, { key = "salv:" .. point:GetFullName(), dur = DUR.salvage, apply = function()
						if (s.charges[point] or 0) <= 0 then return end
						s.charges[point] -= 1
						local loot = {}
						for _, entry in ipairs(cfg.loot) do
							local q = run.rng:NextInteger(entry.min, entry.max)
							if q > 0 then loot[entry.id] = (loot[entry.id] or 0) + q end
						end
						run.inventory:Credit(loot, nextTx())
						s.salvaged += 1
					end })
				end
			end
		end
		return list
	end

	local function tick()
		local now = os.clock()
		for _, w in ipairs(s.workers) do
			if w.job and now >= w.busyUntil then
				local job = w.job
				w.job = nil
				s.assigned[job.key] = nil
				job.apply()
			end
		end
		local phase = run.day.phase
		if phase == "Vote" and run.finale.voteOpen then
			for userId in pairs(run.crew) do run.finale.votes[userId] = "Continue" end
			run.finale:_resolveVote("qasim")
			return
		end
		if not (phase == "Prepare" or phase == "Active" or phase == "Transition" or phase == "Finale") then return end
		for name, sys in pairs(run.ship.systems) do s.minH[name] = math.min(s.minH[name] or 100, sys.health) end
		local list = jobs(now)
		local i = 1
		for _, w in ipairs(s.workers) do
			if not w.job then
				while list[i] and s.assigned[list[i].key] do i += 1 end
				local job = list[i]
				if not job then break end
				i += 1
				s.assigned[job.key] = true
				w.job = job
				w.busyUntil = now + job.dur / k
				s.busyTime += job.dur / k
			end
		end
	end

	local function stop(result)
		if not s.running then return end
		s.running = false
		s.result = result
		for _, c in ipairs(s.conns) do c:Disconnect() end
		for key, v in pairs(s.saved.day) do Config.Day[key] = v end
		for key, v in pairs(s.saved.timing) do Director.Timing[key] = v end
		Config.Finale.VoteSeconds, Config.Finale.HoldSeconds = s.saved.vote, s.saved.hold
		Config.CatastropheGraceSeconds = s.saved.grace
		run.ship.timeScale = nil
		ProfileService.Grant = s.realGrant
		UpkeepService.Run = s.realUpkeep
		print("[QaSim] " .. result)
	end
	s.stop = stop

	table.insert(s.conns, run.day.PhaseChanged.Event:Connect(function(info)
		if info.phase == "Prepare" or info.phase == "Finale" then
			refillCharges()
		end
		if info.phase == "Prepare" then
			resetMin()
		elseif info.phase == "Transition" then
			local worst, worstV = "-", 101
			for name, v in pairs(s.minH) do if v < worstV then worst, worstV = name, v end end
			local busy = s.busyTime / math.max(1, (os.clock() - s.t0) * #s.workers)
			table.insert(s.days, ("D%03d %-16s inc=%d emerg=%d upMiss=%d min=%s %.0f util=%.0f%% | %s | spent %s"):format(info.day, info.sector or "?", s.spawned, s.emergencies, s.upkeepMissed,
				worst, worstV, busy * 100, invLine(run.inventory.items), invLine(s.spent)))
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
		local wasEmerg = false
		while s.running do
			local ok, err = pcall(tick)
			if not ok then table.insert(s.errors, "autopilot: " .. tostring(err)) end
			if run.emergency and not wasEmerg then s.emergencies += 1 end
			wasEmerg = run.emergency ~= nil
			task.wait(0.25)
		end
	end)

	if opts.startDay and opts.startDay > run.day.day then run.day.day = opts.startDay end
	return ("started seed=%d scale=%.1f crew=%d difficulty=%s untilDay=%d"):format(s.seed, k, #s.workers, run.difficulty, s.untilDay)
end

function QaSim.Stop(): string
	if state and state.running then state.stop("stopped by dev") end
	return QaSim.Status()
end

return QaSim
