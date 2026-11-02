-- M11 Fabricator Assembly (server-only generator + validator). Rules: Shared.Minigames.FabricatorAssemblyRules.
-- Crafting task: the blueprint targets the most damaged fabricable system the crew can afford.
-- On success materials are debited once (txId "fab:<taskId>") and the part is installed (exactly-once repair).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)
local Rules = require(ReplicatedStorage.Shared.Minigames.FabricatorAssemblyRules)

local FAB = Config.Fabricator
local FabricatorAssembly = {}
FabricatorAssembly.Id = "FabricatorAssembly"
FabricatorAssembly.System = "Cargo"
FabricatorAssembly.RepairAmount = 0 -- repair is applied by Commit to the blueprint's system
FabricatorAssembly.AlwaysAvailable = true

local CONNECTORS = { "BOLT", "CLIP", "PIN", "WELD" }
local LETTERS = { "A", "B", "C", "D", "E" }
local TIERS = {
	Basic = { sockets = 4, decoys = 2, tol = 2, needsMax = 1, minEdges = 2, upgrade = false, heavy = false },
	Advanced = { sockets = 5, decoys = 2, tol = 1, needsMax = 2, minEdges = 4, upgrade = true, heavy = true },
}

local function affordable(items, cost)
	for id, n in pairs(cost) do if (items[id] or 0) < n then return false end end
	return true
end

-- Server context used both by CanOpen and Generate so the offered blueprint is always craftable
function FabricatorAssembly.Context(run)
	local health = {}
	for name, sys in pairs(run.ship.systems) do health[name] = sys.health end
	return { items = table.clone(run.inventory.items), health = health }
end

local function candidates(ctx)
	local list = {}
	for _, bp in ipairs(FAB.Blueprints) do
		if (ctx.health[bp.system] or 100) < FAB.NeedBelow and affordable(ctx.items, bp.cost) then table.insert(list, bp) end
	end
	table.sort(list, function(a, b) return ctx.health[a.system] < ctx.health[b.system] end)
	return list
end

function FabricatorAssembly.CanOpen(run): (boolean, string?)
	local ctx = FabricatorAssembly.Context(run)
	if #candidates(ctx) > 0 then return true end
	for _, bp in ipairs(FAB.Blueprints) do
		if (ctx.health[bp.system] or 100) < FAB.NeedBelow then
			return false, "Not enough materials for any needed blueprint. Salvage or launch the drone first."
		end
	end
	return false, "Power, Cooling, Oxygen and Hull are fine — nothing to fabricate."
end

