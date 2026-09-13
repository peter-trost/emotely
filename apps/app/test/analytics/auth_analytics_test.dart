import 'package:emotely/analytics/auth_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/sign_in_robot.dart';
import '../helpers/helpers.dart';

void main() {
  group(AuthAnalytics, () {
    test('identifies the user by id and reports sign-in milestones', () async {
      final spy = AnalyticsSpy();
      final analytics = spy.authAnalytics;

      await analytics.codeRequested();
      await analytics.codeRequestFailed();
      await analytics.codeRejected();
      await analytics.identify(userId: 'user-1');
      await analytics.signedIn();
      await analytics.signedOut();
      await analytics.accountDeleted();

      expect(spy.identified, ['user-1']);
      expect(spy.events, [
        event('sign_in_code_requested'),
        event('sign_in_code_request_failed'),
        event('sign_in_code_rejected'),
        event('signed_in'),
        event('signed_out'),
        event('account_deleted'),
      ]);
      // Signing out and deleting the account each make PostHog forget.
      expect(spy.resets, 2);
    });

    testWidgets('never sends the email or the code (ADR 0005)', (tester) async {
      const needleEmail = 'needle.person@example.com';
      const needleCode = '918273';
      // GoTrue quotes the address in a 4xx message and, for a 5xx, gotrue
      // keeps the whole body; a wrong code comes back in the refusal too.
      // Every reported exception is among what leaves; the last try of
      // each step goes through.
      final supabase = SupabaseStub()
        ..script(
          otp: [
            authRefused(
              statusCode: 400,
              errorCode: 'validation_failed',
              message: 'Unable to validate email address: $needleEmail',
            ),
            authRefused(
              statusCode: 500,
              errorCode: 'unexpected_failure',
              message: 'Error sending magic link email to $needleEmail',
            ),
            codeSent(),
          ],
          verify: [
            authRefused(
              statusCode: 403,
              errorCode: 'otp_expired',
              message: 'Token $needleCode has expired or is invalid',
            ),
            sessionGranted(),
          ],
        );
      final agent = AgentStub()..script([unreachable()]);
      final robot = SignInRobot(tester, supabase: supabase, agent: agent);
      await robot.launch();

      await robot.requestCode(needleEmail);
      await robot.requestCode(needleEmail);
      await robot.requestCode(needleEmail);
      await robot.enterCode(needleCode);
      await robot.tapSignIn();
      await robot.settle();
      await robot.tapSignIn();
      await robot.settle();

      expect(robot.home, findsOneWidget);
      expect(robot.analytics.exceptions, [
        captured(
          withheld(
            AuthApiException,
            code: 'validation_failed',
            statusCode: '400',
          ),
          {'step': 'sign_in_code_request'},
        ),
        captured(withheld(AuthRetryableFetchException, statusCode: '500'), {
          'step': 'sign_in_code_request',
        }),
        captured(
          withheld(AuthApiException, code: 'otp_expired', statusCode: '403'),
          {'step': 'sign_in_code_verify'},
        ),
      ]);
      final outgoing = robot.analytics.outgoingStrings.toList();
      expect(outgoing, isNotEmpty);
      for (final leaving in outgoing) {
        expect(leaving, isNot(contains(needleEmail)));
        expect(leaving, isNot(contains('needle')));
        expect(leaving, isNot(contains(needleCode)));
      }
      expect(robot.analytics.identified, [SupabaseStub.userId]);
    });
  });
}
