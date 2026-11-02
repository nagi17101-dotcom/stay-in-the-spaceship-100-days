-- ShipHUD: minimal always-on bar (DAY, progress, Hull/O2/Power, objective) + severity alert stack.
local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)

local ShipHUD = {}
ShipHUD.__index = ShipHUD

local MODE_COLOR = { Nominal = Theme.Teal, Warning = Theme.Amber, Critical = Theme.Red }
local REASON_TEXT = { OxygenDepleted = "OXYGEN DEPLETED", HullBreach = "HULL BREACH" }
local SEVERITY_COLOR = { Info = Theme.Teal, Warning = Theme.Amber, Critical = Theme.Red }
local METERS = { { key = "Hull", label = "HULL", field = "h" }, { key = "Oxygen", label = "O₂", field = "o" }, { key = "Power", label = "POWER", field = "o" } }
local MAX_ALERTS = 3
local TOTAL_DAYS = 100

function ShipHUD.new(playerGui: PlayerGui)
	local self = setmetatable({}, ShipHUD)
	local old = playerGui:FindFirstChild("ShipHUD")
	if old then old:Destroy() end

	self.gui = C.make("ScreenGui", { Name = "ShipHUD", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui })

	local top = C.panel({
		Name = "TopBar", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.new(0.6, 0, 0, 96), Parent = self.gui,
	})
	C.make("UISizeConstraint", { MinSize = Vector2.new(300, 96), MaxSize = Vector2.new(620, 96), Parent = top })
	C.make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), Parent = top })

	self.dayLabel = C.label({ Name = "Day", Size = UDim2.new(0.65, 0, 0, 18), Font = Theme.FontBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Text = "DAY --- / 100", Parent = top })
	self.phaseLabel = C.label({ Name = "Phase", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.35, 0, 0, 18), TextSize = 13, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Right, Text = "STANDBY", Parent = top })
	local _, fill = C.bar({ Name = "DayProgress", Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 0, 4), Parent = top })
	self.progressFill = fill

	local row = C.make("Frame", { Name = "Meters", BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 36), Size = UDim2.new(1, 0, 0, 24), Parent = top })
	C.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
	self.meters = {}
	for i, m in ipairs(METERS) do
		local cell = C.make("Frame", { Name = m.key, LayoutOrder = i, BackgroundTransparency = 1, Size = UDim2.new(1 / 3, -8, 1, 0), Parent = row })
		C.label({ Size = UDim2.new(0.5, 0, 0, 14), TextSize = 12, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Left, Text = m.label, Parent = cell })
		local value = C.label({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.5, 0, 0, 14), Font = Theme.FontBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Text = "--%", Parent = cell })
		local _, mfill = C.bar({ Position = UDim2.new(0, 0, 0, 17), Size = UDim2.new(1, 0, 0, 5), Parent = cell })
		self.meters[m.key] = { value = value, fill = mfill, field = m.field }
	end

	self.objective = C.label({ Name = "Objective", Position = UDim2.new(0, 0, 0, 64), Size = UDim2.new(1, 0, 0, 16), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "", Parent = top })

	self.alerts = C.make("Frame", { Name = "Alerts", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 116), Size = UDim2.new(0, 300, 0, 220), Parent = self.gui })
	C.make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.alerts })
	self.alertOrder = 0
	self.phaseInfo = nil

	-- Crew inventory (bottom-left)
	local inv = C.panel({ Name = "Inventory", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12), Size = UDim2.new(0, 360, 0, 30), Parent = self.gui })
	C.make("UISizeConstraint", { MaxSize = Vector2.new(360, 30), Parent = inv })
	self.inventoryLabel = C.label({ Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), TextSize = 12, RichText = true, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "", Parent = inv })

	-- Emergency banner (under top bar)
	self.emergencyBanner = C.panel({ Name = "Emergency", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 112), Size = UDim2.new(0.6, 0, 0, 30),
		BackgroundColor3 = Color3.fromRGB(60, 14, 16), BackgroundTransparency = 0.1, Visible = false, Parent = self.gui })
	C.make("UISizeConstraint", { MaxSize = Vector2.new(620, 30), Parent = self.emergencyBanner })
	self.emergencyLabel = C.label({ Size = UDim2.fromScale(1, 1), Font = Theme.FontBold, TextSize = 13, TextColor3 = Theme.Red, Text = "", Parent = self.emergencyBanner })
	self.emergency = nil
	self.alerts.Position = UDim2.new(1, -12, 0, 150)
	return self
