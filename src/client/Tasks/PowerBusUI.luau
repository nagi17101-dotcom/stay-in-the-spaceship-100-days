-- PowerBusUI: assign each load to a bus (or OFF). Display-only math; server validates.
local HUD = script.Parent.Parent.HUD
local Theme = require(HUD.Theme)
local C = require(HUD.Components)

local PowerBusUI = {}

function PowerBusUI.Mount(body: Frame, pub)
	local assign = {}
	for _, l in ipairs(pub.loads) do assign[l.id] = 0 end

	local header = C.label({ Size = UDim2.new(1, 0, 0, 18), TextSize = 13, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = body })
	local busLine = C.label({ Position = UDim2.new(0, 0, 0, 20), Size = UDim2.new(1, 0, 0, 16), TextSize = 12, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Left, RichText = true, Parent = body })
	local buttons = {}

	local function refresh()
		local usage, total = {}, 0
		for _, l in ipairs(pub.loads) do
			local ch = assign[l.id]
			if ch > 0 then usage[ch] = (usage[ch] or 0) + l.demand total += l.demand end
		end
		header.Text = ("GENERATOR  %d / %d A"):format(total, pub.generator)
		header.TextColor3 = total > pub.generator and Theme.Red or Theme.Text
		local parts = {}
		for i, c in ipairs(pub.channels) do
			if c.damaged then
				table.insert(parts, ('<font color="#EB4848">BUS %s DAMAGED</font>'):format(c.id))
			else
				local u = usage[i] or 0
				local col = u > c.capacity and "#EB4848" or "#8A96A6"
				table.insert(parts, ('<font color="%s">BUS %s  %d/%d A</font>'):format(col, c.id, u, c.capacity))
			end
		end
		busLine.Text = table.concat(parts, "    ")
		for loadId, row in pairs(buttons) do
			for idx, btn in pairs(row) do
				btn.BackgroundColor3 = assign[loadId] == idx and Theme.Teal or Theme.Track
				btn.TextColor3 = assign[loadId] == idx and Theme.Panel or Theme.Text
			end
		end
	end

	for r, l in ipairs(pub.loads) do
		local y = 44 + (r - 1) * 34
		C.label({ Position = UDim2.new(0, 0, 0, y), Size = UDim2.new(0.42, 0, 0, 28), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
			Text = (l.critical and "★ " or "") .. l.label .. ("  %dA"):format(l.demand), TextColor3 = l.critical and Theme.Amber or Theme.Text, Parent = body })
		buttons[l.id] = {}
		local n = #pub.channels + 1
		for idx = 0, #pub.channels do
			local c = pub.channels[idx]
			local b = C.button({
				Position = UDim2.new(0.44 + idx * (0.56 / n), 0, 0, y), Size = UDim2.new(0.56 / n, -6, 0, 28),
				Text = idx == 0 and "OFF" or c.id, Parent = body,
			})
			if c and c.damaged then b.Text = c.id .. " ✕" end
			buttons[l.id][idx] = b
			b.Activated:Connect(function() assign[l.id] = idx refresh() end)
		end
	end
	refresh()

	return {
		getAction = function()
			local copy = {}
			for k, v in pairs(assign) do copy[k] = v end
			return { assignments = copy }
		end,
	}
end

return PowerBusUI
