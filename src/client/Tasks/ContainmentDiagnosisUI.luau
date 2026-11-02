-- ContainmentDiagnosisUI: read the sensor grid, toggle ISOLATE on the faulty compartment,
-- pick the matching fault from the symptom chart and an available intervention.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HUD = script.Parent.Parent.HUD
local Theme = require(HUD.Theme)
local C = require(HUD.Components)
local Rules = require(ReplicatedStorage.Shared.Minigames.ContainmentDiagnosisRules)

local ContainmentDiagnosisUI = {}
local SEL = Color3.fromRGB(40, 90, 140)
local ISO = Color3.fromRGB(150, 70, 40)
local HIGH, LOW, DIM = "#EB4848", "#5AA0FF", "#5A6474"

function ContainmentDiagnosisUI.Mount(body: Frame, pub)
	local isolate, cause, fix = {}, nil, nil
	local refresh

	-- sensor grid: header + one row per compartment
	local colW = 1 / (#Rules.SENSORS + 1.6)
	for k, s in ipairs(Rules.SENSORS) do
		C.label({ Position = UDim2.new(colW * (k + 0.6), 0, 0, 0), Size = UDim2.new(colW, 0, 0, 14), TextSize = 10, TextColor3 = Theme.Dim,
			Text = ("%s %s"):format(s.id, s.unit), Parent = body })
	end
	local isoBtns = {}
	for i, comp in ipairs(pub.compartments) do
		local y = 16 + (i - 1) * 26
		local b = C.button({ Position = UDim2.fromOffset(0, y), Size = UDim2.new(colW * 1.6, -4, 0, 24), TextSize = 10, Text = "", Parent = body })
		b:SetAttribute("Base", comp.name)
		isoBtns[i] = b
		b.Activated:Connect(function() isolate[i] = not isolate[i] or nil refresh() end)
		for k, s in ipairs(Rules.SENSORS) do
			local r = comp.readings[s.id]
			local text
			if r.state == "OFF" then
				text = ('<font color="%s">OFFLINE</font>'):format(DIM)
			else
				local arrow = r.v > 0 and "▲" or (r.v < 0 and "▼" or "")
				local col = r.v > 0 and HIGH or (r.v < 0 and LOW or "#E2E8F0")
				if r.state == "STALE" then
					text = ('<font color="%s">%s%s <i>stale %dm</i></font>'):format(DIM, tostring(r.val), arrow, r.age or 5)
				else
					text = ('<font color="%s"><b>%s%s</b></font>'):format(col, tostring(r.val), arrow)
				end
			end
			C.label({ Position = UDim2.new(colW * (k + 0.6), 0, 0, y), Size = UDim2.new(colW, 0, 0, 24), TextSize = 11, RichText = true, Text = text, Parent = body })
		end
	end

	-- symptom chart (causes) on the left, interventions on the right
	local y0 = 16 + #pub.compartments * 26 + 6
	local causeBtns, fixBtns = {}, {}
	for i, c in ipairs(Rules.CAUSES) do
		local b = C.button({ Position = UDim2.fromOffset(0, y0 + (i - 1) * 21), Size = UDim2.new(0.55, -4, 0, 20), TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left, Text = ("  %s  ·  %s"):format(c.name, Rules.SigText(c)), Parent = body })
		causeBtns[c.id] = b
		b.Activated:Connect(function() cause = (cause ~= c.id) and c.id or nil refresh() end)
	end
	for i, f in ipairs(Rules.FIXES) do
		local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
		local blocked = pub.blocked and pub.blocked.fix == f.id
		local b = C.button({ Position = UDim2.new(0.55 + col * 0.225, 2, 0, y0 + row * 21), Size = UDim2.new(0.225, -4, 0, 20), TextSize = 10,
			Text = (blocked and "X " or "") .. f.name, Parent = body })
		if blocked then b.TextColor3 = Theme.Dim end
		fixBtns[f.id] = b
		b.Activated:Connect(function() fix = (fix ~= f.id) and f.id or nil refresh() end)
	end
	local y1 = y0 + #Rules.CAUSES * 21 + 4
	local hint = C.label({ Position = UDim2.fromOffset(0, y1), Size = UDim2.new(1, 0, 0, 30), TextSize = 11, Font = Theme.FontBold, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "", Parent = body })

	refresh = function()
		for i, b in ipairs(isoBtns) do
			b.Text = (isolate[i] and "[ISOLATED] " or "") .. b:GetAttribute("Base")
			b.BackgroundColor3 = isolate[i] and ISO or Theme.Track
		end
		for id, b in pairs(causeBtns) do b.BackgroundColor3 = (cause == id) and SEL or Theme.Track end
		for id, b in pairs(fixBtns) do b.BackgroundColor3 = (fix == id) and SEL or Theme.Track end
		local blockedText = pub.blocked and ("  X %s: %s."):format(Rules.FixName(pub.blocked.fix), pub.blocked.reason) or ""
		if not next(isolate) then
			hint.Text = "Fault = BOTH signature sensors fresh & off-nominal in one compartment. Stale or single anomalies are spillover." .. blockedText
			hint.TextColor3 = Theme.Dim
		elseif not cause or not fix then
			hint.Text = "Now pick the fault and an available intervention." .. blockedText
			hint.TextColor3 = Theme.Dim
		else
			hint.Text = "Ready — submit to isolate and apply " .. Rules.FixName(fix) .. "."
			hint.TextColor3 = Theme.Teal
		end
	end
	refresh()

	return {
		getAction = function()
			local list = {}
			for i in pairs(isolate) do table.insert(list, i) end
			table.sort(list)
			return { isolate = list, cause = cause or "", fix = fix or "" }
		end,
	}
end

return ContainmentDiagnosisUI