local function tryGenerate(t, rng, bp, offerUpgrade)
	local n = t.sockets
	local letters = table.clone(LETTERS)
	for i = n, 2, -1 do local j = rng:NextInteger(1, i) letters[i], letters[j] = letters[j], letters[i] end

	local sockets, truth, edges = {}, {}, 0
	local function makeSocket(id)
		local lo = rng:NextInteger(1, 9 - t.tol)
		return { id = id, connector = CONNECTORS[rng:NextInteger(1, #CONNECTORS)], lo = lo, hi = lo + t.tol, needs = {} }
	end
	local function pickNeeds(s, maxIdx, k)
		local pool = {}
		for j = 1, maxIdx do table.insert(pool, sockets[j].id) end
		for _ = 1, math.min(k, #pool) do
			local j = rng:NextInteger(1, #pool)
			table.insert(s.needs, table.remove(pool, j))
		end
	end
	for i = 1, n do -- index i = build order; needs only point to earlier sockets (DAG)
		local s = makeSocket(letters[i])
		sockets[i] = s
		if i > 1 then
			pickNeeds(s, i - 1, rng:NextInteger(0, t.needsMax))
			edges += #s.needs
		end
		truth[i] = { connector = s.connector, size = rng:NextInteger(s.lo, s.hi), mass = rng:NextInteger(1, 3) }
	end
	if edges < t.minEdges then return nil end

	local load = 0
	for _, p in ipairs(truth) do load += p.mass end
	local upgMass = 0
	local parts = table.clone(truth)

	if offerUpgrade then
		local s = makeSocket("R")
		s.optional = true
		sockets[n + 1] = s
		pickNeeds(s, n, rng:NextInteger(1, 2))
		upgMass = rng:NextInteger(1, 2)
		table.insert(parts, { connector = s.connector, size = rng:NextInteger(s.lo, s.hi), mass = upgMass })
	end
	local maxLoad = load + upgMass + rng:NextInteger(0, 1)

	for _ = 1, t.decoys do -- right connector, out of tolerance (or wrong connector if no room)
		local s = sockets[rng:NextInteger(1, n)]
		local size
		if s.hi < 9 and (s.lo <= 1 or rng:NextNumber() < 0.5) then size = math.min(9, s.hi + rng:NextInteger(1, 2))
		elseif s.lo > 1 then size = math.max(1, s.lo - rng:NextInteger(1, 2)) end
		local conn = s.connector
		if not size then
			size = rng:NextInteger(s.lo, s.hi)
			repeat conn = CONNECTORS[rng:NextInteger(1, #CONNECTORS)] until conn ~= s.connector
		end
		table.insert(parts, { connector = conn, size = size, mass = rng:NextInteger(1, 3) })
	end
	if t.heavy then -- fits the socket but breaks the stress test
		local i = rng:NextInteger(1, n)
		local s = sockets[i]
		table.insert(parts, { connector = s.connector, size = rng:NextInteger(s.lo, s.hi), mass = truth[i].mass + upgMass + 2 })
	end

	-- shuffle parts; remember where the true parts went
	local order = {}
	for i = 1, #parts do order[i] = i end
	for i = #order, 2, -1 do local j = rng:NextInteger(1, i) order[i], order[j] = order[j], order[i] end
	local shuffled, where = {}, {}
	for newIdx, oldIdx in ipairs(order) do shuffled[newIdx] = parts[oldIdx] where[oldIdx] = newIdx end

	local steps = {}
	for i = 1, n do table.insert(steps, { socket = sockets[i].id, part = where[i] }) end
	local core = table.clone(steps)
	if offerUpgrade then table.insert(steps, { socket = "R", part = where[n + 1] }) end

	local display = table.clone(sockets)
	table.sort(display, function(a, b) return a.id < b.id end) -- letters hide the build order
	local pub = {
		blueprint = { id = bp.id, name = bp.name, system = bp.system, amount = bp.amount, cost = bp.cost, label = Config.FormatItems(bp.cost) },
		upgrade = offerUpgrade and { cost = FAB.Upgrade.cost, amount = FAB.Upgrade.amount, label = Config.FormatItems(FAB.Upgrade.cost) } or nil,
		maxLoad = maxLoad, sockets = display, parts = shuffled,
	}
	return pub, { steps = steps, core = core }
end

function FabricatorAssembly.Generate(tier: string, seed: number, ctx)
	local t = TIERS[tier] or TIERS.Basic
	local rng0 = Random.new(seed)
	local bp
	if ctx then bp = candidates(ctx)[1] end
	bp = bp or FAB.Blueprints[rng0:NextInteger(1, #FAB.Blueprints)]
	local offerUpgrade = t.upgrade
	if offerUpgrade and ctx then
		local total = table.clone(bp.cost)
		for id, k in pairs(FAB.Upgrade.cost) do total[id] = (total[id] or 0) + k end
		offerUpgrade = affordable(ctx.items, total)
	end
	for attempt = 0, 299 do
		local pub, priv = tryGenerate(t, Random.new(seed + attempt * 73856093), bp, offerUpgrade)
		if pub then return pub, priv end
	end
	error("FabricatorAssembly: no layout for seed " .. seed)
end

function FabricatorAssembly.ValidateShape(pub, action): boolean
	if type(action) ~= "table" or type(action.steps) ~= "table" or #action.steps > #pub.sockets then return false end
	for _, st in ipairs(action.steps) do
		if type(st) ~= "table" or type(st.socket) ~= "string" or #st.socket > 2 then return false end
		local p = st.part
		if type(p) ~= "number" or p % 1 ~= 0 or p < 1 or p > #pub.parts then return false end
	end
	return true
end

function FabricatorAssembly.Validate(pub, _priv, action)
	local ok, reason, message = Rules.Evaluate(pub, action.steps)
	return ok, reason, message
end

function FabricatorAssembly.CheckSolvable(pub, priv): boolean
	return (Rules.Evaluate(pub, priv.steps)) and (Rules.Evaluate(pub, priv.core))
end

-- Called by TaskService after Validate succeeds: debit materials, install the part. Fails closed if stock changed.
function FabricatorAssembly.Commit(run, player, pub, action, taskId: string)
	local _, _, _, st = Rules.Evaluate(pub, action.steps)
	local cost = Rules.TotalCost(pub, st.upgrade)
	if not run.inventory:TryDebit(cost, "fab:" .. taskId) then
		return false, "Materials", "Not enough materials: needs " .. Config.FormatItems(cost) .. "."
	end
	local bp = pub.blueprint
	local amount = bp.amount + (st.upgrade and pub.upgrade.amount or 0)
	run.ship:ApplyRepair(bp.system, amount, "fab:" .. taskId)
	Remotes.Get(Remotes.Names.Alert):FireAllClients({ severity = "Info",
		text = ("%s fabricated %s%s → %s +%d"):format(player.DisplayName, bp.name, st.upgrade and " (reinforced)" or "", bp.system, amount) })
	return true
end

return FabricatorAssembly
