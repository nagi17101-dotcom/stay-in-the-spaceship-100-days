-- UpkeepService: day-end consumables (M5 economy). At each Transition the ship consumes materials on a schedule;
-- if the crew cannot pay, the linked system takes a one-off health penalty instead (never instant loss).
-- Gives materials a steady, predictable sink so salvage choices matter. Disable by emptying Config.Upkeep.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)

local Upkeep = {}

-- Pure: which upkeep items are due on this day (exposed for tests / HUD previews)
function Upkeep.Due(day: number)
	local due = {}
	for _, u in ipairs(Config.Upkeep or {}) do
		if day >= (u.fromDay or 1) and day % u.every == 0 then table.insert(due, u) end
	end
	return due
end

function Upkeep.Run(run, day: number)
	local paid, missed = {}, {}
	for _, u in ipairs(Upkeep.Due(day)) do
		local tx = ("upkeep:%s:%d:%s"):format(run.runId, day, u.id)
		if run.inventory:TryDebit({ [u.id] = u.amount }, tx) then
			paid[u.id] = (paid[u.id] or 0) + u.amount
		else
			run.ship:ApplyDelta(u.system, "health", -u.penalty, tx)
			table.insert(missed, ("no %s for %s — %s -%d"):format(Config.MaterialName(u.id), u.label, u.system, u.penalty))
		end
	end
	local alert = Remotes.Get(Remotes.Names.Alert)
	if next(paid) then alert:FireAllClients({ severity = "Info", text = "Day-end upkeep: -" .. Config.FormatItems(paid) }) end
	for _, text in ipairs(missed) do alert:FireAllClients({ severity = "Warning", text = "Upkeep missed: " .. text }) end
	return paid, missed
end

function Upkeep.Start(run)
	run.day.PhaseChanged.Event:Connect(function(info)
		if info.phase == "Transition" then Upkeep.Run(run, info.day) end
	end)
end

return Upkeep
