# Implementation status — first local source milestone

## Available in this starter

- Complete living game design document and explicit test plan.
- Godot 4.7.2 project and case interface in a controller-first parchment-and-ink theme.
- A Fowl Election scenario with 28 composable rules, 29 possible facts, six locations and eight named residents.
- Seven-day cycle with two spontaneous incident attempts per day; event chains trigger only from newly created causal facts.
- Nudge, Misfile, Reschedule, and Domino Permit interventions, each with costs and a distinct rule.
- Consequence trace in a readable official chronicle.
- Reality Strain, scheduled and telegraphed corrections, and opportunities from corrected events.
- Success and loss resolution, Civil Service Merit and three permanent upgrades.
- Seeded randomness and local autosave/restore.
- GitHub Actions configuration for headless smoke tests on PRs; on-demand Linux x86_64 and Windows release exports (`prototype-build` branch or manual dispatch).

## Validation completed in this environment

- Catalog shape, uniqueness and prerequisite reachability: **passed**.
- 1,000-seed approximate Python balance checks: **passed**; showed why natural event attempts must be limited per day. This model is deliberately NOT a substitute for running the actual Godot engine.
- Manual source structure checks: completed; project currently lacks local Godot runtime.

## Still unverified / not done

- Actual Godot 4.7.2 parse / scene run, headless GDScript test execution, and exported Windows/Linux binaries (Godot binary unavailable locally).
- Actual Steam Deck hardware and suspend/resume test.
- Controller focus and visual layout measurements on hardware.
- Multiple assignments, full rank progression, animated town, sound, polished artwork, Steam integration.
- GitHub commit: no dedicated repository exists yet; GitHub connector currently cannot create repositories.

## Immediate next action once `killjoy00/ministry-of-coincidences` exists

1. Push all source files and docs into that separate repository.
2. Run CI `Godot prototype checks`. Resolve any parser or runtime failures before claiming playable.
3. Trigger `Build Windows and Linux prototypes` to produce downloadable binaries.
4. Run the Linux candidate on Steam Deck; audit focus/navigation and text legibility.
5. Conduct first five short playtests, refine the engine, and only then expand content.

## The real incremental progression — November 9, 2026

Twelve departments now run through a deterministic, data-driven catalog and a controller-accessible Ministry organization chart. Licenses are permanent purchases using Civil Service Merit, require past cases, and can be staffed in combinations (2–5 slots). They change real event outcomes and cause chains; the Chronicle records all department activations. The player's active roster is snapshotted per case, and existing v1 saves are migrated to v2 with currency and traditional upgrades intact.

Preliminary local checks: 104 department mechanic/migration assertions, 14 UI/purchase/navigation checks, and 250 seeded unassisted comparisons, with finite histories and factual parent IDs. The late-case automation combination wins 128/250 cases even with no stamp interventions; it is deliberately powerful and **will require harder follow-up assignments** to maintain engagement. The unstaffed first case remains unchanged. This milestone is incremental infrastructure, not proof of long-term playtest retention. `docs/DEPARTMENTS_AND_PROGRESSION.md` is the authoritative feature guide.
