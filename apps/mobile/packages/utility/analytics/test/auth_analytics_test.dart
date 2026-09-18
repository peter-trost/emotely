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
      await analytics.identify(userId: 'user-1');
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
