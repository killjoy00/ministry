# Causality Theater — a short daily payoff (v0.6)

When a player advances the day, the Ministry presents a **2.73-second illustration-driven reconstruction** rather than forcing them to watch several seconds for every resolved incident. This is a presentation-only change: it never rolls probabilities, changes state, or invents events.

## The sequence

1. **0.00–0.41 s — File stamped.** A stamped seal lands on the Oddford diorama with an existing, locally synthesized rubber-stamp impact. When the player filed nothing, the official seal appears instead, clearly labeled as *natural events only*.
2. **0.57–2.30 s — What actually happened.** Up to four recorded incidents appear, in historical order, with illustrated incident cards, a matching paper character and a tiny location-based movement. The set favors actual stamped outcomes, material support gains and events linked to further outcomes. The theatre does not invent actions to fill the cards.
3. **2.73 s — Register completed.** The actual total number of incidents, momentum delta, and start/end reality strain appear. If more incidents happened than can be shown, the report says how many more are in the Chronicle. The result stays on-screen until the player returns or opens the full replay.

A brass-dotted connector appears **only** between cards where the latter incident's `causes` array explicitly references the former incident's `id`. This includes non-adjacent cards and never links unrelated incidents just because they appear beside each other. When a parent is not in the four-card subset, the line is omitted (its exact provenance is still in the full Chronicle).

## Controls and access

- **A / B / Enter / Escape** (or the visible button): return to the case. B can exit immediately even during the animation.
- **Y / Space**: skip the animation and reveal the complete result immediately.
- **X / R**: open the original full chronological Oddford town replay to examine all incidents at leisure. Its LB/RB step controls and `X` motion preference still work.
- **Mouse:** all three actions are available as buttons.
- **Reduced motion:** respects `user://ministry_visuals.cfg` from the town view. It immediately shows static evidence and the summary, without camera motion or animated cutouts. No new setting or save migration is required.

The player can advance another day normally after closing the theatre. The current case and permanent Ministry profile are unchanged. This replaces the automatic multi-second-per-event replay but *not* the full replay itself.

## Acceptance and evidence

- `tests/daily_theater_smoke.gd`: exact history-only replay, stamp capture before resolution, 1–4 visible cards, real causal arrows only, summary value equality, controller button positions, skip, full replay, and no simulation changes.
- `tests/living_town_smoke.gd`: full chronological replay remains reachable from the brief daily stage.
- Existing gameplay, stamped intervention, saved progression, story art, 1280×800 UI, and assignment balance tests remain in CI.
- Local Linux 1280×800 visual snapshots for the active card stage and the completed register are available in the test workspace; physical Steam Deck and Windows hardware validation are still outstanding.
