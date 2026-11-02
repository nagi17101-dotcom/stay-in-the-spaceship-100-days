-- Minigame registry: minigameId -> server module. Batch A: HullSeal, OxygenMixer, ReactorPhase, PowerBus. Batch B: CoolantLoop, ...
local folder = script.Parent
return {
	HullSeal = require(folder.HullSeal),
	OxygenMixer = require(folder.OxygenMixer),
	ReactorPhase = require(folder.ReactorPhase),
	PowerBus = require(folder.PowerBus),
	CoolantLoop = require(folder.CoolantLoop),
	SignalTriangulator = require(folder.SignalTriangulator),
	ThrusterMatrix = require(folder.ThrusterMatrix),
}
