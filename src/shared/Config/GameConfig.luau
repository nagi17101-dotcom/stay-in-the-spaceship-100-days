-- GameConfig: single source of truth for tuning (starting targets, not playtested values)
local Config = {}

Config.Version = 1
Config.PlayersMin = 2
Config.PlayersMax = 6
Config.DayMilestone = 100
Config.StudioSoloOverride = true -- dev only: allows 1 player when RunService:IsStudio()

Config.Day = {
	PrepareSeconds = 15,
	ActiveSeconds = 75,
	TransitionSeconds = 8,
}

Config.SimTickHz = 2

Config.DefaultDifficulty = "Standard"
Config.Difficulty = {
	Cadet    = { incidentBudgetFactor = 0.7,  startingResourcesFactor = 1.35, wearFactor = 0.7,  graceFactor = 1.35, maxConcurrentCritical = 1 },
	Standard = { incidentBudgetFactor = 1.0,  startingResourcesFactor = 1.0,  wearFactor = 1.0,  graceFactor = 1.0,  maxConcurrentCritical = 2 },
	Veteran  = { incidentBudgetFactor = 1.25, startingResourcesFactor = 0.9,  wearFactor = 1.15, graceFactor = 0.85, maxConcurrentCritical = 2 },
}

Config.Systems = { "Hull", "Oxygen", "Reactor", "Power", "Cooling", "Drive", "Navigation", "Comms", "Shields", "Cargo" }

-- wear = health lost per second during Active phase (before difficulty factor)
Config.SystemDefaults = {
	Hull       = { wear = 0.03 },
	Oxygen     = { wear = 0.04 },
	Reactor    = { wear = 0.06 },
	Power      = { wear = 0.05 },
	Cooling    = { wear = 0.08 },
	Drive      = { wear = 0.05 },
	Navigation = { wear = 0.03 },
	Comms      = { wear = 0.03 },
	Shields    = { wear = 0.04 },
	Cargo      = { wear = 0.02 },
}

Config.Dependencies = {
	CoolingSafe = 50,            -- below this, reactor overheats
	ReactorHeatWear = 0.25,      -- extra reactor wear/s at 0 cooling
	LifeSupportPowerNeed = 60,   -- power output needed for full O2 scrubbing
	HullLeakBelow = 60,          -- hull health under which O2 leaks
	HullLeakRate = 0.8,          -- O2/s leak at hull 0
	OxygenRegen = 0.6,           -- O2/s at full power + healthy scrubbers
	OxygenUsePerCrew = 0.05,
}

Config.Thresholds = { Warning = 50, Critical = 25, Hysteresis = 3 }
Config.CatastropheGraceSeconds = 30 -- time at Hull 0 / O2 0 before run is lost (x graceFactor)

Config.Materials = {
	{ id = "ScrapAlloy", name = "Scrap Alloy", short = "SCRAP" },
	{ id = "SealantFoam", name = "Sealant Foam", short = "SEALANT" },
	{ id = "FilterMembrane", name = "Filter Membrane", short = "FILTER" },
	{ id = "ConductiveFilament", name = "Conductive Filament", short = "FILAMENT" },
	{ id = "CoolantCartridge", name = "Coolant Cartridge", short = "COOLANT" },
}
Config.StartingMaterials = { ScrapAlloy = 3, SealantFoam = 1, FilterMembrane = 1, ConductiveFilament = 2, CoolantCartridge = 1 }

-- Salvage points: finite charges, refilled at each Prepare phase
Config.SalvageLoot = {
	DebrisReceiver = { charges = 2, loot = { { id = "ScrapAlloy", min = 1, max = 2 }, { id = "SealantFoam", min = 0, max = 1 } } },
	SupplyLocker = { charges = 1, loot = { { id = "FilterMembrane", min = 1, max = 1 }, { id = "ConductiveFilament", min = 0, max = 1 } } },
	ScrapBin = { charges = 1, loot = { { id = "ScrapAlloy", min = 1, max = 1 }, { id = "CoolantCartridge", min = 0, max = 1 } } },
}

