# Mocking

- mockito + build_runner. All mocks generated from ONE `test/mocks.dart` with
  a single `@GenerateMocks([...])` — never define mocks inside test files.
- `build.yaml` scopes the builder:

      builders:
        mockito|mockBuilder:
          generate_for: ['test/**.dart', 'integration_test/**.dart']

- `provideDummy(...)` for non-nullable state types mockito can't construct.
- What may be mocked: the agent API http client (the ONLY seam for session
  behavior), platform channels, and infrastructure like image caching.
  What may NOT be mocked: blocs, repositories with logic, widgets.
- No tests for pure passthrough layers — a delegation with no logic gets its
  coverage from the layer above.
