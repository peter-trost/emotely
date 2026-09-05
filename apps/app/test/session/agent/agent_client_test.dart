import 'dart:convert';

import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/agent/advance_response.dart';
import 'package:emotely/session/agent/agent_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/helpers.dart';

void main() {
  group(AgentClient, () {
    const question = AskQuestion(
      questionId: 'q-rate',
      question: 'How was your day?',
      answerType: AnswerType.rating,
    );

    test('starts a session with an empty body', () async {
      final stub = AgentStub()
        ..script([awaiting(toolCallId: 'c1', question: question)]);

      final response = await stub.agentClient.advance();

      expect(stub.lastRequest, isEmpty);
      expect(
        response,
        const AdvanceResponse.awaitingAnswer(
          transcript: ['round'],
          signature: 'sig',
          promptId: 'session/v1',
          pending: PendingQuestion(toolCallId: 'c1', question: question),
        ),
      );
    });

    test('echoes the transcript and signature with the answer', () async {
      final stub = AgentStub()
        ..script([
          completed(
            summary: 'A good day.',
            answers: const {'q-rate': Answer.rating(7)},
          ),
        ]);

      final response = await stub.agentClient.advance(
        transcript: const ['round'],
        signature: 'sig',
        answer: (toolCallId: 'c1', value: 7),
      );

      expect(stub.lastRequest, {
        'transcript': ['round'],
        'signature': 'sig',
        'answer': {'toolCallId': 'c1', 'value': 7},
      });
      expect(
        response,
        const AdvanceResponse.completed(
          transcript: ['round', 'round'],
          signature: 'final',
          promptId: 'session/v1',
          entry: JournalEntry(
            summary: 'A good day.',
            answers: {'q-rate': Answer.rating(7)},
          ),
        ),
      );
    });

    test('posts JSON to the endpoint', () async {
      final stub = AgentStub()
        ..script([awaiting(toolCallId: 'c1', question: question)]);

      await stub.agentClient.advance();

      verify(
        stub.client.post(
          AgentStub.endpoint,
          headers: {'content-type': 'application/json'},
          body: anyNamed('body'),
        ),
      ).called(1);
    });

    test('surfaces the server error message on a non-200', () async {
      final stub = AgentStub()..script([refused(401, 'invalid signature')]);

      await expectLater(
        stub.agentClient.advance(),
        throwsA(
          isA<AgentException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', 'invalid signature')
              .having(
                (e) => e.toString(),
                'toString',
                'AgentException(401): invalid signature',
              ),
        ),
      );
    });

    test(
      'falls back to a generic message when the error is not JSON',
      () async {
        final stub = AgentStub()
          ..script([
            raw('<html>Bad Gateway</html>', 502),
            raw(jsonEncode({'detail': 'nope'}), 500),
          ]);

        for (final code in [502, 500]) {
          await expectLater(
            stub.agentClient.advance(),
            throwsA(
              isA<AgentException>()
                  .having((e) => e.statusCode, 'statusCode', code)
                  .having((e) => e.message, 'message', 'unexpected response'),
            ),
          );
        }
      },
    );
  });
}
