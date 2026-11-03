-- SalvageService: finite salvage points (charges refill each Prepare). Loot is server-rolled, credited once per txId.
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)
local Guard = require(script.Parent.InteractionGuard)

local Salvage = {}
local EMPTY = Color3.fromRGB(40, 44, 52)
local READY = Color3.fromRGB(255, 176, 32)

local function setCharges(point: Model, n: number)
	point:SetAttribute("Charges", n)
	local ind = point:FindFirstChild("Indicator")
	if ind then ind.Color = n > 0 and READY or EMPTY end
	local pp = point:FindFirstChildWhichIsA("ProximityPrompt", true)
	if pp then pp.Enabled = n > 0 end
end

function Salvage.Start(run)
	local cooldowns = {}
	local points = {}

	local function refill()
		for _, p in ipairs(points) do
			local cfg = Config.SalvageLoot[p:GetAttribute("SalvageType")]
			if cfg then setCharges(p, cfg.charges) end
		end
	end

	local function onTriggered(player: Player, point: Model)
		local cfg = Config.SalvageLoot[point:GetAttribute("SalvageType")]
		if not cfg or not Guard.PhaseOpen(run) or not Guard.IsCrew(run, player) or not Guard.InRange(player, point) then return end
		if not Guard.Cooldown(cooldowns, player, 1) then return end
		local charges = point:GetAttribute("Charges") or 0
		if charges <= 0 then return end
		setCharges(point, charges - 1)

		local loot = {}
		for _, entry in ipairs(cfg.loot) do
			local n = run.rng:NextInteger(entry.min, entry.max)
			if n > 0 then loot[entry.id] = (loot[entry.id] or 0) + n end
		end
		local _, overflow = run.inventory:Credit(loot, "salvage:" .. HttpService:GenerateGUID(false))
		run.recordStat(player, "salvage", 1)
		local text = "Salvaged: +" .. Config.FormatItems(loot)
		if overflow then text ..= " (hold full — discarded " .. Config.FormatItems(overflow) .. ")" end
		Remotes.Get(Remotes.Names.Alert):FireClient(player, { severity = "Info", text = text })
	end

	local function bind(point)
		if not point:IsA("Model") then return end
		table.insert(points, point)
		local pp = point:FindFirstChildWhichIsA("ProximityPrompt", true)
		if pp then pp.Triggered:Connect(function(player) onTriggered(player, point) end) end
	end
	for _, p in ipairs(CollectionService:GetTagged("SalvagePoint")) do bind(p) end

	run.day.PhaseChanged.Event:Connect(function(info)
		if info.phase == "Prepare" or info.phase == "Finale" then refill() end -- finale restock: no material dead-ends
	end)
	refill()
end

return Salvage
