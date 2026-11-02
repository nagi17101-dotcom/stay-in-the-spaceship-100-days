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
	row(p, 7, "Your XP", ("+%d  (run %d)%s"):format(you.xp, you.totalXp, you.saved and " · added to profile" or " · not saved"), Theme.Amber)

	local delay = math.clamp((data.nextAt or 0) - workspace:GetServerTimeNow(), 3, 10)
	task.delay(delay, function() if self.summary == p then self:HideDaySummary() end end)
end

function Overlays:HideVote()
	if self.vote then self.vote:Destroy() self.vote = nil end
end

-- Day-100 vote: two choices with live counts; tie/timeout => Extract (server decides)
function Overlays:ShowVote(state, myUserId: number, cast: (string) -> ())
	if not state.open then self:HideVote() return end
	if not self.vote then
		self:HideDaySummary()
		local p = card(self.gui, 230)
		self.vote = p
		C.label({ LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 26), Font = Theme.FontBold, TextSize = 20, TextColor3 = Theme.Teal, Text = "MISSION COMPLETE — DAY 100", Parent = p })
		C.label({ LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 30), TextSize = 12, TextColor3 = Theme.Dim, TextWrapped = true,
			Text = "The return signal is locked. Crew vote: extract now, or continue into the Endless Voyage.", Parent = p })
		local row = C.make("Frame", { LayoutOrder = 3, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Parent = p })
		self.voteExtract = C.button({ Size = UDim2.new(0.5, -4, 1, 0), Text = "", Parent = row })
		self.voteContinue = C.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.5, -4, 1, 0), Text = "", Parent = row })
		self.voteExtract.Activated:Connect(function() cast("Extract") end)
		self.voteContinue.Activated:Connect(function() cast("Continue") end)
		self.voteTimer = C.label({ LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 16), TextSize = 12, TextColor3 = Theme.Dim, Text = "", Parent = p })
		local ref = p
		task.spawn(function()
			while self.vote == ref do
				local left = math.max(0, math.ceil((self.voteEndsAt or 0) - workspace:GetServerTimeNow()))
				self.voteTimer.Text = ("Tie or timeout → Extract · %ds"):format(left)
				task.wait(0.25)
			end
		end)
	end
	self.voteEndsAt = state.endsAt
	local mine = state.votes and (state.votes[myUserId] or state.votes[tostring(myUserId)])
	self.voteExtract.Text = ("EXTRACT & FINISH (%d)"):format(state.extract)
	self.voteContinue.Text = ("CONTINUE — ENDLESS (%d)"):format(state.continue)
	self.voteExtract.BackgroundColor3 = mine == "Extract" and Theme.Teal or Theme.Track
	self.voteContinue.BackgroundColor3 = mine == "Continue" and Theme.Amber or Theme.Track
	self.voteExtract.TextColor3 = mine == "Extract" and Theme.Panel or Theme.Text
	self.voteContinue.TextColor3 = mine == "Continue" and Theme.Panel or Theme.Text
end

function Overlays:ShowRunComplete(data)
	self:HideVote()
	self:HideDaySummary()
	if self.complete then self.complete:Destroy() end
	local p = card(self.gui, 200)
	self.complete = p
	C.label({ LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 28), Font = Theme.FontBold, TextSize = 22, TextColor3 = Theme.Teal, Text = "VOYAGE COMPLETE", Parent = p })
	C.label({ LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 16), TextSize = 12, TextColor3 = Theme.Dim, Text = ("Extracted on Day %d · %s"):format(data.day, string.upper(data.difficulty)), Parent = p })
	row(p, 3, "Repairs completed", tostring(data.tasks))
	row(p, 4, "Salvage recovered", tostring(data.salvage))
	C.label({ LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 14), TextSize = 11, TextColor3 = Theme.Dim, Text = ("Returning to the terminal in %ds"):format(data.returnIn), Parent = p })
	task.delay(data.returnIn + 2, function() if self.complete == p then p:Destroy() self.complete = nil end end)
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
