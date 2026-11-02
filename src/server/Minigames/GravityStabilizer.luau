-- M08 Gravity Stabilizer (server-only generator + validator). Rules: Shared.Minigames.GravityStabilizerRules.
-- Start state = a balanced layout disturbed by k random shifts; undoing them (or any better plan) is valid.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage.Shared.Minigames.GravityStabilizerRules)

local GravityStabilizer = {}
GravityStabilizer.Id = "GravityStabilizer"
GravityStabilizer.System = "Cargo"
GravityStabilizer.RepairAmount = 35

local TIERS = {
	Basic = { disturb = 2, extraShifts = 2, powerBudget = 3 },
	Advanced = { disturb = 3, extraShifts = 0, powerBudget = 2 },
}
local S = Rules.SLOTS

local function balancedRing(rng)
	local ring = table.create(S, 0)
	if rng:NextInteger(1, 3) == 1 then
		local m = rng:NextInteger(1, 3) -- triangle 0/120/240
		local o = rng:NextInteger(0, 1)
		for k = 0, 2 do ring[1 + o + 2 * k] = m end
	else
		local pairs_ = rng:NextInteger(1, 2) -- opposite pairs
		local starts = { 1, 2, 3 }
		for i = 3, 2, -1 do local j = rng:NextInteger(1, i) starts[i], starts[j] = starts[j], starts[i] end
		for p = 1, pairs_ do
			local m = rng:NextInteger(1, 3)
			ring[starts[p]] = m
			ring[starts[p] + 3] = m
		end
	end
	return ring
end

local function tryGenerate(t, rng)
	local rings = { balancedRing(rng), balancedRing(rng), balancedRing(rng) }
	-- disturb: k random shifts, remembered so the reverse is a known solution
	local applied = {}
	for _ = 1, t.disturb do
		local r = rng:NextInteger(1, 3)
		local filled, empty = {}, {}
		for s = 1, S do if rings[r][s] > 0 then table.insert(filled, s) else table.insert(empty, s) end end
		if #filled == 0 or #empty == 0 then return nil end
		local from, to = filled[rng:NextInteger(1, #filled)], empty[rng:NextInteger(1, #empty)]
		rings[r][to], rings[r][from] = rings[r][from], 0
		table.insert(applied, { ring = r, from = from, to = to })
	end
	local solution = {}
	for i = #applied, 1, -1 do
		local mv = applied[i]
		table.insert(solution, { ring = mv.ring, from = mv.to, to = mv.from })
	end
	local pub = {
		rings = rings, resonance = rng:NextInteger(10, 15) / 10,
		threshold = 0.6, maxShifts = t.disturb + t.extraShifts, powerBudget = t.powerBudget,
	}
	-- doing nothing (even with max affordable damping) must fail
	if Rules.Evaluate(pub, {}, pub.powerBudget) then return nil end
	if not Rules.Evaluate(pub, solution, 1) then return nil end
	return pub, { moves = solution, damping = 1 }
end

function GravityStabilizer.Generate(tier: string, seed: number)
	local t = TIERS[tier] or TIERS.Basic
	for attempt = 0, 299 do
		local pub, priv = tryGenerate(t, Random.new(seed + attempt * 67867967))
		if pub then return pub, priv end
	end
	error("GravityStabilizer: no layout for seed " .. seed)
end

function GravityStabilizer.ValidateShape(pub, action): boolean
	if type(action) ~= "table" or type(action.moves) ~= "table" or type(action.damping) ~= "number" then return false end
	if action.damping % 1 ~= 0 or action.damping < 1 or action.damping > Rules.DAMPING_MAX then return false end
	if #action.moves > 12 then return false end
	for _, mv in ipairs(action.moves) do
		if type(mv) ~= "table" then return false end
		for _, f in ipairs({ "ring", "from", "to" }) do
			local v = mv[f]
			if type(v) ~= "number" or v % 1 ~= 0 or v < 1 or v > (f == "ring" and 3 or S) then return false end
		end
	end
	return true
end

function GravityStabilizer.Validate(pub, _priv, action)
	local ok, reason, message = Rules.Evaluate(pub, action.moves, action.damping)
	return ok, reason, message
end

function GravityStabilizer.CheckSolvable(pub, priv): boolean
	return (Rules.Evaluate(pub, priv.moves, priv.damping))
end

return GravityStabilizer
