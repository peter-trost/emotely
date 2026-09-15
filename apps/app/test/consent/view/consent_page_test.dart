import 'package:emotely/consent/consent_text.dart';
import 'package:emotely/consent/view/consent_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/helpers.dart';
import '../../session/session_robot.dart';
import '../consent_robot.dart';

void main() {
  group(ConsentPage, () {
    const journalViewed = {'entries': 0, 'open_session': false};
    const version = {'version': consentVersion};

    /// A Supabase that answers the consent read with [consents], and accepts
    /// whatever the screen writes unless a test scripts otherwise. The agent
    /// has one question ready, so a session that does start is visibly a
    /// session rather than a spinner.
    ConsentRobot robotWith(
      WidgetTester tester, {
      List<Map<String, Object?>> consents = const [],
      List<AuthRound> grants = const [],
      List<AuthRound> withdrawals = const [],
      List<AuthRound> reads = const [],
    }) {
      // Scripted rounds beat the harness's defaults, which grant consent so
      // that tests about other things are not about this one. [reads]
      // replaces the read entirely, for the tests about a read that fails.
      final supabase = SupabaseStub()
        ..rest(consentRead, reads.isEmpty ? [rows(consents)] : reads)
        ..rest(consentGrant, grants)
        ..rest(consentWithdraw, withdrawals);
      final agent = AgentStub()
        ..script([awaiting(toolCallId: 'c1', question: SessionRobot.rate)]);
      return ConsentRobot(tester, supabase: supabase, agent: agent);
    }

    testWidgets('asks before the first session and starts it once given', (
      tester,
    ) async {
      final robot = robotWith(tester);
      await robot.launch();

      // Nothing has been sent, and nothing is asked until a session is.
      expect(robot.consent, findsNothing);
      expect(robot.supabase.to(consentGrant), isEmpty);

      await robot.startSession();

      // The gate, not the session.
      expect(robot.consent, findsOneWidget);
      expect(robot.session, findsNothing);
      expect(find.text(consentTitle), findsOneWidget);

      // The box starts unticked, and until it is ticked the button cannot
      // be pressed at all: no pre-ticked box, and no "by continuing".
      expect(tester.widget<CheckboxListTile>(robot.checkbox).value, isFalse);
      expect(tester.widget<FilledButton>(robot.agree).enabled, isFalse);
      expect(robot.supabase.to(consentGrant), isEmpty);
      expect(robot.session, findsNothing);

      await robot.consentAndContinue();

      // Recorded server-side, naming the wording that was agreed to, and
      // only then does the session begin.
      expect(robot.supabase.to(consentGrant), hasLength(1));
      expect(robot.supabase.bodies('/rest/v1/rpc/record_consent'), [
        {'version': consentVersion},
      ]);
      expect(robot.session, findsOneWidget);
      expect(robot.consent, findsNothing);
      expect(robot.analytics.events, [
        event('journal_viewed', journalViewed),
        event('consent_granted', version),
        ...robot.analytics.events.skip(2),
      ]);
    });

    testWidgets('does not ask again once consent stands', (tester) async {
      final robot = robotWith(tester, consents: [consentRow()]);
      await robot.launch();

      await robot.startSession();

      // Straight into the session: the record is what decides, and it was
      // read from the server at launch.
      expect(robot.consent, findsNothing);
      expect(robot.session, findsOneWidget);
      expect(robot.supabase.to(consentGrant), isEmpty);
    });

    testWidgets(
      'a consent read at launch survives a restart, not a local flag',
      (tester) async {
        final robot = robotWith(tester, consents: [consentRow()]);
        await robot.launch();

        // The gate is answered from the server on every launch, so a fresh
        // install of the app asks the same question of the same record.
        expect(robot.supabase.to(consentRead), hasLength(1));
        final read = robot.supabase.to(consentRead).single;
        expect(read.query['version'], 'eq.$consentVersion');
        expect(read.query['select'], 'withdrawn_at');

        await robot.startSession();

        expect(robot.session, findsOneWidget);
      },
    );

    testWidgets('a withdrawn consent is asked for again', (tester) async {
      final robot = robotWith(
        tester,
        consents: [consentRow(withdrawnAt: '2026-09-15T10:00:00+00:00')],
      );
      await robot.launch();

      await robot.startSession();

      // Withdrawn reads the same as never given: ask before sending
      // anything, rather than treating an old row as a standing yes.
      expect(robot.consent, findsOneWidget);
      expect(robot.session, findsNothing);
    });

    testWidgets('continuing an unfinished session is gated too', (
      tester,
    ) async {
      // A session begun before consent was withdrawn (or before this
      // shipped) still sends its transcript to the model when it resumes,
      // so resuming asks the same question as starting.
      final robot = robotWith(tester);
      robot.supabase.rest('GET /rest/v1/sessions', [
        rows([
          sessionRow(questions: [SessionRobot.rate]),
        ]),
      ]);
      await robot.launch();

      await robot.tap(robot.continueSession);

      expect(robot.consent, findsOneWidget);
      expect(robot.session, findsNothing);
    });

    testWidgets('declining starts nothing and leaves the journal usable', (
      tester,
    ) async {
      final robot = robotWith(tester);
      await robot.launch();
      await robot.startSession();

      await robot.tap(robot.decline);

      // Nothing recorded, nothing sent, and the journal is still there.
      expect(robot.supabase.to(consentGrant), isEmpty);
      expect(robot.session, findsNothing);
      expect(robot.consent, findsNothing);
      expect(robot.home, findsOneWidget);
      expect(robot.start, findsOneWidget);
      expect(robot.declined, findsOneWidget);
      expect(robot.analytics.events, [
        event('journal_viewed', journalViewed),
        event('consent_declined', version),
      ]);

      // And the question can be answered differently a moment later.
      await robot.startSession();

      expect(robot.consent, findsOneWidget);
    });

    testWidgets('leaving the gate by the back arrow starts nothing', (
      tester,
    ) async {
      final robot = robotWith(tester);
      await robot.launch();
      await robot.startSession();

      // Dismissing the route is not an answer, and certainly not a yes.
      await robot.back();

      expect(robot.home, findsOneWidget);
      expect(robot.session, findsNothing);
      expect(robot.supabase.to(consentGrant), isEmpty);

      // Nothing is left half-set: asking again is a clean question.
      await robot.startSession();

      expect(robot.consent, findsOneWidget);
      expect(tester.widget<CheckboxListTile>(robot.checkbox).value, isFalse);
    });

    testWidgets('a consent that cannot be recorded starts no session', (
      tester,
    ) async {
      final robot = robotWith(tester, grants: [restRefused()]);
      await robot.launch();
      await robot.startSession();

      await robot.consentAndContinue();

      // The write failed, so the gate stays shut: a session must never run
      // on a consent the server has no record of.
      expect(robot.session, findsNothing);
      expect(robot.consent, findsOneWidget);
      expect(robot.consentFailure, findsOneWidget);
      expect(
        robot.analytics.events,
        isNot(contains(event('consent_granted', version))),
      );

      // The retry is the same act, and it lands this time.
      await robot.tap(robot.retry);

      expect(robot.supabase.to(consentGrant), hasLength(2));
      expect(robot.session, findsOneWidget);
    });

    testWidgets('a double tap records one consent and starts one session', (
      tester,
    ) async {
      final robot = robotWith(tester, grants: [delayedAuth(rpcReturned(null))]);
      await robot.launch();
      await robot.startSession();
      await robot.tap(robot.checkbox);

      await tester.tap(robot.agree);
      await tester.pump();

      // While the write is in flight the button is gone — the screen shows
      // progress — so a second tap has nothing to hit and cannot write a
      // second consent. The bloc refuses one anyway if it ever did.
      expect(robot.agree, findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await robot.settle();

      expect(robot.supabase.to(consentGrant), hasLength(1));
      expect(robot.session, findsOneWidget);
      expect(robot.analytics.events, [
        event('journal_viewed', journalViewed),
        event('consent_granted', version),
        ...robot.analytics.events.skip(2),
      ]);
    });

    testWidgets('a consent that cannot be read starts no session', (
      tester,
    ) async {
      final robot = robotWith(tester, reads: [restRefused()]);
      await robot.launch();

      await robot.startSession();

      // Not knowing is not the same as knowing the user consented: the gate
      // asks rather than assuming either way.
      expect(robot.session, findsNothing);
      expect(robot.consent, findsOneWidget);
      // The failure is reported, content-free, as its own step.
      expect(robot.analytics.exceptions, hasLength(1));
      expect(robot.analytics.exceptions.single.properties, {
        'step': 'consent_load',
      });
    });

    testWidgets('declining after a failed write still starts nothing', (
      tester,
    ) async {
      final robot = robotWith(tester, grants: [restRefused()]);
      await robot.launch();
      await robot.startSession();
      await robot.consentAndContinue();

      expect(robot.consentFailure, findsOneWidget);

      await robot.tap(robot.decline);

      // Out of the gate without a session and without a record.
      expect(robot.home, findsOneWidget);
      expect(robot.session, findsNothing);
      expect(robot.declined, findsOneWidget);
    });

    testWidgets('the notice is a link the screen can open', (tester) async {
      final launcher = UrlLauncherSpy.setup();
      final robot = robotWith(tester);
      await robot.launch();
      await robot.startSession();

      await robot.tap(robot.notice);

      expect(launcher.launched, [privacyNoticeUrl]);
      // Reading the notice is not consenting to it.
      expect(robot.supabase.to(consentGrant), isEmpty);
      expect(robot.consent, findsOneWidget);
    });

    testWidgets('says what is sent, to whom, and under which basis', (
      tester,
    ) async {
      final robot = robotWith(tester);
      await robot.launch();
      await robot.startSession();

      // The three things Art. 9 (2) (a) needs an explicit consent to be
      // informed about, in the app's own words.
      expect(find.text(consentRecipients), findsOneWidget);
      expect(find.text(consentSensitivity), findsOneWidget);
      expect(find.text(consentLegalBasis), findsOneWidget);
      expect(find.text(consentCheckboxLabel), findsOneWidget);
    });

    testWidgets('never lets journal content leave the device (ADR 0005)', (
      tester,
    ) async {
      final robot = robotWith(tester);
      await robot.launch();
      await robot.startSession();
      await robot.consentAndContinue();

      // The consent events carry a version and nothing else; no wording of
      // the notice and nothing the user wrote ever reaches PostHog.
      for (final outgoing in robot.analytics.outgoingStrings) {
        expect(outgoing, isNot(contains(consentRecipients)));
        expect(outgoing, isNot(contains(consentCheckboxLabel)));
        expect(outgoing, isNot(contains(consentSensitivity)));
      }
      expect(robot.analytics.events, [
        event('journal_viewed', journalViewed),
        event('consent_granted', version),
        ...robot.analytics.events.skip(2),
      ]);
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      final robot = robotWith(tester);
      await robot.supabase.signedIn();

      await tester.expectMeetsAccessibilityGuidelines(
        robot.app,
        prepare: (tester) async {
          await robot.settle();
          await robot.startSession();
          // The box reachable and labelled, the button and the link too.
          await tester.ensureVisible(robot.checkbox);
          await robot.settle();
        },
      );
    });
  });
}
