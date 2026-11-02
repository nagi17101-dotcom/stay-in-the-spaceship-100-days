# QA, ACCEPTANCE AND TEST MATRIX

## Evidence categories
- **Static**: source inspection, lint, schema validation, Rojo build; no claim about visual gameplay.
- **Automated**: executable tests with logged counts, pass/fail and seed; proves tested logic only.
- **Studio**: actual Roblox Studio client/server playtest for 3D visual and interaction behavior.
- **Published private test**: real multi-place teleport and live DataStore/network behavior when permitted and enabled.

## Hard acceptance criteria
### Lobby / matchmaking
- A 2-person party can launch, party size never >6, a 1-person public party cannot launch (except dev simulation mode explicitly labeled).
- Duplicate start button requests cannot create two runs.
- Party leader leave transfers leadership; invalid ready state clears.
- Difficulty selected before launch is consistent throughout voyage and UI.
- Teleport failure returns player to valid lobby UI, does not charge money or lose profile.
- Six unique players can use a room/door without blocking each other.

### Spaceship visual
- Fully 3D interior and external black starfield; no daytime sun or baseplate visible through windows.
- Primary rooms accessible with directional signs; intended camera doesn't clip constantly.
- A visual alert actually corresponds to system state; no random placeholder geometry.
- Medium layout has reasonable 20–35 second cross-ship navigation target.

### Day and difficulty
- Day state increments exactly once per completed cycle on server; no client day modification.
- Cadet, Standard, Veteran settings show different incident budgets and start resources.
- Two-player and six-player incidents both resolvable; no permanent role locks.
- 100th day opens three-stage finale and confirmed win achievement.
- Day 100 Extract saves account record and shows ending; Continue starts 101 and preserves in-run upgrades.
- Endless retains day number, avoids runaway infinite incident concurrency.

### Core systems / incidents
- Power outage can diminish life support, but reserve/power reroute restore functionality.
- Hull breach has visible oxygen loss; fixing it halts drain and restores room safety.
- Reactor and cooling faults propagate with bounded state transitions and explainable UI.
- Director rejects impossible incidents given resource/actor/room constraints.
- Room locked for incident doesn't isolate the only required tool.

### Minigames
- All 12 tasks genuinely distinct, but 4+4+4 batches accepted separately.
- At least 100 generated seeds *per implemented tier per task* tested where possible; compare invalid action and success.
- A successful minigame changes the corresponding real subsystem, and materials consume once.
- Fake client completion, replayed task ID, out-of-range station requests fail.
- Mobile inputs support tasks without tiny precision-only hitboxes.

### Resource/persistence
- Crafting with insufficient stock fails without negative counts.
- Two simultaneous players cannot duplicate the same component.
- Salvage rewards are finite per event; no click-spam farming.
- Account XP, cosmetics and Day-100 achievement survive tested rejoin.
- Run data snapshot never overwrites permanent purchases.
- Receipt processing is idempotent before any real monetization.

### Performance / accessibility
- Budget test with six players, large warning UI and debris events; profile server CPU/network, FPS and memory.
- Reduced-motion and captions work, alerts include non-color cues.
- Internationalization uses consistent English source strings and fallback; untranslated keys never render raw.

## Risk ledger
P0: unsolvable 2-player incidents, duplicate rewards, client-forged repairs, profile loss, wrong Studio/other project modifications.
P1: loop corruption on Day 100, impossible puzzle seed, broken teleport flow, starvation softlock, unplayable mobile HUD.
P2: minor decoration, excessive empty space, sound balancing, small navigational friction.

## Test log template
```text
TEST_ID: T-MG01-001
Date / Commit:
Environment: static | automated | Studio | private published
Players: 2 | 3 | 4 | 6
Difficulty: Cadet | Standard | Veteran
Day / seed:
Steps:
Expected:
Observed:
Outcome: PASS | FAIL | BLOCKED
Evidence: logs, screenshots or recordings when available
Owner / next fix:
```

## Review gates
Every claim `DONE` must include test IDs, commit and build or Studio evidence. A task without external tool access must be `BLOCKED` or `UNVERIFIED`, never quietly complete. No automated test can guarantee a fun map; human playtests are required.
