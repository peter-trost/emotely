import 'package:feature_journal/feature_journal.dart';
import 'package:flutter/widgets.dart';
import 'package:journal_repository/journal_repository.dart';

/// Records what the journal asked of the app, and answers the consent
/// question the way a test says.
class FakeJournalNavigator() extends JournalNavigator {
  /// Every session the journal asked to run, with what it wanted resumed.
  final sessions = <OpenSession?>[];

  /// How often the journal asked for consent.
  var consentRequests = 0;

  /// What a consent request answers.
  var consentGiven = false;

  /// How often the journal opened the account screen.
  var accountOpens = 0;

  /// How often the journal asked to be signed out.
  var signOuts = 0;

  @override
  Future<void> startSession(NavigatorState navigator, {OpenSession? resume}) {
    sessions.add(resume);
    return Future.value();
  }

  @override
  Future<bool> requestConsent(NavigatorState navigator) {
    consentRequests++;
    return Future.value(consentGiven);
  }

  @override
  void openAccount(NavigatorState navigator) => accountOpens++;

  @override
  void signOut(BuildContext context) => signOuts++;
}
