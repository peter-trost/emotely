#!/usr/bin/env bash
# Set up a fresh Linux machine (a cloud agent container, a VM, a CI runner) so
# that every job in .github/workflows/ci.yml can be run locally: the agent
# (TypeScript), the app (Flutter), the web landing page (Dart/Jaspr) and the
# Supabase schema suite.
#
# Runs as root on x86_64 and installs into a system prefix, which is what a
# container is. It is not a dotfiles-friendly installer for a personal laptop:
# under sudo it would leave root-owned build output in your checkout and put the
# pub-cache in root's home.
#
#   scripts/setup-dev-environment.sh [--verify] [--help]
#
# Idempotent: re-running it is cheap, it re-downloads nothing that is already
# installed at the pinned version. Every step fails loudly — the script aborts
# on the first error and says which line died.
#
# Every version comes from the repository, never from this file:
#   Node          .nvmrc
#   pnpm          package.json  "packageManager"
#   Flutter       apps/app/.fvmrc
#   Dart          apps/web/scripts/vercel-install.sh  (checksum-pinned there)
#   Supabase CLI  .github/workflows/ci.yml  (supabase/setup-cli "version:")
#   jaspr_cli     .github/workflows/ci.yml
# Bumping a pin therefore means editing the file that owns it, and this script
# follows. It cross-checks the Dart pin against the CI one and refuses to run
# if the two have drifted apart.
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
# Everything this script installs lives under one prefix, so uninstalling is
# `rm -rf` of a single directory.
readonly PREFIX="${EMOTELY_TOOLCHAIN_PREFIX:-/opt/emotely-toolchain}"
readonly ENV_FILE="$PREFIX/env.sh"
readonly PROFILE_D="/etc/profile.d/emotely-toolchain.sh"

VERIFY=0

# --- output ------------------------------------------------------------------

if [ -t 1 ]; then
  readonly C_BOLD=$'\033[1m' C_DIM=$'\033[2m' C_RED=$'\033[31m' C_GREEN=$'\033[32m' C_OFF=$'\033[0m'
else
  readonly C_BOLD='' C_DIM='' C_RED='' C_GREEN='' C_OFF=''
fi

step() { printf '\n%s==> %s%s\n' "$C_BOLD" "$*" "$C_OFF"; }
info() { printf '    %s\n' "$*"; }
skip() { printf '    %s%s%s\n' "$C_DIM" "$*" "$C_OFF"; }
ok()   { printf '    %s✓%s %s\n' "$C_GREEN" "$C_OFF" "$*"; }

die() {
  printf '\n%s%sSETUP FAILED:%s %s\n' "$C_BOLD" "$C_RED" "$C_OFF" "$*" >&2
  exit 1
}

on_err() {
  local exit_code=$? line=$1 command=$2
  printf '\n%s%sSETUP FAILED%s at %s:%s (exit %s)\n' \
    "$C_BOLD" "$C_RED" "$C_OFF" "${BASH_SOURCE[0]}" "$line" "$exit_code" >&2
  printf '  command: %s\n' "$command" >&2
  printf '  The environment is NOT ready. Fix the error above and re-run.\n' >&2
  exit "$exit_code"
}
trap 'on_err "$LINENO" "$BASH_COMMAND"' ERR

usage() {
  sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  printf '\nOptions:\n'
  printf '  --verify   After installing, run every CI check (lint, typecheck,\n'
  printf '             tests, schema suite) to prove the environment works.\n'
  printf '  --help     Show this message.\n'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --verify) VERIFY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1 (try --help)" ;;
  esac
  shift
done

# --- helpers -----------------------------------------------------------------

# Read a pin out of a repository file, and refuse to guess if it is not there:
# a silently missing pin would install the wrong version.
pin() {
  local description=$1 file=$2 value
  value=$(cat)
  [ -n "$value" ] || die "could not read the $description pin from $file — has its format changed?"
  printf '%s' "$value"
}

fetch() {
  local url=$1 destination=$2
  curl --fail --silent --show-error --location --retry 3 --retry-delay 2 \
    --connect-timeout 20 --output "$destination" "$url" \
    || die "download failed: $url"
}

