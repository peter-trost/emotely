import 'package:feature_journal/feature_journal.dart';
import 'package:flutter/widgets.dart';

/// Records what the journal asked of the app, and answers the consent
/// question the way a test says.
class FakeJournalNavigator() extends JournalNavigator {
  /// Every session the journal asked to run, and whether it was to be
  /// resumed.
  final sessions = <bool>[];

  /// How often the journal asked for consent.
  var consentRequests = 0;

  /// What a consent request answers.
  var consentGiven = false;

  /// Every entry the journal asked to open, by id.
  final entryOpens = <String>[];

  /// How often the journal opened the account screen.
  var accountOpens = 0;

  /// How often the journal asked to be signed out.
  var signOuts = 0;

  @override
  Future<void> startSession(NavigatorState navigator, {required bool resume}) {
    sessions.add(resume);
    return Future.value();
  }

  @override
  Future<bool> requestConsent(NavigatorState navigator) {
    consentRequests++;
    return Future.value(consentGiven);
  }

  @override
  void openEntry(NavigatorState navigator, {required String entryId}) =>
      entryOpens.add(entryId);

  @override
  void openAccount(NavigatorState navigator) => accountOpens++;

  @override
  void signOut(BuildContext context) => signOuts++;
}
