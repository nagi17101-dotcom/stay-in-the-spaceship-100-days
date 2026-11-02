-- DroneSalvageRules: public flight model for M09 Drone Salvage Planner.
-- Shared by server validator (authoritative) and client UI (live route preview). Contains no solutions.
local Rules = {}

local function key(x, y) return x .. "," .. y end
Rules.Key = key

-- Pulsing hazards are active on odd steps (1, 3, 5, ...)
function Rules.HazardAt(pub, x: number, y: number, step: number): string?
	local k = key(x, y)
	if pub.hazardSet == nil then
		pub.hazardSet, pub.pulseSet = {}, {}
		for _, c in ipairs(pub.hazards) do pub.hazardSet[key(c[1], c[2])] = true end
		for _, c in ipairs(pub.pulsing or {}) do pub.pulseSet[key(c[1], c[2])] = true end
	end
	if pub.hazardSet[k] then return "static" end
	if pub.pulseSet[k] and step % 2 == 1 then return "pulse" end
	return nil
end

-- Simulates a route (list of cells after the dock). Returns readout.
-- readout = { steps, picked = {targetIndex...}, atDock, crash = {step, x, y, kind}?, invalid = msg? }
function Rules.Simulate(pub, path)
	local r = { steps = #path, picked = {}, atDock = false }
	local x, y = pub.dock[1], pub.dock[2]
	local taken = {}
	for step, c in ipairs(path) do
		local nx, ny = c[1], c[2]
		if math.abs(nx - x) + math.abs(ny - y) ~= 1 then r.invalid = ("Step %d is not adjacent to the previous cell."):format(step) return r end
		if nx < 1 or ny < 1 or nx > pub.size or ny > pub.size then r.invalid = "Route leaves the scanner field." return r end
		x, y = nx, ny
		local hz = Rules.HazardAt(pub, x, y, step)
		if hz then r.crash = { step = step, x = x, y = y, kind = hz } return r end
		for i, t in ipairs(pub.targets) do
			if t.x == x and t.y == y and not taken[i] and #r.picked < pub.capacity then
				taken[i] = true
				table.insert(r.picked, i)
			end
		end
	end
	r.atDock = (#path > 0 and x == pub.dock[1] and y == pub.dock[2])
	return r
end

-- Returns ok, reasonCode, message, readout
function Rules.Evaluate(pub, path)
	local r = Rules.Simulate(pub, path)
	if r.invalid then return false, "BadRoute", r.invalid, r end
	if r.crash then
		return false, "Hazard", ("Drone destroyed at step %d by a %s hazard."):format(r.crash.step, r.crash.kind == "pulse" and "pulsing" or "debris"), r
	end
	if r.steps > pub.fuel then return false, "NoFuel", ("Route needs %d fuel; drone has %d."):format(r.steps, pub.fuel), r end
	if not r.atDock then return false, "NotReturned", "The drone must end its route back at the dock.", r end
	if #r.picked == 0 then return false, "EmptyHold", "The drone returned empty.", r end
	if pub.priority then
		local got = false
		for _, i in ipairs(r.picked) do if i == pub.priority then got = true end end
		if not got then return false, "MissedPriority", "The priority salvage (★) was not recovered.", r end
	end
	return true, "OK", ("Route approved: %d salvage target(s), %d fuel."):format(#r.picked, r.steps), r
end

return Rules
