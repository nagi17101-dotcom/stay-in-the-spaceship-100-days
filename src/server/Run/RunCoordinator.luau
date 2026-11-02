-- RunCoordinator: owns one voyage (run id, crew, ship, day cycle, inventory, rewards),
-- launches from the lobby party, places characters, handles disconnect/rejoin, emergency, loss, return.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)
local Server = script.Parent.Parent
local ShipStateService = require(Server.ShipSimulation.ShipStateService)
local DayCycleService = require(Server.DayCycle.DayCycleService)
local InventoryService = require(Server.Inventory.InventoryService)
local RunRewards = require(Server.Progression.RunRewards)
local TaskService = require(Server.Tasks.TaskService)
local RoomLightingService = require(Server.World.RoomLightingService)
local SalvageService = require(Server.World.SalvageService)
local QuickActionService = require(Server.World.QuickActionService)
local LobbyPartyService = require(Server.LobbyMatchmaking.LobbyPartyService)

local N = Remotes.Names
local RunCoordinator = {}
local run
local ABANDON_SECONDS = 60 -- run aborts if no crew member is connected for this long

local function crewPlayers()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if run.crew[p.UserId] then table.insert(list, p) end
	end
	return list
end

local function inVoyage(player): boolean
	return run.crew[player.UserId] == true and run.day.phase ~= "Lobby"
end

local function currentObjective(): string
	if run.emergency then return Config.EmergencyObjectives[run.emergency.reason] or "EMERGENCY" end
	local worst = run.ship:GetWorstSystem()
	if worst and not run.day:IsTerminal() and run.day.phase ~= "Lobby" then
		return Config.SystemObjectives[worst]
	end
	return Config.PhaseObjectives[run.day.phase] or ""
end

local function buildSnapshot()
	return {
		runId = run.runId,
		revision = run.ship.revision,
		difficulty = run.difficulty,
		phaseInfo = run.day:GetInfo(),
		systems = run.ship:Serialize(),
		objective = currentObjective(),
		materials = run.inventory:Snapshot(),
		emergency = run.emergency,
	}
end

local function alertAll(severity: string, system: string?, text: string)
	Remotes.Get(N.Alert):FireAllClients({ severity = severity, system = system, text = text })
end

-- Character placement with verification + retry (teleport failure recovery)
local function spawnCFrame(player): CFrame?
	local target = inVoyage(player) and workspace.Ship:FindFirstChild("CrewSpawn")
		or (workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("LobbySpawn"))
	if not target then return nil end
	local jitter = Vector3.new(run.rng:NextNumber(-2, 2), 3.5, run.rng:NextNumber(-2, 2))
	return target.CFrame + jitter
end

local function placeCharacter(player: Player)
	task.spawn(function()
		for attempt = 1, 3 do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local cf = spawnCFrame(player)
			if not cf then return end
			if root then
				char:PivotTo(cf)
				task.wait(0.5)
				if player.Character == char and root.Parent and (root.Position - cf.Position).Magnitude < 25 then return end
			else
				task.wait(0.5)
			end
			warn(("[Run] placement retry %d for %s"):format(attempt, player.Name))
		end
		if player.Parent then player:LoadCharacter() end -- last resort: CharacterAdded places again
	end)
end

local function setEmergency(reason: string?)
	if reason then
		if run.emergency and run.emergency.reason == reason then return end
		local grace = Config.CatastropheGraceSeconds * run.ship.tuning.graceFactor
		run.emergency = { reason = reason, endsAt = workspace:GetServerTimeNow() + grace }
		alertAll("Critical", nil, "EMERGENCY — " .. Config.EmergencyObjectives[reason])
	else
		if not run.emergency then return end
		run.emergency = nil
		alertAll("Info", nil, "Emergency averted. Ship stabilizing.")
	end
	Remotes.Get(N.Emergency):FireAllClients(run.emergency or { active = false })
end

local function resetState()
	run.runId = HttpService:GenerateGUID(false)
	run.seed = math.floor(os.clock() * 1000) % 2147483647
	run.rng = Random.new(run.seed)
	run.lossReason = nil
	run.emergency = nil
	run.noCrewSince = nil
	run.lossToken = (run.lossToken or 0) + 1
	Remotes.Get(N.Emergency):FireAllClients({ active = false })
	run.ship:Reset()
	run.inventory:Reset()
	run.rewards:Reset()
end

