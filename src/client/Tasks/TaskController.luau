-- TaskController: opens the task modal for a server-issued task, sends actions, shows results.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)
local HUD = script.Parent.Parent.HUD
local Theme = require(HUD.Theme)
local C = require(HUD.Components)
local N = Remotes.Names

local UIS = {
	HullSeal = require(script.Parent.HullSealUI),
	PowerBus = require(script.Parent.PowerBusUI),
	CoolantLoop = require(script.Parent.CoolantLoopUI),
}
local TITLES = { HullSeal = "HULL SEAL PLANNER", PowerBus = "POWER BUS ALLOCATOR", CoolantLoop = "COOLANT LOOP" }

local TaskController = {}
local current

local function close(sendCancel: boolean)
	if not current then return end
	if sendCancel then Remotes.Get(N.TaskCancel):FireServer(current.taskId) end
	current.gui:Destroy()
	current = nil
end

local function open(playerGui, spec)
	close(false)
	local ui = UIS[spec.minigameId]
	if not ui then return end
	local gui = C.make("ScreenGui", { Name = "TaskGui", ResetOnSpawn = false, DisplayOrder = 5, Parent = playerGui })
	local modal = C.panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.new(0.9, 0, 0, 380), BackgroundTransparency = 0.05, Parent = gui })
	C.make("UISizeConstraint", { MaxSize = Vector2.new(460, 380), Parent = modal })
	C.make("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), Parent = modal })

	C.label({ Size = UDim2.new(1, 0, 0, 20), Font = Theme.FontBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Text = TITLES[spec.minigameId] or spec.minigameId, Parent = modal })
	C.label({ Position = UDim2.new(0, 0, 0, 22), Size = UDim2.new(1, 0, 0, 14), TextSize = 12, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Left,
		Text = ("%s · %s · %d attempts"):format(string.upper(spec.system), string.upper(spec.tier), spec.maxAttempts), Parent = modal })

	local body = C.make("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 44), Size = UDim2.new(1, 0, 1, -96), Parent = modal })
	local status = C.label({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -36), Size = UDim2.new(1, 0, 0, 16), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Text = "", Parent = modal })
	local submit = C.button({ AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0), Size = UDim2.fromOffset(120, 30), Text = "SUBMIT", BackgroundColor3 = Theme.Teal, TextColor3 = Theme.Panel, Parent = modal })
	local cancel = C.button({ AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -128, 1, 0), Size = UDim2.fromOffset(90, 30), Text = "CLOSE", Parent = modal })

	local mounted = ui.Mount(body, spec.publicPuzzle)
	current = { taskId = spec.taskId, gui = gui, status = status }

	submit.Activated:Connect(function()
		status.Text = "Validating…" status.TextColor3 = Theme.Dim
		Remotes.Get(N.TaskSubmit):FireServer(spec.taskId, mounted.getAction())
	end)
	cancel.Activated:Connect(function() close(true) end)
end

function TaskController.Init(playerGui: PlayerGui)
	Remotes.Get(N.TaskOpen).OnClientEvent:Connect(function(spec) open(playerGui, spec) end)
	Remotes.Get(N.TaskResult).OnClientEvent:Connect(function(res)
		if not current or res.taskId ~= current.taskId then return end
		local s = current.status
		s.Text = res.message .. (res.attemptsLeft and (" (%d left)"):format(res.attemptsLeft) or "")
		s.TextColor3 = res.ok and Theme.Teal or (res.closed and Theme.Red or Theme.Amber)
		if res.closed then
			local id = current.taskId
			task.delay(res.ok and 1.2 or 2.5, function()
				if current and current.taskId == id then close(false) end
			end)
		end
	end)
	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(function() close(true) end)
end

return TaskController
