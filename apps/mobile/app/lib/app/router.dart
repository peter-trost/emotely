import 'dart:async';

import 'package:emotely/app/routes.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// The one decision above every screen — signed in or not — as a redirect
/// (ADR 0016). Signed out, every location leads to sign-in, which remembers
/// where the user was going; signed in, sign-in leads there, or to the
/// journal when there was nowhere in particular, and everything else
/// stands.
///
/// So a deep link opened while signed out, or a screen the user was on when
/// the session ended under them, is where they land once they sign in.
/// Only a location of this app's is honoured: anything that does not start
/// with `/`, or that would lead back to sign-in, falls back to the journal.
///
/// Pure, so it can be read and tested on its own: [signedIn] is the auth
/// bloc's answer at the moment the router asks, and [uri] the location
/// being entered, query and all.
String? authRedirect({required bool signedIn, required Uri uri}) {
  final signIn = const SignInRoute().location;
  final atSignIn = uri.path == signIn;
  if (!signedIn) {
    if (atSignIn) {
      return null;
    }
    final wanted = uri.toString();
    return SignInRoute(
      from: wanted == const JournalRoute().location ? null : wanted,
    ).location;
  }
  if (!atSignIn) {
    return null;
  }
  final from = uri.queryParameters['from'];
  final local =
      from != null && from.startsWith('/') && !from.startsWith(signIn);
  return local ? from : const JournalRoute().location;
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
  redirect: (context, state) =>
      authRedirect(signedIn: auth.state is AuthSignedIn, uri: state.uri),
  observers: observers,
);
