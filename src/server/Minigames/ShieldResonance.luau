-- M10 Shield Resonance (server-only generator + validator). Rules: Shared.Minigames.ShieldResonanceRules.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage.Shared.Minigames.ShieldResonanceRules)

local ShieldResonance = {}
ShieldResonance.Id = "ShieldResonance"
ShieldResonance.System = "Shields"
ShieldResonance.RepairAmount = 35

local CATALOG = {
	{ type = "Kinetic", width = 2, cost = 2 }, { type = "Kinetic", width = 3, cost = 3 },
	{ type = "Ionic", width = 2, cost = 2 }, { type = "Ionic", width = 3, cost = 3 },
	{ type = "Hybrid", width = 2, cost = 4 },
}
local CAPACITOR = { type = "Capacitor", width = 0, cost = -2 }
local TIERS = {
	Basic = { threats = 2, decoys = 1, slack = 1, capacitor = false, disabled = false, heatLimit = nil },
	Advanced = { threats = 3, decoys = 2, slack = 0, capacitor = true, disabled = true, heatLimit = 0 },
}

local function tryGenerate(t, rng)
	local B = Rules.BANDS
	-- threats: separated intervals
	local threats, solution, emitters = {}, {}, {}
	local cursor = rng:NextInteger(1, 2)
	for _ = 1, t.threats do
		local len = rng:NextInteger(1, 3)
		local from = cursor + rng:NextInteger(0, 1)
		local to = from + len - 1
		if to > B then return nil end
		table.insert(threats, { from = from, to = to, kind = rng:NextInteger(1, 2) == 1 and "meteor" or "ion" })
		cursor = to + 2 -- gap keeps a non-overlapping solution possible
	end
	-- one emitter per threat, wide enough, placed to cover it without leaving the spectrum
	local lastEnd = 0
	for _, th in ipairs(threats) do
		local opts = {}
		for _, e in ipairs(CATALOG) do
			local fits = Rules.Covers[e.type][th.kind] and e.width >= (th.to - th.from + 1)
			if fits then table.insert(opts, e) end
		end
		local e = table.clone(opts[rng:NextInteger(1, #opts)])
		local lo = math.max(1, th.to - e.width + 1, lastEnd + 1)
		local hi = math.min(th.from, B - e.width + 1)
		if lo > hi then return nil end
		local start = rng:NextInteger(lo, hi)
		lastEnd = start + e.width - 1
		table.insert(emitters, e)
		table.insert(solution, { emitter = #emitters, start = start })
	end
	local cost = 0
	for _, s in ipairs(solution) do cost += emitters[s.emitter].cost end
	if t.capacitor then
		table.insert(emitters, table.clone(CAPACITOR))
		table.insert(solution, { emitter = #emitters, start = 1 })
	end
	for _ = 1, t.decoys do table.insert(emitters, table.clone(CATALOG[rng:NextInteger(1, #CATALOG)])) end
	-- shuffle emitter list and remap solution
	local order = {}
	for i = 1, #emitters do order[i] = i end
	for i = #order, 2, -1 do local j = rng:NextInteger(1, i) order[i], order[j] = order[j], order[i] end
	local shuffled, newIndex = {}, {}
	for newI, oldI in ipairs(order) do shuffled[newI] = emitters[oldI] newIndex[oldI] = newI end

	local slots = #solution + (t.disabled and 1 or 1)
	local disabledSlot = t.disabled and rng:NextInteger(1, slots) or nil
	local placements, nextSlot = {}, 1
	for _, s in ipairs(solution) do
		if nextSlot == disabledSlot then nextSlot += 1 end
		table.insert(placements, { slot = nextSlot, emitter = newIndex[s.emitter], start = s.start })
		nextSlot += 1
	end
	local pub = {
		threats = threats, emitters = shuffled, slots = slots, disabledSlot = disabledSlot,
		powerBudget = cost + (t.capacitor and -2 or 0) + t.slack, heatLimit = t.heatLimit,
	}
	if not Rules.Evaluate(pub, placements) then return nil end
	if Rules.Evaluate(pub, {}) then return nil end
	return pub, { placements = placements }
end

function ShieldResonance.Generate(tier: string, seed: number)
	local t = TIERS[tier] or TIERS.Basic
	for attempt = 0, 299 do
		local pub, priv = tryGenerate(t, Random.new(seed + attempt * 122949829))
		if pub then return pub, priv end
	end
	error("ShieldResonance: no layout for seed " .. seed)
end

function ShieldResonance.ValidateShape(pub, action): boolean
	if type(action) ~= "table" or type(action.placements) ~= "table" or #action.placements > pub.slots then return false end
	for _, p in ipairs(action.placements) do
		if type(p) ~= "table" then return false end
		for _, f in ipairs({ "slot", "emitter", "start" }) do
			local v = p[f]
			if type(v) ~= "number" or v % 1 ~= 0 or v < 0 or v > 20 then return false end
		end
	end
	return true
end

function ShieldResonance.Validate(pub, _priv, action)
	local ok, reason, message = Rules.Evaluate(pub, action.placements)
	return ok, reason, message
end

function ShieldResonance.CheckSolvable(pub, priv): boolean
	return (Rules.Evaluate(pub, priv.placements))
end

return ShieldResonance