end

function ShipHUD:SetPhase(info)
	self.phaseInfo = info
	if info.day > 0 then
		if info.day > TOTAL_DAYS then
			self.dayLabel.Text = ("DAY %03d · %s"):format(info.day, string.upper(info.sector))
		else
			self.dayLabel.Text = ("DAY %03d / %d · %s"):format(info.day, TOTAL_DAYS, string.upper(info.sector))
		end
	else
		self.dayLabel.Text = "DAY --- / 100 · STANDBY"
	end
	self:Tick(workspace:GetServerTimeNow())
end

function ShipHUD:Tick(now: number)
	local info = self.phaseInfo
	if not info then return end
	local phase = string.upper(info.phase)
	if info.phaseEndsAt > 0 then
		local remaining = math.max(0, info.phaseEndsAt - now)
		local total = math.max(0.01, info.phaseEndsAt - info.phaseStartedAt)
		self.phaseLabel.Text = ("%s · %ds"):format(phase, math.ceil(remaining))
		self.progressFill.Size = UDim2.fromScale(math.clamp(1 - remaining / total, 0, 1), 1)
	else
		self.phaseLabel.Text = phase
		self.progressFill.Size = UDim2.fromScale(info.phase == "Lobby" and 0 or 1, 1)
	end
	self.progressFill.BackgroundColor3 = info.phase == "Failed" and Theme.Red or Theme.Teal
	if self.emergency then
		local left = math.max(0, math.ceil(self.emergency.endsAt - now))
		self.emergencyLabel.Text = ("⚠ EMERGENCY — %s · SHIP LOST IN %ds"):format(REASON_TEXT[self.emergency.reason] or self.emergency.reason, left)
		self.emergencyBanner.BackgroundTransparency = 0.1 + 0.25 * (math.sin(now * 4) + 1) / 2
	end
end

function ShipHUD:UpdateSystems(systems)
	for key, meter in pairs(self.meters) do
		local s = systems[key]
		if s then
			local v = s[meter.field]
			meter.value.Text = ("%d%%"):format(v)
			local color = MODE_COLOR[s.m] or Theme.Teal
			meter.value.TextColor3 = s.m == "Nominal" and Theme.Text or color
			meter.fill.BackgroundColor3 = color
			TweenService:Create(meter.fill, TweenInfo.new(0.4), { Size = UDim2.fromScale(math.clamp(v / 100, 0, 1), 1) }):Play()
		end
	end
end


function ShipHUD:SetInventory(items, materials)
	local parts = {}
	for _, m in ipairs(materials) do
		table.insert(parts, ('<font color="#8A96A6">%s</font> <b>%d</b>'):format(m.short, items[m.id] or 0))
	end
	self.inventoryLabel.Text = table.concat(parts, "   ")
end

function ShipHUD:SetEmergency(e)
	self.emergency = (e and e.reason) and e or nil
	self.emergencyBanner.Visible = self.emergency ~= nil
	self:Tick(workspace:GetServerTimeNow())
end

function ShipHUD:SetObjective(text: string)
	self.objective.Text = text ~= "" and ("▸ " .. text) or ""
end

function ShipHUD:PushAlert(alert)
	local items = {}
	for _, c in ipairs(self.alerts:GetChildren()) do
		if c:IsA("Frame") then table.insert(items, c) end
	end
	table.sort(items, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
	while #items >= MAX_ALERTS do table.remove(items, 1):Destroy() end

	self.alertOrder += 1
	local color = SEVERITY_COLOR[alert.severity] or Theme.Teal
	local card = C.panel({ Name = "Alert", LayoutOrder = self.alertOrder, Size = UDim2.new(1, 0, 0, 40), Parent = self.alerts })
	C.make("Frame", { Size = UDim2.new(0, 3, 1, -12), Position = UDim2.new(0, 6, 0, 6), BackgroundColor3 = color, BorderSizePixel = 0, Parent = card })
	C.label({ Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(1, -24, 1, 0), TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Text = alert.text, TextColor3 = alert.severity == "Critical" and color or Theme.Text, Parent = card })

	local life = alert.severity == "Critical" and 10 or 6
	task.delay(life, function()
		if card.Parent then card:Destroy() end
	end)
end

return ShipHUD
