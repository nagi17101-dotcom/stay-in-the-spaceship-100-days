-- FinaleService: Day 100 "Return Signal" — three guaranteed-achievable stages, then a crew vote.
-- Stage progress only advances from validated server events (TaskService/QuickAction via run.notifyRepair,
-- the Beacon Fabricator prompt, and the server-side hold timer).
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)
local Guard = require(script.Parent.Parent.World.InteractionGuard)
local N = Remotes.Names

local STAGES = {
	{ title = "FINAL ROUTE ALIGNMENT", steps = {
		{ kind = "task", id = "SignalTriangulator", objective = "DAY 100 · 1/3 FINAL ROUTE: triangulate the return signal at the Signal console (Bridge)." },
	} },
	{ title = "TRANSIT CORE", steps = {
		{ kind = "task", id = "ReactorPhase", objective = "DAY 100 · 2/3 TRANSIT CORE: synchronize the coils at the Reactor Phase console." },
		{ kind = "task", id = "PowerBus", objective = "DAY 100 · 2/3 TRANSIT CORE: route emergency power at the Power Bus." },
	} },
	{ title = "BEACON TRANSMISSION", steps = {
		{ kind = "craft", objective = "DAY 100 · 3/3 BEACON: build the transmitter at the Beacon Fabricator (Workshop) — %s." },
		{ kind = "hold", objective = "DAY 100 · 3/3 TRANSMITTING %d/%ds — keep ship condition ≥ %d%%." },
	} },
}

local Finale = {}
Finale.__index = Finale

local function alertAll(severity, text)
	Remotes.Get(N.Alert):FireAllClients({ severity = severity, text = text })
end

function Finale.new(run)
	local self = setmetatable({ run = run }, Finale)
	self:Reset()
	self:_bindStations()
	Remotes.Get(N.CastVote).OnServerEvent:Connect(function(player, choice) self:_onVote(player, choice) end)
	return self
end

function Finale:Reset()
	self.active, self.stage, self.step, self.hold = false, 1, 1, 0
	self.voteOpen, self.votes, self.voteEndsAt = false, {}, 0
	self.voteToken = (self.voteToken or 0) + 1
	self.holdWarned = false
end

function Finale:_current()
	local s = STAGES[self.stage]
	return s and s.steps[self.step]
end

function Finale:_holdSeconds(): number
	return math.ceil(Config.Finale.HoldSeconds / self.run.ship.tuning.graceFactor)
end

function Finale:Begin()
	self:Reset()
	self.active = true
	alertAll("Critical", "DAY 100 — RETURN SIGNAL. Three final stages: route, transit core, beacon.")
	print(("[Finale] begin run=%s difficulty=%s"):format(string.sub(self.run.runId, 1, 8), self.run.difficulty))
end

