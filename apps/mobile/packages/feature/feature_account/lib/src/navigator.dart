import 'package:flutter/widgets.dart';

/// What the account feature asks of the app and cannot do itself, because
/// a feature never knows another feature (ADR 0015): signing the user out
/// belongs to the auth feature, and the consent screen, though this
/// feature's own route, is pushed by the app so that it lands on the root
/// navigator above the tab bar (ADR 0016). The app implements this; a test
/// fakes it.
///
/// One of the two places a widget may touch the container is resolving
/// this: `GetIt.I<AccountNavigator>()`. Every method takes the
/// [BuildContext] of the tap that asked.
abstract class AccountNavigator() {
  /// Signs the user out. The router lands on sign-in underneath; the
  /// account route pops itself afterwards.
  void signOut(BuildContext context);

  /// Shows the consent screen on its own route and completes once it is
  /// closed, however it was closed. The More tab asks the server again
  /// afterwards; what the route answered is the app's to act on.
  Future<void> requestConsent(BuildContext context);
}
