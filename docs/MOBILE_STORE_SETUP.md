# Store handoff — The Ministry of Coincidences

## Identifiers (registered by publisher)
- Display name: **The Ministry of Coincidences**
- Google Play Android package: `org.killjoy00.ministry`
- Apple bundle identifier: `org.killjoy00.ministry`
- Apple Team ID: `3564X3VTDB` (reused from the existing EZTrivia Xcode configuration; verify it matches the team used to register this app)
- Candidate release: version **0.1.0**, build/version code **1**. Increment before each new store upload.
- Privacy policy (once merged to main): `https://github.com/killjoy00/ministry/blob/main/docs/MOBILE_PRIVACY.md`

## Android: obtain a signed AAB without running local code

The CI debug APK is **not** a Google Play release. Google Play requires an AAB signed by a persistent **upload key**. The AAB workflow is `.github/workflows/mobile-play-aab.yml`.

1. Use an existing safely stored Android upload keystore from your publishing setup, or generate **one new persistent keystore** with your usual signing provider. Enable Google Play App Signing. Back up the keystore, alias, and password outside GitHub. Do not use an ephemeral CI smoke keystore for Play.
2. In the **ministry** GitHub repository, open **Settings → Secrets and variables → Actions → New repository secret**, then add:
   - `MINISTRY_ANDROID_UPLOAD_KEYSTORE_BASE64`: the base64 contents of the keystore file, with no line breaks.
   - `MINISTRY_ANDROID_UPLOAD_KEYSTORE_PASSWORD`: the keystore/key password.
   - `MINISTRY_ANDROID_UPLOAD_KEY_ALIAS`: the keystore key alias.
   The Godot exporter uses the same password for the keystore and contained key.
3. Open **Actions → Google Play Android App Bundle → Run workflow**, choose the `mobile/android-ios-beta` branch while this PR is open, and run. The workflow refuses to produce a publishable AAB if any of the three secrets is missing.
4. On success download the `ministry-google-play-aab-<run>` workflow artifact. Extract `ministry-play-upload.aab`.
5. In **Google Play Console → The Ministry of Coincidences → Testing → Internal testing → Create new release**, upload that AAB. Review tester access and roll out to internal testers first.
6. Confirm the Google Play package name and Play App Signing upload-certificate fingerprint match the registered app. Keep the same upload key for future updates.

PR-triggered AAB smoke builds use a **one-time, throwaway key only to verify Gradle export**. They are not uploaded as production release artifacts and must never be sent to Play.

## iOS: unsigned Xcode first, then TestFlight signing
1. The existing iOS project export is `.github/workflows/mobile-ios.yml` (GitHub Actions requires an available macOS runner). It produces an **unsigned Xcode project**, not an IPA.
2. Create or reuse an **App Store Connect API key** with appropriate application access. Store the `.p8` private key in GitHub Actions secrets; do not commit or paste it into an issue or chat. Existing related app workflows use secret names `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `APPLE_TEAM_ID`. Secrets are scoped per repository unless deliberately shared at organization level.
3. Once the mobile changes and their prerequisites have been merged into `main`, open **GitHub → Actions → Ministry iOS TestFlight upload → Run workflow**. The manual `.github/workflows/mobile-testflight.yml` workflow exports the Godot Xcode project, archives with the registered Team ID, and attempts Apple's managed distribution signing/upload using these four GitHub Secrets. This signing/upload workflow is prepared but has **not yet run successfully or produced an IPA**; resolve any Xcode or account errors from the run logs.
4. In **App Store Connect → The Ministry of Coincidences → TestFlight**, add internal testers once the uploaded build has processed. An unsigned Xcode ZIP is not an installable app.

## Store metadata draft

**Subtitle/short description:** Small coincidences. Outrageous consequences.

**Description:**
`The universe has paperwork. In The Ministry of Coincidences, you're the clerk who files it. Choose an unlikely incident, stamp it with a subtle intervention, and watch Oddford respond. A misplaced letter, a wandering goose, or a ruined afternoon can set off a wonderfully unreasonable chain of events. Solve four escalating assignments, discover new departments, and see what really caused every twist. Offline, turn-based, and built for short sessions.`

**Category suggestion:** Games; strategy/puzzle (select the closest actual options the stores offer).

**Privacy/data safety, based on the current source:** No developer-collected personal data, no ads, no account, no networking or analytics. Verify against the **final exported** app's manifest and any future SDK changes.

## Release gates
- GitHub unit/balance/mobile suites green
- Android debug APK verified and tested on a physical Android phone
- Android AAB signed with persistent key and uploaded to Internal testing
- iOS Xcode export verified on macOS runner
- iOS IPA signed under the registered Apple Developer Team and uploaded to TestFlight
- Physical iPhone and iPad touch, orientation, scroll and notch testing
- Screenshot, accessibility, age-rating, copyright/AI-assisted art disclosures, and store declarations reviewed by publisher
- Merge prerequisite PRs #14, #16, #17 and then #18 after checks
