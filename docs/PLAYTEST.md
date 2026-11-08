# Playtesting — The Ministry of Coincidences

This is an **offline pre-alpha** of *A Fowl Election*, not a complete Steam release or a Valve Deck Verified title.

## Steam Deck

1. Download **ministry-steam-deck-linux.tar.gz** from the latest successful Build Windows and Linux prototypes GitHub Actions run (or the attached chat bundle).
2. In Steam Deck **Desktop Mode**, open Dolphin and extract the archive to a permanent folder.
3. Run **Play Ministry.sh**. You can add that script as a **Non-Steam Game** to launch it from Game Mode; set its Start In directory to the extracted folder.
4. Do not force Proton: this package contains native Linux binaries. Keep the executable and matching .pck alongside each other.

## Windows

The GitHub Actions artifact contains **ministry-of-coincidences-windows.exe** and **ministry-of-coincidences-windows.pck**; keep both together and run the .exe. If a **ministry-windows.zip** is included, extract that instead. The two-file package works without installing Godot.

## Controls

| Action | Controller | Keyboard |
| --- | --- | --- |
| Navigate | D-pad | Arrow keys / Tab |
| Select | A | Enter |
| Cycle stamps | LB / RB | Q / E |
| Approve an intervention | X | F |
| Advance a day | Y | Space |
| Clear pending stamp | B | Escape |

Each case lasts seven in-game days. You can stage interventions, watch causal events resolve, earn Merit whether you win or lose, buy permanent desk upgrades, and file another case.

## Playtest checklist

- All critical controls remain visible and usable without mouse input.
- The seven-day case ends with a win or a loss, awards Merit once, and retains upgrades.
- The chronicle accurately explains causes and the correction forecast is comprehensible.
- Text is legible on the actual Steam Deck; saving and suspend/resume work.

**Not yet verified on actual Steam Deck hardware.** Headless Godot CI and rendered Linux desktop checks are not a substitute.

## Illustrated case scene

The top dossier offers **VIEW ODDFORD** and **MEET THE TOWN**; use D-pad/A to open either. Press **B** (or Escape) to close the illustration and return to the same case. The incident cards and selected-incident preview use different illustrations, and all four seals now have bespoke stamp art.
