# GAME DESIGN BIBLE — IDENTITY, LOOP, PLAYER EXPERIENCE

## Elevator pitch
Six friends or a duo crew a compact explorer spacecraft on a failing voyage. Every "day" is a ship-board operational cycle with new pressures. You choose which systems to stabilize, which salvage opportunities to take, and which resources to reserve. Small, physical repair interactions feed back into real ship state. Survive Day 100, complete the return-route beacon, and decide as a group whether to end on a win or continue into a harsher Endless Voyage.

## Original fiction / positioning
Ship callsign: **WAYFARER-07** (working title, changeable). The vessel has lost its main navigational route in a remote field of debris. A transit computer requests 100 successive navigation cycles to reconstruct a safe return path. Every ten cycles the crew reaches a new sector with different risks and salvage. The ship remains in outer space at all times; "days" are only operational labels in logs and HUD.

This is **not** social deduction and contains **no impostor** mechanic. It is also not Control Room: Blackout transplanted into space: the unique selling points are (1) a moving long-range voyage, (2) clear end-of-voyage objective with opt-in Endless, (3) ship external salvage and optional EVA, (4) sector-specific decisions, (5) cooperative repair tasks in an intimately sized ship.

## Four pillars
1. **A ship that feels alive:** changes in life support, gravity, power and navigation are directly visible/audible in the places they occur.
2. **Interesting crisis decisions:** players cannot do everything immediately. They choose between quick patches and efficient long-term fixes.
3. **Varied task interactions:** every minigame has consistent rules, varied initial conditions and meaningful real-world outcomes.
4. **One more day:** clear countdowns and milestone anticipation; awards for performance, not merely idle time.

## Exact core loop
- **Embark:** 2–6 crew join lobby, select challenge, ready, enter ship.
- **Prepare:** open ship status, pull tools, choose optional sector route/contract, manufacture one priority component.
- **Operate:** maintain reactor/oxygen/engines, perform short preventive minigames, scan exterior and recover debris.
- **Crisis:** the Director selects causes; one repair leads to new meaningful decisions, not random permanent failure.
- **Recover:** stabilize, use reserve battery, route power, repair breached hull, secure cargo.
- **Advance:** earn salvage, personal XP, crew reputation; receive next route milestone and meaningful upgrade options.
- **Decide:** after 100, successful completion presents Extract vs Endless, by majority crew vote with clear explanation; tie defaults to Extract for the celebratory ending, with saved achievement.

## Sessions and retention
Target the first satisfying success in 3–5 minutes (learn movement, repair one system, see ship respond). The full 100-day run is **long by design**, therefore implement pause/resume-capable run recovery (with expiration and safe snapshot validation), and optional in-game travel acceleration that *does not remove required crises or rewards*. Balance approximate completion around 100–160 minutes for coordinated teams; test rather than promise. Crew departure or disconnect must not permanently softlock an active task. Players should be able to start a fresh run or resume a valid ship snapshot.

## Player-facing progression
- **Run:** repaired modules, modules installed, ship resource stash, last milestone, crew achievements, ship loadout; lost on true run failure unless a tested checkpoint/resume rule applies.
- **Account:** cosmetic suits, titles, XP, unlocked tool variants (modest), prestige markers, personal stats, highest day, Day-100 clear, endless record. No purchase is lost on run loss.
- **Achievements:** first leak patched, two-person flawless day, no-power recovery, day-10/25/50/75/100 survivals, rescue-vote, day-150/200 endless milestones.

## Rules that protect the experience
- Show objective within five seconds of spawn; reach first useful console within a few steps.
- New players should locate bridge, life support and workshop within 20–30 seconds after learning the layout.
- Give players actionable causes, not ambiguous flashing alarms.
- No hard-coded minigame pass on client request; always server-validate.
- Failure should be explainable: accumulated damage, missed maintenance or risky choices.
- Only one critical alarm audio mix at once; less important notifications queue below it.
- Repeated day loops need sector modifiers and events that change strategies.

## What this game explicitly is not
Not 2D, not a verbatim Among Us recreation, not detailed full-scale spaceflight physics, not PvP, not a random pile of models, not a permanent dark maze, not a pay-to-survive game, not a passive AFK day counter.
