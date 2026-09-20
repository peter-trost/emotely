import 'dart:async';

import 'package:emotely/app/routes.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// The one decision above every screen — signed in or not — as a redirect
/// (ADR 0016). Signed out, every location leads to sign-in; signed in,
/// sign-in leads to the journal and everything else stands.
///
/// Pure, so it can be read and tested on its own: [signedIn] is the auth
/// bloc's answer at the moment the router asks, and [location] is the
/// matched path without its query.
String? authRedirect({required bool signedIn, required String location}) {
  final signIn = const SignInRoute().location;
  if (!signedIn) {
    return location == signIn ? null : signIn;
  }
  return location == signIn ? const JournalRoute().location : null;
}

/// Tells the router to ask [authRedirect] again whenever whether someone is
/// signed in changes — and only then. The auth bloc moves through several
/// states while a code is typed; none of those changes where the user may
/// be, so none of them re-evaluates the route stack.
///
/// The owner disposes it; the router does not own its listenable.
class SignedInListenable(final AuthBloc _auth) extends ChangeNotifier {
  this {
    _changes = _auth.stream
        .map((state) => state is AuthSignedIn)
        .distinct()
        .listen((_) => notifyListeners());
  }

  late final StreamSubscription<void> _changes;

  @override
  void dispose() {
    unawaited(_changes.cancel());
    super.dispose();
  }
}

/// The router over the route table, guarded by [authRedirect] against the
/// live state of [auth]. The redirect reads the bloc when it runs rather
/// than a value captured earlier, so a sign-out from anywhere — the
/// account screen, an expired token, an account deleted elsewhere — lands
/// on sign-in and replaces whatever was on the stack.
GoRouter createRouter({
  required AuthBloc auth,
  required SignedInListenable refresh,
  required List<NavigatorObserver> observers,
}) => GoRouter(
  routes: $appRoutes,
  initialLocation: const JournalRoute().location,
  refreshListenable: refresh,
  redirect: (context, state) => authRedirect(
    signedIn: auth.state is AuthSignedIn,
    location: state.matchedLocation,
  ),
  observers: observers,
);
