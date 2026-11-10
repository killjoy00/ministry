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

## Department and promotion regression

Run `godot --headless --path . --script res://tests/departments_smoke.gd`, `.../tests/departments_ui_smoke.gd`, and `.../tests/department_balance.gd` in CI and before building. Check all 12 offices, rank thresholds, caps on active offices, explicit Merit costs, old save compatibility, unchanged seeded baseline, procedural activation of each unique mechanic, real provenance (no phantom source events), and bounded automation (maximum two free guaranteed incidents/day; maximum 32 fired rules/day).

The Steam Deck board must show all 12 department cards, fit a 1280x800 viewport, support D-pad focus and A/B, and prohibit purchases/reassignment until the case is settled. Test specifically that Double Booking cannot overspend Influence and that a paused or resumed run cannot equip offices after it begins.

## v0.4 assignment catalog acceptance

Run `godot --headless --path . --script res://tests/assignments_smoke.gd` for solvability, per-case constraints, seeded replay, unlock gates, migration and no duplicate Merit. Run `assignments_ui_smoke.gd` for the controller-selectable dossier and dynamically labeled case HUD, then `assignments_balance.gd` for meaningful challenge scaling across 240 fixed seeds. Existing simulation, department, audio and character animation tests remain mandatory.

## First-day briefing and causal inspector regression

Run `godot --headless --path . --script res://tests/onboarding_causality_smoke.gd` on PR and export. Verify isolated practice, four steps, real recorded sources, normal/Misfile alternative routes, correctly labelled conditional chances, no phantom future events, and no changes to real Merit or case saves. The seen preference is stored separately at `user://ministry_briefing.json`.
