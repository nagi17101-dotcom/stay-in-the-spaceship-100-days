--[[
	BuildLobby.luau — regenerates Workspace.Lobby (orbital embarkation terminal). Studio Command Bar, Edit mode.
	Idempotent. Contract with code: Workspace.Lobby.LobbySpawn (enabled SpawnLocation),
	Workspace.Lobby.PartyDisplay (Part + SurfaceGui.Label, text driven by LobbyPartyService).
	Ship's CrewSpawn is disabled: everyone spawns here; crew are moved aboard at launch.
]]
local old = workspace:FindFirstChild("Lobby")
if old then old:Destroy() end

local Y, H = 100, 12
local CX, CZ, SX, SZ = 0, -112, 36, 26
local TEAL = Color3.fromRGB(56, 210, 200)
local AMBER = Color3.fromRGB(255, 176, 32)
local COL = { Floor = Color3.fromRGB(46, 51, 60), Wall = Color3.fromRGB(196, 202, 210), Ceil = Color3.fromRGB(34, 38, 46), Trim = Color3.fromRGB(70, 78, 92) }

local lobby = Instance.new("Model")
lobby.Name = "Lobby"

local function part(name, size, cf, color, mat, props)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in pairs(props or {}) do p[k] = v end
	p.Parent = lobby
	return p
end

local function screen(name, size, pos, facing, text, color, textSize)
	local p = part(name, size, CFrame.lookAt(pos, pos + facing), Color3.fromRGB(14, 18, 24), nil, { CanCollide = false })
	local g = Instance.new("SurfaceGui")
	g.Face, g.PixelsPerStud, g.LightInfluence = Enum.NormalId.Front, 30, 0
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Name, t.Size, t.BackgroundTransparency = "Label", UDim2.fromScale(1, 1), 1
	t.Font, t.TextColor3, t.Text = Enum.Font.GothamBold, color, text
	if textSize then t.TextSize = textSize else t.TextScaled = true end
	t.Parent = g
	return p
end

-- Shell
part("Floor", Vector3.new(SX + 1, 1, SZ + 1), CFrame.new(CX, Y - 0.5, CZ), COL.Floor, Enum.Material.DiamondPlate)
part("Ceiling", Vector3.new(SX + 1, 1, SZ + 1), CFrame.new(CX, Y + H + 0.5, CZ), COL.Ceil)
part("WallN", Vector3.new(SX + 1, H, 1), CFrame.new(CX, Y + H / 2, CZ - SZ / 2), COL.Wall)
part("WallE", Vector3.new(1, H, SZ + 1), CFrame.new(CX + SX / 2, Y + H / 2, CZ), COL.Wall)
part("WallW", Vector3.new(1, H, SZ + 1), CFrame.new(CX - SX / 2, Y + H / 2, CZ), COL.Wall)
-- South wall: wide observation window facing the ship (star-black space)
local zS, ww = CZ + SZ / 2, SX - 8
part("WallS_L", Vector3.new(4.5, H, 1), CFrame.new(CX - SX / 2 + 2.25, Y + H / 2, zS), COL.Wall)
part("WallS_R", Vector3.new(4.5, H, 1), CFrame.new(CX + SX / 2 - 2.25, Y + H / 2, zS), COL.Wall)
part("WallS_Low", Vector3.new(ww, 2.5, 1), CFrame.new(CX, Y + 1.25, zS), COL.Wall)
part("WallS_High", Vector3.new(ww, 2, 1), CFrame.new(CX, Y + H - 1, zS), COL.Wall)
part("ObservationWindow", Vector3.new(ww, H - 4.5, 0.4), CFrame.new(CX, Y + 2.5 + (H - 4.5) / 2, zS), Color3.fromRGB(10, 14, 22), Enum.Material.Glass, { Transparency = 0.8 })

-- Lights
for _, x in ipairs({ -9, 9 }) do
	for _, z in ipairs({ CZ - 6, CZ + 6 }) do
		local p = part("CeilingLight", Vector3.new(6, 0.4, 2), CFrame.new(x, Y + H - 0.3, z), Color3.fromRGB(235, 240, 255), Enum.Material.Neon)
		local l = Instance.new("PointLight")
		l.Range, l.Brightness, l.Shadows = 30, 2, false
		l.Parent = p
	end
end

-- Spawn: north side, facing the window, party display and gate
local spawn = Instance.new("SpawnLocation")
spawn.Name, spawn.Size = "LobbySpawn", Vector3.new(8, 0.2, 6)
spawn.CFrame = CFrame.new(CX, Y + 0.1, CZ - 8)
spawn.Anchored, spawn.Neutral, spawn.Duration, spawn.Enabled = true, true, 0, true
spawn.Color, spawn.Material = COL.Trim, Enum.Material.SmoothPlastic
spawn.Parent = lobby

-- Party display (west wall) and boarding gate (east wall)
screen("PartyDisplay", Vector3.new(12, 5, 0.3), Vector3.new(CX - SX / 2 + 0.7, Y + 6, CZ), Vector3.new(1, 0, 0), "NO CREW FORMED\nCREATE CREW TO BEGIN", TEAL)
screen("PartyDisplayHeader", Vector3.new(12, 1.2, 0.3), Vector3.new(CX - SX / 2 + 0.7, Y + 9.2, CZ), Vector3.new(1, 0, 0), "CREW MANIFEST", Color3.fromRGB(138, 150, 166))

local gx = CX + SX / 2 - 0.6
part("GateFrameL", Vector3.new(0.6, 9, 0.6), CFrame.new(gx, Y + 4.5, CZ - 3), AMBER, Enum.Material.Neon)
part("GateFrameR", Vector3.new(0.6, 9, 0.6), CFrame.new(gx, Y + 4.5, CZ + 3), AMBER, Enum.Material.Neon)
part("GateFrameTop", Vector3.new(0.6, 0.6, 6.6), CFrame.new(gx, Y + 9, CZ), AMBER, Enum.Material.Neon)
part("GateDoor", Vector3.new(0.3, 8.4, 5.4), CFrame.new(gx + 0.2, Y + 4.5, CZ), COL.Trim, Enum.Material.Metal)
screen("GateSign", Vector3.new(8, 1.4, 0.3), Vector3.new(gx - 0.3, Y + 10.3, CZ), Vector3.new(-1, 0, 0), "BOARDING GATE ▸ SHIP", AMBER)

-- Lit path: spawn -> gate
for i = 0, 7 do
	part("PathStrip", Vector3.new(2, 0.1, 0.4), CFrame.new(CX + 2 + i * 2, Y + 0.05, CZ - 8 + i), TEAL, Enum.Material.Neon, { CanCollide = false })
end

lobby.Parent = workspace

-- Everyone spawns in the lobby; RunCoordinator moves crew aboard
local ship = workspace:FindFirstChild("Ship")
local crewSpawn = ship and ship:FindFirstChild("CrewSpawn")
if crewSpawn then crewSpawn.Enabled = false end
print("[BuildLobby] Lobby rebuilt:", #lobby:GetDescendants(), "instances")
