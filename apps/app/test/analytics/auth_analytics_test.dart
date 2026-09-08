import 'package:emotely/analytics/auth_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

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

      expect(spy.identified, ['user-1']);
      expect(spy.events, [
        event('sign_in_code_requested'),
        event('sign_in_code_request_failed'),
        event('sign_in_code_rejected'),
        event('signed_in'),
      ]);
    });

    testWidgets('never sends the email or the code (ADR 0005)', (tester) async {
      const needleEmail = 'needle.person@example.com';
      const needleCode = '918273';
      final supabase = SupabaseStub()
        ..script(otp: [codeSent()], verify: [sessionGranted()]);
      final agent = AgentStub()..script([unreachable()]);
      final robot = SignInRobot(tester, supabase: supabase, agent: agent);
      await robot.launch();

      await robot.requestCode(needleEmail);
      await robot.enterCode(needleCode);
      await robot.tapSignIn();
      await robot.settle();

      expect(robot.session, findsOneWidget);
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
