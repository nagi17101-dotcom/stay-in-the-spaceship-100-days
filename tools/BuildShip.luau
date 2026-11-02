--[[
	BuildShip.luau — regenerates the M1 ship blockout in Workspace.Ship (+ deep-space Lighting).
	Run in Roblox Studio: View > Command Bar, paste this whole file, press Enter (Edit mode).
	Rojo syncs only code (src/). The world lives in the place file; this script is its source of truth.
	Idempotent: destroys and rebuilds Workspace.Ship.

	Contract with code (do not rename without updating src/):
	  Rooms: Workspace.Ship.Rooms.<RoomId> Model, attrs RoomId, DisplayName, Systems ("A,B"), Mode
	  Tags:  RoomLight (Part, optional attr NominalColor), RoomSign (Part+SurfaceGui.Label, optional attr Target),
	         RepairStation (Model: StationId, MinigameId, System; PrimaryPart has ProximityPrompt),
	         SalvagePoint (Model: SalvageType), QuickAction (Model: ActionId)
]]
local CS = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local old = workspace:FindFirstChild("Ship")
if old then old:Destroy() end

local Y, H = 100, 12
local DOOR_W, DOOR_H = 10, 9
local TEAL = Color3.fromRGB(56, 210, 200)
local COL = { Floor = Color3.fromRGB(46, 51, 60), Wall = Color3.fromRGB(196, 202, 210), Ceil = Color3.fromRGB(34, 38, 46), Trim = Color3.fromRGB(70, 78, 92) }

local ship = Instance.new("Model")
ship.Name = "Ship"
local roomsF = Instance.new("Folder")
roomsF.Name = "Rooms"
roomsF.Parent = ship

local function part(parent, name, size, cf, color, mat, props)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in pairs(props or {}) do p[k] = v end
	p.Parent = parent
	return p
end

local function wall(parent, axis, cx, cz, len, opening)
	local function seg(a, b, y0, y1, name, color, mat, props)
		if b - a <= 0.01 or y1 - y0 <= 0.01 then return end
		local mid, l = (a + b) / 2, b - a
		local size = axis == "x" and Vector3.new(l, y1 - y0, 1) or Vector3.new(1, y1 - y0, l)
		local pos = axis == "x" and Vector3.new(cx + mid, Y + (y0 + y1) / 2, cz) or Vector3.new(cx, Y + (y0 + y1) / 2, cz + mid)
		return part(parent, name or "Wall", size, CFrame.new(pos), color or COL.Wall, mat, props)
	end
	local half = len / 2
	if opening == "door" then
		seg(-half, -DOOR_W / 2, 0, H)
		seg(DOOR_W / 2, half, 0, H)
		seg(-DOOR_W / 2, DOOR_W / 2, DOOR_H, H, "Lintel", COL.Trim)
	elseif opening == "window" then
		local w = len - 8
		seg(-half, -w / 2, 0, H)
		seg(w / 2, half, 0, H)
		seg(-w / 2, w / 2, 0, 3)
		seg(-w / 2, w / 2, 10, H)
		seg(-w / 2, w / 2, 3, 10, "Window", Color3.fromRGB(10, 14, 22), Enum.Material.Glass, { Transparency = 0.75 })
	else
		seg(-half, half, 0, H)
	end
end

local function lightPanel(room, x, z)
	local p = part(room, "CeilingLight", Vector3.new(6, 0.4, 2), CFrame.new(x, Y + H - 0.3, z), Color3.fromRGB(235, 240, 255), Enum.Material.Neon)
	local l = Instance.new("PointLight")
	l.Range, l.Brightness, l.Color, l.Shadows = 30, 2, p.Color, false
	l.Parent = p
	CS:AddTag(p, "RoomLight")
end

local function slab(room, cx, cz, sx, sz)
	part(room, "Floor", Vector3.new(sx, 1, sz), CFrame.new(cx, Y - 0.5, cz), COL.Floor, Enum.Material.DiamondPlate)
	part(room, "Ceiling", Vector3.new(sx, 1, sz), CFrame.new(cx, Y + H + 0.5, cz), COL.Ceil)
end

local function newRoom(id, display, systems)
	local m = Instance.new("Model")
	m.Name = id
	m:SetAttribute("RoomId", id)
	m:SetAttribute("DisplayName", display)
	m:SetAttribute("Systems", systems)
	m:SetAttribute("Mode", "Nominal")
	m.Parent = roomsF
	return m
end

