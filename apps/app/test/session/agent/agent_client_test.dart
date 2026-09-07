import 'dart:async';
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
    const toolCallId = 'c1';
    const rating = Answer.rating(7);

    test('starts a session with nothing but the app version', () async {
      final stub = AgentStub()
        ..script([awaiting(toolCallId: toolCallId, question: question)]);

      final response = await stub.agentClient.advance();

      expect(stub.lastRequest, {'app_version': AgentStub.appVersion});
      expect(
        response,
        const AdvanceResponse.awaitingAnswer(
          transcript: AgentStub.transcript,
          signature: AgentStub.signature,
          promptId: 'session/v1',
          pending: PendingQuestion(toolCallId: toolCallId, question: question),
        ),
      );
    });

    test('echoes the transcript and signature with the wire answer', () async {
      const summary = 'A good day.';
      final stub = AgentStub()
        ..script([
          completed(summary: summary, answers: const {'q-rate': rating}),
        ]);

      final response = await stub.agentClient.advance(
        transcript: AgentStub.transcript,
        signature: AgentStub.signature,
        answer: (toolCallId: toolCallId, answer: rating),
      );

      expect(stub.lastRequest, {
        'transcript': AgentStub.transcript,
        'signature': AgentStub.signature,
        'answer': {'tool_call_id': toolCallId, 'value': rating.wireValue},
        'app_version': AgentStub.appVersion,
      });
      expect(
        response,
        const AdvanceResponse.completed(
          transcript: ['round', 'round'],
          signature: 'final',
          promptId: 'session/v1',
          entry: JournalEntry(summary: summary, answers: {'q-rate': rating}),
        ),
      );
    });

    test('decodes the minimum app version the server still serves', () async {
      final stub = AgentStub()
        ..script([
          awaiting(
            toolCallId: toolCallId,
            question: question,
            minAppVersion: '2.0.0',
          ),
        ]);

      final response = await stub.agentClient.advance();

      expect(response.minAppVersion, '2.0.0');
    });

    test('a response without a minimum app version imposes none', () async {
      final stub = AgentStub()
        ..script([awaiting(toolCallId: toolCallId, question: question)]);

      final response = await stub.agentClient.advance();

      expect(response.minAppVersion, isNull);
    });

    test('posts JSON to the endpoint', () async {
      final stub = AgentStub()
        ..script([awaiting(toolCallId: toolCallId, question: question)]);

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
      const message = 'invalid signature';
      final stub = AgentStub()..script([refused(401, message)]);

      await expectLater(
        stub.agentClient.advance(),
        throwsA(
          isA<AgentException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', message)
              .having(
                (e) => e.toString(),
                'toString',
                'AgentException(401): $message',
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

    test('gives up on a round that exceeds the timeout', () async {
      final stub = AgentStub()
        ..script([
          delayed(
            awaiting(toolCallId: toolCallId, question: question),
            const Duration(milliseconds: 50),
          ),
        ]);
      final client = AgentClient(
        httpClient: stub.client,
        endpoint: AgentStub.endpoint,
        appVersion: AgentStub.appVersion,
        timeout: const Duration(milliseconds: 10),
      );

      await expectLater(client.advance(), throwsA(isA<TimeoutException>()));
    });
  });
}
