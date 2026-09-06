import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/widgets/submit_button.dart';
import 'package:material_ui/material_ui.dart';

/// A free-text paragraph; submits [Answer.longtext].
class const LongtextInput({
  required final ValueChanged<Answer> onSubmit,
  super.key,
}) extends StatefulWidget {
  static const fieldKey = Key('longtext_input.field');
  static const submitKey = Key('longtext_input.submit');

  @override
  State<LongtextInput> createState() => _LongtextInputState();
}

class _LongtextInputState() extends State<LongtextInput> {
  final _controller = TextEditingController();

  String get _text => _controller.text.trim();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      TextField(
        key: LongtextInput.fieldKey,
        controller: _controller,
        minLines: 3,
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Write freely…'),
        onChanged: (_) => setState(() {}),
      ),
      SubmitButton(
        key: LongtextInput.submitKey,
        onPressed: _text.isEmpty
            ? null
            : () => widget.onSubmit(Answer.longtext(_text)),
      ),
    ],
  );
}
