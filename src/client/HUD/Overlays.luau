-- Overlays: Day Complete summary and Ship Lost screen.
local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)

local Overlays = {}
Overlays.__index = Overlays

local LOSS_TEXT = {
	OxygenDepleted = "Oxygen reserves were depleted.",
	HullBreach = "Hull integrity failed.",
}

function Overlays.new(playerGui: PlayerGui)
	local self = setmetatable({}, Overlays)
	local old = playerGui:FindFirstChild("Overlays")
	if old then old:Destroy() end
	self.gui = C.make("ScreenGui", { Name = "Overlays", ResetOnSpawn = false, DisplayOrder = 10, IgnoreGuiInset = true, Parent = playerGui })
	return self
end

local function row(parent, order, key, value, color)
	local r = C.make("Frame", { BackgroundTransparency = 1, LayoutOrder = order, Size = UDim2.new(1, 0, 0, 20), Parent = parent })
	C.label({ Size = UDim2.new(0.55, 0, 1, 0), TextSize = 13, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Left, Text = key, Parent = r })
	C.label({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.45, 0, 1, 0), TextSize = 13, Font = Theme.FontBold,
		TextColor3 = color or Theme.Text, TextXAlignment = Enum.TextXAlignment.Right, TextWrapped = true, Text = value, Parent = r })
end

local function card(parent, height)
	local p = C.panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.9, 0, 0, height), BackgroundTransparency = 0.05, Parent = parent })
	C.make("UISizeConstraint", { MaxSize = Vector2.new(400, height), Parent = p })
	C.make("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18), PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 16), Parent = p })
	C.make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = p })
	return p
end

function Overlays:HideDaySummary()
	if self.summary then self.summary:Destroy() self.summary = nil end
end

function Overlays:ShowDaySummary(data)
	self:HideDaySummary()
	local c, you = data.common, data.you
	local p = card(self.gui, 250)
	self.summary = p
	C.label({ LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 24), Font = Theme.FontBold, TextSize = 20, TextColor3 = Theme.Teal, Text = ("DAY %03d COMPLETE"):format(c.day), Parent = p })
	C.label({ LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 16), TextSize = 12, TextColor3 = Theme.Dim, Text = string.upper(c.sector), Parent = p })
	row(p, 3, "Repairs completed", tostring(c.crewTasks))
	row(p, 4, "Salvage recovered", tostring(c.crewSalvage))
	row(p, 5, "Ship condition", c.condition .. "%", c.condition < 50 and Theme.Amber or Theme.Teal)
	row(p, 6, "Crew supplies", "+" .. c.crewReward, Theme.Teal)
	row(p, 7, "Your XP", ("+%d  (run %d)"):format(you.xp, you.totalXp), Theme.Amber)

	local delay = math.clamp((data.nextAt or 0) - workspace:GetServerTimeNow(), 3, 10)
	task.delay(delay, function() if self.summary == p then self:HideDaySummary() end end)
end

function Overlays:HideShipLost()
	if self.lost then self.lost:Destroy() self.lost = nil end
end

function Overlays:ShowShipLost(data, onRestart)
	self:HideDaySummary()
	self:HideShipLost()
	local shade = C.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(20, 4, 6), BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = self.gui })
	self.lost = shade
	local p = card(shade, 250)
	p:FindFirstChildOfClass("UIStroke").Color = Theme.Red
	C.label({ LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 30), Font = Theme.FontBold, TextSize = 26, TextColor3 = Theme.Red, Text = "SHIP LOST", Parent = p })
	C.label({ LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 18), TextSize = 13, Text = LOSS_TEXT[data.reason] or tostring(data.reason), Parent = p })
	row(p, 3, "Survived to", ("Day %d · %s"):format(data.day, data.sector))
	row(p, 4, "Repairs completed", tostring(data.tasks))
	row(p, 5, "Salvage recovered", tostring(data.salvage))
	C.label({ LayoutOrder = 6, Size = UDim2.new(1, 0, 0, 14), TextSize = 11, TextColor3 = Theme.Dim, Text = ("Returning to the terminal in %ds"):format(data.returnIn or 20), Parent = p })
	local btnHolder = C.make("Frame", { LayoutOrder = 7, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), Parent = p })
	local btn = C.button({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(200, 34), Text = "RETURN TO LOBBY",
		BackgroundColor3 = Theme.Teal, TextColor3 = Theme.Panel, Parent = btnHolder })
	btn.Activated:Connect(function()
		btn.Text = "Returning…"
		onRestart()
	end)
end

return Overlays
