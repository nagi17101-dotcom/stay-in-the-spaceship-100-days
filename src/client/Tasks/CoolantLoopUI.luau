-- CoolantLoopUI: rotate pipe tiles to connect IN -> reactor, choose pump speed. Server validates.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HUD = script.Parent.Parent.HUD
local Theme = require(HUD.Theme)
local C = require(HUD.Components)
local PipeMath = require(ReplicatedStorage.Shared.Minigames.PipeMath)

local CoolantLoopUI = {}
local ARMS = {
	[1] = { UDim2.fromScale(0.36, 0), UDim2.fromScale(0.28, 0.5) },
	[2] = { UDim2.fromScale(0.5, 0.36), UDim2.fromScale(0.5, 0.28) },
	[4] = { UDim2.fromScale(0.36, 0.5), UDim2.fromScale(0.28, 0.5) },
	[8] = { UDim2.fromScale(0, 0.36), UDim2.fromScale(0.5, 0.28) },
}

function CoolantLoopUI.Mount(body: Frame, pub)
	local rots = table.clone(pub.rots)
	local speed = 1
	local w, h = pub.w, pub.h
	local tile = math.min(52, math.floor(260 / math.max(w, h)))

	C.label({ Size = UDim2.new(1, 0, 0, 16), TextSize = 12, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Left,
		Text = ("Heat load %d · Max pressure %d · Pressure = tiles + 2 × pump"):format(pub.heatLoad, pub.maxPressure), Parent = body })
	local flow = C.label({ Position = UDim2.new(0, 0, 0, 18), Size = UDim2.new(1, 0, 0, 16), TextSize = 12, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = body })

	local grid = C.make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 40),
		Size = UDim2.fromOffset(w * tile, h * tile), Parent = body })
	C.label({ Position = UDim2.fromOffset(-30, (pub.sourceRow - 1) * tile), Size = UDim2.fromOffset(28, tile), Text = "IN ►", TextSize = 11, Font = Theme.FontBold, TextColor3 = Theme.Teal, Parent = grid })
	C.label({ Position = UDim2.fromOffset(w * tile + 2, (pub.reactorRow - 1) * tile), Size = UDim2.fromOffset(28, tile), Text = "► RX", TextSize = 11, Font = Theme.FontBold, TextColor3 = Theme.Amber, Parent = grid })

	local tiles = {}
	local function draw(i)
		local btn = tiles[i]
		for _, ch in ipairs(btn:GetChildren()) do if ch.Name == "Pipe" then ch:Destroy() end end
		local kind = pub.kinds[i]
		if kind == "Blocked" then
			btn.BackgroundColor3 = Color3.fromRGB(70, 28, 30) btn.Text = "✕" return
		end
		local mask = PipeMath.Mask(kind, rots[i])
		if mask == 0 then return end
		C.make("Frame", { Name = "Pipe", Position = UDim2.fromScale(0.36, 0.36), Size = UDim2.fromScale(0.28, 0.28), BackgroundColor3 = Theme.Teal, BorderSizePixel = 0, Parent = btn })
		for bit, geo in pairs(ARMS) do
			if bit32.band(mask, bit) ~= 0 then
				C.make("Frame", { Name = "Pipe", Position = geo[1], Size = geo[2], BackgroundColor3 = Theme.Teal, BorderSizePixel = 0, Parent = btn })
			end
		end
	end

	local speedButtons = {}
	local function refresh()
		local len = PipeMath.Trace(w, h, pub.kinds, rots, pub.sourceRow, pub.reactorRow)
		if len then
			local p = len + speed * 2
			flow.Text = ("FLOW CONNECTED · %d tiles · pressure %d / %d"):format(len, p, pub.maxPressure)
			flow.TextColor3 = (p > pub.maxPressure or speed < pub.heatLoad) and Theme.Amber or Theme.Teal
		else
			flow.Text = "NO FLOW — rotate pipes to connect IN to RX"
			flow.TextColor3 = Theme.Dim
		end
		for s, b in pairs(speedButtons) do
			b.BackgroundColor3 = s == speed and Theme.Teal or Theme.Track
			b.TextColor3 = s == speed and Theme.Panel or Theme.Text
		end
	end

	for y = 1, h do
		for x = 1, w do
			local i = (y - 1) * w + x
			local btn = C.button({ Position = UDim2.fromOffset((x - 1) * tile + 1, (y - 1) * tile + 1), Size = UDim2.fromOffset(tile - 2, tile - 2), Text = "", Parent = grid })
			tiles[i] = btn
			draw(i)
			local kind = pub.kinds[i]
			if kind ~= "Blocked" and kind ~= "Empty" then
				btn.Activated:Connect(function() rots[i] = (rots[i] + 1) % 4 draw(i) refresh() end)
			end
		end
	end

	local py = 44 + h * tile
	C.label({ Position = UDim2.new(0, 0, 0, py), Size = UDim2.new(0, 60, 0, 26), Text = "PUMP", TextSize = 12, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Left, Parent = body })
	for s = 1, pub.pumpMax do
		local b = C.button({ Position = UDim2.new(0, 60 + (s - 1) * 44, 0, py), Size = UDim2.fromOffset(38, 26), Text = tostring(s), Parent = body })
		speedButtons[s] = b
		b.Activated:Connect(function() speed = s refresh() end)
	end
	refresh()

	return {
		getAction = function() return { rotations = table.clone(rots), speed = speed } end,
	}
end

return CoolantLoopUI
