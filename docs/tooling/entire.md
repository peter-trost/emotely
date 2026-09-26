# Entire

Researched 2026-08-20 against the installed binary (`Entire CLI 0.10.2`,
`/Users/petertrost/.local/bin/entire`) and the official docs at
<https://docs.entire.io>. Entire is **active in this repo**.

## What it is

Entire captures coding-agent sessions (prompts, transcript, tool calls, files
touched, token usage) and links them to git commits, so history records *why* a
change happened, not just what changed — "Git shows what changed. Entire shows
why." ([docs.entire.io/overview](https://docs.entire.io/overview)). Open source,
MIT, [github.com/entireio/cli](https://github.com/entireio/cli).

## How it works here

Capture is two halves ([capture-checkpoints](https://docs.entire.io/guides/checkpoints/capture-checkpoints.md)):

- **Agent hooks** — `.claude/settings.json` wires `entire hooks claude-code ...`
  into SessionStart/Stop/SessionEnd/UserPromptSubmit and PreToolUse/PostToolUse
  on `Agent` + `TaskCreate|TaskUpdate`. `.codex/hooks.json` does the same for
  Codex. `entire status` here reports: `Enabled · branch main`, agents
  `Claude Code, Codex`, `Checkpoints sync to: dedicated checkpoint remote
  (trost-systems/emotely-checkpoints)`.
- **Git hooks** — `.git/hooks/{prepare-commit-msg,commit-msg,post-commit,post-rewrite,pre-push}`
  all shell out to `entire hooks git ...`. `prepare-commit-msg` adds an
  `Entire-Checkpoint: <id>` trailer, `post-commit` condenses the session,
  `post-rewrite` remaps linkage after amend/rebase, `pre-push` pushes session
  logs alongside your push.

Storage: `.entire/settings.json` sets `checkpoints.primary.type = "git-refs"`,
i.e. one git ref per checkpoint under `refs/entire/checkpoints/*` (strings in the
0.10.2 binary) rather than the default shared `entire/checkpoints/v1` branch
([store-checkpoint-data](https://docs.entire.io/guides/checkpoints/store-checkpoint-data.md)).
Either way metadata lives **outside your branch** — no extra commits on the
working branch. Untracked local state (`.entire/logs/`, `metadata/`, `tmp/`,
`settings.local.json`) is ignored via `.entire/.gitignore`. The old
`Read(./.entire/metadata/**)` deny rule in `.claude/settings.json` is retired:
`entire doctor` flags it as stale (it blocked recursive greps and guarded a
file that is removed on condense) and removes it.

**Transcripts are private.** This repo is public, so checkpoint refs do not go
to `origin`: `strategy_options.checkpoint_remote` in `.entire/settings.json`
points them at the private
[trost-systems/emotely-checkpoints](https://github.com/trost-systems/emotely-checkpoints)
(same owner, as Entire requires, so the two repos only ever move together; set
up 2026-09-06 via `entire configure --checkpoint-remote github:<owner>/emotely-checkpoints`,
both moved to `trost-systems` on 2026-09-26,
docs: [store-checkpoints-in-another-repo](https://docs.entire.io/guides/checkpoints/store-checkpoints-in-another-repo.md)).
If that remote is unreachable the code push still succeeds and Entire keeps the
checkpoint local with a warning. Never push `refs/entire/*` to `origin`.

**An owner mismatch fails open, to the public repo.** When `checkpoint_remote`'s
owner differs from `origin`'s, Entire 0.11 does *not* keep checkpoints local: it
logs "ignoring checkpoint_remote that appears to belong to another owner;
pushing checkpoints to the push remote instead" (only in `entire doctor logs`)
and pushes the transcripts to `origin`. That happened on 2026-09-26 from a
branch cut before the move to `trost-systems` still carried the old owner
([#199](https://github.com/trost-systems/emotely/issues/199)). So after any
owner change, on a fork, or on a branch older than the last change to
`.entire/settings.json`: before pushing, merge `main` or put the right
`checkpoint_remote` in the gitignored `.entire/settings.local.json`, and check
that `entire status` says "Checkpoints sync to: dedicated checkpoint remote
(trost-systems/emotely-checkpoints)". A leaked ref is removed with
`git push origin --delete refs/entire/checkpoints/<xx>/<id>` after copying it to
the checkpoint repo.

**entire.io only shows mirrored repos.** Having the Entire GitHub App installed
makes a repo *visible* on entire.io, but it stays "Inactive" and the backend
ingests nothing until the repo is onboarded, i.e. has a mirror placement.
Before 2026-09-22 neither repo was mirrored, so the dashboard showed zero
checkpoints for weeks although 175 refs sat in the checkpoint repo. Symptoms:
Home says "Onboarded 0 / Capturing 0", the repo page redirects to Settings
("Connected to GitHub, no mirrors yet"), and `entire search` fails with
"no matching repositories found … (is the repo mirrored to Entire?)". **Both**
repos need a mirror, in the account's home jurisdiction (`us`, see
`entire auth status`):

- `emotely` — commits and the `Entire-Checkpoint` trailers that name the
  checkpoints. Alone, entire.io lists the checkpoint IDs with no sessions.
- `emotely-checkpoints` — the checkpoint refs holding the transcripts.

Both are mirrored into `aws-us-east-2.entire.io` (first on 2026-09-22; again
under the new owner after the 2026-09-26 move, since a mirror is keyed by
owner/repo and does not follow a GitHub transfer):
`entire repo mirror add /gh/trost-systems/<repo> --cluster aws-us-east-2.entire.io`,
checked with `entire repo mirror get /gh/trost-systems/<repo>`. That means Entire now
holds a copy of the transcripts. entire.io access follows GitHub collaborator
permissions, so they stay as private as the private repo. Sessions show on
the Home dashboard and under `gh/trost-systems/emotely-checkpoints/session/<id>`.
The `emotely` repo's own Sessions tab stays empty: entire.io does not join the
two repos yet, even though the committed `checkpoint_remote` setting names
the link. The same goes for search: a plain `entire search` here scopes to
`emotely` and finds commits only; pass `--all-repos` (or
`--repo trost-systems/emotely-checkpoints`) to reach the sessions. No upstream
issue tracked the split as of 2026-09-22; the closest is
[entireio/cli#1195](https://github.com/entireio/cli/issues/1195) (search
empty with a checkpoint remote and both mirrors ready).

Redaction runs before every write
([privacy-and-redaction](https://docs.entire.io/guides/configuration/privacy-and-redaction.md)):
secrets by default (API keys, tokens, credentialed URLs, connection strings,
private keys), plus PII in `.entire/settings.json` — `redaction.pii` with
`email` and `phone` on, `address` off.

## Key commands

Read-only, safe for agents (`entire agent-help` is the source of truth and always
matches the installed CLI — read it rather than guessing flags):

| Command | Use |
| --- | --- |
| `entire agent-help [cmd]` | Machine-readable usage for the installed version |
| `entire status` | Enabled? which agents? sync target? |
| `entire checkpoint list [--json]` | Checkpoints on the current branch |
| `entire checkpoint explain <id\|sha>` | Full context behind a checkpoint/commit |
| `entire search "<q>" --json --compact` | Hybrid semantic+keyword over checkpoints/commits/sessions (needs `entire login`) |
| `entire why <file>:<line>` | The commit, prompt and session behind a line |
| `entire session list` / `info` / `current` | Sessions across worktrees |
| `entire recap` / `entire activity` | Recent activity summary |

State-changing, **the user's call — suggest, don't run**: `enable`, `disable`,
`configure`, `agent`, `clean`, `plugin`, `login/logout`, `org`, `project`, `repo`
(`entire agent-help` labels these explicitly).

## Notes for agents in this repo

- Nothing to run. Capture is automatic via hooks; just work and commit normally.
- Commit at logical breakpoints; avoid noisy micro-commits that fragment the
  session log ([agents/claude-code](https://docs.entire.io/agents/claude-code.md)).
- Before re-deriving intent from a diff, try `entire why <file>:<line>` or
  `entire checkpoint explain <sha>` — cheaper than re-reading history.
- Expect an `Entire-Checkpoint: <id>` trailer in commit messages. Leave it. The
  binary's own template says: "Remove the `Entire-Checkpoint` trailer above if
  you don't want to link this commit."
- Shadow branches (live-session rewind points, `entire checkpoint list --pending`)
  are local scratch and **must not be pushed** — the README warns they "may
  contain unredacted data."

## Caveats

- **Squash merge can break the link.** This repo squash-merges every PR into
  protected `main`. Per
  [troubleshooting](https://docs.entire.io/guides/checkpoints/troubleshooting.md):
  "Some Git hosts can remove commit trailers during squash merges. If the
  `Entire-Checkpoint` trailer is removed, Entire cannot link the squashed commit
  back to its checkpoint metadata." Verified 2026-09-22: GitHub keeps each
  branch commit's `Entire-Checkpoint:` line inside the squash body (82 of 90
  `main` commits in the last month), but after them it appends a final
  `Co-authored-by:` paragraph, so `git log --format=%(trailers)` sees only 7.
  entire.io still linked 151 checkpoints to `emotely` commits, so it reads the
  lines anywhere in the body. Recovery for an unlinked commit is
  `entire session attach <SESSION_ID> -a <AGENT>`.
- **`pre-push` pushes checkpoints to the private checkpoint repo** on every
  push, so anyone whose sessions should be captured needs write access there
  too. Contributors without it still push code fine; their checkpoints stay
  local.
- Telemetry is on (`"telemetry": true` in `.entire/settings.json`).
- `entire search` requires `entire login` (GitHub device flow) and a mirrored
  repo (see above); the local inspection commands need neither.
- Checkpoints that reached the public `origin` before the private remote
  existed (57 refs, up to 2026-09-06) were pushed to the checkpoint repo and
  deleted from `origin`. Deleted refs can linger in GitHub's object store until
  its garbage collection runs; treat anything captured before that date as
  possibly cached.
- Every clone runs `entire enable` once; git hooks are not versioned. If
  `entire status` says hooks are out of date, `entire enable --force` reinstalls
  them — check its diff of `.claude/settings.json` afterwards.
