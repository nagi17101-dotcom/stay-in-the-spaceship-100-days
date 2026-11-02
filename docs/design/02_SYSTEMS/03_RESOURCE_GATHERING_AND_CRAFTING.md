# RESOURCE GATHERING, SCAVENGING, FABRICATION & SUPPLY CHAIN

## Motivation
Resource acquisition must be a cooperative choice, not an idle auto-clicker. Players survive by deciding when to salvage externally, recycle internal parts, and spend scarce materials for preventative maintenance. Resources are a **shared crew stock**; permanent personal credits and experience are tracked separately.

## Starting resource vocabulary
| Resource | Main source | Main uses | Recovery alternative |
|---|---|---|---|
| Scrap Alloy | recycler, debris | hull patches, brackets | emergency dismantling of noncritical scrap |
| Conductive Filament | cargo, damaged components | power connectors, signal parts | recover from redundant old cabling |
| Filter Membrane | cargo/salvage | atmosphere and coolant filtration | fabricator recycle + baseline material subsidy |
| Logic Module | rare salvage / fabricator | scanners, comms and navigation | low-efficiency diagnostic bypass |
| Coolant Cartridge | service stores/ore ice capture | cooling recovery | temporary low-power throttle workaround |
| Fuel Cell | recovered pods and sector rewards | efficient drive cycle | emergency battery-backed low-speed transit |
| Sealant Foam | workshop/salvage | short-term hull repair | manual containment protocol |
| Capacitor | dismantled electronics | shields, backup power | reduce nonessential loads |

## Five acquisition actions
1. **In-ship salvage:** inspect damaged module, recover a few usable materials after physically completing a short extraction interaction. Finite per breakdown; never farm infinitely by repeatedly toggling a broken module.
2. **Recycler:** feed validated junk items gathered from actual cargo points, use small material sorting decision, produce predictable output; avoid infinite inputs.
3. **External drone:** scan debris, solve M09 waypoint task, launch an unmanned drone; rewards are delivered into Cargo after a visible travel countdown.
4. **Optional EVA:** airlock activates protective suit/tether. Player exits **a small bounded exterior service zone**, retrieves component/patches antenna, returns. The ship itself stays medium; EVA need not be an open-world space flight simulator. Failures carry fair consequences and rescue windows.
5. **Sector contracts:** choose one of two ethically balanced optional missions at sector transitions (scan strange pulse, stabilize derelict beacon, salvage coolant), each with known risk/reward. Content can be procedural from validated templates.

## Core crafting recipes (configurable examples)
- Hull Patch Kit = 2 Scrap Alloy + 1 Sealant Foam.
- Conductive Jumper = 1 Scrap Alloy + 2 Conductive Filament.
- O2 Filter Unit = 2 Filter Membrane + 1 Scrap Alloy.
- Coolant Bypass Kit = 1 Coolant Cartridge + 1 Conductive Filament.
- Comms Transceiver = 2 Logic Module + 1 Conductive Filament + 1 Capacitor.
- Shield Capacitor Bank = 2 Capacitor + 1 Scrap Alloy.
- Day-100 Beacon Assembly = milestone fragments + configurable Comms Transceiver + 1 Alloy Frame; ingredients may be earned via alternate fair sector goals.

## Rules preventing deadlocks
- Reactor emergency has a temporary manual throttle action requiring **no rare material**.
- Oxygen crisis has a short reserve canister or isolated-room solution requiring only available starter materials.
- Cargo recycler must be repairable with scavenged baseline parts or manual bypass; it cannot gate every future resource.
- If Director requires a rare input, it must know the resource is reachable within the scenario's grace budget.
- Missing rare material should demand alternative strategy, **not Robux**.
- Payouts of salvage and crafted items are server-calculated and once-only via unique transaction IDs.

## Crew economy & carry design
- Crew storage has logical capacity by resource category but UI counts are compact; do not simulate hundreds of physical item objects in the ship.
- Carry one large salvage crate at a time; crate can be transferred with validated handshake; tool interactions stay usable.
- Shared material access prevents two players both consuming the same part through race conditions.
- Deliveries should physically appear as a crate at a clean cargo receiver, but data remains authoritative.

## UX and balance
- Every item should explain its primary use in one line. Main HUD shows only resources relevant to active task, not 20 icons constantly.
- Never hide missing materials until the player starts a repair; show bill of materials before committing.
- Resource sources have cooldowns tied to sector activity, not an infinite-click economy.
- Test a two-player Standard run from low resources; team must be able to restore core systems.
