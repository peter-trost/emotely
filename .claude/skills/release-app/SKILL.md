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

## Account deletion (store requirements)

- **App Store** (guideline 5.1.1(v)): deletion is in the app. Put the path
  in the review notes: **Your journal → account icon (top right) → Delete
  account → confirm**. It calls `public.delete_account()`, which removes
  the auth user and every session and entry by cascade, then signs the
  device out.
- **Google Play** additionally requires a **web** deletion URL declared in
  the Data safety form, which the app cannot satisfy on its own. Out of
  scope of the in-app path; tracked in #86.

## Store reviewer accounts

Sign-in is an emailed one-time code (ADR 0010), which App Review, Google
Play's policy reviewers and Google's pre-launch crawler cannot receive: none
of them reads our mailbox, and the crawler retrying the sign-in screen burns
the Resend quota (100 mails/day, shared with the website's waitlist). Both
stores accept a demo account as "username + password"; Google's guidance for
apps with one-time-PIN sign-in is to provide reusable sign-in details that do
not expire. So two accounts sign in with a **password, not a code**, and never
trigger an email (`apps/app/lib/auth/review_accounts.dart`):

- `google-play-review@getemotely.com`
- `app-store-review@getemotely.com`

The app shows a password step for exactly these addresses (trimmed,
case-insensitive) and calls `signInWithPassword`; the accounts exist only on
the server, the app has no sign-up path.

- **The password** is `REVIEWER_PASSWORD` in
  `~/.config/emotely/reviewer-accounts.env` (mode 600, never in the repo) and
  in Peter's iCloud Passwords. It is the same for both accounts. Paste it into
  App Store Connect → App Review Information → Sign-in required, and Play
  Console → App content → App access → "All or some functionality is
  restricted" → sign-in details.
- **Before every store submission, run the recreate script.** A reviewer
  testing "Delete account" really deletes the account (the App Store path
  above), and both stores may re-test at any time:

  ```bash
  .claude/skills/release-app/scripts/reviewer-accounts.sh
  ```

  Idempotent: it reads the password from the env file (generating one with
  `openssl rand` and writing the file with `umask 077` if absent), obtains the
  legacy `service_role` key blind through `supabase projects api-keys`, creates
  each user pre-confirmed with `app_metadata.review_account = true` and, if it
  already exists, resets its password. It prints status lines only, never a
  body, a key or the password. Needs the linked Supabase CLI login, `jq`,
  `curl`, `openssl`.
- **Play Console pre-launch crawler.** The "Sign-in details" entry has a
  switch "allow Google to use these sign-in details for testing": on, the
  pre-launch report's crawler signs in with the reviewer account instead of
  hammering the sign-in screen with an address of its own. Leave it on.
- The accounts are ordinary users under row-level security: whatever a
  reviewer journals is theirs and gone with the next recreate only if they
  deleted the account; the script never wipes an existing account's data.

## App Store Connect prep for a new version

Version records, the app name and TestFlight Test Information are set through
the ASC API with the same key (no dashboard clicking). The one-off script that
did it for 2.0.0 lived outside the repo; the patterns are `appStoreVersions`,
`appInfoLocalizations`, `betaAppLocalizations`, `betaAppReviewDetails`.

## Local tooling

`bundle install` uses `vendor/bundle` (`.bundle/config`, ignored). fastlane
needs `LC_ALL=en_US.UTF-8`. `flutter build ipa` locally still signs
automatically with your dev Apple ID; only CI uses match.
