# Store releases run through fastlane, signed by match, from GitHub Actions

Shipping to TestFlight and to Play must be something an agent runs end to end
(`CLAUDE.md`), with the human only ever touching the store dashboards. That
rules out the two things Apple signing usually needs: an Apple ID logged into
Xcode, and a certificate exported by hand from someone's keychain.

## The pieces

- **fastlane** (`apps/app/fastlane`, pinned in `apps/app/Gemfile`) is the one
  entry point: `ios certificates`, `ios beta`, `android beta`. It wraps
  `flutter build ipa` / `flutter build appbundle` and the two store uploads.
- **match** holds the App Store certificate and provisioning profile,
  encrypted, in the private repo `peter-trost/emotely-certificates`. It mints
  them through the **App Store Connect API key** (`emotely CI`, Admin, key ID
  `8S5G6UTCKM` on team `VCZSHMZY25`) — so no Apple ID, no 2FA, ever. The
  Matchfile is `readonly(true)`; only the `certificates` lane may write.
- **Android** signs with the legacy upload keystore (Play App Signing holds
  the real signing key). CI writes `android/key.properties` and the keystore
  from secrets; without them a release build falls back to the debug key so
  `flutter run --release` works on a dev machine.
- **GitHub Actions** (`.github/workflows/app-release.yml`) runs both lanes in
  the `release` environment on every merge to `main` that touches the app
  (continuous delivery: `main` is already gated by `ci-ok`), and on
  `workflow_dispatch`. The build number is `1000 + run_number`: monotonic,
  and above anything the legacy app ever shipped (ADR 0012). iOS builds on
  `macos-26`, because App Store Connect rejects anything below the iOS 26 SDK.

## Secrets (environment `release`)

`APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`,
`APP_STORE_CONNECT_API_KEY_P8`, `MATCH_PASSWORD`, `MATCH_DEPLOY_KEY` (write
deploy key of the certificates repo), `ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEY_PROPERTIES`, `PLAY_SERVICE_ACCOUNT_JSON`, `POSTHOG_KEY`.
The human-readable copies live in the login keychain on the dev Mac
(`emotely_*` items) — never in the repo, never in chat.

## Amendment 2026-09-19: every build reaches the beta testers

The lanes now distribute, not just upload (#127). `ios beta` hands each build
to the TestFlight groups `Team` (internal) and `Beta` (external); `android
beta` uploads to `internal` and then promotes that same version code to the
closed track `alpha`. Outside testers were the reason: an external TestFlight
group and a closed Play track are the only ways to reach someone who is not
in the App Store Connect team or on an internal list, and assigning each
build by hand in two consoles is exactly the human step this ADR removes.

It costs time, not reliability. `distribute_external` cannot skip Apple's
build processing, so the macos-26 job now waits the 10–30 min it used to
return before; the first build of a version additionally waits for Beta App
Review, and Google reviews every closed-testing release. All three happen
after the workflow is green. Android takes two `upload_to_play_store` calls
rather than one, because supply ignores `track_promote_to` on any run that
uploaded a binary — the promotion has to be its own, binary-free edit.

## What we rejected

- **Xcode cloud-managed signing** (`-allowProvisioningUpdates` with the API
  key) needs fewer secrets but hides the certificate inside Xcode's behaviour,
  and Flutter's `build ipa` does not pass the authentication flags through.
  match keeps the material inspectable and portable to any machine.
- **Exporting the existing distribution certificate** from the dev keychain
  into CI: a manual, unrepeatable step, exactly what this ADR removes.
