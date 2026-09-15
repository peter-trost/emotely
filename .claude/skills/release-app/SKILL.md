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

## Privacy policy URL (store requirements)

Both stores have a field for it, and both are **human steps in the console**.
The value is the same in every place:

```
https://getemotely.com/app-privacy
```

That is the **app's** notice (`apps/web/lib/pages/app_privacy.dart`), not
`/privacy`, which covers the web site and the waitlist and says so in its
first sentence. Pointing a store at `/privacy` is what got the 2026-09-13
Play update rejected — *"Invalid Privacy policy — URL provided
https://emotely.de/app-privacy/ does not link to a valid privacy policy
page"* — first because the legacy domain was dead, and then because the
replacement disclaimed the app it was supposed to cover.

- **Play Console → Policy → App content → Privacy policy.** Paste the URL,
  save, and submit. Google fetches it, so it must be reachable without
  signing in and must not redirect through anything that asks for consent.
- **App Store Connect → App Privacy → Privacy Policy URL.** Set it **per
  locale** — English and German both, since the listing carries both; ASC
  keeps one URL per localisation and an empty one blocks submission. The
  page itself is English-only for now, which is allowed, but if a German
  translation is ever added the German locale must point at it.

**The ASC data declarations must keep agreeing with the page.** App Store
Connect asks separately *which* data types are collected, and a reviewer
compares those answers with the notice. As corrected on 2026-09-15 the
declarations are seven types, everything **Linked** to the user, and **no
tracking**: contact info (email), user content (the journal), identifiers
(user id and the analytics library's device id), usage data, diagnostics.
If the page gains or loses a category — a new event, a new provider, a
dropped identifier — change the declarations in the same release, not later.

## Account deletion (store requirements)

- **App Store** (guideline 5.1.1(v)): deletion is in the app. Put the path
  in the review notes: **Your journal → account icon (top right) → Delete
  account → confirm**. It calls `public.delete_account()`, which removes
  the auth user and every session and entry by cascade, then signs the
  device out.
- **Google Play** additionally requires a **web** deletion URL declared in
  the Data safety form, because some users ask after uninstalling. The URL
  is `https://getemotely.com/delete-account` (`apps/web`, in the sitemap and
  linked from the privacy page). The page explains the in-app path first,
  then offers a self-serve form for people without the app: address → a
  six-digit code from GoTrue with `create_user: false` (a deletion request
  must never create an account) → the code is exchanged for the user's own
  access token, which calls the same `public.delete_account()`. No operator
  step, no mailbox to watch, no service-role key. An address with no account
  is answered exactly like one that has, so the form cannot be used to find
  out who has an emotely account.
- **Declaring it is a human step in the Play Console** and the only part of
  this that an agent cannot do. **Play Console → Policy → App content →
  Data safety → Data deletion**, and three answers change together:
  1. **"My app provides a way for users to request that their account be
     deleted"** → **yes**.
  2. **"My app provides a way for users to request that some or all of
     their data be deleted"** → **yes**. Both are needed: the first covers
     the account, the second the journal entries and sessions that go with
     it. Answering only the first understates what the page does and is a
     common rejection.
  3. The **account deletion URL** field → `https://getemotely.com/delete-account`.

  Save, then **submit the Data safety form** — an edited but unsubmitted
  form does not count. It is a release blocker for the Play track: the
  form cannot be completed without the URL.

  The page also has to satisfy Google's presentation rules, which it does
  and which a redesign must not break: it names the app and developer as
  the listing has them (still "Reflect Therapy AI: emotely" until the
  rename in ADR 0012 — the page and a `pages_test` assertion both carry
  that string, so a rename shows up as a failing test), it is reachable
  without signing in, and it is linked from the footer of every page and
  from the privacy notice.
- **The in-app path is unchanged** by any of this — it remains the route
  the App Store review notes name, and the one to give a reviewer.

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
the server, the app has no sign-up path. **The accounts must exist before the
addresses are public** (in a store build or a console): they do, both were
created on the hosted project through the Auth admin API on 2026-09-13.

- **The password** is `REVIEWER_PASSWORD` in
  `~/.config/emotely/reviewer-accounts.env` (mode 600, never in the repo;
  24 letters and digits) and in Peter's iCloud Passwords. It is the same for
  both accounts and is what the consoles hold.
- **Recreate whenever an account is gone, and before every store
  submission.** A reviewer testing "Delete account" really deletes the
  account (the App Store path above), and both stores may re-test at any
  time:

  ```bash
  .claude/skills/release-app/scripts/reviewer-accounts.sh
  ```

  Idempotent: it reads the password from the env file (generating one with
  `openssl rand` and writing the file with `umask 077` if absent), obtains the
  legacy `service_role` key blind through `supabase projects api-keys` into a
  curl config file (never argv), creates each user pre-confirmed and, if it
  already exists, resets its password. It prints status lines only, never a
  body, a key or the password. Needs the linked Supabase CLI login, `jq`,
  `curl`, `openssl`. It stamps `app_metadata.review_account = true`, which is
  informational only (dashboard, JWT) — nothing server-side reads it; the
  app decides by address.
- **The pre-launch crawler runs on every upload to a track**, and
  `app-release.yml` uploads on every merge that touches `apps/app` — not only
  on submissions. So an account a reviewer deleted stays broken, silently and
  email-free by design, until the script is re-run. The symptom: a
  pre-launch report whose crawls show the sign-in screen only, and in PostHog
  a burst of `sign_in_password_failed` with no `signed_in`.
- **Play Console pre-launch crawler.** The "Sign-in details" entry has a
  switch "allow Google to use these sign-in details for testing": on, the
  pre-launch report's crawler signs in with the reviewer account instead of
  hammering the sign-in screen with an address of its own. Leave it on.
- The accounts are ordinary users under row-level security: whatever a
  reviewer journals is theirs; the script never wipes an existing account's
  data, only resets the password.

### What the consoles say (saved 2026-09-13)

**Play Console → App content → App access → Sign-in details.** Entry name
"Reviewer demo account", user name `google-play-review@getemotely.com`, the
password above, and these instructions (the field allows 500 characters):

> Open the app, enter the user name above as the email address and tap
> Send code. This is a designated reviewer account, so the app asks for a
> password instead of emailing a one-time code; enter the password above.
> Regular users sign in with a one-time code sent by email. Account
> deletion: Your journal -> account icon (top right) -> Delete account ->
> confirm. Deleting the demo account really deletes it; if it no longer
> signs in, email peter@petertrost.com and we recreate it.

**App Store Connect → version → App Review Information → Sign-in
required.** User name `app-store-review@getemotely.com`, the password above,
Notes:

> Demo account for review. Open the app, enter the user name above as the
> email address and tap Send code. Because this address is a designated
> reviewer account, the app asks for a password instead of sending a
> one-time code; enter the password above. Regular users sign in with a
> one-time code sent by email. Account deletion: Your journal -> account
> icon (top right) -> Delete account -> confirm. Deleting the demo account
> really deletes it; if it no longer signs in, contact peter@petertrost.com
> and we recreate it within the hour.

## App Store Connect prep for a new version

Version records, the app name and TestFlight Test Information are set through
the ASC API with the same key (no dashboard clicking). The one-off script that
did it for 2.0.0 lived outside the repo; the patterns are `appStoreVersions`,
`appInfoLocalizations`, `betaAppLocalizations`, `betaAppReviewDetails`.

## Local tooling

`bundle install` uses `vendor/bundle` (`.bundle/config`, ignored). fastlane
needs `LC_ALL=en_US.UTF-8`. `flutter build ipa` locally still signs
automatically with your dev Apple ID; only CI uses match.
