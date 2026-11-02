-- M06 Signal Triangulator (server-only generator + validator). Rules: Shared.Minigames.SignalTriangulatorRules.
-- Generator guarantees exactly ONE cell is consistent with all readings, so any correct deduction is accepted.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage.Shared.Minigames.SignalTriangulatorRules)

local SignalTriangulator = {}
SignalTriangulator.Id = "SignalTriangulator"
SignalTriangulator.System = "Comms"
SignalTriangulator.RepairAmount = 35
SignalTriangulator.AlsoRepairs = { Navigation = 35 } -- M06 covers Comms/Navigation (bible): the fix recalibrates nav too

local TIERS = {
	Basic = { size = 8, band = 0, noise = 0 },
	Advanced = { size = 8, band = 1, noise = 1 },
}

local function borderCells(size)
	local out = {}
	for i = 1, size do
		table.insert(out, { i, 1 }) table.insert(out, { i, size })
		if i > 1 and i < size then table.insert(out, { 1, i }) table.insert(out, { size, i }) end
	end
	return out
end

local function tryGenerate(t, rng)
	local size = t.size
	local border = borderCells(size)
	local antennas, used = {}, {}
	while #antennas < 3 do
		local c = border[rng:NextInteger(1, #border)]
		local k = c[1] .. "," .. c[2]
		if not used[k] then
			used[k] = true
			table.insert(antennas, { id = string.char(64 + #antennas + 1), x = c[1], y = c[2] })
		end
	end
	local bx, by = rng:NextInteger(2, size - 1), rng:NextInteger(2, size - 1)
	for _, a in ipairs(antennas) do
		local d = Rules.Distance(a.x, a.y, bx, by)
		a.reading = math.max(0, d + (t.noise > 0 and rng:NextInteger(-t.noise, t.noise) or 0))
	end
	local pub = { size = size, band = t.band, antennas = antennas }
	-- uniqueness: exactly one consistent cell, and it is the beacon
	local hits = 0
	for x = 1, size do for y = 1, size do
		if Rules.Evaluate(pub, x, y) then hits += 1 end
	end end
	if hits ~= 1 or not Rules.Evaluate(pub, bx, by) then return nil end
	return pub, { x = bx, y = by }
end

function SignalTriangulator.Generate(tier: string, seed: number)
	local t = TIERS[tier] or TIERS.Basic
	for attempt = 0, 499 do
		local pub, priv = tryGenerate(t, Random.new(seed + attempt * 32452843))
		if pub then return pub, priv end
	end
	error("SignalTriangulator: no unique layout for seed " .. seed)
end

function SignalTriangulator.ValidateShape(pub, action): boolean
	if type(action) ~= "table" then return false end
	for _, f in ipairs({ "x", "y" }) do
		local v = action[f]
		if type(v) ~= "number" or v % 1 ~= 0 or v < 1 or v > pub.size then return false end
	end
	return true
end

function SignalTriangulator.Validate(pub, _priv, action)
	return Rules.Evaluate(pub, action.x, action.y)
end

function SignalTriangulator.CheckSolvable(pub, priv): boolean
	return (Rules.Evaluate(pub, priv.x, priv.y))
end

return SignalTriangulator
