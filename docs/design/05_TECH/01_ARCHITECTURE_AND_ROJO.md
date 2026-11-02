# ROBLOX TECHNICAL ARCHITECTURE — BUILDABLE, ISOLATED, AUDITABLE

## Workspace safety
This is a **separate, NEW** experience and repository. Suggested path (not evidence of existence): `C:\RobloxProjects\STAY_IN_THE_SPACESHIP_100_DAYS`. Before creating inspect for collision; do not overwrite. Never modify `STACK_SHIFT` or `CONTROL_ROOM_BLACKOUT`, their Rojo port, Studio instance, or working branches. Reuse installed Rojo safely if available.

## Logical places
**Lobby Place:** small futuristic space-port with queue/party and loading/info, limited economic displays. **Voyage Place:** reserved co-op server for one ship/party and 2–6 players. Consider a simplified single-place prototype only for M1 if teleport cannot be fully tested; make clear future separate-place routing. `TeleportService:TeleportAsync` with `TeleportOptions.ReservedServerId` follows current Roblox docs; use GUID and real place IDs supplied by the project, never invented IDs. Teleport features may require published test experience; Studio standalone cannot prove them.

## Recommended Rojo file tree (build incrementally)
```
STAY_IN_THE_SPACESHIP_100_DAYS/
├── default.project.json
├── AGENTS.md
├── GAME_SPEC.md
├── INTEGRATION_CONTRACT.md
├── TASK_BOARD.md
├── src/
│   ├── shared/
│   │   ├── Config/             Difficulty, systems, days, recipes
│   │   ├── Types/              Luau types/schemas
│   │   └── Network/            Remote name/schema table
│   ├── server/
│   │   ├── Bootstrap.server.luau
│   │   ├── ShipSimulation/
│   │   ├── CrisisDirector/
│   │   ├── DayCycle/
│   │   ├── Inventory/
│   │   ├── LobbyMatchmaking/
│   │   ├── Progression/
│   │   └── Security/
│   ├── client/
│   │   ├── Bootstrap.client.luau
│   │   ├── HUD/
│   │   ├── Interactions/
│   │   ├── Localization/
│   │   └── Effects/
│   ├── minigames/
│   │   ├── Core/
│   │   ├── Generators/
│   │   ├── Validators/
│   │   └── UI/
│   └── world/
│       ├── Lobby/
│       ├── Ship/
│       ├── Modules/
│       └── Signs/
├── tests/
└── docs/
```
Do not put `ServerScript` inside shared replication. Keep authoritative secrets/server handlers in ServerScriptService. Ensure clients can access only public puzzle UI modules; generator and validator server modules remain server-owned. Design source mapping carefully before finalizing actual project JSON.

## Main server modules
- `RunCoordinator`: per-voyage crew/run ID, mission state, room system graph.
- `ShipStateService`: state machine with bounded ticks and dependency propagation.
- `DayCycleService`: prep/active/results/day 100/Endless.
- `CrisisDirector`: deterministic incident selection, feasibility proof, recovery.
- `InventoryService`: atomic shared resource debits/credits and crafting.
- `TaskService`: signed/validated task instance identifiers, station proximity, server minigame validators.
- `LobbyPartyService`: server-owned group composition, ready state, difficulty and teleport locks.
- `ProfileService`: robust DataStores, versioned schema and idempotent grants.
- `UIReplicator`: filtered/paced state delta updates, no per-frame remote spam.

## Performance and networking
- Server tick for environmental simulation ~1–4Hz starting point, event-driven exceptions; derived client bars animate locally.
- Use no real-time network physics for dozens of floating debris parts. Decor starfield procedural low cost.
- Every RemoteEvent validates `player`, `runId`, `taskId`, station proximity, expected state, supplies, cooldown and action shape.
- Keep telemetry: incident seed/ID, resource transaction ID, day, repair results and tests for deterministic reproductions.
- Time-sensitive rescue events tolerate network jitter and player disconnect.

## Data persistence
DataStoreService for permanent profiles/authorized run checkpoints, update/retry/version keys. MemoryStoreService for transient queue/cross-server coordination where necessary; memory store data can expire and must not be used as permanent saves. Avoid saving every simulated tick. TeleportData must not contain secure currency/entitlement secrets.

## Real testing requirements
Rojo build and static tests confirm only file integrity. Need Roblox Studio test for 3D scale, control affordance and 2–6 multiplayer; reserved-server teleport flows often need published private test place/client integration. Never state 'teleport tested' after just a local mock.

## Official docs
- Roblox reserved servers: https://create.roblox.com/docs/projects/teleport-private-servers
- Roblox multi-place teleport: https://create.roblox.com/docs/projects/teleport
- Roblox MemoryStore queues: https://create.roblox.com/docs/cloud-services/memory-stores/queue
- Roblox MemoryStore overview: https://create.roblox.com/docs/cloud-services/memory-stores
