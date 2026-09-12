<!-- aidevops:brief-schema=v2 -->
# t7: Add custom-map editor, validation, and JSON import/export

## Pre-flight
- [x] Memory recall: `Henry's Boats custom map editor JSON` → 0 hits.
- [x] Discovery pass: no remote issue or PR collision; t5 owns the scalable board and MapData loading.
- [x] File refs verified: `scripts/map_data.gd`, `scripts/save_store.gd`, and `scenes/main.tscn` exist at `f723767`.
- [x] Tier: standard — format and editor capability are decided.
- [x] Seeded draft PR decision recorded: skipped — depends on t5's MapBoard API.

## What
Add a Map Editor route where players choose any approved map size, paint Water/Reef/Mountain tiles, place multiple team-coloured ports, place starting units for any team, set starting money, validate the result, and save/load JSON map files. On Web builds, provide download/upload; on native builds, store maps in `user://maps/`.

## Why
Custom maps are needed for multi-team starts and player-authored layouts; MapData already establishes the persisted field names.

## Tier
**Selected tier:** `tier:standard`

## How (Approach)
### Files to Modify
- `NEW: scenes/map_editor.tscn`, `scripts/map_editor.gd` — editing UI and palette.
- `EDIT: scripts/map_data.gd:1-43` — strict `from_dictionary()`, map validation, port/start-unit helpers.
- `EDIT: scripts/save_store.gd:21-30` — enumerate, load, validate, and save maps.
- `EDIT: scripts/map_board.gd` and `scenes/map_board.tscn` — editor paint and placement mode, reusing t5 board input.
- `EDIT: scripts/main.gd` — navigation between home/editor/setup.
- `EDIT: README.md` — document map authoring and JSON portability.

### Complete Write Surface
- **Callers/readers:** `scripts/setup_menu.gd` lists validated saved maps; `scripts/map_board.gd` emits selected grid cells; GameState consumes map ports and starting units.
- **Writers/mutation paths:** `scripts/map_editor.gd` changes only a working MapData copy; save occurs only after validation passes.
- **Existing verification/tests:** headless launch and Web export; exercise JSON parse validation with valid and malformed payloads.
- **Schemas/config:** `scripts/map_data.gd` owns version 1 fields, terrain values Water/Reef/Mountain, ports, starting_units, and starting_money.
- **Generated/deployed mirrors:** Web upload/download must not expose filesystem paths; native maps are under `user://maps/`.
- **Migrations/backfills:** `scripts/map_data.gd` rejects unknown future versions with a clear message and fills optional missing arrays with empty arrays.
- **Cleanup/rollback paths:** `scripts/map_editor.gd` cancel discards the unsaved working copy; delete requires confirmation and affects only the selected saved map.
- **Callers/readers:** `scripts/main.gd` and `scripts/setup_menu.gd` read validated `scripts/map_data.gd` maps.
- **Writers/mutation paths:** `scripts/save_store.gd` is the only persistent map writer.
- **Tests/fixtures:** `project.godot` has no test framework; `godot --headless --path . --quit-after 1` is the current production smoke check.
- **Schemas/config:** `scripts/map_data.gd` is the map JSON schema owner.
- **Migrations/backfills:** `scripts/map_data.gd` fills missing optional arrays while rejecting incompatible versions.
- **Cleanup/rollback paths:** `scripts/map_editor.gd` discards an unsaved MapData copy on cancel.

### Implementation Steps
1. Reuse MapBoard paint/selection APIs rather than creating a second cell renderer.
2. Validate size, terrain values, ports, unique occupied cells, 2–8 participating teams, and starting units before enabling Save/Use Map.
3. Serialize only JSON-safe data; represent Vector2i as explicit x/y objects or arrays consistently.
4. Add Web-safe import/export controls and native local-map list controls.

### Hazards and Compatibility
- **Concurrency/atomicity:** editing is isolated until Save/Use Map; no mutation of an active match.
- **Migration/rollback:** malformed data never overwrites a valid map.
- **Mixed-version/backward compatibility:** version 1 maps remain readable after adding optional fields.
- **Idempotency/retry:** saving a same-name map requires explicit replace confirmation.
- **Partial failure/recovery:** failed parse/write shows an error and preserves the editor working copy.

### Verification Before Dispatch
- **Surface mapping:** the headless launch parses editor/map serialization code; the export verifies its scenes and resources are present in the browser artifact.
```bash
bash -lc 'godot --headless --path . --quit-after 1'
bash -lc 'mkdir -p site && godot --headless --path . --export-release "Web" site/index.html'
```

## Acceptance Criteria
- [ ] A map author can create a valid multi-port map with all terrain types, starting units, and starting money, then use it in match setup.
- [ ] Invalid or malformed JSON cannot crash the game or replace a valid saved map.
- [ ] Editor cancellation does not mutate an active match or an existing saved map.

## Files Scope
- `scripts/map_data.gd`
- `scripts/save_store.gd`
- `scripts/map_board.gd`
- `scripts/map_editor.gd`
- `scripts/main.gd`
- `scenes/map_board.tscn`
- `scenes/map_editor.tscn`
- `README.md`
