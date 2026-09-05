import 'package:emotely/analytics/session_analytics.dart';
import 'package:emotely/contract/contract.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/helpers.dart';

void main() {
  group(SessionAnalytics, () {
    const question = AskQuestion(
      questionId: 'q-grateful',
      question: 'What are you grateful for? (never sent)',
      answerType: AnswerType.textList,
    );

    test('describes a question by id and type only', () async {
      final spy = AnalyticsSpy();

      await spy.analytics.questionAsked(question: question, index: 2);
      await spy.analytics.answerSubmitted(question: question);

      expect(spy.events, [
        event('question_asked', {
          'question_id': 'q-grateful',
          'answer_type': 'textList',
          'index': 2,
        }),
        event('answer_submitted', {
          'question_id': 'q-grateful',
          'answer_type': 'textList',
        }),
      ]);
    });

    test('reports session milestones with counts and codes', () async {
      final spy = AnalyticsSpy();
      final analytics = spy.analytics;

      await analytics.sessionStarted();
      await analytics.sessionCompleted(answers: 10);
      await analytics.sessionFailed(statusCode: 429);
      await analytics.sessionFailed();
      await analytics.sessionRetried();

      expect(spy.events, [
        event('session_started'),
        event('session_completed', {'answers': 10}),
        event('session_failed', {'status_code': 429}),
        event('session_failed'),
        event('session_retried'),
      ]);
    });
  });
}
