-- LobbyPartyService: server-owned crew (party) for this voyage server.
-- Single-place prototype: one ship per server => one party. Future: lobby place + reserved servers
-- (TeleportService:TeleportAsync with ReservedServerId) — requires published place IDs.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)
local N = Remotes.Names

local Lobby = {}
local run, launchFn
local party = nil -- { leaderId, members = {userId}, ready = {[userId]=true}, difficulty, countdownEndsAt, token }
local lastAction = {}

function Lobby.RequiredPlayers(): number
	if RunService:IsStudio() and Config.StudioSoloOverride then return 1 end
	return Config.PlayersMin
end

local function runActive(): boolean
	return run.day.phase ~= "Lobby"
end

local function notify(player, text)
	Remotes.Get(N.Alert):FireClient(player, { severity = "Info", text = text })
end

local function indexOf(list, v)
	for i, x in ipairs(list) do if x == v then return i end end
	return nil
end

local function cancelCountdown()
	if party then
		party.countdownEndsAt = nil
		party.token += 1
	end
end

local function updateDisplay(state)
	local lobby = workspace:FindFirstChild("Lobby")
	local display = lobby and lobby:FindFirstChild("PartyDisplay")
	local label = display and display:FindFirstChild("SurfaceGui") and display.SurfaceGui:FindFirstChild("Label")
	if not label then return end
	if state.run.active then
		label.Text = ("VOYAGE IN PROGRESS\nDAY %03d · %d CREW ABOARD"):format(state.run.day, #state.run.crew)
	elseif not state.party then
		label.Text = "NO CREW FORMED\nCREATE CREW TO BEGIN"
	else
		local ready = 0
		for _, m in ipairs(state.party.members) do if m.ready then ready += 1 end end
		label.Text = ("CREW %d/%d · READY %d\n%s"):format(#state.party.members, Config.PlayersMax, ready, string.upper(state.party.difficulty))
		if state.party.countdownEndsAt then label.Text ..= " · LAUNCHING" end
	end
end

function Lobby.BuildState()
	local state = {
		minPlayers = Lobby.RequiredPlayers(),
		maxPlayers = Config.PlayersMax,
		run = { active = runActive(), day = run.day.day, phase = run.day.phase, crew = {} },
	}
	for userId in pairs(run.crew or {}) do table.insert(state.run.crew, userId) end
	if party then
		local members = {}
		for _, uid in ipairs(party.members) do
			local p = Players:GetPlayerByUserId(uid)
			table.insert(members, { userId = uid, name = p and p.DisplayName or "?", ready = party.ready[uid] == true, leader = uid == party.leaderId })
		end
		state.party = { leaderId = party.leaderId, members = members, difficulty = party.difficulty, countdownEndsAt = party.countdownEndsAt }
	end
	return state
end

function Lobby.Broadcast()
	local state = Lobby.BuildState()
	Remotes.Get(N.PartyState):FireAllClients(state)
	updateDisplay(state)
end

local function removeMember(userId: number)
	if not party then return end
	local i = indexOf(party.members, userId)
	if not i then return end
	table.remove(party.members, i)
	party.ready[userId] = nil
	cancelCountdown()
	if #party.members == 0 then
		party = nil
	elseif party.leaderId == userId then
		party.leaderId = party.members[1]
	end
end

local function canLaunch(): (boolean, string?)
	if not party then return false, "No crew." end
	if runActive() then return false, "A voyage is already in progress." end
	if #party.members < Lobby.RequiredPlayers() then return false, ("Need at least %d crew."):format(Lobby.RequiredPlayers()) end
	if #party.members > Config.PlayersMax then return false, "Crew is full." end
	for _, uid in ipairs(party.members) do
		if not party.ready[uid] then return false, "Everyone must be READY." end
	end
	return true
end

local ACTIONS = {}

function ACTIONS.create(player)
	if party then return notify(player, "A crew already exists. Join it.") end
	party = { leaderId = player.UserId, members = { player.UserId }, ready = {}, difficulty = Config.DefaultDifficulty, token = 0 }
end

function ACTIONS.join(player)
	if not party then return notify(player, "No crew to join. Create one.") end
	if indexOf(party.members, player.UserId) then return end
	if #party.members >= Config.PlayersMax then return notify(player, "Crew is full (6/6).") end
	table.insert(party.members, player.UserId)
	cancelCountdown()
end

function ACTIONS.leave(player)
	removeMember(player.UserId)
end

function ACTIONS.ready(player, value)
	if not party or not indexOf(party.members, player.UserId) or type(value) ~= "boolean" then return end
	party.ready[player.UserId] = value or nil
	if not value then cancelCountdown() end
end

function ACTIONS.difficulty(player, value)
	if not party or party.leaderId ~= player.UserId then return end
	if type(value) ~= "string" or not Config.Difficulty[value] then return end
	party.difficulty = value
	cancelCountdown()
end

function ACTIONS.launch(player)
	if not party or party.leaderId ~= player.UserId then return end
	local ok, why = canLaunch()
	if not ok then return notify(player, why) end
	if party.countdownEndsAt then return end
	party.countdownEndsAt = workspace:GetServerTimeNow() + Config.Lobby.LaunchCountdown
	local token = party.token
	task.delay(Config.Lobby.LaunchCountdown, function()
		if not party or party.token ~= token then return end
		local stillOk = canLaunch()
		party.countdownEndsAt = nil
		if not stillOk then Lobby.Broadcast() return end
		local crew = {}
		for _, uid in ipairs(party.members) do
			local p = Players:GetPlayerByUserId(uid)
			if p then table.insert(crew, p) end
		end
		launchFn(crew, party.difficulty)
		for uid in pairs(party.ready) do party.ready[uid] = nil end
		Lobby.Broadcast()
	end)
end

function Lobby.OnRunEnded()
	if party then
		for uid in pairs(party.ready) do party.ready[uid] = nil end
		cancelCountdown()
	end
	Lobby.Broadcast()
end

function Lobby.Start(runRef, launch)
	run, launchFn = runRef, launch
	Remotes.Get(N.PartyAction).OnServerEvent:Connect(function(player, action, value)
		if type(action) ~= "string" or not ACTIONS[action] then return end
		local now = os.clock()
		if lastAction[player] and now - lastAction[player] < Config.Lobby.ActionCooldown then return end
		lastAction[player] = now
		if runActive() and action ~= "leave" then return notify(player, "A voyage is in progress.") end
		ACTIONS[action](player, value)
		Lobby.Broadcast()
	end)
	Players.PlayerAdded:Connect(function(p)
		task.defer(function() Remotes.Get(N.PartyState):FireClient(p, Lobby.BuildState()) end)
	end)
	Players.PlayerRemoving:Connect(function(p)
		lastAction[p] = nil
		removeMember(p.UserId)
		Lobby.Broadcast()
	end)
	Lobby.Broadcast()
end

return Lobby