-- Emergency quick actions: no minigame, consume materials, buy time (deadlock prevention)
Config.QuickActions = {
	EmergencyO2 = { label = "Emergency O2 Reserve", cost = { FilterMembrane = 1 }, system = "Oxygen", field = "output", amount = 35, cooldown = 8 },
	HullPatch = { label = "Hull Patch Kit", cost = { ScrapAlloy = 2, SealantFoam = 1 }, system = "Hull", field = "health", amount = 25, cooldown = 8 },
}

Config.Rewards = {
	BaseXP = 10, TaskXP = 15, SalvageXP = 5, ActionXP = 5,
	CrewBonus = { ScrapAlloy = 1 },
	HealthyBonus = { SealantFoam = 1 },
	HealthyThreshold = 50,
}

Config.EmergencyObjectives = {
	OxygenDepleted = "EMERGENCY: Use the O2 Reserve in Life Support, then restore power.",
	HullBreach = "EMERGENCY: Apply a Hull Patch Kit at the Main Junction.",
}

Config.Lobby = {
	LaunchCountdown = 5,        -- seconds; cancelled if roster/ready changes
	ActionCooldown = 0.3,       -- per-player party action rate limit
	ReturnToLobbyAfterLoss = 20, -- auto-return if nobody presses the button
	DifficultyOrder = { "Cadet", "Standard", "Veteran" },
}

Config.Progression = {
	AutosaveSeconds = 120,
	XpPerLevelCurve = 50, -- xp needed for level L = 50 * (L-1)^2
	Ranks = { -- cosmetic, permanent
		{ level = 1, id = "CrewCadet", name = "CREW CADET" },
		{ level = 5, id = "Technician", name = "TECHNICIAN" },
		{ level = 10, id = "Navigator", name = "NAVIGATOR" },
		{ level = 20, id = "Veteran", name = "VETERAN" },
		{ level = 35, id = "Commander", name = "COMMANDER" },
	},
	SurviveMilestones = { 10, 25, 50, 75, 100 }, -- achievements per difficulty
}

function Config.MaterialName(id: string): string
	for _, m in ipairs(Config.Materials) do if m.id == id then return m.name end end
	return id
end

function Config.FormatItems(items): string
	local parts = {}
	for _, m in ipairs(Config.Materials) do
		local n = items[m.id]
		if n and n ~= 0 then table.insert(parts, ("%d %s"):format(n, m.name)) end
	end
	return table.concat(parts, " + ")
end

Config.Sectors = {
	{ name = "Awakening",          from = 1,  to = 5 },
	{ name = "Outer Freight Belt", from = 6,  to = 15 },
	{ name = "Echo Fields",        from = 16, to = 30 },
	{ name = "Ion Corridor",       from = 31, to = 50 },
	{ name = "Dead Relay Zone",    from = 51, to = 70 },
	{ name = "Fading Signal",      from = 71, to = 90 },
	{ name = "Approach",           from = 91, to = 99 },
	{ name = "Return Signal",      from = 100, to = 100 },
}

-- English source text (localization keys later)
Config.SystemObjectives = {
	Hull = "Hull integrity dropping. Seal the breach before oxygen vents.",
	Oxygen = "Oxygen low. Replace a scrubber filter in Life Support.",
	Reactor = "Reactor unstable. Stabilize the coils in the Reactor room.",
	Power = "Power Distribution: output reduced. Route power to Life Support.",
	Cooling = "Coolant pumps failing. Restart the coolant loop.",
	Drive = "Drive misaligned. Align the thruster coils in Engine.",
	Navigation = "Navigation drifting. Recalibrate on the Bridge.",
	Comms = "Comms static. Tune the receiver.",
	Shields = "Shield band mismatch. Tune shield resonance.",
	Cargo = "Recycler jammed. Clear it in Cargo.",
}
Config.PhaseObjectives = {
	Lobby = "Waiting for crew to board.",
	Prepare = "Prepare: check systems and restock at the Workshop.",
	Active = "Keep all systems running until the cycle ends.",
	Transition = "Cycle complete. Systems settling.",
	Finale = "DAY 100 — Return Signal. Final objective incoming.",
	Failed = "Ship lost.",
}

function Config.SectorFor(day: number): string
	if day > Config.DayMilestone then return "Endless Voyage" end
	for _, s in ipairs(Config.Sectors) do
		if day >= s.from and day <= s.to then return s.name end
	end
	return "Standby"
end

return Config
