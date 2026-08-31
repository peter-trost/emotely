# Bloc unit tests

Allowed ONLY when the bloc has genuinely complex state whose combinations
would significantly slow the suite as widget tests. Trivial blocs
(load → success/error) are covered through widgets — do not add blocTest
suites to them.

When justified:

- `blocTest<SessionBloc, SessionState>` from bloc_test.
- `expect:` matches FULL state instances, never single properties.
- Initial state gets a plain `test()`, not a blocTest.
- Multi-step acts use cascades: `act: (bloc) => bloc..add(A())..add(B())`.
- `errors:` alongside `expect:` when the bloc rethrows.
- Pure computed methods get plain `test()` cases.
