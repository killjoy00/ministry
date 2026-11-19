# Mobile versions (Android and iOS) — beta

The Ministry shares **one Godot game and one seeded simulation implementation** across
Linux/Steam Deck, Windows, Android, and iOS. `scenes/mobile_main.tscn` is selected by
the `mobile` Godot feature tag in `project.godot`; desktop still uses
`scenes/main.tscn`. No account, advertising, IAP, analytics SDK, backend, cloud
save, or network permission has been added.

## Mobile interaction

- Portrait-first phone interface; resizable center column on tablets/rotation.
- Incident selection, four stamp choices, Influence/Strain and odds preview,
  WHY? / evidence inspection, full Chronicle, town view, and optional tutorial.
- File up to **one** incident, or **two distinct** incidents with Double Booking,
  each day. A zero-stamp day is allowed; spontaneous events still happen.
- Tap **Advance Day** for a short skippable Causality Theater with illustrated
  genuine incidents, documented source events, and daily result deltas.
- Case settlement, Merit upgrades, all twelve departments, and the four-case
  selection board are available on touch. Existing save schema v3 is reused;
  mobile platforms keep their own local device save files.
- Touch targets are at least 42-60 logical pixels and scrollable text is
  available without relying on gamepad buttons. Layout accounts for device
  display safe area.
- The original 1280 x 800 desktop screen and controller bindings are untouched.

## Android

`Android Debug APK` produces an installable developer-signed APK for local and
internal QA. The package identifier in `export_presets.cfg` is **provisional**
(`org.killjoy00.ministry`) until confirmed in Play Console. Do not release
under an identifier you do not intend to keep.

Official Android publishing requires a release keystore, a signed **AAB**
(Gradle build), store listing and privacy/data-safety declarations, and Google
Play testing/review as applicable. Never commit private signing keys/passwords.
CI exports a debug APK automatically for PRs and branch pushes once the Android
SDK and Godot 4.7.2 export templates are configured.

## iOS

`iOS (Xcode project)` is an Xcode export preset; its Team ID is a placeholder
until an actual Apple Developer Team ID is supplied. An iOS artifact is **not**
a signed IPA and cannot be installed/TestFlighted without Apple signing.
A macOS/Xcode workflow exports the project; a separate signed archive/upload
step will require actual App Store Connect credentials and app registration.
No existing iOS apps or signing values are assumed or modified.

## Test cases

`godot --headless --path . --script res://tests/mobile_smoke.gd` covers the
mobile scene, 390x844 and 844x390 layouts, incident selection, filing, undo,
Double Booking, history-based theater, evidence, help/tutorial isolation,
and orientation keeping state intact. CI runs it alongside the Steam Deck tests.
Physical Android and iPhone checks remain required, including taps, scroll,
notches, suspend/resume, sound interruptions, font scaling, and save persistence.
