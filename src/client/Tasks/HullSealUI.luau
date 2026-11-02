-- HullSealUI: pick a plate, rotate, click a cell to place (anchor = clicked cell); click a plate to remove it.
-- Live hints use the same public rules as the server; the server re-validates on submit.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HUD = script.Parent.Parent.HUD
local Theme = require(HUD.Theme)
local C = require(HUD.Components)
local Rules = require(ReplicatedStorage.Shared.Minigames.HullSealRules)

local HullSealUI = {}
local LEAK = Color3.fromRGB(120, 78, 20)
local RAIL = Color3.fromRGB(22, 25, 31)
local HOT = Color3.fromRGB(110, 30, 30)

function HullSealUI.Mount(body: Frame, pub)
	local placements = {}
	local selected, rot = nil, 0
	local w, h = pub.w, pub.h
	local tile = math.min(40, math.floor(220 / math.max(w, h)))
	local leakSet, railSet, hotSet = {}, {}, {}
	for _, c in ipairs(pub.leak) do leakSet[Rules.Key(c[1], c[2])] = true end
	for _, c in ipairs(pub.blocked) do railSet[Rules.Key(c[1], c[2])] = true end
	for _, c in ipairs(pub.hot) do hotSet[Rules.Key(c[1], c[2])] = true end

	local hint = C.label({ Size = UDim2.new(1, 0, 0, 16), TextSize = 12, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = body })
	C.label({ Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 14), TextSize = 11, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Cover the leak · no rail ▦ / hot ✱ · every plate touches frame or plate" .. (pub.stressSide and (" · brace " .. Rules.SideName[pub.stressSide]) or ""), Parent = body })

	local grid = C.make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 38), Size = UDim2.fromOffset(w * tile, h * tile), Parent = body })
	if pub.stressSide then
		local s = pub.stressSide
		local geo = ({
			N = { UDim2.fromOffset(0, -4), UDim2.new(1, 0, 0, 3) }, S = { UDim2.new(0, 0, 1, 1), UDim2.new(1, 0, 0, 3) },
			W = { UDim2.fromOffset(-4, 0), UDim2.new(0, 3, 1, 0) }, E = { UDim2.new(1, 1, 0, 0), UDim2.new(0, 3, 1, 0) },
		})[s]
		C.make("Frame", { Position = geo[1], Size = geo[2], BackgroundColor3 = Theme.Amber, BorderSizePixel = 0, Parent = grid })
	end

	local cells = {}
	local plateButtons = {}
	local function refresh()
		local ok, _, message, occupied = Rules.Evaluate(pub, placements)
		hint.Text = ok and "SEAL READY — submit to pressure test" or message
		hint.TextColor3 = ok and Theme.Teal or Theme.Amber
		for k, btn in pairs(cells) do
			local idx = occupied[k]
			if idx then
				btn.BackgroundColor3 = Theme.Teal
				btn.TextColor3 = Theme.Panel
				btn.Text = tostring(placements[idx].plate)
			else
				btn.BackgroundColor3 = railSet[k] and RAIL or hotSet[k] and HOT or leakSet[k] and LEAK or Theme.Track
				btn.TextColor3 = Theme.Text
				btn.Text = railSet[k] and "▦" or hotSet[k] and "✱" or ""
			end
		end
		local used = {}
		for _, p in ipairs(placements) do used[p.plate] = true end
		for i, b in ipairs(plateButtons) do
			b.BackgroundColor3 = (i == selected) and Theme.Teal or (used[i] and Theme.Panel or Theme.Track)
			b.TextColor3 = (i == selected) and Theme.Panel or (used[i] and Theme.Dim or Theme.Text)
		end
	end

	for y = 1, h do
		for x = 1, w do
			local k = Rules.Key(x, y)
			local btn = C.button({ Position = UDim2.fromOffset((x - 1) * tile + 1, (y - 1) * tile + 1), Size = UDim2.fromOffset(tile - 2, tile - 2), Text = "", TextSize = 12, Parent = grid })
			cells[k] = btn
			btn.Activated:Connect(function()
				local _, _, _, occupied = Rules.Evaluate(pub, placements)
				local idx = occupied[k]
				if idx then
					table.remove(placements, idx)
				elseif selected then
					for _, p in ipairs(placements) do if p.plate == selected then return end end
					table.insert(placements, { plate = selected, x = x, y = y, rot = rot })
					selected = nil
				end
				refresh()
			end)
		end
	end

	-- Plate tray + rotate
	local trayX = w * tile + 16
	C.label({ Position = UDim2.fromOffset(trayX, 38), Size = UDim2.fromOffset(120, 14), TextSize = 11, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Left, Text = "PLATES", Parent = body })
	for i, shape in ipairs(pub.plates) do
		local b = C.button({ Position = UDim2.fromOffset(trayX + ((i - 1) % 2) * 62, 56 + math.floor((i - 1) / 2) * 32), Size = UDim2.fromOffset(58, 28), Text = i .. " · " .. shape, TextSize = 12, Parent = body })
		plateButtons[i] = b
		b.Activated:Connect(function() selected = (selected == i) and nil or i refresh() end)
	end
	local rotBtn = C.button({ Position = UDim2.fromOffset(trayX, 56 + math.ceil(#pub.plates / 2) * 32 + 6), Size = UDim2.fromOffset(120, 28), Text = "ROTATE ↻ 0°", Parent = body })
	rotBtn.Activated:Connect(function()
		rot = (rot + 1) % 4
		rotBtn.Text = ("ROTATE ↻ %d°"):format(rot * 90)
	end)
	refresh()

	return {
		getAction = function()
			local copy = {}
			for _, p in ipairs(placements) do table.insert(copy, { plate = p.plate, x = p.x, y = p.y, rot = p.rot }) end
			return { placements = copy }
		end,
	}
end

return HullSealUI
