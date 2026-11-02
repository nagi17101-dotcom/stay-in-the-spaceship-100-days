-- M04 Power Bus Allocator (server-only generator + validator)
local PowerBus = {}
PowerBus.Id = "PowerBus"
PowerBus.System = "Power"
PowerBus.RepairAmount = 35

local LOAD_POOL = {
	{ id = "LifeSupport", label = "Life Support", critical = true },
	{ id = "Shields", label = "Shields" },
	{ id = "Fabricator", label = "Fabricator" },
	{ id = "Scanner", label = "Scanner" },
	{ id = "Drive", label = "Drive Coils" },
	{ id = "Comms", label = "Comms" },
}
local TIERS = {
	Basic = { loads = 3, channels = 2, damaged = 0 },
	Advanced = { loads = 5, channels = 3, damaged = 1 },
}

local function shuffle(t, rng)
	for i = #t, 2, -1 do local j = rng:NextInteger(1, i) t[i], t[j] = t[j], t[i] end
end

function PowerBus.Generate(tier: string, seed: number)
	local rng = Random.new(seed)
	local t = TIERS[tier] or TIERS.Basic
	local pool = {}
	for i = 2, #LOAD_POOL do table.insert(pool, LOAD_POOL[i]) end
	shuffle(pool, rng)

	local loads = { { id = LOAD_POOL[1].id, label = LOAD_POOL[1].label, critical = true, demand = rng:NextInteger(3, 5) } }
	for i = 1, t.loads - 1 do
		table.insert(loads, { id = pool[i].id, label = pool[i].label, critical = false, demand = rng:NextInteger(2, 5) })
	end

	local channels = {}
	for i = 1, t.channels do channels[i] = { id = string.char(64 + i), capacity = 0, damaged = false } end
	if t.damaged > 0 then channels[rng:NextInteger(1, t.channels)].damaged = true end
	local live, used = {}, {}
	for i, c in ipairs(channels) do if not c.damaged then table.insert(live, i) used[i] = 0 end end

	-- Build a known-valid solution, then derive capacities around it (puzzle always solvable)
	local nonCrit = {}
	for i = 2, #loads do table.insert(nonCrit, i) end
	shuffle(nonCrit, rng)
	local offCount = math.max(1, math.floor(#nonCrit / 3))
	local powered = { 1 }
	for k = offCount + 1, #nonCrit do table.insert(powered, nonCrit[k]) end

	local solution, total = {}, 0
	for _, li in ipairs(powered) do
		local ch = live[rng:NextInteger(1, #live)]
		solution[loads[li].id] = ch
		used[ch] += loads[li].demand
		total += loads[li].demand
	end
	for _, l in ipairs(loads) do solution[l.id] = solution[l.id] or 0 end
	for _, ch in ipairs(live) do channels[ch].capacity = math.max(2, used[ch] + rng:NextInteger(0, 1)) end

	local all = 0
	for _, l in ipairs(loads) do all += l.demand end
	local generator = math.min(total + rng:NextInteger(0, 1), all - 1)

	return { generator = generator, loads = loads, channels = channels }, { solution = solution }
end

function PowerBus.ValidateShape(pub, action): boolean
	if type(action) ~= "table" or type(action.assignments) ~= "table" then return false end
	local count = 0
	for k, v in pairs(action.assignments) do
		count += 1
		if type(k) ~= "string" or type(v) ~= "number" or v % 1 ~= 0 or v < 0 or v > #pub.channels then return false end
	end
	for _, l in ipairs(pub.loads) do if action.assignments[l.id] == nil then return false end end
	return count == #pub.loads
end

function PowerBus.Validate(pub, _priv, action)
	local a = action.assignments
	local usage, total = {}, 0
	for _, l in ipairs(pub.loads) do
		local ch = a[l.id]
		if l.critical and ch == 0 then return false, "CriticalUnpowered", l.label .. " must stay powered." end
		if ch > 0 then
			local c = pub.channels[ch]
			if c.damaged then return false, "LineDamaged", "Bus " .. c.id .. " is damaged — breaker tripped." end
			usage[ch] = (usage[ch] or 0) + l.demand
			total += l.demand
		end
	end
	for i, u in pairs(usage) do
		local c = pub.channels[i]
		if u > c.capacity then return false, "Overload", ("Bus %s overloaded (%dA / %dA) — breaker tripped."):format(c.id, u, c.capacity) end
	end
	if total > pub.generator then return false, "GeneratorOverdraw", ("Generator overdrawn (%dA / %dA)."):format(total, pub.generator) end
	return true, "OK", "Power distribution restored."
end

function PowerBus.CheckSolvable(pub, priv): boolean
	return (PowerBus.Validate(pub, priv, { assignments = priv.solution }))
end

return PowerBus
