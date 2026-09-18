# apps/mobile/app — Flutter client

State management: bloc. Widgets: standalone
`material_ui`/`cupertino_ui` packages (never `flutter/material.dart`). Custom
look lives in `ThemeData` (Baskervville serif, emotely-orange seed), not in
hand-rolled widgets.

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
  its own feature's navigator (once features are packages). Nothing else in
  a widget reads a dependency; a side effect that needs one (analytics, a
  launcher) is an event the bloc handles.
- Build-time values (`--dart-define`s) are read and validated in the app
  only (`lib/app/environment.dart`, `urlFrom`) and passed into registration
  functions. No package calls `String.fromEnvironment`.
- Tests compose with the same `registerApp` and replace only the leaves:
  the two http clients, the Supabase client, the PostHog instance
  (`test/helpers/app_harness.dart`). `getIt.reset()` runs in teardown;
  `allowReassignment` stays off so a double registration fails loudly.
