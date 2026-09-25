#!/usr/bin/env bash
# Sets the Flutter app up on an iOS simulator against the deployed agent,
# signed in as the smoke account and registered with marionette, so an agent
# can drive it with plain marionette commands; then records, collects the
# evidence bundle and tears it all down. `run-app.sh help` for usage.
#
# Signs in as the smoke account and nobody else (ADR 0005: this repository
# and its attachments are public, so evidence holds made-up content only).
# Secrets are read blind from the agent's .env.local, never printed, never
# written into the bundle, and scrubbed from every text file in it.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$(git -C "$SKILL_DIR" rev-parse --show-toplevel)"
APP_DIR="$REPO/apps/mobile/app"
# A worktree has no .env.local of its own; the main checkout does.
MAIN_CHECKOUT="$(dirname "$(git -C "$SKILL_DIR" rev-parse --path-format=absolute --git-common-dir)")"
ENV_FILE="${EMOTELY_ENV_FILE:-$MAIN_CHECKOUT/apps/agent/.env.local}"
DEVICE_TYPE="${EMOTELY_DEVICE_TYPE:-iPhone 17 Pro}"
# One session per checkout; its state lives in the ignored build directory.
STATE_DIR="$APP_DIR/build/run-app"
STATE_FILE="$STATE_DIR/state"
POSTHOG_API="https://eu.posthog.com/api/projects/262464"
# The hosted project, as `lib/app/environment.dart` defaults to it. Both are
# public (ADR 0010); the CLI needs them to learn the smoke user's id, which
# is how it finds this session's PostHog events among everyone else's.
SUPABASE_URL="https://khfkszlujgkfjgnawdlf.supabase.co"
SUPABASE_PUBLISHABLE_KEY="sb_publishable_di6BB76PPuuoDklt7jtI0w_KlwO_8JF"
MARIONETTE_DOCS="https://github.com/leancodepl/marionette_mcp/blob/main/docs/cli.md"

# CocoaPods refuses to run under a non-UTF-8 locale.
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

