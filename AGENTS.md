# emotely

Rebuild of the original emotely journaling app around a tools-first AI harness.
Read [`README.md`](README.md) for the architecture and [`docs/adr/`](docs/adr/)
for the load-bearing decisions.

Agents are first-class citizens here: every action must be executable by an
agent end to end — building, running, testing, deploying, verifying — with a
human in the loop only for critical steps such as production access and secret
handling. If a step is only documented for humans, move it into a skill.

## Conventions

- Research the latest version and current API of any dependency, model, or action
  from its canonical source before pinning or calling it — never from memory.
- `main` is protected: all changes land via squash-merged PR, `ci-ok` green.
- Never point at a skill from a `CLAUDE.md`: skill descriptions are already in
  context, so the pointer is noise. Put the fact itself here or in the skill.
- Lints are deny-by-default and always errors: biome `preset: "all"`
  (`biome.jsonc`), all TS strictness flags,
  [`flutter_agent_lints`](https://github.com/peter-trost/flutter_agent_lints)
  (experimental variant; every SDK rule is an error or a reasoned `false`)
  with `flutter analyze --fatal-infos`. Disabling any rule requires an
  in-config justification comment next to the override. Never fix a
  diagnostic by weakening a rule without that justification.

## Billing

- **Vercel is on Pro since 2026-09-13 and MUST stay there** while emotely is
  in front of testers or customers. The team hosting `emotely-agent` was on
  Hobby from 2026-08-29 (downgraded during the IAKUVO shutdown) and was upgraded
  again for the beta. Hobby is non-commercial-only: Vercel defines commercial
  usage as any deployment "used for the purpose of financial gain of anyone
  involved in any part of the production of the project", with no de-minimis
  threshold, and reserves the right to terminate Hobby projects without notice.
  Never downgrade to save the ~20 USD/month while the app is distributed.
  Source: [Fair Use Guidelines](https://vercel.com/docs/limits/fair-use-guidelines)
  § "Commercial usage"; [Terms of Service](https://vercel.com/legal/terms) § 4.
- **The agent runtime now depends on Pro** (changed 2026-09-15). Gateway
  *access* is not plan-gated, and until now Pro only unlocked peripheral
  features (team-wide provider allowlist, Trace Drains) and more than one
  firewall rate-limit rule
  ([ADR 0008](docs/adr/0008-public-endpoint-abuse-controls.md)) — so the
  runtime genuinely did not depend on the plan. It does now: every model round
  requests **request-level Zero Data Retention**, which Vercel gates to **Pro
  and Enterprise only**
  ([ADR 0003](docs/adr/0003-model-gateway-and-cost-ceiling.md) amendment
  2026-09-15). The gateway's privacy filters fail *closed*, so a downgrade
  would not quietly fall back to weaker privacy — it would **fail every round
  of every session**, taking the app down rather than degrading it. That is
  the safer failure mode, and it turns "stay on Pro" from a billing
  preference into a runtime requirement: a downgrade is an outage, not a
  saving.

## Tooling

- [`scripts/setup-dev-environment.sh`](scripts/setup-dev-environment.sh) — brings
  a fresh Linux machine to where every job in `ci.yml` runs locally (Node, pnpm,
  Flutter, Dart, the Supabase CLI, a headless Chromium). Root on x86_64, Docker
  expected to exist already. Idempotent, fails loudly, and reads every version
  pin out of the repo rather than carrying its own. `dart` is the standalone SDK
  `apps/web` is pinned to; `flutter-dart` is Flutter's bundled one and is what
  `apps/app` uses wherever CI says `dart`. It does not cover the device-side
  jobs (`app-release.yml` needs an Android SDK and a JDK) and installs no
  secrets, no `fvm` and no `gh`; it lists what it skipped when it finishes.
- [Entire](docs/tooling/entire.md) — captures agent sessions and links them to
  commits. Active in this repo; capture is automatic. Use `entire why <file>:<line>`
  / `entire checkpoint explain <sha>` to recover the intent behind a change, and
  leave the `Entire-Checkpoint` commit trailer alone.
