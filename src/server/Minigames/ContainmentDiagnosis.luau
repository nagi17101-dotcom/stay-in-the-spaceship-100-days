-- M12 Containment Diagnosis (server-only generator + validator). Rules: Shared.Minigames.ContainmentDiagnosisRules.
-- Opened only while a Director incident needs it (containment alarm). Success halts that incident's cascade
-- and hands the crew to a real repair station (next incident step).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage.Shared.Minigames.ContainmentDiagnosisRules)

local ContainmentDiagnosis = {}
ContainmentDiagnosis.Id = "ContainmentDiagnosis"
ContainmentDiagnosis.System = "Oxygen"
ContainmentDiagnosis.RepairAmount = 10 -- isolation stabilises the atmosphere a little
ContainmentDiagnosis.MaxAttempts = 2 -- deduction task: few attempts so blind guessing does not pay

local NAMES = { "Tank Bay", "Scrubber Deck", "Service Duct", "Filter Loft", "Pump Well" }
local BLOCK_REASONS = { "vent line offline", "maintenance lockout", "tool rack empty", "power budget exceeded" }
local TIERS = {
	Basic = { comps = 3, offline = 1, stale = 0, spill = 1, herring = 0, block = false },
	Advanced = { comps = 3, offline = 2, stale = 2, spill = 1, herring = 1, block = true },
}

function ContainmentDiagnosis.CanOpen(run): (boolean, string?)
	if run.director and run.director:NeedsTask(ContainmentDiagnosis.Id) then return true end
	return false, "No containment alarm — diagnostics idle."
end

local function reading(rng, sensor, v, state)
	local jitter = (rng:NextNumber() - 0.5) * 0.3 * sensor.delta
	local val = sensor.nom + v * sensor.delta + jitter
	return { v = v, val = math.floor(val * 10 + 0.5) / 10, state = state }
end

local function tryGenerate(t, rng)
	local names = table.clone(NAMES)
	local comps = {}
	for i = 1, t.comps do
		local name = table.remove(names, rng:NextInteger(1, #names))
		local rd = {}
		for _, s in ipairs(Rules.SENSORS) do rd[s.id] = reading(rng, s, 0, "OK") end
		comps[i] = { name = name, readings = rd }
	end
	local root = rng:NextInteger(1, t.comps)
	local cause = Rules.CAUSES[rng:NextInteger(1, #Rules.CAUSES)]
	local sensorById = {}
	for _, s in ipairs(Rules.SENSORS) do sensorById[s.id] = s end
	local decisive = {}
	for id, d in pairs(cause.sig) do
		comps[root].readings[id] = reading(rng, sensorById[id], d, "OK")
		decisive[root .. id] = true
	end
	local function others()
		local list = {}
		for i = 1, t.comps do if i ~= root then table.insert(list, i) end end
		return list
	end
	local function freeSlot(compIdx)
		local free = {}
		for _, s in ipairs(Rules.SENSORS) do
			local r = comps[compIdx].readings[s.id]
			if not decisive[compIdx .. s.id] and r.state == "OK" and r.v == 0 then table.insert(free, s) end
		end
		return #free > 0 and free[rng:NextInteger(1, #free)] or nil
	end
	-- spillover: a neighbour shows one of the root's symptoms (misleading but single)
	local sigIds = {}
	for id in pairs(cause.sig) do table.insert(sigIds, id) end
	table.sort(sigIds)
	for k = 1, t.spill do
		local list = others()
		local c = list[((k - 1 + rng:NextInteger(0, #list - 1)) % #list) + 1]
		local id = sigIds[rng:NextInteger(1, #sigIds)]
		if comps[c].readings[id].v == 0 then comps[c].readings[id] = reading(rng, sensorById[id], cause.sig[id], "OK") end
	end
	-- red herring: one symptom of a different fault elsewhere
	for _ = 1, t.herring do
		local list = others()
		local c = list[rng:NextInteger(1, #list)]
		local s = freeSlot(c)
		if s then comps[c].readings[s.id] = reading(rng, s, rng:NextNumber() < 0.5 and -1 or 1, "OK") end
	end
	-- stale sensors: abnormal but explainable (old sample); never on decisive sensors
	for _ = 1, t.stale do
		local c = rng:NextInteger(1, t.comps)
		local s = freeSlot(c)
		if s then
			local r = reading(rng, s, rng:NextNumber() < 0.5 and -1 or 1, "STALE")
			r.age = rng:NextInteger(3, 9)
			comps[c].readings[s.id] = r
		end
	end
	for _ = 1, t.offline do
		local c = rng:NextInteger(1, t.comps)
		local s = freeSlot(c)
		if s then comps[c].readings[s.id] = { v = 0, val = 0, state = "OFF" } end
	end

	local pub = { compartments = comps }
	if t.block then
		pub.blocked = { fix = cause.fixes[rng:NextInteger(1, 2)], reason = BLOCK_REASONS[rng:NextInteger(1, #BLOCK_REASONS)] }
	end
	local cands = Rules.Candidates(pub)
	if #cands ~= 1 or cands[1].index ~= root or cands[1].cause ~= cause.id then return nil end
	-- the misleading symptom must actually exist for Advanced
	local anomalies = 0
	for i, comp in ipairs(comps) do
		if i ~= root then for _, r in pairs(comp.readings) do if r.v ~= 0 then anomalies += 1 end end end
	end
	if anomalies < t.spill then return nil end
	local fix
	for _, f in ipairs(cause.fixes) do if not (pub.blocked and pub.blocked.fix == f) then fix = f break end end
	return pub, { root = root, cause = cause.id, fix = fix }
end

function ContainmentDiagnosis.Generate(tier: string, seed: number)
	local t = TIERS[tier] or TIERS.Basic
	for attempt = 0, 299 do
		local pub, priv = tryGenerate(t, Random.new(seed + attempt * 19349663))
		if pub then return pub, priv end
	end
	error("ContainmentDiagnosis: no layout for seed " .. seed)
end

function ContainmentDiagnosis.ValidateShape(pub, action): boolean
	if type(action) ~= "table" or type(action.isolate) ~= "table" or #action.isolate > #pub.compartments then return false end
	for _, i in ipairs(action.isolate) do
		if type(i) ~= "number" or i % 1 ~= 0 or i < 1 or i > #pub.compartments then return false end
	end
	return type(action.cause) == "string" and #action.cause <= 20 and type(action.fix) == "string" and #action.fix <= 20
end

function ContainmentDiagnosis.Validate(pub, _priv, action)
	local ok, reason, message = Rules.Evaluate(pub, action)
	return ok, reason, message
end

function ContainmentDiagnosis.CheckSolvable(pub, priv): boolean
	return (Rules.Evaluate(pub, { isolate = { priv.root }, cause = priv.cause, fix = priv.fix }))
end

return ContainmentDiagnosis
