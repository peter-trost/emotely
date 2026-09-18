import 'package:flutter/widgets.dart';

/// What the account feature asks of the app and cannot do itself, because
/// a feature never knows another feature (ADR 0015): signing the user out
/// belongs to the auth feature. The app implements this; a test fakes it.
///
/// One of the two places a widget may touch the container is resolving
/// this: `GetIt.I<AccountNavigator>()`.
abstract class AccountNavigator() {
  /// Signs the user out. The root swaps to sign-in underneath; the account
  /// route pops itself afterwards.
  void signOut(BuildContext context);
}
