-- ShieldResonanceRules: public spectrum model for M10 Shield Resonance.
-- Shared by server validator (authoritative) and client UI (live coverage). Contains no solutions.
local Rules = {}

Rules.BANDS = 12
-- type: "Kinetic" covers meteor, "Ionic" covers ion, "Hybrid" covers both, "Capacitor" adds power (cost < 0), no range
Rules.Covers = { Kinetic = { meteor = true }, Ionic = { ion = true }, Hybrid = { meteor = true, ion = true }, Capacitor = {} }

-- placements: { { slot, emitter, start } } ; returns readout { covered = {band -> bool}, overlap = n, power = n, slotsUsed = n } or nil, reason, message
function Rules.Readout(pub, placements)
	local usedEmitter, usedSlot = {}, {}
	local layer = table.create(Rules.BANDS, 0)
	local power = 0
	local coveredBy = {}
	for _, p in ipairs(placements) do
		local e = pub.emitters[p.emitter]
		if not e then return nil, "BadEmitter", "Unknown emitter." end
		if usedEmitter[p.emitter] then return nil, "Duplicate", "Each emitter can be armed once." end
		usedEmitter[p.emitter] = true
		if p.slot < 1 or p.slot > pub.slots then return nil, "BadSlot", "No such harmonic slot." end
		if usedSlot[p.slot] then return nil, "SlotTaken", "Two emitters in one harmonic slot." end
		if pub.disabledSlot == p.slot then return nil, "SlotOffline", ("Harmonic slot %d is offline."):format(p.slot) end
		usedSlot[p.slot] = true
		power += e.cost
		if e.width > 0 then
			local last = p.start + e.width - 1
			if p.start < 1 or last > Rules.BANDS then return nil, "OffSpectrum", "An emitter range leaves the spectrum." end
			for b = p.start, last do
				layer[b] += 1
				coveredBy[b] = coveredBy[b] or {}
				table.insert(coveredBy[b], e.type)
			end
		end
	end
	local overlap = 0
	for b = 1, Rules.BANDS do if layer[b] > 1 then overlap += 1 end end
	return { coveredBy = coveredBy, overlap = overlap, power = power, slotsUsed = #placements }
end

function Rules.BandProtected(r, band: number, kind: string): boolean
	for _, t in ipairs(r.coveredBy[band] or {}) do
		if Rules.Covers[t][kind] then return true end
	end
	return false
end

-- Returns ok, reasonCode, message, readout
function Rules.Evaluate(pub, placements)
	local r, reason, message = Rules.Readout(pub, placements)
	if not r then return false, reason, message, nil end
	local open = 0
	for _, th in ipairs(pub.threats) do
		for b = th.from, th.to do
			if not Rules.BandProtected(r, b, th.kind) then open += 1 end
		end
	end
	if open > 0 then return false, "Uncovered", ("%d threat band(s) still unshielded."):format(open), r end
	if r.power > pub.powerBudget then return false, "PowerOver", ("Emitters draw %d power; budget %d."):format(r.power, pub.powerBudget), r end
	if pub.heatLimit and r.overlap > pub.heatLimit then
		return false, "Overheat", ("%d overlapping band(s) overheat the array (limit %d)."):format(r.overlap, pub.heatLimit), r
	end
	return true, "OK", "Shield harmonics locked. Threat spectrum covered.", r
end

return Rules
