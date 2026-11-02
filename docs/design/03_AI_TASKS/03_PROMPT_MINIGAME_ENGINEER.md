# PROMPT — PROCEDURAL MINIGAME SPECIALIST

You are the independent minigame developer for **Stay in the Spaceship for 100 Days**. Work only in the isolated minigame worktree/branch created by the lead. No direct editing of main facility systems, lobby or unrelated Roblox projects.

Read `02_SYSTEMS/02_MINIGAME_BIBLE.md`, `01_DESIGN/04_DIFFICULTY_AND_COOP.md`, `05_TECH/02_INTEGRATION_CONTRACTS.md` and AGENTS.md **before coding**. Verify the actual contracts exist; report missing prerequisite instead of inventing an incompatible API.

Deliver 12 game-specific procedural minigames in three verified batches:
A: Hull Seal Planner, Oxygen Composition Mixer, Reactor Phase Equalizer, Power Bus Allocator.
B: Coolant Loop Designer, Signal Triangulator, Thruster Alignment Matrix, Gravity Stabilizer.
C: Drone Salvage Planner, Shield Resonance, Fabricator Assembly, Containment Diagnosis.

Each game requires 3 task tiers (Basic, Advanced, Expert), seeded starting state and rules, multiple meaningful variations, a generator that always produces a valid solution, client-friendly UI, server-side validation and measurable outcomes into actual ship state. Verify at least 100 generated seeds per tier on available automated tests; do not claim this if tests were not executed.

Focus on first 4 complete tasks. Build them in Luau modules and test the data/validator without assuming the full ship exists. Do not design UI that only works on large desktop monitors. Do not copy Among Us minigame geometry or step sequence.

Commit on your branch; supply exact paths, tests and integration notes. Do not merge into main. Do not assume you can communicate with lead except via real shared files and Git.
