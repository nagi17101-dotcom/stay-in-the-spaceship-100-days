# TASK BOARD
Evidence = Studio playtest unless noted. "Single-player" = Studio solo override; multiplayer not yet tested.

| ID | Task | Status | Evidence |
|---|---|---|---|
| M1-01 | Config / types / network registry | DONE | loads in play |
| M1-02 | Ship simulation (10 systems, dependencies, hysteresis) | DONE | cascade Cooling→Drive→Bridge red observed |
| M1-03 | Day cycle Prepare/Active/Transition | DONE | console phase log |
| M1-04 | HUD (day, meters, objective, alerts, inventory, emergency) | DONE | client read-back |
| M1-05 | Ship blockout: Hub, Bridge, Life Support, Workshop, Reactor | DONE | screenshots |
| M1-06 | State-driven room lights + signs | DONE | amber/red verified |
| M1-07 | Minigame PowerBus (M04) Basic/Advanced | DONE | 300 seeds solvable; wrong rejected, valid accepted |
| M1-08 | Minigame CoolantLoop (M05) Basic/Advanced | DONE | 300 seeds solvable; wrong rejected, valid accepted |
| M1-09 | TaskService (server validation, exactly-once repair) | DONE | end-to-end via prompts |
| M1-10 | Salvage points (finite, refill per day) | DONE | prompt test, charges/disable |
| M1-11 | Quick actions: Hull Patch, Emergency O2 | DONE | Hull via prompt; O2 via server path (prompt sim flaky) |
| M1-12 | Day Complete summary + crew/XP rewards | DONE | overlay read-back |
| M1-13 | Emergency window → Ship Lost → restart | DONE | full loss + restart observed |
| M1-14 | Lobby terminal + party (create/join/leave/ready/difficulty/launch countdown, 2–6 cap) | DONE (solo) | create→Cadet→ready→launch→aboard; loss→return to lobby, party kept, ready reset |
| M1-16 | Crew-only interactions, disconnect warning + rejoin aboard, 60s abandon → lobby | CODE DONE | needs multi-client test |
| M1-17 | Character placement with verify/retry (in-place teleport recovery) | DONE (solo) | placed in ship and back in lobby |
| M1-18 | Cross-place lobby → reserved voyage server (TeleportService) | NOT STARTED | needs published place IDs |
| M1-15 | 2-player Studio test (Clients and Servers) | DONE (owner) | owner reported: session locks + DataStore sync OK with 2 clients. 6-player test still open |
| M3-01 | Minigame HullSeal (M01) Basic/Advanced + station (Hub) | DONE | 300 seeds/tier solvable; empty rejected (LeakOpen), solver-from-public-data accepted, Hull +35 in play |
| M3-02 | Minigame OxygenMixer (M02) Basic/Advanced (wave source) + station (Life Support) | DONE | 300 seeds/tier solvable, 1–15 of 375 settings valid; max-everything rejected (PowerOver), public-data solution accepted, Oxygen +30 in play |
| M3-06 | Minigame ReactorPhase (M03) Basic/Advanced (coupled coils) + station (Reactor) + Director CoilDrift, HotCore step 2 alt path | DONE | 300 seeds/tier: solvable, start never synced, 1–6 of 1728 tunings valid; in play: OutOfPhase + Overheat rejected, valid accepted, CoilDrift resolved via ReactorPhase |
| M3-07 | Minigame SignalTriangulator (M06) Basic/Advanced (noisy ±1) + Bridge station; Director GhostEcho + sector weighting (Echo Fields ×3) | DONE | 300 seeds/tier: exactly one valid cell each; in play: wrong cell rejected (ArcMismatch), correct accepted, GhostEcho resolved |
| M3-08 | Minigame ThrusterMatrix (M07) Basic/Advanced (offline nozzle, tol 0) + Bridge station; Director ThrusterDrift (Outer Freight Belt ×2) | DONE | 300 seeds/tier: solvable, idle never valid, corridor always on plot (fixed after test found (-9,-4) off-plot); in play: OffCorridor + Vibration rejected, valid accepted, ThrusterDrift resolved |
| M3-03 | Crisis Director v1: 5 templates, day budget, feasibility, bounded escalation, recovery window | DONE (solo) | feasibility matrix (day/health/no-path/Veteran/critical cap); natural spawn BreakerTrip → resolved via PowerBus; forced MicroBreach escalated 1/2 → resolved via Hull Patch kit |
| M3-05 | Director: 2/6-player tests, more templates (Shield, Comms, Navigation once their minigames exist) | NOT STARTED | — |
| M3-04 | Persistent profiles: schema v1 + migration, UpdateAsync with retries/budget, session lock (stale 5 min), idempotent Grant, autosave 120s, save+release on leave/BindToClose, lobby profile panel | DONE | 13/13 unit tests (tests/ProfileStore.spec.luau); in play: 10 day grants → LV2 + Survive10_Standard; duplicate grant id rejected. Real DataStore (Studio API on): session 1 +40 → stored xp 40, lock released on close; session 2 reload xp 40, same grant rejected after reload, lock held while playing; close → xp 55, lock released |
| M4-01 | Day 100 finale: 3 stages (SignalTriangulator → ReactorPhase+PowerBus → Beacon Fabricator + hold), finale restock, task threshold bypass | DONE (solo) | stage 1 via real Advanced task with healthy Comms; craft via real prompt (2 Filament + 1 Scrap debited); hold counter 0→19 live on HUD |
| M4-02 | Crew vote Extract/Continue (tie/timeout → Extract), +500 XP + Day-100 achievement for all aboard | DONE (solo) | timeout → Extract; Continue → Day 101; Extract → VOYAGE COMPLETE → lobby after 15s |
| M4-03 | Endless Voyage (Day 101+, HUD without /100, milestones 125/150/200) | DONE (solo) | Day 101 · ENDLESS VOYAGE shown; endless loss → Ship Lost → lobby |
| M4-04 | Minigame GravityStabilizer (M08) Basic/Advanced + Workshop station; Director GravityWobble (Dead Relay Zone ×2) | DONE | 300 seeds/tier solvable, idle never solves, partial+damping solves 19%/6% (real trade-off); in play: idle rejected (Unstable), 2 shifts + damping 2 accepted, GravityWobble resolved |
| M4-05 | Minigame DroneSalvage (M09) Basic/Advanced (pulsing hazards, priority target) + Drone Bay; server-delayed loot, 1 launch/day; Director ReceiverJam blocks launches; TaskService CanOpen/AlwaysAvailable/OnSuccess hooks | DONE | 300 seeds/tier solvable, out-and-back rejected; in play: NotReturned rejected, valid route → +2 Scrap after 8s, 2nd launch same day refused, launch blocked during ReceiverJam |
| M4-06 | Minigame ShieldResonance (M10) Basic/Advanced (12 bands, Kinetic/Ionic/Hybrid/Capacitor) at Bridge `BR-ShieldResonance`; shields absorb incident hull damage ×(1−0.5·shield%) + passive hull wear below ShieldSafe=50; Bridge lights follow Shields; Director DebrisBarrage + IonSquall (merged with parallel session, Junction station & ResonanceMismatch removed) | DONE | 300 seeds/tier solvable; play: full shields hull −7.5 vs −15 ("Shields absorbed 50%"), shields 20% → passive wear, Bridge Critical/Hub Nominal, IonSquall rejected at 20% shields (WouldCripple), spawned at full; empty rejected, valid accepted |
| M4-07 | Minigames M11–M12 (FabricatorAssembly, ContainmentDiagnosis) | NOT STARTED | — |
