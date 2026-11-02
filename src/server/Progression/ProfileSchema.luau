-- ProfileSchema: versioned account profile. Bump VERSION and add a step in Migrate for every breaking change.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.GameConfig)

local Schema = {}
Schema.VERSION = 1
Schema.GRANT_LOG_MAX = 400 -- idempotency window (newest kept)

function Schema.Default()
	return {
		schema = Schema.VERSION,
		xp = 0,
		stats = { runs = 0, shipsLost = 0, daysSurvived = 0, repairs = 0, salvage = 0, actions = 0 },
		bestDay = { Cadet = 0, Standard = 0, Veteran = 0 },
		achievements = {}, -- id -> unix time
		unlocks = { CrewCadet = true },
		grantLog = {},     -- ordered list of applied grant ids
		createdAt = os.time(),
		updatedAt = 0,
	}
end

local function deepCopy(t)
	if type(t) ~= "table" then return t end
	local out = {}
	for k, v in pairs(t) do out[k] = deepCopy(v) end
	return out
end
Schema.DeepCopy = deepCopy

-- Fills missing fields and upgrades old versions. Never drops unknown fields (forward safety).
function Schema.Migrate(data)
	if type(data) ~= "table" then return Schema.Default() end
	local def = Schema.Default()
	-- v0 -> v1: no schema field, flat "level" may exist (derived now, removed)
	if data.schema == nil then
		data.level = nil
		data.schema = 1
	end
	for k, v in pairs(def) do
		if data[k] == nil then data[k] = v
		elseif type(v) == "table" and type(data[k]) == "table" then
			for k2, v2 in pairs(v) do if data[k][k2] == nil then data[k][k2] = v2 end end
		end
	end
	if data.schema > Schema.VERSION then
		data.__newerSchema = true -- written by a newer server build: load read-only
	end
	return data
end

function Schema.Level(xp: number): number
	return math.floor(math.sqrt(math.max(0, xp) / Config.Progression.XpPerLevelCurve)) + 1
end

function Schema.XpForLevel(level: number): number
	return Config.Progression.XpPerLevelCurve * (level - 1) ^ 2
end

function Schema.Rank(level: number)
	local best = Config.Progression.Ranks[1]
	for _, r in ipairs(Config.Progression.Ranks) do if level >= r.level then best = r end end
	return best
end

return Schema