local function room(id, display, systems, cx, cz, sx, sz, open)
	local m = newRoom(id, display, systems)
	slab(m, cx, cz, sx + 1, sz + 1)
	wall(m, "x", cx, cz - sz / 2, sx + 1, open.N)
	wall(m, "x", cx, cz + sz / 2, sx + 1, open.S)
	wall(m, "z", cx + sx / 2, cz, sz + 1, open.E)
	wall(m, "z", cx - sx / 2, cz, sz + 1, open.W)
	return m
end

local function corridor(id, cx, cz, sx, sz, alongX)
	local m = newRoom(id, "Corridor", "Hull")
	slab(m, cx, cz, sx, sz)
	for _, s in ipairs({ -1, 1 }) do
		if alongX then
			part(m, "PathStrip", Vector3.new(sx, 0.1, 0.3), CFrame.new(cx, Y + 0.05, cz + s * (sz / 2 - 1)), TEAL, Enum.Material.Neon)
		else
			part(m, "PathStrip", Vector3.new(0.3, 0.1, sz), CFrame.new(cx + s * (sx / 2 - 1), Y + 0.05, cz), TEAL, Enum.Material.Neon)
		end
	end
	if alongX then
		wall(m, "x", cx, cz - sz / 2, sx)
		wall(m, "x", cx, cz + sz / 2, sx)
	else
		wall(m, "z", cx - sx / 2, cz, sz)
		wall(m, "z", cx + sx / 2, cz, sz)
	end
	lightPanel(m, cx, cz)
end

local function sign(parent, text, pos, outward, target)
	local p = part(parent, "Sign", Vector3.new(9, 1.6, 0.2), CFrame.lookAt(pos, pos + outward), Color3.fromRGB(18, 22, 28), nil, { CanCollide = false })
	local g = Instance.new("SurfaceGui")
	g.Face, g.PixelsPerStud, g.LightInfluence = Enum.NormalId.Front, 40, 0
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Name, t.Size, t.BackgroundTransparency = "Label", UDim2.fromScale(1, 1), 1
	t.Font, t.TextScaled, t.Text, t.TextColor3 = Enum.Font.GothamBold, true, text, TEAL
	t.Parent = g
	if target then p:SetAttribute("Target", target) end
	CS:AddTag(p, "RoomSign")
end

-- Layout: Hub center, Bridge fore (-Z), Reactor aft (+Z), Life Support west, Workshop east
local hub = room("Hub", "Main Junction", "Hull", 0, 0, 18, 18, { N = "door", S = "door", E = "door", W = "door" })
lightPanel(hub, 0, 0)
corridor("CorridorFore", 0, -18, 10, 18, false)
corridor("CorridorAft", 0, 18, 10, 18, false)
corridor("CorridorWest", -17, 0, 16, 10, true)
corridor("CorridorEast", 17, 0, 16, 10, true)

local bridge = room("Bridge", "Bridge / Nav", "Navigation,Comms,Drive", 0, -38, 30, 22, { N = "window", S = "door" })
local life = room("LifeSupport", "Life Support", "Oxygen,Hull", -36, 0, 22, 22, { E = "door" })
local shop = room("Workshop", "Workshop", "Cargo", 36, 0, 22, 22, { W = "door" })
local reactor = room("Reactor", "Reactor / Power", "Reactor,Power,Cooling", 0, 40, 30, 26, { N = "door" })
lightPanel(bridge, -7, -38) lightPanel(bridge, 7, -38)
lightPanel(reactor, -7, 40) lightPanel(reactor, 7, 40)
lightPanel(life, -36, -5) lightPanel(life, -36, 5)
lightPanel(shop, 36, -5) lightPanel(shop, 36, 5)

local SY = Y + DOOR_H + 1.3
sign(bridge, "BRIDGE / NAV", Vector3.new(0, SY, -26.8), Vector3.new(0, 0, 1))
sign(reactor, "REACTOR / POWER", Vector3.new(0, SY, 26.8), Vector3.new(0, 0, -1))
sign(life, "LIFE SUPPORT", Vector3.new(-24.8, SY, 0), Vector3.new(1, 0, 0))
sign(shop, "WORKSHOP", Vector3.new(24.8, SY, 0), Vector3.new(-1, 0, 0))
sign(hub, "▲ BRIDGE", Vector3.new(0, SY, -8.8), Vector3.new(0, 0, 1), "Bridge")
sign(hub, "▼ REACTOR", Vector3.new(0, SY, 8.8), Vector3.new(0, 0, -1), "Reactor")
sign(hub, "◄ LIFE SUPPORT", Vector3.new(-8.8, SY, 0), Vector3.new(1, 0, 0), "LifeSupport")
sign(hub, "WORKSHOP ►", Vector3.new(8.8, SY, 0), Vector3.new(-1, 0, 0), "Workshop")

