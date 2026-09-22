import 'package:feature_account/feature_account.dart';
import 'package:flutter/widgets.dart';

/// Records what the account feature asked of the app.
class FakeAccountNavigator() extends AccountNavigator {
  /// How often the feature asked to be signed out.
  var signOuts = 0;

  /// How often the feature asked for the consent screen.
  var consentRequests = 0;

  /// How often the feature asked for the account screen.
  var accountOpens = 0;

  @override
  void signOut(BuildContext context) => signOuts++;

  @override
  Future<void> requestConsent(NavigatorState navigator) {
    consentRequests++;
    return Future.value();
  }

  @override
  void openAccount(NavigatorState navigator) => accountOpens++;
}
