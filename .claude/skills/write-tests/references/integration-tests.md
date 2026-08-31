# Integration tests

- `integration_test` package, robot pattern: one
  `integration_test/<flow>_robot.dart` per flow holding the WidgetTester;
  finders are getters, actions are Future<void> methods ending in
  `pumpAndSettle()`; tests read as prose.
- The agent API is mocked with canned tool-call rounds (scripted
  ask_question/complete sequences) — CI never hits the network.
- Coarse assertions on purpose: `findsOneWidget` on screen types plus the few
  properties that define the flow.
- The LIVE-agent smoke test (real deployed endpoint, full session) runs
  nightly and pre-release only — never per-PR.
