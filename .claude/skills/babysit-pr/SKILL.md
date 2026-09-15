---
name: babysit-pr
description: Watch an open PR until it is merged, closed, or genuinely needs Peter — polling CI, review threads and mergeability, diagnosing ci-ok failures, fixing what the branch broke, and re-running only what is flaky. Use whenever asked to babysit, monitor or watch a PR, keep an eye on CI, or drive review feedback to zero.
---

# Babysitting a PR

One PR, watched to a terminal state. The loop is: snapshot → decide → act →
snapshot again, until the PR is merged or closed, or something genuinely needs
a human. Green CI is a milestone inside the loop, never a reason to leave it —
review comments arrive after CI goes green, and that is exactly when a watcher
that stopped early costs a round trip.

Everything here is `gh` + `jq`. There is no watcher daemon and no Python: the
repo has no Python anywhere, and a poll loop that the agent runs itself keeps
the decisions in the transcript where they can be reviewed, rather than inside
a script's control flow.

## Pick up the PR

```bash
gh pr view --json number,url,state,isDraft,mergeable,mergeStateStatus,headRefName,headRefOid,reviewDecision
```

No argument means the PR for the current branch; otherwise take a number or a
URL and pass it as the first argument to every command below. Confirm the head
SHA before acting on any CI result — a snapshot describes one SHA, and a push
that lands mid-loop invalidates it.

## The snapshot

```bash
gh pr checks --json name,state,bucket,link,workflow | jq -r '
  group_by(.bucket) | map({bucket: .[0].bucket, n: length, names: map(.name)}) | .[]
  | "\(.bucket)\t\(.n)\t\(.names | join(", "))"'
gh pr-review threads list --pr <n> --repo peter-trost/emotely --unresolved
```

`gh pr-review` needs both `--pr` and `--repo`: it does not infer the PR from
the current branch the way `gh pr` does, and a numeric selector without
`--repo` is an error. It prints a JSON array (`[]` when a PR has no inline
threads), so pipe it through `jq` — check the object shape with
`jq '.[0] | keys'` on a PR that has threads before writing a field path
against it.

`gh pr checks` buckets into `pass` / `fail` / `pending` / `skipping`. Read the
buckets, not the individual jobs: this repo's CI is path-filtered, so a PR that
touches only `apps/web` legitimately shows `agent`, `app` and `supabase` as
skipped — **skipped is not failed**, and `ci-ok` is green precisely because it
treats them as fine.

Two checks come from outside `ci.yml` and are worth recognising: the **Vercel**
preview deployments (`emotely-agent`, `emotely-web`, each skipped by its
`vercel-ignore.sh` when that app is untouched) and **GitGuardian**. A
GitGuardian failure means a secret may have been committed — stop and tell
Peter; never "fix" it by rewriting history on your own.

## What CI actually means here

`ci-ok` is the only required check ([`.github/workflows/ci.yml`](../../../.github/workflows/ci.yml)).
It is a gate job: green only when every other job succeeded or was skipped.
Three consequences for a watcher:

- **Diagnose the job, not the gate.** `ci-ok` failing tells you nothing except
  that something upstream of it failed. Find the real job before reading logs.
- **Cancellation leaves `ci-ok` pending, not failed.** The workflow's
  concurrency group cancels in-flight runs when a new commit supersedes them.
  A pending `ci-ok` on a stale SHA is not a hang — check whether the head SHA
  moved before investigating.
- **A fork PR skips the live eval** for want of a gateway key, and that is
  expected. On a branch in this repo a missing `AI_GATEWAY_API_KEY` is a broken
  `ci` environment and fails loudly — that one is Peter's, not yours to patch.

## Reading a failure

```bash
gh run list --commit "$(gh pr view --json headRefOid -q .headRefOid)" \
  --json databaseId,name,status,conclusion,url
gh api "repos/{owner}/{repo}/actions/runs/<run-id>/jobs" --jq \
  '.jobs[] | select(.conclusion == "failure") | {id, name, html_url}'
gh api "repos/{owner}/{repo}/actions/jobs/<job-id>/logs" > "$TMPDIR/job-<job-id>.log"
```

