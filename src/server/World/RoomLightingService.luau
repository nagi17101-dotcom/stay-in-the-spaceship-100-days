-- RoomLightingService: state-driven room lighting (neutral -> amber -> red) and door sign colors.
-- Server sets colors + Room "Mode" attribute; client adds a gentle critical pulse locally.
local CollectionService = game:GetService("CollectionService")

local RoomLighting = {}
local LIGHT = { Nominal = Color3.fromRGB(235, 240, 255), Warning = Color3.fromRGB(255, 170, 60), Critical = Color3.fromRGB(235, 60, 60) }
local SIGN = { Nominal = Color3.fromRGB(56, 210, 200), Warning = Color3.fromRGB(255, 176, 32), Critical = Color3.fromRGB(235, 72, 72) }
local RANK = { Nominal = 0, Warning = 1, Critical = 2 }

local function setSign(sign, mode)
	local label = sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui:FindFirstChild("Label")
	if label then label.TextColor3 = SIGN[mode] end
end

local function apply(room: Model, mode: string)
	room:SetAttribute("Mode", mode)
	for _, d in ipairs(room:GetDescendants()) do
		if CollectionService:HasTag(d, "RoomLight") then
			local c = mode == "Nominal" and (d:GetAttribute("NominalColor") or LIGHT.Nominal) or LIGHT[mode]
			d.Color = c
			local pl = d:FindFirstChildOfClass("PointLight")
			if pl then pl.Color = c end
		elseif CollectionService:HasTag(d, "RoomSign") and not d:GetAttribute("Target") then
			setSign(d, mode)
		end
	end
end

function RoomLighting.Start(run)
	local roomsFolder = workspace:WaitForChild("Ship"):WaitForChild("Rooms")
	local rooms = roomsFolder:GetChildren()

	local function refresh()
		for _, room in ipairs(rooms) do
			local worst = "Nominal"
			for sysName in string.gmatch(room:GetAttribute("Systems") or "", "[^,]+") do
				local sys = run.ship.systems[sysName]
				if sys and RANK[sys.mode] > RANK[worst] then worst = sys.mode end
			end
			if room:GetAttribute("Mode") ~= worst then apply(room, worst) end
		end
		for _, sign in ipairs(CollectionService:GetTagged("RoomSign")) do
			local target = sign:GetAttribute("Target")
			local room = target and roomsFolder:FindFirstChild(target)
			if room then setSign(sign, room:GetAttribute("Mode") or "Nominal") end
		end
	end

	run.ship.ModeChanged.Event:Connect(refresh)
	for _, room in ipairs(rooms) do apply(room, "Nominal") end
	refresh()
end

return RoomLighting
