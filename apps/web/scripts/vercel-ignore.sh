#!/usr/bin/env sh
# Vercel "Ignored Build Step" for emotely-web (wired via ignoreCommand in
# vercel.json). Exit 0 skips the deployment, any other exit code builds it.
#
# Same idea as apps/agent/scripts/vercel-ignore.sh: name the site's build
# inputs explicitly and diff only those, so an agent-only or app-only PR
# never builds (or previews) the site.
#
# Runs in the project's Root Directory (apps/web) inside a shallow clone.
# Pathspecs use the `:/` prefix so they resolve from the repo top level.
set -u

head="${VERCEL_GIT_COMMIT_SHA:-HEAD}"

base="${VERCEL_GIT_PREVIOUS_SHA:-}"
if [ -z "$base" ] || ! git cat-file -e "$base^{commit}" 2>/dev/null; then
  base="$head^"
fi
if ! git cat-file -e "$base^{commit}" 2>/dev/null; then
  echo "vercel-ignore: no base commit to diff against; building"
  exit 1
fi

# Everything the site build reads. Keep in sync with the layout.
inputs="
  :/apps/web
"

# shellcheck disable=SC2086 # word splitting on $inputs is the point.
if git diff --quiet "$base" "$head" -- $inputs; then
  echo "vercel-ignore: no site build input changed between $base and $head; skipping"
  exit 0
fi
echo "vercel-ignore: site build inputs changed between $base and $head; building"
exit 1
