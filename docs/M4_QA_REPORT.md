# M4 gate — accelerated QA run (Studio, 2026-11-01)

Tool: `ServerScriptService.Server.Dev.QaSim` (Studio only) via `DevCommand("qasim", {seed, untilDay, active})`,
`qastatus`, `qareport`, `qastop`. Runs on the real server loop with compressed days (Prepare 0.5 s / Active 22 s /
Transition 0.5 s, Director quiet 3/3 s, check 4 s), an autopilot crew (resolves incident steps through
`notifyRepair` / `ApplyRepair` / inventory debits, salvages every Prepare, maintains systems < 55 %), real Day-100
finale (tasks via `notifyRepair`, Beacon craft debits `TransmitterCost`, hold counted by `FinaleService:Tick`)
and a unanimous "Continue" vote. Profile grants are intercepted (counted, never written).

## Result — seed 1337, solo crew, Standard
| Metric | Value |
|---|---|
| Reached | Day 103 (Endless), 2449 s wall time |
| Finale | 3 stages complete, hold 20.5 s, vote → Continue → Day 101 |
| Incidents spawned / steps resolved | 208 / 218 (all 14 templates seen, 8–19 each) |
| Unresolvable steps (no affordable path) | 0 |
| Emergencies / losses | 0 / 0 |
| Script errors | 0 |
| Reward grants / duplicate grant ids | 103 / 0 |

## Findings
1. **FIXED — Navigation had no repair path.** No minigame repaired Navigation; it decayed every day
   (min 69 → 30 by Day 103 even with compressed days; at real pace it would bottom out around Day 40).
   M06 SignalTriangulator now also repairs Navigation (`AlsoRepairs`, +35), and the Comms/Nav console opens
   when either system is damaged. Verified in play: Navigation 60 → 94 after one triangulation.
2. **FIXED — finale material softlock risk.** Fabricator blueprints spend Conductive Filament, which the
   Beacon Transmitter needs on Day 100. `FinaleService:Begin` now tops up any shortfall once (`finale:kit:<runId>`).
3. **OPEN (balance, M5) — materials accumulate without bound** when the crew salvages every point each day:
   Scrap 519, Sealant 208, Filter 103 by Day 103. Scarcity disappears after ~Day 10. Candidates: per-material
   cap, fewer salvage charges in later sectors, more material-only incident paths.
4. **Limitation:** compressed days scale ship wear down ~3.4×, so survival pressure is understated; this run proves
   progression/softlock/idempotency, not difficulty balance. Normal-speed playtests remain scheduled separately.
