-- SignalTriangulatorRules: public geometry for M06 Signal Triangulator.
-- Shared by server validator (authoritative) and client UI (confidence arcs). Contains no solutions.
local Rules = {}

-- Rounded Euclidean distance in grid cells
function Rules.Distance(ax: number, ay: number, bx: number, by: number): number
	local dx, dy = ax - bx, ay - by
	return math.floor(math.sqrt(dx * dx + dy * dy) + 0.5)
end

-- Is cell (x, y) consistent with antenna i's reading (reading ± band)?
function Rules.OnArc(pub, i: number, x: number, y: number): boolean
	local a = pub.antennas[i]
	return math.abs(Rules.Distance(a.x, a.y, x, y) - a.reading) <= pub.band
end

-- Returns ok, reasonCode, message
function Rules.Evaluate(pub, x: number, y: number)
	if x < 1 or x > pub.size or y < 1 or y > pub.size then return false, "OffGrid", "Selected cell is outside the sector grid." end
	for i, a in ipairs(pub.antennas) do
		if not Rules.OnArc(pub, i, x, y) then
			return false, "ArcMismatch", ("Antenna %s rejects that cell: expects range %d%s, cell is %d."):format(
				a.id, a.reading, pub.band > 0 and ("±" .. pub.band) or "", Rules.Distance(a.x, a.y, x, y))
		end
	end
	return true, "OK", "Beacon source locked. Comms array realigned."
end

return Rules
