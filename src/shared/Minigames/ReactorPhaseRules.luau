-- ReactorPhaseRules: public coil model for M03 Reactor Phase Equalizer.
-- Shared by server validator (authoritative) and client UI (live readout). Contains no solutions.
local Rules = {}

Rules.STEPS = 12 -- one step = 30°

-- Coupled tier: tuning coil i also shifts coil i+1 (ring), i.e. coil i receives tuning of coil i-1.
function Rules.Phases(pub, tuning: {number}): {number}
	local n, out = #pub.coils, {}
	for i, coil in ipairs(pub.coils) do
		local shift = tuning[i]
		if pub.coupled then shift += tuning[(i - 2) % n + 1] end
		out[i] = (coil.phase + shift) % Rules.STEPS
	end
	return out
end

-- Rotating either direction is allowed; heat counts the shorter way.
function Rules.Distance(t: number): number
	return math.min(t, Rules.STEPS - t)
end

function Rules.Heat(pub, tuning: {number}): number
	local heat = pub.baseHeat
	for i, coil in ipairs(pub.coils) do heat += coil.heatCoeff * Rules.Distance(tuning[i]) end
	return heat
end

-- Returns ok, reasonCode, message, readout { phases, heat, synced }
function Rules.Evaluate(pub, tuning: {number})
	local phases = Rules.Phases(pub, tuning)
	local heat = Rules.Heat(pub, tuning)
	local synced = true
	for i = 2, #phases do if phases[i] ~= phases[1] then synced = false end end
	local r = { phases = phases, heat = heat, synced = synced }
	if not synced then
		local deg = {}
		for _, p in ipairs(phases) do table.insert(deg, (p * 30) .. "°") end
		return false, "OutOfPhase", "Coils out of phase: " .. table.concat(deg, " / ") .. ".", r
	end
	if heat > pub.heatCeiling then
		return false, "Overheat", ("Synchronized, but heat %d exceeds ceiling %d."):format(heat, pub.heatCeiling), r
	end
	return true, "OK", ("Coils synchronized at %d°. Reactor stabilized."):format(phases[1] * 30), r
end

return Rules
