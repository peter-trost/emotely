import 'package:emotely/auth/bloc/auth_bloc.dart';
import 'package:emotely/auth/view/sign_in_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../helpers/helpers.dart';
import '../sign_in_robot.dart';

void main() {
  group(SignInPage, () {
    const code = '482913';

    testWidgets('asks for the email, then the code, then opens a session', (
      tester,
    ) async {
      final supabase = SupabaseStub()
        ..script(otp: [codeSent()], verify: [sessionGranted()]);
      final agent = AgentStub()..script([unreachable()]);
      final robot = SignInRobot(tester, supabase: supabase, agent: agent);
      await robot.launch();

      expect(robot.signIn, findsOneWidget);
      expect(robot.canSendCode, isFalse);

      await robot.enterEmail('not an email');
      expect(robot.canSendCode, isFalse);

      await robot.requestCode();

      expect(
        supabase.bodies('/auth/v1/otp').single['email'],
        SupabaseStub.email,
      );
      expect(robot.codeField, findsOneWidget);
      expect(find.textContaining(SupabaseStub.email), findsOneWidget);
      expect(robot.canSubmitCode, isFalse);

      await robot.enterCode('12');
      expect(robot.canSubmitCode, isFalse);
      await robot.enterCode(code);
      await robot.tapSignIn();
      await robot.settle();

      final verify = supabase.bodies('/auth/v1/verify').single;
      expect(verify['email'], SupabaseStub.email);
      expect(verify['token'], code);
      expect(verify['type'], 'email');
      expect(robot.session, findsOneWidget);
      expect(robot.signIn, findsNothing);
      expect(
        agent.lastHeaders['authorization'],
        'Bearer ${SupabaseStub.accessToken}',
      );
    });

    testWidgets('shows progress while Supabase answers', (tester) async {
      final supabase = SupabaseStub()
        ..script(
          otp: [delayedAuth(codeSent())],
          verify: [delayedAuth(sessionGranted())],
        );
      final agent = AgentStub()..script([unreachable()]);
      final robot = SignInRobot(tester, supabase: supabase, agent: agent);
      await robot.launch();

      await robot.enterEmail(SupabaseStub.email);
      await robot.tapSendCode();

      expect(robot.busy, findsOneWidget);
      expect(robot.sendCode, findsNothing);

      await robot.settle();

      expect(robot.busy, findsNothing);
      expect(robot.codeField, findsOneWidget);

      await robot.enterCode(code);
      await robot.tapSignIn();

      expect(robot.busy, findsOneWidget);
      expect(robot.submitCode, findsNothing);

      await robot.settle();

      expect(robot.session, findsOneWidget);
    });

    testWidgets('explains when Supabase refuses the email', (tester) async {
      final supabase = SupabaseStub()
        ..script(
          otp: [
            authRefused(
              statusCode: 400,
              errorCode: 'validation_failed',
              message: 'Unable to validate email address',
            ),
          ],
        );
      final robot = SignInRobot(tester, supabase: supabase, agent: AgentStub());
      await robot.launch();

      await robot.requestCode('nobody@example.invalid');

      expect(robot.emailField, findsOneWidget);
      expect(robot.errorText, SignInPage.couldNotSendMessage);
    });

    testWidgets('treats a code answer without a session as rejected', (
      tester,
    ) async {
      final supabase = SupabaseStub()
        ..script(otp: [codeSent()], verify: [sessionWithheld()]);
      final robot = SignInRobot(tester, supabase: supabase, agent: AgentStub());
      await robot.launch();
      await robot.requestCode();

      await robot.enterCode(code);
      await robot.tapSignIn();
      await robot.settle();

      expect(robot.codeField, findsOneWidget);
      expect(robot.errorText, SignInPage.wrongCodeMessage);
      expect(robot.analytics.events, [
        event('sign_in_code_requested'),
        event('sign_in_code_rejected'),
      ]);
    });

    testWidgets('explains when no more codes can be sent', (tester) async {
      final supabase = SupabaseStub()
        ..script(
          otp: [
            authRefused(
              statusCode: 429,
              errorCode: 'over_email_send_rate_limit',
              message: 'email rate limit exceeded',
            ),
          ],
        );
      final robot = SignInRobot(tester, supabase: supabase, agent: AgentStub());
      await robot.launch();

      await robot.requestCode();

      expect(robot.emailField, findsOneWidget);
      expect(robot.errorText, SignInPage.tooManyCodesMessage);
    });

    testWidgets('tells the user when Supabase is unreachable', (tester) async {
      final supabase = SupabaseStub()..script(otp: [authUnreachable()]);
      final robot = SignInRobot(tester, supabase: supabase, agent: AgentStub());
      await robot.launch();

      await robot.requestCode();

      expect(robot.errorText, SignInPage.unreachableMessage);
    });

    testWidgets('rejects a wrong code and lets the user try again', (
      tester,
    ) async {
      final supabase = SupabaseStub()
        ..script(
          otp: [codeSent()],
          verify: [
            authRefused(
              statusCode: 403,
              errorCode: 'otp_expired',
              message: 'Token has expired or is invalid',
            ),
            sessionGranted(),
          ],
        );
      final agent = AgentStub()..script([unreachable()]);
      final robot = SignInRobot(tester, supabase: supabase, agent: agent);
      await robot.launch();
      await robot.requestCode();

      await robot.enterCode('000000');
      await robot.tapSignIn();
      await robot.settle();

      expect(robot.codeField, findsOneWidget);
      expect(robot.errorText, SignInPage.wrongCodeMessage);

      await robot.enterCode(code);
      await robot.tapSignIn();
      await robot.settle();

      expect(robot.session, findsOneWidget);
    });

    testWidgets('lets the user go back and change the email', (tester) async {
      final supabase = SupabaseStub()..script(otp: [codeSent(), codeSent()]);
      final robot = SignInRobot(tester, supabase: supabase, agent: AgentStub());
      await robot.launch();
      await robot.requestCode('first@example.com');

      await robot.tapChangeEmail();

      expect(robot.emailField, findsOneWidget);
      expect(robot.error, findsNothing);

      await robot.requestCode('second@example.com');

      expect(supabase.bodies('/auth/v1/otp').map((b) => b['email']), [
        'first@example.com',
        'second@example.com',
      ]);
    });

    testWidgets('returns to sign-in when the session ends', (tester) async {
      final supabase = SupabaseStub()..script(logout: [signedOut()]);
      await supabase.signedIn();
      final agent = AgentStub()..script([unreachable()]);
      final robot = SignInRobot(tester, supabase: supabase, agent: agent);
      await robot.launch();
      await robot.settle();

      expect(robot.session, findsOneWidget);

      await supabase.supabase.auth.signOut();
      await robot.settle();

      expect(robot.signIn, findsOneWidget);
    });

    testWidgets('stays put when the SDK reports an auth error', (tester) async {
      final supabase = SupabaseStub()..script(logout: [signedOut()]);
      await supabase.signedIn();
      final agent = AgentStub()..script([unreachable()]);
      final robot = SignInRobot(tester, supabase: supabase, agent: agent);
      await robot.launch();
      await robot.settle();

      // A corrupt persisted session: the SDK signs out locally and reports
      // the error on its auth stream. The app must not crash on the report.
      await expectLater(
        supabase.supabase.auth.recoverSession('{}'),
        throwsA(isA<AuthException>()),
      );
      await robot.settle();

      expect(robot.signIn, findsOneWidget);
    });

    testWidgets('renders nothing once signed in; the root swaps the screen', (
      tester,
    ) async {
      final supabase = SupabaseStub();
      await supabase.signedIn();
      final spy = AnalyticsSpy();

      await tester.pumpWidget(
        BlocProvider(
          create: (_) => AuthBloc(
            supabase: supabase.supabase,
            analytics: spy.authAnalytics,
          ),
          child: const MaterialApp(home: SignInPage()),
        ),
      );

      expect(find.byType(TextField), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('meets accessibility guidelines on both steps', (tester) async {
      final supabase = SupabaseStub()..script(otp: [codeSent()]);
      final robot = SignInRobot(tester, supabase: supabase, agent: AgentStub());

      await tester.expectMeetsAccessibilityGuidelines(robot.app);
      await tester.expectMeetsAccessibilityGuidelines(
        robot.app,
        prepare: (tester) => robot.requestCode(),
      );
    });
  });
}
