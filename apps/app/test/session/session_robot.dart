import 'package:emotely/contract/contract.dart';
import 'package:emotely/main.dart';
import 'package:emotely/session/view/entry_view.dart';
import 'package:emotely/session/view/session_page.dart';
import 'package:emotely/session/widgets/answer_input.dart';
import 'package:emotely/session/widgets/color_input.dart';
import 'package:emotely/session/widgets/longtext_input.dart';
import 'package:emotely/session/widgets/rating_input.dart';
import 'package:emotely/session/widgets/text_list_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/helpers.dart';

/// Drives a journaling session through the real app against a scripted
/// agent. Finders are getters, actions settle, tests read as prose.
class SessionRobot(final WidgetTester tester, final AgentStub agent) {
  Finder get thinking => find.byType(CircularProgressIndicator);
  Finder get question => find.byKey(SessionView.questionKey);
  Finder get answerInput => find.byType(AnswerInput);
  Finder get summary => find.byKey(EntryView.summaryKey);
  Finder get retry => find.byKey(SessionView.retryKey);

  String get questionText => tester.widget<Text>(question).data!;

  /// Launches the app; the first round is in flight until [settle].
  Future<void> launch() async {
    await tester.pumpWidget(EmotelyApp(agentClient: agent.agentClient));
    await tester.pump();
  }

  Future<void> settle() => tester.pumpAndSettle();

  Future<void> answerRating(int value) async {
    await tester.tap(find.byKey(RatingInput.chipKey(value)));
    await tester.pump();
    await tapSubmit(tester, RatingInput.submitKey);
    await settle();
  }

  Future<void> answerLongtext(String text) async {
    await tester.enterText(find.byKey(LongtextInput.fieldKey), text);
    await tester.pump();
    await tapSubmit(tester, LongtextInput.submitKey);
    await settle();
  }

  Future<void> answerTextList(List<String> items) async {
    for (final item in items) {
      await tester.enterText(find.byKey(TextListInput.fieldKey), item);
      await tester.pump();
      await tester.tap(find.byKey(TextListInput.addKey));
      await tester.pump();
    }
    await tapSubmit(tester, TextListInput.submitKey);
    await settle();
  }

  Future<void> answerColor(String paletteName) async {
    await tester.tap(find.byKey(ColorInput.paletteKey(paletteName)));
    await tester.pump();
    await tapSubmit(tester, ColorInput.submitKey);
    await settle();
  }

  Future<void> tapRetry() async {
    await tester.tap(retry);
    await settle();
  }

  /// The answer value the app posted in its most recent round.
  Object? get lastPostedValue =>
      (agent.lastRequest['answer'] as Map<String, dynamic>)['value'];

  /// The tool call the app answered in its most recent round.
  String get lastAnsweredToolCall =>
      (agent.lastRequest['answer'] as Map<String, dynamic>)['toolCallId']
          as String;

  static const rate = AskQuestion(
    questionId: 'q-rate',
    question: 'How would you rate your day?',
    answerType: AnswerType.rating,
  );
  static const grateful = AskQuestion(
    questionId: 'q-grateful',
    question: 'What are you grateful for?',
    answerType: AnswerType.textList,
  );
  static const colors = AskQuestion(
    questionId: 'q-colors',
    question: 'Which colors were your day?',
    answerType: AnswerType.color,
  );
  static const best = AskQuestion(
    questionId: 'q-best',
    question: 'What was the best thing today?',
    answerType: AnswerType.longtext,
  );
}
