-- M03 Reactor Phase Equalizer (server-only generator + validator). Rules: Shared.Minigames.ReactorPhaseRules.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage.Shared.Minigames.ReactorPhaseRules)

local ReactorPhase = {}
ReactorPhase.Id = "ReactorPhase"
ReactorPhase.System = "Reactor"
ReactorPhase.RepairAmount = 35

local TIERS = {
	Basic = { coupled = false, slack = { 0, 1 }, maxValid = 4 },
	Advanced = { coupled = true, slack = { 0, 2 }, maxValid = 6 },
}
local S = Rules.STEPS

local function tryGenerate(t, rng)
	local coils = {}
	for i = 1, 3 do
		table.insert(coils, { label = "COIL " .. string.char(64 + i), phase = rng:NextInteger(0, S - 1), heatCoeff = rng:NextInteger(1, 3) })
	end
	local pub = { coils = coils, coupled = t.coupled, baseHeat = 2, heatCeiling = 0 }
	if Rules.Evaluate(pub, { 0, 0, 0 }) or Rules.Phases(pub, { 0, 0, 0 })[1] == Rules.Phases(pub, { 0, 0, 0 })[2]
		and Rules.Phases(pub, { 0, 0, 0 })[2] == Rules.Phases(pub, { 0, 0, 0 })[3] then
		return nil -- already synchronized at start
	end

	-- Enumerate every tuning; keep synchronized ones
	local synced, minHeat = {}, math.huge
	for a = 0, S - 1 do for b = 0, S - 1 do for c = 0, S - 1 do
		local tuning = { a, b, c }
		local _, _, _, r = Rules.Evaluate(pub, tuning)
		if r.synced then
			table.insert(synced, { tuning = tuning, heat = r.heat })
			minHeat = math.min(minHeat, r.heat)
		end
	end end end
	if #synced == 0 then return nil end

	pub.heatCeiling = minHeat + rng:NextInteger(t.slack[1], t.slack[2])
	local valid = {}
	for _, s in ipairs(synced) do if s.heat <= pub.heatCeiling then table.insert(valid, s) end end
	if #valid < 1 or #valid > t.maxValid then return nil end
	local pick = valid[rng:NextInteger(1, #valid)]
	return pub, { tuning = pick.tuning, validCount = #valid, syncedCount = #synced }
end

function ReactorPhase.Generate(tier: string, seed: number)
	local t = TIERS[tier] or TIERS.Basic
	for attempt = 0, 299 do
		local pub, priv = tryGenerate(t, Random.new(seed + attempt * 15485863))
		if pub then return pub, priv end
	end
	error("ReactorPhase: no layout for seed " .. seed)
end

function ReactorPhase.ValidateShape(pub, action): boolean
	if type(action) ~= "table" or type(action.tuning) ~= "table" or #action.tuning ~= #pub.coils then return false end
	for i = 1, #pub.coils do
		local v = action.tuning[i]
		if type(v) ~= "number" or v % 1 ~= 0 or v < 0 or v >= S then return false end
	end
	return true
end

function ReactorPhase.Validate(pub, _priv, action)
	local ok, reason, message = Rules.Evaluate(pub, action.tuning)
	return ok, reason, message
end

function ReactorPhase.CheckSolvable(pub, priv): boolean
	return (Rules.Evaluate(pub, priv.tuning))
end

return ReactorPhase
