import 'package:emotely/contract/contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(AskQuestion, () {
    const json = <String, dynamic>{
      'question_id': 'q-grateful',
      'question': 'What are you grateful for?',
      'answer_type': 'text_list',
    };
    const question = AskQuestion(
      questionId: 'q-grateful',
      question: 'What are you grateful for?',
      answerType: AnswerType.textList,
    );

    test('decodes an ask_question tool call', () {
      expect(AskQuestion.fromJson(json), question);
    });

    test('encodes back to the same wire shape', () {
      expect(question.toJson(), json);
    });

    test('an unknown answer_type fails to decode', () {
      expect(
        () => AskQuestion.fromJson(const {
          'question_id': 'q-grateful',
          'question': 'What are you grateful for?',
          'answer_type': 'multiple_choice',
        }),
        throwsArgumentError,
      );
    });
  });
}
