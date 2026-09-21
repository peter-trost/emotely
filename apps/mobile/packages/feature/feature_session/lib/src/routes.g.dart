// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$sessionRoute];

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
