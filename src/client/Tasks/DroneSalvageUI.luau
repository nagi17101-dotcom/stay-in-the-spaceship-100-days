-- DroneSalvageUI: click adjacent cells to draw the drone route from the dock and back; click the last cell to undo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HUD = script.Parent.Parent.HUD
local Theme = require(HUD.Theme)
local C = require(HUD.Components)
local Rules = require(ReplicatedStorage.Shared.Minigames.DroneSalvageRules)

local DroneSalvageUI = {}
local HAZ = Color3.fromRGB(110, 30, 30)
local PULSE = Color3.fromRGB(120, 80, 20)
local TARGET = Color3.fromRGB(40, 90, 140)

function DroneSalvageUI.Mount(body: Frame, pub)
	local size = pub.size
	local tile = math.min(25, math.floor(225 / size))
	local path = {}
	local cells = {}
	local special = {}
	for i, t in ipairs(pub.targets) do special[Rules.Key(t.x, t.y)] = { kind = "target", i = i } end
	for _, c in ipairs(pub.hazards) do special[Rules.Key(c[1], c[2])] = { kind = "hazard" } end
	for _, c in ipairs(pub.pulsing or {}) do special[Rules.Key(c[1], c[2])] = { kind = "pulse" } end

	local grid = C.make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(size * tile, size * tile), Parent = body })
	local side = size * tile + 10
	local legend = {}
	for i, t in ipairs(pub.targets) do
		table.insert(legend, ("%s%d: %s"):format(pub.priority == i and "★" or "▣", i, t.label))
	end
	C.label({ Position = UDim2.fromOffset(side, 0), Size = UDim2.new(1, -side, 0, 88), TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, Text = table.concat(legend, "\n") .. ((#(pub.pulsing or {}) > 0) and "\n◌ pulsing: active on odd steps" or ""), Parent = body })
	local readout = C.label({ Position = UDim2.fromOffset(side, 92), Size = UDim2.new(1, -side, 0, 34), TextSize = 12, RichText = true, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "", Parent = body })
	local hint = C.label({ Position = UDim2.fromOffset(side, 128), Size = UDim2.new(1, -side, 0, 46), TextSize = 12, Font = Theme.FontBold, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "", Parent = body })
	local clear = C.button({ Position = UDim2.fromOffset(side, 178), Size = UDim2.fromOffset(80, 26), Text = "CLEAR", Parent = body })

	local function refresh()
		local ok, _, message, r = Rules.Evaluate(pub, path)
		local order = {}
		for i, c in ipairs(path) do order[Rules.Key(c[1], c[2])] = i end
		for k, b in pairs(cells) do
			local sp = special[k]
			local x, y = b:GetAttribute("X"), b:GetAttribute("Y")
			local isDock = x == pub.dock[1] and y == pub.dock[2]
			local bg = Theme.Track
			local text = ""
			if isDock then bg, text = Theme.Teal, "D"
			elseif sp and sp.kind == "hazard" then bg, text = HAZ, "✕"
			elseif sp and sp.kind == "pulse" then bg, text = PULSE, "◌"
			elseif sp and sp.kind == "target" then bg, text = TARGET, (pub.priority == sp.i and "★" or "▣")
			end
			if order[k] and not isDock then
				bg = Color3.fromRGB(56, 160, 150)
				text = tostring(order[k])
			end
			b.BackgroundColor3 = bg
			b.Text = text
		end
		local fuelOk = r.steps <= pub.fuel
		readout.Text = ('FUEL <font color="%s"><b>%d</b></font>/%d   CARGO %d/%d%s'):format(fuelOk and "#38D2C8" or "#EB4848", r.steps, pub.fuel, #r.picked, pub.capacity,
			r.atDock and "   <font color=\"#38D2C8\">DOCKED</font>" or "")
		hint.Text = ok and "ROUTE SAFE — submit to launch the drone" or (#path == 0 and "Draw a route from the dock (D) through salvage and back." or message)
		hint.TextColor3 = ok and Theme.Teal or (#path == 0 and Theme.Dim or Theme.Amber)
	end

	for y = 1, size do
		for x = 1, size do
			local k = Rules.Key(x, y)
			local b = C.button({ Position = UDim2.fromOffset((x - 1) * tile + 1, (y - 1) * tile + 1), Size = UDim2.fromOffset(tile - 2, tile - 2), Text = "", TextSize = 11, Parent = grid })
			b:SetAttribute("X", x) b:SetAttribute("Y", y)
			cells[k] = b
			b.Activated:Connect(function()
				local last = path[#path] or pub.dock
				if #path > 0 and last[1] == x and last[2] == y then
					table.remove(path) -- undo last step
				elseif math.abs(last[1] - x) + math.abs(last[2] - y) == 1 then
					table.insert(path, { x, y })
				end
				refresh()
			end)
		end
	end
	clear.Activated:Connect(function() table.clear(path) refresh() end)
	refresh()

	return {
		getAction = function()
			local copy = {}
			for _, c in ipairs(path) do table.insert(copy, { c[1], c[2] }) end
			return { path = copy }
		end,
	}
end

return DroneSalvageUI
