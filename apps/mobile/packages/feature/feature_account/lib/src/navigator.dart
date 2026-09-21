import 'package:flutter/widgets.dart';

/// What the account feature asks of the app and cannot do itself, because
/// a feature never knows another feature (ADR 0015): signing the user out
/// belongs to the auth feature. The app implements this; a test fakes it.
///
/// One of the two places a widget may touch the container is resolving
/// this: `GetIt.I<AccountNavigator>()`.
abstract class AccountNavigator() {
  /// Signs the user out. The router lands on sign-in underneath; the
  /// account route pops itself afterwards.
  void signOut(BuildContext context);

  /// Shows the consent screen on its own route and completes once it is
  /// closed, however it was closed. The account screen asks the server
  /// again afterwards; what the route answered is the app's to act on.
  ///
  /// Takes the [NavigatorState] rather than a context so the app can reach
  /// its router from something that outlives the screen.
  Future<void> requestConsent(NavigatorState navigator);
}
