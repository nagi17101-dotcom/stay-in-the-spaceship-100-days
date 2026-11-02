-- M09 Drone Salvage Planner (server-only generator + validator). Rules: Shared.Minigames.DroneSalvageRules.
-- Resource task: no system repair. Loot is credited by the server after a visible return delay, once per task id.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)
local Rules = require(ReplicatedStorage.Shared.Minigames.DroneSalvageRules)

local DroneSalvage = {}
DroneSalvage.Id = "DroneSalvage"
DroneSalvage.System = "Cargo"
DroneSalvage.RepairAmount = 0
DroneSalvage.AlwaysAvailable = true -- not a repair: open even when Cargo is healthy
DroneSalvage.RETURN_SECONDS = 8

local LOOT = {
	{ ScrapAlloy = 2 }, { SealantFoam = 1, ScrapAlloy = 1 }, { FilterMembrane = 1 },
	{ CoolantCartridge = 1 }, { ConductiveFilament = 1 }, { ScrapAlloy = 3 },
}
local TIERS = {
	Basic = { size = 9, targets = 3, hazards = 6, pulsing = 0, capacity = 2, slack = 4, priority = false },
	Advanced = { size = 9, targets = 4, hazards = 7, pulsing = 5, capacity = 2, slack = 2, priority = true },
}
local DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

-- BFS over (x, y, parity, pickedMask): shortest route that returns to dock satisfying the requirement
local function solve(pub)
	local n = #pub.targets
	local start = { pub.dock[1], pub.dock[2], 0, 0 }
	local function sid(x, y, p, m) return ((x * 32 + y) * 2 + p) * 64 + m end
	local seen = { [sid(start[1], start[2], 0, 0)] = true }
	local queue, head = { { x = start[1], y = start[2], step = 0, mask = 0, path = {} } }, 1
	while queue[head] do
		local s = queue[head] head += 1
		if s.step > 0 and s.x == pub.dock[1] and s.y == pub.dock[2] then
			local ok = Rules.Evaluate(pub, s.path)
			if ok then return s.path end
		end
		if s.step < 40 then
			for _, d in ipairs(DIRS) do
				local nx, ny, step = s.x + d[1], s.y + d[2], s.step + 1
				if nx >= 1 and ny >= 1 and nx <= pub.size and ny <= pub.size and not Rules.HazardAt(pub, nx, ny, step) then
					local mask = s.mask
					local count = 0
					for i = 1, n do if bit32.btest(mask, bit32.lshift(1, i - 1)) then count += 1 end end
					for i, t in ipairs(pub.targets) do
						if t.x == nx and t.y == ny and not bit32.btest(mask, bit32.lshift(1, i - 1)) and count < pub.capacity then
							mask = bit32.bor(mask, bit32.lshift(1, i - 1))
						end
					end
					local id = sid(nx, ny, step % 2, mask)
					if not seen[id] then
						seen[id] = true
						local path = table.clone(s.path)
						table.insert(path, { nx, ny })
						table.insert(queue, { x = nx, y = ny, step = step, mask = mask, path = path })
					end
				end
			end
		end
	end
	return nil
end

local function tryGenerate(t, rng)
	local size = t.size
	local dock = { math.ceil(size / 2), size }
	local used = { [Rules.Key(dock[1], dock[2])] = true }
	-- keep the cell above the dock clear so the drone can always launch
	used[Rules.Key(dock[1], dock[2] - 1)] = true
	local function freeCell(minY)
		for _ = 1, 100 do
			local x, y = rng:NextInteger(1, size), rng:NextInteger(minY or 1, size)
			local k = Rules.Key(x, y)
			if not used[k] then used[k] = true return x, y end
		end
	end
	local pub = { size = size, dock = dock, capacity = t.capacity, targets = {}, hazards = {}, pulsing = {} }
	for i = 1, t.targets do
		local x, y = freeCell(1)
		if not x then return nil end
		local loot = LOOT[rng:NextInteger(1, #LOOT)]
		table.insert(pub.targets, { x = x, y = y, loot = loot, label = Config.FormatItems(loot) })
	end
	for _ = 1, t.hazards do local x, y = freeCell(1) if not x then return nil end table.insert(pub.hazards, { x, y }) end
	for _ = 1, t.pulsing do local x, y = freeCell(1) if not x then return nil end table.insert(pub.pulsing, { x, y }) end
	if t.priority then pub.priority = rng:NextInteger(1, #pub.targets) end

	pub.fuel = 99
	local best = solve(pub)
	pub.hazardSet = nil -- cache built during solve; not part of the public payload
	pub.pulseSet = nil
	if not best or #best < 4 then return nil end
	pub.fuel = #best + t.slack
	return pub, { path = best }
end

function DroneSalvage.Generate(tier: string, seed: number)
	local t = TIERS[tier] or TIERS.Basic
	for attempt = 0, 299 do
		local pub, priv = tryGenerate(t, Random.new(seed + attempt * 86028121))
		if pub then return pub, priv end
	end
	error("DroneSalvage: no layout for seed " .. seed)
end

-- One launch per cycle, and not while the cargo receiver is jammed
function DroneSalvage.CanOpen(run): (boolean, string?)
	if run.droneLaunchDay == run.day.day then return false, "The drone already flew this cycle. Next launch available next day." end
	for _, inc in ipairs(run.director and run.director.active or {}) do
		if inc.template.id == "ReceiverJam" then return false, "Cargo receiver jammed — clear it before launching the drone." end
	end
	return true
end

function DroneSalvage.ValidateShape(pub, action): boolean
	if type(action) ~= "table" or type(action.path) ~= "table" or #action.path == 0 or #action.path > 60 then return false end
	for _, c in ipairs(action.path) do
		if type(c) ~= "table" then return false end
		for i = 1, 2 do
			local v = c[i]
			if type(v) ~= "number" or v % 1 ~= 0 or v < 0 or v > pub.size + 1 then return false end
		end
	end
	return true
end

function DroneSalvage.Validate(pub, _priv, action)
	local ok, reason, message = Rules.Evaluate(pub, action.path)
	return ok, reason, message
end

function DroneSalvage.CheckSolvable(pub, priv): boolean
	return (Rules.Evaluate(pub, priv.path))
end

-- Called by TaskService after a validated success. Loot arrives after a visible return trip.
function DroneSalvage.OnSuccess(run, player, pub, action, taskId: string)
	run.droneLaunchDay = run.day.day
	local r = Rules.Simulate(pub, action.path)
	local loot = {}
	for _, i in ipairs(r.picked) do
		for id, n in pairs(pub.targets[i].loot) do loot[id] = (loot[id] or 0) + n end
	end
	local runId = run.runId
	Remotes.Get(Remotes.Names.Alert):FireAllClients({ severity = "Info", text = ("Drone launched by %s — returning in %ds."):format(player.DisplayName, DroneSalvage.RETURN_SECONDS) })
	task.delay(DroneSalvage.RETURN_SECONDS, function()
		if run.runId ~= runId or run.day:IsTerminal() and run.day.phase ~= "Vote" then return end
		if run.inventory:Credit(loot, "drone:" .. taskId) then
			run.recordStat(player, "salvage", 1)
			Remotes.Get(Remotes.Names.Alert):FireAllClients({ severity = "Info", text = "Drone docked: +" .. Config.FormatItems(loot) })
		end
	end)
end

return DroneSalvage
