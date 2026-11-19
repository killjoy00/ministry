# Mobile versions (Android and iOS) — beta

The Ministry shares **one Godot game and one seeded simulation implementation** across
Linux/Steam Deck, Windows, Android, and iOS. `scenes/mobile_main.tscn` is selected by
the `mobile` Godot feature tag in `project.godot`; desktop still uses
`scenes/main.tscn`. No account, advertising, IAP, analytics SDK, backend, cloud
save, or network permission has been added.

## Mobile interaction

- Portrait-locked handset interface in this beta, with a centered, width-aware column on tablets. Android/iOS device rotation is not enabled yet; simulated orientation/resolution changes are covered by headless tests.
- Incident selection, four stamp choices, Influence/Strain and odds preview,
  **the same live `sim.forecast()` correction forecast shown on desktop**,
  WHY? / evidence inspection, and the full Chronicle.
- Oddford is a **touchable six-district map** using the existing desktop
  district positions. Its local witness dockets filter real eligible cases by
  place, let players choose/inspect them, and show recorded incidents. The
  **archived day replay** uses only recorded events and deliberately labels
  unrecorded historic stamp/Strain data as unavailable. The six original
  illustrated resident portraits also have a phone-native gallery.
- Miss Quill's optional briefing steps through **three actual practice
  actions** (start a separate seeded simulation, file its Nudge, advance its
  day) before reviewing the recorded causal history. Practice never touches
  the player's real active case, Merit or filings.
- Audio controls in Office Settings call the same `MusicDirector` as
  desktop: persistent on/off and volume. Reduced-motion settings are also
  saved in the same local configuration file as desktop.
- File up to **one** incident, or **two distinct** incidents with Double Booking,
  each day. A zero-stamp day is allowed; spontaneous events still happen.
- Tap **Advance Day** for a short skippable Causality Theater with original
  character portraits and incident art, documented source events, explicit
  actual-cause links, direct evidence inspection, and daily result deltas.
  The animation can be skipped or disabled with Reduced Motion.
- Case settlement, Merit upgrades, all twelve departments, and the four-case
  selection board are available on touch. Existing save schema v3 is reused;
  mobile platforms keep their own local device save files.
- Touch targets are at least 42-60 logical pixels, with swipe scrolling over
  incident cards, stamp tiles, evidence, and longer screens. All nested controls
  propagate drag gestures into the scrollable content; selecting an incident or
  stamp does not jump back to the top. Layout accounts for the safe area.
- The original 1280 x 800 desktop screen and controller bindings are untouched.

## Android

`Android Debug APK` produces an installable developer-signed APK for local and
internal QA. The package identifier in `export_presets.cfg` is `org.killjoy00.ministry`,
registered by the publisher in Play Console. Preserve it for all updates.

Official Android publishing requires a release keystore, a signed **AAB**
(Gradle build), store listing and privacy/data-safety declarations, and Google
Play testing/review as applicable. Never commit private signing keys/passwords.
Ministry CI exports a **QA-only debug APK** on PRs. The persistent upload key
and release AAB generation live centrally in EZTrivia, reusing the same
credentials and release process used for StarRun and other apps.

## iOS

`iOS (Xcode project)` is an Xcode export preset; its Team ID is `3564X3VTDB`, taken from the existing EZTrivia developer
configuration and expected to match the Ministry App Store Connect app. An iOS artifact is **not**
a signed IPA and cannot be installed/TestFlighted without Apple signing.
The EZTrivia release system exports this preset, archives, signs and uploads
to TestFlight using the existing Apple App Store Connect secrets. No Apple
signing secrets should be copied into the Ministry repository.

## Test cases

`godot --headless --path . --script res://tests/mobile_smoke.gd` covers the
mobile scene, 390x844 and 844x390 layouts, incident selection, filing, undo,
Double Booking, history-based theater, evidence, help/tutorial isolation,
and orientation keeping state intact. CI runs it alongside the Steam Deck tests.
CI also captures **14 unaltered game-rendered phone screenshots**, including
town, residents, briefing, settings, chronicle, and Causality Theater.
The native Android emulator must show nonblank app art, navigate actual taps,
verify incident-list and stamp-gallery swipes against screenshot changes,
and survive Back/home-resume: an earlier real emulator run showed a gray
app surface, so a running Android process is not sufficient proof.
Physical Android and iPhone checks remain required, including taps, scroll,
notches, suspend/resume, sound interruptions, font scaling, and save persistence.

## Store enrollment and upload

The publisher has created both app records as of November 19, 2026. See
[`MOBILE_STORE_SETUP.md`](MOBILE_STORE_SETUP.md) for the permanent app IDs,
EZTrivia's existing signing infrastructure, release steps,
store copy, and remaining acceptance gates. Privacy policy:
[`MOBILE_PRIVACY.md`](MOBILE_PRIVACY.md).
