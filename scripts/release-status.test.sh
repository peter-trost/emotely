#!/usr/bin/env bash
# Tests for release-status.sh, through its command line only: a status file
# and arguments in, the file and the exit code out. Run from anywhere:
#   bash scripts/release-status.test.sh
set -euo pipefail

script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/release-status.sh"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

commit_a=0123456789abcdef0123456789abcdef01234567
at_a=2026-09-24T10:00:00Z

failures=0
fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

# A fresh status file holding the given JSON.
status_file() {
  local file="${work}/status-${RANDOM}.json"
  printf '%s\n' "$1" >"${file}"
  printf '%s' "${file}"
}

test_writes_a_channel_into_an_empty_file() {
  local file
  file="$(status_file '{}')"

  bash "${script}" "${file}" ios internal 2.0.0 1042 "${commit_a}" "${at_a}"

  local expected='{"ios":{"internal":{"version":"2.0.0","build":1042,"label":"2.0.0 (1042)","commit":"0123456789abcdef0123456789abcdef01234567","updated_at":"2026-09-24T10:00:00Z"}}}'
  [[ "$(jq -c . "${file}")" == "${expected}" ]] ||
    fail "writes a channel into an empty file: got $(jq -c . "${file}")"
}

test_replaces_its_channel_and_keeps_the_others() {
  local file
  file="$(status_file '{"ios":{"internal":{"version":"2.0.0","build":1041}},"android":{"internal":{"version":"2.0.0","build":1041}}}')"

  bash "${script}" "${file}" ios internal 2.0.0 1042 "${commit_a}" "${at_a}"

  [[ "$(jq -c '.ios.internal.build' "${file}")" == 1042 ]] ||
    fail "replaces its channel: ios build is $(jq -c '.ios.internal.build' "${file}")"
  [[ "$(jq -c '.android.internal' "${file}")" == '{"version":"2.0.0","build":1041}' ]] ||
    fail "keeps the others: android is $(jq -c '.android.internal' "${file}")"
}

# Runs the script with the given arguments after the file, expecting a
# refusal: a non-zero exit and the file byte for byte as it was.
expect_refusal() {
  local name="$1"
  shift
  local file before
  file="$(status_file '{"ios":{"internal":{"version":"2.0.0","build":1041}}}')"
  before="$(cat "${file}")"

  if bash "${script}" "${file}" "$@" 2>/dev/null; then
    fail "refuses ${name}: exited 0"
  fi
  [[ "$(cat "${file}")" == "${before}" ]] || fail "refuses ${name}: file changed"
}

test_refuses_a_channel_outside_the_allowlist() {
  expect_refusal "an unknown platform" web internal 2.0.0 1042 "${commit_a}" "${at_a}"
  expect_refusal "an unknown track" ios production 2.0.0 1042 "${commit_a}" "${at_a}"
  expect_refusal "a JSON-path platform" '__proto__' internal 2.0.0 1042 "${commit_a}" "${at_a}"
}

test_refuses_malformed_values() {
  expect_refusal "a version that is not x.y.z" ios internal '2.0.0 <b>' 1042 "${commit_a}" "${at_a}"
  expect_refusal "a pre-release version" ios internal 2.0.0-rc.1 1042 "${commit_a}" "${at_a}"
  expect_refusal "an empty version" ios internal '' 1042 "${commit_a}" "${at_a}"
  expect_refusal "a non-numeric build" ios internal 2.0.0 '1042"' "${commit_a}" "${at_a}"
  expect_refusal "a build with a leading zero" ios internal 2.0.0 01042 "${commit_a}" "${at_a}"
  expect_refusal "an empty build" ios internal 2.0.0 '' "${commit_a}" "${at_a}"
  expect_refusal "a short commit" ios internal 2.0.0 1042 0123456 "${at_a}"
  expect_refusal "an upper-case commit" ios internal 2.0.0 1042 0123456789ABCDEF0123456789ABCDEF01234567 "${at_a}"
  expect_refusal "a local time" ios internal 2.0.0 1042 "${commit_a}" 2026-09-24T10:00:00+02:00
  expect_refusal "a missing argument" ios internal 2.0.0 1042 "${commit_a}"
}

test_refuses_a_status_file_that_is_not_an_object() {
  local file
  for content in '["ios"]' 'not json'; do
    file="$(status_file "${content}")"
    if bash "${script}" "${file}" ios internal 2.0.0 1042 "${commit_a}" "${at_a}" 2>/dev/null; then
      fail "refuses a status file holding ${content}: exited 0"
    fi
    [[ "$(cat "${file}")" == "${content}" ]] || fail "refuses a status file holding ${content}: file changed"
  done
}

test_writes_a_channel_into_an_empty_file
test_replaces_its_channel_and_keeps_the_others
test_refuses_a_channel_outside_the_allowlist
test_refuses_malformed_values
test_refuses_a_status_file_that_is_not_an_object

if ((failures > 0)); then
  printf '%d failed\n' "${failures}" >&2
  exit 1
fi
printf 'all passed\n'
