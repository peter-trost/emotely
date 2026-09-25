#!/usr/bin/env bash
# Records the build a release lane just shipped to one store channel in the
# status file the README badges read (the `status` branch, status.json).
#
#   release-status.sh <status.json> <platform> <track> <version> <build> <commit> <updated-at>
#
# Rewrites that one channel in place and leaves every other channel as it was.
set -euo pipefail

refuse() {
  printf 'release-status: %s\n' "$1" >&2
  exit 1
}

(($# == 7)) || refuse "usage: release-status.sh <status.json> <platform> <track> <version> <build> <commit> <updated-at>"
file="$1" platform="$2" track="$3" version="$4" build="$5" commit="$6" updated_at="$7"

# The file is public and the badges render whatever it holds, so every value
# is held to an exact shape: only these channels, and nothing a value could
# smuggle into the JSON or the badge text.
case "${platform}/${track}" in
  ios/internal | android/internal) ;;
  *) refuse "unknown channel ${platform}/${track}" ;;
esac
[[ "${version}" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] ||
  refuse "version must be x.y.z, got '${version}'"
[[ "${build}" =~ ^[1-9][0-9]{0,8}$ ]] || refuse "build must be a positive integer, got '${build}'"
[[ "${commit}" =~ ^[0-9a-f]{40}$ ]] || refuse "commit must be a full lower-case SHA-1, got '${commit}'"
[[ "${updated_at}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]] ||
  refuse "updated-at must be UTC as YYYY-MM-DDTHH:MM:SSZ, got '${updated_at}'"

next="$(jq \
  --arg platform "${platform}" --arg track "${track}" \
  --arg version "${version}" --argjson build "${build}" \
  --arg commit "${commit}" --arg updated_at "${updated_at}" \
  '.[$platform][$track] = {
    version: $version,
    build: $build,
    label: "\($version) (\($build))",
    commit: $commit,
    updated_at: $updated_at
  }' "${file}")"
printf '%s\n' "${next}" >"${file}"