function Finale:_advance()
	self.step += 1
	if self.step > #STAGES[self.stage].steps then
		alertAll("Info", ("STAGE %d/%d COMPLETE — %s"):format(self.stage, #STAGES, STAGES[self.stage].title))
		print(("[Finale] stage %d complete"):format(self.stage))
		self.stage += 1
		self.step = 1
		if self.stage > #STAGES then
			self.active = false
			self.run.onFinaleComplete()
		end
	end
end

function Finale:Objective(): string?
	if not self.active then return nil end
	local cur = self:_current()
	if cur.kind == "craft" then
		return cur.objective:format(Config.FormatItems(Config.Finale.TransmitterCost))
	elseif cur.kind == "hold" then
		return cur.objective:format(math.floor(self.hold), self:_holdSeconds(), Config.Finale.HoldMinCondition)
	end
	return cur.objective
end

function Finale:OnRepaired(_system: string, source: string)
	if not self.active then return end
	local cur = self:_current()
	if cur.kind == "task" and source == "task:" .. cur.id then self:_advance() end
end

function Finale:_condition(): number
	local sum, n = 0, 0
	for _, sys in pairs(self.run.ship.systems) do sum += math.min(sys.health, sys.output) n += 1 end
	return sum / n
end

function Finale:Tick(dt: number)
	if not self.active then return end
	local cur = self:_current()
	if cur.kind ~= "hold" then return end
	if self.run.emergency == nil and self:_condition() >= Config.Finale.HoldMinCondition then
		self.hold += dt
		self.holdWarned = false
		if self.hold >= self:_holdSeconds() then self:_advance() end
	elseif not self.holdWarned then
		self.holdWarned = true
		alertAll("Warning", "Transmission paused — ship condition too low. Repair to resume.")
	end
end

function Finale:_bindStations()
	local function bind(station)
		local pp = station:FindFirstChildWhichIsA("ProximityPrompt", true)
		if not pp then return end
		pp.Triggered:Connect(function(player) self:_craft(player, station) end)
	end
	for _, s in ipairs(CollectionService:GetTagged("FinaleStation")) do bind(s) end
	CollectionService:GetInstanceAddedSignal("FinaleStation"):Connect(bind)
end

function Finale:_craft(player: Player, station: Model)
	local function notify(text) Remotes.Get(N.Alert):FireClient(player, { severity = "Info", text = text }) end
	if not self.active or self.run.day.phase ~= "Finale" then return notify("The Beacon Fabricator is only needed on Day 100.") end
	if not Guard.IsCrew(self.run, player) or not Guard.InRange(player, station) then return end
	local cur = self:_current()
	if cur.kind ~= "craft" then return notify("Not yet — finish the current Day 100 stage first.") end
	local cost = Config.Finale.TransmitterCost
	if not self.run.inventory:TryDebit(cost, "finale:craft:" .. self.run.runId) then
		return notify("Need " .. Config.FormatItems(cost) .. ". Salvage points were restocked for the finale.")
	end
	alertAll("Info", player.DisplayName .. " assembled the Beacon Transmitter. Transmission starting.")
	self:_advance()
end

-- Vote ---------------------------------------------------------------------
function Finale:_presentCrew()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do if self.run.crew[p.UserId] then table.insert(list, p) end end
	return list
end

function Finale:_broadcastVote()
	local extract, continue = 0, 0
	for _, p in ipairs(self:_presentCrew()) do
		local v = self.votes[p.UserId]
		if v == "Extract" then extract += 1 elseif v == "Continue" then continue += 1 end
	end
	Remotes.Get(N.VoteState):FireAllClients({
		open = self.voteOpen, endsAt = self.voteEndsAt, extract = extract, continue = continue,
		voters = #self:_presentCrew(), votes = self.votes,
	})
	return extract, continue
end

function Finale:OpenVote()
	self.voteOpen, self.votes = true, {}
	self.voteEndsAt = workspace:GetServerTimeNow() + Config.Finale.VoteSeconds
	self.voteToken += 1
	local token = self.voteToken
	self:_broadcastVote()
	task.delay(Config.Finale.VoteSeconds, function()
		if self.voteOpen and self.voteToken == token then self:_resolveVote("timeout") end
	end)
end

function Finale:_onVote(player: Player, choice: any)
	if not self.voteOpen or not self.run.crew[player.UserId] then return end
	if choice ~= "Extract" and choice ~= "Continue" then return end
	self.votes[player.UserId] = choice
	self:_broadcastVote()
	local all = true
	for _, p in ipairs(self:_presentCrew()) do if not self.votes[p.UserId] then all = false end end
	if all then self:_resolveVote("all voted") end
end

function Finale:_resolveVote(why: string)
	if not self.voteOpen then return end
	local extract, continue = self:_broadcastVote()
	self.voteOpen = false
	local choice = continue > extract and "Continue" or "Extract" -- tie or no votes => Extract (nobody stranded)
	self:_broadcastVote()
	print(("[Finale] vote %s: extract=%d continue=%d -> %s"):format(why, extract, continue, choice))
	self.run.onVoteResult(choice)
end

function Finale:DevAdvance() if self.active then self:_advance() end end
function Finale:Status(): string
	return ("active=%s stage=%d step=%d hold=%.1f vote=%s"):format(tostring(self.active), self.stage, self.step, self.hold, tostring(self.voteOpen))
end

return Finale
