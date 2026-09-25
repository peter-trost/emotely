---
name: run-app
description: How to run, drive and verify the Flutter app (apps/mobile/app) on an iOS simulator — run-app.sh sets it up signed in against the deployed agent, the agent drives it with plain marionette commands, and the CLI records and collects an evidence bundle (screenshots, video, logs, PostHog events); plus the on-device acceptance session and the unit gate. Use whenever asked to run the app, see a screen, verify a change on a device, collect evidence for a pull request, or run integration_test.
---

# Running apps/mobile/app

## Verify on the simulator: up → drive → collect → down

`.claude/skills/run-app/scripts/run-app.sh` sets the app up and collects the
evidence; you drive it in between with plain `marionette` commands. Run
`run-app.sh help` first: it prints the CLI's usage followed by marionette's
own reference (`marionette help-ai`).

1. **Up.** `run-app.sh up` builds a debug app, boots a fresh iOS simulator,
   launches the app with `flutter run` against the deployed agent, registers
   it with marionette and signs in as the smoke account. It ends on the
   signed-in journal and prints the **instance** and the **bundle**:

   ```
   instance  emotely-verify-12345
   device    <udid>
   bundle    …/apps/mobile/app/build/evidence/20260925-101500
   drive     marionette -i emotely-verify-12345 get-interactive-elements
   ```

   About three minutes (build, boot, sign-in). `run-app.sh status` prints the
   same again. Attach the Claude Code iOS Simulator panel to the device to
   watch. Any command that fails exits non-zero and names its step
   (`preflight`, `build`, `simulator`, `launch`, `register`, `sign-in`, …).
2. **Drive** with `marionette -i <instance> <command>`. Look before acting:
   `get-interactive-elements` lists what is on screen with its keys. Match by
   **key** first (`--key journal_view.start`), by visible `--text` only where a
   widget has none, and never by coordinates: a widget the task needs gets a
   `Key('<screen>.<thing>')` like its neighbours. Marionette taps the centre
   of what a key names, so the key belongs on the tappable widget itself (see
   `SubmitButton.buttonKey`), never on a full-width row around it. A model
   round takes a few seconds: poll `get-interactive-elements` until the next
   key shows up. Screenshots go into the bundle:
   `take-screenshots --output <bundle>/NN-<name>.png`. For video, wrap the
   part worth watching in `run-app.sh record start` / `record stop`.
3. **Collect.** `run-app.sh collect` stops a running recording and writes
   `app.log` (marionette `get-logs`: every `debugPrint`),
   `posthog-events.json` (the smoke user's events since `up`, `$`
   properties dropped) and `summary.json`, next to `flutter-run.log` and your
   screenshots. It briefly backgrounds the app so PostHog flushes (up to two
   and a half minutes while events arrive), then brings it back; drive on and
   collect again if you need to.
4. **Down.** `run-app.sh down` stops the app and deletes the simulator `up`
   created. The bundle stays. Attach what a reviewer needs to the pull
   request with `gh pr create --attach` / `gh pr edit --attach`.

`up --device <udid>` reuses a simulator (the app is uninstalled first, so it
still starts signed out); `up --skip-build` reuses the last `Runner.app` that
`up` built.

### Worked example: start a session and answer the first question

```bash
S=.claude/skills/run-app/scripts/run-app.sh
$S up                                   # prints instance and bundle
I=emotely-verify-12345                  # from up's output
B=/…/build/evidence/20260925-101500     # from up's output
m() { marionette -i "$I" "$@"; }

$S record start
m get-interactive-elements              # a leftover session shows journal_view.discard
m tap --key journal_view.discard        # only if it is there
m take-screenshots --output "$B/01-journal.png"
m tap --key journal_view.start
# The consent screen, only while the smoke account's consent is missing or
# out of date: m scroll-to --key consent_view.checkbox; m tap --key
# consent_view.checkbox; m scroll-to --key consent_view.agree; m tap --key
# consent_view.agree
m get-interactive-elements              # repeat until session_view.question shows
m take-screenshots --output "$B/02-first-question.png"
# The keys tell the kind of question; this one was a text list:
m enter-text --key text_list_input.field.0 --input "Made-up item one"
m enter-text --key text_list_input.field.1 --input "Made-up item two"
m tap --key text_list_input.submit
m get-interactive-elements              # repeat until Text: "Question 2" shows
m take-screenshots --output "$B/03-second-question.png"
m press-back-button                     # leave no open session behind
m get-interactive-elements              # repeat until journal_view.discard shows
m tap --key journal_view.discard
$S collect
$S down
```

The other kinds: `longtext_input.field` then `longtext_input.submit`;
`tap --key rating_input.slider` (its centre is a 5) then
`rating_input.submit`; `emoji_input.slot.0`, `tap --text 😊` (the
third-party picker has no keys) then `emoji_input.submit`;
`color_input.slot.0`, `color_input.select` then `color_input.submit`.
Discard what you open: the nightly live smoke starts a new session and fails
on an unfinished one.

### Privacy

The repository and its attachments are public (ADR 0005). `up` signs in only
as the smoke account from `apps/agent/.env.local` (read blind, from the main
checkout when run in a worktree), refuses an address outside the reserved
test domains, and signs in before any recording. `collect` scrubs the smoke
address, password and user id from every text file in the bundle. What you
type is yours to keep clean: made-up content only, and say so. Never sign in
as anyone else on a driven app.

How it fits together: `main.dart` initialises `MarionetteBinding` only under
`kDebugMode`, so profile and release builds never contain it. The debug
build carries `SMOKE_EMAIL`, which makes the sign-in screen ask that one
account for a password instead of a code (it has no mailbox). The installed
`marionette_cli` must match the app's `marionette_flutter` version; `up`'s
preflight says which to activate.

