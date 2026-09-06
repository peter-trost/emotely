import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/widgets/submit_button.dart';
import 'package:material_ui/material_ui.dart';

/// A 1–10 rating picked from ten chips; submits [Answer.rating].
class const RatingInput({
  required final ValueChanged<Answer> onSubmit,
  super.key,
}) extends StatefulWidget {
  static const submitKey = Key('rating_input.submit');

  /// Lowest and highest selectable values, as in the contract.
  static const min = 1;
  static const max = 10;

  /// Key of the chip for [value].
  static Key chipKey(int value) => Key('rating_input.chip.$value');

  @override
  State<RatingInput> createState() => _RatingInputState();
}

class _RatingInputState() extends State<RatingInput> {
  int? _value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var value = RatingInput.min; value <= RatingInput.max; value++)
            ChoiceChip(
              key: RatingInput.chipKey(value),
              label: Text('$value'),
              selected: _value == value,
              onSelected: (_) => setState(() => _value = value),
            ),
        ],
      ),
      SubmitButton(
        key: RatingInput.submitKey,
        onPressed: switch (_value) {
          null => null,
          final value => () => widget.onSubmit(Answer.rating(value)),
        },
      ),
    ],
  );
}
