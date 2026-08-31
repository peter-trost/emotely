# apps/app — Flutter client

State management: bloc. Widgets: standalone
`material_ui`/`cupertino_ui` packages (never `flutter/material.dart`). Custom
look lives in `ThemeData` (Baskervville serif, emotely-orange seed), not in
hand-rolled widgets.

Tests: follow the `write-tests` skill (.claude/skills/write-tests) — UI-driven
with real blocs, agent API mocked at the http seam, universal a11y check,
hard 100% coverage gate.
