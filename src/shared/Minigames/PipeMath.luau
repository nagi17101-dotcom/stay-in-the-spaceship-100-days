-- PipeMath: public pipe-grid helpers (shared by server validator and client UI). No solutions here.
local PipeMath = {}
PipeMath.N, PipeMath.E, PipeMath.S, PipeMath.W = 1, 2, 4, 8
PipeMath.Base = { Empty = 0, Straight = 5, Elbow = 3, Tee = 7, Blocked = 0 }
PipeMath.Dirs = {
	{ bit = 1, dx = 0, dy = -1, opp = 4 },
	{ bit = 2, dx = 1, dy = 0, opp = 8 },
	{ bit = 4, dx = 0, dy = 1, opp = 1 },
	{ bit = 8, dx = -1, dy = 0, opp = 2 },
}

function PipeMath.Rotate(mask: number, r: number): number
	for _ = 1, r % 4 do
		mask = bit32.band(bit32.bor(bit32.lshift(mask, 1), bit32.rshift(mask, 3)), 15)
	end
	return mask
end

function PipeMath.Mask(kind: string, rot: number): number
	return PipeMath.Rotate(PipeMath.Base[kind] or 0, rot)
end

-- Shortest connected path length (tiles) from west edge at sourceRow to east edge at reactorRow, or nil
function PipeMath.Trace(w: number, h: number, kinds: {string}, rots: {number}, sourceRow: number, reactorRow: number): number?
	local function idx(x, y) return (y - 1) * w + x end
	local function mask(i) return PipeMath.Mask(kinds[i], rots[i]) end
	local start = idx(1, sourceRow)
	if bit32.band(mask(start), PipeMath.W) == 0 then return nil end
	local goal = idx(w, reactorRow)
	local dist = { [start] = 1 }
	local queue, head = { { 1, sourceRow } }, 1
	while queue[head] do
		local x, y = queue[head][1], queue[head][2]
		head += 1
		local i = idx(x, y)
		local m = mask(i)
		if i == goal and bit32.band(m, PipeMath.E) ~= 0 then return dist[i] end
		for _, d in ipairs(PipeMath.Dirs) do
			local nx, ny = x + d.dx, y + d.dy
			if bit32.band(m, d.bit) ~= 0 and nx >= 1 and nx <= w and ny >= 1 and ny <= h then
				local j = idx(nx, ny)
				if not dist[j] and bit32.band(mask(j), d.opp) ~= 0 then
					dist[j] = dist[i] + 1
					table.insert(queue, { nx, ny })
				end
			end
		end
	end
	return nil
end

return PipeMath
