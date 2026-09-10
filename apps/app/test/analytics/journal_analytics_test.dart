import 'package:emotely/analytics/journal_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/helpers.dart';

void main() {
  group(JournalAnalytics, () {
    test('reports the journal by counts and flags only', () async {
      final spy = AnalyticsSpy();
      final analytics = spy.journalAnalytics;

      await analytics.journalViewed(entries: 3, openSession: true);
      await analytics.entryOpened();
      await analytics.sessionDiscarded();

      expect(spy.events, [
        event('journal_viewed', {'entries': 3, 'open_session': true}),
        event('entry_opened'),
        event('session_discarded'),
      ]);
    });
  });
}
