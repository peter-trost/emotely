#!/usr/bin/env bash
# Runs the Flutter app on an iOS simulator against the deployed agent, drives
# one named flow with marionette, and writes an evidence bundle: a screenshot
# per flow step, a video, the app log, the flutter run log and the PostHog
# events the run produced. `run-app.sh help` for usage.
#
# Signs in as the smoke account and nobody else (ADR 0005: this repository
# and its attachments are public, so evidence holds made-up content only).
# Secrets are read blind from the agent's .env.local, never printed, never
# written into the bundle, and scrubbed from every text file in it.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLOWS_DIR="$SKILL_DIR/flows"
REPO="$(git -C "$SKILL_DIR" rev-parse --show-toplevel)"
APP_DIR="$REPO/apps/mobile/app"
# A worktree has no .env.local of its own; the main checkout does.
MAIN_CHECKOUT="$(dirname "$(git -C "$SKILL_DIR" rev-parse --path-format=absolute --git-common-dir)")"
ENV_FILE="${EMOTELY_ENV_FILE:-$MAIN_CHECKOUT/apps/agent/.env.local}"
DEVICE_TYPE="${EMOTELY_DEVICE_TYPE:-iPhone 17 Pro}"
POSTHOG_API="https://eu.posthog.com/api/projects/262464"
# The hosted project, as `lib/app/environment.dart` defaults to it. Both are
# public (ADR 0010); the CLI needs them to learn the smoke user's id, which
# is how it finds this run's PostHog events among everyone else's.
SUPABASE_URL="https://khfkszlujgkfjgnawdlf.supabase.co"
SUPABASE_PUBLISHABLE_KEY="sb_publishable_di6BB76PPuuoDklt7jtI0w_KlwO_8JF"
# Marionette's own reference, shown by `help`.
MARIONETTE_DOCS="https://github.com/leancodepl/marionette_mcp/blob/main/docs/cli.md"

# CocoaPods refuses to run under a non-UTF-8 locale.
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

