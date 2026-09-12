<!-- aidevops:brief-schema=v2 -->
# t6: Add home, match setup, and permanent upgrades

## Pre-flight
- [x] Memory recall: `Henry's Boats home setup permanent upgrades` → 0 hits.
- [x] Discovery pass: no remote issue or PR collision; t5 owns shared match state.
- [x] File refs verified: `scenes/main.tscn`, `scripts/main.gd`, `scripts/save_store.gd`, and `scripts/upgrade_catalog.gd` exist at `f723767`.
- [x] Tier: standard — user choices and persistence location are decided.
- [x] Seeded draft PR decision recorded: skipped — depends on t5's board/controller boundary.

## What
Add a home screen with Play, Map Editor, and Upgrades routes. Match setup must offer the approved map sizes; 2–8 teams; human/CPU assignment; random or saved-map selection; and starting money from the selected map. Upgrades are permanent in `user://profile.json`, purchasable on the home screen, and applied only when a new match starts.

## Why
The user needs a clear route into CPU/hot-seat games, a persistent progression loop, and explicit configuration before a match begins.

## Tier
**Selected tier:** `tier:standard`

## How (Approach)
### Files to Modify
- `NEW: scenes/setup_menu.tscn`, `scripts/setup_menu.gd` — home and match setup UI.
- `NEW: scenes/upgrade_screen.tscn`, `scripts/upgrade_screen.gd` — upgrade purchase UI.
- `EDIT: scripts/save_store.gd:1-30` — validate profile data and expose atomic profile save/load.
- `EDIT: scripts/upgrade_catalog.gd:1-12` — expose upgrade effects without mutating catalog constants.
- `EDIT: scripts/main.gd` and `scenes/main.tscn` — route screens and receive completed setup configuration.
- `EDIT: DESIGN.md` — replace placeholders with the implemented game-menu palette, touch targets, and screen hierarchy.

### Complete Write Surface
- **Callers/readers:** home screen starts GameState; `SaveStore.load_profile()` reads `user://profile.json`; GameState applies owned upgrades at creation.
- **Writers/mutation paths:** `scripts/save_store.gd` writes one validated profile payload; reject unknown IDs and insufficient currency.
- **Existing verification/tests:** headless launch and Web export; inspect local profile behavior manually in the running game.
- **Schemas/config:** profile shape remains `{version: 1, upgrades: []}` and may add a currency field with a default.
- **Generated/deployed mirrors:** `export_presets.cfg` Pages export must include all new scenes/resources.
- **Migrations/backfills:** `scripts/save_store.gd` keeps an absent profile as a fresh profile and preserves known upgrades when adding fields.
- **Cleanup/rollback paths:** reset-profile control must require confirmation and delete only `user://profile.json`.
- **Writers/mutation paths:** `scripts/save_store.gd` is the only profile writer.
- **Tests/fixtures:** `project.godot` has no test framework; `godot --headless --path . --quit-after 1` is the current production smoke check.
- **Generated/deployed mirrors:** `export_presets.cfg` builds `site/index.html` for Pages.
- **Migrations/backfills:** `scripts/save_store.gd` supplies profile defaults for pre-upgrade users.

### Implementation Steps
1. Build accessible home/setup controls using the documented DESIGN.md tokens and 44px minimum touch targets.
2. Validate selections before starting a match: 2–8 teams, at least one human team, and selected map/player counts compatible with its ports.
3. Add permanent upgrade purchase and ownership feedback; apply modifiers to newly created units/matches only.
4. Ensure saved-map and Map Editor navigation has a back path to home.

### Hazards and Compatibility
- **Concurrency/atomicity:** profile writes must write a complete JSON document and not mutate a running match.
- **Migration/rollback:** default missing profile and unknown upgrade IDs safely.
- **Mixed-version/backward compatibility:** old profiles with only `upgrades` remain valid.
- **Idempotency/retry:** purchasing an owned upgrade cannot charge twice.
- **Partial failure/recovery:** file write errors remain visible and leave in-memory profile unchanged.

### Verification Before Dispatch
- **Surface mapping:** the headless launch parses home/setup/upgrade scene routes; the export proves their resources are available to the web build.
```bash
bash -lc 'godot --headless --path . --quit-after 1'
bash -lc 'mkdir -p site && godot --headless --path . --export-release "Web" site/index.html'
```

## Acceptance Criteria
- [ ] A player can configure a 2–8 team match from home, choose a listed size or saved map, and start it.
- [ ] Purchased upgrades persist across restart and affect newly started matches only; an owned upgrade cannot be bought again.
- [ ] A failed profile write does not charge the player or corrupt the prior profile.

## Files Scope
- `scripts/main.gd`
- `scripts/save_store.gd`
- `scripts/upgrade_catalog.gd`
- `scripts/setup_menu.gd`
- `scripts/upgrade_screen.gd`
- `scenes/main.tscn`
- `scenes/setup_menu.tscn`
- `scenes/upgrade_screen.tscn`
- `DESIGN.md`