-- Props (blockout)
part(bridge, "HelmConsole", Vector3.new(10, 3, 3), CFrame.new(0, Y + 1.5, -44), COL.Trim)
part(bridge, "HelmScreen", Vector3.new(9, 0.2, 2), CFrame.new(0, Y + 3.1, -44) * CFrame.Angles(math.rad(-20), 0, 0), TEAL, Enum.Material.Neon)
for i = -1, 1 do
	part(life, "O2Tank", Vector3.new(7, 4, 4), CFrame.new(-44, Y + 3.5, i * 6) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(150, 170, 190), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
end
part(life, "FilterRack", Vector3.new(6, 6, 2), CFrame.new(-36, Y + 3, -9.5), COL.Trim)
part(shop, "Workbench", Vector3.new(8, 3, 4), CFrame.new(36, Y + 1.5, -8), Color3.fromRGB(110, 90, 70), Enum.Material.Wood)
part(shop, "Fabricator", Vector3.new(5, 7, 5), CFrame.new(44, Y + 3.5, 6), COL.Trim, Enum.Material.Metal)
local coreCf = CFrame.new(0, Y + 5, 46) * CFrame.Angles(0, 0, math.rad(90))
local core = part(reactor, "Core", Vector3.new(10, 5, 5), coreCf, TEAL, Enum.Material.Neon, { Shape = Enum.PartType.Cylinder })
core:SetAttribute("NominalColor", TEAL)
CS:AddTag(core, "RoomLight")
part(reactor, "CoreShield", Vector3.new(10, 9, 9), coreCf, Color3.fromRGB(150, 200, 220), Enum.Material.Glass, { Shape = Enum.PartType.Cylinder, Transparency = 0.7 })

local function prompt(parent, objectText, actionText, hold)
	local pp = Instance.new("ProximityPrompt")
	pp.ObjectText, pp.ActionText, pp.HoldDuration = objectText, actionText, hold
	pp.MaxActivationDistance, pp.RequiresLineOfSight = 8, false
	pp.Parent = parent
end

-- Repair stations (minigames)
local function station(parentRoom, id, minigameId, system, label, pos, facing)
	local m = Instance.new("Model")
	m.Name = "Station_" .. minigameId
	m:SetAttribute("StationId", id)
	m:SetAttribute("MinigameId", minigameId)
	m:SetAttribute("System", system)
	local body = part(m, "Console", Vector3.new(4, 4, 1.5), CFrame.lookAt(pos, pos + facing), COL.Trim, Enum.Material.Metal)
	local scr = part(m, "Screen", Vector3.new(3.4, 2.4, 0.1), body.CFrame * CFrame.new(0, 0.4, -0.8), TEAL, Enum.Material.Neon)
	scr:SetAttribute("NominalColor", TEAL)
	CS:AddTag(scr, "RoomLight")
	prompt(body, label, "Repair", 0.3)
	m.PrimaryPart = body
	CS:AddTag(m, "RepairStation")
	m.Parent = parentRoom
end
station(reactor, "RX-PowerBus", "PowerBus", "Power", "Power Bus", Vector3.new(-13.5, Y + 2, 40), Vector3.new(1, 0, 0))
station(reactor, "RX-CoolantLoop", "CoolantLoop", "Cooling", "Coolant Loop", Vector3.new(13.5, Y + 2, 40), Vector3.new(-1, 0, 0))
station(hub, "HUB-HullSeal", "HullSeal", "Hull", "Hull Seal", Vector3.new(-6.5, Y + 2, 7.8), Vector3.new(0, 0, -1))
station(life, "LS-OxygenMixer", "OxygenMixer", "Oxygen", "Oxygen Mixer", Vector3.new(-38, Y + 2, 9.8), Vector3.new(0, 0, -1))
station(reactor, "RX-ReactorPhase", "ReactorPhase", "Reactor", "Reactor Phase", Vector3.new(8, Y + 2, 51.8), Vector3.new(0, 0, -1))
station(bridge, "BR-SignalTriangulator", "SignalTriangulator", "Comms", "Signal Triangulator", Vector3.new(-13.5, Y + 2, -40), Vector3.new(1, 0, 0))
station(bridge, "BR-ThrusterMatrix", "ThrusterMatrix", "Drive", "Thruster Matrix", Vector3.new(13.5, Y + 2, -40), Vector3.new(-1, 0, 0))
station(shop, "WS-GravityStabilizer", "GravityStabilizer", "Cargo", "Gravity Stabilizer", Vector3.new(28, Y + 2, -9.8), Vector3.new(0, 0, 1))
station(shop, "WS-DroneSalvage", "DroneSalvage", "Cargo", "Drone Bay", Vector3.new(46.3, Y + 2, 0), Vector3.new(-1, 0, 0))

-- Salvage points + emergency quick actions
local function point(rm, tag, attr, value, name, objectText, actionText, hold, pos, size, color)
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute(attr, value)
	local body = part(m, "Body", size, CFrame.new(pos), color, Enum.Material.Metal)
	part(m, "Indicator", Vector3.new(size.X * 0.8, 0.3, size.Z * 0.8), CFrame.new(pos + Vector3.new(0, size.Y / 2 + 0.15, 0)), Color3.fromRGB(255, 176, 32), Enum.Material.Neon, { CanCollide = false })
	prompt(body, objectText, actionText, hold)
	m.PrimaryPart = body
	CS:AddTag(m, tag)
	m.Parent = rm
end
local GRAY = Color3.fromRGB(90, 96, 108)
point(shop, "SalvagePoint", "SalvageType", "DebrisReceiver", "DebrisReceiver", "Debris Receiver", "Salvage", 2, Vector3.new(44, Y + 1.5, -6), Vector3.new(5, 3, 5), GRAY)
point(life, "SalvagePoint", "SalvageType", "SupplyLocker", "SupplyLocker", "Supply Locker", "Salvage", 2, Vector3.new(-29, Y + 2.5, -9.5), Vector3.new(4, 5, 2), GRAY)
point(reactor, "SalvagePoint", "SalvageType", "ScrapBin", "ScrapBin", "Scrap Bin", "Salvage", 2, Vector3.new(-11, Y + 1.25, 50), Vector3.new(4, 2.5, 4), GRAY)
point(life, "QuickAction", "ActionId", "EmergencyO2", "EmergencyO2", "Emergency O2 Reserve (1 Filter)", "Use", 1.5, Vector3.new(-30, Y + 3, 9), Vector3.new(3, 6, 3), Color3.fromRGB(70, 140, 110))
point(hub, "QuickAction", "ActionId", "HullPatch", "HullPatchLocker", "Hull Patch Kit (2 Scrap + 1 Sealant)", "Use", 1.5, Vector3.new(7, Y + 2.5, -7.8), Vector3.new(3, 5, 1.5), Color3.fromRGB(150, 110, 60))

-- Day 100 Beacon Fabricator (FinaleStation)
do
	local m = Instance.new("Model")
	m.Name = "BeaconFabricator"
	local body = part(m, "Body", Vector3.new(4, 3, 3), CFrame.new(38, Y + 1.5, 9), COL.Trim, Enum.Material.Metal)
	part(m, "Indicator", Vector3.new(3, 0.3, 2), CFrame.new(38, Y + 3.15, 9), Color3.fromRGB(255, 176, 32), Enum.Material.Neon, { CanCollide = false })
	prompt(body, "Beacon Fabricator (2 Filament + 1 Scrap)", "Build Transmitter", 1.5)
	m.PrimaryPart = body
	CS:AddTag(m, "FinaleStation")
	m.Parent = shop
end

local spawn = Instance.new("SpawnLocation")
spawn.Name, spawn.Size, spawn.CFrame = "CrewSpawn", Vector3.new(6, 0.2, 6), CFrame.new(0, Y + 0.1, 2)
spawn.Anchored, spawn.Neutral, spawn.Duration = true, true, 0
spawn.Enabled = false -- players spawn in the Lobby; crew are moved aboard at launch
spawn.Color, spawn.Material = COL.Trim, Enum.Material.SmoothPlastic
spawn.Parent = ship
ship.Parent = workspace

-- Template leftovers: hidden, not deleted
local oldSpawn = workspace:FindFirstChild("SpawnLocation")
if oldSpawn then oldSpawn.Enabled, oldSpawn.Transparency, oldSpawn.CanCollide = false, 1, false end
local bp = workspace:FindFirstChild("Baseplate")
if bp then bp.Transparency, bp.CanCollide = 1, false end

-- Deep space: no daylight, star-black outside every window
Lighting.ClockTime = 0
Lighting.Brightness = 1
Lighting.Ambient = Color3.fromRGB(92, 98, 112)
Lighting.OutdoorAmbient = Color3.fromRGB(18, 20, 26)
Lighting.EnvironmentDiffuseScale = 0.5
Lighting.EnvironmentSpecularScale = 0.3
for _, c in ipairs(Lighting:GetChildren()) do
	if c:IsA("Atmosphere") or c:IsA("Clouds") then c:Destroy() end
end
local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
sky.StarCount, sky.CelestialBodiesShown = 3000, false
sky.Parent = Lighting
print("[BuildShip] Ship rebuilt:", #ship:GetDescendants(), "instances")
