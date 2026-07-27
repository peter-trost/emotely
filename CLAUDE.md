# emotely

Rebuild of the original emotely journaling app around a tools-first AI harness.
Read [`README.md`](README.md) for the architecture and [`docs/adr/`](docs/adr/)
for the load-bearing decisions.

## Conventions

- Research the latest version and current API of any dependency, model, or action
  from its canonical source before pinning or calling it — never from memory.
- `main` is protected: all changes land via squash-merged PR, `ci-ok` green.
