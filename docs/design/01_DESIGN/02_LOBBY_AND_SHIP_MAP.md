# 3D WORLD BIBLE — FUTURISTIC LOBBY AND MEDIUM SPACESHIP

## Lobby: purpose and appearance
A tidy orbital embarkation lounge in black star-filled space, perhaps a small transparent observation wall overlooking the waiting spacecraft. Treat the sky as outer space, **not daytime Earth**. Lighting comes from architectural strips, terminals and modest recessed beacons. No crowded sign walls, levitating shops or disconnected islands.

**Spatial order:** entry spawn -> central mission board -> two launch/party staging pads or a compact boarding gate -> short side alcove for cosmetics/records. The goal is a small purposeful public lobby, **not** a huge social plaza.

### Functional lobby details
- Party host creates or joins a 2–6 crew party, invites friends, chooses difficulty: Cadet, Standard, Veteran.
- Easy-to-read party panel: `3/6 CREW`, player names, READY status, difficulty and expected mission rules. Host may leave; leadership transfers deterministically.
- Players can leave party without leaving the lobby; party owner can start only with **2–6 valid players**, unless Studio dev testing override active.
- Start countdown 10–15 seconds after eligible players ready; cancel if count falls below 2 or host revokes.
- Match becomes launch-locked before teleport; prevent duplicate starts and double-teleport. Failed teleport returns player to a clean lobby state with a visible retry.
- Support separate queue/party instances. Roblox reserved servers are a suitable implementation after testing; see official docs in `05_TECH`.
- Show simple tutorial kiosk with optional concise controls. No mandatory multi-minute tutorial.
- No mission rank or store purchase gating.

## Ship exterior: silhouette
A compact, original exploration vessel: narrow forward bridge nose, larger central cylindrical/rounded cabin modules, paired engine pods aft, small shield array, one bright EVA airlock. This **must not** mimic the silhouette or exact layout of another game. Exterior is primarily visible from the lobby or occasional EVA windows; gameplay is mainly inside.

## Size constraints and navigation targets
Target normal traversal across ship **~20–35 seconds** without sprint, common Bridge-to-Reactor **~8–14 seconds**, important room entrances reachable from main junction in **~5–12 seconds**. Final dimensions should be chosen by actual Roblox avatar and camera tests, not copied from a top-down diagram. Mostly **single deck**, with a tiny service crawlspace or cargo platform only if it improves gameplay. 2–3 broad central corridors, optional short alternate maintenance passage; no labyrinth or dead-end decorative wings.

### Conceptual adjacency (NOT a copyrighted layout)
```
                       [BRIDGE / NAV]
                            |
           [COMMS] -- [CENTRAL JUNCTION] -- [MED / REST]
                         /      |       \
                   [LIFE]   [WORKSHOP]   [POWER]
                      |        |           |
                   [CARGO] -- [SERVICE] -- [REACTOR / ENGINE]
                      |
                  [AIRLOCK / EVA]
```
This is a **functional graph**, not a literal blueprint. The level designer must give each room practical geometry and validate sightlines. A small shared **Central Junction** supports emergency triage and clear signs. Use no clone of any existing ship map.

## Required named rooms / 11 logical zones
1. **Bridge** — helm controls, status overview, day advance display; wide forward window displaying black space. Controls must match actual events.
2. **Navigation** — sector chart, route choice, long-term signal objective; can share the Bridge footprint but must be distinguished logically.
3. **Reactor** — physical power core, risk indicators, emergency shutdown and staged restart; visually contained.
4. **Engine** — thrust/fuel checks, overheating mitigation; close to Reactor but separate repair station.
5. **Life Support** — oxygen scrubbers, filters, atmospheric regulation and reserve tanks.
6. **Power/Distribution** — distribution buses, breakers, battery, prioritization switches.
7. **Cooling/Service** — coolant pumps/thermal controls and maintenance access; can be a service subzone of Engineering to keep ship compact.
8. **Workshop/Fabricator** — recyclable input, crafting output, tool rack, parts storage and component assembly.
9. **Cargo/Salvage** — finite storage, cargo crate interactions, external salvage receiver, inventory terminal.
10. **Comms/Scanner** — warning logs, distress beacons, hazard forecast and meaningful temporary scan calibration.
11. **Medical/Rest** — medical restoration, crew morale cue, short recovery affordances; not a giant cafeteria.
12. **Airlock/EVA** — controlled optional salvage sorties with return tether, always a survivable fallback.
You may combine Bridge+Navigation or Cooling+Service visually while retaining unique console functions. Avoid 14 tiny rooms solely to fill a list.

## Room standards
Each room requires (a) nameplate, (b) one distinct silhouette/color accent, (c) at least one useful interaction, (d) at least two safe standing positions for co-op where relevant, (e) clear visible route back to Junction, (f) clear blocked/unblocked state if incident affects it. No duplicate fake consoles. Use readable iconography as well as text.

## Windows and outer space
Outside the ship: near-black background, sparse low-contrast stars, occasional distant silhouettes/nebula accents, subtle passing debris. **Never bright blue daytime sky, sun cycle, regular clouds or planetary ground.** Window panes should feel real and not reveal a terrain baseplate. Stars must not distract from interactive screens. An animated travel backdrop is cosmetic; gameplay does not depend on physically moving the full ship.

## Level-of-detail targets
Use modular wall/floor/ceiling kits, controlled emissives, subtle gray/white/blue with room-specific yellow/red warning. Limited mesh count and sensible collision. Place trim where it explains architecture. A coherent small environment beats a huge empty spacecraft. Model important stations as coherent mechanisms with legible inputs/outputs; do not use hundreds of buttons with no function.

## Navigation acceptance test
A new player who has never seen the map must be able to follow `BRIDGE > LIFE SUPPORT > WORKSHOP > AIRLOCK` using signs alone. At every doorway the room name and current danger state must be visually readable. Test R6/R15 clearance, PC/mobile camera, two players standing at one station, 6 players passing a junction, and carrying a small resource crate.
