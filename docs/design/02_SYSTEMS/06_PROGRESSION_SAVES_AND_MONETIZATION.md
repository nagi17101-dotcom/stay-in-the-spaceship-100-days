# PROGRESSION, PERSISTENCE & OPTIONAL COMMERCIALIZATION

## Two independent data layers
**Account progression** saved in DataStore with versioned schema: personal XP, level, achievements, best day, Day-100 completion by difficulty, cosmetic unlocks, selected worker/astronaut suit variants, optional purchased entitlements, lifetime meaningful actions. Protect against save failure and overlap; use update semantics, retries and shutdown handling.

**Run state**: ship/day/sector/difficulty, active room conditions, crew resource stash, ship module upgrades, generated seed, mission fragments, revisioned recent snapshot, run ID and participating players; snapshot only on stable points. Run state should not overwrite permanent purchases or other games' data. A new run doesn't inherit unfairly strong run upgrades.

## Level progression and rewards
Earn XP/credits through verified repairs, salvage, saves, low-damage transitions and milestones. No gain for holding interaction spam or fake RemoteEvents. Team share reward for core tasks, optional individual contribution bonus with a fair cap (avoid competition sabotaging others). Introduce permanent cosmetic rank (e.g., Crew Cadet, Navigator, Veteran) and modest tool convenience unlocks.

## Run upgrades
Temporary choices after certain milestones: more battery reserve, slightly faster recycler, more efficient filters, additional emergency canister, scanner forecast range. The choice is strategic. Limit stacking bonuses so Day 101+ remains risky.

## Save/rejoin expectations
- Players rejoining during a live voyage can be restored to their party if explicitly allowed and capacity remains. Rejoin must not duplicate run rewards.
- Party run resume after all players leave is an advanced feature and must never be falsely described as finished. Store authoritative server snapshot only after safe checkpoints and validate ownership/run version.
- DataStore failures must not appear as successful saves. Show graceful errors and avoid accidental permanent loss.

## Optional Robux design
Only prepare configurable hooks initially; no real Game Pass/Product IDs invented. Suggested: astronaut suit cosmetics, cabin themes, personal emotes, noncombat nameplate effects, small quality-of-life tool skins. If credits boosts are later considered, balance must keep main experience fair, and never make free rescue impossible. No paid random loot, misleading limited-time claims, or coercive failure prompts. Premium items require secure MarketplaceService receipts; protect replay via idempotency.

## Achievements and social reasons to return
- Survive Day 10 / 25 / 50 / 75 / 100 (difficulty-separated records).
- Save reactor during multi-system failure.
- Complete a Cadet/Standard/Veteran run with 2 players.
- Endure an EVA hazard and return without lost cargo.
- Choose Endless after winning; reach 125/150/200.
- Most ship efficiency without paid advantage; leaderboard anti-cheat and sensible update rates.

## Commercial goal
Sustainable optional revenue depends on player retention. Test first-minute clarity, rate of successful initial repairs, early co-op fun, replay variety and Day-100 aspiration before spending time on product art or passes. A shipped fun game is more valuable than an empty store.
