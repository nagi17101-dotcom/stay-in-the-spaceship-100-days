-- M01 Hull Seal Planner (server-only generator + validator). Rules live in Shared.Minigames.HullSealRules.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage.Shared.Minigames.HullSealRules)

local HullSeal = {}
HullSeal.Id = "HullSeal"
HullSeal.System = "Hull"
HullSeal.RepairAmount = 35

local TIERS = {
	Basic = { w = 5, h = 4, leak = { 3, 4 }, rail = 0, hot = 1, spares = 1, stress = false, shapes = { "I2", "I3", "L3", "O4" } },
	Advanced = { w = 6, h = 5, leak = { 5, 6 }, rail = 3, hot = 2, spares = 1, stress = true, shapes = { "I2", "I3", "L3", "O4", "T4" } },
}
local NEIGH = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
local key = Rules.Key

local function shuffle(t, rng)
	for i = #t, 2, -1 do local j = rng:NextInteger(1, i) t[i], t[j] = t[j], t[i] end
end

local function tryGenerate(t, rng)
	local w, h = t.w, t.h
	-- 1) Leak blob grown from an interior cell
	local leak, leakSet = {}, {}
	local sx, sy = rng:NextInteger(2, w - 1), rng:NextInteger(2, h - 1)
	table.insert(leak, { sx, sy }) leakSet[key(sx, sy)] = true
	local target = rng:NextInteger(t.leak[1], t.leak[2])
	for _ = 1, 100 do
		if #leak >= target then break end
		local c = leak[rng:NextInteger(1, #leak)]
		local d = NEIGH[rng:NextInteger(1, 4)]
		local nx, ny = c[1] + d[1], c[2] + d[2]
		if nx >= 1 and nx <= w and ny >= 1 and ny <= h and not leakSet[key(nx, ny)] then
			table.insert(leak, { nx, ny }) leakSet[key(nx, ny)] = true
		end
	end

	-- 2) Known solution: cover every leak cell with random plates
	local occ, sol, shapesUsed = {}, {}, {}
	local order = table.clone(leak)
	shuffle(order, rng)
	for _, tc in ipairs(order) do
		if not occ[key(tc[1], tc[2])] then
			local placed = false
			for _ = 1, 40 do
				local shape = t.shapes[rng:NextInteger(1, #t.shapes)]
				local rot = rng:NextInteger(0, 3)
				local cells = Rules.Cells(shape, 0, 0, rot)
				local pick = cells[rng:NextInteger(1, #cells)]
				local ax, ay = tc[1] - pick[1], tc[2] - pick[2]
				local ok = true
				for _, c in ipairs(Rules.Cells(shape, ax, ay, rot)) do
					if c[1] < 1 or c[1] > w or c[2] < 1 or c[2] > h or occ[key(c[1], c[2])] then ok = false break end
				end
				if ok then
					for _, c in ipairs(Rules.Cells(shape, ax, ay, rot)) do occ[key(c[1], c[2])] = true end
					table.insert(sol, { shape = shape, x = ax, y = ay, rot = rot })
					placed = true
					break
				end
			end
			if not placed then return nil end
		end
	end

	-- 3) Obstacles only on cells the solution does not use
	local free = {}
	for y = 1, h do for x = 1, w do
		if not occ[key(x, y)] and not leakSet[key(x, y)] then table.insert(free, { x, y }) end
	end end
	local blocked = {}
	if t.rail > 0 then
		-- maintenance rail: horizontal run of free cells
		local runs = {}
		for y = 1, h do for x = 1, w - t.rail + 1 do
			local ok = true
			for i = 0, t.rail - 1 do if occ[key(x + i, y)] or leakSet[key(x + i, y)] then ok = false break end end
			if ok then table.insert(runs, { x, y }) end
		end end
		if #runs == 0 then return nil end
		local r = runs[rng:NextInteger(1, #runs)]
		for i = 0, t.rail - 1 do table.insert(blocked, { r[1] + i, r[2] }) end
	end
	local blockedSet = {}
	for _, c in ipairs(blocked) do blockedSet[key(c[1], c[2])] = true end
	local hotCandidates = {}
	for _, c in ipairs(free) do if not blockedSet[key(c[1], c[2])] then table.insert(hotCandidates, c) end end
	shuffle(hotCandidates, rng)
	local hot = {}
	for i = 1, math.min(t.hot, #hotCandidates) do table.insert(hot, hotCandidates[i]) end

	-- 4) Plate inventory = solution plates + spares, shuffled; remap solution
	local inv = {}
	for i, p in ipairs(sol) do table.insert(inv, { shape = p.shape, solIndex = i }) end
	for _ = 1, t.spares do table.insert(inv, { shape = t.shapes[rng:NextInteger(1, #t.shapes)] }) end
	shuffle(inv, rng)
	local plates, solution = {}, {}
	for idx, item in ipairs(inv) do
		plates[idx] = item.shape
		if item.solIndex then
			local p = sol[item.solIndex]
			table.insert(solution, { plate = idx, x = p.x, y = p.y, rot = p.rot })
		end
	end

	local stressSide = nil
	if t.stress then
		local sides = {}
		for _, s in ipairs({ "N", "E", "S", "W" }) do
			for k in pairs(occ) do
				local x, y = string.match(k, "(-?%d+),(-?%d+)")
				if Rules.OnSide({ w = w, h = h }, tonumber(x), tonumber(y), s) then table.insert(sides, s) break end
			end
		end
		if #sides == 0 then return nil end
		stressSide = sides[rng:NextInteger(1, #sides)]
	end

	local pub = { w = w, h = h, leak = leak, blocked = blocked, hot = hot, plates = plates, stressSide = stressSide }
	local ok = Rules.Evaluate(pub, solution)
	if not ok then return nil end
	return pub, { solution = solution }
end

function HullSeal.Generate(tier: string, seed: number)
	local t = TIERS[tier] or TIERS.Basic
	for attempt = 0, 199 do
		local pub, priv = tryGenerate(t, Random.new(seed + attempt * 7919))
		if pub then return pub, priv end
	end
	error("HullSeal: no solvable layout for seed " .. seed)
end

function HullSeal.ValidateShape(pub, action): boolean
	if type(action) ~= "table" or type(action.placements) ~= "table" then return false end
	local n = #action.placements
	if n > #pub.plates then return false end
	for i = 1, n do
		local p = action.placements[i]
		if type(p) ~= "table" then return false end
		for _, f in ipairs({ "plate", "x", "y", "rot" }) do
			local v = p[f]
			if type(v) ~= "number" or v % 1 ~= 0 or v < -10 or v > 20 then return false end
		end
		if p.plate < 1 or p.plate > #pub.plates or p.rot < 0 or p.rot > 3 then return false end
	end
	return true
end

function HullSeal.Validate(pub, _priv, action)
	local ok, reason, message = Rules.Evaluate(pub, action.placements)
	return ok, reason, message
end

function HullSeal.CheckSolvable(pub, priv): boolean
	return (Rules.Evaluate(pub, priv.solution))
end

return HullSeal
