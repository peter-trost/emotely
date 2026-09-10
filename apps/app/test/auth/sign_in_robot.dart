import 'package:emotely/auth/view/sign_in_page.dart';
import 'package:emotely/journal/view/journal_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/helpers.dart';

/// Drives sign-in through the real app against a scripted Supabase. The
/// agent is scripted too, because a successful sign-in opens a session.
class SignInRobot(
  final WidgetTester tester, {
  required final SupabaseStub supabase,
  required final AgentStub agent,
}) {
  final analytics = AnalyticsSpy();

  Finder get signIn => find.byType(SignInPage);
  Finder get home => find.byType(JournalPage);
  Finder get emailField => find.byKey(SignInPage.emailKey);
  Finder get sendCode => find.byKey(SignInPage.sendCodeKey);
  Finder get codeField => find.byKey(SignInPage.codeKey);
  Finder get submitCode => find.byKey(SignInPage.signInKey);
  Finder get changeEmail => find.byKey(SignInPage.changeEmailKey);
  Finder get error => find.byKey(SignInPage.errorKey);
  Finder get busy => find.byType(CircularProgressIndicator);

  String get errorText => tester.widget<Text>(error).data!;

  bool get canSendCode =>
      tester.widget<FilledButton>(sendCode).onPressed != null;
  bool get canSubmitCode =>
      tester.widget<FilledButton>(submitCode).onPressed != null;

  Widget get app =>
      appUnderTest(agent: agent, supabase: supabase, analytics: analytics);

  Future<void> launch() async {
    await tester.pumpWidget(app);
    await tester.pump();
  }

  Future<void> settle() => tester.pumpAndSettle();

  Future<void> enterEmail(String email) async {
    await tester.enterText(emailField, email);
    await tester.pump();
  }

  Future<void> tapSendCode() async {
    await tester.tap(sendCode);
    await tester.pump();
  }

  Future<void> enterCode(String code) async {
    await tester.enterText(codeField, code);
    await tester.pump();
  }

  Future<void> tapSignIn() async {
    await tester.tap(submitCode);
    await tester.pump();
  }

  Future<void> tapChangeEmail() async {
    await tester.tap(changeEmail);
    await tester.pump();
  }

  /// The happy path up to the code step.
  Future<void> requestCode([String email = SupabaseStub.email]) async {
    await enterEmail(email);
    await tapSendCode();
    await settle();
  }
}
