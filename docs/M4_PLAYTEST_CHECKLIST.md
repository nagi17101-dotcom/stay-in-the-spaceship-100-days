# M4 gate — multiplayer playtest checklist (owner-run)

Studio: **Test → Clients and Servers → 6 players → Start**. Record PASS/FAIL + notes per line.

## A. Lobby & launch (6 players)
1. All 6 spawn in the lobby; one creates a crew, others join; manifest shows 6.
2. All ready → launch countdown → all 6 appear aboard; nobody stuck in lobby.
3. 6 characters fit through every door/corridor (Bridge, Reactor, Life Support, Workshop, Junction).

## B. Parallel tasks (no cross-talk)
4. Two players open two different consoles at the same time → each gets their own puzzle; solving one does not close the other.
5. Two players try the SAME console → second gets "Another crew member is using this station."
6. Quick action + salvage spam from 2 players → materials never go negative, loot granted once per press.

## C. Incidents & HUD
7. An incident alert shows for all 6; objective line identical on all clients.
8. Resolve it from one client → "Resolved" alert for everyone; HUD bars update on all clients.

## D. Disconnect / late join
9. Mid-day, one player leaves → others see "lost connection"; the run continues.
10. Same player rejoins → "reconnected and rejoined the crew", placed aboard, HUD snapshot correct.
11. A player who was NOT in the crew joins mid-voyage → stays in the lobby, cannot use ship consoles.
12. All but one leave → solo player can still finish the day (director budget shrinks, no softlock).

## E. Day end & rewards
13. Day summary appears for everyone; XP shown; Profile panel XP increases once (not per client).
14. Leave & rejoin during Transition → no double XP for that day.

## F. Finale (use DevCommand on the server: `finale`, then play)
15. Stage 1–2 consoles open even if the system is healthy; Beacon craft works; hold counter visible to all.
16. Vote: 3 Extract / 3 Continue → tie → Extract. Repeat with majority Continue → Day 101 (Endless).

Report the failures only (line number + what happened); everything else counts as PASS.
