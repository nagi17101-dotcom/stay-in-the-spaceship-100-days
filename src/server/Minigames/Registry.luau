-- Minigame registry: minigameId -> server module. Batch A: HullSeal, (OxygenMixer), (ReactorPhase), PowerBus. Batch B: CoolantLoop, ...
local folder = script.Parent
return {
	HullSeal = require(folder.HullSeal),
	PowerBus = require(folder.PowerBus),
	CoolantLoop = require(folder.CoolantLoop),
}
