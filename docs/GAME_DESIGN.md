# THE MINISTRY OF COINCIDENCES
## Game design document (living) — v0.1, 2026-11-07

> **Nothing happens by accident. Especially accidents.**

**Genre:** 2D, turn-based, incremental roguelite / systemic cause-and-effect strategy  
**Target:** Steam Deck first; Windows and Linux desktop; offline single-player  
**Engine:** Godot 4.7.2 (GDScript, no runtime LLM or backend)  
**Audience promise:** In each short case, solve an absurd assignment by turning harmless mishaps into auditable chains of extraordinary outcomes. Advance from junior clerk to a bureaucrat capable of manipulating the universe.

## 1. Pillars (ranked)

1. **I made that happen.** Players can explain why the outcome occurred. Every event keeps its causal provenance; surprising does not mean opaque.
2. **The universe surprises me.** Systems combine so that the best outcomes are partially unplanned. Multiple valid solutions per case.
3. **Astonishing escalation.** Permanent progression unlocks types of causality, combinations, and scale, not simply bigger percentages.
4. **Deadpan whimsy.** A goose winning an election is reported as routine public-sector business. Character jokes are supplemental; systems are the comedy.
5. **Handheld-first agency.** Brief decisions, satisfying payoffs, large text, native controller support, and instant suspend/resume.

### Non-goals

- Reflex/action combat; sprawling real-time NPC simulation; freeform generative-AI storytelling; online infrastructure; grindy idle-only progression; realistic electoral simulation.
- A full Steam release or Steam Deck Verified claim before tested builds exist.

## 2. Player fantasy and presentation

You are a minor official at a secret Ministry that balances probability. Your desk contains assignments, certified rubber stamps, forms, and Reality's Ledger. Below your office sits a lovingly illustrated tiny town. Characters follow agendas; small incidents influence meetings, rumors, relationships, and policies.

**Tone:** Terry Pratchett-like bureaucratic absurdity in *spirit*, but no borrowed characters, text, worldbuilding, or art; 1950s paperwork and warmly illustrated small-town dioramas. No need for spoken dialogue. The Ministry treats the preposterous with utter seriousness.

**Core screen:** case file (goal + deadline), town/event opportunities, four stamps, Reality's Ledger, cause/effect chronicle. The player reads the story through event cards, not long dialogue trees.

## 3. Core loop

1. Receive a procedurally varied case: objective, deadline, neighborhood conditions, and personalities.
2. Inspect **currently possible events**, including probability, prerequisites, downstream effects, and causal sources.
3. Approve **one intervention per day** (or abstain); spend Influence, raise Reality Strain.
4. Advance the clock. Ordinary events resolve by seeded randomness. Triggered events cascade, with provenance recorded.
5. React to the results and to scheduled **Reality Corrections**; try to achieve the absurd objective by its deadline.
6. Receive Civil Service Merit on success or failure, unlock department upgrades, and file a new case.

**Target length:** first cases 3–5 minutes; later 8–15 minutes. Early decisions should happen every 15–40 seconds, with a single day resolution taking <2 seconds in normal play.

## 4. The causal event engine

### Event data contract

Each event has: stable ID, short name, narrative, base probability, persistent prerequisites (`all`, `any`), outputs (facts/stat changes), repeat policy, potential alternative effect when Misfiled, and an explicit source of any spawned chain.

- **Facts** are binary and persist through a case unless specifically expired.
- **Stats** (e.g. public support) accumulate.
- **Probability** is deterministic for a given seed + action sequence; use a locally seeded RNG and journal every roll in debug mode.
- **Chain**: resolving one event introduces facts that enable other events. Newly enabled rules are attempted in the current day's resolution; each rule is attempted at most once per day and fires at most once per run in v0.1.
- **Cause tracing**: every fact stores the event that produced it. Event log displays its enabling causes; the ledger never claims causation without a corresponding recorded fact.
- **Bounded simulation**: at most 32 events per day; bounded resolution passes to prevent runaway cascades.
- **Opportunity visibility**: player can see plausible upstream events, odds and the next unlocks, but not guaranteed solutions.

