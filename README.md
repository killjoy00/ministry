# The Ministry of Coincidences

*Nothing happens by accident. Especially accidents.*

A Steam Deck-first, offline, turn-based incremental roguelite about arranging improbable causal chains with government-approved rubber stamps.

## Status

**Pre-alpha prototype**. Four playable cases, from **A Fowl Election** to **The World's Unlikeliest Apology**. The game is not yet released and is not certified or tested on Steam Deck hardware. This repository starter contains source, a full design doc, Godot headless smoke tests, and on-demand export workflows. See [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) and [`docs/TEST_PLAN.md`](docs/TEST_PLAN.md).

## Run

1. Install [Godot 4.7.2 stable](https://godotengine.org/download/archive/4.7.2-stable/).
2. Open `project.godot` in Godot.
3. Press F6/F5 to play the main scene.
4. Use mouse/keyboard or a controller. **D-pad** navigates, **A/Enter** selects, **LB/RB or Q/E** cycles stamps, **X/F** approves a stamp, **Y/Space** advances the day, and **B/Escape** clears a queued intervention.

## Gameplay

- Choose among four assignments with 7–8-day deadlines, different causal goals and increasing pressure. The later cases unlock after 2, 5 and 9 filed cases.
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

## Incremental game progression (v0.3)

The Ministry now has **12 unlockable operational departments** purchased with Civil Service Merit after a case. Choose a 2–5 office loadout in the controller-navigable organization chart. Offices change **actual causality**—misrouted letters, synchronized appointments, parallel outcomes, free knock-on consequences, second stamped approvals, appeals, revised reality corrections, and automatically filed event chains. They do not simply raise damage or income percentages. Everything is seeded, offline and saved, including migration of original save files.

[Read the department roster, costs and combination examples](docs/DEPARTMENTS_AND_PROGRESSION.md). The next milestone adds three harder assignments, with distinct factual success requirements and more rewarding case wins. [Read the case progression and balance audit](docs/ASSIGNMENTS_AND_DIFFICULTY.md).

## First-run briefing and causal evidence (pre-playtest)

Miss Quill offers a skippable four-step tutorial on a new day-one save. In an isolated, deterministic practice case, players Nudge an abandoned sandwich, advance the day, and inspect why Gerald followed it. Practice does not spend real Influence/Merit or change saves; B/Escape skips and **? HELP** / keyboard **H** reopens it.

**WHY?** beside the stamp controls (keyboard **I**) opens an inspectable event dossier: ALL/ANY prerequisite facts and their sources, conditional stamp chances, normal versus Misfile-only potential follow-ups, and real journaled causes. Recorded incidents in the Chronicle link directly to their dossiers. Full D-pad/A/B support. [Read the briefing and causality guide](docs/FIRST_DAY_BRIEFING_AND_EVIDENCE.md).

## Oddford incident atlas (v0.5)

All four assignments now have **109 more hand-authored, fact-linked incidents**: 16 cross-case civic threads plus 93 case-specific incidents. Each assignment has 65-70 possible incidents, but new incidents are conditional, so they do not crowd the first-day options. The same stamped event engine, provenance, department powers, and save system are used throughout. [Read the incident atlas and its seeded-playtest findings](docs/INCIDENT_ATLAS.md).

### Stamp desk

Pick an incident, choose a stamp, then **File Stamp** (X) and **Advance Day** (Y). The preview shows chance and cost; choosing a stamp alone does not apply it. See [Stamp desk guide](docs/STAMP_DESK_GUIDE.md).

## The daily Causality Theater (v0.6)

Advancing the day triggers a brief, skippable storybook reconstruction: one rubber-stamp impact, up to four **actual** recorded incidents with illustrated paper actors and documented cause/effect threads, then the register shows real totals and changes. Press **Y / Space** to skip immediately, **X / R** for the full chronological town replay, or **A / B** to return. Reduced motion is inherited from the town view. This never changes simulation outcomes or permanent progress. See [docs/DAILY_CAUSALITY_THEATER.md](docs/DAILY_CAUSALITY_THEATER.md).
