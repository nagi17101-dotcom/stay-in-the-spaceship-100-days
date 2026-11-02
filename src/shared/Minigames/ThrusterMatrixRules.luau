-- ThrusterMatrixRules: public burn model for M07 Thruster Alignment Matrix.
-- Shared by server validator (authoritative) and client UI (live trajectory). Contains no solutions.
local Rules = {}

Rules.MAX_POWER = 2
Rules.PLOT_RANGE = 8 -- diagram shows -8..8 on both axes; generator keeps drift + corridor inside it
-- y points "up" on the diagram
Rules.DIRS = {
	{ id = "N", x = 0, y = 1, fuel = 2 }, { id = "NE", x = 1, y = 1, fuel = 3 },
	{ id = "E", x = 1, y = 0, fuel = 2 }, { id = "SE", x = 1, y = -1, fuel = 3 },
	{ id = "S", x = 0, y = -1, fuel = 2 }, { id = "SW", x = -1, y = -1, fuel = 3 },
	{ id = "W", x = -1, y = 0, fuel = 2 }, { id = "NW", x = -1, y = 1, fuel = 3 },
}

-- Deterministic burn result: endpoint = drift + sum(power_i * dir_i)
function Rules.Readout(pub, powers: {number})
	local x, y, fuel, vib = pub.drift.x, pub.drift.y, 0, 0
	for i, d in ipairs(Rules.DIRS) do
		local p = powers[i]
		x += p * d.x
		y += p * d.y
		fuel += p * d.fuel
		vib += p * p -- concentrated burns shake the hull
	end
	return { x = x, y = y, fuel = fuel, vibration = vib }
end

function Rules.InCorridor(pub, x: number, y: number): boolean
	return math.abs(x - pub.corridor.x) <= pub.corridor.tol and math.abs(y - pub.corridor.y) <= pub.corridor.tol
end

-- Returns ok, reasonCode, message, readout
function Rules.Evaluate(pub, powers: {number})
	local r = Rules.Readout(pub, powers)
	if pub.disabled and powers[pub.disabled] > 0 then
		return false, "NozzleOffline", ("Nozzle %s is offline and cannot fire."):format(Rules.DIRS[pub.disabled].id), r
	end
	if not Rules.InCorridor(pub, r.x, r.y) then
		return false, "OffCorridor", ("Trajectory ends at (%d, %d); corridor is (%d, %d) ±%d."):format(r.x, r.y, pub.corridor.x, pub.corridor.y, pub.corridor.tol), r
	end
	if r.fuel > pub.fuelBudget then return false, "FuelOver", ("Fuel %d exceeds budget %d."):format(r.fuel, pub.fuelBudget), r end
	if r.vibration > pub.vibrationLimit then return false, "Vibration", ("Vibration %d exceeds limit %d — spread the burn."):format(r.vibration, pub.vibrationLimit), r end
	return true, "OK", "Burn plotted inside the corridor. Drive aligned.", r
end

return Rules
