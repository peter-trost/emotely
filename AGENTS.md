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
- **AI Gateway is not plan-gated**, so the agent runtime
  ([ADR 0003](docs/adr/0003-model-gateway-and-cost-ceiling.md)) never depended
  on the plan. Pro unlocks the peripheral features (team-wide provider
  allowlist, Zero Data Retention, Trace Drains) and more than one firewall
  rate-limit rule ([ADR 0008](docs/adr/0008-public-endpoint-abuse-controls.md)).

## Tooling

- [Entire](docs/tooling/entire.md) — captures agent sessions and links them to
  commits. Active in this repo; capture is automatic. Use `entire why <file>:<line>`
  / `entire checkpoint explain <sha>` to recover the intent behind a change, and
  leave the `Entire-Checkpoint` commit trailer alone.