usage() {
  cat <<EOF
Usage: run-app.sh <command>

  run <flow> [options]  Build a debug app, launch it on a simulator, sign in as
                        the smoke account, run flows/<flow>.yaml and write the
                        evidence bundle. Exits non-zero naming the failed step.
  check                 Validate every flow file (no device needed).
  list                  List the flows.
  help                  This text, then marionette's reference (help-ai).

Options for run:
  --device <udid>       Reuse this simulator (booted if needed; the app is
                        uninstalled first, so the run still starts signed out).
                        Default: a fresh simulator ($DEVICE_TYPE, newest iOS),
                        deleted afterwards.
  --out <dir>           Evidence directory.
                        Default: apps/mobile/app/build/evidence/<time>-<flow>.
  --skip-build          Reuse apps/mobile/app/build/ios/iphonesimulator/Runner.app.
                        Only a build this CLI made carries marionette and the
                        smoke account; anything else fails at sign-in.
  --keep                Leave the app running (and a fresh simulator alive)
                        after the flow; prints the VM service URI so marionette
                        can keep driving it: marionette --uri <uri> <command>.

Flows (flows/*.yaml) are data. Every flow starts on the journal, signed in.
A step is one action, plus optional modifiers:

  - tap: {key: <k>}               also {text: <t>}; retried until it lands
  - enter-text: {key: <k>}
    input: <text>                 made-up content only: evidence is public
  - scroll-to: {key: <k>}
  - wait: {key: <k>}              until it is on screen; also {text: <t>}
  - screenshot: <name>            NN-<name>.png in the bundle
  - back: true                    the system back button
  - branch:                       waits until one 'when' is on screen, runs
      - when: {key: <k>}          that branch's steps
        steps: [...]
  modifiers:  timeout: <seconds>  default 15
              optional: true      skip the step if its target never appears
                                  (then the timeout defaults to 3)

Matchers are widget keys (ValueKey<String>, e.g. Key('journal_view.start')) or
visible text. Never coordinates: give the widget a key instead.

Environment: SMOKE_EMAIL, SMOKE_PASSWORD, POSTHOG_KEY and
POSTHOG_PERSONAL_API_KEY are read from $ENV_FILE
(EMOTELY_ENV_FILE overrides the path). SMOKE_EMAIL must be on a reserved test
domain (example.com, .test, ...): the CLI refuses any other account.

Marionette: $MARIONETTE_DOCS
EOF
}

# --- output --------------------------------------------------------------------

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

# --- flows ---------------------------------------------------------------------

flow_json() { yq -o=json '.' "$1"; }

# Prints one problem per line for a flow's JSON on stdin; nothing when valid.
flow_problems() {
  jq -r '
    def matcher_problems($where):
      if type != "object" then "\($where): matcher must be {key: ...} or {text: ...}"
      elif ((keys - ["key", "text"]) | length) > 0 or (keys | length) != 1
        then "\($where): matcher takes exactly one of key, text"
      elif ((.key // .text) | type) != "string" or ((.key // .text) == "")
        then "\($where): matcher value must be a non-empty string"
      elif ((.key // "") | startswith("sign_in_page."))
        then "\($where): sign-in belongs to the CLI; flows start signed in"
      else empty end;
    def step_problems($where):
      (keys - ["timeout", "optional", "input"]) as $actions
      | if ($actions | length) != 1
          then "\($where): one action per step (tap, enter-text, scroll-to, wait, screenshot, back, branch), found \($actions)"
        else $actions[0] as $a
          | ( if ($a == "tap" or $a == "scroll-to" or $a == "wait") then .[$a] | matcher_problems("\($where) \($a)")
              elif $a == "enter-text" then
                (.[$a] | matcher_problems("\($where) enter-text")),
                (if (.input | type) != "string" then "\($where) enter-text: needs input" else empty end)
              elif $a == "screenshot" then
                (if (.screenshot | type) != "string" or (.screenshot | test("^[a-z0-9-]+$") | not)
                  then "\($where) screenshot: name must be lowercase letters, digits and dashes" else empty end)
              elif $a == "back" then
                (if .back != true then "\($where) back: must be true" else empty end)
              elif $a == "branch" then
                (if (.branch | type) != "array" or (.branch | length) == 0 then "\($where) branch: needs a list of when/steps"
                 else .branch | to_entries[] | (.key + 1) as $i | .value
                   | (.when | matcher_problems("\($where) branch \($i) when")),
                     (if (.steps | type) != "array" or (.steps | length) == 0
                        then "\($where) branch \($i): needs steps" else empty end)
                 end)
              else "\($where): unknown action \($a)" end ),
            (if has("input") and $a != "enter-text" then "\($where): input belongs to enter-text" else empty end),
            (if has("timeout") and ((.timeout | type) != "number" or .timeout <= 0)
               then "\($where): timeout must be a positive number of seconds" else empty end),
            (if has("optional") and (.optional | type) != "boolean" then "\($where): optional must be true or false" else empty end)
        end;
    def walk_steps($prefix):
      to_entries[] | .key as $i | .value
      | ("\($prefix)\($i + 1)") as $where
      | if type != "object" then "\($where): a step is a map"
        else step_problems("step \($where)"),
             (if has("branch") and (.branch | type) == "array"
                then .branch | to_entries[] | .key as $b
                  | (.value.steps // []) | walk_steps("\($where).\($b + 1).")
                else empty end)
        end;
    if type != "object" then "the flow must be a map"
    else
      (if (.summary | type) != "string" then "summary: a one-line description is required" else empty end),
      (if (.steps | type) != "array" or (.steps | length) == 0 then "steps: at least one step is required"
       else .steps | walk_steps("") end),
      ([.. | objects | .screenshot? // empty] | group_by(.) | map(select(length > 1) | .[0])[]
        | "screenshot \(.): names must be unique")
    end'
}

check_flow() {
  local file="$1" problems
  problems="$(flow_json "$file" | flow_problems)" || die "$file: not valid YAML"
  if [[ -n "$problems" ]]; then
    printf '%s:\n' "${file#"$REPO"/}" >&2
    printf '  %s\n' "${problems//$'\n'/$'\n'  }" >&2
    return 1
  fi
}

cmd_check() {
  STEP="check"
  local file failed=0 count=0
  for file in "$FLOWS_DIR"/*.yaml; do
    [[ -e "$file" ]] || die "no flows in $FLOWS_DIR"
    count=$((count + 1))
    check_flow "$file" || failed=1
  done
  [[ $failed -eq 0 ]] || die "flows have problems (above)"
  log "$count flow(s) valid"
}

cmd_list() {
  local file
  for file in "$FLOWS_DIR"/*.yaml; do
    [[ -e "$file" ]] || continue
    printf '%-20s %s\n' "$(basename "$file" .yaml)" "$(yq '.summary' "$file")"
  done
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

# --- marionette ----------------------------------------------------------------

INSTANCE="emotely-verify-$$"
DEFAULT_TIMEOUT=15
OPTIONAL_TIMEOUT=3

m() { marionette -i "$INSTANCE" "$@"; }

# Whether the matcher is on screen now.
present() {
  local matcher="$1" kind value elements
  kind="$(jq -r 'keys[0]' <<<"$matcher")"
  value="$(jq -r '.[keys[0]]' <<<"$matcher")"
  elements="$(m get-interactive-elements 2>/dev/null)" || return 1
  case "$kind" in
    key) grep -qF "Key: \"$value\"" <<<"$elements" ;;
    text) grep -qF "Text: \"$value\"" <<<"$elements" ;;
    *) return 1 ;;
  esac
}

# Retries "$@" until it succeeds or $1 seconds pass; the command's last
# output is kept in LAST_OUTPUT.
LAST_OUTPUT=""
retry_for() {
  local seconds="$1" deadline
  shift
  deadline=$((SECONDS + seconds))
  while :; do
    if LAST_OUTPUT="$("$@" 2>&1)"; then
      return 0
    fi
    ((SECONDS < deadline)) || return 1
    sleep 1
  done
}

# --- the run -----------------------------------------------------------------

OUT=""
FLOW=""
REUSE_DEVICE=""
SKIP_BUILD=0
KEEP=0
UDID=""
CREATED_DEVICE=0
RUN_PID=""
VIDEO_PID=""
REGISTERED=0
PRIVATE_DIR=""
SMOKE_EMAIL=""
SMOKE_PASSWORD=""
SMOKE_USER_ID=""
RUNNER_APP=""
SHOT=0
STEPS_JSON="[]"
STARTED_AT=""
FAILED_STEP=""

cleanup() {
  local status=$?
  set +e
  stop_video
  [[ $REGISTERED -eq 1 ]] && marionette unregister "$INSTANCE" >/dev/null 2>&1
  if [[ $KEEP -eq 1 && $status -eq 0 ]]; then
    log "kept running on $UDID (flutter run is pid $RUN_PID):"
    log "  marionette --uri $(cat "$PRIVATE_DIR/ws" 2>/dev/null) <command>"
  else
    if [[ -n "$RUN_PID" ]]; then
      kill "$RUN_PID" 2>/dev/null
      wait "$RUN_PID" 2>/dev/null
    fi
    if [[ $CREATED_DEVICE -eq 1 ]]; then
      xcrun simctl shutdown "$UDID" >/dev/null 2>&1
      xcrun simctl delete "$UDID" >/dev/null 2>&1
    fi
  fi
  [[ -n "$OUT" && -d "$OUT" ]] && scrub_bundle
  [[ -n "$PRIVATE_DIR" ]] && rm -rf "$PRIVATE_DIR"
  if [[ -n "$OUT" && -d "$OUT" ]]; then
    printf 'run-app: evidence in %s\n' "$OUT" >&2
  fi
  exit "$status"
}

stop_video() {
  if [[ -n "$VIDEO_PID" ]]; then
    # The recorder finalises the file on SIGINT. `marionette` is a pub
    # wrapper script that does not exec, so the signal goes to its child,
    # the Dart VM; the wrapper then exits with it.
    pkill -INT -P "$VIDEO_PID" 2>/dev/null || kill -INT "$VIDEO_PID" 2>/dev/null
    local deadline=$((SECONDS + 30))
    while kill -0 "$VIDEO_PID" 2>/dev/null && ((SECONDS < deadline)); do
      sleep 1
    done
    if kill -0 "$VIDEO_PID" 2>/dev/null; then
      log "the recorder did not stop on SIGINT; video.webm may be cut short"
      pkill -KILL -P "$VIDEO_PID" 2>/dev/null
      kill -KILL "$VIDEO_PID" 2>/dev/null
    fi
    wait "$VIDEO_PID" 2>/dev/null
    VIDEO_PID=""
  fi
}

# Replaces the smoke account's address, password and user id in every text
# file of the bundle, whatever wrote them.
scrub_bundle() {
  local file content
  while IFS= read -r -d '' file; do
    content="$(<"$file")"
    [[ -n "$SMOKE_PASSWORD" ]] && content="${content//"$SMOKE_PASSWORD"/[smoke password]}"
    [[ -n "$SMOKE_EMAIL" ]] && content="${content//"$SMOKE_EMAIL"/[smoke account]}"
    [[ -n "$SMOKE_USER_ID" ]] && content="${content//"$SMOKE_USER_ID"/[smoke user id]}"
    printf '%s\n' "$content" >"$file"
  done < <(find "$OUT" -type f \( -name '*.log' -o -name '*.json' -o -name '*.txt' \) -print0)
}

record_step() {
  local description="$1" status="$2" started="$3"
  STEPS_JSON="$(jq -c --arg d "$description" --arg s "$status" \
    --argjson t "$((SECONDS - started))" '. + [{step: $d, status: $s, seconds: $t}]' \
    <<<"$STEPS_JSON")"
  printf '%s  %s (%ss)\n' "$status" "$description" "$((SECONDS - started))" >>"$OUT/steps.log"
}

screenshot() {
  SHOT=$((SHOT + 1))
  local file
  file="$(printf '%s/%02d-%s.png' "$OUT" "$SHOT" "$1")"
  m take-screenshots --output "$file" >/dev/null
}

# Runs one flow step (a JSON object). Returns non-zero on failure.
run_step() {
  local step="$1" action target optional timeout description started
  action="$(jq -r 'keys - ["timeout", "optional", "input"] | .[0]' <<<"$step")"
  optional="$(jq -r '.optional // false' <<<"$step")"
  if [[ "$optional" == true ]]; then
    timeout="$(jq -r --argjson d "$OPTIONAL_TIMEOUT" '.timeout // $d' <<<"$step")"
  else
    timeout="$(jq -r --argjson d "$DEFAULT_TIMEOUT" '.timeout // $d' <<<"$step")"
  fi
  target="$(jq -c --arg a "$action" '.[$a]' <<<"$step")"
  description="$action $(jq -r 'if type == "object" then to_entries[0] | "\(.key)=\(.value)"
    elif type == "array" then "of \(length)" else tostring end' <<<"$target")"
  started=$SECONDS
  STEP="flow: $description"

  # Two words, --key|--text and the value; macOS bash 3.2 has no mapfile.
  local -a args=(--none none)
  case "$action" in
    tap | scroll-to | enter-text)
      args=("--$(jq -r 'keys[0]' <<<"$target")" "$(jq -r '.[keys[0]]' <<<"$target")")
      ;;
  esac

  local ok=0
  case "$action" in
    tap) retry_for "$timeout" m tap "${args[@]}" || ok=1 ;;
    scroll-to) retry_for "$timeout" m scroll-to "${args[@]}" || ok=1 ;;
    enter-text)
      local input
      input="$(jq -r '.input' <<<"$step")"
      retry_for "$timeout" m enter-text "${args[@]}" --input "$input" || ok=1
      ;;
    wait) retry_for "$timeout" present "$target" || ok=1 ;;
    screenshot) screenshot "$(jq -r '.screenshot' <<<"$step")" || ok=1 ;;
    back) m press-back-button >/dev/null || ok=1 ;;
    branch) run_branch "$step" "$timeout" || ok=1 ;;
    *) ok=1 ;;
  esac

  if [[ $ok -eq 0 ]]; then
    record_step "$description" ok "$started"
  elif [[ "$optional" == true ]]; then
    record_step "$description" skipped "$started"
  else
    record_step "$description" failed "$started"
    FAILED_STEP="$description"
    log "${LAST_OUTPUT:-gave up after ${timeout}s}"
    return 1
  fi
}

# Waits until one branch's `when` is on screen, then runs its steps.
run_branch() {
  local step="$1" timeout="$2" count i when deadline
  count="$(jq '.branch | length' <<<"$step")"
  deadline=$((SECONDS + timeout))
  while :; do
    for ((i = 0; i < count; i++)); do
      when="$(jq -c --argjson i "$i" '.branch[$i].when' <<<"$step")"
      if present "$when"; then
        log "branch $((i + 1)): $when"
        printf 'branch %s: %s\n' "$((i + 1))" "$when" >>"$OUT/steps.log"
        run_steps "$(jq -c --argjson i "$i" '.branch[$i].steps' <<<"$step")"
        return
      fi
    done
    ((SECONDS < deadline)) || {
      LAST_OUTPUT="no branch matched within ${timeout}s"
      return 1
    }
    sleep 1
  done
}

run_steps() {
  local steps="$1" count i
  count="$(jq 'length' <<<"$steps")"
  for ((i = 0; i < count; i++)); do
    run_step "$(jq -c --argjson i "$i" '.[$i]' <<<"$steps")" || return 1
  done
}

preflight() {
  step "preflight"
  local tool
  for tool in fvm xcrun marionette jq yq curl ffmpeg plutil; do
    command -v "$tool" >/dev/null || die "missing tool: $tool"
  done
  local app_version cli_version
  app_version="$(yq '.packages.marionette_flutter.version' "$REPO/apps/mobile/pubspec.lock")"
  cli_version="$(marionette --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
  if [[ -z "$cli_version" ]]; then
    cli_version="$(dart pub global list 2>/dev/null | sed -n 's/^marionette_cli \([0-9.]*\).*/\1/p')"
  fi
  [[ "$cli_version" == "$app_version" ]] \
    || die "marionette_cli is ${cli_version:-missing}, the app has marionette_flutter $app_version: dart pub global activate marionette_cli $app_version"

  check_flow "$FLOWS_DIR/$FLOW.yaml" || die "flow $FLOW is invalid (above)"

  [[ -r "$ENV_FILE" ]] || die "cannot read $ENV_FILE"
  SMOKE_EMAIL="$(env_value SMOKE_EMAIL)"
  SMOKE_PASSWORD="$(env_value SMOKE_PASSWORD)"
  [[ -n "$SMOKE_EMAIL" && -n "$SMOKE_PASSWORD" ]] || die "SMOKE_EMAIL and SMOKE_PASSWORD must be set in $ENV_FILE"
  is_reserved_test_address "$SMOKE_EMAIL" \
    || die "SMOKE_EMAIL is not on a reserved test domain; the CLI signs in as the smoke account only"

  # Everything secret goes through files in a private directory (mode 700),
  # never through argv or the bundle.
  PRIVATE_DIR="$(mktemp -d)"
  chmod 700 "$PRIVATE_DIR"
  jq -n --arg email "$SMOKE_EMAIL" --arg key "$(env_value POSTHOG_KEY)" \
    '{SMOKE_EMAIL: $email, POSTHOG_KEY: $key}' >"$PRIVATE_DIR/defines.json"
  jq -n --arg email "$SMOKE_EMAIL" --arg password "$SMOKE_PASSWORD" \
    '{email: $email, password: $password}' >"$PRIVATE_DIR/grant.json"
  printf 'header = "apikey: %s"\n' "$SUPABASE_PUBLISHABLE_KEY" >"$PRIVATE_DIR/supabase.curl"
  printf 'header = "Authorization: Bearer %s"\n' "$(env_value POSTHOG_PERSONAL_API_KEY)" \
    >"$PRIVATE_DIR/posthog.curl"

  # The smoke user's id: proves the credentials before a two-minute build,
  # and is how the run's PostHog events are told apart from everyone else's.
  SMOKE_USER_ID="$(curl -sS --fail-with-body -K "$PRIVATE_DIR/supabase.curl" \
    -H 'Content-Type: application/json' --data @"$PRIVATE_DIR/grant.json" \
    "$SUPABASE_URL/auth/v1/token?grant_type=password" | jq -r '.user.id // empty')" \
    || die "the smoke account's password grant failed"
  [[ -n "$SMOKE_USER_ID" ]] || die "the smoke account's password grant returned no user"
  rm -f "$PRIVATE_DIR/grant.json"
}

build() {
  step "build"
  RUNNER_APP="$APP_DIR/build/ios/iphonesimulator/Runner.app"
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
    || die "flutter build failed; see build.log"
}

simulator() {
  step "simulator"
  if [[ -n "$REUSE_DEVICE" ]]; then
    UDID="$REUSE_DEVICE"
    xcrun simctl list devices -j | jq -e --arg u "$UDID" '[.devices[][] | select(.udid == $u)] | length == 1' >/dev/null \
      || die "no simulator $UDID"
    xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
  else
    local type runtime
    type="$(xcrun simctl list devicetypes -j | jq -r --arg n "$DEVICE_TYPE" '.devicetypes[] | select(.name == $n) | .identifier')"
    [[ -n "$type" ]] || die "no device type \"$DEVICE_TYPE\" (EMOTELY_DEVICE_TYPE)"
    runtime="$(xcrun simctl list runtimes -j | jq -r '[.runtimes[] | select(.platform == "iOS" and .isAvailable)] | sort_by(.version | split(".") | map(tonumber)) | last | .identifier // empty')"
    [[ -n "$runtime" ]] || die "no available iOS runtime"
    UDID="$(xcrun simctl create "emotely-verify-$(date +%H%M%S)" "$type" "$runtime")"
    CREATED_DEVICE=1
    xcrun simctl boot "$UDID"
  fi
  xcrun simctl bootstatus "$UDID" -b >/dev/null || die "simulator $UDID did not boot"
  local bundle_id
  bundle_id="$(plutil -extract CFBundleIdentifier raw "$RUNNER_APP/Info.plist")"
  # A reused simulator may hold another account's session; start signed out.
  xcrun simctl uninstall "$UDID" "$bundle_id" >/dev/null 2>&1 || true
  log "device $UDID"
}

launch() {
  step "launch"
  local vm_file="$PRIVATE_DIR/vmservice" deadline
  (cd "$APP_DIR" && exec fvm flutter run -d "$UDID" --debug \
    --use-application-binary="$RUNNER_APP" \
    --dart-define-from-file="$PRIVATE_DIR/defines.json" \
    --vmservice-out-file="$vm_file") </dev/null >"$OUT/flutter-run.log" 2>&1 &
  RUN_PID=$!
  deadline=$((SECONDS + 240))
  until [[ -s "$vm_file" ]]; do
    kill -0 "$RUN_PID" 2>/dev/null || die "flutter run exited; see flutter-run.log"
    ((SECONDS < deadline)) || die "no VM service within 240s; see flutter-run.log"
    sleep 1
  done
  # Flutter writes the ws:// URI; older releases wrote the http:// one
  # (http://127.0.0.1:PORT/TOKEN=/ -> ws://127.0.0.1:PORT/TOKEN=/ws).
  local uri
  uri="$(tr -d '[:space:]' <"$vm_file")"
  case "$uri" in
    ws://*) ;;
    http://*) uri="ws://${uri#http://}" && uri="${uri%/}/ws" ;;
    *) die "unexpected VM service URI in --vmservice-out-file" ;;
  esac
  printf '%s\n' "$uri" >"$PRIVATE_DIR/ws"
  log "VM service up"
}

