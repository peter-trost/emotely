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

## Tooling

- [Entire](docs/tooling/entire.md) — captures agent sessions and links them to
  commits. Active in this repo; capture is automatic. Use `entire why <file>:<line>`
  / `entire checkpoint explain <sha>` to recover the intent behind a change, and
  leave the `Entire-Checkpoint` commit trailer alone.
