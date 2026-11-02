# INTEGRATION CONTRACTS — FIRST DRAFT

These contracts are game-architecture requirements, not pre-existing implemented APIs. **LEAD must publish actual Luau types and module paths before other agents begin editing.** Never copy this blindly into production and assume it is complete.

## Shared difficulty data
```lua
export type DifficultyPreset = "Cadet" | "Standard" | "Veteran"
export type PartyConfig = {
    partyId: string,
    leaderUserId: number,
    members: {number},
    difficulty: DifficultyPreset,
    readyUserIds: {[number]: boolean},
    launchLocked: boolean,
}
```

## Ship state high-level
```lua
export type ShipSystem = "Hull" | "Oxygen" | "Reactor" | "Power" | "Cooling" | "Drive" | "Navigation" | "Comms" | "Shields" | "Cargo"
export type SystemState = {
    health: number,
    mode: string,
    output: number,
    capacity: number,
    faults: {string},
    revision: number,
}
export type RunState = {
    runId: string,
    day: number,
    phase: "Prepare" | "Active" | "Transition" | "Finale" | "Complete" | "Endless" | "Failed",
    difficulty: DifficultyPreset,
    crew: {number},
    systems: {[ShipSystem]: SystemState},
    materials: {[string]: number},
    currentIncidents: {string},
    sectorId: string,
    seed: number,
    revision: number,
}
```

## Procedural minigame interfaces
```lua
export type MinigameSpec = {
    minigameId: string,
    version: number,
    difficultyTier: "Basic" | "Advanced" | "Expert",
    seed: number,
    taskId: string,
    relevantSystem: ShipSystem,
    publicPuzzle: {[string]: any}, -- NO hidden solution
    requiredMaterials: {[string]: number},
    expiresAtServerTime: number,
}

-- Engine-owned server methods, shape to finalize:
-- Generate(serverRunState, tier, seed) -> MinigameSpec + privateSolution
-- CheckSolvable(privateSolution, spec) -> boolean
-- ValidateAction(player, taskId, action, serverState) -> result
-- CommitRepair(taskId, serverTransactionId, result) -> exactly-once ship/material changes
-- AbortTask(taskId, reason) -> release reservation safely
```
Never use a user-supplied `success` boolean as proof. A task instance is bound to run ID, station, player(s), version, and reserved resources. Action payloads must be limited and typed. Server carries transaction marker to prevent duplicate rewards.

## Incident descriptor
```lua
export type Incident = {
    incidentId: string,
    typeId: string,
    seed: number,
    targetRooms: {string},
    rootCauseSystem: ShipSystem,
    prerequisites: {[string]: any},
    requiredMinigames: {string},
    possibleRepairPaths: {{string}},
    maxSimultaneousPlayers: number,
    hazardBudget: number,
    graceSeconds: number,
    status: "Queued" | "Active" | "Resolved" | "Failed",
}
```
LEAD implements feasibility checker that accepts team size/resource availability/room graph. A scripted incident with no valid repair path must not spawn.

## Responsibility boundaries
- WORLD creates model names, spawn points, room attributes/tags and station attachment points; publishes entity register and transform info.
- LEAD owns mapping from world `StationId` to authoritative minigame type and ship system.
- PUZZLES creates logic/UI that binds via `minigameId` and does not directly grant currency or mutate state.
- QA validates contracts, reproduces race conditions and confirms actual tests.

## Version and event rules
Schema version increments for breaking changes; detailed migration plan required before merging. Network sends meaningful deltas not all state every frame. UI includes data source and server revision so stale updates cannot revert a newer result. Do not transmit player private data with cross-place teleport; persist secure data server-side.
