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
  `Claude Code, Codex`, `Checkpoints sync to: origin`.
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
`settings.local.json`) is ignored via `.entire/.gitignore`; `.claude/settings.json`
also denies reads of `.entire/metadata/**`.

Secrets are detected and redacted before anything is stored
([entire.io](https://entire.io/)).

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
  back to its checkpoint metadata." The branch commits keep their checkpoints;
  the squashed `main` commit may not. Recovery is
  `entire session attach <SESSION_ID> -a <AGENT>`. Worth verifying against a real
  merged PR, and worth an ADR if the team wants the link guaranteed on `main`.
- **`pre-push` pushes to `origin`** (this repo's GitHub remote) on every push, so
  checkpoint refs land in the shared repo — anyone pushing needs write access,
  which they have anyway.
- Telemetry is on (`"telemetry": true` in `.entire/settings.json`).
- `entire search` requires `entire login` (GitHub device flow); the local
  inspection commands do not.
- No `refs/entire/*` exist locally or on `origin` yet — Entire was enabled
  2026-08-20 and no agent commit has been made since, so this is unexercised.
