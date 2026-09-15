# Reading a failed job in this repo

Which job failed tells you what broke and how to reproduce it locally. Fix the
cause on the branch; never quiet the check. Every command below runs from the
repo root unless the job's `working-directory` says otherwise.

## `agent` — `apps/agent`, `packages/**` (Node, pnpm)

| Failing step | What it means | Reproduce |
| --- | --- | --- |
| `pnpm lint` | biome, `preset: "all"`, warnings are errors | `pnpm lint`, then `pnpm format` for the mechanical half |
| `pnpm typecheck` | project-wide `tsc --build`, every strictness flag | `pnpm typecheck` |
| `pnpm -r --if-present test` | a package's own suite | `pnpm -r --if-present test` |
| contract tripwire | `contract.schema.json` no longer matches the zod source | `pnpm --filter @emotely/contract schema` and commit the result |
| `pnpm --filter @emotely/agent eval` | live-model protocol eval, deterministic assertions | needs `AI_GATEWAY_API_KEY`; see below |

The contract tripwire is a **regenerate-and-commit**, not a fix: the schema is
emitted from zod and committed, and CI fails when the two drift. Run the
generator and commit its output — never hand-edit the JSON to match.

A failing eval is a real signal about model behaviour, not a flake to re-run.
Judged behaviour evals run nightly; the CI one is deterministic. If it fails
only on a fork PR for a missing key, that is expected and not yours to fix.

## `app` — `apps/app` (Flutter)

| Failing step | What it means | Reproduce (in `apps/app`) |
| --- | --- | --- |
| `build_runner build --only-check` | committed generated code is stale | `dart run build_runner build --delete-conflicting-outputs`, commit |
| `dart format --set-exit-if-changed .` | formatting | `dart format .` |
| `flutter analyze --fatal-infos` | `flutter_agent_lints`; infos fail too | `flutter analyze --fatal-infos` |
| `very_good test --coverage --min-coverage 100` | a test failed, or hand-written code is uncovered | see below |

Coverage is a hard 100% gate on hand-written code, with generated files
(`*.freezed.dart`, `*.g.dart`, `*.mocks.dart`) excluded and `main.dart` carrying
a `coverage:ignore-file` marker. A coverage failure on a PR that added code
means the new code needs tests — not that the threshold needs lowering.

Regenerating with `--delete-conflicting-outputs` and `--build-filter` together
is blocked by a global hook, and rightly: the first deletes every generated
file while the second regenerates only a subset, leaving the tree broken. Use
one or the other.

## `web` — `apps/web` (Jaspr, Dart)

Runs `dart format --set-exit-if-changed .`, `dart analyze --fatal-infos`,
`dart test`, `dart test -p chrome test/client`, `jaspr build`, then
`git diff --exit-code -- lib`.

Two failure modes are specific to this job:

- **`git diff --exit-code -- lib`** — the build rewrote a committed
  `*.options.dart`. Run the build and commit the generated file.
- **`dart test -p chrome test/client`** — the browser half. Running it through
  the very_good CLI MCP tool requires `optimization: false`, because the test
  optimizer bundles everything into one VM entrypoint and the
  `@TestOn('browser')` files then fail to compile on `dart:js_interop`.

## `supabase` — `supabase/**`

`supabase db start`, `supabase test db --local` (pgTAP), then
`supabase db lint --local --fail-on warning`.

A pgTAP failure is usually a row-level-security assertion, and RLS is the point
of the suite (ADR 0010) — a failing policy test is a security finding, not a
flake. Reproduce with `supabase start` and `supabase test db --local`.

`supabase-deploy` only runs on `main`; it is never part of a PR's checks.

## Flaky vs branch-related

Treat as **flaky/infrastructural** — re-run, up to 3 per SHA:

- runner provisioning or image startup failure
- DNS, registry or network timeout while fetching dependencies
- GitHub Actions service degradation
- a container failing to start (for example `supabase db start` timing out)

Treat as **branch-related** — fix it:

- anything deterministic in code the PR touched
- lint, analyze, format, typecheck, coverage
- a tripwire (`contract.schema.json`, `*.options.dart`, `build_runner`)

The tripwires look like infrastructure and are not: they fail because
committed generated output drifted from its source, which is a branch problem
with a one-command fix.

When the same job fails twice on the same SHA with the same log, stop calling
it flaky.
