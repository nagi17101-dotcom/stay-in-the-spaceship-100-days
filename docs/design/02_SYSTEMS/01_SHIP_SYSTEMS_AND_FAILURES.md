# SHIP SYSTEMS — INTERDEPENDENT BUT UNDERSTANDABLE

## Authoritative state model
The server owns each system's `health [0,100]`, `mode`, `load`, `production`, `temporaryFaults`, `repairProgress`, `lastChange`, and known dependencies. Clients only render permitted state and send validated interaction intents. Keep a single config table and event bus; avoid a single gigantic server script.

### Primary systems / concrete gameplay
| System | Controls | Affected by | Player actions | Visible consequence |
|---|---|---|---|---|
| Hull | pressurization, leak rate | impacts, corrosion | inspect crack, weld/seal patch, close bulkhead | local venting, emergency doors |
| Oxygen/life support | O2 stock, filtering rate | power, hull leaks, bad filter | replace scrubber, re-route oxygen, isolate room | breathing warnings, room oxygen indicators |
| Reactor | power capacity, instability, heat | coolant, module wear | stabilize coils, emergency throttle, start backup | light flicker, console alarm, power loss |
| Power buses | distribution to loads | reactor, short circuits | switch breakers, allocate power priorities | dim corridors, disabled stations |
| Cooling | heat rejection, coolant capacity | pumps, filter clogging | route coolant, purge line, synchronize pumps | increasing heat and engine throttling |
| Engines/drive | jump readiness, fuel efficiency | power, cooling | align coils, repair thruster, conserve fuel | travel progress slows; route options close |
| Navigation | route completion, confidence | scanner, comms | triangulate, calibrate instruments | sector choice and day-100 data |
| Comms/scanner | hazard forecast & rescue beacon | power, static | decode signal, tune receiver | early-warning and salvage opportunities |
| Shields | impact resistance & charge | power, frequency mismatch | tune shield band, distribute capacitors | increased meteor/ion damage |
| Cargo/fabricator | usable parts and output | power, materials | salvage, recycle, craft | repair alternatives and capacity |
| Crew support | personal injury and rest | oxygen, radiation, impact | use med station and suit | temporary movement/task penalties, no gore |

## Design relationships
- Reactor low -> power bus cannot satisfy all loads -> life support and fabricator may be partially disabled. Redirect power from noncritical modules to support oxygen; crew sees consequence on HUD.
- Cooling pump failure -> heat rises in reactor -> load limits -> engine cannot complete next jump. Repair pump OR throttle reactor + run reserve battery to buy time.
- Hull breach -> oxygen drain -> auto-sealing bulkhead blocks shortcut, not the only path; repair from accessible side, restore pressurization.
- Shield frequency mismatch -> meteor impact chance increases in a particular sector; scanner predicts broad risk category, not exact outcome.
- Scanner breakdown -> salvage is harder to find, but emergency baseline parts remain obtainable from recycling.
- Cargo recycler loss -> crafting reduced; players can use spare components or restore recycler with low-cost manual task.

## Clear catastrophe rules
A catastrophic fail must be foreshadowed and reversible before threshold. Do not drain all O2 in seconds without counterplay. Set a **critical fail condition** (e.g., hull 0 plus no reserve restoration before rescue window) rather than instant loss at a single 0 stat. On Cadet increase rescue windows. Survivable emergency suit reserves protect temporary life support failure; limited but renewable if a comeback route exists.

## Health repair vs task states
Not every fault is repaired by one generic click: some require diagnosis, isolation, resource consumption, interactive minigame, final confirmation. Quick patches consume fewer steps but yield shorter protection, permanent fixes consume a crafted module and validated puzzle. Give each task a progress state machine: `AVAILABLE -> RESERVED -> ACTIVE -> VALIDATING -> RESOLVED/FAILED/EXPIRED` with safe cleanup if player leaves.

## Hard engineering constraints
- Cap server simulation update frequency; update dependencies in batches rather than per-frame loops.
- No event spam or oscillating failure cascades. Apply cooldown, hysteresis for threshold transitions, and dependency cycle tests.
- Keep simulation deterministic from a seed/config for offline incident reproduction.
- Failed interaction consumes exactly defined resources or none; no double-debit race.
- Recovery from disconnect and latencies >150ms must be tolerated.

## Example day 26
Scanner reports electromagnetic squall. Crew can spend 1 power module on shields or accept extra risk while collecting debris. An ion surge trips a peripheral bus, slowing life-support fan. Operator reroutes power; technician solves a seeded breaker task, engineer restarts coolant. Debris retrieval is optional. The ship survives the day with more spare parts if proactive.
