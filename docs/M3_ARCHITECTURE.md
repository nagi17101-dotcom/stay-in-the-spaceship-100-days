# M3 Architecture — Batch A minigames + Crisis Director v1

Order: **HullSeal → OxygenMixer → CrisisDirector**. Incidents need real repair paths, so minigames come first.

## 1. Minigames (unchanged contract, see INTEGRATION_CONTRACT.md)
| Id | System | Station | Rules module (shared, public) | Status |
|---|---|---|---|---|
| HullSeal (M01) | Hull +35 | Hub `HUB-HullSeal` | `Shared/Minigames/HullSealRules` | DONE |
| OxygenMixer (M02) | Oxygen +30 | Life Support `LS-OxygenMixer` | `Shared/Minigames/OxygenMixerRules` | DONE |
| PowerBus (M04) | Power +35 | Reactor | — | DONE |

Pattern: pure rule evaluation lives in a **shared** module (client shows live hints, server re-runs it as authority). The **server** module owns `Generate` (builds a known solution first, then obstacles around it), `CheckSolvable`, `ValidateShape`. Solutions never leave the server. Every generator gets a 300-seed/tier self-test.

## 2. Crisis Director v1 (`src/server/CrisisDirector/`) — IMPLEMENTED
```
CrisisDirector/
  Director.luau          -- tick during Active phase, budget, scheduling, lifecycle
  IncidentTemplates.luau -- data: id, rootCause, effects, repairPaths, prerequisites, weight, cooldown, severity
  Feasibility.luau       -- pure: can this incident be resolved by THIS crew with THESE resources in time?
```
### Inputs
`day, sector, difficulty tuning, crewPresent, ship systems, inventory, active incidents, template cooldowns, seeded rng`.

### Budget
`budget = min(cap, baseDay(day) × incidentBudgetFactor × teamFactor(crew) × stressRelief(shipHealth))`
- `stressRelief < 1` when the ship is already hurt → fewer/shorter incidents (never pile on a losing crew).
- Critical incidents also respect `maxConcurrentCritical` (difficulty) and the **two-player invariant**: a mandatory incident never needs more simultaneous stations than crew present (max 2 for 2 players).
- No spawns in the first/last 10s of Active, none during Prepare/Transition, emergencies, or a post-emergency **RECOVERY WINDOW**.

### Incident lifecycle
`Queued (advance notice) → Active (effect applied: degrade/fault on root system) → Resolved (validated task or quick action on that system) | Escalated (timer: worsens one step, never instant loss)`.
Resolution hooks off existing server events — `TaskService` resolve and `QuickActionService` use — via one `Director.OnSystemRepaired(system, source)` call. No new client trust.

### Feasibility check (pure, unit-tested)
A template is spawnable only if at least one repair path is fully available:
- station exists and its room is reachable,
- required materials are in inventory **or** a material-free path exists (e.g. minigame),
- `travel + task time × worst latency ≤ graceSeconds × graceFactor`,
- simultaneous stations ≤ crew present.
If no template passes → spawn nothing (never an untested impossible scenario).

### v1 template set (uses only content that exists)
| Template | Root | Effect | Repair paths |
|---|---|---|---|
| MicroBreach | Hull | −20 Hull, leak | HullSeal · HullPatch kit |
| BreakerTrip | Power | −30 Power | PowerBus |
| CoolantJam | Cooling | −30 Cooling (reactor heats) | CoolantLoop |
| FilterClog | Oxygen | O2 regen halved | OxygenMixer (after M3-02) · EmergencyO2 |
| ChainHotCore | Cooling→Reactor | CoolantJam + reactor wear ×2 | CoolantLoop, then PowerBus |

### Stability
Cooldown per template, max chain depth 2, causal chain id per incident, hysteresis already in ShipState. Deterministic from run seed (reproducible logs: `[Director] day, template, seed, result`).

### Implementation notes (v1)
- Budget: `min(4, (1 + 0.15·day) × incidentBudgetFactor × clamp(1 + 0.15·(crew−2), 1, 1.6) × relief)`; relief 0.5 (<50% avg) / 0.75 (<70%) / 1. Day 1 ≈ one Major incident.
- Spawn check every 8s in Active, skipping the first/last 10s, emergencies and a 25s RECOVERY WINDOW after an emergency.
- Feasibility rejects: too early, same template or same root system already active, critical cap, worst case (spawn + all escalations) dropping any value below 15, a step without an available path, total path time > escalation window × graceFactor.
- Incidents persist across Prepare/Transition (no magic reset); cleared on Lobby/Failed.
- HUD objective priority: emergency > active incident step > worst system > phase text.
- Studio dev: `DevCommand:Invoke("incident", "<TemplateId>")`, `DevCommand:Invoke("director")`.
