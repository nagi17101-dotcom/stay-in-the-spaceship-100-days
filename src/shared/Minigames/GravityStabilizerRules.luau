-- GravityStabilizerRules: public ring model for M08 Gravity Stabilizer.
-- Shared by server validator (authoritative) and client UI (live COM markers). Contains no solutions.
local Rules = {}

Rules.SLOTS = 6 -- 60° apart
Rules.DAMPING_MAX = 3

local UNIT = {}
for s = 1, Rules.SLOTS do
	local a = math.rad((s - 1) * 360 / Rules.SLOTS)
	UNIT[s] = { math.cos(a), math.sin(a) }
end
Rules.Unit = UNIT

-- rings: { {mass per slot, 0 = empty} x3 }
function Rules.Com(ring: {number})
	local x, y = 0, 0
	for s, m in ipairs(ring) do x += m * UNIT[s][1] y += m * UNIT[s][2] end
	return x, y, math.sqrt(x * x + y * y)
end

-- Apply moves to a copy of the start state. Returns rings or nil, reason, message
function Rules.Apply(pub, moves)
	if #moves > pub.maxShifts then
		return nil, "TooManyShifts", ("Only %d weight shifts are available."):format(pub.maxShifts)
	end
	local rings = {}
	for r, ring in ipairs(pub.rings) do rings[r] = table.clone(ring) end
	for _, mv in ipairs(moves) do
		local ring = rings[mv.ring]
		if not ring or not ring[mv.from] or not ring[mv.to] then return nil, "BadMove", "Invalid shift." end
		if ring[mv.from] == 0 then return nil, "BadMove", "No weight in that slot." end
		if ring[mv.to] ~= 0 then return nil, "BadMove", "Target slot is occupied." end
		ring[mv.to], ring[mv.from] = ring[mv.from], 0
	end
	return rings
end

function Rules.Oscillation(pub, rings, damping: number): number
	local sum = 0
	for _, ring in ipairs(rings) do local _, _, m = Rules.Com(ring) sum += m end
	return sum * pub.resonance / damping
end

-- Returns ok, reasonCode, message, readout { rings, oscillation, power }
function Rules.Evaluate(pub, moves, damping: number)
	local rings, reason, message = Rules.Apply(pub, moves)
	if not rings then return false, reason, message, nil end
	local osc = Rules.Oscillation(pub, rings, damping)
	local r = { rings = rings, oscillation = osc, power = damping }
	if damping > pub.powerBudget then
		return false, "PowerOver", ("Damping %d exceeds the power budget (%d)."):format(damping, pub.powerBudget), r
	end
	if osc > pub.threshold + 1e-6 then
		return false, "Unstable", ("Oscillation %.2f is above the safe threshold %.2f."):format(osc, pub.threshold), r
	end
	return true, "OK", "Rings balanced. Gravity field stable.", r
end

return Rules