# Download and check against a sha256 published by the upstream project, not
# one copied into this script — a pin bump must not mean hand-copying digests.
fetch_verified() {
  local url=$1 destination=$2 expected_sha=$3
  fetch "$url" "$destination"
  printf '%s  %s\n' "$expected_sha" "$destination" | sha256sum --check --status \
    || die "checksum mismatch for $url — refusing to install it"
}

have() { command -v "$1" >/dev/null 2>&1; }

# `git config --add` appends every time; adding the same path on each run grows
# the global config without bound.
mark_git_safe() {
  local directory=$1
  git config --global --get-all safe.directory 2>/dev/null | grep -qxF "$directory" \
    || git config --global --add safe.directory "$directory"
}

# --- 0. host packages --------------------------------------------------------

step "Host packages"

[ "$(uname -s)" = "Linux" ] || die "this script targets Linux; on macOS use Homebrew (see the skills in .claude/skills)"
# Every archive below is an x86_64 build, and Flutter publishes no Linux arm64
# release at all. Say so here rather than let a checksum pass and the binary
# fail later with "cannot execute binary file".
[ "$(uname -m)" = "x86_64" ] || die "only x86_64 is supported; this machine is $(uname -m)"
[ "$(id -u)" = "0" ] || die "run as root: the toolchain installs into $PREFIX"

# Flutter, its artifacts, Dart, Node and the Supabase images together want
# roughly 10 GB. Half an install is worse than none.
available_kb=$(df -Pk "$(dirname "$PREFIX")" | awk 'NR == 2 { print $4 }')
[ "${available_kb:-0}" -ge 10485760 ] \
  || die "need ~10 GB free on $(dirname "$PREFIX"), have $((available_kb / 1024)) MB"

missing=()
for command_name in curl git tar unzip xz sha256sum; do
  have "$command_name" || missing+=("$command_name")
