# MINIGAME BIBLE — 12 ORIGINAL, SOLVABLE, REPLAYABLE TASKS

All minigames are **new designs**, not copies of Among Us tasks. They must have a small 3D physical station in the ship, a readable 2D **interface only for the interaction screen**, procedurally varied conditions, local feedback, and server-authoritative completion. The **overall game remains fully 3D**. They must be playable without voice chat and without fast-reflex reliance.

## Shared standard
Each task exposes `id`, `generatorVersion`, `seed`, `difficultyTier`, `shipContext`, `requiredMaterials`, `solvable`, `timeBudget`, `rules`, `publicState`, `validate(action, authoritativeState)` and `outcome`. A server may send only the puzzle data necessary for display, never a plain solution. The validator checks ordered actions, rate limits and station proximity. Clients cannot simply send `completed=true`.

**Three minigame tiers:** Basic, Advanced, Expert. Separate from session's Cadet/Standard/Veteran and day band, which influence selection probability. Expert should be conceptually harder, not require a rapid double-click. Generated seed suites must test 100+ cases per tier initially; expand coverage during integration.

## M01 — Hull Seal Planner (Hull / Airlock)
- **Player view:** 3D breach scan with a simple plate-grid panel; a leak has boundary, pressure and weak weld lines.
- **Actions:** select patch plate orientations and placement order, then activate seal and pressure test.
- **Variation:** defect shape, blocked cells, number of plates, stress direction and spare plate materials.
- **Rules:** plates must fully cover leak; reinforcement edges need contact, overheating weld points are forbidden.
- **Advanced:** more plates and a blocked maintenance rail. **Expert:** two reinforcement constraints and material limits.
- **Validation:** set of occupied cells/edge constraints and final pressure; generator verifies at least one solution.
- **Success:** slows/ends O2 loss, raises hull integrity. **Failure:** pressure remains low; no arbitrary permanent damage.

## M02 — Oxygen Composition Mixer (Life Support)
- **Player view:** oxygen recycling control with three gas sources/flow dials, a target healthy breathable band.
- **Actions:** set mixing ratios and filter mode within a power budget.
- **Variation:** source purity, filter wear, target bands, total capacity, available valves.
- **Rules:** combined O2 index and contaminant index must remain inside labeled safe intervals; energy consumption capped.
- **Advanced/Expert:** one source unstable or delayed; use readout history, not timing reflex.
- **Validation:** recompute resultant ratios at server, validate stable interval for N simulated ticks.
- **Success:** restores oxygen rate. **Failure:** filter stress warning; retry permitted after cooldown.

## M03 — Reactor Phase Equalizer (Reactor)
- **Player view:** three power coils represented as dials with phase offsets and temperature output.
- **Actions:** swap coil banks or rotate tuning values; achieve synchronized overall phase under temperature ceiling.
- **Variation:** starting phase, coil couplings, allowable frequencies, heat coefficient.
- **Basic:** independent coils. **Advanced:** coupled dials. **Expert:** coupled with heat/energy constraints.
- **Validation:** evaluator checks resulting phase deltas and heat, not a memorized button order.
- **Success:** reactor stability recovery; partial success can prevent runaway without full bonus.

## M04 — Power Bus Allocator (Electrical)
- **Player view:** miniature network of loads and bus channels with visible capacity, critical priority markers.
- **Actions:** toggle branch assignments and allocate limited amperage without overloading wires.
- **Variation:** generator output, line capacities, essential loads, disabled edges, mission priorities.
- **Basic:** 3 circuits. **Advanced:** 5 circuits and 1 damaged line. **Expert:** multiple valid priority tradeoffs and a reserve battery.
- **Validation:** graph constraints and required life-support loads satisfied.
- **Success:** restored distribution; incorrect output trips an explainable breaker, recoverable.

## M05 — Coolant Loop Designer (Cooling)
- **Player view:** pipe and pump schematic with rotatable junctions and an insulated bypass.
- **Actions:** rotate pipe modules, choose pump speed; connect cold source to reactor and return line.
- **Variation:** pipe connections, pressure drops, blocked segments and target heat load.
- **Expert:** two cooling destinations and pressure bound.
- **Validation:** directed graph reachability, consistent loop, flow budget and pressure bounds.
- **Success:** heat rate decreases; unnecessary overpressure flagged.

