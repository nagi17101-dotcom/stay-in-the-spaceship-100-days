-- TaskService: station -> task lifecycle. AVAILABLE -> ACTIVE -> VALIDATING -> RESOLVED/FAILED/EXPIRED/ABORTED
-- Never trusts a client "success": the server re-validates every action against its own task record.
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)
local Registry = require(script.Parent.Parent.Minigames.Registry)
local N = Remotes.Names

local TaskService = {}
local TASK_TTL = 120
local MAX_ATTEMPTS = 4
local INTERACT_RANGE = 12
local REPAIR_THRESHOLD = 98
local SUBMIT_COOLDOWN = 0.75

local run
local tasks, byStation, byPlayer, lastSubmit = {}, {}, {}, {}

local function tierForDay(day: number): string
	return day <= 15 and "Basic" or "Advanced"
end

local function notify(player, severity, text)
	Remotes.Get(N.Alert):FireClient(player, { severity = severity, text = text })
end

local function result(task, payload)
	payload.taskId = task.taskId
	Remotes.Get(N.TaskResult):FireClient(task.player, payload)
end

local function release(task, state: string)
	task.state = state
	tasks[task.taskId] = nil
	if byStation[task.stationId] == task.taskId then byStation[task.stationId] = nil end
	if byPlayer[task.player] == task.taskId then byPlayer[task.player] = nil end
end

local function inRange(player, station): boolean
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local anchor = station.PrimaryPart
	return root ~= nil and anchor ~= nil and (root.Position - anchor.Position).Magnitude <= INTERACT_RANGE
end

local function openTask(player: Player, station: Model)
	local phase = run.day.phase
	if phase == "Lobby" or run.day:IsTerminal() then return end
	if not (run.crew and run.crew[player.UserId]) then return end
	if byPlayer[player] then return notify(player, "Info", "Finish your current task first.") end
	local stationId = station:GetAttribute("StationId")
	if byStation[stationId] then return notify(player, "Info", "Another crew member is using this station.") end
	if not inRange(player, station) then return end

	local mg = Registry[station:GetAttribute("MinigameId")]
	if not mg then return end
	local sys = run.ship.systems[mg.System]
	if mg.CanOpen then
		local allowed, why = mg.CanOpen(run)
		if not allowed then return notify(player, "Info", why) end
	end
	local f = run.finale
	local finaleStep = f and f.active and f:_current()
	local finaleNeeds = finaleStep and finaleStep.kind == "task" and finaleStep.id == mg.Id
	local incidentNeeds = run.director ~= nil and run.director:NeedsTask(mg.Id)
	if sys.health >= REPAIR_THRESHOLD and not finaleNeeds and not incidentNeeds and not mg.AlwaysAvailable then
		return notify(player, "Info", mg.System .. " is nominal. No repair needed.")
	end

	local seed = run.rng:NextInteger(1, 2147483646)
	local tier = tierForDay(run.day.day)
	local pub, priv = mg.Generate(tier, seed, mg.Context and mg.Context(run))
	if not mg.CheckSolvable(pub, priv) then
		warn(("[Task] unsolvable %s seed=%d tier=%s — skipped"):format(mg.Id, seed, tier))
		return
	end

	local task = {
		taskId = HttpService:GenerateGUID(false),
		player = player, station = station, stationId = stationId,
		mg = mg, pub = pub, priv = priv, tier = tier, seed = seed,
		state = "ACTIVE", attempts = 0, expiresAt = os.clock() + TASK_TTL,
	}
	tasks[task.taskId] = task
	byStation[stationId] = task.taskId
	byPlayer[player] = task.taskId

	Remotes.Get(N.TaskOpen):FireClient(player, {
		taskId = task.taskId, minigameId = mg.Id, tier = tier, system = mg.System,
		publicPuzzle = pub, maxAttempts = mg.MaxAttempts or MAX_ATTEMPTS, ttl = TASK_TTL,
	})
