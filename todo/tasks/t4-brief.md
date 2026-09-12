<!-- aidevops:brief-schema=v2 -->
# t4: Build the configurable multiplayer roadmap

## Pre-flight
- [x] Memory recall: `Henry's Boats terrain combat UI multiplayer CPU map editor upgrades` → 0 hits.
- [x] Discovery pass: 4 relevant local commits; no merged or open remote PRs; no open issues.
- [x] File refs verified: `scripts/main.gd`, `scenes/main.tscn`, and the four existing data scripts are present at `f723767`.
- [x] Tier: thinking — the prototype needs an architectural split before multiple workers can safely extend it.
- [x] Seeded draft PR decision recorded: skipped — children should own isolated implementation PRs.

## What
Coordinate the approved local-game expansion: 2–8 coloured human/CPU teams, map sizes from 10×10 to 100×100, saved custom maps, persistent local upgrades, terrain/unit inspection, and observable 1.5-second CPU action pacing. This is a parent tracker only; it must not receive implementation work or auto-dispatch.

## Why
The current single-scene prototype hard-codes two sides and an 8×8 button board. The requested modes require ordered child delivery so new UI does not duplicate or bypass the shared match state.

## Tier
**Selected tier:** `tier:thinking`

**Tier rationale:** Sequencing, model ownership, scalable rendering, and persistent map compatibility span all remaining delivery work. The child briefs below contain decided implementation boundaries.

## Phases
- Phase 1 - Extract dynamic match state and a scalable map board [auto-fire:on]
- Phase 2 - Add home, match setup, and permanent upgrades [auto-fire:on-prior-merge]
- Phase 3 - Add custom-map editor, validation, and JSON import/export [auto-fire:on-prior-merge]
- Phase 4 - Add hot-seat teams and paced CPU turns [auto-fire:on-prior-merge]
- Phase 5 - Add map/unit inspection, range overlays, and end-to-end verification [auto-fire:on-prior-merge]

## How (Approach)
### Files to Modify
- `EDIT: TODO.md` — retain the parent task and dependency intent.
- `EDIT: todo/tasks/t4-brief.md` — retain the parent delivery contract.

### Complete Write Surface
- **Callers/readers:** GitHub parent/sub-issue relationships and Pulse status labels.
- **Writers/mutation paths:** children create their own worktrees and PRs.
- **Existing verification/tests:** `godot --headless --path . --quit-after 1`; Web export from `export_presets.cfg`.
- **Schemas/config:** `scripts/map_data.gd`, `scripts/save_store.gd`, and `scripts/team_data.gd` are the established foundation.
- **Generated/deployed mirrors:** `.github/workflows/deploy-pages.yml` deploys main; no parent changes required.
- **Migrations/backfills:** child t7 owns JSON map compatibility; child t6 owns persistent profile compatibility.
- **Cleanup/rollback paths:** close or re-scope a child without closing this parent until all phases are delivered.

### Implementation Steps
1. Keep this issue labelled `parent-task`; do not create a PR that closes it.
2. Maintain native sub-issue dependencies and allow Pulse to promote blocked children after verified predecessor merges.

### Hazards and Compatibility
- **Concurrency/atomicity:** independent workers must not edit `scripts/main.gd` until t5 has merged.
- **Migration/rollback:** child PRs must preserve the playable 8×8 default until their replacement is complete.
- **Mixed-version/backward compatibility:** map/profile JSON must be versioned by the owning child.
- **Idempotency/retry:** dependency labels and relationships can be safely reconciled by Pulse.
- **Partial failure/recovery:** leave the failing child open and keep later children blocked.

### Verification Before Dispatch
- **Surface mapping:** `gh issue list` proves the parent and child tracker state without mutating game code.
```bash
bash -lc 'gh issue list --repo superdav42/henrys-boats --state open'
```

## Acceptance Criteria
- [ ] The parent has native child relationships for t5–t9 and remains open until all child work is merged.
- [ ] No worker is dispatched directly for this parent tracker.

## Files Scope
- `TODO.md`
- `todo/tasks/t4-brief.md`
