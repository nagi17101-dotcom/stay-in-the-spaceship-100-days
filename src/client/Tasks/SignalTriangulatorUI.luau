-- SignalTriangulatorUI: toggle each antenna's confidence arc, pick the cell where all arcs meet. Server re-validates.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HUD = script.Parent.Parent.HUD
local Theme = require(HUD.Theme)
local C = require(HUD.Components)
local Rules = require(ReplicatedStorage.Shared.Minigames.SignalTriangulatorRules)

local SignalTriangulatorUI = {}
local ARC_COLORS = { Color3.fromRGB(56, 140, 210), Color3.fromRGB(200, 90, 200), Color3.fromRGB(230, 150, 40) }

function SignalTriangulatorUI.Mount(body: Frame, pub)
	local size = pub.size
	local tile = math.min(30, math.floor(240 / size))
	local shown = { true, true, true }
	local selected = nil
	local cells = {}
	local antennaAt = {}
	for i, a in ipairs(pub.antennas) do antennaAt[a.x .. "," .. a.y] = i end

	local grid = C.make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(size * tile, size * tile), Parent = body })
	local side = size * tile + 12
	C.label({ Position = UDim2.fromOffset(side, 0), Size = UDim2.new(1, -side, 0, 14), TextSize = 11, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "ANTENNA RANGE" .. (pub.band > 0 and (" (noise ±" .. pub.band .. ")") or ""), Parent = body })
	local toggles = {}
	local hint = C.label({ Position = UDim2.fromOffset(side, 18 + #pub.antennas * 32 + 6), Size = UDim2.new(1, -side, 0, 46), TextSize = 12, Font = Theme.FontBold,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "", Parent = body })

	local function refresh()
		for k, btn in pairs(cells) do
			local x, y = btn:GetAttribute("X"), btn:GetAttribute("Y")
			local count, color = 0, Theme.Track
			for i in ipairs(pub.antennas) do
				if shown[i] and Rules.OnArc(pub, i, x, y) then count += 1 color = ARC_COLORS[i] end
			end
			local ai = antennaAt[k]
			btn.Text = ai and pub.antennas[ai].id or (count >= 2 and tostring(count) or "")
			btn.BackgroundColor3 = (selected == k) and Theme.Teal or (ai and Color3.fromRGB(20, 24, 30)) or (count >= 2 and Color3.fromRGB(70, 110, 120)) or (count == 1 and color:Lerp(Theme.Track, 0.55)) or Theme.Track
			btn.TextColor3 = (selected == k) and Theme.Panel or Theme.Text
		end
		for i, t in ipairs(toggles) do
			t.BackgroundColor3 = shown[i] and ARC_COLORS[i] or Theme.Track
		end
		if selected then
			local x, y = string.match(selected, "(%d+),(%d+)")
			local ok, _, message = Rules.Evaluate(pub, tonumber(x), tonumber(y))
			hint.Text = ok and "ALL ARCS AGREE — submit to lock beacon" or message
			hint.TextColor3 = ok and Theme.Teal or Theme.Amber
		else
			hint.Text = "Pick the cell where all antenna arcs intersect."
			hint.TextColor3 = Theme.Dim
		end
	end

	for y = 1, size do
		for x = 1, size do
			local k = x .. "," .. y
			local btn = C.button({ Position = UDim2.fromOffset((x - 1) * tile + 1, (y - 1) * tile + 1), Size = UDim2.fromOffset(tile - 2, tile - 2), Text = "", TextSize = 11, Parent = grid })
			btn:SetAttribute("X", x) btn:SetAttribute("Y", y)
			cells[k] = btn
			btn.Activated:Connect(function()
				if antennaAt[k] then return end
				selected = (selected == k) and nil or k
				refresh()
			end)
		end
	end
	for i, a in ipairs(pub.antennas) do
		local t = C.button({ Position = UDim2.fromOffset(side, 18 + (i - 1) * 32), Size = UDim2.new(1, -side, 0, 28), TextSize = 12,
			Text = ("%s  range %d%s"):format(a.id, a.reading, pub.band > 0 and ("±" .. pub.band) or ""), Parent = body })
		toggles[i] = t
		t.Activated:Connect(function() shown[i] = not shown[i] refresh() end)
	end
	refresh()

	return {
		getAction = function()
			if not selected then return { x = 0, y = 0 } end -- rejected by shape check; server ignores
			local x, y = string.match(selected, "(%d+),(%d+)")
			return { x = tonumber(x), y = tonumber(y) }
		end,
	}
end

return SignalTriangulatorUI