end

local function onSubmit(player: Player, taskId: any, action: any)
	if type(taskId) ~= "string" then return end
	local task = tasks[taskId]
	if not task or task.player ~= player or task.state ~= "ACTIVE" then return end
	local now = os.clock()
	if lastSubmit[player] and now - lastSubmit[player] < SUBMIT_COOLDOWN then return end
	lastSubmit[player] = now

	if now > task.expiresAt then
		release(task, "EXPIRED")
		return result(task, { ok = false, closed = true, reason = "Expired", message = "Task expired." })
	end
	if run.day:IsTerminal() then
		release(task, "ABORTED")
		return result(task, { ok = false, closed = true, reason = "RunEnded", message = "Run ended." })
	end
	if not inRange(player, task.station) then
		return result(task, { ok = false, closed = false, reason = "OutOfRange", message = "Move back to the console." })
	end
	if not task.mg.ValidateShape(task.pub, action) then return end -- malformed payload: drop silently

	task.state = "VALIDATING"
	task.attempts += 1
	local ok, reason, message = task.mg.Validate(task.pub, task.priv, action)
	if ok then
		if task.mg.Commit then -- side effects that can still fail (e.g. materials spent meanwhile): fail closed
			local cok, creason, cmsg = task.mg.Commit(run, player, task.pub, action, task.taskId)
			if not cok then
				release(task, "FAILED")
				return result(task, { ok = false, closed = true, reason = creason, message = cmsg })
			end
		end
		if task.mg.RepairAmount > 0 then
			run.ship:ApplyRepair(task.mg.System, task.mg.RepairAmount, task.taskId) -- exactly-once by txId
		end
		if task.mg.OnSuccess then task.mg.OnSuccess(run, player, task.pub, action, task.taskId) end
		release(task, "RESOLVED")
		print(("[Task] %s resolved by %s (+%d %s, tier=%s, attempts=%d)"):format(task.mg.Id, player.Name, task.mg.RepairAmount, task.mg.System, task.tier, task.attempts))
		run.recordStat(player, "tasks", 1)
		if run.notifyRepair then run.notifyRepair(task.mg.System, "task:" .. task.mg.Id) end
		return result(task, { ok = true, closed = true, reason = reason, message = message })
	end
	local maxAttempts = task.mg.MaxAttempts or MAX_ATTEMPTS
	if task.attempts >= maxAttempts then
		release(task, "FAILED")
		return result(task, { ok = false, closed = true, reason = reason, message = message .. " Task failed — reopen the console to retry." })
	end
	task.state = "ACTIVE"
	result(task, { ok = false, closed = false, reason = reason, message = message, attemptsLeft = maxAttempts - task.attempts })
end

local function bindStation(station: Instance)
	if not station:IsA("Model") then return end
	local prompt = station:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not prompt then return end
	prompt.Triggered:Connect(function(player) openTask(player, station) end)
end

function TaskService.Start(runRef)
	run = runRef
	for _, s in ipairs(CollectionService:GetTagged("RepairStation")) do bindStation(s) end
	CollectionService:GetInstanceAddedSignal("RepairStation"):Connect(bindStation)

	Remotes.Get(N.TaskSubmit).OnServerEvent:Connect(onSubmit)
	Remotes.Get(N.TaskCancel).OnServerEvent:Connect(function(player, taskId)
		local task = type(taskId) == "string" and tasks[taskId]
		if task and task.player == player then release(task, "ABORTED") end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local id = byPlayer[player]
		if id and tasks[id] then release(tasks[id], "ABORTED") end
		lastSubmit[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(5)
			local now = os.clock()
			for _, t in pairs(tasks) do
				if now > t.expiresAt and t.state == "ACTIVE" then
					release(t, "EXPIRED")
					result(t, { ok = false, closed = true, reason = "Expired", message = "Task expired." })
				end
			end
		end
	end)
end

return TaskService
