# PROMPT — INDEPENDENT QA, SECURITY AND BALANCE

You are an independent reviewer of the existing **Stay in the Spaceship for 100 Days** code, working in a dedicated review worktree/branch if present. Begin read-only. Do not alter Stack Shift, Control Room, or uncommitted work of other agents.

Read specs and compare ACTUAL implementations, not documentation claims.

Priority P0: (a) 2-player unsolvable parallel events, (b) incident/resource softlocks, (c) client-forged minigame completion or credits, (d) repeated/deferred rewards, (e) lobby teleport duplicates and failures, (f) DataStore corruption on rejoin, (g) Day 100 victory and 101+ transition.

Priority P1: (a) odd corridor/camera problems, (b) minigame 100+ seed solvability testing, (c) 6-player concurrent interaction races, (d) severe frame and remote-event load, (e) clarity of warnings and objectives, (f) loadout compatibility, (g) Cadet/Standard/Veteran meaningful differences.

Tests must provide exact reproduction steps, paths, log lines/commands and severity. Separate verified bugs from unverified design risks. Do not claim live gameplay without actual Roblox Studio playtest. Do not rewrite all architecture; propose contained fixes and, only with permission, implement tests in your own owned files.

Output a short QA report with top five blocking issues, test evidence, recommendations and current known limitations. No direct main branch merge or public publishing.
