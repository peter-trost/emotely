import 'package:emotely/contract/contract.dart';
import 'package:emotely/main.dart';
import 'package:emotely/session/view/entry_view.dart';
import 'package:emotely/session/view/session_page.dart';
import 'package:emotely/session/widgets/longtext_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/helpers.dart';
import '../session_robot.dart';

void main() {
  group(SessionPage, () {
    testWidgets('shows a thinking state until the agent asks', (tester) async {
      final agent = AgentStub()
        ..script([
          delayed(awaiting(toolCallId: 'c1', question: SessionRobot.rate)),
        ]);
      final robot = SessionRobot(tester, agent);

      await robot.launch();

      expect(robot.thinking, findsOneWidget);
      expect(agent.requests, hasLength(1));
      expect(agent.lastRequest, isEmpty);

      await robot.settle();

      expect(robot.thinking, findsNothing);
      expect(find.text('Question 1'), findsOneWidget);
      expect(robot.questionText, 'How would you rate your day?');
      expect(robot.answerInput, findsOneWidget);
    });

    testWidgets('walks a whole session and shows the entry', (tester) async {
      final agent = AgentStub()
        ..script([
          awaiting(toolCallId: 'c1', question: SessionRobot.rate),
          awaiting(
            toolCallId: 'c2',
            question: SessionRobot.grateful,
            transcript: const ['round', 'round'],
            signature: 'sig-2',
          ),
          awaiting(toolCallId: 'c3', question: SessionRobot.best),
          completed(
            summary: 'A 7 kind of day, grateful for two things.',
            answers: const {
              'q-rate': Answer.rating(7),
              'q-grateful': Answer.textList(['my wife', 'Flutter']),
              'q-best': Answer.longtext('Shipping the session screen.'),
            },
          ),
        ]);
      final robot = SessionRobot(tester, agent);
      await robot.launch();
      await robot.settle();

      await robot.answerRating(7);

      expect(robot.lastAnsweredToolCall, 'c1');
      expect(robot.lastPostedValue, 7);
      expect(agent.lastRequest['transcript'], ['round']);
      expect(agent.lastRequest['signature'], 'sig');
      expect(find.text('Question 2'), findsOneWidget);
      expect(robot.questionText, 'What are you grateful for?');

      await robot.answerTextList(['my wife', 'Flutter']);

      expect(robot.lastAnsweredToolCall, 'c2');
      expect(robot.lastPostedValue, ['my wife', 'Flutter']);
      expect(agent.lastRequest['transcript'], ['round', 'round']);
      expect(agent.lastRequest['signature'], 'sig-2');
      expect(find.text('Question 3'), findsOneWidget);

      await robot.answerLongtext('Shipping the session screen.');

      expect(robot.lastPostedValue, 'Shipping the session screen.');
      expect(robot.summary, findsOneWidget);
      expect(
        find.text('A 7 kind of day, grateful for two things.'),
        findsOneWidget,
      );
      expect(find.text('How would you rate your day?'), findsOneWidget);
      expect(find.text('7 / 10'), findsOneWidget);
      expect(find.text('• my wife\n• Flutter'), findsOneWidget);
      expect(find.text('Shipping the session screen.'), findsOneWidget);
    });

    testWidgets('posts wire values, never Dart objects', (tester) async {
      // Colors are the one type whose Dart value is not its JSON value; the
      // request body must be encodable, and the agent must see #RRGGBB.
      final agent = AgentStub()
        ..script([
          awaiting(toolCallId: 'c1', question: SessionRobot.colors),
          awaiting(toolCallId: 'c2', question: SessionRobot.rate),
        ]);
      final robot = SessionRobot(tester, agent);
      await robot.launch();
      await robot.settle();

      await robot.answerColor('teal');

      expect(robot.lastPostedValue, ['#00897B']);
      expect(robot.questionText, 'How would you rate your day?');
    });

    testWidgets('a new question never inherits the previous draft', (
      tester,
    ) async {
      final agent = AgentStub()
        ..script([
          awaiting(toolCallId: 'c1', question: SessionRobot.best),
          awaiting(
            toolCallId: 'c2',
            question: SessionRobot.best.copyWith(
              questionId: 'q-worst',
              question: 'And the worst?',
            ),
          ),
        ]);
      final robot = SessionRobot(tester, agent);
      await robot.launch();
      await robot.settle();

      await robot.answerLongtext('The best.');

      expect(robot.questionText, 'And the worst?');
      expect(find.text('The best.'), findsNothing);
      expect(isSubmitEnabled(tester, LongtextInput.submitKey), isFalse);
    });

    testWidgets('shows the server message and retries the same round', (
      tester,
    ) async {
      final agent = AgentStub()
        ..script([
          awaiting(toolCallId: 'c1', question: SessionRobot.rate),
          refused(429, 'rate limited'),
          awaiting(toolCallId: 'c2', question: SessionRobot.grateful),
        ]);
      final robot = SessionRobot(tester, agent);
      await robot.launch();
      await robot.settle();

      await robot.answerRating(5);

      expect(find.text('rate limited'), findsOneWidget);
      expect(robot.retry, findsOneWidget);

      await robot.tapRetry();

      expect(agent.requests, hasLength(3));
      expect(agent.requests[2], agent.requests[1]);
      expect(robot.questionText, 'What are you grateful for?');
    });

    testWidgets('a network failure gets a generic message', (tester) async {
      final agent = AgentStub()..script([unreachable()]);
      final robot = SessionRobot(tester, agent);
      await robot.launch();
      await robot.settle();

      expect(
        find.text('Could not reach the journaling assistant.'),
        findsOneWidget,
      );
      expect(robot.retry, findsOneWidget);
    });

    testWidgets('renders every answer type in the entry', (tester) async {
      final agent = AgentStub()
        ..script([
          completed(
            summary: 'Colorful.',
            answers: const {
              'q-color': Answer.color([Color(0xFFFF8800), Color(0xFF00AAFF)]),
              'q-emoji': Answer.emoji(['😊', '🙏']),
            },
          ),
        ]);
      final robot = SessionRobot(tester, agent);
      await robot.launch();
      await robot.settle();

      // Questions the agent never asked in this (scripted) session fall back
      // to their id.
      expect(find.text('q-color'), findsOneWidget);
      expect(find.text('😊 🙏'), findsOneWidget);
      expect(find.byType(AnswerText), findsNWidgets(2));
      expect(find.bySemanticsLabel('#FF8800 #00AAFF'), findsOneWidget);
    });

    group('analytics', () {
      testWidgets('narrates the session with ids, types and counts only', (
        tester,
      ) async {
        final agent = AgentStub()
          ..script([
            awaiting(toolCallId: 'c1', question: SessionRobot.rate),
            awaiting(toolCallId: 'c2', question: SessionRobot.best),
            completed(
              summary: 'Done.',
              answers: const {
                'q-rate': Answer.rating(7),
                'q-best': Answer.longtext('Shipping.'),
              },
            ),
          ]);
        final robot = SessionRobot(tester, agent);
        await robot.launch();
        await robot.settle();
        await robot.answerRating(7);
        await robot.answerLongtext('Shipping.');

        expect(robot.analytics.events, [
          event('session_started'),
          event('question_asked', {
            'question_id': 'q-rate',
            'answer_type': 'rating',
            'index': 0,
          }),
          event('answer_submitted', {
            'question_id': 'q-rate',
            'answer_type': 'rating',
          }),
          event('question_asked', {
            'question_id': 'q-best',
            'answer_type': 'longtext',
            'index': 1,
          }),
          event('answer_submitted', {
            'question_id': 'q-best',
            'answer_type': 'longtext',
          }),
          event('session_completed', {'answers': 2}),
        ]);
      });

      testWidgets('never lets journal content leave the device', (
        tester,
      ) async {
        // Needles in every place content can appear: question text, the
        // typed answer, the agent's summary and the recorded answers.
        const needle = 'NEEDLE';
        final agent = AgentStub()
          ..script([
            awaiting(
              toolCallId: 'c1',
              question: SessionRobot.best.copyWith(
                question: 'What was the $needle-best thing?',
              ),
            ),
            completed(
              summary: 'A $needle day.',
              answers: const {'q-best': Answer.longtext('$needle answer')},
            ),
          ]);
        final robot = SessionRobot(tester, agent);
        await robot.launch();
        await robot.settle();
        await robot.answerLongtext('$needle answer');

        expect(robot.summary, findsOneWidget);
        expect(robot.analytics.events, hasLength(4));
        for (final outgoing in robot.analytics.outgoingStrings) {
          expect(outgoing, isNot(contains(needle)));
        }
      });

      testWidgets('reports failures with the status code and retries', (
        tester,
      ) async {
        final agent = AgentStub()
          ..script([
            refused(429, 'rate limited'),
            unreachable(),
            awaiting(toolCallId: 'c1', question: SessionRobot.rate),
          ]);
        final robot = SessionRobot(tester, agent);
        await robot.launch();
        await robot.settle();
        await robot.tapRetry();
        await robot.tapRetry();

        expect(robot.analytics.events, [
          event('session_started'),
          event('session_failed', {'status_code': 429}),
          event('session_retried'),
          event('session_failed'),
          event('session_retried'),
          event('question_asked', {
            'question_id': 'q-rate',
            'answer_type': 'rating',
            'index': 0,
          }),
        ]);
      });
    });

    group('meets accessibility guidelines', () {
      testWidgets('while asking', (tester) async {
        final agent = AgentStub()
          ..script([awaiting(toolCallId: 'c1', question: SessionRobot.rate)]);

        await tester.expectMeetsAccessibilityGuidelines(
          EmotelyApp(
            agentClient: agent.agentClient,
            analytics: AnalyticsSpy().analytics,
          ),
        );
      });

      testWidgets('on the entry', (tester) async {
        final agent = AgentStub()
          ..script([
            completed(
              summary: 'Done.',
              answers: const {'q-rate': Answer.rating(9)},
            ),
          ]);

        await tester.expectMeetsAccessibilityGuidelines(
          EmotelyApp(
            agentClient: agent.agentClient,
            analytics: AnalyticsSpy().analytics,
          ),
        );
      });

      testWidgets('on failure', (tester) async {
        final agent = AgentStub()..script([refused(500, 'boom')]);

        await tester.expectMeetsAccessibilityGuidelines(
          EmotelyApp(
            agentClient: agent.agentClient,
            analytics: AnalyticsSpy().analytics,
          ),
        );
      });
    });
  });
}
