-- FabricatorAssemblyUI: pick a socket, then a part to mount it. Mount order matters (socket dependencies).
-- R = optional reinforcement socket (Advanced): extra material, extra repair.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HUD = script.Parent.Parent.HUD
local Theme = require(HUD.Theme)
local C = require(HUD.Components)
local Rules = require(ReplicatedStorage.Shared.Minigames.FabricatorAssemblyRules)

local FabricatorAssemblyUI = {}
local SEL = Color3.fromRGB(40, 90, 140)
local DONE = Color3.fromRGB(56, 160, 150)

function FabricatorAssemblyUI.Mount(body: Frame, pub)
	local steps = {}
	local refresh
	local selected = nil
	local bp = pub.blueprint
	local head = ('<b>%s</b> → %s +%d   <font color="#8A96A6">cost: %s</font>'):format(bp.name, bp.system, bp.amount, bp.label)
	if pub.upgrade then
		head ..= ('\n<font color="#FFB020">R optional: +%s → +%d more</font>'):format(pub.upgrade.label, pub.upgrade.amount)
	end
	C.label({ Size = UDim2.new(1, 0, 0, 30), TextSize = 12, RichText = true, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, Text = head, Parent = body })

	local socketBtns, partBtns = {}, {}
	local ROW = 24
	for i, s in ipairs(pub.sockets) do
		local needs = #s.needs > 0 and ("after " .. table.concat(s.needs, ",")) or "base"
		local b = C.button({ Position = UDim2.fromOffset(0, 32 + (i - 1) * (ROW + 2)), Size = UDim2.new(0.5, -4, 0, ROW), TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = body })
		b:SetAttribute("Base", ("%s%s  %s Ø%d–%d  · %s"):format(s.optional and "★" or "", s.id, s.connector, s.lo, s.hi, needs))
		socketBtns[s.id] = b
		b.Activated:Connect(function()
			selected = (selected ~= s.id) and s.id or nil
			refresh()
		end)
	end
	for i, p in ipairs(pub.parts) do
		local b = C.button({ Position = UDim2.new(0.5, 4, 0, 32 + (i - 1) * 21), Size = UDim2.new(0.5, -4, 0, 20), TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = body })
		b:SetAttribute("Base", ("#%d  %s Ø%d  %dkg"):format(i, p.connector, p.size, p.mass))
		partBtns[i] = b
		b.Activated:Connect(function()
			if not selected then return end
			for _, st in ipairs(steps) do if st.part == i or st.socket == selected then return end end
			table.insert(steps, { socket = selected, part = i })
			selected = nil
			refresh()
		end)
	end

	local y0 = 32 + math.max(#pub.sockets * (ROW + 2), #pub.parts * 21) + 4
	local readout = C.label({ Position = UDim2.fromOffset(0, y0), Size = UDim2.new(1, -150, 0, 16), TextSize = 12, RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = body })
	local hint = C.label({ Position = UDim2.fromOffset(0, y0 + 17), Size = UDim2.new(1, -150, 0, 30), TextSize = 11, Font = Theme.FontBold, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "", Parent = body })
	local undo = C.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -74, 0, y0), Size = UDim2.fromOffset(66, 24), Text = "UNDO", Parent = body })
	local clear = C.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, y0), Size = UDim2.fromOffset(66, 24), Text = "CLEAR", Parent = body })

	refresh = function()
		local ok, reason, message, st = Rules.Evaluate(pub, steps)
		for id, b in pairs(socketBtns) do
			local part = st.filled[id]
			b.Text = b:GetAttribute("Base") .. (part and ("  ▸ #" .. part) or "")
			b.BackgroundColor3 = (selected == id) and SEL or (part and DONE) or Theme.Track
		end
		for i, b in pairs(partBtns) do
			local used = st.used[i]
			b.Text = b:GetAttribute("Base") .. (used and ("  ▸ " .. used) or "")
			b.BackgroundColor3 = used and DONE or Theme.Track
		end
		local over = st.load > pub.maxLoad
		local seq = {}
		for _, s in ipairs(steps) do table.insert(seq, s.socket) end
		readout.Text = ('LOAD <font color="%s"><b>%d</b></font>/%d kg   ORDER %s'):format(over and "#EB4848" or "#38D2C8", st.load, pub.maxLoad, #seq > 0 and table.concat(seq, "→") or "—")
		if ok then
			hint.Text, hint.TextColor3 = message .. " Submit to fabricate.", Theme.Teal
		elseif #steps == 0 then
			hint.Text, hint.TextColor3 = selected and ("Socket " .. selected .. ": now pick a part.") or "Pick a socket, then a compatible part. Respect the mount order.", Theme.Dim
		elseif reason == "Incomplete" and not selected then
			hint.Text, hint.TextColor3 = message, Theme.Dim
		else
			hint.Text, hint.TextColor3 = selected and ("Socket " .. selected .. ": now pick a part.") or message, Theme.Amber
		end
	end

	undo.Activated:Connect(function() table.remove(steps) selected = nil refresh() end)
	clear.Activated:Connect(function() table.clear(steps) selected = nil refresh() end)
	refresh()

	return {
		getAction = function()
			local copy = {}
			for _, s in ipairs(steps) do table.insert(copy, { socket = s.socket, part = s.part }) end
			return { steps = copy }
		end,
	}
end

return FabricatorAssemblyUI
