-- LobbyPanel: crew manifest + party controls. Sends intents only; server owns party state.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.GameConfig)
local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)

local LobbyPanel = {}
LobbyPanel.__index = LobbyPanel

function LobbyPanel.new(playerGui: PlayerGui, send: (string, any?) -> ())
	local self = setmetatable({}, LobbyPanel)
	self.send = send
	local old = playerGui:FindFirstChild("LobbyGui")
	if old then old:Destroy() end
	self.gui = C.make("ScreenGui", { Name = "LobbyGui", ResetOnSpawn = false, Parent = playerGui })
	local p = C.panel({ AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0), Size = UDim2.new(0, 300, 0, 380), Parent = self.gui })
	C.make("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), Parent = p })
	self.panel = p

	C.label({ Size = UDim2.new(1, 0, 0, 20), Font = Theme.FontBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Text = "ORBITAL TERMINAL", Parent = p })
	self.status = C.label({ Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 30), TextSize = 12, TextColor3 = Theme.Dim, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "", Parent = p })

	self.list = C.make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 0, 150), Parent = p })
	C.make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.list })

	-- Difficulty row
	C.label({ Position = UDim2.fromOffset(0, 214), Size = UDim2.new(0.4, 0, 0, 28), TextSize = 12, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Left, Text = "DIFFICULTY", Parent = p })
	self.diffPrev = C.button({ Position = UDim2.new(0.4, 0, 0, 214), Size = UDim2.fromOffset(28, 28), Text = "◄", Parent = p })
	self.diffLabel = C.label({ Position = UDim2.new(0.4, 32, 0, 214), Size = UDim2.new(0.6, -64, 0, 28), Font = Theme.FontBold, TextSize = 13, Text = "", Parent = p })
	self.diffNext = C.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 214), Size = UDim2.fromOffset(28, 28), Text = "►", Parent = p })

	-- Action buttons
	self.primary = C.button({ Position = UDim2.fromOffset(0, 254), Size = UDim2.new(0.5, -4, 0, 34), Text = "", Parent = p })
	self.secondary = C.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 254), Size = UDim2.new(0.5, -4, 0, 34), Text = "", Parent = p })
	self.launch = C.button({ Position = UDim2.fromOffset(0, 296), Size = UDim2.new(1, 0, 0, 38), Text = "LAUNCH", BackgroundColor3 = Theme.Teal, TextColor3 = Theme.Panel, TextSize = 15, Parent = p })
	self.countdown = C.label({ Position = UDim2.fromOffset(0, 338), Size = UDim2.new(1, 0, 0, 18), Font = Theme.FontBold, TextSize = 13, TextColor3 = Theme.Amber, Text = "", Parent = p })

	self.primaryAction, self.secondaryAction = nil, nil
	self.primary.Activated:Connect(function() if self.primaryAction then self.send(self.primaryAction[1], self.primaryAction[2]) end end)
	self.secondary.Activated:Connect(function() if self.secondaryAction then self.send(self.secondaryAction[1], self.secondaryAction[2]) end end)
	self.launch.Activated:Connect(function() self.send("launch") end)
	local function cycle(dir)
		local order = Config.Lobby.DifficultyOrder
		local cur = self.state and self.state.party and self.state.party.difficulty
		local i = table.find(order, cur) or 2
		self.send("difficulty", order[(i - 1 + dir) % #order + 1])
	end
	self.diffPrev.Activated:Connect(function() cycle(-1) end)
	self.diffNext.Activated:Connect(function() cycle(1) end)
	return self
end

function LobbyPanel:SetProfile(s)
	if not self.profile then
		local p = C.panel({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -16), Size = UDim2.new(0, 300, 0, 58), Parent = self.gui })
		C.make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 8), Parent = p })
		self.profileTitle = C.label({ Size = UDim2.new(1, 0, 0, 16), Font = Theme.FontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = p })
		local _, fill = C.bar({ Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 4), Parent = p })
		self.profileFill = fill
		self.profileLine = C.label({ Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 14), TextSize = 11, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = p })
		self.profile = p
	end
	self.profileTitle.Text = ("LV %d · %s"):format(s.level, s.rank)
	local span = math.max(1, s.nextLevelXp - s.levelXp)
	self.profileFill.Size = UDim2.fromScale(math.clamp((s.xp - s.levelXp) / span, 0, 1), 1)
	if s.persistent then
		self.profileLine.Text = ("XP %d / %d · best day C%d S%d V%d · %d achievements"):format(s.xp, s.nextLevelXp, s.bestDay.Cadet, s.bestDay.Standard, s.bestDay.Veteran, s.achievements)
		self.profileLine.TextColor3 = Theme.Dim
	else
		self.profileLine.Text = "⚠ Progress is not being saved this session."
		self.profileLine.TextColor3 = Theme.Amber
	end
