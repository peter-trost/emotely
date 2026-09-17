import 'package:posthog_flutter/posthog_flutter.dart';

/// Journal analytics, content-free by construction (ADR 0005): counts and
/// flags only, never a summary or an answer.
class const JournalAnalytics({required final Posthog posthog}) {
  /// The journal was shown with [entries] entries and, if [openSession], a
  /// session to continue.
  Future<void> journalViewed({
    required int entries,
    required bool openSession,
  }) => posthog.capture(
    eventName: 'journal_viewed',
    properties: {'entries': entries, 'open_session': openSession},
  );

  /// The user opened a filed entry.
  Future<void> entryOpened() => posthog.capture(eventName: 'entry_opened');

  /// The user dropped an unfinished session.
  Future<void> sessionDiscarded() =>
      posthog.capture(eventName: 'session_discarded');
}
