-- M02 Oxygen Composition Mixer (server-only generator + validator). Rules: Shared.Minigames.OxygenMixerRules.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage.Shared.Minigames.OxygenMixerRules)

local OxygenMixer = {}
OxygenMixer.Id = "OxygenMixer"
OxygenMixer.System = "Oxygen"
OxygenMixer.RepairAmount = 30

local ARCHETYPES = {
	{ id = "Electrolysis", label = "Electrolysis O₂", purity = { 88, 97 }, contaminant = { 1, 3 } },
	{ id = "Recycler", label = "Cabin Recycler", purity = { 14, 20 }, contaminant = { 9, 15 } },
	{ id = "Buffer", label = "N₂ Buffer Tank", purity = { 0, 4 }, contaminant = { 0, 2 } },
}
local TIERS = {
	Basic = { ticks = 1, wave = nil, maxValid = 40 },
	Advanced = { ticks = 6, wave = { 3, 6 }, maxValid = 20 },
}

local SETTINGS = {}
for a = 0, Rules.FLOW_MAX do for b = 0, Rules.FLOW_MAX do for c = 0, Rules.FLOW_MAX do
	for _, filter in ipairs(Rules.FilterOrder) do table.insert(SETTINGS, { flows = { a, b, c }, filter = filter }) end
end end end

local function countValid(pub)
	local n = 0
	for _, s in ipairs(SETTINGS) do
		if Rules.Evaluate(pub, s.flows, s.filter) then n += 1 end
	end
	return n
end

local function tryGenerate(t, rng)
	local sources = {}
	for _, a in ipairs(ARCHETYPES) do
		table.insert(sources, {
			id = a.id, label = a.label,
			purity = rng:NextInteger(a.purity[1], a.purity[2]),
			contaminant = rng:NextInteger(a.contaminant[1], a.contaminant[2]),
		})
	end
	for i = #sources, 2, -1 do local j = rng:NextInteger(1, i) sources[i], sources[j] = sources[j], sources[i] end
	if t.wave then
		for _, s in ipairs(sources) do
			if s.id == "Recycler" then
				local amp = rng:NextInteger(t.wave[1], t.wave[2])
				s.wave = {}
				for k = 1, t.ticks do s.wave[k] = rng:NextInteger(-amp, amp) end
			end
		end
	end
	local probe = { sources = sources, ticks = t.ticks }

	-- Pick a realistic target mix, then derive constraints around it
	local candidates = {}
	for _, s in ipairs(SETTINGS) do
		local r = Rules.Readout(probe, s.flows, s.filter)
		if r.flow >= 3 and r.o2Min >= 16 and r.o2Max <= 28 then table.insert(candidates, { s = s, r = r }) end
	end
	if #candidates == 0 then return nil end
	local pick = candidates[rng:NextInteger(1, #candidates)]
	local r = pick.r
	local pub = {
		sources = sources,
		ticks = t.ticks,
		o2Low = math.floor(r.o2Min) - rng:NextInteger(1, 2),
		o2High = math.ceil(r.o2Max) + rng:NextInteger(1, 2),
		contaminantMax = math.ceil(r.contaminant * 2) / 2 + 0.5 * rng:NextInteger(0, 1),
		minFlow = math.max(2, r.flow - rng:NextInteger(0, 1)),
		powerBudget = r.power + rng:NextInteger(0, 1),
		flowMax = Rules.FLOW_MAX,
	}
	local valid = countValid(pub)
	if valid < 1 or valid > t.maxValid then return nil end
	if Rules.Evaluate(pub, { 0, 0, 0 }, "Standard") then return nil end
	if Rules.Evaluate(pub, { 4, 4, 4 }, "Scrub") then return nil end -- "max everything" must not work
	return pub, { flows = table.clone(pick.s.flows), filter = pick.s.filter, validCount = valid }
end

function OxygenMixer.Generate(tier: string, seed: number)
	local t = TIERS[tier] or TIERS.Basic
	for attempt = 0, 299 do
		local pub, priv = tryGenerate(t, Random.new(seed + attempt * 104729))
		if pub then return pub, priv end
	end
	error("OxygenMixer: no layout for seed " .. seed)
end

function OxygenMixer.ValidateShape(pub, action): boolean
	if type(action) ~= "table" or type(action.flows) ~= "table" or type(action.filter) ~= "string" then return false end
	if not Rules.Filters[action.filter] or #action.flows ~= #pub.sources then return false end
	for i = 1, #pub.sources do
		local v = action.flows[i]
		if type(v) ~= "number" or v % 1 ~= 0 or v < 0 or v > Rules.FLOW_MAX then return false end
	end
	return true
end

function OxygenMixer.Validate(pub, _priv, action)
	local ok, reason, message = Rules.Evaluate(pub, action.flows, action.filter)
	return ok, reason, message
end

function OxygenMixer.CheckSolvable(pub, priv): boolean
	return (Rules.Evaluate(pub, priv.flows, priv.filter))
end

return OxygenMixer
