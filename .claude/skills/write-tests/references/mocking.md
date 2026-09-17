# Mocking

- mockito + build_runner. All mocks generated from ONE file,
  `apps/mobile/packages/utility/testing/lib/src/mocks.dart`, with a single
  `@GenerateNiceMocks([...])` on the export of the generated library — never
  define mocks inside test files, and never add a second `mocks.dart` to a
  package. Every package gets `MockClient` and `MockPosthog` from
  `package:testing`.
- The `testing` package's `build.yaml` scopes the builder to that one file:

      builders:
        mockito|mockBuilder:
          generate_for: ['lib/src/mocks.dart']

- `provideDummy(...)` for non-nullable state types mockito can't construct.
- What may be mocked: the http clients behind the agent API (`AgentStub`)
  and the Supabase SDK (`SupabaseStub`, the real `SupabaseClient` over a
  scripted `MockClient`; sign in a test with `supabase.signedIn()`, script
  the data API per `METHOD /rest/v1/...` with `rest(...)`, defaults come
  from `journalWorks()`), platform
  channels, and infrastructure like image caching. Every stub and spy —
  `AgentStub`, `ConfigStub`, `SupabaseStub`, `AnalyticsSpy`, `UrlLauncherSpy`,
  the journal row builders, the a11y check and the submit helpers — lives in
  `package:testing`, which depends on the utilities it fakes (they dev-depend
  on it in turn). `appUnderTest(...)` in the app's
  `test/helpers/app_harness.dart` wires the stubs together the way `main.dart`
  does; only that and `pumpApp` stay in the app.
  What may NOT be mocked: blocs, repositories with logic, widgets.
- `SupabaseStub.script(otp:, verify:, password:, logout:)` queues the auth
  endpoints (`/auth/v1/otp`, `/verify`, `/token`, `/logout`). Rounds are
  keyed on `METHOD /path` only: `password:` serves every
  `POST /auth/v1/token`, whatever its `grant_type` query says — assert the
  query on the recorded request (`to(...).single.query['grant_type']`).
- PostHog is the `MockPosthog` behind `AnalyticsSpy`: `capture` lands in
  `spy.events`, `captureException` in `spy.exceptions`, and
  `spy.outgoingStrings` is everything that would leave the device (event
  names, properties, identities, each exception's type, text, cause chain,
  properties and stack trace) — what the needle tests scan. Assert a report
  with `captured(error, {'step': ..., ...})`; an exception whose message the
  reporter withholds is
  `withheld(PostgrestApiException, code: 'XX000', statusCode: 409)` or
  `withheld(AuthApiException, code: ..., statusCode: ...)`.
- No tests for pure passthrough layers — a delegation with no logic gets its
  coverage from the layer above.