### Example causal branches: "A Fowl Election"

- Weather: rain → indoor parade → disrupted mayoral address → goose on stage → mistaken photo → celebrity → nomination.
- Food: abandoned sandwich → goose pursues sandwich → accidental public appearance → amusing coverage → public support.
- Paperwork: lost letter → altered eligibility filing → goose eligible for office → petition.
- Backlash: overuse probability stamps → correction gust → campaign posters blow away → substitute goose publicity.

These are **rules**, not a fixed screenplay. Exact event combinations depend on intervention and random outcomes.

## 5. Intervention stamps

All stamps apply to one eligible future event. Exactly one can be approved per day; there is an explicit option to clear the approval before advancing.

| Stamp | Cost (prototype) | Effect | Player question |
|---|---:|---|---|
| **Nudge** | 2 Influence, +2 Strain | +55 percentage points to an event's chance this day (capped at 98%) | Which unlikely event needs help? |
| **Misfile** | 3 Influence, +3 Strain | +40 points and replace selected outcome with a designated plausible alternative | Who or what should receive this consequence instead? |
| **Reschedule** | 2 Influence, +1 Strain | Prevent today's event; guarantee it tomorrow if still valid | When does this need to happen? |
| **Domino Permit** | 3 Influence, +3 Strain | +25 points to selected event and guarantee its first newly enabled child if it triggers | Where would one cascade be most useful? |

No stamp should make a case an automatic win. Misfile is offered only when an event has a defined alternative. Stamp effects are previewed before commitment.

## 6. Reality Pushback

Influencing the world accumulates **Reality Strain**. At a threshold, the Ledger schedules a correction next day, with a specific forecast. This must be **telegraphed**, **deterministic**, **mechanically legible**, and **usable as a strategic resource**—not a random punitive meteor.

Examples: an intense gust shifts posters; a misplaced appointment causes an unexpected meeting; an unseasonal shower moves the press indoors. Advanced builds can redirect or exploit corrections deliberately.

Prototype: threshold 6 Strain; when crossed, queue one correction for the following day, decrement Strain by 6; show it on the HUD. One correction can create facts enabling follow-up rules. Later progression introduces correction types and exchanges of risk for opportunity.

## 7. Case structure, challenge, and success

- **Core:** goal + deadline + special constraints, visible before play.
- **Prototype:** A Fowl Election. Make Gerald the Goose a sufficiently well-supported, legitimate candidate by end of day 7. Several event paths build support/legitimacy.
- **Later cases:** The Bakery That Bought the Bank; Thursday Has Been Cancelled; Two Strangers, One Umbrella; Seventeen Raffles; The World's Unlikeliest Apology.
- **Loss:** deadline or irreparable constraint failure. Losing still grants reduced Merit. Players should not be forced to reset without progression.
- **Scoring:** grade success, causal depth, clever use of corrections, and unspent influence. Reward meaningful alternative approaches rather than a single optimal script.

## 8. Long-term incremental loop

**Currencies:** Influence (per-run interventions), Reality Strain (risk / opportunity), Civil Service Merit (permanent progression), later Policy Exceptions (high-tier rule editing). Avoid more currencies until playtests demand them.

Permanent upgrades in the first prototype:

1. **Better Desk:** increases maximum Influence.
2. **Fresh Ink:** increases starting Influence.
3. **Audit Training:** reduces Strain added by stamps.

Beyond prototype, persistent department upgrades affect **which mechanisms are available**, not only quantities:

- Lost Property: misdirected objects trigger secondary events.
- Fortuitous Timing: events coinciding on the same day amplify one another.
- Minor Embarrassments: social mishaps produce Influence.
- Statistical Compliance: high-strain play becomes manageable.

Long-term ranks: Junior Clerk → Senior Coincidence Officer → Regional Director of Happenstance → Undersecretary of Improbability → Acting Deputy to the Universe. The scale graduates from a town to a region, a planet, then causality itself. *Do not build those scales before the single-town engine works.*

## 9. Replayability and procedural generation

Do not generate arbitrary nonsense. Generate varied **situations** from curated, composable rule families:

