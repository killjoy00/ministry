# Living Oddford — character choreography
The town is a **paper-theatre replay of the deterministic case log**, not an independent simulation.
Only recorded incident IDs trigger an animated scene. Visuals cannot create events, change probabilities or rewards, or fabricate parent links.

## Gameplay
- Six existing illustrated portraits become lightweight, animated cutouts.
- On the recorded `goose_stage` incident Gerald waddles from the plaza onto the stage; the mayor gives way and the reporter and baker react.
- Other documented scenes animate paper deliveries, sandwiches, wet parades, public reporting, correction winds and civic ceremonies.
- Gold causal arrows use the **actual parent event IDs** recorded in the case ledger, and support popups use the ledger's actual support gain.
- Event reports hide location markers to make the cast visible; the clickable location markers remain in town investigation mode.
- X on controller, R on keyboard, or the on-screen toggle enables **reduced motion**, which snaps every actor to the last pose. The option is saved offline.
- LB/RB navigates report steps; Y/Space skips; B/Escape returns. The existing Oddford Waltz and music settings remain unchanged.

## Implementation
- `scripts/ui/character_choreography.gd`: authored event-to-stage blocking (not live-generated behavior)
- `scripts/ui/paper_actor.gd`: inexpensive cutout footsteps, idle bob and reaction poses
- `scripts/ui/living_town.gd`: replay wiring and reduced-motion setting
- `scripts/ui/town_fx.gd`: source-backed causal arrows
- `tests/character_animation_smoke.gd`: Godot regression

This is a playable animation pass, **not** a free-roaming NPC simulator or hand-drawn frame-by-frame sprites. Actual Steam Deck input, performance, suspend/resume, and audio playback still need hardware verification.
