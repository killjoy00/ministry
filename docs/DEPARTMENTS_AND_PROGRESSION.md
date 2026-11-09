# The Ministry's Departments — playable progression, v0.3

**Nothing happens by accident. It now requires a departmental sign-off.**

Departments are **permanent licenses bought with Civil Service Merit after a case**. You then assign a small roster to work on your *next* case. The licensed departments remain yours forever; the assigned roster stays fixed until that case ends. You can inspect the Ministry during a case, but cannot cheat by changing the roster mid-run.

## Career and staffing

- Start with **2 active office slots**. License at least **4** departments to open a third slot, **8** for a fourth and **12** for a fifth.
- To purchase an office you need its listed Merit cost and at least the listed number of completed cases (wins and losses both count). No extra currency or grinding through paid content.
- The first available slots auto-assign freshly purchased offices; once full, a purchase is stored but not staffed. Use **Stand Down** and **Assign** to try different combinations.
- Career titles advance from Junior Clerk to Senior Coincidence Officer (2 licensed), Regional Director (4), Undersecretary (8), and Acting Deputy to the Universe (12).
- The existing Better Desk / Fresh Ink / Audit Training upgrades remain available and keep working.
- All forced incidents still require their real event-rule prerequisites. Department actions appear in the Chronicle. Automatically synchronized but unrelated incidents are **not falsely labeled as cause and effect**.
- A standing Ministry may automatically guarantee **at most two incidents per day in total**, shared by Timing, Postal Inspector, Knock-On Effects and Self-Filing Paperwork. Explicitly paid stamps do not use that free approval budget. This is to preserve decisions instead of producing a screensaver.

## The twelve departments

| Office | Merit | Cases completed | Mechanic, not a passive percentage |
|---|---:|---:|---|
| Department of Lost Property | 7 | 0 | First eligible postal or high-street misdirection **takes its alternate outcome** automatically. Changes which facts exist. |
| Office of Fortuitous Timing | 9 | 0 | Once/day, synchronize a second **eligible** incident at the same location; its relationship is timing, not false prerequisite causation. |
| Minor Embarrassments Division | 9 | 0 | First daily social blunder produces a new gossip fact and one Influence. Gossip can initiate a distinct Gazette follow-up. |
| Inspectorate of Misplaced Mail | 11 | 1 | The first real postal incident each day **guarantees an eligible consequence it just enabled**. |
| Department of Double Booking | 14 | 2 | **Two different paid stamps in one day**, with both Influence costs and Strain. The second can be changed before filing. |
| Office of Convenient Appointments | 15 | 2 | Rescheduling an event **also guarantees another eligible event** at the same location tomorrow. |
| Bureau of Parallel Outcomes | 17 | 3 | First applicable event per day may produce both its normal and alternate factual consequences. |
| Official Rumour Mill | 18 | 3 | First public-support incident daily creates a public-interest fact; a distinct news event can propagate that fact. |
| Reality Reconciliation Office | 21 | 4 | The first scheduled Reality Correction each day also realizes a second, different correction's facts, separately journaled. |
| Knock-On Effects Authority | 24 | 4 | The first newly eligible child incident daily is **guaranteed** instead of rolled. |
| Appeals and Second Chances | 28 | 6 | The first failed stamped attempt per day is filed for a **guaranteed next-day retry**, if it remains eligible. |
| Office of Self-Filing Paperwork | 36 | 8 | Automates **up to two new multi-prerequisite chain links daily**, subject to the common two-free-approvals budget. |

## Examples of loadouts

- **Errant Mail:** Lost Property + Postal Inspector. A stray invitation may choose a goose rather than a mayor, then automatically unlock the next postal consequence.
- **Auspicious Calendar:** Fortuitous Timing + Convenient Appointments + Double Booking. Set up collisions in a single place, and spend two stamps to steer the date.
- **The Publicity Department:** Minor Embarrassments + Rumour Mill + Parallel Outcomes. A diplomatic blunder produces a newspaper story, then a headline sets off another chain.
- **Causality Factory (late career):** Reality Reconciliation + Knock-On Effects + Self-Filing Paperwork + Second Chances + Lost Property. The Ministry can build lengthy chains, but the player still chooses the case's direction with paid stamps.

## Technical invariants

- `department_catalog.gd` is the **only source** for department IDs, names, costs and case prerequisites. `case_simulation.gd` supplies the functional rules, with no hidden backend.
- `profile.departments` stores owned offices, `profile.equipped` stores the next-case loadout, and `run_departments` is the immutable roster for the current case.
- `SAVE_VERSION=2` accepts **v1 saves**, retaining all existing Merit, cases, Desk, Ink and Audit progress. Existing cases resume with no departments until the next run.
- The engine resolves a maximum of 32 physical incidents a day. Per-day department triggers are capped and the random number generator remains seeded.
- Automatic effects are **not staged as player purchases** and cannot subtract more Influence than available. Real auto effects and their source facts are recorded, and rule-derived cause IDs refer only to actual source events.
- For pre-release, see `tests/departments_smoke.gd`, `tests/departments_ui_smoke.gd`, and `tests/department_balance.gd`.

## Balance observations, November 2026

On 250 fixed seeds with **no player interventions**, the original unstaffed case won 26 times (10.4%), with 11.9 physical incidents per run. An intentionally powerful five-office automation loadout won 128 (51.2%), with 19.5 incidents and 6.4 recorded office actions per run, but did not win every case. These are **simulation outcomes, not human win rates**. The later-game case catalog will require tougher objectives as the Ministry becomes stronger. We should tune department costs and combinations based on real playtesting, not force all offices to be equally strong.

## Next content milestone

Add 2–3 genuinely distinct cases with new success constraints and reusable causal rules. Long-term progression should unlock **new kinds of causality and increasingly challenging files**, not just trivialize Gerald's election. The Ministry's very first case must remain readable, playable and winnable with no department licenses.
