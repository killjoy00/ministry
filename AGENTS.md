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
