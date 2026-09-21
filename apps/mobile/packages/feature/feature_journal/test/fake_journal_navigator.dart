import 'package:feature_journal/feature_journal.dart';
import 'package:flutter/widgets.dart';

/// Records what the journal asked of the app, and answers the consent
/// question the way a test says.
class FakeJournalNavigator() extends JournalNavigator {
  /// Every session the journal asked to run: the id to resume, or null for
  /// a fresh one.
  final sessions = <String?>[];

  /// How often the journal asked for consent.
  var consentRequests = 0;

  /// What a consent request answers.
  var consentGiven = false;

  @override
  Future<void> startSession(NavigatorState navigator, {String? resume}) {
    sessions.add(resume);
    return Future.value();
  }

  @override
  Future<bool> requestConsent(NavigatorState navigator) {
    consentRequests++;
    return Future.value(consentGiven);
  }
}
