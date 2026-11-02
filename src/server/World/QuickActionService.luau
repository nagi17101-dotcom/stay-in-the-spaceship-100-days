-- QuickActionService: emergency actions that spend materials to buy time (no rare materials, no minigame).
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)
local Guard = require(script.Parent.InteractionGuard)

local QuickActions = {}

function QuickActions.Start(run)
	local stationCooldown, playerCooldown = {}, {}
	local N = Remotes.Names

	local function notify(player, text)
		Remotes.Get(N.Alert):FireClient(player, { severity = "Info", text = text })
	end

	local function onTriggered(player: Player, station: Model)
		local actionId = station:GetAttribute("ActionId")
		local cfg = Config.QuickActions[actionId]
		if not cfg or not Guard.PhaseOpen(run) or not Guard.IsCrew(run, player) or not Guard.InRange(player, station) then return end
		if not Guard.Cooldown(playerCooldown, player, 1) then return end

		local sys = run.ship.systems[cfg.system]
		if sys[cfg.field] >= 95 then return notify(player, cfg.system .. " is already stable.") end
		if (stationCooldown[station] or 0) > os.clock() then return notify(player, cfg.label .. " is recharging.") end
		if not run.inventory:Has(cfg.cost) then
			return notify(player, "Not enough materials: needs " .. Config.FormatItems(cfg.cost) .. ".")
		end

		local txId = "qa:" .. HttpService:GenerateGUID(false)
		if not run.inventory:TryDebit(cfg.cost, txId) then return end
		run.ship:ApplyDelta(cfg.system, cfg.field, cfg.amount, txId)
		stationCooldown[station] = os.clock() + cfg.cooldown
		run.recordStat(player, "actions", 1)
		if run.director then run.director:OnRepaired(cfg.system, "action:" .. actionId) end
		Remotes.Get(N.Alert):FireAllClients({ severity = "Info", text = ("%s used %s (+%d %s)."):format(player.DisplayName, cfg.label, cfg.amount, cfg.system) })
	end

	-- Same validated path for prompts, future UI buttons and Studio tests
	QuickActions.Use = onTriggered

	for _, s in ipairs(CollectionService:GetTagged("QuickAction")) do
		if s:IsA("Model") then
			local pp = s:FindFirstChildWhichIsA("ProximityPrompt", true)
			if pp then pp.Triggered:Connect(function(player) onTriggered(player, s) end) end
		end
	end
end

return QuickActions
