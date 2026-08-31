# Widget tests

- Use the `pumpApp` extension (`test/helpers/pump_app.dart`) — real themes,
  real localization once l10n exists, with a NON-English default locale so
  hardcoded strings fail.
- Each test file defines a local `pumpTestWidget(tester, {...})` closure in
  `main()`'s scope; named parameters carry variation, mocks stay in scope.
- Provide REAL blocs backed by the mocked agent API. Never mock a bloc; reach
  rare states (errors, timeouts) by making the mocked API produce them.
- Finders, in order of preference: static `Key` constants declared on the
  widget class (`find.byKey(SubmitButton.submitKey)`), `find.byType`,
  localized text via the real l10n object
  (`tester.element(find.byType(WidgetUnderTest))`) — never hardcoded strings.
- Explicit `pump()` over `pumpAndSettle()`; settle only for animated
  transitions/navigation.
- Assert widget properties via `tester.widget<FilledButton>(finder).onPressed`
  for enabled/disabled.
- Run one test across locales with a `ValueVariant` subclass declared at the
  end of the file.
- Close every file's suite with the a11y check:
  `await tester.expectMeetsAccessibilityGuidelines(widgetUnderTest);`
