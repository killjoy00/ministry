# First-day briefing and causal evidence — pre-playtest milestone

## Player-facing goal

A first-time player should understand Nudge, probability, Reality Strain, and why a new event followed another event **before** being asked to plan a harder case. The explanation must be a useful tool throughout the game, not a tutorial-only cutscene.

## First-day briefing

- On a new, day-one, unfinished local profile, the game opens Miss Quill's **optional four-form practice briefing**. This appears only once by default; HELP (or **H**) reopens it whenever desired.
- Press **A / Enter** to advance the forms or **B / Escape** to skip. The sequence usually takes under two minutes, but there is no enforced time limit.
- Form 1 introduces the legal absurdity and explains that the tutorial is practice.
- Form 2 presents **An Abandoned Sandwich** at its real base probability and lets the player apply a **Nudge** in a separate seeded practice simulation (seed 1).
- Form 3 explains the conditional probability and advances the practice day through the real deterministic rules engine.
- Form 4 lists **actual journaled** incident titles and sources, including Gerald following the sandwich. It teaches the distinction between forecasts and recorded evidence.
- The practice `CaseSimulation` is constructed with `persist=false`. It never spends real Merit, changes a case, awards rewards, modifies real department loadouts, or overwrites a run.
- Completing or skipping writes only `user://ministry_briefing.json` as a local `seen` preference, separate from the version-3 case save. Existing saves remain compatible; no network account or telemetry is used.
- The automatic popup is suppressed for resumed mid-case games and headless automated test sessions.

## The incident dossier: WHY?

- On an active assignment, select an incident and choose **WHY?** beside the approval controls. **I** opens the same dossier from the keyboard. Existing, recorded incidents in the Chronicle also open their actual dossier.
- Prerequisites are separated into **ALL required** and **at least ONE of these**. Green requirements have actually been recorded, with the recorded source event named when known. Missing ones remain explicit.
- Stamp probabilities are **conditional when attempted**, not promises that a future event will occur. Misfile is labelled unavailable where there is no alternate result.
- The **NORMAL** and **MISFILE ONLY** routes list possible downstream authored rules, distinguish which requirements those new facts could satisfy, and disclose remaining constraints. A potential future consequence is not reported as a historical fact.
- For incidents which occurred, **WHAT ACTUALLY HAPPENED** shows their journaled day, narration, output facts, and **real parent event IDs** from the simulation ledger. Press **A** on a linked recorded parent to inspect it. This view never manufactures extra source events.
- Controller navigation uses D-pad and A, with **B** returning to the case. The modal is scrollable on the 1280×800 Steam Deck viewport.
- Event forecasts use the authored base rule data; current equipped departments, randomness, and the daily incident budget may alter what actually resolves. The dossier is a causal explanation aid, not a guaranteed solver.

## Quality gates

The new `tests/onboarding_causality_smoke.gd` exercises 37+ conditions: valid prerequisite groups, base/adjusted probabilities, distinct Misfile branches, true historical causes, no phantom future events, isolated practice state, and UI navigation at 1280×800.

The full simulation, art, audio, departments, assignments, and balance tests remain required on pull requests and exports. Physical Steam Deck input, legibility, suspend/resume and audio still need human validation.

## First human test

Give the first group the regular fresh-save flow without a verbal walkthrough. Observe whether they can explain why Gerald followed the sandwich, find an unfulfilled prerequisite, make an intervention based on a possible consequence, and independently reopen the dossier from the Chronicle. Record confusion without changing their run for them.