register() {
  step "register"
  marionette register "$INSTANCE" "$(cat "$PRIVATE_DIR/ws")" >/dev/null || die "marionette register failed"
  REGISTERED=1
  retry_for 60 m get-interactive-elements || die "marionette cannot reach the app: $LAST_OUTPUT"
}

# Through the app's own screen, which asks a debug build's smoke account for
# its password. Nothing is recorded: no screenshot, no video, no output.
sign_in() {
  step "sign-in"
  retry_for 60 m enter-text --key sign_in_page.email --input "$SMOKE_EMAIL" \
    || die "no email field (a build without SMOKE_EMAIL?)"
  retry_for 10 m tap --key sign_in_page.send_code || die "could not submit the email"
  retry_for 20 m enter-text --key sign_in_page.password --input "$SMOKE_PASSWORD" \
    || die "no password step: the build does not name this account (rebuild without --skip-build)"
  retry_for 10 m tap --key sign_in_page.password_sign_in || die "could not submit the password"
  retry_for 60 present '{"key":"app_shell.journal"}' || die "not signed in after 60s"
  log "signed in"
}

record() {
  step "record"
  # Not through m(): a backgrounded function is a subshell, one more process
  # between VIDEO_PID and the Dart VM that stop_video has to reach.
  marionette -i "$INSTANCE" record-video --output "$OUT/video.webm" >"$PRIVATE_DIR/video.log" 2>&1 &
  VIDEO_PID=$!
  sleep 2
  kill -0 "$VIDEO_PID" 2>/dev/null || die "record-video exited: $(cat "$PRIVATE_DIR/video.log")"
}

