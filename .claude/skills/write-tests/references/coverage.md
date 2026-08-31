# Coverage

- CI gate: `very_good test --coverage --min-coverage 100` in the app job —
  hard failure below 100%.
- Exemptions are per-file and explicit: `// coverage:ignore-file` on its own
  line, reserved for composition roots (main.dart). Generated files
  (`*.freezed.dart`, `*.g.dart`, `*.mocks.dart`, localizations) are stripped
  before the gate when they appear.
- Never chase the gate with tautological tests; if a line can't be reached
  through the UI or a justified bloc test, question the line.