end

function LobbyPanel:SetVisible(v: boolean)
	self.gui.Enabled = v
end

local function setButton(btn, text, enabled, color)
	btn.Text = text
	btn.Visible = text ~= ""
	btn.Active = enabled
	btn.AutoButtonColor = enabled
	btn.BackgroundColor3 = enabled and (color or Theme.Track) or Theme.Panel
	btn.TextColor3 = (enabled and color) and Theme.Panel or (enabled and Theme.Text or Theme.Dim)
end

function LobbyPanel:Render(state, myUserId: number)
	self.state = state
	self.myUserId = myUserId
	for _, ch in ipairs(self.list:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end

	local party = state.party
	local me, isLeader, allReady = nil, false, true
	if party then
		for i, m in ipairs(party.members) do
			if m.userId == myUserId then me = m isLeader = m.leader end
			if not m.ready then allReady = false end
			local row = C.make("Frame", { LayoutOrder = i, BackgroundColor3 = Theme.Track, BackgroundTransparency = 0.3, Size = UDim2.new(1, 0, 0, 21), Parent = self.list },
				{ C.make("UICorner", { CornerRadius = UDim.new(0, 4) }) })
			C.label({ Position = UDim2.fromOffset(8, 0), Size = UDim2.new(0.7, -8, 1, 0), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
				Text = (m.leader and "★ " or "") .. m.name .. (m.userId == myUserId and " (you)" or ""), Parent = row })
			C.label({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.new(0.3, 0, 1, 0), TextSize = 11, Font = Theme.FontBold,
				TextXAlignment = Enum.TextXAlignment.Right, Text = m.ready and "READY" or "—", TextColor3 = m.ready and Theme.Teal or Theme.Dim, Parent = row })
		end
	end

	local count = party and #party.members or 0
	if state.run.active then
		self.status.Text = ("Voyage in progress · Day %d. Wait here for the crew to return."):format(state.run.day)
	elseif not party then
		self.status.Text = ("No crew yet. Create one (%d–%d players)."):format(state.minPlayers, state.maxPlayers)
	else
		self.status.Text = ("Crew %d/%d · need %d+ · all must be READY."):format(count, state.maxPlayers, state.minPlayers)
	end

	self.diffLabel.Text = party and string.upper(party.difficulty) or "—"
	local canEditDiff = isLeader and not state.run.active
	self.diffPrev.Visible, self.diffNext.Visible = canEditDiff, canEditDiff

	if state.run.active then
		setButton(self.primary, "", false) setButton(self.secondary, "", false)
		self.primaryAction, self.secondaryAction = nil, nil
	elseif not party then
		setButton(self.primary, "CREATE CREW", true, Theme.Teal) setButton(self.secondary, "", false)
		self.primaryAction, self.secondaryAction = { "create" }, nil
	elseif not me then
		local full = count >= state.maxPlayers
		setButton(self.primary, full and "CREW FULL" or "JOIN CREW", not full, Theme.Teal) setButton(self.secondary, "", false)
		self.primaryAction, self.secondaryAction = (not full) and { "join" } or nil, nil
	else
		setButton(self.primary, me.ready and "UNREADY" or "READY", true, not me.ready and Theme.Teal or nil)
		setButton(self.secondary, "LEAVE CREW", true)
		self.primaryAction, self.secondaryAction = { "ready", not me.ready }, { "leave" }
	end

	local launchable = isLeader and not state.run.active and count >= state.minPlayers and allReady and not party.countdownEndsAt
	self.launch.Visible = isLeader and not state.run.active
	setButton(self.launch, "LAUNCH", launchable, Theme.Teal)
	self.launch.Visible = isLeader and not state.run.active
	self:Tick(workspace:GetServerTimeNow())
end

function LobbyPanel:Tick(now: number)
	local party = self.state and self.state.party
	if party and party.countdownEndsAt then
		self.countdown.Text = ("BOARDING IN %ds"):format(math.max(0, math.ceil(party.countdownEndsAt - now)))
	else
		self.countdown.Text = ""
	end
end

return LobbyPanel
