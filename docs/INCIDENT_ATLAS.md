# Oddford incident atlas — replayable causal branches (v0.5)

The incident catalog is the game's story engine, **not** a deck of random flavour cards. A stamped incident still uses real rules: requirements, conditional chance, consequences, and recorded causal sources. Natural incidents may happen without the player's intervention. Each authored event fires at most once per run.

## What changed

- **109 new unique incidents**: 16 reusable civic/post/bakery incidents, plus 24 goose-election, 22 bank-takeover, 24 missing-Thursday, and 23 reconciliation incidents.
- **70 possible incidents** in *A Fowl Election*, **65** in *The Bakery That Bought the Bank*, **67** in *Thursday Has Been Cancelled*, and **66** in *The World's Unlikeliest Apology*. These are **catalog sizes**, not promises that every incident will occur in one run.
- Every new incident has a recorded prerequisite; the initial pool stays at 7–10 eligible root incidents per assignment. New incidents unlock in response to things that actually happened rather than flooding the first day.
- No new currency, department, case objective, backend, random outcome outside the simulation, or required art asset. Existing illustration families can stand in for the new episodes; bespoke scene art can come after early player feedback.
- Original episode rule IDs and the original 4 assignment win conditions stay intact. Existing saves continue loading without a schema migration; a build update changes the future event catalog, so identical seeds played in **different versions** need not resolve identically.

## How the stories expand

| Case | Additional alternative pathways | Causal purpose |
|---|---|---|
| **A Fowl Election** | Empty lectern → goose stand-in → reporter's wire → petitions; bakery ribbon → sash → civic acclaim; copied ballot → an eligibility exception | Several paths to candidacy, public support and a photograph without a compulsory single screenplay |
| **Bakery Bought the Bank** | Accounted-for queues → verified takings → solvency; vault moth → reserve audit → bank weakness; investors' tea → subscription book → verified backing; lunch meeting → legal deed | Capital, bank vulnerability and legal ownership must still be established independently |
| **Thursday Cancelled** | Railway timetable → clock dispute → council calendar; drivers' petition → public agreement; school closure and merchants' schedule; council decree → revised calendar → formal deletion | Institutional and public compliance become distinct branches, not just an ever-growing score |
| **Unlikeliest Apology** | Old custard receipt → shared apprenticeship → doubts; shared delivery → kindness; mutual recipe → trust; typed apology → delivered reply → joint bakery | Reconciliation remains an earned consequence with multiple contributing routes |

### Shared threads across cases

A waterlogged ledger can lead to a recovered register; late buses can prompt a clerk's inspection; free bakery samples can affect finance or an election; the Gazette may need to print an official correction; and a public gathering can become a council hearing. These events are authored **once** and reused consistently across several assignments. Each case only includes shared threads whose prerequisites can be produced in that case.

## Scope and mechanical limits

New incidents are mostly small upstream causes (zero momentum), with **modest +1 momentum** at significant turning points. Stamp costs, Influence regeneration, Reality Strain, department budgets, objective facts, deadlines and natural incident draws are unchanged. Later cases still limit successful incidents per day (bank 9, Thursday 7, apology 5); new consequences do not bypass those limits.

Some outcomes are alternate producers of an established fact (for example, a second way to secure a petition or transfer). A fact's recorded source remains the **first real incident** that created it; speculative links in the inspector are not presented as confirmed occurrences.

## Actual-engine verification

`tests/incident_expansion_smoke.gd` verifies unique IDs, chances, prerequisite producers, static reachability from starting incidents, unchanged case objectives, no new unconditional opening incidents, controller-friendly initial pool, reproducible seeded outcomes, and run-to-run diversity. In the 45-seed exploratory audit with rotating stamp choices, observed *new incident types* were 40 (election), 36 (bank), 37 (Thursday) and 27 (apology). The test proves the new branches can actually occur, not just exist in a catalog.

Run the usual `smoke.gd`, `assignments_smoke.gd`, `assignments_balance.gd`, `departments_smoke.gd`, `onboarding_causality_smoke.gd`, and `incident_expansion_smoke.gd` together before publishing. These are deterministic simulation tests, **not human enjoyment scores**. No Steam Deck hardware verification is implied.

For the first human playtest, prioritize whether these new chains are **understandable and surprising**, rather than treating event count alone as an objective. If players can't identify why something happened, revise the specific rule or the causal inspector instead of adding more content.