flow() {
  step "flow"
  : >"$OUT/steps.log"
  local status=0
  run_steps "$(flow_json "$FLOWS_DIR/$FLOW.yaml" | jq -c '.steps')" || status=1
  if [[ $status -ne 0 ]]; then
    STEP="flow"
    screenshot failure || true
  fi
  return "$status"
}

collect() {
  step "evidence"
  stop_video
  m get-logs >"$OUT/app.log" 2>&1 || log "get-logs failed"
  # PostHog flushes on a timer or when the app goes to the background.
  xcrun simctl launch "$UDID" com.apple.Preferences >/dev/null 2>&1 || true
  local deadline previous=-1 count=0 events
  deadline=$((SECONDS + 150))
  while ((SECONDS < deadline)); do
    sleep 15
    events="$(curl -sS --fail -K "$PRIVATE_DIR/posthog.curl" \
      "$POSTHOG_API/events/?distinct_id=$SMOKE_USER_ID&after=$STARTED_AT&limit=200")" || continue
    count="$(jq '.results | length' <<<"$events")"
    # Settled: something arrived and nothing more since the last look.
    if ((count > 0 && count == previous)); then
      break
    fi
    previous=$count
  done
  # Ids, types, counts and status codes only (ADR 0005); PostHog's own `$`
  # properties (IP, geo, device) stay out of a public bundle.
  jq '[.results // [] | .[] | {event, timestamp,
        properties: (.properties | with_entries(select(.key | startswith("$") | not)))}]
      | sort_by(.timestamp)' <<<"${events:-"{}"}" >"$OUT/posthog-events.json"
  log "$(jq length "$OUT/posthog-events.json") PostHog event(s)"
}

