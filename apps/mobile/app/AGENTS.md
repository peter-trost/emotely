# apps/mobile/app — Flutter client

State management: bloc. Widgets: standalone
`material_ui`/`cupertino_ui` packages (never `flutter/material.dart`). Custom
look lives in `ThemeData` (Baskervville serif, emotely-orange seed), not in
hand-rolled widgets.

## Routing (ADR 0016)

- `lib/app/routes.dart` is the one route table: a `GoRouteData` class per
  screen with a `@TypedGoRoute` annotation, generated into `routes.g.dart`
  by go_router_builder (`dart run build_runner build` here after any
  change; `melos run codegen:check` is the tripwire). Only the app depends
  on go_router; a feature package never imports it.
- Nothing travels as `extra`. A route carries path and query parameters
  only (`EntryRoute(id:)`, `SessionRoute(resume:)`), and the screen reads
  what it shows by that. A screen that needs an object gets a bloc that
  loads it, not a constructor argument from the caller.
- A feature reaches a screen through its navigator, and the app's
  implementation in `lib/app/navigators.dart` answers with a route:
  `const AccountRoute().go(navigator.context)`, or `.push<T>` when the
  caller awaits an answer (the session's end, the consent outcome). The
  navigator's context outlives any screen, which is why the seams take a
  `NavigatorState` rather than a page's context.
- The signed-in/out guard is `authRedirect` in `lib/app/router.dart`, pure
  over "signed in?" and the matched location; `SignedInListenable` re-runs
  it only when that boolean flips. Never gate a screen on auth state
  inside a widget — add to the redirect.
- The router is built once, in `_RouterState`, over the auth bloc above
  it. `ConfigGate` and `PostHogWidget` live in `MaterialApp.router`'s
  `builder`, over the navigator.

## Dependencies (ADR 0015)

- `lib/app/dependencies.dart` is the one composition root: `registerApp`
  fills the get_it container in dependency order and nothing else registers
  anything. Every utility and every feature exposes one plain
  `registerX(GetIt getIt, {...})` function; the app calls them.
- Blocs are factories, created by the screen that owns them. Everything
  else is an eager singleton and user-agnostic: nothing per-user outlives a
  screen, so sign-out already drops all state. The day a per-user object
  must outlive a screen, it goes into a get_it scope pushed on sign-in and
  popped on sign-out — not into a singleton.
- Widgets touch the container in exactly two places:
  `BlocProvider(create: (_) => GetIt.I<SomeBloc>())`, and a page resolving
  its own feature's navigator (`GetIt.I<JournalNavigator>()`). Nothing else
  in a widget reads a dependency; a side effect that needs one (analytics, a
  launcher) is an event the bloc handles.
- Every feature's navigator is implemented in `lib/app/navigators.dart` and
  registered next to the feature in `registerApp`. The app is the only
  place that knows two features' pages and blocs together, so cross-feature
  routes, and what the user is told about their outcome, live there.
- Build-time values (`--dart-define`s) are read and validated in the app
  only (`lib/app/environment.dart`, `urlFrom`) and passed into registration
  functions. No package calls `String.fromEnvironment`.
- Tests compose with the same `registerApp` and replace only the leaves:
  the two http clients, the Supabase client, the PostHog instance
  (`test/helpers/app_harness.dart`). `getIt.reset()` runs in teardown;
  `allowReassignment` stays off so a double registration fails loudly.