done
if [ ${#missing[@]} -gt 0 ]; then
  info "installing: ${missing[*]}"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq curl ca-certificates git tar unzip xz-utils coreutils
else
  skip "curl, git, tar, unzip, xz, sha256sum already present"
fi

mkdir -p "$PREFIX"
WORK_DIR="$(mktemp -d)"
readonly WORK_DIR
trap 'rm -rf "$WORK_DIR"' EXIT

# --- 1. Node -----------------------------------------------------------------

step "Node"

NODE_VERSION=$(pin "Node" "$REPO_ROOT/.nvmrc" < <(tr -d ' \t\r\n' < "$REPO_ROOT/.nvmrc"))
readonly NODE_VERSION
readonly NODE_DIR="$PREFIX/node"

if [ -x "$NODE_DIR/bin/node" ] && [ "$("$NODE_DIR/bin/node" --version)" = "v$NODE_VERSION" ]; then
  skip "Node v$NODE_VERSION already installed"
else
  info "installing Node v$NODE_VERSION (.nvmrc)"
  node_archive="node-v$NODE_VERSION-linux-x64.tar.xz"
  fetch "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt" "$WORK_DIR/node-shasums.txt"
  node_sha=$(awk -v file="$node_archive" '$2 == file { print $1 }' "$WORK_DIR/node-shasums.txt")
  [ -n "$node_sha" ] || die "Node v$NODE_VERSION has no linux-x64 build published"
  fetch_verified "https://nodejs.org/dist/v$NODE_VERSION/$node_archive" "$WORK_DIR/$node_archive" "$node_sha"
  rm -rf "$NODE_DIR"
  mkdir -p "$NODE_DIR"
  tar --extract --xz --file "$WORK_DIR/$node_archive" --directory "$NODE_DIR" --strip-components=1
fi
export PATH="$NODE_DIR/bin:$PATH"
ok "$(node --version)"

# --- 2. pnpm -----------------------------------------------------------------

step "pnpm"

PNPM_SPEC=$(pin "pnpm" "$REPO_ROOT/package.json" < <(node -p "require('$REPO_ROOT/package.json').packageManager || ''"))
readonly PNPM_SPEC

if have pnpm && [ "$(command -v pnpm)" = "$NODE_DIR/bin/pnpm" ] && [ "pnpm@$(pnpm --version)" = "$PNPM_SPEC" ]; then
  skip "$PNPM_SPEC already activated"
else
  info "activating $PNPM_SPEC via corepack"
  corepack enable --install-directory "$NODE_DIR/bin"
  corepack prepare "$PNPM_SPEC" --activate
fi
ok "pnpm $(pnpm --version)"

# --- 3. Dart -----------------------------------------------------------------
# The landing page builds on Vercel with a checksum-pinned SDK; that script is
# the pin, and CI must agree with it.

step "Dart SDK"

readonly VERCEL_INSTALL="$REPO_ROOT/apps/web/scripts/vercel-install.sh"
DART_VERSION=$(pin "Dart version" "$VERCEL_INSTALL" < <(sed -n 's/^DART_VERSION="\([^"]*\)".*/\1/p' "$VERCEL_INSTALL"))
DART_SHA256=$(pin "Dart checksum" "$VERCEL_INSTALL" < <(sed -n 's/^DART_SHA256="\([^"]*\)".*/\1/p' "$VERCEL_INSTALL"))
readonly DART_VERSION DART_SHA256

readonly CI_WORKFLOW="$REPO_ROOT/.github/workflows/ci.yml"
ci_dart_version=$(pin "CI Dart version" "$CI_WORKFLOW" < <(sed -n 's/^ *sdk: *\([0-9][0-9.]*\).*/\1/p' "$CI_WORKFLOW" | head -1))
[ "$ci_dart_version" = "$DART_VERSION" ] \
  || die "Dart pins disagree: $VERCEL_INSTALL says $DART_VERSION, $CI_WORKFLOW says $ci_dart_version"

readonly DART_DIR="$PREFIX/dart-sdk"
if [ -x "$DART_DIR/bin/dart" ] && "$DART_DIR/bin/dart" --version 2>&1 | grep -q "version: $DART_VERSION "; then
  skip "Dart $DART_VERSION already installed"
else
  info "installing Dart $DART_VERSION"
  dart_zip="dartsdk-linux-x64-release.zip"
  fetch_verified \
    "https://storage.googleapis.com/dart-archive/channels/stable/release/$DART_VERSION/sdk/$dart_zip" \
    "$WORK_DIR/$dart_zip" "$DART_SHA256"
  rm -rf "$DART_DIR" "$WORK_DIR/dart-unpack"
  unzip -q "$WORK_DIR/$dart_zip" -d "$WORK_DIR/dart-unpack"
  mv "$WORK_DIR/dart-unpack/dart-sdk" "$DART_DIR"
fi
export PATH="$DART_DIR/bin:$PATH"
ok "$(dart --version 2>&1)"

# --- 4. Flutter --------------------------------------------------------------
# `dart` on PATH stays the standalone SDK above (that is what CI gives
# apps/web); apps/app uses Flutter's own bundled Dart through `flutter`, and
# the wrapper installed below (`flutter-dart`) exposes it for `dart run
# build_runner` inside apps/app.

step "Flutter SDK"

FLUTTER_VERSION=$(pin "Flutter" "$REPO_ROOT/apps/app/.fvmrc" \
  < <(node -p "JSON.parse(require('fs').readFileSync('$REPO_ROOT/apps/app/.fvmrc', 'utf8')).flutter || ''"))
readonly FLUTTER_VERSION
readonly FLUTTER_DIR="$PREFIX/flutter"

# Flutter runs `git` against its own checkout — for `flutter --version`, and
# here to tell which release is unpacked. Git refuses on a tree it considers
# foreign unless it is marked safe, so do that before asking.
mark_git_safe "$FLUTTER_DIR"
# Same for the checkout itself: two --verify steps below are `git diff`, and as
# root over a checkout owned by someone else git would refuse them.
mark_git_safe "$REPO_ROOT"

if [ -x "$FLUTTER_DIR/bin/flutter" ] \
   && [ "$(git -C "$FLUTTER_DIR" describe --tags 2>/dev/null || true)" = "$FLUTTER_VERSION" ]; then
  skip "Flutter $FLUTTER_VERSION already installed"
else
  info "installing Flutter $FLUTTER_VERSION (apps/app/.fvmrc)"
  fetch "https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json" \
    "$WORK_DIR/flutter-releases.json"
  # The release index carries the archive path and its sha256 per version.
  flutter_release=$(node -p "
    const index = JSON.parse(require('fs').readFileSync('$WORK_DIR/flutter-releases.json', 'utf8'));
    const release = index.releases.find(r => r.version === '$FLUTTER_VERSION' && r.channel === 'stable');
    release ? release.archive + ' ' + release.sha256 : ''")
  [ -n "$flutter_release" ] || die "Flutter $FLUTTER_VERSION is not in the Linux stable release index"
  flutter_archive=${flutter_release%% *}
  flutter_sha=${flutter_release##* }
  fetch_verified \
    "https://storage.googleapis.com/flutter_infra_release/releases/$flutter_archive" \
    "$WORK_DIR/flutter.tar.xz" "$flutter_sha"
  rm -rf "$FLUTTER_DIR"
  mkdir -p "$FLUTTER_DIR"
  tar --extract --xz --file "$WORK_DIR/flutter.tar.xz" --directory "$FLUTTER_DIR" --strip-components=1
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

# No telemetry from an agent container, and no animations in a log.
flutter --disable-analytics >/dev/null
flutter config --no-cli-animations >/dev/null
dart --disable-analytics >/dev/null

# First run unpacks the bundled Dart and the tool's own snapshot; do it now so
# the first `flutter test` is not a surprise download.
info "warming the Flutter tool (first run unpacks its artifacts)"
flutter precache --universal >/dev/null
ok "Flutter $FLUTTER_VERSION"

# `dart` on PATH is the standalone SDK, which cannot resolve `sdk: flutter`
# packages. Inside apps/app, use this wrapper wherever CI says `dart`.
install -d "$PREFIX/bin"
cat > "$PREFIX/bin/flutter-dart" <<WRAPPER
#!/usr/bin/env sh
# Flutter's bundled Dart — the one that can resolve \`sdk: flutter\` packages.
# Use it for apps/app (\`flutter-dart run build_runner build --only-check\`);
# plain \`dart\` is the standalone SDK the landing page is pinned to.
#
# It also puts Flutter's bin first on PATH for everything it starts, so a tool
# that shells out to \`dart\` (very_good_cli does, to run its hooks) keeps the
# same SDK. Mixing the two mid-process fails with "Invalid SDK hash", because a
# kernel snapshot only loads into the SDK that compiled it.
PATH="$FLUTTER_DIR/bin:\$PATH"
export PATH
exec "$FLUTTER_DIR/bin/dart" "\$@"
WRAPPER
chmod +x "$PREFIX/bin/flutter-dart"
export PATH="$PREFIX/bin:$PATH"

# --- 5. Supabase CLI ---------------------------------------------------------

step "Supabase CLI"

# The workflow pins the CLI in more than one job. Take the pin only if they all
# agree — picking the first of two different versions would be a silent choice.
supabase_pins=$(sed -n '/supabase\/setup-cli/,/^$/ s/^ *version: *\([0-9][0-9.]*\).*/\1/p' "$CI_WORKFLOW" | sort -u)
[ "$(printf '%s\n' "$supabase_pins" | wc -l)" -eq 1 ] \
  || die "$CI_WORKFLOW pins more than one Supabase CLI version: $(printf '%s' "$supabase_pins" | tr '\n' ' ')"
SUPABASE_VERSION=$(pin "Supabase CLI" "$CI_WORKFLOW" < <(printf '%s' "$supabase_pins"))
readonly SUPABASE_VERSION

if [ -x "$PREFIX/bin/supabase" ] && [ "$("$PREFIX/bin/supabase" --version 2>/dev/null)" = "$SUPABASE_VERSION" ]; then
  skip "Supabase CLI $SUPABASE_VERSION already installed"
else
  info "installing Supabase CLI $SUPABASE_VERSION (.github/workflows/ci.yml)"
  supabase_archive="supabase_${SUPABASE_VERSION}_linux_amd64.tar.gz"
  supabase_base="https://github.com/supabase/cli/releases/download/v$SUPABASE_VERSION"
  fetch "$supabase_base/checksums.txt" "$WORK_DIR/supabase-checksums.txt"
  supabase_sha=$(awk -v file="$supabase_archive" '$2 == file { print $1 }' "$WORK_DIR/supabase-checksums.txt")
  [ -n "$supabase_sha" ] || die "Supabase CLI $SUPABASE_VERSION publishes no linux_amd64 tarball"
  fetch_verified "$supabase_base/$supabase_archive" "$WORK_DIR/$supabase_archive" "$supabase_sha"
  tar --extract --gzip --file "$WORK_DIR/$supabase_archive" --directory "$PREFIX/bin" supabase
fi
ok "Supabase CLI $(supabase --version)"

# --- 6. Chromium -------------------------------------------------------------
# `dart test -p chrome test/client` (apps/web) needs a browser. Agent
# containers usually ship the Playwright one; otherwise install Chromium.

step "Chromium"

chrome_binary=""
# `-x` alone is true for a directory, and the Playwright layout has both a
# `chromium` directory and a `chromium` symlink to the binary depending on the
# image — so require a file.
for candidate in "${PLAYWRIGHT_BROWSERS_PATH:-/opt/pw-browsers}/chromium" \
                 "${PLAYWRIGHT_BROWSERS_PATH:-/opt/pw-browsers}"/chromium-*/chrome-linux/chrome \
                 /usr/bin/chromium /usr/bin/chromium-browser /usr/bin/google-chrome; do
  if [ -f "$candidate" ] && [ -x "$candidate" ]; then chrome_binary="$candidate"; break; fi
done

if [ -z "$chrome_binary" ]; then
  info "no browser found; installing Chromium from apt"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq chromium || apt-get install -y -qq chromium-browser
  for candidate in /usr/bin/chromium /usr/bin/chromium-browser; do
    if [ -f "$candidate" ] && [ -x "$candidate" ]; then chrome_binary="$candidate"; break; fi
  done
  [ -n "$chrome_binary" ] || die "could not install a Chromium for the apps/web browser tests"
fi

# The test runner launches the browser as whoever runs it; as root Chromium
# refuses to start its sandbox, so point CHROME_EXECUTABLE at a wrapper that
# adds the flag rather than at the binary.
cat > "$PREFIX/bin/emotely-chrome" <<WRAPPER
#!/usr/bin/env sh
# Chromium for \`dart test -p chrome\`. --no-sandbox because these containers
# run as root, where Chromium's own sandbox cannot start.
exec "$chrome_binary" --no-sandbox --disable-dev-shm-usage "\$@"
WRAPPER
chmod +x "$PREFIX/bin/emotely-chrome"
export CHROME_EXECUTABLE="$PREFIX/bin/emotely-chrome"

# Being on disk is not the same as being able to start — a snap shim, or a
# Chromium missing a shared library, passes every check above and then fails
# inside `dart test -p chrome`, long after setup said it was fine.
"$PREFIX/bin/emotely-chrome" --headless=new --dump-dom about:blank >/dev/null 2>&1 \
  || die "$chrome_binary is installed but will not start; apps/web's browser tests need a working Chromium"
ok "$chrome_binary"

# --- 7. The shell environment ------------------------------------------------

step "Shell environment"

cat > "$ENV_FILE" <<ENV
# Written by scripts/setup-dev-environment.sh — do not edit by hand.
# The emotely toolchain: Node, pnpm, the standalone Dart SDK (the landing
# page's pin), Flutter, the Supabase CLI and a Chromium for the browser tests.
# Sourcing this twice must not stack the same entries onto PATH.
case ":\$PATH:" in
  *":$PREFIX/bin:"*) ;;
  *) PATH="$PREFIX/bin:$NODE_DIR/bin:$DART_DIR/bin:$FLUTTER_DIR/bin:\$HOME/.pub-cache/bin:\$PATH" ;;
esac
export PATH
export CHROME_EXECUTABLE="$PREFIX/bin/emotely-chrome"
ENV

ln -sf "$ENV_FILE" "$PROFILE_D"

# Login shells read profile.d; interactive non-login shells (what an agent
# usually gets) read .bashrc, so source it from there too, exactly once.
bashrc="$HOME/.bashrc"
marker="# emotely toolchain"
if ! grep -qF "$marker" "$bashrc" 2>/dev/null; then
  printf '\n%s\n. %s\n' "$marker" "$ENV_FILE" >> "$bashrc"
fi
export PATH="$PREFIX/bin:$NODE_DIR/bin:$DART_DIR/bin:$FLUTTER_DIR/bin:$HOME/.pub-cache/bin:$PATH"
ok "$ENV_FILE (sourced from $PROFILE_D and ~/.bashrc)"

# --- 8. Docker ---------------------------------------------------------------
# The Supabase stack (`supabase start`, `supabase test db`) is containers.

step "Docker"

if ! have docker; then
  info "Docker is not installed — the Supabase schema suite will not run."
  info "Install Docker Engine: https://docs.docker.com/engine/install/"
elif docker info >/dev/null 2>&1; then
  skip "daemon already running"
  ok "$(docker --version)"
else
  info "starting dockerd"
  # The packaged init script sets ulimits the container may not allow, so run
  # the daemon directly and wait for the socket.
  mkdir -p /var/log
  (nohup dockerd >/var/log/dockerd.log 2>&1 &)
  for _ in $(seq 1 30); do
    docker info >/dev/null 2>&1 && break
    sleep 1
  done
  docker info >/dev/null 2>&1 || die "dockerd did not come up — see /var/log/dockerd.log"
  ok "$(docker --version)"
fi

# --- 9. Workspace dependencies -----------------------------------------------

step "Workspace dependencies"

info "pnpm install (agent + contract)"
(cd "$REPO_ROOT" && pnpm install --frozen-lockfile)

info "apps/app: flutter pub get"
(cd "$REPO_ROOT/apps/app" && flutter pub get)

info "apps/web: dart pub get"
(cd "$REPO_ROOT/apps/web" && dart pub get)

# apps/agent/src/cli.ts and apps/agent/evals/harness.ts both read this file at
# startup. Leave a commented, value-free template so the names are discoverable;
# it is gitignored, and filling it in is a human's job.
readonly AGENT_ENV_FILE="$REPO_ROOT/apps/agent/.env.local"
if [ -e "$AGENT_ENV_FILE" ]; then
  skip "apps/agent/.env.local already exists — left untouched"
else
  info "writing an empty apps/agent/.env.local template"
  cat > "$AGENT_ENV_FILE" <<'AGENT_ENV'
# Read by `pnpm --filter @emotely/agent session` and by the evals. Gitignored.
# Values are secrets: fill them in yourself, never through an agent transcript.
AI_GATEWAY_API_KEY=
# Only for scripts/live-smoke.ts and the on-device acceptance session:
SUPABASE_URL=
SUPABASE_PUBLISHABLE_KEY=
SMOKE_EMAIL=
SMOKE_PASSWORD=
AGENT_ENV
fi

JASPR_CLI_VERSION=$(pin "jaspr_cli" "$CI_WORKFLOW" \
  < <(sed -n 's/.*dart pub global activate jaspr_cli \([0-9][0-9.]*\).*/\1/p' "$CI_WORKFLOW" | head -1))
readonly JASPR_CLI_VERSION

if dart pub global list 2>/dev/null | grep -q "^jaspr_cli $JASPR_CLI_VERSION\b"; then
  skip "jaspr_cli $JASPR_CLI_VERSION already activated"
else
  info "dart pub global activate jaspr_cli $JASPR_CLI_VERSION"
  dart pub global activate jaspr_cli "$JASPR_CLI_VERSION" >/dev/null
fi

# very_good_cli runs the app's coverage gate. CI does not pin it, so neither
# does this — it is a test runner, not a build input.
if dart pub global list 2>/dev/null | grep -q '^very_good_cli '; then
  skip "very_good_cli already activated"
else
  info "dart pub global activate very_good_cli"
  flutter-dart pub global activate very_good_cli >/dev/null
fi
ok "dependencies resolved"

# --- 10. Verification --------------------------------------------------------

step "Installed"

printf '    %-14s %s\n' "node"     "$(node --version)"
printf '    %-14s %s\n' "pnpm"     "$(pnpm --version)"
printf '    %-14s %s\n' "dart"     "$(dart --version 2>&1 | sed 's/^Dart SDK version: //;s/ (stable).*//')"
printf '    %-14s %s\n' "flutter"  "$FLUTTER_VERSION"
printf '    %-14s %s\n' "supabase" "$(supabase --version)"
printf '    %-14s %s\n' "chromium" "$chrome_binary"
printf '    %-14s %s\n' "docker"   "$(docker --version 2>/dev/null || echo 'not available')"

if [ "$VERIFY" -eq 1 ]; then
  step "Verifying (the CI checks, minus the ones that need secrets)"

  info "agent: lint, typecheck, tests, contract tripwire"
  (cd "$REPO_ROOT" && pnpm lint && pnpm typecheck && pnpm -r --if-present test)
  (cd "$REPO_ROOT" && pnpm --filter @emotely/contract schema \
    && git diff --exit-code packages/contract/contract.schema.json)

  info "app: codegen check, format, analyze, tests"
  (cd "$REPO_ROOT/apps/app" \
    && flutter-dart run build_runner build --only-check \
    && flutter-dart format --set-exit-if-changed . \
    && flutter analyze --fatal-infos \
    && flutter-dart pub global run very_good_cli:very_good test --coverage --min-coverage 100 \
         --exclude-coverage '**/*.{freezed,g,mocks}.dart')

  info "web: format, analyze, tests (VM + Chrome), build"
  (cd "$REPO_ROOT/apps/web" \
    && dart format --set-exit-if-changed . \
    && dart analyze --fatal-infos \
    && dart test \
    && dart test -p chrome test/client \
    && jaspr build --sitemap-domain https://getemotely.com \
    && git diff --exit-code -- lib)

  if docker info >/dev/null 2>&1; then
    info "supabase: migrations + pgTAP row-level-security suite"
    # `db start` is what the CI job runs: only the database container, which is
    # all the SQL tests need. The full `supabase start` (auth, PostgREST,
    # Inbucket) is a separate thing you ask for when developing against it.
    (cd "$REPO_ROOT" && supabase db start && supabase test db --local \
      && supabase db lint --local --fail-on warning)
    info "the database container is left running; 'supabase stop' shuts it down"
    ok "every check passed"
  else
    skipped_supabase=1
    info "supabase: SKIPPED — no Docker daemon, so the schema suite did not run"
    ok "every check that could run passed; the Supabase job did not run"
  fi
fi

printf '\n%s%sEnvironment ready.%s Open a new shell, or: . %s\n' \
  "$C_BOLD" "$C_GREEN" "$C_OFF" "$ENV_FILE"

if [ "${skipped_supabase:-0}" -eq 1 ]; then
  printf '\n%sDocker is missing, so the Supabase job cannot run here.%s Install Docker\n' \
    "$C_RED" "$C_OFF"
  printf 'Engine (https://docs.docker.com/engine/install/) and re-run to cover it.\n'
fi

cat <<'NOTES'

What this does NOT set up, on purpose:

  · Secrets. apps/agent/.env.local is where AI_GATEWAY_API_KEY goes, for
    `pnpm --filter @emotely/agent session` and for the evals; a template is
    written for you, empty. A human fills it in. Note that every model round
    asks the gateway for Zero Data Retention, which is Pro-only -- a key on a
    Hobby team fails every round, and that is billing, not a broken machine.
  · Entire. Its hooks in .claude/settings.json no-op while the CLI is absent,
    so commits made here carry no Entire-Checkpoint trailer. Installing it
    means running `entire enable`, which writes git hooks and pushes to a
    private checkpoint repo: the maintainer's call, see docs/tooling/entire.md.
  · fvm. The run-app skill drives apps/app through `fvm flutter` / `fvm dart`;
    here the pinned SDK is on PATH directly, as `flutter` and `flutter-dart`.
  · The GitHub CLI. `main` is protected and merges go through PRs; the release
    and supabase skills shell out to `gh`. Install and authenticate it yourself
    if you need those.
  · Anything that runs the app on a device. No Android SDK, no JDK, no
    emulator, no Xcode: `flutter run`, `flutter build`, integration_test and
    the android half of app-release.yml are all out of reach on this machine.
    apps/app's unit and widget tests do run.
NOTES
