# PRODUCTION ROADMAP — NO FAKE COMPLETION

## Release rule
A milestone is `DONE` only if required implementation exists, build/tests are recorded, applicable Studio tests were performed (or explicitly marked blocked), and the integration branch is stable. A documentation-only milestone cannot unlock the next content batch. Every commit should keep a playable or revertible point.

## M0 — Project isolation and contracts
**Lead:** detect tools & active Roblox Studio instances; create new repo at verified new location, Rojo project, test scaffolding, shared types, agent documentation, first commit. Confirm Stack Shift and Control Room untouched. **Gate:** `rojo build` (or installed equivalent) passes; correct project identity/PlaceId recorded; one small room loaded safely in intended test place. No duplicate Roblox Studio mutations.

## M1 — Core vertical slice (first playable experience)
**World:** clean 2–6 lobby with simple staging/ready UI; short high-tech hallway/bridge, life support, power room, cargo pickup and minimal black-space windows. **Lead:** party and run setup (simulation for Studio if teleports not available), one complete day, ship status HUD, server hull/O2/power and two valid incidents. **Puzzles:** two working minigames, one with multiple real generated seeds. **Gate:** two players can board, operate, fix a system, collect one salvage component, survive a day, see a result and return; 6 players can fit in corridors. No static fake success buttons.

## M2 — Survival alpha
Implement all primary systems, first four complete minigames (Batch A), Crisis Director with causal chains and feasibility checks, basic crafting/recycling, optional external drone scan, short sector chain to Day 10, real 2/6 scaling. **Gate:** at least 10 days can play without softlocks or worsening resource deficit; 100+ seeds/tier checks for Batch A, when automated runners support.

## M3 — Voyage beta
Add Comms/Navigation, EVA prototype, sector modifiers, Batch B (8 total minigames), profile XP/unlocks/saving, party disconnect handling, optional resume prototype. **Gate:** live multiplayer day 25–50 test, no reward duplication, valid O2 comeback, filtered alerts, Cadet/Standard/Veteran distinct but fair.

## M4 — Full Day 100 + Endless
All 12 minigames integrated, sector bands, specialized 91–99 buildup, playable Day-100 3-stage mission, majority Extract/Endless choice, 101+ rotation and difficulty ceiling, run loss and persistence. **Gate:** deterministic accelerated QA simulations can reach 100/101; actual normal-speed playtests scheduled and results separated. Test full 2-player route and late-join/disconnect.

## M5 — Content/quality/shipping candidate
Improve actual world details, mobile UI, accessibility, sound, localization, save failure handling, exploit audit and optimization. Monetization placeholders only until permission. **Gate:** verified no P0, critical flows play-tested, 30 FPS mobile target profiled on hardware, release checklist complete. Publish only after explicit user approval.

## Recommended agent sequence
- Day 1 work session: Lead M0 and M1 source-of-truth; WORLD may draft geometry only after room/station naming contract.
- After interfaces: PUZZLES Batch A; QA initial read-only. Agents own isolated files and commits.
- Each Batch: PUZZLES -> Lead contract review -> merge -> tests -> Studio playtest -> next Batch permission.
- If model quotas run out, use Lead sequentially, do not spend the session organizing unavailable agents.

## Anti-overplanning rule
Documentation initial effort should be bounded. The first real game test is a priority. Keep design files updated with changes actually implemented. Never claim more completeness than actual build demonstrates.
