---
name: run-app
description: How to build, run, and drive the Flutter app (apps/app) on a simulator against the deployed or a local agent, and how to run the on-device acceptance session. Use whenever asked to run the app, see a screen, verify a change on a device, or run integration_test.
---

# Running apps/app

Everything below is agent-executable; the only human step is producing a
PostHog project token, and one already exists locally.

## Build-time configuration

All configuration is `--dart-define`s, read in one place: `lib/app/environment.dart`.

| define | default | purpose |
| --- | --- | --- |
| `EMOTELY_AGENT_URL` | `https://emotely-agent.vercel.app/api/advance-session` | the agent; point at a local or preview deployment when needed |
| `POSTHOG_KEY` | empty = analytics off (the SDK skips setup) | PostHog project token (`phc_…`) |

The token is public by design but is never committed. Read it **blind** from
the agent's local env — never print it, never paste it into a message:

```bash
KEY=$(grep -E '^POSTHOG_KEY=' apps/agent/.env.local | cut -d= -f2- | tr -d '"' | tr -d "'")
```

## Toolchain

- Flutter is pinned by FVM (`apps/app/.fvmrc`); always call `fvm flutter` /
  `fvm dart` from `apps/app`. The global Flutter also matches the pin so the
  VGV plugin's MCP tools work, but FVM is the source of truth.
- First native build after adding a CocoaPods plugin may need
  `pod repo update` (the error says "specs repository is too out-of-date").

## Run on the iOS simulator

1. Find or boot a device: `xcrun simctl list devices booted`.
2. Attach the panel first (cheap, opens instantly): the Claude Code iOS
   Simulator tool, action `attach`, device e.g. `iPhone 17 Pro`.
3. Build the real app (not the test runner):

   ```bash
   cd apps/app && fvm flutter build ios --simulator --dart-define=POSTHOG_KEY="$KEY"
   ```

4. Launch `build/ios/iphonesimulator/Runner.app` with the simulator tool's
   `launch` action; wait ~8 s for the first agent round, then `screenshot`.
   Drive it with `tap` / `text` in device points (402×874 on iPhone 17 Pro).

Gotchas: the app renders a **blank screen** if the `Runner.app` on disk came
from `flutter test integration_test` (that build idles waiting for a test
driver) — rebuild with step 3. The simulator keyboard autocorrects typed
text (German layout); use exact-match finders only in tests, not on device.

## On-device acceptance (live agent)

A whole session against the deployed agent, answering whatever it asks —
nightly / pre-release by hand, never per PR:

```bash
cd apps/app && fvm flutter test integration_test/live_session_test.dart -d <device udid> --dart-define=POSTHOG_KEY="$KEY"
```

Expect ~25 s after the build (about ten live model rounds). Then verify the
events arrived in PostHog with the personal key, also read blind:

```bash
PHX=$(grep -E '^POSTHOG_PERSONAL_API_KEY=' apps/agent/.env.local | cut -d= -f2- | tr -d '"' | tr -d "'")
curl -s -H "Authorization: Bearer $PHX" "https://eu.posthog.com/api/projects/262464/events/?event=session_completed&limit=1&after=$(date -u +%Y-%m-%dT00:00:00Z)" | jq '.results[0].properties | with_entries(select(.key | startswith("$") | not))'
```

Properties must be ids, types, counts and status codes only — never content
(ADR 0005).

## Unit gate (what CI runs)

```bash
cd apps/app && fvm flutter analyze --fatal-infos && fvm dart format --set-exit-if-changed . && fvm dart run build_runner build --only-check && fvm dart pub global run very_good_cli:very_good test --coverage --min-coverage 100 --exclude-coverage '**/*.{freezed,g,mocks}.dart'
```
