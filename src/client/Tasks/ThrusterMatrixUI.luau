-- ThrusterMatrixUI: tap a thruster to cycle power 0→1→2; live plot shows drift, corridor and burn endpoint.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HUD = script.Parent.Parent.HUD
local Theme = require(HUD.Theme)
local C = require(HUD.Components)
local Rules = require(ReplicatedStorage.Shared.Minigames.ThrusterMatrixRules)

local ThrusterMatrixUI = {}
local RANGE, CELL = Rules.PLOT_RANGE, 10
-- compass slot (col,row) in a 3x3 pad for each DIRS index
local SLOT = { N = { 2, 1 }, NE = { 3, 1 }, E = { 3, 2 }, SE = { 3, 3 }, S = { 2, 3 }, SW = { 1, 3 }, W = { 1, 2 }, NW = { 1, 1 } }

function ThrusterMatrixUI.Mount(body: Frame, pub)
	local powers = {}
	for i = 1, #Rules.DIRS do powers[i] = 0 end
	local span = (RANGE * 2 + 1) * CELL

	-- Plot
	local plot = C.make("Frame", { Size = UDim2.fromOffset(span, span), BackgroundColor3 = Color3.fromRGB(8, 10, 14), BorderSizePixel = 0, ClipsDescendants = true, Parent = body },
		{ C.make("UICorner", { CornerRadius = UDim.new(0, 6) }) })
	local function toPx(x, y) return UDim2.fromOffset((x + RANGE) * CELL, (RANGE - y) * CELL) end
	C.make("Frame", { Position = UDim2.fromOffset(0, RANGE * CELL + CELL / 2), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Track, BorderSizePixel = 0, Parent = plot })
	C.make("Frame", { Position = UDim2.fromOffset(RANGE * CELL + CELL / 2, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Theme.Track, BorderSizePixel = 0, Parent = plot })
	local tol = pub.corridor.tol
	local cpos = toPx(pub.corridor.x - tol, pub.corridor.y + tol)
	C.make("Frame", { Position = cpos, Size = UDim2.fromOffset((2 * tol + 1) * CELL, (2 * tol + 1) * CELL), BackgroundColor3 = Theme.Teal, BackgroundTransparency = 0.6, BorderSizePixel = 0, Parent = plot })
	C.make("Frame", { Position = toPx(pub.drift.x, pub.drift.y), Size = UDim2.fromOffset(CELL, CELL), BackgroundColor3 = Theme.Amber, BorderSizePixel = 0, Parent = plot },
		{ C.make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local endpoint = C.make("Frame", { Size = UDim2.fromOffset(CELL, CELL), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, Parent = plot },
		{ C.make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	C.label({ Position = UDim2.fromOffset(4, span - 14), Size = UDim2.fromOffset(span, 12), TextSize = 10, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "● drift   ■ corridor   ● burn end", Parent = plot })

	-- Thruster pad
	local padX = span + 14
	local buttons = {}
	local readout = C.label({ Position = UDim2.fromOffset(padX, 3 * 40 + 6), Size = UDim2.new(1, -padX, 0, 34), TextSize = 12, RichText = true, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "", Parent = body })
	local hint = C.label({ Position = UDim2.fromOffset(0, span + 6), Size = UDim2.new(1, 0, 0, 16), TextSize = 12, Font = Theme.FontBold, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = body })

	local function refresh()
		local ok, _, message, r = Rules.Evaluate(pub, powers)
		endpoint.Position = toPx(math.clamp(r.x, -RANGE, RANGE), math.clamp(r.y, -RANGE, RANGE))
		endpoint.BackgroundColor3 = Rules.InCorridor(pub, r.x, r.y) and Theme.Teal or Theme.Text
		for i, b in ipairs(buttons) do
			local d = Rules.DIRS[i]
			if pub.disabled == i then
				b.Text = d.id .. " ✕" b.BackgroundColor3 = Color3.fromRGB(70, 28, 30)
			else
				b.Text = ("%s %d"):format(d.id, powers[i])
				b.BackgroundColor3 = powers[i] == 0 and Theme.Track or (powers[i] == 1 and Color3.fromRGB(40, 120, 120) or Theme.Teal)
			end
		end
		local function c(okv) return okv and "#38D2C8" or "#EB4848" end
		readout.Text = ('END (%d, %d)\nFUEL <font color="%s"><b>%d</b></font>/%d   VIB <font color="%s"><b>%d</b></font>/%d'):format(
			r.x, r.y, c(r.fuel <= pub.fuelBudget), r.fuel, pub.fuelBudget, c(r.vibration <= pub.vibrationLimit), r.vibration, pub.vibrationLimit)
		hint.Text = ok and "BURN READY — submit to align the drive" or message
		hint.TextColor3 = ok and Theme.Teal or Theme.Amber
	end

	for i, d in ipairs(Rules.DIRS) do
		local slot = SLOT[d.id]
		local b = C.button({ Position = UDim2.fromOffset(padX + (slot[1] - 1) * 58, (slot[2] - 1) * 40), Size = UDim2.fromOffset(54, 36), TextSize = 12, Text = "", Parent = body })
		buttons[i] = b
		b.Activated:Connect(function()
			if pub.disabled == i then return end
			powers[i] = (powers[i] + 1) % (Rules.MAX_POWER + 1)
			refresh()
		end)
	end
	C.label({ Position = UDim2.fromOffset(padX + 58, 40), Size = UDim2.fromOffset(54, 36), TextSize = 10, TextColor3 = Theme.Dim, Text = "fuel\n2 · ◇3", Parent = body })
	refresh()

	return {
		getAction = function() return { powers = table.clone(powers) } end,
	}
end

return ThrusterMatrixUI