function RunCoordinator.ReturnToLobby(reason: string)
	local wasCrew = crewPlayers()
	resetState()
	run.crew = {}
	run.day:Reset()
	for _, p in ipairs(wasCrew) do placeCharacter(p) end
	Remotes.Get(N.StateSnapshot):FireAllClients(buildSnapshot())
	LobbyPartyService.OnRunEnded()
	print(("[Run] Returned to lobby (%s)"):format(reason))
end

function RunCoordinator.Launch(players: {Player}, difficulty: string)
	if run.day.phase ~= "Lobby" or #players == 0 then return false end
	run.difficulty = Config.Difficulty[difficulty] and difficulty or Config.DefaultDifficulty
	run.ship:SetDifficulty(run.difficulty)
	run.inventory.factor = run.ship.tuning.startingResourcesFactor
	resetState()
	run.crew = {}
	for _, p in ipairs(players) do run.crew[p.UserId] = true end
	run.day:Begin()
	for _, p in ipairs(players) do placeCharacter(p) end
	Remotes.Get(N.StateSnapshot):FireAllClients(buildSnapshot())
	alertAll("Info", nil, ("Crew of %d boarding · %s"):format(#players, run.difficulty))
	print(("[Run] Launched %s | %d crew | %s"):format(run.runId, #players, run.difficulty))
	return true
end

local function onFailed()
	local reason = run.lossReason or "Unknown"
	Remotes.Get(N.ShipLost):FireAllClients({
		reason = reason,
		day = run.day.day,
		sector = Config.SectorFor(math.max(run.day.day, 1)),
		tasks = run.rewards.crewTotal.tasks,
		salvage = run.rewards.crewTotal.salvage,
		returnIn = Config.Lobby.ReturnToLobbyAfterLoss,
	})
	print(("[Run %s] SHIP LOST on day %d (%s)"):format(string.sub(run.runId, 1, 8), run.day.day, reason))
	local token = run.lossToken
	task.delay(Config.Lobby.ReturnToLobbyAfterLoss, function()
		if run.lossToken == token and run.day.phase == "Failed" then RunCoordinator.ReturnToLobby("auto after loss") end
	end)
end

function RunCoordinator.GetRun() return run end

function RunCoordinator.Start()
	Remotes.Init()
	local seed = math.floor(os.clock() * 1000) % 2147483647
	run = {
		runId = HttpService:GenerateGUID(false),
		seed = seed,
		rng = Random.new(seed),
		difficulty = Config.DefaultDifficulty,
		crew = {},
		lossToken = 0,
	}
	run.ship = ShipStateService.new(run.difficulty, seed)
	run.day = DayCycleService.new()
	run.inventory = InventoryService.new(run.ship.tuning.startingResourcesFactor)
	run.rewards = RunRewards.new()
	run.recordStat = function(player, key, n) run.rewards:Record(player, key, n) end

	run.ship.ModeChanged.Event:Connect(function(name, _old, new)
		if run.day:IsTerminal() or run.day.phase == "Lobby" then return end
		if new == "Critical" then
			alertAll("Critical", name, string.upper(name) .. " CRITICAL — " .. Config.SystemObjectives[name])
		elseif new == "Warning" then
			alertAll("Warning", name, name .. ": " .. Config.SystemObjectives[name])
		else
			alertAll("Info", name, name .. " restored to nominal.")
		end
	end)

	run.day.PhaseChanged.Event:Connect(function(info)
		print(("[Run %s] Day %d -> %s (%s)"):format(string.sub(run.runId, 1, 8), info.day, info.phase, info.sector))
		Remotes.Get(N.DayPhase):FireAllClients(info)
		if info.phase == "Transition" then
			local common, personal = run.rewards:CloseDay(run)
			if common then
				for player, mine in pairs(personal) do
					if player.Parent then
						Remotes.Get(N.DaySummary):FireClient(player, { common = common, you = mine, nextAt = run.day.phaseEndsAt })
					end
				end
			end
		elseif info.phase == "Failed" then
			onFailed()
		end
		if info.phase == "Prepare" and info.day == 1 or info.phase == "Failed" then LobbyPartyService.Broadcast() end
	end)

	run.inventory.Changed.Event:Connect(function(items)
		Remotes.Get(N.Inventory):FireAllClients(items)
	end)

	local lastRequest = {}
	Remotes.Get(N.RequestSnapshot).OnServerEvent:Connect(function(player)
		local t = os.clock()
		if lastRequest[player] and t - lastRequest[player] < 1 then return end
		lastRequest[player] = t
		Remotes.Get(N.StateSnapshot):FireClient(player, buildSnapshot())
	end)
	Remotes.Get(N.RestartRun).OnServerEvent:Connect(function(player)
		if run.day.phase ~= "Failed" or not run.crew[player.UserId] then return end
		alertAll("Info", nil, player.DisplayName .. " returned the crew to the terminal.")
		RunCoordinator.ReturnToLobby("crew request")
	end)

	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("HumanoidRootPart", 5)
			placeCharacter(player)
		end)
		if player.Character then placeCharacter(player) end
		if inVoyage(player) then
			alertAll("Info", nil, player.DisplayName .. " reconnected and rejoined the crew.")
			Remotes.Get(N.StateSnapshot):FireClient(player, buildSnapshot())
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end
	Players.PlayerRemoving:Connect(function(p)
		lastRequest[p] = nil
		if inVoyage(p) then alertAll("Warning", nil, p.DisplayName .. " lost connection. They can rejoin this voyage.") end
	end)

	TaskService.Start(run)
	RoomLightingService.Start(run)
	SalvageService.Start(run)
	QuickActionService.Start(run)
	LobbyPartyService.Start(run, RunCoordinator.Launch)

	task.spawn(function()
		local interval = 1 / Config.SimTickHz
		while true do
			local dt = task.wait(interval)
			local day = run.day
			if day.phase ~= "Lobby" then
				local present = #crewPlayers()
				if present == 0 then
					run.noCrewSince = run.noCrewSince or os.clock()
					if os.clock() - run.noCrewSince >= ABANDON_SECONDS then
						RunCoordinator.ReturnToLobby("crew abandoned voyage")
						continue
					end
				else
					run.noCrewSince = nil
				end

				if not day:IsTerminal() then
					run.ship.crewCount = math.max(1, present)
					run.ship:Step(dt, day:IsActive())

					setEmergency(run.ship:GetCatastrophe())
					if run.emergency and workspace:GetServerTimeNow() >= run.emergency.endsAt then
						run.lossReason = run.emergency.reason
						run.emergency = nil
						Remotes.Get(N.Emergency):FireAllClients({ active = false })
						day:Fail()
					elseif not run.emergency then
						day:Update(workspace:GetServerTimeNow()) -- emergencies hold the day open
					end

					local delta = run.ship:CollectDelta()
					if delta then
						Remotes.Get(N.StateDelta):FireAllClients({
							revision = run.ship.revision,
							systems = delta,
							objective = currentObjective(),
						})
					end
				end
			end
		end
	end)

	-- Studio-only dev hook (never active in live servers)
	if RunService:IsStudio() then
		local dev = Instance.new("BindableFunction")
		dev.Name = "DevCommand"
		dev.OnInvoke = function(cmd, a, b, c)
			if cmd == "damage" and run.ship.systems[a] then
				local s = run.ship.systems[a]
				s.health = math.clamp(s.health - b, 0, 100)
			elseif cmd == "set" and run.ship.systems[a] then
				run.ship.systems[a][b] = c
			elseif cmd == "use" then
				local CollectionService = game:GetService("CollectionService")
				for _, st in ipairs(CollectionService:GetTagged("QuickAction")) do
					if st:GetAttribute("ActionId") == a then QuickActionService.Use(Players:GetPlayers()[1], st) end
				end
			elseif cmd == "skip" then
				run.day:SkipPhase()
			elseif cmd == "fail" then
				run.lossReason = "OxygenDepleted"
				run.day:Fail()
			elseif cmd == "lobby" then
				return game:GetService("HttpService"):JSONEncode(LobbyPartyService.BuildState())
			end
			local s = run.ship:Serialize()
			local inv = run.inventory:Snapshot()
			local crewN = 0
			for _ in pairs(run.crew) do crewN += 1 end
			return ("day=%d phase=%s diff=%s crew=%d emerg=%s | Hull %d O2 %d Power %d Cooling %d | Scrap %d Sealant %d Filter %d"):format(
				run.day.day, run.day.phase, run.difficulty, crewN, run.emergency and run.emergency.reason or "-", s.Hull.h, s.Oxygen.o, s.Power.o, s.Cooling.h,
				inv.ScrapAlloy, inv.SealantFoam, inv.FilterMembrane)
		end
		dev.Parent = game:GetService("ServerScriptService")
	end

	print(("[Run] Server ready | lobby needs %d crew"):format(LobbyPartyService.RequiredPlayers()))
end

return RunCoordinator
