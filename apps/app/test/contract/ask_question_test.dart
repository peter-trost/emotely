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

    test('two questions with the same fields are equal', () {
      expect(
        question,
        const AskQuestion(
          questionId: 'q-grateful',
          question: 'What are you grateful for?',
          answerType: AnswerType.textList,
        ),
      );
      expect(question.hashCode, isNot(question.copyWith(question: 'x')));
      expect(question, isNot(question.copyWith(questionId: 'q-other')));
    });

    test('prints id, answer type and text for readable test failures', () {
      expect(
        question.toString(),
        'AskQuestion(q-grateful, text_list: What are you grateful for?)',
      );
    });

    test('an unknown answer_type fails to decode', () {
      expect(
        () => AskQuestion.fromJson(const {
          'question_id': 'q-grateful',
          'question': 'What are you grateful for?',
          'answer_type': 'multiple_choice',
        }),
        throwsFormatException,
      );
    });
  });
}
