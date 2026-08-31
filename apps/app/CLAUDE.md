# apps/app — Flutter client

State management: bloc (no abstract-interface ceremony). Widgets: standalone
`material_ui`/`cupertino_ui` packages (never `flutter/material.dart`). Custom
look lives in `ThemeData` (Baskervville serif, emotely-orange seed), not in
hand-rolled widgets.

## Testing conventions (from flutter-testing-concepts, refined)

- **Drive tests through the UI with real blocs; mock the agent API at the
  http seam.** Never mock a bloc — error states are injected by making the
  mocked API return them.
- `blocTest` unit tests only for blocs with genuinely complex state that
  would slow widget tests; trivial blocs are covered through widgets.
- No tests for pure passthrough layers — a delegation with no logic gets its
  coverage from the layer above.
- Every widget test file also runs the 3-line a11y guideline check
  (`testIfWidgetMeetsAccessibilityGuidelines`: tap targets, labels, contrast).
- Mocks: mockito, generated from ONE `test/mocks.dart` (`@GenerateMocks`);
  never define mocks in test files. `build.yaml` scopes the builder to
  `test/**` + `integration_test/**`.
- One `pumpApp` extension in `test/helpers/pump_app.dart` — localization with
  a NON-English default locale (catches hardcoded strings); per-file local
  `pumpTestWidget` closures carry variation via named params.
- Finders: static `Key` constants on the widget class are the contract
  (`find.byKey(SubmitButton.key)`); localized strings asserted via the real
  l10n object from `tester.element(...)`, never hardcoded.
- Explicit `pump()` over `pumpAndSettle()`; settle only for animated
  transitions/navigation.
- `group()` takes the class reference, not a string. Test names are plain
  declarative sentences ("renders loading state", "submit is disabled when no
  answer selected") — no given/when/then, no "should", no Arrange/Act comments.
- Integration tests: robot pattern (`integration_test/<flow>_robot.dart`),
  agent API mocked with canned tool-call rounds — CI never hits the network.
  The live-agent smoke test runs nightly/pre-release only.
- Coverage: hard 100% gate — `very_good test --coverage --min-coverage 100`
  with generated files (`*.freezed.dart`, `*.g.dart`, `*.mocks.dart`,
  localizations) stripped from lcov first.
