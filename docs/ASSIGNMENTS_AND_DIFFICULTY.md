# The Ministry's case desk — escalating assignments (v0.4)

*The universe has filed a number of increasingly unreasonable requests.*

This release adds **three distinct harder assignments** alongside *A Fowl Election*. Each case uses the same seeded causal engine and the same twelve permanent departments; no online service, AI storyteller, or new currency is involved.

## The four playable assignments

| Case | Unlock after | Days | Goal requirements | Case momentum | Daily natural incidents | Base Influence restored/day | Extra Merit on win |
|---|---:|---:|---|---:|---:|---:|---:|
| A Fowl Election | available immediately | 7 | Gerald certified as a candidate | 15 | 2 | +2 | +0 |
| The Bakery That Bought the Bank | 2 cases filed | 8 | Bakery solvent + backers verified + signed bank transfer | 19 | 1 | +2 | +4 |
| Thursday Has Been Cancelled | 5 cases filed | 8 | Calendar revised + public compliance + Thursday legally canceled | 22 | 1 | +1 | +7 |
| The World's Unlikeliest Apology | 9 cases filed | 8 | Apology delivered + accepted + bakers reconciled | 21 | 1 | +1 | +11 |

Cases filed includes victories and failures, so a player can always reach new story material even while learning. Later cases reward successful planning with more Merit. This is a **single shared persistent Ministry**, not four separate profiles: bought departments and equipped loadouts carry into the next chosen assignment.

## What makes a case harder?

- **Different victory conditions.** No number of influence points can replace mandatory facts. Nora must actually acquire the bank; canceling Thursday requires both a signed exception and residents following it.
- **Fewer spontaneous incidents.** Harder cases have one randomly offered natural incident each day instead of two. Players must be more deliberate about where to intervene.
- **More complex chains.** Later cases rely on multi-prerequisite events and branching interactions among post, bakery, town hall, public gardens and press.
- **Tighter administrative resources.** Advanced and exceptional cases restore only one Influence per day. Better Desk, Fresh Ink and departments therefore matter more.
- **Shorter cascade bursts.** Advanced cases restrict resolved incidents to 7/5 a day, versus the original engine limit of 32; stalled but still-eligible events can be pursued on later days. No event or impossible fact is invented to fill a quota.

## Example solution paths (not required scripts)

**Bakery:** A pastry rush or a fair prize improves Nora's accounts; meanwhile, a misplaced receipt, a redirected statement, or an audit identifies a bank opportunity. A press story or receipt helps attract backers, then the bid and transfer require actual financial proof. *Lost Property*, *Postal Inspector*, *Parallel Outcomes* and *Fortuitous Timing* are particularly helpful, but not required.

**Thursday:** A misprinted almanac, disputed town clock, or displaced public transport generates scheduling confusion. A school trip and petition create public agreement, while the council must make the exception official. *Convenient Appointments*, *Double Booking*, and *Fortuitous Timing* create strong calendar-focused combinations.

**Apology:** An incorrect recipe delivery, unexpected kindness, or shared pastry disaster creates an opening between the rivals. Mediation and genuine trust must lead to delivery and acceptance of an apology, followed by a publicly recognized reconciliation. *Second Chances*, *Knock-On Effects*, and *Self-Filing Paperwork* can preserve crucial late-stage links.

Every event is authored as a reusable prerequisite/effect rule. The outcome is a consequence of facts that really happened, not a fixed screenplay or a fabricated narrative.

## Case selection and old saves

After a case ends, **File Another Case / Choose Assignment** opens a full-screen, D-pad-accessible dossier with portraits, objectives, unlock requirements, and bonus Merit. Press A to start one and B to return. The assignment and equipped departments are snapshotted for the run. There is no switch mid-case.

Save schema **v3** adds `case_id` and per-case wins to the existing v2 department profile. v1 and v2 saves still load as the original goose election, preserving Merit, completed cases, licenses and equipped offices. Cases already filed count toward the new unlocks. The seeded engine can resume the chosen assignment without changing its underlying rules.

## Actual-engine balance audit (240 fixed seeds each)

These are **deterministic strategy simulations**, *not estimates of human success*. The purposeful strategy makes one Nudge approval per day when available, prioritizing the next relevant case event. The equipped strategy adds a powerful five-department roster.

| Case | No intervention | Purposeful Nudges | Nudges + five departments |
|---|---:|---:|---:|
| Election | 25 / 240 | 232 / 240 | 240 / 240 |
| Bank | 0 / 240 | 86 / 240 | 207 / 240 |
| Thursday | 0 / 240 | 45 / 240 | 193 / 240 |
| Apology | 0 / 240 | 24 / 240 | 198 / 240 |

The intended curve is clear in the purposeful-only column. An extremely strong late-game department setup can make those harder cases substantially easier, which is the incremental reward. This deliberately is **not yet a prestige mode**; future progression should introduce higher risk, changing case constraints and new causality types without removing accessibility for players who are still learning.

The tests assert that cases remain solvable and deterministic, all win-condition facts are causally reachable, no locked assignment can be selected, and no result awards Merit twice. `tests/assignments_balance.gd` and `tests/assignments_smoke.gd` provide the executable contracts.

## v0.5 balance after the Oddford incident atlas expansion

The table above is the **v0.4 baseline** before the new incident branches. The expanded catalog adds alternative ways to reach mandatory facts, so the same 240-seed strategy audit has been rerun in actual Godot 4.7.2. These are deterministic agent strategy simulations, not human win-rate estimates:

| Case | No stamp | Purposeful Nudge | Nudge + five departments |
|---|---:|---:|---:|
| Election | 21/240 | 230/240 | 240/240 |
| Bank | 0/240 | 128/240 | 211/240 |
| Thursday | 0/240 | 101/240 | 198/240 |
| Apology | 2/240 | 24/240 | 84/240 |

The advanced cases remain successively harder using the **same strategy**, while installed departments substantially improve success. A broader causal graph also makes more intermediate events possible, so these values are not stable across catalog versions. All four objectives still require their named factual outcomes. See `docs/INCIDENT_ATLAS.md` for the new reusable pathways.

## Future work

Add selectable case modifiers (e.g., a shorter deadline or stricter Reality Strain audit), boss-style auditor assignments, and more genuinely different use cases for the departments. Playtests should inspect whether the new cases produce *clear but unexpected* chains; do not tune solely for target win rates.
