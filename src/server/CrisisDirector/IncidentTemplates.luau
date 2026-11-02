-- IncidentTemplates (v1): data only. Every step lists alternative repair paths that already exist in the game.
-- kind = "task" (minigame id at a RepairStation) | "action" (QuickAction id, costs materials).
-- Escalation never causes instant loss: Feasibility rejects templates whose worst case would zero a system.
return {
	{
		id = "MicroBreach", title = "Micrometeor breach", severity = "Major", cost = 1, minDay = 1, weight = 3, cooldown = 120,
		alert = "Micrometeor impact! Hull breached.",
		effects = { { system = "Hull", field = "health", amount = -20 } },
		steps = {
			{ objective = "BREACH: seal it at the Hull Seal console (Junction) or use a Hull Patch Kit.",
				paths = { { kind = "task", id = "HullSeal" }, { kind = "action", id = "HullPatch" } } },
		},
		escalate = { every = 30, max = 2, text = "Breach widening — hull integrity falling.", effects = { { system = "Hull", field = "health", amount = -8 } } },
	},
	{
		id = "BreakerTrip", title = "Power bus breaker trip", severity = "Major", cost = 1, minDay = 1, weight = 3, cooldown = 120,
		alert = "Insulation fault! A power bus breaker tripped.",
		effects = { { system = "Power", field = "health", amount = -30 } },
		steps = {
			{ objective = "BREAKER TRIP: reroute loads at the Power Bus console (Reactor room).",
				paths = { { kind = "task", id = "PowerBus" } } },
		},
		escalate = { every = 30, max = 2, text = "Peripheral loads dropping — power still unbalanced.", effects = { { system = "Power", field = "health", amount = -8 } } },
	},
	{
		id = "CoolantJam", title = "Coolant valve jam", severity = "Major", cost = 1, minDay = 2, weight = 2, cooldown = 150,
		alert = "Coolant valve jammed! Reactor temperature rising.",
		effects = { { system = "Cooling", field = "health", amount = -30 } },
		steps = {
			{ objective = "COOLANT JAM: restore the loop at the Coolant Loop console (Reactor room).",
				paths = { { kind = "task", id = "CoolantLoop" } } },
		},
		escalate = { every = 30, max = 2, text = "Reactor heat building up.", effects = { { system = "Reactor", field = "health", amount = -6 } } },
	},
	{
		id = "FilterClog", title = "Life support filter clog", severity = "Major", cost = 1, minDay = 2, weight = 2, cooldown = 150,
		alert = "Scrubber filters clogged! Oxygen generation reduced.",
		effects = { { system = "Oxygen", field = "health", amount = -30 } },
		steps = {
			{ objective = "FILTER CLOG: rebalance the mix at the Oxygen Mixer (Life Support). Emergency O2 buys time.",
				paths = { { kind = "task", id = "OxygenMixer" } } },
		},
		escalate = { every = 30, max = 2, text = "Breathable reserve dropping.", effects = { { system = "Oxygen", field = "output", amount = -6 } } },
	},
	{
		id = "CoilDrift", title = "Reactor coil phase drift", severity = "Major", cost = 1, minDay = 3, weight = 2, cooldown = 150,
		alert = "Reactor coils drifting out of phase! Output unstable.",
		effects = { { system = "Reactor", field = "health", amount = -25 } },
		steps = {
			{ objective = "COIL DRIFT: resynchronize the coils at the Reactor Phase console (Reactor room).",
				paths = { { kind = "task", id = "ReactorPhase" } } },
		},
		escalate = { every = 30, max = 2, text = "Coil drift worsening — reactor output dropping.", effects = { { system = "Reactor", field = "health", amount = -7 } } },
	},
	{
		id = "GhostEcho", title = "Navigation ghost echo", severity = "Major", cost = 1, minDay = 2, weight = 2, cooldown = 150,
		sectorWeight = { ["Echo Fields"] = 3 },
		alert = "Ghost echo on the comms array! Beacon position unreliable.",
		effects = { { system = "Comms", field = "health", amount = -25 } },
		steps = {
			{ objective = "GHOST ECHO: triangulate the real beacon at the Signal console (Bridge).",
				paths = { { kind = "task", id = "SignalTriangulator" } } },
		},
		escalate = { every = 30, max = 2, text = "Navigation drifting on bad signal data.", effects = { { system = "Navigation", field = "health", amount = -7 } } },
	},
	{
		id = "ThrusterDrift", title = "Thruster alignment drift", severity = "Major", cost = 1, minDay = 3, weight = 2, cooldown = 150,
		sectorWeight = { ["Outer Freight Belt"] = 2 },
		alert = "Debris strike knocked the lateral thrusters out of alignment!",
		effects = { { system = "Drive", field = "health", amount = -25 } },
		steps = {
			{ objective = "THRUSTER DRIFT: plot a corrective burn at the Thruster Matrix (Bridge).",
				paths = { { kind = "task", id = "ThrusterMatrix" } } },
		},
		escalate = { every = 30, max = 2, text = "Drift growing — transit slowing.", effects = { { system = "Drive", field = "health", amount = -7 } } },
	},
	{
		id = "GravityWobble", title = "Gravity stabilizer wobble", severity = "Major", cost = 1, minDay = 3, weight = 2, cooldown = 150,
		sectorWeight = { ["Dead Relay Zone"] = 2 },
		alert = "Gravity rings out of balance! Cargo handling unstable.",
		effects = { { system = "Cargo", field = "health", amount = -25 } },
		steps = {
			{ objective = "GRAVITY WOBBLE: rebalance the rings at the Gravity Stabilizer (Workshop).",
				paths = { { kind = "task", id = "GravityStabilizer" } } },
		},
		escalate = { every = 30, max = 2, text = "Wobble growing — cargo racks shifting.", effects = { { system = "Cargo", field = "health", amount = -7 } } },
	},
	{
		id = "ReceiverJam", title = "Cargo receiver jam", severity = "Major", cost = 1, minDay = 4, weight = 1, cooldown = 200,
		alert = "Cargo receiver jammed! Drone salvage cannot dock.",
		effects = { { system = "Cargo", field = "health", amount = -20 } },
		steps = {
			{ objective = "RECEIVER JAM: recalibrate cargo handling at the Gravity Stabilizer (Workshop) to free the drone dock.",
				paths = { { kind = "task", id = "GravityStabilizer" } } },
		},
		escalate = { every = 35, max = 2, text = "Receiver rails grinding — cargo handling degrading.", effects = { { system = "Cargo", field = "health", amount = -6 } } },
	},

	{
		id = "ComponentWear", title = "Worn couplings", severity = "Major", cost = 1, minDay = 8, weight = 2, cooldown = 150,
		sectorWeight = { ["Outer Freight Belt"] = 2 },
		alert = "Worn couplings failing on the power and coolant lines!",
		effects = { { system = "Power", field = "health", amount = -18 }, { system = "Cooling", field = "health", amount = -12 } },
		steps = {
			{ objective = "WORN COUPLINGS: fabricate a replacement part (Workshop Fabricator) or reroute at the Power Bus.",
				paths = { { kind = "task", id = "FabricatorAssembly" }, { kind = "task", id = "PowerBus" } } },
		},
		escalate = { every = 35, max = 2, text = "Couplings degrading — power line losing load.", effects = { { system = "Power", field = "health", amount = -6 } } },
	},
	{
		id = "DebrisBarrage", title = "Debris barrage", severity = "Major", cost = 1, minDay = 2, weight = 2, cooldown = 150,
		sectorWeight = { ["Outer Freight Belt"] = 2 },
		alert = "Debris barrage! Hull impacts and shield emitters stressed.",
		effects = { { system = "Hull", field = "health", amount = -15 }, { system = "Shields", field = "health", amount = -15 } },
		steps = {
			{ objective = "DEBRIS BARRAGE: re-tune shield harmonics at the Shield Resonance console (Bridge).",
				paths = { { kind = "task", id = "ShieldResonance" } } },
		},
		escalate = { every = 30, max = 2, text = "More impacts — hull taking hits.", effects = { { system = "Hull", field = "health", amount = -6 } } },
	},
	{
		id = "IonSquall", title = "Ion squall", severity = "Major", cost = 1, minDay = 3, weight = 2, cooldown = 150,
		sectorWeight = { ["Ion Corridor"] = 3 },
		alert = "Ion squall! Shield resonance mismatched to the storm spectrum.",
		effects = { { system = "Shields", field = "health", amount = -25 } },
		steps = {
			{ objective = "ION SQUALL: match the storm spectrum at the Shield Resonance console (Bridge).",
				paths = { { kind = "task", id = "ShieldResonance" } } },
		},
		escalate = { every = 30, max = 2, text = "Ion surge leaking into the power bus.", effects = { { system = "Power", field = "health", amount = -6 } } },
	},
	{
		id = "HotCore", title = "Hot core chain", severity = "Critical", cost = 2, minDay = 4, weight = 1, cooldown = 300,
		alert = "HOT CORE: coolant loop blocked and reactor output unstable!",
		effects = { { system = "Cooling", field = "health", amount = -25 }, { system = "Reactor", field = "health", amount = -15 } },
		steps = {
			{ objective = "HOT CORE 1/2: restore the Coolant Loop first (Reactor room).", paths = { { kind = "task", id = "CoolantLoop" } } },
			{ objective = "HOT CORE 2/2: stabilize output — Reactor Phase console or Power Bus.",
				paths = { { kind = "task", id = "ReactorPhase" }, { kind = "task", id = "PowerBus" } } },
		},
		escalate = { every = 40, max = 2, text = "Core temperature climbing.", effects = { { system = "Reactor", field = "health", amount = -8 } } },
	},
}
