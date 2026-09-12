<!-- aidevops:brief-schema=v2 -->
# t9: Add map and unit inspection, range overlays, and end-to-end verification

## Pre-flight
- [x] Memory recall: `Henry's Boats inspection ranges verification` → 0 hits.
- [x] Discovery pass: no remote issue or PR collision; t5–t8 own shared data, setup, editor, and turn behavior.
- [x] File refs verified: `scripts/main.gd`, `scenes/main.tscn`, `README.md`, and `DESIGN.md` exist at `f723767`.
- [x] Tier: standard — inspector content and range semantics are decided by existing unit stats and terrain defence rules.
- [x] Seeded draft PR decision recorded: skipped — run after predecessor merge to avoid stale UI assumptions.

## What
Show a clear inspector when a tile or unit is selected. Empty tiles display terrain and defence rules; occupied tiles also display team, unit type, HP, move, range, attack, target restrictions, and active defence. Selecting a unit overlays its legal movement and attack ranges. Complete a user-path verification pass for home, saved maps, hot-seat, CPU, combat, and Web export.

## Why
Players need to understand terrain defence, target restrictions, and why a unit can or cannot act. This is the integration closeout for the expanded game flow.

## Tier
**Selected tier:** `tier:standard`

## How (Approach)
### Files to Modify
- `NEW: scenes/inspector_panel.tscn`, `scripts/inspector_panel.gd` — selected tile/unit facts and accessible labels.
- `EDIT: scripts/map_board.gd` — selection and legal move/attack overlay rendering.
- `EDIT: scripts/main.gd` and `scenes/main.tscn` — route selection to inspector and clear stale overlays on turn change.
- `EDIT: README.md` and `DESIGN.md` — document controls and final visual interaction rules.

### Complete Write Surface
- **Callers/readers:** `scripts/map_board.gd` selection emits grid/unit IDs; `scripts/game_state.gd` exposes terrain, stats, defence, and legal destinations/targets; inspector reads only snapshots.
- **Writers/mutation paths:** `scripts/game_state.gd` remains the gameplay writer; inspector and overlays are read-only.
- **Existing verification/tests:** Godot headless launch and Web export; manual product path across menu/editor/match modes.
- **Schemas/config:** `scripts/map_data.gd` has no persisted schema change; read MapData terrain and GameState unit/team values.
- **Generated/deployed mirrors:** export `site/index.html` and confirm the Pages build workflow succeeds after merge.
- **Migrations/backfills:** `scripts/inspector_panel.gd` has no saved-data migration; missing optional unit fields display safe defaults.
- **Cleanup/rollback paths:** `scripts/main.gd` clears overlays and inspector when selected entity disappears or match ends.
- **Callers/readers:** `scripts/main.gd` passes MapBoard selection snapshots to `scripts/inspector_panel.gd`.
- **Writers/mutation paths:** `scripts/game_state.gd` remains the only gameplay-state writer; `scripts/inspector_panel.gd` is read-only.
- **Tests/fixtures:** `project.godot` has no test framework; `godot --headless --path . --quit-after 1` is the current production smoke check.
- **Schemas/config:** `scripts/map_data.gd` terrain values and `scripts/game_state.gd` unit stats are read without schema changes.
- **Migrations/backfills:** N/A because `scripts/inspector_panel.gd` introduces no persisted fields.
- **Cleanup/rollback paths:** `scripts/main.gd` clears selection when the active unit disappears.

### Implementation Steps
1. Add a compact, responsive inspector that names terrain defence separately from unit stats.
2. Render distinct movement and attack range overlays for the selected current-team unit, excluding illegal terrain and target categories.
3. Add a visible explanation when an attempted action is invalid instead of silently ignoring it.
4. Exercise and document every requested route: home, upgrades, map editor, saved map selection, CPU/hot-seat turns, terrain, unit combat, victory, and Web export.

### Hazards and Compatibility
- **Concurrency/atomicity:** selection redraw must not mutate state or interrupt CPU animation.
- **Migration/rollback:** no persisted data changes; missing details cannot crash inspector rendering.
- **Mixed-version/backward compatibility:** existing combat range and terrain defence rules remain the source of truth.
- **Idempotency/retry:** repeated selection replaces, not stacks, overlay nodes.
- **Partial failure/recovery:** a removed unit clears selection and inspector safely.

### Verification Before Dispatch
- **Surface mapping:** the headless launch parses inspector and overlay scene links; the export confirms all final user-path assets enter `site/`.
```bash
bash -lc 'godot --headless --path . --quit-after 1'
bash -lc 'mkdir -p site && godot --headless --path . --export-release "Web" site/index.html'
```

## Acceptance Criteria
- [ ] Selecting any tile or unit exposes the relevant terrain/unit/team/defence information and legal range overlays.
- [ ] Overlays cannot enable illegal moves or attacks and are cleared when selection, turn, or match state changes.
- [ ] The complete game path launches and exports without Godot errors.

## Files Scope
- `scripts/main.gd`
- `scripts/map_board.gd`
- `scripts/inspector_panel.gd`
- `scenes/main.tscn`
- `scenes/inspector_panel.tscn`
- `README.md`
- `DESIGN.md`
