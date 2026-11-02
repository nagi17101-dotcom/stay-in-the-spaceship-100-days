-- Minigame registry: minigameId -> server module. Add Batch A/B/C entries here.
local folder = script.Parent
return {
	PowerBus = require(folder.PowerBus),
	CoolantLoop = require(folder.CoolantLoop),
}
