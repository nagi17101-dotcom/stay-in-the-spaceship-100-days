-- ReactorPhaseUI: rotate each coil with ◄ ►, bring all three to one phase under the heat ceiling. Server re-validates.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HUD = script.Parent.Parent.HUD
local Theme = require(HUD.Theme)
local C = require(HUD.Components)
local Rules = require(ReplicatedStorage.Shared.Minigames.ReactorPhaseRules)

local ReactorPhaseUI = {}

function ReactorPhaseUI.Mount(body: Frame, pub)
	local tuning = {}
	for i = 1, #pub.coils do tuning[i] = 0 end

	C.label({ Size = UDim2.new(1, 0, 0, 14), TextSize = 11, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Left,
		Text = pub.coupled and "COUPLED: tuning a coil also shifts the next coil (A→B→C→A). Heat = coeff × steps (shortest way)."
			or "Bring all coils to one phase. Heat = coeff × steps (shortest way).", TextWrapped = true, Parent = body })

	local dials, offsets = {}, {}
	local colW = 1 / #pub.coils
	local refresh
	for i, coil in ipairs(pub.coils) do
		local col = C.make("Frame", { BackgroundTransparency = 1, Position = UDim2.new(colW * (i - 1), 4, 0, 22), Size = UDim2.new(colW, -8, 0, 150), Parent = body })
		C.label({ Size = UDim2.new(1, 0, 0, 16), Font = Theme.FontBold, TextSize = 13, Text = coil.label, Parent = col })
		C.label({ Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 14), TextSize = 11, TextColor3 = Theme.Dim, Text = ("heat ×%d"):format(coil.heatCoeff), Parent = col })
		-- dial: ring + needle
		local ring = C.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 34), Size = UDim2.fromOffset(64, 64),
			BackgroundColor3 = Theme.Track, Parent = col }, { C.make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		local needle = C.make("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 4, 0.45, 0),
			BackgroundColor3 = Theme.Teal, BorderSizePixel = 0, Parent = ring })
		local deg = C.label({ Position = UDim2.fromOffset(0, 100), Size = UDim2.new(1, 0, 0, 16), Font = Theme.FontBold, TextSize = 14, Text = "", Parent = col })
		local minus = C.button({ Position = UDim2.fromOffset(0, 120), Size = UDim2.new(0.33, -2, 0, 26), Text = "◄", Parent = col })
		offsets[i] = C.label({ Position = UDim2.new(0.33, 0, 0, 120), Size = UDim2.new(0.34, 0, 0, 26), TextSize = 12, TextColor3 = Theme.Dim, Text = "±0", Parent = col })
		local plus = C.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 120), Size = UDim2.new(0.33, -2, 0, 26), Text = "►", Parent = col })
		dials[i] = { needle = needle, deg = deg }
		minus.Activated:Connect(function() tuning[i] = (tuning[i] - 1) % Rules.STEPS refresh() end)
		plus.Activated:Connect(function() tuning[i] = (tuning[i] + 1) % Rules.STEPS refresh() end)
	end

	local readout = C.label({ Position = UDim2.fromOffset(0, 178), Size = UDim2.new(1, 0, 0, 16), TextSize = 12, RichText = true, TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = body })
	local hint = C.label({ Position = UDim2.fromOffset(0, 198), Size = UDim2.new(1, 0, 0, 16), TextSize = 12, Font = Theme.FontBold, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = body })

	refresh = function()
		local ok, _, message, r = Rules.Evaluate(pub, tuning)
		for i, d in ipairs(dials) do
			d.needle.Rotation = r.phases[i] * 30
			d.deg.Text = (r.phases[i] * 30) .. "°"
			d.needle.BackgroundColor3 = r.synced and Theme.Teal or Theme.Amber
			local t = tuning[i]
			offsets[i].Text = t == 0 and "±0" or (t <= Rules.STEPS / 2 and ("+" .. t) or ("−" .. (Rules.STEPS - t)))
		end
		readout.Text = ('SYNC <font color="%s"><b>%s</b></font>    HEAT <font color="%s"><b>%d</b></font> / %d'):format(
			r.synced and "#38D2C8" or "#FFB020", r.synced and "LOCKED" or "OFF", r.heat <= pub.heatCeiling and "#38D2C8" or "#EB4848", r.heat, pub.heatCeiling)
		hint.Text = ok and "PHASE LOCKED — submit to stabilize" or message
		hint.TextColor3 = ok and Theme.Teal or Theme.Amber
	end
	refresh()

	return {
		getAction = function() return { tuning = table.clone(tuning) } end,
	}
end

return ReactorPhaseUI
