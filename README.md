# The Ministry of Coincidences

*Nothing happens by accident. Especially accidents.*

A Steam Deck-first, offline, turn-based incremental roguelite about arranging improbable causal chains with government-approved rubber stamps.

## Status

**Pre-alpha prototype**. One playable case: **A Fowl Election**. The game is not yet released and is not certified or tested on Steam Deck hardware. This repository starter contains source, a full design doc, Godot headless smoke tests, and on-demand export workflows. See [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) and [`docs/TEST_PLAN.md`](docs/TEST_PLAN.md).

## Run

1. Install [Godot 4.7.2 stable](https://godotengine.org/download/archive/4.7.2-stable/).
2. Open `project.godot` in Godot.
3. Press F6/F5 to play the main scene.
4. Use mouse/keyboard or a controller. **D-pad** navigates, **A/Enter** selects, **LB/RB or Q/E** cycles stamps, **X/F** approves a stamp, **Y/Space** advances the day, and **B/Escape** clears a queued intervention.

## Gameplay

- Each case lasts seven days. Manipulate daily opportunities and cascade through linked event rules.
- Four different stamps: Nudge, Misfile, Reschedule, and Domino Permit.
- Reality Strain creates a forecast correction which can become an opportunity.
- Win or lose, gain Civil Service Merit and buy permanent desk upgrades.
- Reproducible seeds, transparent cause log, automatic local saving.

## Test

```bash
godot --headless --path . --script res://tests/smoke.gd
```

## Architecture

- `scripts/scenarios/fowl_election.gd` — initial case rules and text.
- `scripts/simulation/case_simulation.gd` — state transitions and deterministic event engine.
- `scripts/main.gd` — presentation and input bindings.
- `docs/` — design decisions, acceptance tests.
- `.github/workflows/` — CI definition, active after publishing to GitHub.

Run `python3 tests/validate_catalog.py` for an additional offline catalog/balance check. GitHub Actions runs the real engine tests on PRs, and `Build Windows and Linux prototypes` generates downloadable binaries when manually dispatched or when changes are pushed to `prototype-build`.

No paid services, online accounts, telemetry, or backend required.

## Art direction

The playable interface is designed as a hand-illustrated mid-century Ministry case file, with original SVG art of Oddford and Gerald, illustrated event icons and individual stamp seals. The design guide is [docs/ART_DIRECTION.md](docs/ART_DIRECTION.md).
