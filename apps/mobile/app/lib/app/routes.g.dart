// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $signInRoute,
  $appShellRoute,
  $sessionRoute,
  $consentRoute,
];

RouteBase get $signInRoute => GoRouteData.$route(
  path: '/sign-in',
  name: 'signIn',
  hasOverriddenOnExit: false,
  factory: $SignInRoute._fromState,
);

mixin $SignInRoute on GoRouteData {
  static SignInRoute _fromState(GoRouterState state) =>
      SignInRoute(from: state.uri.queryParameters['from']);

  SignInRoute get _self => this as SignInRoute;

  @override
  String get location => GoRouteData.$location(
    '/sign-in',
    queryParams: {if (_self.from != null) 'from': _self.from},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $appShellRoute => StatefulShellRouteData.$route(
  factory: $AppShellRouteExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/',
          name: 'journal',
          hasOverriddenOnExit: false,
          factory: $JournalRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'entries/:id',
              name: 'entry',
              hasOverriddenOnExit: false,
              factory: $EntryRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/more',
          name: 'more',
          hasOverriddenOnExit: false,
          factory: $MoreRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'account',
              name: 'account',
              hasOverriddenOnExit: false,
              factory: $AccountRoute._fromState,
            ),
          ],
        ),
      ],
    ),
  ],
);

extension $AppShellRouteExtension on AppShellRoute {
  static AppShellRoute _fromState(GoRouterState state) => const AppShellRoute();
}

mixin $JournalRoute on GoRouteData {
  static JournalRoute _fromState(GoRouterState state) => const JournalRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $EntryRoute on GoRouteData {
  static EntryRoute _fromState(GoRouterState state) =>
      EntryRoute(id: state.pathParameters['id']!);

  EntryRoute get _self => this as EntryRoute;

  @override
  String get location =>
      GoRouteData.$location('/entries/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MoreRoute on GoRouteData {
  static MoreRoute _fromState(GoRouterState state) => const MoreRoute();

  @override
  String get location => GoRouteData.$location('/more');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AccountRoute on GoRouteData {
  static AccountRoute _fromState(GoRouterState state) => const AccountRoute();

  @override
  String get location => GoRouteData.$location('/more/account');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $sessionRoute => GoRouteData.$route(
  path: '/session',
  name: 'session',
  hasOverriddenOnExit: false,
  factory: $SessionRoute._fromState,
);

mixin $SessionRoute on GoRouteData {
  static SessionRoute _fromState(GoRouterState state) =>
      SessionRoute(resume: state.uri.queryParameters['resume']);

  SessionRoute get _self => this as SessionRoute;

  @override
  String get location => GoRouteData.$location(
    '/session',
    queryParams: {if (_self.resume != null) 'resume': _self.resume},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $consentRoute => GoRouteData.$route(
  path: '/consent',
  name: 'consent',
  hasOverriddenOnExit: false,
  factory: $ConsentRoute._fromState,
);

mixin $ConsentRoute on GoRouteData {
  static ConsentRoute _fromState(GoRouterState state) => const ConsentRoute();

  @override
  String get location => GoRouteData.$location('/consent');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
