<!-- aidevops:brief-schema=v2 -->
# t5: Extract dynamic match state and a scalable map board

## Pre-flight
- [x] Memory recall: `Henry's Boats multiplayer map state board` → 0 hits.
- [x] Discovery pass: `c1c3715` added `scripts/map_data.gd`, `scripts/team_data.gd`, `scripts/save_store.gd`, and `scripts/upgrade_catalog.gd`; no remote issue or PR collision.
- [x] File refs verified: `scripts/main.gd`, `scenes/main.tscn`, and each existing data script are present at `f723767`.
- [x] Tier: standard — architecture is decided but the worker must make local Godot scene boundaries.
- [x] Seeded draft PR decision recorded: skipped — no stable extraction exists yet.

## What
Replace the hard-coded two-side 8×8 Button grid with a shared match-state model and a rendered board that supports 10×10, 15×15, 20×20, 25×25, 30×30, 40×40, 50×50, 75×75, and 100×100 maps. The board must pan and zoom rather than instantiate 10,000 buttons.

## Why
Every remaining multiplayer, editor, CPU, and inspector feature needs one authoritative map/team/unit model and a board that is usable on a mobile viewport at 100×100.

## Tier
**Selected tier:** `tier:standard`

**Tier rationale:** The data foundation exists, and the requested scale and map-size choices are decided; scene extraction and input handling remain normal implementation choices.

## How (Approach)
### Files to Modify
- `EDIT: scripts/main.gd:1-485` — reduce to a screen/game controller and remove hard-coded `PLAYER`, `ENEMY`, `GRID_COLUMNS`, and `GRID_ROWS` state.
- `EDIT: scripts/map_data.gd:1-43` — add validation and dictionary loading while preserving version `1` serialization.
- `EDIT: scripts/team_data.gd:1-18` — support team turn order and 2–8 named coloured teams.
- `NEW: scripts/game_state.gd` — authoritative match state and unit collection.
- `NEW: scripts/map_board.gd` and `NEW: scenes/map_board.tscn` — draw cells and expose pan, zoom, selection, and grid conversion.
- `EDIT: scenes/main.tscn` — host the board instead of dynamically-created cell Buttons.

### Complete Write Surface
- **Callers/readers:** `scripts/main.gd` currently owns map draw, selection, combat, and turns; later menu/editor/CPU tasks must consume `GameState` and `MapBoard`.
- **Writers/mutation paths:** `MapData.set_terrain()` and unit/team collections are the only state mutation entry points after extraction.
- **Existing verification/tests:** no automated unit suite exists; use headless launch and Web export.
- **Schemas/config:** preserve `MapData.to_dictionary()` version 1 fields: width, height, starting_money, terrain, ports, starting_units.
- **Generated/deployed mirrors:** `.github/workflows/deploy-pages.yml` exports `site/index.html`.
- **Migrations/backfills:** `scripts/map_data.gd` defaults must create a valid 10×10 map when old state is absent.
- **Cleanup/rollback paths:** retain a playable default map and avoid changing saved maps outside `MapData`.
- **Tests/fixtures:** `project.godot` has no test framework; `godot --headless --path . --quit-after 1` is the current production smoke check.

### Implementation Steps
1. Introduce `GameState` with MapData, teams, units, current team index, and safe lookup/mutation methods.
2. Replace cell Button creation with `_draw()` terrain/unit-adjacent rendering plus pointer-to-grid conversion; support drag pan and bounded zoom.
3. Keep the existing terrain/defence/combat rules working through the new model on the default map.
4. Provide a tested default map factory with at least two ports and valid starting units.

### Hazards and Compatibility
- **Concurrency/atomicity:** one controller owns game-state mutations; visual nodes must not mutate dictionaries directly.
- **Migration/rollback:** missing or malformed map fields fall back to a safe default rather than crash.
- **Mixed-version/backward compatibility:** version-1 MapData fields remain serializable.
- **Idempotency/retry:** board rebuilds must clear/re-render without duplicating units or listeners.
- **Partial failure/recovery:** invalid grid input must be ignored with a user-facing message.

### Verification Before Dispatch
- **Surface mapping:** the headless launch parses `scripts/main.gd`, MapData, GameState, and board scenes; the export validates every referenced resource enters `site/`.
```bash
bash -lc 'godot --headless --path . --quit-after 1'
bash -lc 'mkdir -p site && godot --headless --path . --export-release "Web" site/index.html'
```

## Acceptance Criteria
- [ ] A new match can use every listed map size and a 100×100 board remains navigable via pan/zoom.
- [ ] The default map still launches and preserves existing terrain, port-capture, and combat behavior.

## Files Scope
- `scripts/main.gd`
- `scripts/map_data.gd`
- `scripts/team_data.gd`
- `scripts/game_state.gd`
- `scripts/map_board.gd`
- `scenes/main.tscn`
- `scenes/map_board.tscn`
