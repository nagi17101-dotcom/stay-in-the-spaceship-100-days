-- Feasibility: pure checks. A template may spawn only if this crew can resolve it now.
-- ctx = { day, crew, systems (name -> {health, output}), hasMaterials(cost)->bool, stations (minigameId set),
--         actions (actionId set), quickActions (Config.QuickActions), active (list of incidents), maxCritical, graceFactor }
local Feasibility = {}

Feasibility.TASK_SECONDS = 45   -- travel + solve, worst reasonable latency
Feasibility.ACTION_SECONDS = 15
Feasibility.FLOOR = 15          -- worst case may not push any system below this

local function pathAvailable(path, ctx)
	if path.kind == "task" then
		return ctx.stations[path.id] == true, Feasibility.TASK_SECONDS
	elseif path.kind == "action" then
		local qa = ctx.quickActions[path.id]
		return ctx.actions[path.id] == true and qa ~= nil and ctx.hasMaterials(qa.cost), Feasibility.ACTION_SECONDS
	end
	return false, math.huge
end

-- returns ok, reason
function Feasibility.Check(t, ctx)
	if ctx.day < t.minDay then return false, "TooEarly" end

	local criticalActive = 0
	for _, inc in ipairs(ctx.active) do
		if inc.template.id == t.id then return false, "AlreadyActive" end
		if inc.template.severity == "Critical" then criticalActive += 1 end
		for _, e in ipairs(t.effects) do
			for _, e2 in ipairs(inc.template.effects) do
				if e.system == e2.system then return false, "SystemBusy" end -- no stacking on one system (no cascade loops)
			end
		end
	end
	if t.severity == "Critical" and criticalActive >= ctx.maxCritical then return false, "CriticalCap" end

	-- Worst case (spawn + all escalations) must leave every touched value above FLOOR
	local worst = {}
	local function add(e, times)
		local k = e.system .. "." .. e.field
		local sys = ctx.systems[e.system]
		worst[k] = (worst[k] or sys[e.field]) + e.amount * times
	end
	for _, e in ipairs(t.effects) do add(e, 1) end
	for _, e in ipairs(t.escalate.effects) do add(e, t.escalate.max) end
	for k, v in pairs(worst) do
		if v < Feasibility.FLOOR then return false, "WouldCripple:" .. k end
	end

	-- Every step needs an available path; steps are sequential (1 station at a time => fine for 2 players)
	local needed = 0
	for i, step in ipairs(t.steps) do
		local best = math.huge
		for _, p in ipairs(step.paths) do
			local ok, secs = pathAvailable(p, ctx)
			if ok then best = math.min(best, secs) end
		end
		if best == math.huge then return false, "NoPath:step" .. i end
		needed += best
	end
	local window = t.escalate.every * (t.escalate.max + 1) * ctx.graceFactor
	if needed > window then return false, "NotEnoughTime" end
	if ctx.crew < 1 then return false, "NoCrew" end
	return true, "OK"
end

return Feasibility
