-- Remotes: single registry of network endpoints. Server creates, client waits.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}
Remotes.Names = {
	StateSnapshot = "ShipStateSnapshot",   -- S->C full state (join / on request)
	StateDelta = "ShipStateDelta",         -- S->C changed systems only
	DayPhase = "DayPhaseChanged",          -- S->C phase info
	Alert = "ShipAlert",                   -- S->C severity alert
	RequestSnapshot = "RequestSnapshot",   -- C->S (rate limited)
	TaskOpen = "TaskOpen",                 -- S->C public puzzle for a reserved task
	TaskSubmit = "TaskSubmit",             -- C->S (taskId, action) validated server-side
	TaskCancel = "TaskCancel",             -- C->S (taskId)
	TaskResult = "TaskResult",             -- S->C outcome
	Inventory = "InventoryChanged",        -- S->C shared crew materials
	DaySummary = "DaySummary",             -- S->C day complete + personal rewards
	Emergency = "EmergencyState",          -- S->C catastrophe countdown on/off
	ShipLost = "ShipLost",                 -- S->C run failed summary
	RestartRun = "RestartRun",             -- C->S return to lobby after loss
	PartyState = "PartyState",             -- S->C lobby party + run status
	ProfileState = "ProfileState",         -- S->C account progression summary
	PartyAction = "PartyAction",           -- C->S { action, value } (create/join/leave/ready/difficulty/launch)
}
local FOLDER = "Remotes"

function Remotes.Init()
	assert(RunService:IsServer(), "Remotes.Init is server-only")
	local folder = ReplicatedStorage:FindFirstChild(FOLDER)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER
		folder.Parent = ReplicatedStorage
	end
	for _, name in pairs(Remotes.Names) do
		if not folder:FindFirstChild(name) then
			local r = Instance.new("RemoteEvent")
			r.Name = name
			r.Parent = folder
		end
	end
end

function Remotes.Get(name: string): RemoteEvent
	if RunService:IsServer() then
		return ReplicatedStorage[FOLDER][name]
	end
	return ReplicatedStorage:WaitForChild(FOLDER):WaitForChild(name)
end

return Remotes
