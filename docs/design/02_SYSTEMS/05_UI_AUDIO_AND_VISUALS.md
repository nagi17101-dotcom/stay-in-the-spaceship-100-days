# PRESENTATION — SCI-FI WITHOUT CLUTTER

## Overall direction
Compact, readable, slightly stylized sci-fi industrial realism. Dark brushed metal, off-white structural surfaces, restrained teal/cyan navigation and amber warnings, emergency red only for dangerous states. User must recognize the ship as high-tech and intentionally laid out. A competent modular builder should achieve a good result without Blender, fancy shaders or AI art.

## Lobby
- Black outer space through glass with sparse small stars and at most a faint nearby docking craft.
- Floor: clean plating with thin illuminated edges that actually mark paths; no floor spam, shop billboards or decorative rocks.
- Displays: `CREATE CREW`, `JOIN CREW`, `READY`, `2/6`, `DIFFICULTY`, `LAUNCH` and account cosmetics/info.
- Player start point facing boarding gate and main party display. Distinguish party gathering from general lobby wandering.

## Ship
- Consistent door size, ceiling clearance and repeatable corridor segments. Special rooms have distinct functional silhouettes: Bridge has a wide observation window, Reactor a protected glowing core, Cargo shelving and transfer hatch, Life Support sealed tanks, Workshop workbench and fabricator.
- Danger uses **state-driven** light changes in a room (normal neutral -> amber fault -> red critical) rather than rainbow color flicker.
- Use proper windows with near-black space. Subtle starfield slow drift; no fake terrestrial day/night.
- 3D gameplay world. UI panels appear on interaction; never turn entire game into top-down FTL or a 2D Among Us copy.

## HUD hierarchy
Always visible minimal bar: `DAY`, day progress, Hull%, O2%, Power%, `OBJECTIVE` (one sentence), small inventory shortcut. Alerts stack by severity: Critical > Warning > Informational. Expandable ship status reveals detailed temp, shields, engine and sector route. 1–2 lines for active tasks. Party pings include icon and room name.

### Example HUD copy (English source)
- `DAY 024 / 100 · ECHO FIELDS`
- `Power Distribution: Reactor output reduced. Route power to Life Support.`
- `Collect 2 Scrap Alloy from the debris receiver.`
- `Oxygen low in Cargo. Seal the bulkhead or repair the leak.`
- `DAY 100 COMPLETE — EXTRACT / CONTINUE ENDLESS`
No static filler. Update values from server state; use Roblox localization infrastructure and prepared phrase keys for translated text.

## Audio
Ambient engine hum with soundscape zones, subtle metal creaks, gentle panel confirmation. One master critical alarm with room-spatial indicators rather than six conflicting sirens. Alerts audible but never painfully loud. Optional captions and sound level preferences. Avoid copyrighted soundtracks or ripped game SFX. Use licensed assets or compose original short effects.

## Animation & polish
Doors open with limited, performant tweens; panels react to proximity; colored indicators show real health state. Hide UI when not needed. Use motion reduction support. No unreadable microtext on mobile. Avoid strong camera shake or unnecessary blur that makes tasks harder.

## Performance targets
Practical initial tuning target: stable 30 FPS on typical supported mobile devices in 6-player sessions, better on desktop. Profile instead of inventing performance claims. Use streaming where useful; avoid dense physical debris fields and per-frame updates for static screens. External starfield can be a lightweight backdrop; no full rendered galaxy simulation required.

## References
See `04_REFERENCES/REFERENCE_LINKS_AND_RIGHTS.md` for original-source game visuals and a CC0 art-kit option. Reference screenshots teach proportions and legibility, **not** provide copyright to reuse assets.
