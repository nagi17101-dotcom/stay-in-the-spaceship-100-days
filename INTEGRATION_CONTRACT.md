# INTEGRATION_CONTRACT (v1, owner: LEAD)
Types: `src/shared/Types/ShipTypes.luau`. Remotes: `src/shared/Network/Remotes.luau` (single registry).

## Minigame module (server: `src/server/Minigames/<Id>.luau`, register in `Registry.luau`)
- `Id`, `System`, `RepairAmount`
- `Generate(tier, seed) -> publicPuzzle, privateData` — public must not reveal a solution
- `CheckSolvable(public, private) -> boolean`
- `ValidateShape(public, action) -> boolean` — strict payload typing
- `Validate(public, private, action) -> ok, reasonCode, message` — any valid answer accepted
- Optional: `AlwaysAvailable`, `CanOpen(run) -> ok, why`, `OnSuccess(run, player, public, action, taskId)` for non-repair tasks (rewards credited server-side, idempotent by taskId)
Client UI: `src/client/Tasks/<Id>UI.luau` with `Mount(body, public) -> { getAction }`. UI never grants anything.

## Task lifecycle (TaskService)
AVAILABLE → ACTIVE → VALIDATING → RESOLVED / FAILED / EXPIRED / ABORTED. One task per player, one per station, TTL 120s, 4 attempts, repair applied exactly once by txId.

## World tags & attributes (built by `tools/BuildShip.luau`)
| Tag | Instance | Attributes |
|---|---|---|
| RoomLight | Part | NominalColor? |
| RoomSign | Part + SurfaceGui.Label | Target? (room id) |
| RepairStation | Model (PrimaryPart has ProximityPrompt) | StationId, MinigameId, System |
| SalvagePoint | Model | SalvageType (key in `Config.SalvageLoot`), Charges (runtime) |
| QuickAction | Model | ActionId (key in `Config.QuickActions`) |
Rooms: `Workspace.Ship.Rooms.<RoomId>` with RoomId, DisplayName, Systems ("A,B"), Mode (runtime).

## Economy
Shared crew materials via `InventoryService` only: `TryDebit(cost, txId)` / `Credit(items, txId)`, idempotent per txId.

## Lobby / party (LobbyPartyService)
- One party per server (single-place prototype). `PartyAction(action, value)`: create, join, leave, ready(bool), difficulty(name, leader only), launch(leader only).
- Launch needs min..max crew (min 1 in Studio, 2 live) and all READY; 5s countdown, cancelled by any roster/ready/difficulty change.
- `PartyState`: `{ minPlayers, maxPlayers, party?{leaderId, members[{userId,name,ready,leader}], difficulty, countdownEndsAt?}, run{active, day, phase, crew[userId]} }`.
- `run.crew[userId]` gates every ship interaction (`InteractionGuard.IsCrew`). Disconnected crew stay in `run.crew` and are placed aboard on rejoin.
- World: `Workspace.Lobby.LobbySpawn` (only enabled spawn), `Workspace.Lobby.PartyDisplay.SurfaceGui.Label`.

## Progression (ProfileService)
- Rewards only via `ProfileService.Grant(player, grantId, { xp?, stats?, bestDay? = {difficulty, day} })`. grantId must be globally unique and deterministic: `day:<runId>:<day>`, `runend:<runId>`, later `ach:<id>`, `purchase:<receiptId>`. Same id is applied at most once per profile (last 400 ids kept in the profile).
- Never write profiles outside ProfileStore (UpdateAsync + session lock). A failed or session-only save must never be shown as saved.
- Schema changes: bump `ProfileSchema.VERSION`, add a step in `Migrate`, keep unknown fields.
