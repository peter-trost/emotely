import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/widgets/color_input.dart';
import 'package:emotely/session/widgets/emoji_input.dart';
import 'package:emotely/session/widgets/longtext_input.dart';
import 'package:emotely/session/widgets/rating_input.dart';
import 'package:emotely/session/widgets/text_list_input.dart';
import 'package:material_ui/material_ui.dart';

/// The generative-UI seam: one native widget per `ask_question` tool call,
/// chosen by [AskQuestion.answerType].
class const AnswerInput({
  required final AskQuestion question,
  required final ValueChanged<Answer> onSubmit,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (question.answerType) {
    AnswerType.color => ColorInput(onSubmit: onSubmit),
    AnswerType.emoji => EmojiInput(onSubmit: onSubmit),
    AnswerType.longtext => LongtextInput(onSubmit: onSubmit),
    AnswerType.rating => RatingInput(onSubmit: onSubmit),
    AnswerType.textList => TextListInput(onSubmit: onSubmit),
  };
}
