# DIFFICULTY PRESETS AND 2–6 PLAYER CO-OP

## Difficulty selected in lobby
**Cadet — relaxed learning:** lower incident frequency and system drain, forgiving diagnostics, more starting resources, longer repair grace windows. Same core content and progress achievements with distinct Cadet badge. Best first run.

**Standard — intended default:** balanced resources and incident budgets, varied tasks, occasional overlapping crises, satisfying preparation. Day 100 is challenging but fair.

**Veteran — coordinated survival:** more complex puzzle configurations, tighter resource margins, stronger linked incidents, greater importance of tools and prioritization. No arbitrary instant death. Veteran adds cosmetic/achievement prestige, not mandatory progression gate.

## Initial adjustable parameters (not empirically balanced)
| Setting | Cadet | Standard | Veteran |
|---|---:|---:|---:|
| Base incident budget per cycle | 0.70x | 1.00x | 1.25x |
| Starting spare parts | 1.35x | 1.00x | 0.90x |
| Passive system wear | 0.70x | 1.00x | 1.15x |
| Task complexity tier shift | -1 capped | normal | +1 capped |
| Emergency grace window | 1.35x | 1.00x | 0.85x |
| Repair reward | 1.00x | 1.10x | 1.20x |
| Cap on concurrent critical incidents | 1 | 2* | 2* |

`*` Concurrency is further capped by player count, room accessibility and current conditions, never simply by preset. A larger team may have more simultaneous noncritical tasks. Bonus rewards should not exceed anti-abuse limits.

## Team-size adjustments
- **2 players:** no more than one required simultaneous critical intervention; second player may provide tools, guidance or sequential station operation. Resources sized for realistic task completion.
- **3 players:** one main incident plus independent optional prep task; some two-person relay tasks.
- **4 players:** two repair streams occasionally; coordinated comms/maintenance tasks.
- **5–6 players:** higher task throughput, larger events or optional side contracts; NEVER six identical simultaneous button tasks. Spawn points, stations and corridor widths must physically accommodate 6.
- All jobs are accessible to everyone. Optional **role loadouts** add information or mild efficiency, not exclusive permissions; 2-player runs must not lose access to required panels.

## Co-op assignments by preferred role
- **Navigator:** bridge, sector choice, scanner and trajectory. Can do repairs.
- **Engineer:** reactor, power, cooling, machinery. Can gather salvage.
- **Technician:** diagnostics, tool inventory, fabricator. Can navigate.
- **Life-Support Specialist:** atmosphere, medical reserves, hull repair. Can run EVA.
- **Salvager:** airlock, cargo, debris and drone retrieval. Can operate panels.
- **Coordinator:** pings, emergency priority, ship-wide status. This is an informal function, not a six-person requirement.

## Good cooperation example
A power bus fails, reducing oxygen production. The player by Bridge sees which sector can be powered down; a player at Power panel selects a safe reroute; another at Life Support swaps a filter. In a 2-person run, the navigator can perform panel step first, then move to the filter. In a 6-person run, the others can prep spare parts and scan an optional salvage opportunity. Every contribution is credited without splitting loot destructively.

## Difficulty fairness invariants
1. Required concurrent human actors <= available players.
2. All required consoles and parts accessible during the event.
3. If supply is insufficient, supply recovery action exists before catastrophic countdown expires.
4. Critical event cannot have an impossible procedural puzzle.
5. Failure states and time budgets derive from visible, teachable system rules.
6. Veteran should demand better planning, **not** instantaneous reactions or low ping.
7. Server verifies difficulty and rewards; client cannot request easier setting mid-run.

## Accessibility and preference settings
UI contrast, subtitle toggle, motion reduction, colorblind-safe labels plus colors, camera shake off, volume sliders where supported. High contrast warning icons independent of hue. No voice-chat dependence.
