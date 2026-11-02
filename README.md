# Stay in the Spaceship for 100 Days

Original 2–6 player co-op survival game for Roblox. Keep an interdependent ship alive for 100 navigation days, then Extract or continue into Endless Voyage.

**Status:** M1 vertical slice (code complete, single-player Studio tested). See `TASK_BOARD.md`.

## Setup (Windows)
1. Install [Aftman](https://github.com/LPGhatguy/aftman), then in this folder: `aftman install` (installs Rojo 7.4.4).
2. Install the Rojo Studio plugin: `rojo plugin install`.
3. `rojo serve` → in Studio open the place, Rojo plugin → **Connect**.
4. World (ship, lobby, lighting) is in the place file. To rebuild it in a fresh place: paste `tools/BuildShip.luau`, then `tools/BuildLobby.luau` into Studio's Command Bar.
5. Multiplayer test: Studio → Test → Clients and Servers → 2 (or 6) players. In Studio a solo crew can launch (`Config.StudioSoloOverride`); live servers require 2–6.

Rojo manages only `ReplicatedStorage.Shared`, `ServerScriptService.Server`, `StarterPlayer.StarterPlayerScripts.Client`. Edit code in `src/`, not in Studio.

## Layout
```
src/shared   Config, types, network registry, public minigame math (replicated)
src/server   Run coordinator, ship simulation, day cycle, tasks, minigame validators, inventory, world services
src/client   HUD, overlays, task UIs, local effects
tools/       Studio command-bar scripts (world builder)
docs/design  Original design & AI task package (source of truth for game design)
```
