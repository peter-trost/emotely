---
name: release-app
description: How to ship the Flutter app (apps/app) to TestFlight and the Play internal track with fastlane and the app-release workflow, how signing works (match, the ASC API key, the Android upload keystore), and how to rotate any of it. Use whenever asked to release, ship a beta, upload a build, fix signing, or touch apps/app/fastlane or .github/workflows/app-release.yml.
---

# Releasing the app (apps/app)

Decisions in [ADR 0012](../../../docs/adr/0012-reuse-the-original-store-listings.md)
(store identity `de.emotely.emotely`, version `2.0.0+`) and
[ADR 0013](../../../docs/adr/0013-fastlane-release-pipeline.md) (fastlane +
match, the `release` environment).

## Ship a beta build

Every merge to `main` that touches `apps/app/**`, the contract schema or the
workflow itself ships automatically (continuous delivery). To ship without a
change, or to retry:

```bash
gh workflow run app-release.yml
gh run watch
```

The workflow runs `fastlane ios beta` (macos-26, Xcode 26) and `fastlane
android beta` (Linux) with `BUILD_NUMBER = 1000 + run_number`. The IPA lands
in TestFlight and processes on Apple's side for 10–30 min; the AAB lands on
the Play **internal** track immediately.

After the build shows up:

- **TestFlight**: App Store Connect → TestFlight → add the build to a group.
  Internal testers (App Store Connect users) need no review; an **external**
  group needs Beta App Review once per version, which reads Test Information
  (kept current by the `asc` prep, see below).
- **Play**: Play Console → Testing → Internal testing → the release is live
  for the tester email list defined there.

## Signing

- **iOS**: `match` (`fastlane/Matchfile`) stores the App Store certificate
  and profile encrypted in `peter-trost/emotely-certificates`. CI is
  read-only. To mint or rotate, run locally with the ASC API key:

  ```bash
  cd apps/app
  export APP_STORE_CONNECT_API_KEY_ID=8S5G6UTCKM \
         APP_STORE_CONNECT_ISSUER_ID=725518f0-067c-4ff1-b09b-05712e5b9e87 \
         APP_STORE_CONNECT_API_KEY_P8="$(security find-generic-password -s emotely_asc_api_key_8S5G6UTCKM_base64 -w | base64 -D)" \
         MATCH_PASSWORD="$(security find-generic-password -s emotely_match_password -w)"
  bundle exec fastlane ios certificates
  ```

  The certificate expires after a year; `certificates` renews it. Nuke and
  re-mint with `bundle exec fastlane match nuke distribution` only if the
  private key is compromised.
- **Android**: the legacy upload keystore. Human copies:
  `~/.config/emotely/upload-keystore.jks` + `key.properties`, and keychain
  items `emotely_upload_keystore_base64` / `emotely_upload_key.properties_base64`.
  Play App Signing holds the app signing key; if the upload key is ever lost,
  request an upload-key reset in Play Console → Setup → App signing.

## Secrets (`release` environment on peter-trost/emotely)

Set blind, never echoed: `gh secret set NAME -R peter-trost/emotely --env release < file`.
The list is in ADR 0013. `PLAY_SERVICE_ACCOUNT_JSON` is the JSON key of
`google-play-upload-konto@pc-api-5174249003608815741-70.iam.gserviceaccount.com`.

## App Store Connect prep for a new version

Version records, the app name and TestFlight Test Information are set through
the ASC API with the same key (no dashboard clicking). The one-off script that
did it for 2.0.0 lived outside the repo; the patterns are `appStoreVersions`,
`appInfoLocalizations`, `betaAppLocalizations`, `betaAppReviewDetails`.

## Local tooling

`bundle install` uses `vendor/bundle` (`.bundle/config`, ignored). fastlane
needs `LC_ALL=en_US.UTF-8`. `flutter build ipa` locally still signs
automatically with your dev Apple ID; only CI uses match.
