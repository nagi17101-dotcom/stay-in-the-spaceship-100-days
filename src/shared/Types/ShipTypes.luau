-- Shared Luau types (contract v1, see INTEGRATION_CONTRACTS)
export type DifficultyPreset = "Cadet" | "Standard" | "Veteran"
export type ShipSystem = "Hull" | "Oxygen" | "Reactor" | "Power" | "Cooling" | "Drive" | "Navigation" | "Comms" | "Shields" | "Cargo"
export type SystemMode = "Nominal" | "Warning" | "Critical"
export type Phase = "Lobby" | "Prepare" | "Active" | "Transition" | "Finale" | "Complete" | "Endless" | "Failed"

-- Wire format (compact): h = health, o = output, m = mode
export type SystemWire = { h: number, o: number, m: SystemMode }

export type PhaseInfo = {
	day: number,
	phase: Phase,
	sector: string,
	phaseStartedAt: number,
	phaseEndsAt: number,
}

export type Snapshot = {
	runId: string,
	revision: number,
	difficulty: DifficultyPreset,
	phaseInfo: PhaseInfo,
	systems: { [ShipSystem]: SystemWire },
	objective: string,
}

export type Delta = {
	revision: number,
	systems: { [ShipSystem]: SystemWire },
	objective: string,
}

export type Alert = { severity: "Critical" | "Warning" | "Info", system: string?, text: string }

return {}
