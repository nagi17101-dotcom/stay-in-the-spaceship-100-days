# M5-01 — Economy & difficulty tuning (QaSim v2)

## QaSim v2 (time-faithful)
`DevCommand("qasim", { seed, untilDay, scale, crew, difficulty })` — Studio only.
- **Time scale** `scale` (default 4): day phases, ship simulation `dt` (`ShipStateService.timeScale`), Director pacing
  (`Director.Timing`, escalation intervals and cooldowns via `Timing.scale`), catastrophe grace and finale hold are all
  compressed by the same factor, so wear/escalation per day matches a real 75 s day (v1 understated wear ~3.4×).
- **Crew model** `crew` workers (default 2 = minimum party): every job occupies a worker for its game-time duration
  (task 30 s, quick action 10 s, salvage 8 s). Priorities: emergency → finale → incident steps (fastest affordable
  path: kits before minigames) → maintenance (< 60 %) → salvage (only while a material is below its cap).
- Metrics: worker utilisation (difficulty signal), incidents, blocked steps, emergencies, upkeep misses, materials spent.

## Changes
| Change | Where |
|---|---|
| Cargo hold cap per material: Scrap 10, Sealant 5, Filter 5, Filament 6, Coolant 5 (overflow discarded, salvage alert says so; HUD shows `n/cap`, amber at cap) | `Config.MaterialCap`, `Inventory:Credit`, `SalvageService`, `ShipHUD` |
| Day-end upkeep from Day 3: 1 Scrap/day (else Hull −6), 1 Filter / 2 days (else Oxygen −12), 1 Coolant / 3 days (else Cooling −10) | `Config.Upkeep`, `World/UpkeepService` |
| Income: Debris Receiver 2 → 1 charge/day; daily crew bonus (1 Scrap) removed (healthy-ship Sealant bonus kept) | `Config.SalvageLoot`, `Config.Rewards` |
| Director budget: day curve capped first, then difficulty × team × relief (Veteran / bigger crews no longer flatten to the same cap after Day 20) | `Director:ComputeBudget` |
| Veteran wear 1.15 → 1.3 | `Config.Difficulty.Veteran` |

## Results (seed 1337, 2-worker crew, scale 4, Day 1 → 40)
| Run | Stock Day 40 (S/Se/F/Fi/Co) | Spent S/Se/F/Fi/Co | Util | Incidents | Min health dip | Emergencies |
|---|---|---|---|---|---|---|
| Standard, old economy | 47/29/30/8/8 (growing) | 26/12/1/6/4 | 61 % | 109 | ~46 | 0 |
| Standard, new economy | 9/5/5/6/0 (capped) | 67/13/18/6/15 | 66 % | 110 | 38 | 0 |
| Veteran, new economy, old budget | 8/4/5/6/4 | 65/12/19/7/14 | 73 % | 121 | 33 | 0 |
| Veteran, new economy + budget fix + wear 1.3 | 7/5/5/3/2 | 71/14/18/10/15 | 76 % | 129 | 23 | 0 |

Reading: materials now flow (spend ≈ 2.6× before, stock bounded, Coolant is the tight one), Veteran loads the crew
~10 points more than Standard. The autopilot never fails a minigame and walks optimally, so real crews will sit higher;
calibrate `DUR.task` against a normal-speed playtest before the next tuning pass.

## Open
- Sealant still sits at cap (only sink: Hull Patch Kit) — candidate for a second sink or lower healthy-ship bonus.
- Cadet and 3–6 crew runs not yet simulated (crew size only changes worker count; Director team factor uses real players).
