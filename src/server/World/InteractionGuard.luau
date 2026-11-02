-- InteractionGuard: common server checks for ProximityPrompt interactions.
local Guard = {}
local RANGE = 12

function Guard.InRange(player: Player, model: Model): boolean
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local anchor = model.PrimaryPart
	return root ~= nil and anchor ~= nil and hum ~= nil and hum.Health > 0
		and (root.Position - anchor.Position).Magnitude <= RANGE
end

function Guard.IsCrew(run, player: Player): boolean
	return run.crew ~= nil and run.crew[player.UserId] == true
end

function Guard.PhaseOpen(run): boolean
	return run.day.phase ~= "Lobby" and not run.day:IsTerminal()
end

function Guard.Cooldown(store, key, seconds: number): boolean
	local now = os.clock()
	if store[key] and now - store[key] < seconds then return false end
	store[key] = now
	return true
end

return Guard
