import 'package:feature_session/src/view/session_page.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

part 'routes.g.dart';

/// The session's screen as a route (ADR 0016), at the root so that pushing
/// it covers whatever tab bar the app shows: a session is not something to
/// switch away from. The app reaches it through the journal's navigator.

/// A journaling session, pushed so the caller can reload when it pops.
/// `?resume=<id>` picks that stored session up; the session reads it back
/// itself, so the location is all there is to carry. The journal only ever
/// holds one session in progress (a new one replaces it), but the route
/// names which, so the location says what it does and a second unfinished
/// session would need no new route.
@TypedGoRoute<SessionRoute>(path: '/session', name: 'session')
@immutable
class const SessionRoute({final String? resume})
    extends GoRouteData
    with $SessionRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      SessionPage(resume: resume);
}
