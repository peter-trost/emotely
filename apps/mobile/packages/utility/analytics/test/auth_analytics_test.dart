import 'package:analytics/analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing/testing.dart';

void main() {
  group(AuthAnalytics, () {
    test('names every sign-in milestone, and the user only by id', () async {
      final spy = AnalyticsSpy();
      final analytics = spy.authAnalytics;

      await analytics.codeRequested();
      await analytics.codeRequestFailed();
      await analytics.codeRejected();
      await analytics.passwordFailed();
      await analytics.identify(userId: 'user-1', internal: false);
      await analytics.signedIn();

      expect(spy.identified, ['user-1']);
      expect(spy.events, [
        event('sign_in_code_requested'),
        event('sign_in_code_request_failed'),
        event('sign_in_code_rejected'),
        event('sign_in_password_failed'),
        event('signed_in'),
      ]);
    });

    test('flags the person internal or not, never by email', () async {
      final spy = AnalyticsSpy();
      final analytics = spy.authAnalytics;

      await analytics.identify(userId: 'user-1', internal: true);
      await analytics.identify(userId: 'user-2', internal: false);

      expect(spy.identities, [
        identity('user-1', {r'$internal_or_test_user': true}),
        identity('user-2', {r'$internal_or_test_user': false}),
      ]);
    });

    test("forgets the device's user on sign-out and on deletion", () async {
      final spy = AnalyticsSpy();
      final analytics = spy.authAnalytics;

      await analytics.signedOut();
      await analytics.accountDeleted();

      expect(spy.events, [event('signed_out'), event('account_deleted')]);
      expect(spy.resets, 2);
    });
  });
}
