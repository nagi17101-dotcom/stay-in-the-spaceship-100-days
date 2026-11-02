-- M07 Thruster Alignment Matrix (server-only generator + validator). Rules: Shared.Minigames.ThrusterMatrixRules.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage.Shared.Minigames.ThrusterMatrixRules)

local ThrusterMatrix = {}
ThrusterMatrix.Id = "ThrusterMatrix"
ThrusterMatrix.System = "Drive"
ThrusterMatrix.RepairAmount = 35

local TIERS = {
	Basic = { tol = 1, disabled = false, slack = { 1, 3 }, maxValid = 40 },
	Advanced = { tol = 0, disabled = true, slack = { 0, 2 }, maxValid = 15 },
}

-- All 3^8 power settings, precomputed once
local SETTINGS = {}
do
	local n, P = #Rules.DIRS, Rules.MAX_POWER + 1
	for code = 0, P ^ n - 1 do
		local powers, c = {}, code
		for i = 1, n do powers[i] = c % P c = c // P end
		table.insert(SETTINGS, powers)
	end
end

local function tryGenerate(t, rng)
	local pub = {
		drift = { x = rng:NextInteger(-4, 4), y = rng:NextInteger(-4, 4) },
		disabled = t.disabled and rng:NextInteger(1, #Rules.DIRS) or nil,
	}
	-- target burn: a random setting using 2-4 thrusters, never the disabled one
	local target
	for _ = 1, 50 do
		local s = SETTINGS[rng:NextInteger(1, #SETTINGS)]
		local used = 0
		for i, p in ipairs(s) do if p > 0 then used += 1 end end
		if used >= 2 and used <= 4 and not (pub.disabled and s[pub.disabled] > 0) then target = s break end
	end
	if not target then return nil end
	local r = Rules.Readout(pub, target)
	if r.x == pub.drift.x and r.y == pub.drift.y then return nil end
	local limit = Rules.PLOT_RANGE - t.tol - 1
	if math.abs(r.x) > limit or math.abs(r.y) > limit then return nil end -- corridor must be visible on the plot
	pub.corridor = { x = r.x, y = r.y, tol = t.tol }
	pub.fuelBudget = r.fuel + rng:NextInteger(t.slack[1], t.slack[2])
	pub.vibrationLimit = r.vibration + rng:NextInteger(t.slack[1], t.slack[2])
	if Rules.InCorridor(pub, pub.drift.x, pub.drift.y) then return nil end -- doing nothing must not work

	local valid = 0
	for _, s in ipairs(SETTINGS) do
		if Rules.Evaluate(pub, s) then valid += 1 if valid > t.maxValid then return nil end end
	end
	if valid < 1 then return nil end
	return pub, { powers = table.clone(target), validCount = valid }
end

function ThrusterMatrix.Generate(tier: string, seed: number)
	local t = TIERS[tier] or TIERS.Basic
	for attempt = 0, 299 do
		local pub, priv = tryGenerate(t, Random.new(seed + attempt * 49979687))
		if pub then return pub, priv end
	end
	error("ThrusterMatrix: no layout for seed " .. seed)
end

function ThrusterMatrix.ValidateShape(pub, action): boolean
	if type(action) ~= "table" or type(action.powers) ~= "table" or #action.powers ~= #Rules.DIRS then return false end
	for i = 1, #Rules.DIRS do
		local v = action.powers[i]
		if type(v) ~= "number" or v % 1 ~= 0 or v < 0 or v > Rules.MAX_POWER then return false end
	end
	return true
end

function ThrusterMatrix.Validate(pub, _priv, action)
	local ok, reason, message = Rules.Evaluate(pub, action.powers)
	return ok, reason, message
end

function ThrusterMatrix.CheckSolvable(pub, priv): boolean
	return (Rules.Evaluate(pub, priv.powers))
end

return ThrusterMatrix