`{owner}/{repo}` is expanded by `gh` from the current repo — leave it literal.
Write logs to a scratch path, never into the worktree: an untracked log file
would show up as an unrelated change on the next commit.

Go to the failed job's log as soon as that job fails. `gh run view --log-failed`
is run-scoped and stays empty until the whole run finishes, so on a PR that
touches several apps you would wait for the slowest job to diagnose the one
that already failed.

Then classify, and let the classification decide the action:

- **Branch-related** — a compile, analyze, format, test or coverage failure in
  code this PR touched. Fix it. See [references/failures.md](references/failures.md)
  for what each job's failure output looks like in this repo and which command
  reproduces it locally.
- **Flaky or infrastructural** — runner provisioning, a network or registry
  timeout, an Actions outage. Re-run it, at most **3 times** per SHA, then stop
  and report.

Never close the gap between those two by weakening the thing that caught it.
Lints here are deny-by-default and generated code is committed and
tripwired; a red check is usually correct. Silencing a rule, loosening a
coverage threshold or regenerating a committed artifact to make CI quiet is a
change to the repo's standards, and that is Peter's call — surface it instead.

```bash
gh run rerun <run-id> --failed
```

## Reading review feedback

```bash
gh pr-review threads list --pr <n> --repo peter-trost/emotely --unresolved
gh pr view <n> --json comments,reviews   # top-level comments and submissions
```

Ignore reviews still in `PENDING` state — the reviewer has not submitted them,
and acting on a half-written review is both wrong and visible. Threads already
marked resolved are done unless new unresolved feedback hangs off them.

When a comment is correct and actionable, fix it in code, push, and then
resolve its thread:

```bash
gh pr-review threads resolve --pr <n> --repo peter-trost/emotely --thread-id <id>
```

When it is ambiguous, wrong, asks a question, or wants a product decision,
**bring it to Peter in chat with a suggested reply** rather than answering on
GitHub. Writing to a review thread is visible to other people, so it follows
one rule: never leave a GitHub trace that makes it hard to tell whether Peter
or an agent did something.

- Resolve threads Peter opened, and threads from review bots.
- Leave threads where other humans are participating — report those instead.
- Post a reply only when Peter has confirmed the exact text, and prefix it with
  `[from Claude]: ` so its origin is unambiguous.
- Never mark the PR draft or ready, never close or reopen it, never dismiss a
  review.

```bash
gh pr-review comments reply --pr <n> --repo peter-trost/emotely \
  --thread-id <id> --body '[from Claude]: ...'
```

## Merging is not yours

Report that a PR is ready; let Peter merge it. Branch protection wants the
branch up to date with `main` (`strict: true`), so when the only thing standing
between the PR and mergeable is a stale branch:

```bash
gh pr update-branch
```

That is a safe, expected write. If it conflicts, stop and say so — resolving a
merge conflict is a judgement call about intent, and belongs in a session where
Peter is watching, not in a poll loop.

## The loop

Poll about every 60s while anything is pending or failing, and keep that
cadence after green while the PR is open — late review comments are the whole
reason to still be watching. Reset to the base cadence whenever the head SHA,
check states, review threads or mergeability change.

Each pass, in this order:

1. **Merged or closed?** Report the terminal state and stop.
2. **New review feedback?** Handle it before CI. A review fix produces a new
   commit, which retriggers CI anyway — so acting on review first avoids
   re-running checks on a SHA you are about to replace.
3. **Failed checks?** Diagnose, then fix (branch-related) or re-run (flaky).
4. **Mergeable?** Check conflicts and the up-to-date requirement.
5. Otherwise wait and repeat.

After any push, start again from the new SHA in the same turn. A push is not a
finish line, and neither is the first all-green snapshot.

## Reporting

While watching, report only changes and the occasional heartbeat — not every
poll. Say it once when CI first goes green for a SHA, then keep watching.

Stop and hand back only when the PR is merged or closed, or when you are
actually blocked: the retry budget is spent, `gh` auth or push permission
fails, the worktree holds unrelated uncommitted changes, a conflict needs
resolving, or a reviewer is asking for a decision that is not yours to make.
Say which of those it is, and what you would do next.

Final summary: head SHA, CI status, mergeability, what you pushed, how many
re-runs you spent, and anything still open.
