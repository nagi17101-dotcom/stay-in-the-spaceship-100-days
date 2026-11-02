# MULTI-AGENT DEVELOPMENT COORDINATION

## Goal
This design package can be used with **one AI or several specialized AIs**. It does NOT require a specific model or connected application. Unavailable free-tier models must not block production. Never pretend one AI can read another AI's chat automatically; handoffs are real files/commits.

## Recommended agent slots
| Slot | Role | Owned source areas | Deliverables | When to start |
|---|---|---|---|---|
| LEAD | Architecture & Integration (e.g. Qoder/Codex) | core server, Rojo project, cross-system interfaces, main branch | runnable vertical slice, merge/test, ship simulation, lobby | immediately |
| PUZZLES | Procedural Gameplay (e.g. Antigravity/AI Studio) | `src/minigames/**`, designated UI minigame modules | 4+4+4 seeded, validated minigames with tests | after contracts initial commit |
| WORLD | 3D Level & UX (any capable AI) | `src/world/**`, world builder & art config, designated UI layout | compact lobby, ship map, signs, lighting; asset register | after world/room contracts |
| QA | Security, Testing, Balance (Codex/other) | `tests/**`, `docs/QA_*.md`, no source modification at first | risks, verified bugs, test improvements, balance report | after playable slice |

A single AI may fill all roles sequentially if no other models are available. Role labels are responsibilities, not claims about model access.

## Ownership rules
- **One real repo**: `STAY_IN_THE_SPACESHIP_100_DAYS`; do not clone Stack Shift or Control Room into it.
- LEAD creates `AGENTS.md`, `INTEGRATION_CONTRACT.md`, `TASK_BOARD.md`, first Git commit and isolated branches/worktrees if truly needed.
- PUZZLES never edits main ship simulation modules or lobby place configuration.
- WORLD never rewrites authoritative game systems. Geometry only; interactions are wired to agreed server APIs.
- QA starts read-only; tests and report may be committed on its branch only with LEAD approval; no unilateral main merge.
- No shared live Roblox Studio session for parallel worktrees. Only LEAD's main branch performs final Studio sync; protect the correct `PlaceId` and Rojo server identity.
- Every task has `owner`, `dependency`, `changed paths`, `definition of done`, `tests`, `commit hash`, `integration status` and `risks`.

## Integration sequence
1. LEAD establishes data contracts including system status, minigame lifecycle, resource transactions, event dispatch, lobby party creation and day-state progress.
2. PUZZLES develops Batch A independently from real interfaces, with local unit tests and no fabricated server.
3. WORLD constructs the small lobby and ship; exports Rojo-managed geometry or a declared .rbxlx model with clear source-of-truth decisions. Exact handoff path must exist.
4. LEAD integrates and verifies. If QA available, audit before Batch B.
5. Agents repeat until M5; no need for a high-limit third agent to ship a first version.

## Human-in-the-loop boundaries
AIs can edit project files when authorized by their tool and workspace. They cannot automatically install Roblox plugins, upload paid assets, publish a game or physically interact with Studio without corresponding access. If an action needs a user step, report it once with exact instructions. Never claim completion without a screenshot, test log, source file or actual tool result.

## Git worktree example (run ONLY after repository initialized)
```text
C:\RobloxProjects\STAY_IN_THE_SPACESHIP_100_DAYS         [main / LEAD]
C:\RobloxProjects\SPACESHIP_MINIGAMES                    [feature/minigames / PUZZLES]
C:\RobloxProjects\SPACESHIP_WORLD                        [feature/world / WORLD]
C:\RobloxProjects\SPACESHIP_QA                           [review/qa / QA]
```
Do not create these as unrelated blank folders. Do not create worktrees if no other agent is active; unnecessary branches add overhead.

## Daily reporting format
`TASK ID | Owner | Started from commit | Changed paths | Tested commands | Studio test? | Result | Review status | Handoff commit`.
Use a single short status update with actual evidence. A report about plans is not evidence of gameplay.
