# STAY IN THE SPACESHIP FOR 100 DAYS
## Original Roblox 3D Cooperative Survival Game — Complete English Design & AI Development Package

**Status:** Game design and implementation instructions; **NOT a built Roblox game**. All engineering tasks start as `NOT STARTED` until verified by the agent working on them.

**The pitch:** Two to six players board a compact, clean, futuristic spaceship, survive 100 operational days by maintaining interdependent ship systems, gathering supplies, solving varied minigames and responding to unpredictable emergencies. Day 100 concludes the main rescue-route mission; survivors can extract or continue into **Endless Voyage (Day 101+)**. The environment stays deep space throughout. No terrestrial day/night sky cycle.

**Must-have guardrails**
- **3D game only**; immersive human-scale interior, not a 2D overhead map.
- **2–6 cooperative players** in a real matchmaking lobby; solo only for development simulations if necessary.
- **Medium-sized, legible spaceship**; distinct purposeful rooms, no sprawling maze, no excessive decorative clutter.
- **Star-black space outside every window**, including lobby observation windows; no bright daytime skies.
- **Original art and mechanics.** Other games serve as inspiration for design principles, not blueprints or copied minigames.
- **100 meaningful navigation days**, with a player-choice Endless continuation.
- **Three selectable difficulty presets** and adaptive scaling by player count/day/ship condition.
- **A complete playable vertical slice first.** Do not build 100 empty days, 12 fake minigames or unused rooms.
- Keep this game separate from **STACK_SHIFT** and **CONTROL_ROOM_BLACKOUT**.

## Open these files in order
1. `00_MASTER_GOAL_EN.md` — copy into the lead development AI.
2. `01_DESIGN/01_GAME_DESIGN_BIBLE.md` — identity, loop, player experience, design pillars.
3. `01_DESIGN/02_LOBBY_AND_SHIP_MAP.md` — lobby, geometry, circulation and room-specific content.
4. `01_DESIGN/03_100_DAYS_AND_ENDLESS.md` — day phases, major milestones, day-100 choice.
5. `01_DESIGN/04_DIFFICULTY_AND_COOP.md` — Easy/Standard/Hard and 2–6 players.
6. `02_SYSTEMS/*` — systems, events, resources, minigames, persistence and UI.
7. `03_AI_TASKS/*` — assignments for multiple AI assistants; no agent is required to be simultaneously available.
8. `05_TECH/*` — source-of-truth, Rojo and integration contracts.
9. `06_PRODUCTION/*` — milestones, backlog and acceptance tests.
10. `04_REFERENCES/REFERENCE_BOARD.html` — links to human-made game/reference visuals, online viewing required.

## Package directory
```
Stay_in_the_Spaceship_for_100_Days_English_Package/
├── README_START_HERE.md
├── 00_MASTER_GOAL_EN.md
├── 01_DESIGN/         Game vision, lobby/ship, 100 days, difficulty
├── 02_SYSTEMS/        Ship mechanics, minigames, resources, threats, UI, progression
├── 03_AI_TASKS/       Agent work ownership, separate English prompts, handoffs
├── 04_REFERENCES/     HTML reference gallery, credits, copyright rules
├── 05_TECH/           Rojo architecture, interfaces and example configuration
└── 06_PRODUCTION/     Milestone plan, task board CSV, QA and scenarios
```

## How to use
**AI Studio / Qoder / Codex:** attach this ZIP or unzip and open the top-level folder in a local-capable environment. Send `00_MASTER_GOAL_EN.md` first. The AI must inspect files and implement a phased playable game. In cloud-only tools, a Windows path is not access; upload the folder or give repository access.

**Multiple agents:** the lead AI defines contracts, initializes one repo and delegates optional parallel tasks using Git branches/worktrees. No assistant should claim direct communication, completion or tests without real access/evidence. Integration always occurs in the main project under lead ownership.

**Reference policy:** linked screenshots from existing games are for concept study. They are *not licensed for redistribution or direct reuse*. The Kenney links are human-created CC0 assets and may be used within their license. No AI artwork is included.

**Important:** Tunable day durations, balance numbers and room sizes are **starting targets**, not demonstrated playtest results. They must be reviewed in Roblox Studio.
