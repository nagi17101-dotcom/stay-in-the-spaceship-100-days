# MASTER BUILD GOAL — STAY IN THE SPACESHIP FOR 100 DAYS
**For the lead autonomous AI software-development assistant.**

You are the technical lead, Roblox gameplay engineer, co-op systems architect, level designer and integrator. **Build an original, playable 3D multiplayer Roblox experience.** Do not stop after writing a game design document or an empty map.

## Exact game identity
Name: **Stay in the Spaceship for 100 Days**.
- Gameplay: **2–6-person cooperative survival and spaceship maintenance**.
- Premise: an original exploration ship is stranded on a long emergency transit route. Keep systems alive and collect navigation data through 100 navigation cycles (called "days" for player readability). When Day 100 is survived, unlock a satisfying main-mission conclusion, then let the team choose **Extract** or **Continue to Endless Voyage / Day 101+**.
- World: fully 3D, Roblox-friendly proportions; **clean mid-sized interior with different rooms** and black outer space beyond windows; lobby is a tidy futuristic orbital embarkation terminal with a star-black view; no terrestrial night/day cycling.
- Gameplay pillars: (1) shared ship survival, (2) meaningful cooperative workload, (3) interactive varied minigames, (4) resource acquisition and crafting, (5) manageable but escalating emergencies, (6) upgrades and replayable voyages.
- Visual rule: simple, deliberate, premium-looking low-poly or stylized industrial sci-fi, **not busy, not maze-like, not merely empty gray boxes**.
- Difficulty: select **Cadet / Standard / Veteran** before deployment; dynamically adjust incident concurrency for 2–6 players. Each difficulty must be achievable without paid purchases.

## Understand the specifications BEFORE coding
Read the complete package, especially:
- `01_DESIGN/01_GAME_DESIGN_BIBLE.md`
- `01_DESIGN/02_LOBBY_AND_SHIP_MAP.md`
- `01_DESIGN/03_100_DAYS_AND_ENDLESS.md`
- `01_DESIGN/04_DIFFICULTY_AND_COOP.md`
- `02_SYSTEMS/01_SHIP_SYSTEMS_AND_FAILURES.md`
- `02_SYSTEMS/02_MINIGAME_BIBLE.md`
- `02_SYSTEMS/03_RESOURCE_GATHERING_AND_CRAFTING.md`
- `02_SYSTEMS/04_EVENTS_THREATS_AND_DIRECTOR.md`
- `02_SYSTEMS/05_UI_AUDIO_AND_VISUALS.md`
- `02_SYSTEMS/06_PROGRESSION_SAVES_AND_MONETIZATION.md`
- `03_AI_TASKS/01_AGENT_TEAM_AND_OWNERSHIP.md`
- `05_TECH/01_ARCHITECTURE_AND_ROJO.md`
- `05_TECH/02_INTEGRATION_CONTRACTS.md`
- `06_PRODUCTION/01_MILESTONES_AND_GATES.md`
- `06_PRODUCTION/03_TEST_AND_ACCEPTANCE.md`

