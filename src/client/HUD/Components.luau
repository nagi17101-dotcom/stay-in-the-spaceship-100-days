-- Small UI component helpers (reusable, no game logic)
local Theme = require(script.Parent.Theme)
local C = {}

function C.make(class: string, props: {[string]: any}, children: {Instance}?)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then (inst :: any)[k] = v end
	end
	for _, child in ipairs(children or {}) do child.Parent = inst end
	if props.Parent then inst.Parent = props.Parent end
	return inst
end

function C.panel(props)
	props.BackgroundColor3 = props.BackgroundColor3 or Theme.Panel
	props.BackgroundTransparency = props.BackgroundTransparency or Theme.PanelTransparency
	props.BorderSizePixel = 0
	return C.make("Frame", props, {
		C.make("UICorner", { CornerRadius = Theme.Radius }),
		C.make("UIStroke", { Color = Theme.Stroke, Transparency = 0.3, Thickness = 1 }),
	})
end

function C.label(props)
	props.BackgroundTransparency = 1
	props.Font = props.Font or Theme.Font
	props.TextColor3 = props.TextColor3 or Theme.Text
	props.TextScaled = false
	return C.make("TextLabel", props)
end

-- Thin progress bar; returns frame, fill
function C.bar(props)
	props.BackgroundColor3 = Theme.Track
	props.BorderSizePixel = 0
	local frame = C.make("Frame", props, { C.make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local fill = C.make("Frame", {
		Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Teal, BorderSizePixel = 0, Parent = frame,
	}, { C.make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	return frame, fill
end

function C.button(props)
	props.BackgroundColor3 = props.BackgroundColor3 or Theme.Track
	props.BorderSizePixel = 0
	props.Font = props.Font or Theme.FontBold
	props.TextColor3 = props.TextColor3 or Theme.Text
	props.TextSize = props.TextSize or 13
	props.AutoButtonColor = true
	return C.make("TextButton", props, { C.make("UICorner", { CornerRadius = UDim.new(0, 6) }) })
end

return C
