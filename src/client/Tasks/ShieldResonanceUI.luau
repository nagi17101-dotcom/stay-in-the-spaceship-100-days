-- ShieldResonanceUI: ARM emitters (auto-assigned to working harmonic slots) and slide their bands with ◄ ►.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HUD = script.Parent.Parent.HUD
local Theme = require(HUD.Theme)
local C = require(HUD.Components)
local Rules = require(ReplicatedStorage.Shared.Minigames.ShieldResonanceRules)

local ShieldResonanceUI = {}
local METEOR, ION = Color3.fromRGB(200, 110, 60), Color3.fromRGB(150, 90, 210)
local TYPE_COLOR = { Kinetic = METEOR, Ionic = ION, Hybrid = Color3.fromRGB(180, 160, 80), Capacitor = Color3.fromRGB(80, 140, 200) }

function ShieldResonanceUI.Mount(body: Frame, pub)
	local armed = {}      -- ordered list of emitter indices
	local start = {}      -- emitter index -> start band
	for i in ipairs(pub.emitters) do start[i] = 1 end
	local B = Rules.BANDS
	local cw = math.floor(300 / B)

	local function placements()
		local out, slot = {}, 1
		for _, i in ipairs(armed) do
			if slot == pub.disabledSlot then slot += 1 end
			table.insert(out, { slot = slot, emitter = i, start = start[i] })
			slot += 1
		end
		return out
	end

	-- spectrum rows
	local threatAt = {}
	for _, th in ipairs(pub.threats) do for b = th.from, th.to do threatAt[b] = th.kind end end
	local threatCells, coverCells = {}, {}
	for b = 1, B do
		local t = threatAt[b]
		threatCells[b] = C.make("TextLabel", { Position = UDim2.fromOffset((b - 1) * cw, 0), Size = UDim2.fromOffset(cw - 2, 20), BorderSizePixel = 0,
			BackgroundColor3 = t == "meteor" and METEOR or (t == "ion" and ION or Theme.Track), Font = Theme.FontBold, TextSize = 11, TextColor3 = Theme.Text,
			Text = t == "meteor" and "M" or (t == "ion" and "I" or tostring(b)), Parent = body })
		coverCells[b] = C.make("Frame", { Position = UDim2.fromOffset((b - 1) * cw, 22), Size = UDim2.fromOffset(cw - 2, 8), BorderSizePixel = 0, BackgroundColor3 = Theme.Track, Parent = body })
	end

	local cards = {}
	local refresh
	for i, e in ipairs(pub.emitters) do
		local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
		local card = C.panel({ Position = UDim2.new(col * 0.5, col * 4, 0, 38 + row * 34), Size = UDim2.new(0.5, -4, 0, 30), BackgroundColor3 = Theme.Track, BackgroundTransparency = 0.2, Parent = body })
		C.make("Frame", { Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = TYPE_COLOR[e.type], BorderSizePixel = 0, Parent = card })
		local label = C.label({ Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -120, 1, 0), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
			Text = e.width > 0 and ("%s w%d · %dP"):format(e.type, e.width, e.cost) or ("Capacitor +%dP"):format(-e.cost), Parent = card })
		local arm = C.button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.fromOffset(44, 24), Text = "ARM", TextSize = 11, Parent = card })
		local left, right
		if e.width > 0 then
			left = C.button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -74, 0.5, 0), Size = UDim2.fromOffset(24, 24), Text = "◄", TextSize = 11, Parent = card })
			right = C.button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -48, 0.5, 0), Size = UDim2.fromOffset(24, 24), Text = "►", TextSize = 11, Parent = card })
			left.Activated:Connect(function() start[i] = math.max(1, start[i] - 1) refresh() end)
			right.Activated:Connect(function() start[i] = math.min(B - e.width + 1, start[i] + 1) refresh() end)
		end
		arm.Activated:Connect(function()
			local idx = table.find(armed, i)
			if idx then table.remove(armed, idx) else table.insert(armed, i) end
			refresh()
		end)
		cards[i] = { arm = arm, label = label, e = e }
	end

	local rows = math.ceil(#pub.emitters / 2)
	local y = 38 + rows * 34 + 4
	local readout = C.label({ Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 16), TextSize = 12, RichText = true, TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = body })
	local hint = C.label({ Position = UDim2.fromOffset(0, y + 18), Size = UDim2.new(1, 0, 0, 16), TextSize = 12, Font = Theme.FontBold, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = body })

	refresh = function()
		local pl = placements()
		local ok, _, message, r = Rules.Evaluate(pub, pl)
		for i, c in pairs(cards) do
			local on = table.find(armed, i) ~= nil
			c.arm.BackgroundColor3 = on and Theme.Teal or Theme.Track
			c.arm.TextColor3 = on and Theme.Panel or Theme.Text
			if c.e.width > 0 then c.label.Text = ("%s w%d · %dP · %d–%d"):format(c.e.type, c.e.width, c.e.cost, start[i], start[i] + c.e.width - 1) end
		end
		if r then
			for b = 1, B do
				local layers = r.coveredBy[b] and #r.coveredBy[b] or 0
				local t = threatAt[b]
				local color = Theme.Track
				if layers > 1 then color = Theme.Red
				elseif t then color = Rules.BandProtected(r, b, t) and Theme.Teal or Theme.Amber
				elseif layers == 1 then color = Color3.fromRGB(60, 90, 100) end
				coverCells[b].BackgroundColor3 = color
			end
			local slotsFree = pub.slots - (pub.disabledSlot and 1 or 0)
			readout.Text = ('POWER <font color="%s"><b>%d</b></font>/%d   SLOTS %d/%d%s%s'):format(r.power <= pub.powerBudget and "#38D2C8" or "#EB4848", r.power, pub.powerBudget,
				#pl, slotsFree, pub.disabledSlot and (" (slot " .. pub.disabledSlot .. " offline)") or "", pub.heatLimit and ("   OVERLAP " .. r.overlap .. "/" .. pub.heatLimit) or "")
		end
		hint.Text = ok and "SPECTRUM COVERED — submit to lock the shield" or message
		hint.TextColor3 = ok and Theme.Teal or Theme.Amber
	end
	refresh()

	return { getAction = function() return { placements = placements() } end }
end

return ShieldResonanceUI
