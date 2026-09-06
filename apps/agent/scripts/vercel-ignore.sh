#!/usr/bin/env sh
# Vercel "Ignored Build Step" for emotely-agent (wired via ignoreCommand in
# vercel.json). Exit 0 skips the deployment, any other exit code builds it.
#
# Why this exists: Vercel's built-in "skip unaffected projects" only knows the
# pnpm workspace graph. Everything outside a workspace package (apps/app, docs,
# AGENTS.md, ...) counts as a "global change" and deploys every project, so
# app-only PRs were building the agent. This script names the agent's build
# inputs explicitly and diffs only those.
#
# Runs in the project's Root Directory (apps/agent) inside a shallow clone
# (--depth=10). Pathspecs use the `:/` prefix so they resolve from the repo
# top level regardless of the working directory.
set -u

head="${VERCEL_GIT_COMMIT_SHA:-HEAD}"

# Prefer the last built deployment of this branch (only set when an Ignored
# Build Step is configured), so a change skipped in one push is not lost when
# a later push touches nothing. Fall back to the parent commit when it is
# unset or outside the shallow clone.
base="${VERCEL_GIT_PREVIOUS_SHA:-}"
if [ -z "$base" ] || ! git cat-file -e "$base^{commit}" 2>/dev/null; then
  base="$head^"
fi
if ! git cat-file -e "$base^{commit}" 2>/dev/null; then
  echo "vercel-ignore: no base commit to diff against; building"
  exit 1
fi

# Everything the agent build reads. Keep in sync with the workspace layout.
inputs="
  :/apps/agent
  :/packages
  :/pnpm-lock.yaml
  :/pnpm-workspace.yaml
  :/package.json
  :/tsconfig.base.json
  :/.nvmrc
  :/.vercelignore
"

# shellcheck disable=SC2086 # word splitting on $inputs is the point.
if git diff --quiet "$base" "$head" -- $inputs; then
  echo "vercel-ignore: no agent build input changed between $base and $head; skipping"
  exit 0
fi
echo "vercel-ignore: agent build inputs changed between $base and $head; building"
exit 1
