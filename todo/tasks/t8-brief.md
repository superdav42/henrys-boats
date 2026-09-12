<!-- aidevops:brief-schema=v2 -->
# t8: Add hot-seat teams and paced CPU turns

## Pre-flight
- [x] Memory recall: `Henry's Boats hot-seat CPU visible turns` → 0 hits.
- [x] Discovery pass: no remote issue or PR collision; t5 owns GameState/team turn order.
- [x] File refs verified: `scripts/main.gd`, `scripts/team_data.gd`, and `scenes/main.tscn` exist at `f723767`.
- [x] Tier: standard — local hot-seat rules and 1.5-second action pacing are decided.
- [x] Seeded draft PR decision recorded: skipped — depends on t5's shared state.

## What
Implement ordered 2–8 team turns with named colours, local hot-seat hand-off screens, and CPU-controlled teams. The CPU must buy units when it has money and an available port, then visibly move or attack one unit at a time with a 1.5-second pause between actions. Human input remains disabled until a CPU turn and transition have finished.

## Why
The prototype currently runs an instantaneous hard-coded enemy loop. Players must be able to understand CPU decisions and pass a shared device safely between human teams.

## Tier
**Selected tier:** `tier:standard`

## How (Approach)
### Files to Modify
- `NEW: scripts/turn_manager.gd` — ordered team advancement, transition state, and action lock.
- `NEW: scripts/cpu_controller.gd` — produce legal build/move/attack action commands from immutable state.
- `EDIT: scripts/game_state.gd` — execute commands shared by human and CPU teams.
- `EDIT: scripts/team_data.gd:1-18` — colour/name/controller helpers.
- `EDIT: scripts/main.gd` and `scenes/main.tscn` — render transitions, action highlights, and input lock.

### Complete Write Surface
- **Callers/readers:** `scripts/setup_menu.gd` creates teams; `scripts/game_state.gd` validates actions; MapBoard displays movement; UI reads current team.
- **Writers/mutation paths:** only `scripts/turn_manager.gd` advances turns; only `scripts/game_state.gd` applies validated commands and money changes.
- **Existing verification/tests:** headless launch and Web export; manual play must exercise human/CPU mixed teams.
- **Schemas/config:** controller type is exactly `human` or `cpu`; team IDs are stable map references.
- **Generated/deployed mirrors:** `export_presets.cfg` produces the normal Web export.
- **Migrations/backfills:** `scripts/game_state.gd` default two-team matches map player to human and opponent to CPU.
- **Cleanup/rollback paths:** `scripts/turn_manager.gd` restores input only after a cancelled animation action completes; no half-applied move.
- **Callers/readers:** `scripts/main.gd` and `scripts/map_board.gd` read the active turn from `scripts/turn_manager.gd`.
- **Writers/mutation paths:** `scripts/game_state.gd` applies commands while `scripts/turn_manager.gd` alone advances turns.
- **Tests/fixtures:** `project.godot` has no test framework; `godot --headless --path . --quit-after 1` is the current production smoke check.
- **Generated/deployed mirrors:** `export_presets.cfg` builds `site/index.html` for Pages.
- **Migrations/backfills:** `scripts/game_state.gd` provides a two-team human/CPU default when controller data is absent.
- **Cleanup/rollback paths:** `scripts/turn_manager.gd` releases its input lock after a rejected CPU command.

### Implementation Steps
1. Replace the hard-coded `_run_enemy_turn()` with TurnManager and legal action commands.
2. Display a five-second human-team hand-off overlay before enabling the next human player; never show it between CPU actions.
3. Animate each CPU movement step and wait 1.5 seconds between completed CPU actions; show current team and selected unit.
4. Implement conservative CPU purchases at owned unblocked ports and legal nearest-target/port actions.

### Hazards and Compatibility
- **Concurrency/atomicity:** lock player input throughout CPU planning, movement animation, and turn transition.
- **Migration/rollback:** default team state preserves a playable human-versus-CPU game.
- **Mixed-version/backward compatibility:** GameState remains the action authority for both controllers.
- **Idempotency/retry:** CPU commands are revalidated before execution; stale commands are discarded.
- **Partial failure/recovery:** invalid or blocked CPU action ends that unit's action without freezing the turn.

### Verification Before Dispatch
- **Surface mapping:** the headless launch parses turn/CPU scripts and scene connections; the export confirms animated-turn resources are built for Pages.
```bash
bash -lc 'godot --headless --path . --quit-after 1'
bash -lc 'mkdir -p site && godot --headless --path . --export-release "Web" site/index.html'
```

## Acceptance Criteria
- [ ] Mixed human/CPU games cycle through every configured team; human hand-offs display for five seconds and do not run CPU logic.
- [ ] CPU actions are legal, visibly animated, and paced by roughly 1.5 seconds; player input cannot alter state mid-action.

## Files Scope
- `scripts/main.gd`
- `scripts/game_state.gd`
- `scripts/team_data.gd`
- `scripts/turn_manager.gd`
- `scripts/cpu_controller.gd`
- `scenes/main.tscn`