## Build-time configuration

All configuration is `--dart-define`s, read in one place: `lib/app/environment.dart`.

| define | default | purpose |
| --- | --- | --- |
| `EMOTELY_AGENT_URL` | `https://api.getemotely.com/api/advance-session` | the agent (production alias of the `emotely-agent` Vercel project); point at a local or preview deployment when needed |
| `POSTHOG_KEY` | empty = analytics off (the SDK skips setup) | PostHog project token (`phc_…`) |
| `EMOTELY_SUPABASE_URL` | the hosted project | Supabase project URL; public (ADR 0010) |
| `EMOTELY_SUPABASE_PUBLISHABLE_KEY` | the hosted project's key | Supabase publishable key; public, acts only under the signed-in user |
| `SMOKE_EMAIL` | none | debug builds only: the one address asked for a password (the CLI sets it); the live integration test signs in with it too |
| `SMOKE_PASSWORD` | none | integration_test only: the smoke user's password |

Every secret lives in `apps/agent/.env.local` and is read **blind** — never
printed, never pasted into a message:

```bash
KEY=$(grep -E '^POSTHOG_KEY=' apps/agent/.env.local | cut -d= -f2- | tr -d '"' | tr -d "'")
```

## What the CLI does not do

- **Another agent, or Android.** The CLI runs the deployed agent on iOS. For
  anything else build and run by hand: `fvm flutter build ios --simulator`
  (plus the defines above) from `apps/mobile/app`, then the simulator tool's
  `launch` with `build/ios/iphonesimulator/Runner.app`, or `fvm flutter run
  -d <device>`. On a device a person signs in with the emailed six-digit code;
  against the local Supabase stack (supabase skill) the code shows up in
  Inbucket at http://127.0.0.1:54324. The app renders a **blank screen** when
  the `Runner.app` on disk came from `flutter test integration_test`: rebuild.
- **Toolchain.** Flutter is pinned by FVM (`apps/mobile/app/.fvmrc`); call
  `fvm flutter` / `fvm dart` from `apps/mobile/app`. CocoaPods comes from the
  app's `Gemfile` (`bundle config set --local path vendor/bundle && bundle
  install` once per checkout; the CLI does it) and fails under a non-UTF-8
  locale (`LANG=en_US.UTF-8`). After adding a CocoaPods plugin the first
  build may need `pod repo update`.

## On-device acceptance (live agent)

A whole session against the deployed agent, answering whatever it asks —
nightly / pre-release by hand, never per PR:

```bash
SMOKE_EMAIL=$(grep -E '^SMOKE_EMAIL=' apps/agent/.env.local | cut -d= -f2-)
SMOKE_PASSWORD=$(grep -E '^SMOKE_PASSWORD=' apps/agent/.env.local | cut -d= -f2-)
cd apps/mobile/app && fvm flutter test integration_test/live_session_test.dart -d <device udid> --dart-define=POSTHOG_KEY="$KEY" --dart-define=SMOKE_EMAIL="$SMOKE_EMAIL" --dart-define=SMOKE_PASSWORD="$SMOKE_PASSWORD"
```

Expect ~25 s after the build (about ten live model rounds). It starts a new
session, so it needs the smoke account without an unfinished one: discard
what a driven session leaves open (above).

## PostHog by hand

`run-app.sh collect` already fetches a session's events. For anything else, the personal key
(also read blind) reads the events API; properties must be ids, types, counts
and status codes only — never content (ADR 0005):

```bash
PHX=$(grep -E '^POSTHOG_PERSONAL_API_KEY=' apps/agent/.env.local | cut -d= -f2- | tr -d '"' | tr -d "'")
curl -s -H "Authorization: Bearer $PHX" "https://eu.posthog.com/api/projects/262464/events/?event=session_completed&limit=1&after=$(date -u +%Y-%m-%dT00:00:00Z)" | jq '.results[0].properties | with_entries(select(.key | startswith("$") | not))'
```

Error tracking answers on the same endpoint. Provoke a handled failure (the
cheapest: request a sign-in code for an address Supabase refuses, e.g. a
second request within 60 s), then list the `$exception` events since the run
started; the SDK stamps `$app_version`/`$app_build` and `ErrorReporter` adds
`step`:

```bash
AFTER=$(date -u +%Y-%m-%dT%H:%M:%SZ)   # take this BEFORE provoking the failure
curl -s -H "Authorization: Bearer $PHX" "https://eu.posthog.com/api/projects/262464/events/?event=%24exception&limit=5&after=$AFTER" | jq '.results[] | {timestamp, exceptions: [.properties["$exception_list"][] | {type, value, handled: .mechanism.handled}], step: .properties.step, status_code: .properties.status_code, app_version: .properties["$app_version"], app_build: .properties["$app_build"]}'
```

`value` must be the type plus a code (`… (message withheld, ADR 0005)`) for
everything but `AgentException`, `ClientException` and `TimeoutException`.
Uncaught-error autocapture is off in debug builds, so a simulator run only
shows handled failures. The SDK flushes on a timer or when the app goes to
the background: press HOME and give it ~45 s before querying.

## Unit gate (what CI runs)

Every package in the workspace, each in its own directory — codegen
tripwire, format, analyze, complexity and size limits, the 100% coverage
gate:

```bash
cd apps/mobile && melos run ci
```

One gate at a time is `melos run codegen:check` / `format` / `analyze` /
`complexity` / `test`. To run only what changed since `main` plus its dependents, as a
pull request's CI does:

```bash
cd apps/mobile && EMOTELY_SCOPE="--diff=origin/main...HEAD --include-dependents" melos run ci
```
