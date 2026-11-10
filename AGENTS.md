# Instructions for AI development agents

This is a **Steam Deck-first** offline Godot game. The authoritative requirements are `docs/GAME_DESIGN.md` and `docs/TEST_PLAN.md`.

## Development protocol

1. Prioritize a fun, transparent causal event engine before artwork, menus, content, marketing, or Steam integration.
2. Before changing core event rules, preserve determinism, causality provenance, simulation bounds, and at least two legitimate case solutions.
3. Use pull requests, small scoped commits, and automated tests; avoid altering other repositories or production systems.
4. `godot --headless --path . --script res://tests/smoke.gd` must pass. `python3 tests/validate_catalog.py` supplements but never replaces runtime tests.
5. Maintain controller-first focus navigation; never introduce mandatory mouse/touch interactions. Test at 1280x800.
6. Update the GDD's implementation status and open questions when design decisions change.
7. Do not create a backend, Vercel deployment, account system, paywall, telemetry, or online dependency without explicit approval.
8. Do not describe the game as Deck Verified until Valve confirms that status.
9. For game content, prefer small data-driven reusable rules over case-specific scripted sequences.
10. The player is a non-programmer on a mobile device; automate build/test and provide downloadable build artifacts, not local shell instructions as the default route.

## Next work, in order

- Get Godot CI actually green and export one runnable Linux binary.
- Run 20–100 deterministic seeds; tune support threshold and event odds.
- Inspect the game on an actual Deck; improve navigation/focus and legibility.
- Add an in-game "why" causal tree and better branch-choice previews.
- Playtest 3–5 minutes per run; validate whether players deliberately start another case.
- Only then add 2 new cases based on the shared rule engine.

## Department progression gates (November 2026)

The twelve department IDs, costs and prerequisites live in `scripts/simulation/department_catalog.gd`; their event-system effects are in `scripts/simulation/case_simulation.gd`. Keep `docs/DEPARTMENTS_AND_PROGRESSION.md` in sync with every change. Do not implement new departments as passive numeric bonuses; every office must change factual outcomes, eligibility, intervention capacity, scheduling, or autonomous causal chain resolution. Preserve 2–5 case-snapshotted loadout slots, no mid-case purchases/assignment, two shared free approvals/day, and lossless v1 save migration.

Run the department simulation, UI and 250-seed balance tests on PRs and build jobs. Compare unstaffed/fully staffed behavior, causal provenance and bounded resolution. The game is still not Deck Verified.

11. Every new assignment must specify real required facts, a distinct objective, unlock threshold, deadline and balance tests. Preserve v1/v2/v3 save migration, case-specific seeded replay and department effects.
12. Do not assume that raising a support threshold makes a case harder; seeded simulations must compare natural wins, purposeful stamps and staffed runs.