## Required real gameplay
1. **Lobby** with team join/leave, 2–6 player cap, party readiness, selected difficulty, launch countdown, clear spaceship boarding affordance, teleport failure recovery, and sensible small-scale staging. Do not fill it with random props or floating signs.
2. **Ship** with a coherent 3D traversable layout, bridge, engine/reactor, life support, cooling/power, cargo/workshop, navigation/comms, medical/rest, EVA/airlock, and engineering sections. Use combined room areas where necessary to keep travel short. Clear directional signage, no confusing corridor labyrinth.
3. **Day cycle** with short preparation, active maintenance, escalating event window, resolution and rewards; 100 logical days and Endless. No external day/night changes.
4. **Server-authoritative interdependent systems**: hull, oxygen, power, reactor stability, temperature, engines, shields, supplies and crew safety. Failure cascades must have clear causality and reachable solutions.
5. **Meaningful tools and resources**: recycle, salvage, incoming debris, fabrication, limited EVA for advanced resources. No infinite clicker loops or involuntary paywalls.
6. **Twelve distinct task/minigame concepts**, playable in three difficulty tiers initially (Basic/Advanced/Expert) and under four task-specific variation dimensions. Implement in 4+4+4 verified batches; do not fake buttons or hardcode one correct answer.
7. **Crisis Director** tracks days, difficulty, team size, resources, live failures, accessible rooms, recent incident history, and permits recovery. It must not intentionally create irrecoverable situations.
8. **Multi-player**: flexible specialization, meaningful interactions, synchronized state, two-player solvability, clear quick pings, handling disconnect and rejoin.
9. **UI**: restrained spaceship panels, obvious objective, ship condition and alerts, accessible PC/mobile input. Consistent English source/localization readiness.
10. **Progression**: persistent XP, modest unlocks/cosmetics, run-only upgrades, safe saves; optional ethically designed Robux cosmetics/convenience, not essential resources or impossible free challenges.
11. **Day 100 choice**: genuine crew success event and choice; Do not silently kill the run after 100. Endless increments day number and continues scaling carefully.

## Visual inspiration and copyright
Read `04_REFERENCES/REFERENCE_LINKS_AND_RIGHTS.md` and optionally open `REFERENCE_BOARD.html`. Reference **human-made games** such as Among Us (room naming clarity only), FTL (system dependencies), Void Crew (cooperative machinery), Space Station 14 (operational emergencies), and 99 Nights in the Forest (survive-day progression). **Never copy room layout, character silhouettes, precise tasks, textures, screenshots, UI, logos or code.** Do not use AI-generated artwork for design references. Kenney's CC0 space kits are optional usable source assets with their own clear license.

## Development & coordination requirements
- Create a **NEW dedicated project/repository**, never within or over Stack Shift or Control Room. Suggested new workspace: `C:\RobloxProjects\STAY_IN_THE_SPACESHIP_100_DAYS`, after checking existing paths; do not overwrite.
- Reuse available Roblox Studio/Rojo installation if present. Do not interfere with other Studio instances, Rojo ports or Git worktrees.
- Lead AI owns source of truth, schema and merges. Other AIs can work **only after** shared interfaces and independent branches/worktrees are established; see `03_AI_TASKS/*`.
- Use robust Luau server validation, idempotent rewards/purchase receipts, DataStore retries, no client-trusted economic operations.
- Keep a real task board with evidence; do not mark anything complete without tests.
- Use small, testable releases. **First prove 2–6 player lobby, one clean ship, 2–3 working systems, one full survival day, two complete minigames, a salvage interaction and a failure/recovery outcome.** Then expand.
- Test with real Roblox Studio access when possible; simulated tests and build passing are not equivalent to visual/multiplayer playtests.
- No publishing, real purchases, API tokens or paid asset acquisitions without explicit owner authorization.

## Implementation sequence
**M0**: environment discovery, new isolated repo, brief tech contracts, launchable Rojo/Studio project.
**M1**: visually coherent lobby and compact ship, 2–6 player test, one day with repair and reward.
**M2**: systemic survival loop, four real minigames, resource gathering, real failure cascades.
**M3**: persistent progression, six-to-eight minigames, more threats, 2–6 scaling.
**M4**: twelve minigames, 100-day milestone progression, balanced late game, Endless.
**M5**: localization, accessibility, optimization, monetization scaffolding (without real purchases), release QA.

## First actions
1. Inspect actual environment; report capability and project isolation.
2. Read package, confirm key constraints in `GAME_SPEC` / source docs (not lengthy prose).
3. Create new project and a small task board; initialize repository and modular Rojo mapping.
4. Implement **M1 playable vertical slice** and test it, including 2-player and 6-player behavior where tools permit.
5. Make an evidence-backed progress report with remaining blockers and next assigned tasks.

**Quality bar: a coherent, genuinely fun spaceship survival experience, not a copied Among Us map and not a giant empty hall full of unrelated minigames.**