## M06 — Signal Triangulator (Comms/Navigation)
- **Player view:** 3 antenna arrays with relative signal delays and a coarse star-sector grid.
- **Actions:** adjust bearing and filter noise, intersect three confidence arcs to find beacon source.
- **Variation:** beacon coordinates, delay noise, source quality, antenna availability.
- **Basic:** clear arcs. **Advanced:** noisy measurement. **Expert:** false echo with a distinguishable second diagnostic.
- **Validation:** computed position within tolerance, evidence used; never require a specific click path.
- **Success:** route fragment, warning improvement or optional salvage marker.

## M07 — Thruster Alignment Matrix (Engine)
- **Player view:** vector diagram for lateral thrusters with a destination corridor.
- **Actions:** choose thruster power vectors under a fuel budget and vibration limit.
- **Variation:** mass, initial angular drift, number of thrusters, disabled nozzle.
- **Expert:** multi-step burn with heat/fuel constraint, but generous timing.
- **Validation:** deterministic trajectory result and safe corridor intersection.
- **Success:** drive efficiency and route progress.

## M08 — Gravity Stabilizer (Service)
- **Player view:** three weighted rings with center-of-mass markers and stabilizer settings.
- **Actions:** rebalance weights and set damping so oscillation falls below threshold.
- **Variation:** mass distribution, available rails, resonance frequency.
- **Expert:** extra coupling and limit on shifts.
- **Validation:** stable resultant simulation, no physical ragdoll requirement.
- **Success:** restores cargo handling and EVA docking reliability.

## M09 — Drone Salvage Planner (Cargo/Airlock)
- **Player view:** debris field on scanner, drone fuel, magnet strength and hazard zones.
- **Actions:** plan waypoints and timing windows with hazard forecast; dispatch/recall drone.
- **Variation:** debris positions, hazards, fuel, cargo priority.
- **Expert:** two useful targets and limited battery; tradeoff rather than impossible perfection.
- **Validation:** server computes path length, hazard intersection and capacity.
- **Success:** actual resources spawn in ship cargo terminal after delay (not client-side granted).

## M10 — Shield Resonance (Defense)
- **Player view:** harmonic slots and incoming meteor/ion spectrum bands.
- **Actions:** assign compatible emitters and reserve capacitors to cover threat ranges.
- **Variation:** emitter bandwidth, disabled slot, threat profile and power budget.
- **Expert:** spectrum overlap and heat. **Validation:** coverage/overlap/power constraints.
- **Success:** shield effectiveness against current sector hazard.

## M11 — Fabricator Assembly (Workshop)
- **Player view:** modular mechanical blueprint with compatible connectors and material list.
- **Actions:** choose components in a valid assembly order and run a stress test.
- **Variation:** component sockets, target function, tolerance, available parts.
- **Expert:** one optional improvement vs repair speed tradeoff.
- **Validation:** dependency DAG and compatibility plus actual materials available.
- **Success:** one crafted part, consumed materials exactly once.

## M12 — Containment Diagnosis (Medical/Service)
- **Player view:** sensor logs from three compartments, leak/malfunction symptom chart and isolation controls.
- **Actions:** inspect evidence, infer root subsystem, isolate only affected compartment and select repair action.
- **Variation:** root cause, true/false-but-explainable readings, accessible sensor set, two possible interventions.
- **Expert:** causal chain with misleading symptom; at least two decisive clues always exist.
- **Validation:** cause classification + safe isolation constraints; no hidden random guess.
- **Success:** halts cascade, unlocks real repair station.

## Technical standard per task
- Client screen supports PC keyboard/mouse and touch with hit area >= practical device sizes; no precision drag on 6-inch phones.
- 2–6 players may operate parallel stations without corrupting each other; one task reservation token per minigame instance, robust timeout and release on departure.
- Server validates materials and station proximity before offering; rejects out-of-date puzzle instances.
- Tests: at least 100 seeds per tier, including boundary seeds, all outcomes, replay rejection and disconnect.
- Designed task can take 15–35 seconds Basic, 30–50 seconds Advanced, 40–75 seconds Expert as tuning targets, not rigid timer cutoffs.
- Record actual validation and integration as separate milestones.

## Batch plan
Batch A: M01 Hull Seal, M02 Oxygen Mixer, M03 Reactor Equalizer, M04 Power Bus.
Batch B: M05 Coolant, M06 Signal, M07 Thruster, M08 Gravity.
Batch C: M09 Drone Salvage, M10 Shield, M11 Fabricator, M12 Containment.

**Never ship twelve superficial UIs. Four complete, varied and validated tasks are better than twelve static mockups.**
