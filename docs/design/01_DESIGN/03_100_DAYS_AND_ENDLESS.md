# THE 100-DAY VOYAGE — PACING, MILESTONES, ENDLESS

## What a day means
A **Day** is an operational navigation cycle aboard a ship in permanent outer-space darkness. Do not produce sunrise, sky color transitions or fake Earth weather. Display `DAY 037 — SECTOR: SILENT BELT` in the ship's console and HUD. A ship clock/progress bar represents the cycle. Day advancement requires the server state machine and isn't trustable to client input.

## Suggested baseline duration
Initial target **~75 seconds live operations + ~15 seconds preparation** per day (90 seconds total). Roughly 150 minutes for a complete 100-day run without acceleration. Cadet can target 70–85 sec, Standard 80–100 sec, Veteran 90–110 sec per day as tuning ranges, but do not reward slow days merely for being slow. These must be playtested. Early days can be shorter and tutorials embedded into gameplay; an intense critical emergency may safely extend a day until a recoverable checkpoint. Do not impose deadlines that are impossible for 2 players.

## Day lifecycle
1. **Ready / Preparation (10–20s):** restock at workshop, review scanner, choose voluntary low-risk prep tasks.
2. **Operations (50–80s):** primary sector goal plus maintenance, salvage and repairs; Director uses an incident budget rather than constant spam.
3. **Crisis / Resolution window (dynamic):** danger may arrive mid-operations; a critical event resolves or becomes persistent state, rather than auto-resetting magically at day boundary.
4. **Transition (5–10s):** ship systems settle, apply route milestone, score team actions, show a concise progress board, next day starts.

## Day sector bands
- **Days 1–5 | Awakening:** easy ship introductions, oxygen filter, cargo scan, small reactor warning; guaranteed understandable rescue actions.
- **Days 6–15 | Outer Freight Belt:** moving debris, first optional EVA, crafting, two-part repairs, workshop tutorial.
- **Days 16–30 | Echo Fields:** static interference, comms triangulation, power choices, alternating scanner data.
- **Days 31–50 | Ion Corridor:** shielding/cooling interplay, repeatable but varied sector contracts, pressure on energy budgets.
- **Days 51–70 | Dead Relay Zone:** remote derelict salvage, spare-part shortages, dangerous but optional supply runs.
- **Days 71–90 | Fading Signal:** increased combined incident budgets and stronger strategic preparation.
- **Days 91–99 | Approach:** unique recognizable finale preparation, repair damaged long-range beacon, earn navigation fragments.
- **Day 100 | Return Signal:** final **three-stage original co-op objective**, successful beacon lock and choice screen. Must be a guaranteed achievable culmination with prior actions mattering, not a cinematic after an arbitrary timer.
- **Day 101+ | Endless Voyage:** sectors expand, modifiers rotate, scores persist in the run, temporary upgrades continue with capped power. Difficulty scales logarithmically/capped; survive as long as possible.

## Day-100 finale — concrete playable stages
A. **Final route alignment**: compare three scanner readings with a navigation pattern. One player may operate, a second provides reference data.
B. **Stabilize transit core**: concurrently route emergency power and control heat; for 2-player teams, tasks are sequential or offer longer stability grace periods.
C. **Beacon transmission**: supply one crafted transmitter component, align communications and hold ship condition above minimum for a short wave; skill and earlier resources affect the margin for error.
On completion: achievement + earned rewards + ship log. Crew sees `MISSION COMPLETE — DAY 100`. A server-controlled majority vote decides `EXTRACT & FINISH` or `CONTINUE — ENDLESS VOYAGE`. All players receive the win achievement even if continuing. If votes tie or timeout, Extract by default. Never permanently strand a player because a teammate quits during voting.

## Optional legitimate pace acceleration
- **Overdrive Navigation** after Day 10: temporarily shortens calm portions of cycles by using reactor efficiency/fuel; not mandatory or sold for Robux.
- **Sector efficiency milestone**: certain verified cooperative goals reduce optional low-interest tasks on subsequent cycles.
- **Ready vote fast-forward** during calm windows; **blocked during critical incidents**, active EVA, or required mission gates.
- Acceleration must never silently skip essential repairs or cheat the day-100 achievement. Prefer faster transitions over multiplying incident frequency.

## Run loss and recovery
- Ship is lost if hull critical, crew life support irrecoverably fails, or a bounded system-specific catastrophe reaches its declared threshold after clear warning. Avoid instant unexplained game-overs.
- During critical failure: activate emergency battery/oxygen reserve, repair task or evacuation route. Give players meaningful chance to recover, adjusted for 2–6 players.
- With valid run-resume: save last **stable transition snapshot**, not each frame; restore with version validation and no duplicate reward grants. Snapshot is party/run-specific and expires after a defined policy (e.g., 48–72h). Resuming may use the original host or eligible crew member with ownership consent. If not reliably implemented, mark as future feature rather than pretend long-run persistence is complete.
- UI clearly states when the run can be resumed and what reset rules apply.

## Repeatability beyond random alarms
Sector modifiers, alternative resource routes, ship module combinations, differing route contracts, ship layout cosmetic variants (without changing navigability), procedural puzzles, event chains and evolving player roles. Do not merely double damage every ten days. From Day 101+, allow milestone records (125, 150, 200, etc.) while preventing infinitely increasing simultaneous task counts.
