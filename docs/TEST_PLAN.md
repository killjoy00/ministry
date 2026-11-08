# Prototype test and acceptance plan

## Automated tests (Godot headless)
- Fixed seeds produce identical event histories given the same intervention sequence.
- A causal event cannot fire before prerequisites are satisfied.
- Once-per-run rules never fire twice.
- Misfile only affects eligible event definitions and changes the result.
- Reschedule does not fire a target early and resolves it the next day when prerequisites still hold.
- Domino guarantees at most one newly eligible child and does not bypass child requirements.
- Crossing the Reality Strain threshold schedules a visible correction rather than an immediate invisible penalty.
- Success and failure both award Merit once; permanent upgrades survive restart; autosave restores a run.
- Each daily resolution is bounded; causal provenance contains a valid source for every prerequisite.

## Manual UX test on actual Deck (not yet performed)
- Launch game with controller; never touch touchscreen or mouse.
- A selects, D-pad navigates, X approves, Y advances, B clears, LB/RB cycle stamps.
- Read chance, required facts and outcomes from normal handheld distance at 1280x800.
- Suspend mid-case; restore. Close and relaunch; resume. Test after case payout.
- Test 16:9 monitor, handheld 16:10, and alternate resolutions.
- Confirm game remains responsive on a low battery / lowered TDP profile.

## Early playtest notes to collect
- Seed, action sequence, outcome, run duration, cause-chain depth, decisions understood, moments of surprise, confusion points, second-run intent.
- First 20 seeds: percent completed, min/median/max support, mean number of triggered events, longest linked chain, number of choices presented each day.
