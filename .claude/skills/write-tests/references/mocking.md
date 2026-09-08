# Mocking

- mockito + build_runner. All mocks generated from ONE `test/mocks.dart` with
  a single `@GenerateMocks([...])` — never define mocks inside test files.
- `build.yaml` scopes the builder:

      builders:
        mockito|mockBuilder:
          generate_for: ['test/**.dart', 'integration_test/**.dart']

- `provideDummy(...)` for non-nullable state types mockito can't construct.
- What may be mocked: the http clients behind the agent API (`AgentStub`)
  and the Supabase SDK (`SupabaseStub`, the real `SupabaseClient` over a
  scripted `MockClient`; sign in a test with `supabase.signedIn()`, script
  the data API per `METHOD /rest/v1/...` with `rest(...)`, defaults come
  from `journalWorks()`), platform
  channels, and infrastructure like image caching. `appUnderTest(...)` in
  `test/helpers/app_harness.dart` wires the three together the way `main.dart`
  does.
  What may NOT be mocked: blocs, repositories with logic, widgets.
- No tests for pure passthrough layers — a delegation with no logic gets its
  coverage from the layer above.
