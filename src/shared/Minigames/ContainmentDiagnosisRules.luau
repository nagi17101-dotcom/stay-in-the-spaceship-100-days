-- M12 Containment Diagnosis rules (shared: symptom chart for the client + server validation).
-- pub = { compartments = { {name, readings = { [sensor] = {v = -1|0|1, val, state = "OK"|"STALE"|"OFF"} }} }, blocked = {fix, reason}? }
-- action = { isolate = {compartmentIndex...}, cause = causeId, fix = fixId }
-- A fault is identified by BOTH of its signature sensors reading fresh (OK) in the right direction,
-- with every other fresh sensor in that compartment nominal. Stale sensors and single anomalies are spillover.
local Rules = {}

Rules.SENSORS = {
	{ id = "PRES", name = "Pressure", nom = 101, delta = 28, unit = "kPa" },
	{ id = "TEMP", name = "Temp", nom = 22, delta = 14, unit = "°C" },
	{ id = "CO2", name = "CO₂", nom = 4, delta = 3, unit = "‰" },
	{ id = "FLOW", name = "Flow", nom = 12, delta = 6, unit = "L/s" },
}

Rules.CAUSES = {
	{ id = "Leak", name = "Seal leak", sig = { PRES = -1, FLOW = 1 }, fixes = { "SEAL", "REPRESSURIZE" } },
	{ id = "Scrubber", name = "Scrubber failure", sig = { CO2 = 1, FLOW = -1 }, fixes = { "SWAP_FILTER", "PURGE" } },
	{ id = "PumpHeat", name = "Pump overheat", sig = { TEMP = 1, FLOW = -1 }, fixes = { "COOLANT_FLUSH", "THROTTLE" } },
	{ id = "Contamination", name = "Contamination", sig = { CO2 = 1, TEMP = 1 }, fixes = { "PURGE", "VENT_HEAT" } },
	{ id = "ValveStuck", name = "Stuck valve", sig = { PRES = 1, FLOW = -1 }, fixes = { "CYCLE_VALVE", "THROTTLE" } },
}

Rules.FIXES = {
	{ id = "SEAL", name = "Seal breach" }, { id = "REPRESSURIZE", name = "Repressurize" },
	{ id = "SWAP_FILTER", name = "Swap filter" }, { id = "PURGE", name = "Atmos purge" },
	{ id = "COOLANT_FLUSH", name = "Coolant flush" }, { id = "THROTTLE", name = "Throttle pump" },
	{ id = "VENT_HEAT", name = "Heat vent" }, { id = "CYCLE_VALVE", name = "Cycle valve" },
}

function Rules.Cause(id)
	for _, c in ipairs(Rules.CAUSES) do if c.id == id then return c end end
	return nil
end

function Rules.FixName(id)
	for _, f in ipairs(Rules.FIXES) do if f.id == id then return f.name end end
	return tostring(id)
end

function Rules.SigText(cause)
	local parts = {}
	for _, s in ipairs(Rules.SENSORS) do
		local d = cause.sig[s.id]
		if d then table.insert(parts, s.id .. (d > 0 and "▲" or "▼")) end
	end
	return table.concat(parts, " ")
end

function Rules.Consistent(comp, cause): boolean
	for _, s in ipairs(Rules.SENSORS) do
		local r = comp.readings[s.id]
		local want = cause.sig[s.id]
		if want then
			if r.state ~= "OK" or r.v ~= want then return false end
		elseif r.state == "OK" and r.v ~= 0 then
			return false
		end
	end
	return true
end

-- Every (compartment, cause) pair the readings support; a fair puzzle has exactly one.
function Rules.Candidates(pub)
	local out = {}
	for i, comp in ipairs(pub.compartments) do
		for _, cause in ipairs(Rules.CAUSES) do
			if Rules.Consistent(comp, cause) then table.insert(out, { index = i, cause = cause.id }) end
		end
	end
	return out
end

function Rules.Evaluate(pub, action)
	local cands = Rules.Candidates(pub)
	if #cands ~= 1 then return false, "Ambiguous", "Sensor data inconclusive." end
	local root = cands[1]
	local iso = {}
	for _, i in ipairs(action.isolate) do iso[i] = true end
	if not next(iso) then return false, "NoIsolation", "Isolate the faulty compartment first." end
	for i in pairs(iso) do
		if i ~= root.index then
			local name = pub.compartments[i] and pub.compartments[i].name or "?"
			return false, "Unsafe", ("Unsafe: isolating %s cuts air to a compartment with no confirmed fault."):format(name)
		end
	end
	if not iso[root.index] then return false, "WrongCompartment", "Wrong compartment isolated — cascade continues." end
	if action.cause ~= root.cause then return false, "WrongCause", "Diagnosis does not match the readings in the isolated compartment." end
	if pub.blocked and action.fix == pub.blocked.fix then
		return false, "Blocked", ("%s unavailable: %s."):format(Rules.FixName(action.fix), pub.blocked.reason)
	end
	local cause = Rules.Cause(root.cause)
	if not table.find(cause.fixes, action.fix) then
		return false, "WrongFix", ("%s does not address %s."):format(Rules.FixName(action.fix), string.lower(cause.name))
	end
	return true, "Contained", ("%s contained in %s."):format(cause.name, pub.compartments[root.index].name)
end

return Rules
