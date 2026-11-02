-- GravityStabilizerUI: tap a weight, then an empty slot in the same ring to shift it. Damping trades power for stability.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HUD = script.Parent.Parent.HUD
local Theme = require(HUD.Theme)
local C = require(HUD.Components)
local Rules = require(ReplicatedStorage.Shared.Minigames.GravityStabilizerRules)

local GravityStabilizerUI = {}
local R, SLOT = 46, 26 -- ring radius and slot button size (px)

function GravityStabilizerUI.Mount(body: Frame, pub)
	local moves, damping, selected = {}, 1, nil
	local slotButtons, markers = {}, {}
	local refresh

	for r = 1, #pub.rings do
		local box = C.make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset((r - 1) * 140, 0), Size = UDim2.fromOffset(130, 130), Parent = body })
		C.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(2 * R, 2 * R),
			BackgroundTransparency = 1, Parent = box }, { C.make("UICorner", { CornerRadius = UDim.new(1, 0) }), C.make("UIStroke", { Color = Theme.Stroke, Thickness = 2 }) })
		C.label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 14), Size = UDim2.fromOffset(40, 14), TextSize = 11, TextColor3 = Theme.Dim, Text = "RING " .. string.char(64 + r), Parent = box })
		markers[r] = C.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = Theme.Amber, BorderSizePixel = 0, Parent = box },
			{ C.make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		slotButtons[r] = {}
		for s = 1, Rules.SLOTS do
			local u = Rules.Unit[s]
			local b = C.button({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, u[1] * R, 0.5, -u[2] * R), Size = UDim2.fromOffset(SLOT, SLOT), Text = "", TextSize = 13, Parent = box })
			slotButtons[r][s] = b
			b.Activated:Connect(function()
				local _, _, _, rd = Rules.Evaluate(pub, moves, damping)
				local rings = rd and rd.rings
				if not rings then return end
				if rings[r][s] > 0 then
					selected = (selected and selected.r == r and selected.s == s) and nil or { r = r, s = s }
				elseif selected and selected.r == r and #moves < pub.maxShifts then
					table.insert(moves, { ring = r, from = selected.s, to = s })
					selected = nil
				end
				refresh()
			end)
		end
	end

	local y = 136
	C.label({ Position = UDim2.fromOffset(0, y), Size = UDim2.fromOffset(70, 26), TextSize = 12, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Left, Text = "DAMPING", Parent = body })
	local dampButtons = {}
	for d = 1, Rules.DAMPING_MAX do
		local b = C.button({ Position = UDim2.fromOffset(70 + (d - 1) * 44, y), Size = UDim2.fromOffset(40, 26), Text = tostring(d), Parent = body })
		dampButtons[d] = b
		b.Activated:Connect(function() damping = d refresh() end)
	end
	local undo = C.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, y), Size = UDim2.fromOffset(80, 26), Text = "UNDO", Parent = body })
	undo.Activated:Connect(function() table.remove(moves) selected = nil refresh() end)
	local readout = C.label({ Position = UDim2.fromOffset(0, y + 32), Size = UDim2.new(1, 0, 0, 16), TextSize = 12, RichText = true, TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = body })
	local hint = C.label({ Position = UDim2.fromOffset(0, y + 52), Size = UDim2.new(1, 0, 0, 16), TextSize = 12, Font = Theme.FontBold, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = body })

	refresh = function()
		local ok, _, message, rd = Rules.Evaluate(pub, moves, damping)
		if rd then
			for r, ring in ipairs(rd.rings) do
				for s, m in ipairs(ring) do
					local b = slotButtons[r][s]
					local isSel = selected and selected.r == r and selected.s == s
					b.Text = m > 0 and tostring(m) or ""
					b.BackgroundColor3 = isSel and Theme.Amber or (m > 0 and Color3.fromRGB(70, 110, 120) or Theme.Track)
				end
				local x, yy, mag = Rules.Com(ring)
				local scale = math.min(1, mag / 4) * R / math.max(mag, 1e-6)
				markers[r].Position = UDim2.new(0.5, x * scale, 0.5, -yy * scale)
				markers[r].BackgroundColor3 = mag < 0.05 and Theme.Teal or Theme.Amber
			end
			readout.Text = ('OSCILLATION <font color="%s"><b>%.2f</b></font> / %.2f   SHIFTS %d/%d   POWER <font color="%s"><b>%d</b></font>/%d'):format(
				rd.oscillation <= pub.threshold + 1e-6 and "#38D2C8" or "#FFB020", rd.oscillation, pub.threshold, #moves, pub.maxShifts,
				damping <= pub.powerBudget and "#38D2C8" or "#EB4848", damping, pub.powerBudget)
		end
		for d, b in ipairs(dampButtons) do
			b.BackgroundColor3 = d == damping and Theme.Teal or Theme.Track
			b.TextColor3 = d == damping and Theme.Panel or Theme.Text
		end
		hint.Text = ok and "FIELD STABLE — submit to lock the rings" or message
		hint.TextColor3 = ok and Theme.Teal or Theme.Amber
	end
	refresh()

	return {
		getAction = function()
			local copy = {}
			for _, mv in ipairs(moves) do table.insert(copy, { ring = mv.ring, from = mv.from, to = mv.to }) end
			return { moves = copy, damping = damping }
		end,
	}
end

return GravityStabilizerUI
