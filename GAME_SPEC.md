# GAME_SPEC — key constraints (full design: docs/design/)
- 3D only, 2–6 co-op players (Studio solo override for dev only: `Config.StudioSoloOverride`).
- Medium, legible single-deck ship; star-black space outside; no day/night sky.
- Day = Prepare 15s → Active 75s → Transition 8s (starting targets, not playtested). 100 days, then Extract / Endless.
- Difficulty: Cadet / Standard / Veteran (`Config.Difficulty`). Achievable without purchases.
- Server-authoritative everything: clients send intents; server validates range, ownership, shape, state, cooldown.
- Catastrophe (Hull 0 or O2 0) is foreshadowed + reversible: 30s × graceFactor emergency window before loss.
- 12 minigames total in 4+4+4 batches; no hardcoded single answer; every generated puzzle checked solvable.
- Original art/mechanics only. No copied layouts, UI, textures or code.
