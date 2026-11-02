-- OxygenMixerUI: three flow dials + filter mode, live readout against the safe band. Server re-validates.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HUD = script.Parent.Parent.HUD
local Theme = require(HUD.Theme)
local C = require(HUD.Components)
local Rules = require(ReplicatedStorage.Shared.Minigames.OxygenMixerRules)

local OxygenMixerUI = {}

function OxygenMixerUI.Mount(body: Frame, pub)
	local flows = {}
	for i = 1, #pub.sources do flows[i] = 0 end
	local filter = "Standard"

	-- Sources
	local valueLabels = {}
	for i, s in ipairs(pub.sources) do
		local y = (i - 1) * 40
		local info = ("%s\n<font color=\"#8A96A6\">O₂ %d%%%s · contaminant %d</font>"):format(s.label, s.purity,
			s.wave and (" (wave: " .. table.concat((function()
				local t = {}
				for _, d in ipairs(s.wave) do table.insert(t, tostring(s.purity + d)) end
				return t
			end)(), " ") .. ")") or "", s.contaminant)
		C.label({ Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, -120, 0, 34), TextSize = 12, RichText = true, TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left, Text = info, TextColor3 = s.wave and Theme.Amber or Theme.Text, Parent = body })
		local minus = C.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -78, 0, y + 3), Size = UDim2.fromOffset(28, 28), Text = "−", Parent = body })
		valueLabels[i] = C.label({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -36, 0, y + 3), Size = UDim2.fromOffset(40, 28), Font = Theme.FontBold, TextSize = 15, Text = "0", Parent = body })
		local plus = C.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, y + 3), Size = UDim2.fromOffset(28, 28), Text = "+", Parent = body })
		minus.Activated:Connect(function() flows[i] = math.max(0, flows[i] - 1) OxygenMixerUI._refresh() end)
		plus.Activated:Connect(function() flows[i] = math.min(pub.flowMax, flows[i] + 1) OxygenMixerUI._refresh() end)
	end

	-- Filter mode
	local fy = #pub.sources * 40 + 4
	C.label({ Position = UDim2.fromOffset(0, fy), Size = UDim2.fromOffset(60, 26), TextSize = 12, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Left, Text = "FILTER", Parent = body })
	local filterButtons = {}
	for i, name in ipairs(Rules.FilterOrder) do
		local f = Rules.Filters[name]
		local b = C.button({ Position = UDim2.fromOffset(60 + (i - 1) * 104, fy), Size = UDim2.fromOffset(100, 26), TextSize = 11,
			Text = ("%s −%d%% · %dP"):format(string.upper(name), f.efficiency * 100, f.power), Parent = body })
		filterButtons[name] = b
		b.Activated:Connect(function() filter = name OxygenMixerUI._refresh() end)
	end

	-- Readout
	local readout = C.label({ Position = UDim2.fromOffset(0, fy + 34), Size = UDim2.new(1, 0, 0, 34), TextSize = 12, RichText = true, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = body })
	local hint = C.label({ Position = UDim2.fromOffset(0, fy + 70), Size = UDim2.new(1, 0, 0, 16), TextSize = 12, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = body })

	local function color(ok) return ok and "#38D2C8" or "#FFB020" end
	function OxygenMixerUI._refresh()
		for i, l in ipairs(valueLabels) do l.Text = tostring(flows[i]) end
		for name, b in pairs(filterButtons) do
			b.BackgroundColor3 = name == filter and Theme.Teal or Theme.Track
			b.TextColor3 = name == filter and Theme.Panel or Theme.Text
		end
		local ok, _, message, r = Rules.Evaluate(pub, flows, filter)
		local o2ok = r.flow > 0 and r.o2Min >= pub.o2Low - 1e-6 and r.o2Max <= pub.o2High + 1e-6
		local o2txt = r.flow == 0 and "—" or (pub.ticks > 1 and ("%.1f–%.1f"):format(r.o2Min, r.o2Max) or ("%.1f"):format(r.o2Min))
		readout.Text = ('O₂ <font color="%s"><b>%s</b></font> (safe %d–%d)   CONTAM <font color="%s"><b>%.1f</b></font> (≤ %.1f)\nFLOW <font color="%s"><b>%d</b></font> (≥ %d)   POWER <font color="%s"><b>%d</b></font> (≤ %d)'):format(
			color(o2ok), o2txt, pub.o2Low, pub.o2High,
			color(r.flow > 0 and r.contaminant <= pub.contaminantMax + 1e-6), r.contaminant, pub.contaminantMax,
			color(r.flow >= pub.minFlow), r.flow, pub.minFlow,
			color(r.power <= pub.powerBudget), r.power, pub.powerBudget)
		hint.Text = ok and "MIX STABLE — submit to commit" or message
		hint.TextColor3 = ok and Theme.Teal or Theme.Amber
	end
	OxygenMixerUI._refresh()

	return {
		getAction = function() return { flows = table.clone(flows), filter = filter } end,
	}
end

return OxygenMixerUI
