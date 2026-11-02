-- OxygenMixerRules: public mixing model for M02 Oxygen Composition Mixer.
-- Shared by server validator (authoritative) and client UI (live readout). Contains no solutions.
local Rules = {}

Rules.FLOW_MAX = 4
Rules.FilterOrder = { "Eco", "Standard", "Scrub" }
Rules.Filters = {
	Eco = { efficiency = 0.30, power = 1 },
	Standard = { efficiency = 0.50, power = 2 },
	Scrub = { efficiency = 0.75, power = 3 },
}

-- Purity of source i at tick t (Advanced: one source follows a repeating wave the crew can read)
function Rules.Purity(pub, i: number, t: number): number
	local s = pub.sources[i]
	if s.wave then return s.purity + s.wave[(t - 1) % #s.wave + 1] end
	return s.purity
end

-- Pure readout for any setting (no constraint checks)
function Rules.Readout(pub, flows: {number}, filter: string)
	local flow = 0
	for i = 1, #pub.sources do flow += flows[i] end
	local f = Rules.Filters[filter]
	local r = { flow = flow, power = flow + f.power, o2Min = 0, o2Max = 0, contaminant = 0 }
	if flow == 0 then return r end
	local o2Min, o2Max = math.huge, -math.huge
	for t = 1, pub.ticks do
		local o2 = 0
		for i in ipairs(pub.sources) do o2 += flows[i] * Rules.Purity(pub, i, t) end
		o2 /= flow
		o2Min, o2Max = math.min(o2Min, o2), math.max(o2Max, o2)
	end
	local c = 0
	for i, s in ipairs(pub.sources) do c += flows[i] * s.contaminant end
	r.o2Min, r.o2Max = o2Min, o2Max
	r.contaminant = c / flow * (1 - f.efficiency)
	return r
end

-- Returns ok, reasonCode, message, readout
function Rules.Evaluate(pub, flows: {number}, filter: string)
	local r = Rules.Readout(pub, flows, filter)
	if r.flow < pub.minFlow then return false, "LowFlow", ("Total flow %d is below the required %d."):format(r.flow, pub.minFlow), r end
	if r.power > pub.powerBudget then return false, "PowerOver", ("Power draw %d exceeds budget %d."):format(r.power, pub.powerBudget), r end
	if r.o2Min < pub.o2Low - 1e-6 then return false, "O2Low", ("O₂ index drops to %.1f (min %d)."):format(r.o2Min, pub.o2Low), r end
	if r.o2Max > pub.o2High + 1e-6 then return false, "O2High", ("O₂ index peaks at %.1f (max %d)."):format(r.o2Max, pub.o2High), r end
	if r.contaminant > pub.contaminantMax + 1e-6 then
		return false, "Contaminated", ("Contaminants %.1f exceed limit %.1f."):format(r.contaminant, pub.contaminantMax), r
	end
	return true, "OK", "Breathable mix stable. Oxygen generation restored.", r
end

return Rules
