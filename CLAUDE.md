# emotely

Rebuild of the original emotely journaling app around a tools-first AI harness.
Read [`README.md`](README.md) for the architecture and [`docs/adr/`](docs/adr/)
for the load-bearing decisions.

## Conventions

- Research the latest version and current API of any dependency, model, or action
  from its canonical source before pinning or calling it — never from memory.
- `main` is protected: all changes land via squash-merged PR, `ci-ok` green.
- Lints are deny-by-default and always errors: biome `preset: "all"`
  (`biome.jsonc`), all TS strictness flags, `very_good_analysis` + strict
  language modes with `flutter analyze --fatal-infos`. Disabling any rule
  requires an in-config justification comment next to the override. Never
  fix a diagnostic by weakening a rule without that justification.

## Billing

- **MUST upgrade Vercel to Pro before taking any payment.** The account hosting
  `emotely-agent` is on **Hobby** as of 2026-08-29 (downgraded from Pro during
  the IAKUVO shutdown to cut costs). Before emotely accepts its first payment —
  or advertises a paid tier, runs ads, or asks for donations — it MUST be back
  on Pro. Hobby is non-commercial-only: Vercel defines commercial usage as any
  deployment "used for the purpose of financial gain of anyone involved in any
  part of the production of the project", with no de-minimis threshold, and
  reserves the right to terminate Hobby projects without notice. Treat this as a
  release-blocking item on the payments work, not background cleanup. Source:
  [Fair Use Guidelines](https://vercel.com/docs/limits/fair-use-guidelines)
  § "Commercial usage"; [Terms of Service](https://vercel.com/legal/terms) § 4.
- **AI Gateway is not plan-gated** and works on Hobby, so the agent runtime
  ([ADR 0003](docs/adr/0003-model-gateway-and-cost-ceiling.md)) is unaffected by
  the downgrade. Only peripheral features are Pro-gated (team-wide provider
  allowlist, Zero Data Retention, Trace Drains). The downgrade is not a reason to
  move off the gateway.

## Tooling

- [Entire](docs/tooling/entire.md) — captures agent sessions and links them to
  commits. Active in this repo; capture is automatic. Use `entire why <file>:<line>`
  / `entire checkpoint explain <sha>` to recover the intent behind a change, and
  leave the `Entire-Checkpoint` commit trailer alone.
