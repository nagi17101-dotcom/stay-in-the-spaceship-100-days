# CRISIS DIRECTOR — INCIDENTS, THREATS, SCALING, FAIRNESS

## Design principles
Incidents must be **causal, varied and solvable**. They are generated from actual ship conditions, sector hazards and the day number, not a roulette of unrelated alarms. An incident is an opportunity for teamwork, not an excuse to make the game impossible.

## Inputs and outputs
Inputs: `day`, `sector`, `difficultyPreset`, `playerCount`, `shipVitals`, `reserveResources`, `activeIncidents`, `roomAccess`, `toolAvailability`, `lastIncidents`, `graceTime`, `runModifiers`, `seed`.
Outputs: a candidate incident with `prerequisites`, `rootCause`, `symptoms`, `repairOptions`, `materials`, `taskInstances`, `timeWindow`, `consequences`, `recoveryPaths`, `cost`, `cooldown`, `score`. Only schedule if guaranteed feasible.

## Example incident library (at least 20 variations, not necessarily 20 bespoke systems)
1. Micrometeor nick -> minor hull leak.
2. Debris barrage -> shields stressed, optional protection choice.
3. Solar/ion interference -> scanner noise and signal misread.
4. Coolant valve jam -> reactor temperature rises.
5. Reactor coil phase drift -> output instability.
6. Life support filter clog -> reduced oxygen generation.
7. Oxygen distributor misconfiguration -> wrong compartment flow.
8. Power bus insulation fault -> peripheral load cutoff.
9. Battery swelling warning -> charge capped until serviced.
10. Thruster alignment drift -> reduced transit speed.
11. Fuel cell contamination -> drive efficiency falls.
12. Cargo receiver jam -> drone salvage pickup blocked.
13. Workshop printer defect -> fabrication slows.
14. Navigation beacon ghost echo -> needs triangulation.
15. Shield resonance mismatch -> more ion damage.
16. Gravity stabilizer misalignment -> cargo handling penalty.
17. Comms antenna collision -> external repair opportunity.
18. Crew suit puncture risk -> EVA choice and repair.
19. Temporary magnetic interference -> sensor outlier; clues available.
20. Door pressure seal failure -> closes a shortcut but never the only path to required consoles.
21. Two-system chain -> reactor low -> cooling throttled -> engine locks until crew reroutes.
22. Sector jackpot -> optional abundant salvage but increased radiation risk.

## Difficulty budget example
`budget = baseDayBudget(day) * presetFactor * teamFactor(players) * healthStressModifier` with fixed maximum. Each candidate consumes budget. Critical incidents count toward `criticalConcurrencyCap`. Do not use a naive formula that always punishes damaged teams by spawning even more impossible incidents; when integrity low, prefer recovery chance and shorter chains. Avoid frequency spikes at day transitions.

**Two-player invariant:** a mandatory crisis can never require three simultaneous stations. If team size drops mid-crisis, gracefully convert the parallel step to sequential or create a buffer; do not auto-fail.

## Template examples
### E013: Silent Corridor
Prereq: power >= 25%, one alternative hallway accessible. Cause: branch breaker overload. Symptoms: corridor light dim, oxygen fans slow but function. Player choices: use Power Bus minigame to reroute, or consume conductive jumper for fast fix. Time to catastrophe calculated from O2 reserve and >= realistic traversal+task duration. Reward: 1 efficiency point for minimal lost O2. Repair options validate supplies.

### E044: Hot Core
Prereq: coolant pump available, Reactor station reachable, <=1 active critical incident if 2 people. Cause: blocked coolant loop. Symptoms: heat trend rising and vibration sound. Solutions: coolant minigame + improved heat rejection OR safe throttle then craft cartridge. If ignored: power reduction -> slow navigation, then reactor critical event with visible margin. Never instant death.

### E071: Echo Marker
Prereq: comms functioning enough to display scanner. Cause: sector interference. Main objective: triangulate real beacon from false echo, then decide salvage optional reward. Solution is procedural and verifiably distinguishable; failure loses only time/extra reward, not entire ship.

## Director pipeline
1. Score sector candidates by relevance and recency cooldown.
2. Filter out candidates requiring unavailable rooms/tools/parts.
3. Build an explicit resolution dependency graph. Check a reachable, non-Robux completion path.
4. Check simultaneous-player and time feasibility with worst-case reasonable latency/travel.
5. Enqueue short advance notice if appropriate. Use incident-budget rules, avoiding overlapping alarm sounds.
6. Spawn through server, track deterministic ID and states.
7. Resolve based on validated minigame/repair events and update ship systems.
8. Record causes, player participation and sector history. Cool down used templates.

## Stability requirements
- Avoid infinite loops (e.g., low power causes cooling fail, cooling fail low power repeatedly): impose latches/hysteresis, unique causal chain IDs, max chain depth.
- Preserve existing player tasks when a new incident begins; don't spawn a new 90-second mandatory task in a 10-second remaining window with no grace.
- Add a visible `RECOVERY WINDOW` after severe emergencies, unless the team deliberately takes a high-risk optional contract.
- When data invalid, choose no incident rather than untested impossible scenario.
- Tests must assert reachable resolutions from multiple seeds, day bands, 2/6 players, and low-resource conditions.