summary() {
  local status="$1"
  jq -n --arg flow "$FLOW" --arg status "$status" --arg started "$STARTED_AT" \
    --arg failed "$FAILED_STEP" --argjson steps "$STEPS_JSON" \
    --arg commit "$(git -C "$REPO" rev-parse --short HEAD)" \
    '{flow: $flow, status: $status, started: $started, commit: $commit,
      failed_step: (if $failed == "" then null else $failed end), steps: $steps}' \
    >"$OUT/summary.json"
}

cmd_run() {
  FLOW="${1:-}"
  [[ -n "$FLOW" ]] || {
    usage >&2
    exit 64
  }
  shift
  [[ -f "$FLOWS_DIR/$FLOW.yaml" ]] || die "no flow $FLOW (run-app.sh list)"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --device) REUSE_DEVICE="${2:?--device needs a udid}"; shift 2 ;;
      --out) OUT="${2:?--out needs a directory}"; shift 2 ;;
      --skip-build) SKIP_BUILD=1; shift ;;
      --keep) KEEP=1; shift ;;
      *) die "unknown option $1" ;;
    esac
  done
  OUT="${OUT:-$APP_DIR/build/evidence/$(date +%Y%m%d-%H%M%S)-$FLOW}"
  mkdir -p "$OUT"
  OUT="$(cd "$OUT" && pwd)"
  STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  trap cleanup EXIT

  preflight
  build
  simulator
  launch
  register
  sign_in
  record
  if flow; then
    collect
    summary passed
    STEP="done"
    log "flow $FLOW passed"
  else
    collect
    summary failed
    STEP="flow"
    die "$FAILED_STEP"
  fi
}

main() {
  case "${1:-help}" in
    run) shift; cmd_run "$@" ;;
    check) cmd_check ;;
    list) cmd_list ;;
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
