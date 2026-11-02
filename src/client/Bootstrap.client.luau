-- Client entry point: binds server state to HUD/overlays. No authority on the client.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Network"):WaitForChild("Remotes"))
local Config = require(Shared:WaitForChild("Config"):WaitForChild("GameConfig"))
local HUDFolder = script.Parent:WaitForChild("HUD")
local ShipHUD = require(HUDFolder:WaitForChild("ShipHUD"))
local Overlays = require(HUDFolder:WaitForChild("Overlays"))
local LobbyPanel = require(HUDFolder:WaitForChild("LobbyPanel"))
local N = Remotes.Names

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local hud = ShipHUD.new(playerGui)
local overlays = Overlays.new(playerGui)
local myUserId = Players.LocalPlayer.UserId
local lobby = LobbyPanel.new(playerGui, function(action, value) Remotes.Get(N.PartyAction):FireServer(action, value) end)
local inVoyage = false
hud.gui.Enabled = false

local function applyPartyState(state)
	inVoyage = false
	if state.run.active then
		for _, uid in ipairs(state.run.crew) do if uid == myUserId then inVoyage = true end end
	end
	hud.gui.Enabled = inVoyage
	lobby:SetVisible(not inVoyage)
	lobby:Render(state, myUserId)
	if not inVoyage then overlays:HideDaySummary() end
end
Remotes.Get(N.PartyState).OnClientEvent:Connect(applyPartyState)
Remotes.Get(N.ProfileState).OnClientEvent:Connect(function(s) lobby:SetProfile(s) end)
Remotes.Get(N.VoteState).OnClientEvent:Connect(function(state)
	if not inVoyage then return end
	overlays:ShowVote(state, myUserId, function(choice) Remotes.Get(N.CastVote):FireServer(choice) end)
end)
Remotes.Get(N.RunComplete).OnClientEvent:Connect(function(data)
	if inVoyage then overlays:ShowRunComplete(data) end
end)
require(script.Parent:WaitForChild("Tasks"):WaitForChild("TaskController")).Init(playerGui)
require(script.Parent:WaitForChild("Effects"):WaitForChild("RoomFX")).Start()

local lastRevision = -1

local function onPhase(info)
	hud:SetPhase(info)
	if info.phase ~= "Failed" then overlays:HideShipLost() end
	if info.phase == "Prepare" or info.phase == "Lobby" then overlays:HideDaySummary() end
end

Remotes.Get(N.StateSnapshot).OnClientEvent:Connect(function(snap)
	lastRevision = snap.revision -- snapshot is authoritative (also after restart)
	onPhase(snap.phaseInfo)
	hud:UpdateSystems(snap.systems)
	hud:SetObjective(snap.objective)
	if snap.materials then hud:SetInventory(snap.materials, Config.Materials) end
	hud:SetEmergency(snap.emergency)
end)

Remotes.Get(N.StateDelta).OnClientEvent:Connect(function(delta)
	if delta.revision < lastRevision then return end -- stale update guard
	lastRevision = delta.revision
	hud:UpdateSystems(delta.systems)
	hud:SetObjective(delta.objective)
end)

Remotes.Get(N.DayPhase).OnClientEvent:Connect(onPhase)
Remotes.Get(N.Alert).OnClientEvent:Connect(function(alert) hud:PushAlert(alert) end)
Remotes.Get(N.Inventory).OnClientEvent:Connect(function(items) hud:SetInventory(items, Config.Materials) end)
Remotes.Get(N.Emergency).OnClientEvent:Connect(function(e) hud:SetEmergency(e) end)
Remotes.Get(N.DaySummary).OnClientEvent:Connect(function(data) overlays:ShowDaySummary(data) end)
Remotes.Get(N.ShipLost).OnClientEvent:Connect(function(data)
	hud:SetEmergency(nil)
	if not inVoyage then return end
	overlays:ShowShipLost(data, function() Remotes.Get(N.RestartRun):FireServer() end)
end)

Remotes.Get(N.RequestSnapshot):FireServer()

while true do
	local now = workspace:GetServerTimeNow()
	hud:Tick(now)
	lobby:Tick(now)
	task.wait(0.2)
end
