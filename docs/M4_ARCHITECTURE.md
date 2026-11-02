# M4 Architecture — Day 100 finale, Endless, remaining minigames

## Day cycle phases
`Lobby → Prepare → Active → Transition → … → (day 100 Transition) → Finale → Vote → Complete | Prepare(day 101, Endless)`; `Failed` from any simulated phase.
- **Finale is simulated** (wear, emergencies, loss still possible). `Vote` and `Complete` are terminal (no simulation).
- Director spawns only in `Active`, so no random incidents during the finale.

## FinaleService (`src/server/Finale/FinaleService.luau`)
| Stage | Steps | Advances on |
|---|---|---|
| 1 Final route alignment | SignalTriangulator | `task:SignalTriangulator` |
| 2 Transit core | ReactorPhase → PowerBus (sequential: 2-player safe) | `task:*` |
| 3 Beacon transmission | craft at Beacon Fabricator (`Config.Finale.TransmitterCost`) → hold `HoldSeconds / graceFactor` with avg condition ≥ `HoldMinCondition` and no emergency | prompt (server-validated) / server tick |
- All progress comes from server events: `run.notifyRepair(system, source)` (TaskService, QuickActionService) feeds Director **and** Finale.
- TaskService opens a finale-step task even if the system is ≥98% (no "No repair needed" dead end).
- No material dead end: transmitter needs 2 Filament (never spent elsewhere) + 1 Scrap; salvage points restock when the finale starts.
- Hold pauses (does not reset) when condition drops; crew is warned once.

## Vote
- `VoteState` S→C, `CastVote` C→S. Only crew present count; early resolve when all voted; **tie, no votes or timeout → Extract** (nobody stranded).
- On finale completion every crew member aboard gets `finale:<runId>` (+`Config.Finale.Xp`, bestDay 100 → Survive100 achievement) regardless of the vote.
- Extract: `runend:<runId>` (runs +1), `Complete` phase, `RunComplete` overlay, return to lobby after `CompleteReturnSeconds`.
- Continue: `run.endless = true`, day 101 `Prepare`. Later loss grants the same `runend:<runId>` once.

## Endless
Sector "Endless Voyage"; Director budget is already capped (`BUDGET_CAP`), so difficulty does not grow without bound. Achievements at 125/150/200 per difficulty. HUD shows `DAY 101 · ENDLESS VOYAGE`.

## HUD objective freshness
RunCoordinator sends `ShipStateDelta` when systems change **or** the objective text changes, and once per phase change.

## Studio dev commands
`DevCommand:Invoke("finale")` (jump to Day 100), `"finalestep"` (advance one step), `"finalestatus"`.

## Next: minigames M08–M12
Same contract (shared Rules + server generator/validator + UI + 300-seed self-test + station) and one Director template each.

| Id | System | Station | Rules module | Status |
|---|---|---|---|---|
| GravityStabilizer (M08) | Cargo +35 | Workshop `WS-GravityStabilizer` | `Shared/Minigames/GravityStabilizerRules` | DONE |
| DroneSalvage (M09) | resource task (no repair) | Workshop `WS-DroneSalvage` | `Shared/Minigames/DroneSalvageRules` | DONE |

Minigame module optional hooks (TaskService): `AlwaysAvailable` (open without damage), `CanOpen(run) -> ok, why`, `OnSuccess(run, player, pub, action, taskId)` (server-side rewards, keyed by taskId).
| ShieldResonance (M10) | Shields +35 | Bridge `BR-ShieldResonance` | `Shared/Minigames/ShieldResonanceRules` | DONE |

Shield mechanic: when shield output < `Dependencies.ShieldSafe` (50), the hull takes extra wear up to `ShieldHullWear` (0.15/s) during Active (Power → Shields → Hull chain). The Main Junction room now tracks `Hull,Shields` for lights/signs.

## Shield mechanics (M10, merged)
- **Incident absorption** (CrisisDirector): Hull damage from incidents × (1 − 0.5 · shield%); alert shows "Shields absorbed X%".
- **Passive wear** (ShipStateService): below `Dependencies.ShieldSafe` (50) hull loses `deficit · ShieldHullWear(0.15) · wf` per second.
- **Station**: single console on the Bridge (`BR-ShieldResonance`); Bridge room lighting follows Shields, Junction follows Hull only.
- **Incidents**: DebrisBarrage (hull + shields) and IonSquall (shields); Feasibility rejects them when they would cripple Shields.