usage() {
  cat <<EOF
Usage: run-app.sh <command>

  up [options]     Build a debug app, launch it on a simulator against the
                   deployed agent, sign in as the smoke account and register
                   it with marionette. Leaves the app on the signed-in journal
                   and prints the marionette instance and the evidence bundle.
  status           Print the instance, device and bundle of the session.
  record start     Start recording the app to <bundle>/video[-N].webm.
  record stop      Stop and finalise the recording.
  collect          Write the app log, the flutter run log, the PostHog events
                   since \`up\` and summary.json into the bundle, scrubbed of
                   the smoke account's credentials. Stops a running recording.
  down             Stop the app and delete the simulator \`up\` created.
  help             This text, then marionette's reference (help-ai).

Options for up:
  --device <udid>  Reuse this simulator (booted if needed; the app is
                   uninstalled first, so it still starts signed out).
                   Default: a fresh one ($DEVICE_TYPE, newest iOS), which
                   \`down\` deletes.
  --out <dir>      The evidence bundle.
                   Default: apps/mobile/app/build/evidence/<time>/.
  --skip-build     Reuse apps/mobile/app/build/ios/iphonesimulator/Runner.app.
                   Only a build \`up\` made carries marionette and the smoke
                   account; anything else fails at sign-in.

Between up and down, drive the app with marionette:
  marionette -i <instance> get-interactive-elements
  marionette -i <instance> tap --key journal_view.start
  marionette -i <instance> take-screenshots --output <bundle>/01-journal.png
Match by widget key first (Key('journal_view.start')), visible text second,
never coordinates: a widget without a key gets one. Type made-up content
only: evidence is public.

Every command exits non-zero naming the step that failed. SMOKE_EMAIL,
SMOKE_PASSWORD, POSTHOG_KEY and POSTHOG_PERSONAL_API_KEY are read from
$ENV_FILE
(EMOTELY_ENV_FILE overrides the path). SMOKE_EMAIL must be on a reserved test
domain (example.com, .test, ...): the CLI refuses any other account.

Marionette: $MARIONETTE_DOCS
EOF
}

# --- output ---------------------------------------------------------------------

STEP="setup"
log() { printf '[%s] %s\n' "$STEP" "$*" >&2; }
die() {
  printf 'run-app: step "%s" failed: %s\n' "$STEP" "$*" >&2
  exit 1
}
step() {
  STEP="$1"
  log "..."
}

# --- state ----------------------------------------------------------------------

# The session's facts, one KEY=value per line; no secrets.
state_get() { sed -n "s/^$1=//p" "$STATE_FILE" 2>/dev/null | tail -1; }
state_set() { printf '%s=%s\n' "$1" "$2" >>"$STATE_FILE"; }
require_session() {
  [[ -f "$STATE_FILE" ]] || die "no session: run \`run-app.sh up\` first"
  INSTANCE="$(state_get INSTANCE)"
  OUT="$(state_get OUT)"
}

# --- secrets --------------------------------------------------------------------

# Reads KEY's value from the env file without printing it.
env_value() {
  sed -n "s/^$1=//p" "$ENV_FILE" | head -1 | tr -d '\r' | tr -d "\"'"
}

# RFC 2606 / RFC 6761 reserved names: nobody can own a mailbox there, so an
# account on one is a test fixture, never a person.
is_reserved_test_address() {
  local domain="${1##*@}"
  domain="$(printf '%s' "$domain" | tr '[:upper:]' '[:lower:]')"
  case "$domain" in
    example.com | example.net | example.org) return 0 ;;
    *.example | *.test | *.invalid | *.localhost) return 0 ;;
    *) return 1 ;;
  esac
}

# Everything secret goes through files in a private directory (mode 700),
# never through the bundle, and away again when the command ends.
PRIVATE_DIR=""
private_dir() {
  PRIVATE_DIR="$(mktemp -d)"
  chmod 700 "$PRIVATE_DIR"
  trap 'rm -rf "$PRIVATE_DIR"' EXIT
}

read_smoke_account() {
  [[ -r "$ENV_FILE" ]] || die "cannot read $ENV_FILE"
  SMOKE_EMAIL="$(env_value SMOKE_EMAIL)"
  SMOKE_PASSWORD="$(env_value SMOKE_PASSWORD)"
  [[ -n "$SMOKE_EMAIL" && -n "$SMOKE_PASSWORD" ]] \
    || die "SMOKE_EMAIL and SMOKE_PASSWORD must be set in $ENV_FILE"
  is_reserved_test_address "$SMOKE_EMAIL" \
    || die "SMOKE_EMAIL is not on a reserved test domain; the CLI signs in as the smoke account only"
}

# --- marionette -------------------------------------------------------------------

INSTANCE=""
OUT=""
m() { marionette -i "$INSTANCE" "$@"; }

# Retries "$@" (quietly) until it succeeds or $1 seconds pass.
retry() {
  local seconds="$1" deadline
  shift
  deadline=$((SECONDS + seconds))
  until "$@" >/dev/null 2>&1; do
    ((SECONDS < deadline)) || return 1
    sleep 1
  done
}

# Whether the widget keyed $1 is on screen. Captured first: under pipefail a
# `grep -q` that stops reading early fails the pipeline through SIGPIPE.
on_screen() {
  local elements
  elements="$(m get-interactive-elements 2>/dev/null)" || return 1
  grep -qF "Key: \"$1\"" <<<"$elements"
}

# --- up -------------------------------------------------------------------------

UDID=""
RUNNER_APP="$APP_DIR/build/ios/iphonesimulator/Runner.app"

preflight() {
  step "preflight"
  local tool
  for tool in fvm xcrun marionette jq yq curl ffmpeg plutil; do
    command -v "$tool" >/dev/null || die "missing tool: $tool"
  done
  local app_version cli_version
  app_version="$(yq '.packages.marionette_flutter.version' "$REPO/apps/mobile/pubspec.lock")"
  cli_version="$(dart pub global list 2>/dev/null | sed -n 's/^marionette_cli \([0-9.]*\).*/\1/p')"
  [[ "$cli_version" == "$app_version" ]] \
    || die "marionette_cli is ${cli_version:-missing}, the app has marionette_flutter $app_version: dart pub global activate marionette_cli $app_version"

  read_smoke_account
  jq -n --arg email "$SMOKE_EMAIL" --arg key "$(env_value POSTHOG_KEY)" \
    '{SMOKE_EMAIL: $email, POSTHOG_KEY: $key}' >"$PRIVATE_DIR/defines.json"
  jq -n --arg email "$SMOKE_EMAIL" --arg password "$SMOKE_PASSWORD" \
    '{email: $email, password: $password}' >"$PRIVATE_DIR/grant.json"
  printf 'header = "apikey: %s"\n' "$SUPABASE_PUBLISHABLE_KEY" >"$PRIVATE_DIR/supabase.curl"

  # The smoke user's id: proves the credentials before a two-minute build,
  # and is how `collect` tells this session's PostHog events apart.
  local user_id
  user_id="$(curl -sS --fail-with-body -K "$PRIVATE_DIR/supabase.curl" \
    -H 'Content-Type: application/json' --data @"$PRIVATE_DIR/grant.json" \
    "$SUPABASE_URL/auth/v1/token?grant_type=password" | jq -r '.user.id // empty')" \
    || die "the smoke account's password grant failed"
  [[ -n "$user_id" ]] || die "the smoke account's password grant returned no user"
  state_set SMOKE_USER_ID "$user_id"
}

build() {
  step "build"
  if [[ $SKIP_BUILD -eq 1 ]]; then
    [[ -d "$RUNNER_APP" ]] || die "--skip-build, but there is no $RUNNER_APP"
    log "reusing $RUNNER_APP"
    return
  fi
  (cd "$APP_DIR" && bundle check >/dev/null 2>&1) \
    || (cd "$APP_DIR" && bundle config set --local path vendor/bundle >/dev/null && bundle install >/dev/null) \
    || die "bundle install (CocoaPods) failed"
  (cd "$APP_DIR" && fvm flutter build ios --simulator --debug \
    --dart-define-from-file="$PRIVATE_DIR/defines.json") >"$OUT/build.log" 2>&1 \
    || die "flutter build failed; see $OUT/build.log"
}

simulator() {
  step "simulator"
  if [[ -n "$REUSE_DEVICE" ]]; then
    UDID="$REUSE_DEVICE"
    xcrun simctl list devices -j | jq -e --arg u "$UDID" '[.devices[][] | select(.udid == $u)] | length == 1' >/dev/null \
      || die "no simulator $UDID"
    xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
    state_set CREATED_DEVICE 0
  else
    local type runtime
    type="$(xcrun simctl list devicetypes -j | jq -r --arg n "$DEVICE_TYPE" '.devicetypes[] | select(.name == $n) | .identifier')"
    [[ -n "$type" ]] || die "no device type \"$DEVICE_TYPE\" (EMOTELY_DEVICE_TYPE)"
    runtime="$(xcrun simctl list runtimes -j | jq -r '[.runtimes[] | select(.platform == "iOS" and .isAvailable)] | sort_by(.version | split(".") | map(tonumber)) | last | .identifier // empty')"
    [[ -n "$runtime" ]] || die "no available iOS runtime"
    UDID="$(xcrun simctl create "emotely-verify-$(date +%H%M%S)" "$type" "$runtime")"
    state_set CREATED_DEVICE 1
    xcrun simctl boot "$UDID"
  fi
  state_set UDID "$UDID"
  xcrun simctl bootstatus "$UDID" -b >/dev/null || die "simulator $UDID did not boot"
  local bundle_id
  bundle_id="$(plutil -extract CFBundleIdentifier raw "$RUNNER_APP/Info.plist")"
  state_set BUNDLE_ID "$bundle_id"
  # A reused simulator may hold another account's session; start signed out.
  xcrun simctl uninstall "$UDID" "$bundle_id" >/dev/null 2>&1 || true
  log "device $UDID"
}

launch() {
  step "launch"
  local vm_file="$PRIVATE_DIR/vmservice" deadline pid
  # Outlives this command: `down` stops it.
  (cd "$APP_DIR" && exec fvm flutter run -d "$UDID" --debug \
    --use-application-binary="$RUNNER_APP" \
    --dart-define-from-file="$PRIVATE_DIR/defines.json" \
    --vmservice-out-file="$vm_file") </dev/null >"$OUT/flutter-run.log" 2>&1 &
  pid=$!
  state_set RUN_PID "$pid"
  deadline=$((SECONDS + 240))
  until [[ -s "$vm_file" ]]; do
    kill -0 "$pid" 2>/dev/null || die "flutter run exited; see $OUT/flutter-run.log"
    ((SECONDS < deadline)) || die "no VM service within 240s; see $OUT/flutter-run.log"
    sleep 1
  done
  # Flutter writes the ws:// URI; older releases wrote the http:// one.
  local uri
  uri="$(tr -d '[:space:]' <"$vm_file")"
  case "$uri" in
    ws://*) ;;
    http://*) uri="ws://${uri#http://}" && uri="${uri%/}/ws" ;;
    *) die "unexpected VM service URI in --vmservice-out-file" ;;
  esac
  state_set URI "$uri"
  log "VM service up"
}

register() {
  step "register"
  marionette register "$INSTANCE" "$(state_get URI)" >/dev/null || die "marionette register failed"
  retry 60 m get-interactive-elements || die "marionette cannot reach the app"
}

# Through the app's own screen, which asks a debug build's smoke account for
# its password. Before any recording, and nothing of it reaches the bundle.
sign_in() {
  step "sign-in"
  retry 60 m enter-text --key sign_in_page.email --input "$SMOKE_EMAIL" \
    || die "no email field (a build without SMOKE_EMAIL?)"
  retry 10 m tap --key sign_in_page.send_code || die "could not submit the email"
  retry 20 m enter-text --key sign_in_page.password --input "$SMOKE_PASSWORD" \
    || die "no password step: the build does not name this account (rebuild without --skip-build)"
  retry 10 m tap --key sign_in_page.password_sign_in || die "could not submit the password"
  retry 60 on_screen app_shell.journal || die "not signed in after 60s"
  log "signed in"
}

cmd_up() {
  REUSE_DEVICE=""
  SKIP_BUILD=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --device) REUSE_DEVICE="${2:?--device needs a udid}"; shift 2 ;;
      --out) OUT="${2:?--out needs a directory}"; shift 2 ;;
      --skip-build) SKIP_BUILD=1; shift ;;
      *) die "unknown option $1" ;;
    esac
  done
  [[ ! -f "$STATE_FILE" ]] || die "a session is already up ($(state_get INSTANCE)): run-app.sh down first"
  mkdir -p "$STATE_DIR"
  OUT="${OUT:-$APP_DIR/build/evidence/$(date +%Y%m%d-%H%M%S)}"
  mkdir -p "$OUT"
  OUT="$(cd "$OUT" && pwd)"
  INSTANCE="emotely-verify-$$"
  : >"$STATE_FILE"
  state_set INSTANCE "$INSTANCE"
  state_set OUT "$OUT"
  state_set STARTED_AT "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  private_dir

  # A failed `up` leaves the session for `down` to clean away.
  preflight
  build
  simulator
  launch
  register
  sign_in

  STEP="up"
  log "ready: the app is on the signed-in journal"
  cmd_status
}

cmd_status() {
  require_session
  cat <<EOF
instance  $INSTANCE
device    $(state_get UDID)
bundle    $OUT
drive     marionette -i $INSTANCE get-interactive-elements
EOF
}

# --- record ---------------------------------------------------------------------

record_start() {
  STEP="record"
  require_session
  local pid file n=1
  pid="$(state_get VIDEO_PID)"
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    die "already recording to $(state_get VIDEO_FILE)"
  fi
  file="$OUT/video.webm"
  while [[ -e "$file" ]]; do
    n=$((n + 1))
    file="$OUT/video-$n.webm"
  done
  # Outlives this command: `record stop` ends it.
  marionette -i "$INSTANCE" record-video --output "$file" >"$STATE_DIR/video.log" 2>&1 &
  pid=$!
  sleep 2
  kill -0 "$pid" 2>/dev/null || die "record-video exited: $(cat "$STATE_DIR/video.log")"
  state_set VIDEO_PID "$pid"
  state_set VIDEO_FILE "$file"
  log "recording to $file"
}

record_stop() {
  STEP="record"
  require_session
  local pid deadline
  pid="$(state_get VIDEO_PID)"
  if [[ -z "$pid" ]] || ! kill -0 "$pid" 2>/dev/null; then
    log "not recording"
    return
  fi
  # The recorder finalises the file on SIGINT. `marionette` is a pub wrapper
  # script that does not exec, so the signal goes to its child, the Dart VM;
  # the wrapper then exits with it.
  pkill -INT -P "$pid" 2>/dev/null || kill -INT "$pid" 2>/dev/null
  deadline=$((SECONDS + 30))
  while kill -0 "$pid" 2>/dev/null && ((SECONDS < deadline)); do
    sleep 1
  done
  if kill -0 "$pid" 2>/dev/null; then
    log "the recorder did not stop on SIGINT; the video may be cut short"
    pkill -KILL -P "$pid" 2>/dev/null || true
    kill -KILL "$pid" 2>/dev/null || true
  fi
  state_set VIDEO_PID ""
  log "saved $(state_get VIDEO_FILE)"
}

cmd_record() {
  case "${1:-}" in
    start) record_start ;;
    stop) record_stop ;;
    *) die "record start|stop" ;;
  esac
}

# --- collect --------------------------------------------------------------------

# Replaces the smoke account's address, password and user id in every text
# file of the bundle, whatever wrote them.
scrub_bundle() {
  local file content user_id
  user_id="$(state_get SMOKE_USER_ID)"
  while IFS= read -r -d '' file; do
    content="$(<"$file")"
    content="${content//"$SMOKE_PASSWORD"/[smoke password]}"
    content="${content//"$SMOKE_EMAIL"/[smoke account]}"
    [[ -n "$user_id" ]] && content="${content//"$user_id"/[smoke user id]}"
    printf '%s\n' "$content" >"$file"
  done < <(find "$OUT" -type f \( -name '*.log' -o -name '*.json' -o -name '*.txt' \) -print0)
}

cmd_collect() {
  STEP="collect"
  require_session
  read_smoke_account
  private_dir
  record_stop
  STEP="collect"
  m get-logs >"$OUT/app.log" 2>&1 || log "get-logs failed"

  # PostHog flushes on a timer or when the app goes to the background.
  local udid bundle_id started user_id
  udid="$(state_get UDID)"
  bundle_id="$(state_get BUNDLE_ID)"
  started="$(state_get STARTED_AT)"
  user_id="$(state_get SMOKE_USER_ID)"
  printf 'header = "Authorization: Bearer %s"\n' "$(env_value POSTHOG_PERSONAL_API_KEY)" \
    >"$PRIVATE_DIR/posthog.curl"
  xcrun simctl launch "$udid" com.apple.Preferences >/dev/null 2>&1 || true
  local deadline previous=-1 count=0 events=""
  deadline=$((SECONDS + 150))
  while ((SECONDS < deadline)); do
    sleep 15
    events="$(curl -sS --fail -K "$PRIVATE_DIR/posthog.curl" \
      "$POSTHOG_API/events/?distinct_id=$user_id&after=$started&limit=500")" || continue
    count="$(jq '.results | length' <<<"$events")"
    # Settled: something arrived and nothing more since the last look.
    if ((count > 0 && count == previous)); then
      break
    fi
    previous=$count
  done
  # Back to the app, where the agent left it.
  xcrun simctl launch "$udid" "$bundle_id" >/dev/null 2>&1 || true
  # Ids, types, counts and status codes only (ADR 0005); PostHog's own `$`
  # properties (IP, geo, device) stay out of a public bundle.
  jq '[.results // [] | .[] | {event, timestamp,
        properties: (.properties | with_entries(select(.key | startswith("$") | not)))}]
      | sort_by(.timestamp)' <<<"${events:-"{}"}" >"$OUT/posthog-events.json"
  log "$(jq length "$OUT/posthog-events.json") PostHog event(s)"

  jq -n --arg started "$started" --arg collected "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg commit "$(git -C "$REPO" rev-parse --short HEAD)" --arg device "$udid" \
    --argjson files "$(cd "$OUT" && find . -type f ! -name summary.json | sed 's|^\./||' | sort | jq -R . | jq -s .)" \
    '{started: $started, collected: $collected, commit: $commit, device: $device, files: $files}' \
    >"$OUT/summary.json"
  scrub_bundle
  printf 'run-app: evidence in %s\n' "$OUT" >&2
}

# --- down -----------------------------------------------------------------------

cmd_down() {
  STEP="down"
  [[ -f "$STATE_FILE" ]] || {
    log "no session"
    return
  }
  INSTANCE="$(state_get INSTANCE)"
  OUT="$(state_get OUT)"
  set +e
  record_stop
  STEP="down"
  marionette unregister "$INSTANCE" >/dev/null 2>&1
  local pid udid
  pid="$(state_get RUN_PID)"
  if [[ -n "$pid" ]]; then
    kill "$pid" 2>/dev/null
  fi
  udid="$(state_get UDID)"
  if [[ -n "$udid" && "$(state_get CREATED_DEVICE)" == 1 ]]; then
    xcrun simctl shutdown "$udid" >/dev/null 2>&1
    xcrun simctl delete "$udid" >/dev/null 2>&1
    log "deleted simulator $udid"
  fi
  rm -rf "$STATE_DIR"
  set -e
  log "down; the bundle stays in $OUT"
}

main() {
  case "${1:-help}" in
    up) shift; cmd_up "$@" ;;
    status) cmd_status ;;
    record) shift; cmd_record "$@" ;;
    collect) cmd_collect ;;
    down) cmd_down ;;
    help | -h | --help)
      usage
      printf '\n---\n\n'
      marionette help-ai 2>/dev/null || printf 'marionette is not installed: dart pub global activate marionette_cli\n'
      ;;
    *)
      usage >&2
      exit 64
      ;;
  esac
}

main "$@"
