// The live-agent acceptance run: a whole journaling session on a device
// against the DEPLOYED agent, answering whatever the agent asks. Runs
// nightly / pre-release by hand — never per PR (see the write-tests skill):
//
//   flutter test integration_test -d <device> \
//     --dart-define=POSTHOG_KEY=phc_… [--dart-define=EMOTELY_AGENT_URL=…]
import 'package:emotely/analytics/session_analytics.dart';
import 'package:emotely/main.dart';
import 'package:emotely/session/agent/agent_client.dart';
import 'package:emotely/session/view/entry_view.dart';
import 'package:emotely/session/view/session_page.dart';
import 'package:emotely/session/widgets/color_input.dart';
import 'package:emotely/session/widgets/emoji_input.dart';
import 'package:emotely/session/widgets/longtext_input.dart';
import 'package:emotely/session/widgets/rating_input.dart';
import 'package:emotely/session/widgets/text_list_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('completes a full session against the deployed agent', (
    tester,
  ) async {
    await Posthog().setup(PostHogConfig(posthogKey)..host = posthogHost);
    final robot = LiveSessionRobot(tester);
    await robot.launch();

    const maxRounds = 15;
    var asked = 0;
    while (robot.summary.evaluate().isEmpty) {
      expect(asked, lessThan(maxRounds), reason: 'session did not complete');
      expect(robot.failure, findsNothing, reason: robot.failureMessage);
      await robot.answerCurrentQuestion();
      asked++;
    }

    expect(asked, greaterThanOrEqualTo(10));
    // The entry list is lazy, so count recorded answers, not rendered rows.
    final entry = tester.widget<EntryView>(find.byType(EntryView)).entry;
    expect(entry.answers, hasLength(greaterThanOrEqualTo(10)));
    expect(entry.summary, isNotEmpty);
    expect(find.byType(AnswerText), findsWidgets);
    await Posthog().flush();
  });
}

/// Answers whatever question is on screen with a plausible canned value.
class LiveSessionRobot(final WidgetTester tester) {
  Finder get summary => find.byKey(EntryView.summaryKey);
  Finder get failure => find.byKey(SessionView.retryKey);

  String? get failureMessage => failure.evaluate().isEmpty
      ? null
      : tester.widget<Text>(find.byType(Text).first).data;

  Future<void> launch() async {
    await tester.pumpWidget(
      EmotelyApp(
        agentClient: AgentClient(
          httpClient: http.Client(),
          endpoint: Uri.parse(agentUrl),
        ),
        analytics: SessionAnalytics(posthog: Posthog()),
      ),
    );
    await _settleRound();
  }

  Future<void> answerCurrentQuestion() async {
    if (find.byType(RatingInput).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(RatingInput.chipKey(8)));
      await tester.pump();
      await _submit(RatingInput.submitKey);
    } else if (find.byType(TextListInput).evaluate().isNotEmpty) {
      for (final item in ['the live smoke', 'green tests', 'cheap models']) {
        await tester.enterText(find.byKey(TextListInput.fieldKey), item);
        await tester.pump();
        await tester.tap(find.byKey(TextListInput.addKey));
        await tester.pump();
      }
      await _submit(TextListInput.submitKey);
    } else if (find.byType(LongtextInput).evaluate().isNotEmpty) {
      await tester.enterText(
        find.byKey(LongtextInput.fieldKey),
        'The session screen ran on a device against the deployed agent.',
      );
      await tester.pump();
      await _submit(LongtextInput.submitKey);
    } else if (find.byType(EmojiInput).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(EmojiInput.chipKey('🙏')));
      await tester.pump();
      await _submit(EmojiInput.submitKey);
    } else if (find.byType(ColorInput).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(ColorInput.paletteKey('teal')));
      await tester.pump();
      await _submit(ColorInput.submitKey);
    } else {
      fail('no answer widget on screen');
    }
    await _settleRound();
  }

  Future<void> _submit(Key key) async {
    await tester.tap(
      find.descendant(of: find.byKey(key), matching: find.byType(FilledButton)),
    );
    await tester.pump();
  }

  /// A round is a real model call; wait for the spinner to go away.
  Future<void> _settleRound() async {
    const step = Duration(milliseconds: 250);
    const limit = Duration(seconds: 60);
    var waited = Duration.zero;
    do {
      await tester.pump(step);
      waited += step;
    } while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty &&
        waited < limit);
    await tester.pumpAndSettle();
  }
}