- Shuffle initial conditions, residents' relationships, objectives, event likelihood bands, neighborhoods, and deadlines.
- Expose a reproducible run seed to debug failures and share entertaining cases later.
- Constrain combinations so a solvable path always exists; use offline seed testing to measure chance of solution.
- Keep multiple mechanistically distinct paths open in each case; avoid hidden mandatory event sequences.

## 10. Deck UX and accessibility

- Design at 1280x800; support window resize and 16:9 safely.
- Full gamepad operation without touchscreen or mouse. D-pad selects focusable controls; A confirms; LB/RB cycle stamps; Y advances a day; X approves selected event; B clears pending intervention. Provide matching keyboard inputs.
- Render base body text around 20–24 px; contrast-conscious parchment/ink palette; no tiny probability readouts.
- Offline saves, no account, no backend, autosave after every resolution, reliably restore after system suspend.
- Use restrained animation with skip option; no rapid strobing; status conveyed in text, not color alone.
- Never describe the game as "Deck Verified" before Valve verifies a shipping build.

## 11. Technical architecture

- **Godot 4.7.2/GDScript** with event engine independent of scene/UI. Content in data definitions, not scene branches.
- `scripts/simulation/case_simulation.gd`: seeded RNG, facts, provenance, event resolution, stamp rules, reward logic, profile persistence.
- `scripts/scenarios/fowl_election.gd`: event catalog and case setup.
- `scripts/main.gd`: controller-first view layer; no business rules.
- `tests/smoke.gd`: headless engine tests on seeded event, stamps, corrections, save/replay invariants.
- `docs/TEST_PLAN.md`: balance and usability gates.
- `save.json`: versioned local user save. No personal data or telemetry in first build.
- GitHub Actions (when the repo exists): import and run Godot headless tests on PR, then export Windows/Linux snapshots on tagged releases. No Vercel, external databases, or paid infrastructure.

## 12. Build phases and gates

| Phase | Deliverable | Exit gate |
|---|---|---|
| **0 — Playable toy** | Single-town case, real causal event rules, four stamps, correction, end result, local merit and upgrades | Player can create a visible 3–5-event cascade; no mouse required |
| **1 — Fun proof** | 10–20 tested seeds, UI polish, cause-tree inspection, balancing | Multiple solutions; player understands causation; 3+ voluntary repeat runs in playtests |
| **2 — Content proof** | 3 distinct cases, personality modifiers, ~60 reusable event rules | Rules recombine across cases instead of scripted-case bloat |
| **3 — Incremental proof** | Departments and meaningful permanent unlocks | Progression changes strategies, not merely win rate |
| **4 — Deck proof** | Native Linux and Windows builds, suspend/resume, on-device input/performance/legibility pass | Tested on actual Deck hardware; no controller dead-ends |
| **5 — Steam demo** | Menus, accessibility, presentation, sounds, stability, compliance | End-to-end playable demo; feedback instrumentation optional and opt-in |

## 13. Quality rubric

Each playtest session asks:

1. Did the player understand **why** the major event occurred? (target: 90%)
2. Did anything genuinely unexpected yet logical happen? (target: majority of runs)
3. Did a decision change the outcome? Can the player name it?
4. Did Reality Pushback feel like an opportunity rather than a tax?
5. Did they willingly start another run?
6. Could they play entirely with a Deck controller and read all relevant details?

Never accept an event graph that is *technically* connected but narratively arbitrary. Author causal rules as self-contained, testable contracts.

## 14. Open questions (defer until after prototype)

- Town simulation view versus filing-cabinet-only UI: prototype starts card-first; add animated town only if the mechanic earns it.
- How much additional hidden information improves replayability without eroding fairness?
- Final victory thresholds and session length must be tuned from instrumented seed simulations.
- Pricing, release date, trailer, store page, and monetization are deliberately out of scope.

## 15. Current implementation status

This document is a *target*, not proof of release readiness. The initial prototype implements the core loop only. Linux/Windows exports and actual Steam Deck testing remain unverified until built and run in the target environment.
