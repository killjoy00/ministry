# Implementation and verification status — 2026-11-08

## Playable vertical slice implemented

Godot 4.7.2 project with a seven-day *A Fowl Election* case; 28 connected causal rules; Nudge, Misfile, Reschedule and Domino Permit stamps; staged approvals; reality strain/corrections; seeded deterministic outcomes and provenance chronicle; offline save/restore; Merit and three upgrades; controller-first interface.

The original headless suite passed 280 assertions. The actual Godot 4.7.2 engine was also run against 500 uninfluenced seeds (68 wins) and 500 targeted Nudge seeds (466 wins). UI checks were exercised at 1280x800 and a seven-day keyboard-driven Linux desktop run reached its result and Merit screen. The header, case counters, chronicle, first-event focus and footer were adjusted after rendered visual inspection.

## Automated CI and distribution

- Godot import and headless simulation smoke suite
- Actual-engine 500-seed balance regression
- 1280x800 UI controls/layout regression on starting, result and restarted case
- Linux x86_64 and Windows exports
- Steam Deck-friendly tar.gz with executable permission and launcher, plus Windows zip when Python is present

## Remaining before a public Steam launch

No Steam Deck hardware, sleep/resume or performance test has been performed. No Steamworks integration, audio/graphics polish, multiple assignments, larger incremental tiers or external playtesting yet. Do not claim Valve Deck Verified status.

The game is a completed **playable first-case build**, not a complete commercial game.

## New illustrated assets / Steam publishing preparation — November 8, 2026

The generated portraits, Oddford wide scene, event cards and stamp icons are incorporated into the Godot UI as local assets. The player may open the town panorama or six-person cast register without a mouse; B closes the scene. A new Godot art regression covers texture imports, modals and a complete seven-day case. The gameplay engine, progression rules and no-backend design are unchanged. `docs/STEAM_RELEASE_GUIDE.md` documents Steam Direct signup, AI disclosure, SteamPipe builds, reviews and Steam Deck acceptance. The first case is playable, not a commercially complete game; physical Deck testing and additional content are still needed.

## Living Oddford and audio — November 9, 2026

Interactive six-location illustrated town, inspection-driven navigation into real pending events, a skippable day-by-day causal replay of logged simulation events, event-dependent paper-and-ink animation, rubber-stamp sound and an original procedural waltz with persisted music settings. Added `tests/living_town_smoke.gd` and CI gates. These present the simulation visually but do not change its odds or results. Actual Steam Deck audio/gamepad/suspend validation remains open.
