-- ProfileService: account progression lifecycle. Load on join, autosave, save+release on leave and shutdown.
-- All rewards go through Grant(player, grantId, reward): each grantId is applied once per profile (stored in it).
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)
local Schema = require(script.Parent.ProfileSchema)
local Store = require(script.Parent.ProfileStore)
local N = Remotes.Names

local ProfileService = {}
local store, backendPersistent, backendReason
local profiles = {} -- player -> { data, grants = set, dirty, persistent, readOnly, saving }
local pending = {}  -- player -> { {grantId, reward} } granted before the profile finished loading

local function notify(player, severity, text)
	Remotes.Get(N.Alert):FireClient(player, { severity = severity, text = text })
end

local function buildState(p)
	local d = p.data
	local level = Schema.Level(d.xp)
	local n = 0
	for _ in pairs(d.achievements) do n += 1 end
	return {
		xp = d.xp, level = level, levelXp = Schema.XpForLevel(level), nextLevelXp = Schema.XpForLevel(level + 1),
		rank = Schema.Rank(level).name, bestDay = d.bestDay, achievements = n, stats = d.stats,
		persistent = p.persistent, readOnly = p.readOnly == true,
	}
end

local function push(player)
	local p = profiles[player]
	if p and player.Parent then Remotes.Get(N.ProfileState):FireClient(player, buildState(p)) end
end

local function apply(player, p, grantId: string, reward)
	if p.grants[grantId] then return false end
	local d = p.data
	local oldLevel = Schema.Level(d.xp)
	d.xp += math.max(0, math.floor(reward.xp or 0))
	for k, v in pairs(reward.stats or {}) do
		if type(d.stats[k]) == "number" and type(v) == "number" and v > 0 then d.stats[k] += v end
	end
	if reward.bestDay then
		local diff, day = reward.bestDay.difficulty, reward.bestDay.day
		if d.bestDay[diff] ~= nil and day > d.bestDay[diff] then d.bestDay[diff] = day end
		for _, ms in ipairs(Config.Progression.SurviveMilestones) do
			local id = ("Survive%d_%s"):format(ms, diff)
			if day >= ms and not d.achievements[id] then
				d.achievements[id] = os.time()
				notify(player, "Info", ("ACHIEVEMENT: Survived Day %d on %s."):format(ms, diff))
			end
		end
	end
	table.insert(d.grantLog, grantId)
	p.grants[grantId] = true
	while #d.grantLog > Schema.GRANT_LOG_MAX do
		p.grants[table.remove(d.grantLog, 1)] = nil
	end
	local newLevel = Schema.Level(d.xp)
	if newLevel > oldLevel then
		local rank = Schema.Rank(newLevel)
		d.unlocks[rank.id] = true
		notify(player, "Info", ("LEVEL %d — %s"):format(newLevel, rank.name))
	end
	p.dirty = true
	push(player)
	return true
end

-- Idempotent reward entry point. reward = { xp?, stats? = {k=n}, bestDay? = {difficulty, day} }
function ProfileService.Grant(player: Player, grantId: string, reward)
	local p = profiles[player]
	if not p then
		pending[player] = pending[player] or {}
		table.insert(pending[player], { grantId, reward })
		return nil
	end
	return apply(player, p, grantId, reward)
end

function ProfileService.IsPersistent(player: Player): boolean
	local p = profiles[player]
	return p ~= nil and p.persistent
end

local function save(player: Player, release: boolean): boolean
	local p = profiles[player]
	if not p or not p.persistent or p.readOnly then return false end
	while p.saving do task.wait() end -- serialize saves per player
	p.saving = true
	local ok, err = store:Save(player.UserId, p.data, release)
	p.saving = false
	if ok then
		p.dirty = false
	else
		warn(("[Profile] save failed for %d: %s"):format(player.UserId, tostring(err)))
		if err == "LockLost" then
			p.persistent = false
			notify(player, "Warning", "Progress can no longer be saved this session (profile opened on another server).")
			push(player)
		end
	end
	return ok
end

local function onPlayerAdded(player: Player)
	local data, err
	if backendPersistent then data, err = store:Load(player.UserId) end
	if not player.Parent then
		if data then store:Save(player.UserId, data, true) end -- left while loading: release lock
		return
	end
	local p
	if data then
		p = { data = data, persistent = not data.__newerSchema, readOnly = data.__newerSchema == true }
	else
		p = { data = Schema.Default(), persistent = false }
		local why = backendPersistent and ("load failed: " .. tostring(err)) or backendReason
		warn(("[Profile] %d session-only (%s)"):format(player.UserId, why))
		notify(player, "Warning", "Progress is NOT being saved this session (data service unavailable).")
	end
	p.grants = {}
	for _, id in ipairs(p.data.grantLog) do p.grants[id] = true end
	profiles[player] = p
	for _, g in ipairs(pending[player] or {}) do apply(player, p, g[1], g[2]) end
	pending[player] = nil
	push(player)
end

function ProfileService.Start()
	local backend
	backend, backendReason = Store.Detect()
	backendPersistent = backend.persistent
	local jobId = game.JobId ~= "" and game.JobId or ("studio-" .. HttpService:GenerateGUID(false))
	store = Store.new(backend, jobId)
	print(("[Profile] backend: %s"):format(backendReason))

	Players.PlayerAdded:Connect(function(p) task.spawn(onPlayerAdded, p) end)
	for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, p) end
	Players.PlayerRemoving:Connect(function(p)
		save(p, true)
		profiles[p] = nil
		pending[p] = nil
	end)

	game:BindToClose(function()
		local remaining = 0
		for player in pairs(profiles) do
			remaining += 1
			task.spawn(function() save(player, true) remaining -= 1 end)
		end
		local t0 = os.clock()
		while remaining > 0 and os.clock() - t0 < 25 do task.wait(0.1) end
	end)

	task.spawn(function()
		while true do
			task.wait(Config.Progression.AutosaveSeconds)
			for player, p in pairs(profiles) do
				if p.persistent then task.spawn(save, player, false) end -- also refreshes the session lock
			end
		end
	end)
end

return ProfileService
