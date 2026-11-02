-- HullSealRules: public plate geometry + rule evaluation for M01 Hull Seal Planner.
-- Shared by server validator (authoritative) and client UI (live hints). Contains no solutions.
local Rules = {}

-- Cells relative to anchor, before rotation
Rules.Shapes = {
	I2 = { { 0, 0 }, { 1, 0 } },
	I3 = { { 0, 0 }, { 1, 0 }, { 2, 0 } },
	L3 = { { 0, 0 }, { 0, 1 }, { 1, 1 } },
	O4 = { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } },
	T4 = { { 0, 0 }, { 1, 0 }, { 2, 0 }, { 1, 1 } },
}
Rules.SideName = { N = "NORTH", E = "EAST", S = "SOUTH", W = "WEST" }

local function key(x, y) return x .. "," .. y end
Rules.Key = key

-- Rotation r (0..3) is clockwise: (dx, dy) -> (-dy, dx)
function Rules.Cells(shape: string, x: number, y: number, rot: number)
	local out = {}
	for _, c in ipairs(Rules.Shapes[shape] or {}) do
		local dx, dy = c[1], c[2]
		for _ = 1, rot % 4 do dx, dy = -dy, dx end
		table.insert(out, { x + dx, y + dy })
	end
	return out
end

local function onSide(pub, x, y, side)
	return (side == "N" and y == 1) or (side == "S" and y == pub.h) or (side == "W" and x == 1) or (side == "E" and x == pub.w)
end
Rules.OnSide = onSide

local function toSet(list)
	local s = {}
	for _, c in ipairs(list or {}) do s[key(c[1], c[2])] = true end
	return s
end

-- placements: { { plate = index into pub.plates, x, y, rot } }
-- returns ok, reasonCode, message, occupied (key -> placement index)
function Rules.Evaluate(pub, placements)
	local blocked, hot = toSet(pub.blocked), toSet(pub.hot)
	local occupied, used = {}, {}
	for i, p in ipairs(placements) do
		if used[p.plate] then return false, "PlateReused", "Each plate can be used only once.", occupied end
		used[p.plate] = true
		local shape = pub.plates[p.plate]
		if not shape then return false, "UnknownPlate", "Unknown plate.", occupied end
		for _, c in ipairs(Rules.Cells(shape, p.x, p.y, p.rot)) do
			local x, y = c[1], c[2]
			local k = key(x, y)
			if x < 1 or x > pub.w or y < 1 or y > pub.h then return false, "OutOfFrame", "A plate overhangs the hull frame.", occupied end
			if blocked[k] then return false, "OnRail", "A plate sits on the maintenance rail.", occupied end
			if hot[k] then return false, "HotWeld", "A plate covers an overheating weld point.", occupied end
			if occupied[k] then return false, "Overlap", "Plates overlap.", occupied end
			occupied[k] = i
		end
	end

	local open = 0
	for _, c in ipairs(pub.leak) do
		if not occupied[key(c[1], c[2])] then open += 1 end
	end
	if open > 0 then return false, "LeakOpen", ("Leak still open: %d cell(s) uncovered."):format(open), occupied end

	-- Weld contact: every plate touches the frame edge or another plate
	for i, p in ipairs(placements) do
		local touches = false
		for _, c in ipairs(Rules.Cells(pub.plates[p.plate], p.x, p.y, p.rot)) do
			local x, y = c[1], c[2]
			if x == 1 or y == 1 or x == pub.w or y == pub.h then touches = true break end
			for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
				local o = occupied[key(x + d[1], y + d[2])]
				if o and o ~= i then touches = true break end
			end
			if touches then break end
		end
		if not touches then return false, "NoWeldContact", ("Plate %d has no weld contact (frame or another plate)."):format(i), occupied end
	end

	if pub.stressSide then
		local braced = false
		for k in pairs(occupied) do
			local x, y = string.match(k, "(-?%d+),(-?%d+)")
			if onSide(pub, tonumber(x), tonumber(y), pub.stressSide) then braced = true break end
		end
		if not braced then return false, "StressUnbraced", ("Stress side %s is not braced by any plate."):format(Rules.SideName[pub.stressSide]), occupied end
	end

	return true, "OK", "Seal holds. Pressure restored.", occupied
end

return Rules
