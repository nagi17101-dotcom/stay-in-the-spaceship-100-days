-- M05 Coolant Loop Designer (server-only generator + validator)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PipeMath = require(ReplicatedStorage.Shared.Minigames.PipeMath)

local CoolantLoop = {}
CoolantLoop.Id = "CoolantLoop"
CoolantLoop.System = "Cooling"
CoolantLoop.RepairAmount = 40
local PUMP_MAX = 3

local TIERS = {
	Basic = { w = 4, h = 3, blocked = 0, heat = { 1, 2 } },
	Advanced = { w = 5, h = 4, blocked = 2, heat = { 2, 3 } },
}
local DIR_BIT = { ["0,-1"] = 1, ["1,0"] = 2, ["0,1"] = 4, ["-1,0"] = 8 }
local FILL = { "Straight", "Elbow", "Elbow", "Tee", "Empty" }

local function fit(mask)
	for _, kind in ipairs({ "Straight", "Elbow" }) do
		for r = 0, 3 do if PipeMath.Mask(kind, r) == mask then return kind, r end end
	end
	error("no tile fits mask " .. mask)
end

function CoolantLoop.Generate(tier: string, seed: number)
	local rng = Random.new(seed)
	local t = TIERS[tier] or TIERS.Basic
	local w, h = t.w, t.h
	local sr, er = rng:NextInteger(1, h), rng:NextInteger(1, h)

	-- Column-by-column path from west source to east reactor (no revisits)
	local path, r = {}, sr
	for c = 1, w do
		local target = (c == w) and er or rng:NextInteger(1, h)
		local step = target >= r and 1 or -1
		for y = r, target, step do table.insert(path, { x = c, y = y }) end
		r = target
	end

	local kinds, rots, sol, onPath = {}, {}, {}, {}
	local function idx(x, y) return (y - 1) * w + x end
	for i, cell in ipairs(path) do
		local prev = path[i - 1]
		local nxt = path[i + 1]
		local pBit = prev and DIR_BIT[(prev.x - cell.x) .. "," .. (prev.y - cell.y)] or PipeMath.W
		local nBit = nxt and DIR_BIT[(nxt.x - cell.x) .. "," .. (nxt.y - cell.y)] or PipeMath.E
		local kind, rot = fit(bit32.bor(pBit, nBit))
		local k = idx(cell.x, cell.y)
		kinds[k], sol[k], onPath[k] = kind, rot, true
		-- scramble to a rotation with a different opening mask
		local scr = rot
		repeat scr = (scr + rng:NextInteger(1, 3)) % 4 until PipeMath.Mask(kind, scr) ~= PipeMath.Mask(kind, rot)
		rots[k] = scr
	end

	local free = {}
	for k = 1, w * h do
		if not onPath[k] then
			kinds[k] = FILL[rng:NextInteger(1, #FILL)]
			rots[k] = rng:NextInteger(0, 3)
			sol[k] = rots[k]
			table.insert(free, k)
		end
	end
	for _ = 1, math.min(t.blocked, #free) do
		local k = table.remove(free, rng:NextInteger(1, #free))
		kinds[k] = "Blocked"
	end

	local heat = rng:NextInteger(t.heat[1], t.heat[2])
	local pub = {
		w = w, h = h, kinds = kinds, rots = rots,
		sourceRow = sr, reactorRow = er,
		heatLoad = heat, pumpMax = PUMP_MAX,
		maxPressure = #path + heat * 2 + 2,
	}
	return pub, { solutionRots = sol, solutionSpeed = heat }
end

function CoolantLoop.ValidateShape(pub, action): boolean
	if type(action) ~= "table" or type(action.rotations) ~= "table" or type(action.speed) ~= "number" then return false end
	if action.speed % 1 ~= 0 or action.speed < 1 or action.speed > pub.pumpMax then return false end
	if #action.rotations ~= pub.w * pub.h then return false end
	for i = 1, pub.w * pub.h do
		local v = action.rotations[i]
		if type(v) ~= "number" or v % 1 ~= 0 or v < 0 or v > 3 then return false end
	end
	return true
end

function CoolantLoop.Validate(pub, _priv, action)
	local len = PipeMath.Trace(pub.w, pub.h, pub.kinds, action.rotations, pub.sourceRow, pub.reactorRow)
	if not len then return false, "NoFlow", "Coolant does not reach the reactor." end
	if action.speed < pub.heatLoad then
		return false, "Underflow", ("Pump too slow for heat load %d."):format(pub.heatLoad)
	end
	local pressure = len + action.speed * 2
	if pressure > pub.maxPressure then
		return false, "Overpressure", ("Overpressure (%d / %d). Lower pump speed or shorten the loop."):format(pressure, pub.maxPressure)
	end
	return true, "OK", "Coolant loop restored."
end

function CoolantLoop.CheckSolvable(pub, priv): boolean
	return (CoolantLoop.Validate(pub, priv, { rotations = priv.solutionRots, speed = priv.solutionSpeed }))
end

return CoolantLoop
