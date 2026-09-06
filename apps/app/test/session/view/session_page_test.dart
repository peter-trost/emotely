import 'package:emotely/contract/contract.dart';
import 'package:emotely/main.dart';
import 'package:emotely/session/agent/agent_client.dart';
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
      expect(robot.questionText, SessionRobot.rate.question);
      expect(robot.answerInput, findsOneWidget);
    });

    testWidgets('walks a whole session and shows the entry', (tester) async {
      const secondTranscript = <Object?>['round', 'round'];
      const secondSignature = 'sig-2';
      const rating = 7;
      const gratefulFor = ['my wife', 'Flutter'];
      const bestThing = 'Shipping the session screen.';
      const summary = 'A 7 kind of day, grateful for two things.';
      final agent = AgentStub()
        ..script([
          awaiting(toolCallId: 'c1', question: SessionRobot.rate),
          awaiting(
            toolCallId: 'c2',
            question: SessionRobot.grateful,
            transcript: secondTranscript,
            signature: secondSignature,
          ),
          awaiting(toolCallId: 'c3', question: SessionRobot.best),
          completed(
            summary: summary,
            answers: {
              SessionRobot.rate.questionId: const Answer.rating(rating),
              SessionRobot.grateful.questionId: const Answer.textList(
                gratefulFor,
              ),
              SessionRobot.best.questionId: const Answer.longtext(bestThing),
            },
          ),
        ]);
      final robot = SessionRobot(tester, agent);
      await robot.launch();
      await robot.settle();

      await robot.answerRating(rating);

      expect(robot.lastAnsweredToolCall, 'c1');
      expect(robot.lastPostedValue, rating);
      expect(agent.lastRequest['transcript'], AgentStub.transcript);
      expect(agent.lastRequest['signature'], AgentStub.signature);
      expect(find.text('Question 2'), findsOneWidget);
      expect(robot.questionText, SessionRobot.grateful.question);

      await robot.answerTextList(gratefulFor);

      expect(robot.lastAnsweredToolCall, 'c2');
      expect(robot.lastPostedValue, gratefulFor);
      expect(agent.lastRequest['transcript'], secondTranscript);
      expect(agent.lastRequest['signature'], secondSignature);
      expect(find.text('Question 3'), findsOneWidget);

      await robot.answerLongtext(bestThing);

      expect(robot.lastPostedValue, bestThing);
      expect(robot.summary, findsOneWidget);
      expect(find.text(summary), findsOneWidget);
      expect(find.text(SessionRobot.rate.question), findsOneWidget);
      expect(find.text('$rating / 10'), findsOneWidget);
      expect(
        find.text(gratefulFor.map((v) => '• $v').join('\n')),
        findsOneWidget,
      );
      expect(find.text(bestThing), findsOneWidget);
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
      expect(robot.questionText, SessionRobot.rate.question);
    });

    testWidgets('a new question never inherits the previous draft', (
      tester,
    ) async {
      const draft = 'The best.';
      final worst = SessionRobot.best.copyWith(
        questionId: 'q-worst',
        question: 'And the worst?',
      );
      final agent = AgentStub()
        ..script([
          awaiting(toolCallId: 'c1', question: SessionRobot.best),
          awaiting(toolCallId: 'c2', question: worst),
        ]);
      final robot = SessionRobot(tester, agent);
      await robot.launch();
      await robot.settle();

      await robot.answerLongtext(draft);

      expect(robot.questionText, worst.question);
      expect(find.text(draft), findsNothing);
      expect(isSubmitEnabled(tester, LongtextInput.submitKey), isFalse);
    });

    testWidgets('shows the server message and retries the same round', (
      tester,
    ) async {
      const serverMessage = 'rate limited';
      final agent = AgentStub()
        ..script([
          awaiting(toolCallId: 'c1', question: SessionRobot.rate),
          refused(429, serverMessage),
          awaiting(toolCallId: 'c2', question: SessionRobot.grateful),
        ]);
      final robot = SessionRobot(tester, agent);
      await robot.launch();
      await robot.settle();

      await robot.answerRating(5);

      expect(find.text(serverMessage), findsOneWidget);
      expect(robot.retry, findsOneWidget);

      await robot.tapRetry();

      expect(agent.requests, hasLength(3));
      expect(agent.requests[2], agent.requests[1]);
      expect(robot.questionText, SessionRobot.grateful.question);
    });

    testWidgets('a network failure gets a generic message', (tester) async {
      final agent = AgentStub()..script([unreachable()]);
      final robot = SessionRobot(tester, agent);
      await robot.launch();
      await robot.settle();

      expect(find.text(SessionRobot.unreachableMessage), findsOneWidget);
      expect(robot.retry, findsOneWidget);
    });

    testWidgets('a hung round times out into the generic failure', (
      tester,
    ) async {
      final agent = AgentStub()
        ..script([
          delayed(
            awaiting(toolCallId: 'c1', question: SessionRobot.rate),
            AgentClient.defaultTimeout + const Duration(seconds: 1),
          ),
        ]);
      final robot = SessionRobot(tester, agent);
      await robot.launch();
      await robot.settle();

      expect(find.text(SessionRobot.unreachableMessage), findsOneWidget);
      expect(robot.retry, findsOneWidget);

      // Let the stub's late response fire; the client already gave up on it.
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('renders every answer type in the entry', (tester) async {
      const colors = [Color(0xFFFF8800), Color(0xFF00AAFF)];
      const emoji = ['😊', '🙏'];
      final agent = AgentStub()
        ..script([
          completed(
            summary: 'Colorful.',
            answers: const {
              'q-color': Answer.color(colors),
              'q-emoji': Answer.emoji(emoji),
            },
          ),
        ]);
      final robot = SessionRobot(tester, agent);
      await robot.launch();
      await robot.settle();

      // Questions the agent never asked in this (scripted) session fall back
      // to their id.
      expect(find.text('q-color'), findsOneWidget);
      expect(find.text(emoji.join(' ')), findsOneWidget);
      expect(find.byType(AnswerText), findsNWidgets(2));
      expect(find.bySemanticsLabel('#FF8800 #00AAFF'), findsOneWidget);
    });

    group('meets accessibility guidelines', () {
      testWidgets('while asking', (tester) async {
        final agent = AgentStub()
          ..script([awaiting(toolCallId: 'c1', question: SessionRobot.rate)]);

        await tester.expectMeetsAccessibilityGuidelines(
          EmotelyApp(agentClient: agent.agentClient),
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
          EmotelyApp(agentClient: agent.agentClient),
        );
      });

      testWidgets('on failure', (tester) async {
        final agent = AgentStub()..script([refused(500, 'boom')]);

        await tester.expectMeetsAccessibilityGuidelines(
          EmotelyApp(agentClient: agent.agentClient),
        );
      });
    });
  });
}
