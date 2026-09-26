import 'package:analytics/analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:testing/testing.dart';

void main() {
  group('registerAnalytics', () {
    test('registers every builder over the one PostHog instance', () async {
      final getIt = GetIt.asNewInstance();
      final spy = AnalyticsSpy();

      registerAnalytics(getIt, posthog: spy.posthog, consentVersion: 'v1');

      await getIt<SessionAnalytics>().sessionStarted();
      await getIt<AuthAnalytics>().signedIn(SignInMethod.code);
      await getIt<JournalAnalytics>().entryOpened();
      await getIt<ConsentAnalytics>().consentDeclined();
      await getIt<ErrorReporter>().consentLoadFailed(
        Exception('x'),
        StackTrace.empty,
      );

      expect(spy.events, [
        event('session_started'),
        event('signed_in', {'method': 'code'}),
        event('entry_opened'),
        event('consent_declined', {'version': 'v1'}),
      ]);
      expect(spy.exceptions, hasLength(1));
    });

    test('registers each builder once, as a singleton', () {
      final getIt = GetIt.asNewInstance();
      registerAnalytics(
        getIt,
        posthog: AnalyticsSpy().posthog,
        consentVersion: 'v1',
      );

      expect(getIt<SessionAnalytics>(), same(getIt<SessionAnalytics>()));
      expect(getIt<ErrorReporter>(), same(getIt<ErrorReporter>()));
    });
  });
}
