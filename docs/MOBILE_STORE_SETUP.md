# Mobile store handoff — The Ministry of Coincidences

**Mobile project:** `killjoy00/ministry`  
**Central signing and store publishing:** `killjoy00/eztrivia`

The Ministry repository owns the game, offline simulations, Godot export presets, and
mobile QA. **EZTrivia owns the existing Apple Developer credentials, Android upload
key, Google Play service account, and cross-repository publishing workflows.**
Do not copy secrets into Ministry, generate new upload keys, or run independent
Ministry signing workflows.

## Registered app IDs
- Display name: **The Ministry of Coincidences**
- Google Play package / Apple bundle ID: `org.killjoy00.ministry`
- Apple Team ID: `3564X3VTDB` (already used by EZTrivia and StarRun)
- Intended initial beta version: `0.1.0`; build numbers must increase per upload
- Privacy text: [MOBILE_PRIVACY.md](MOBILE_PRIVACY.md)

## Release approach

1. Merge Ministry's dependent feature PRs **#14 → #16 → #17 → #18** only after
   the relevant CI checks are green. Never build/store-sign an unmerged feature
   branch or an unreviewed commit.
2. Pin the exact **Ministry main** commit SHA in EZTrivia's release request or
   approved manual invocation. The central workflow verifies that the SHA is
   an ancestor of Ministry main.
3. For Android, use the **Ministry Play Internal** adapter in EZTrivia.
   It checks the registered package ID, exports the `Android Play AAB` preset
   in the checked-out Ministry source, signs using EZTrivia's existing
   `ANDROID_UPLOAD_KEYSTORE_BASE64` and `ANDROID_UPLOAD_KEY_PASSWORD`,
   and uses the existing `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` for **internal**
   testing uploads only. No production changes.
4. For iOS, use the **Ministry TestFlight** adapter in EZTrivia. It checks the
   same immutable source SHA, exports the `iOS Xcode Project` Godot preset,
   signs with the existing Apple Team ID and EZTrivia's
   `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, and `APPLE_TEAM_ID`.
   Its only store destination is TestFlight; Apple processing/beta review can
   take additional time.
5. Run phone acceptance: portrait, rotation, safe-area/notches, font sizes,
   file/undo, second stamp when Double Booking is active, real causal links,
   Causality Theater skip/replay, persistence after closing/reopening.
6. Confirm the Play app has Google Play App Signing configured to accept the
   existing shared **upload certificate** and that the existing Play service
   account can access the new app. If either is unconfigured, that one-time
   provider setting must be changed before store upload; no new credentials
   need to be duplicated in Ministry.

The `Android Debug APK` in Ministry CI is **QA-only**. The signed store AAB and
TestFlight upload must originate in EZTrivia. The Android/iOS export presets
stay in Ministry because they describe the app, not credentials.

## Suggested store copy

**Short description:** Small coincidences. Outrageous consequences.

**Description:**

The universe has paperwork. In The Ministry of Coincidences, you're the clerk
who files it. Choose an unlikely incident, stamp it with a subtle intervention,
and watch Oddford respond. A misplaced letter, a wandering goose, or a ruined
afternoon can set off a wonderfully unreasonable chain of events. Solve four
escalating assignments, discover new departments, and see what really caused
every twist. Offline, turn-based, and built for short sessions.

**Categories:** Games / Strategy or Puzzle (choose the closest options offered).

**Privacy / data safety (current code):** No accounts, advertising,
analytics, location collection, or network activity by the game. Verify the
final exported binary and store questions before submission.
