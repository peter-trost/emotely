# Lego package layering for the Flutter client

The Flutter client (`apps/mobile`) is a pub workspace of packages in three
tiers, after Tide's "Project Miniclient" architecture:

- **utilities** (`packages/utility/*`) depend only on other utilities;
- **features** (`packages/feature/*`) depend only on utilities, and never on
  another feature;
- **the app** (`app`) is glue: it depends on anything and composes the
  features.

Every package carries its own gates — codegen tripwire, format, analyze
against the one shared rule set (`packages/utility/analysis`), and the hard
100% coverage gate — and CI runs those gates only for the packages a pull
request changed plus their dependents (`melos run ci`, scoped through
`EMOTELY_SCOPE`).

## Why

The client had grown to five features inside one package, with one
build_runner pass, one analyzer run and one 260-test suite that every change
paid for in full, and with nothing but discipline keeping `journal` from
importing `session`'s internals. Both costs grow with the app, not with the
change. Packages make the boundary a compile error and let every gate scale
with what changed.

We chose Tide's three tiers over VGV's four layers (data, repository,
business logic, presentation as separate packages) because VGV cuts by layer
and Tide cuts by feature: a feature package owns its bloc, its screens and its
tests, which is the unit an agent touches and a reviewer reads. Repositories
and analytics builders are utilities in this model; the vocabulary is
*Repository* for Supabase-backed data access, as both references use it.

We chose a pub workspace plus melos over path dependencies alone because a
workspace resolves once (one lock file, one package config, no drift between
packages) and melos gives per-package, change-scoped scripts without a
second build system. Tide manages ~300 packages with melos; we have a
handful, and the same tooling holds.

## Consequences

- Adding a package is a checklist, not a design decision: pubspec with
  `resolution: workspace`, a one-line `analysis_options.yaml`, an entry in the
  root `workspace:` list, tests, and the gates run without further wiring.
- A change to the shared rule set, the workspace pubspec or lock, or the
  contract schema runs every package's gates, because it affects every
  package.
- `flutter_launcher_icons` left the dependency graph: its newest release pins
  a `cli_util` that cannot resolve next to melos, and it is only ever run by
  hand (`dart pub global run flutter_launcher_icons` from `app`).
- Cross-feature navigation needs a seam, since features cannot import each
  other: one abstract navigator per feature, implemented by the app. That and
  the dependency-injection container that lets a feature package register
  itself are the second half of this decision, recorded when they land.

Decided on #39 (design comment of 2026-09-17), implemented as a stack of
pull requests starting with the move to `apps/mobile`.
