import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/widgets/submit_button.dart';
import 'package:material_ui/material_ui.dart';

/// One or more short items, added one at a time; submits [Answer.textList].
///
/// Whatever is still typed in the field when submitting counts as an item,
/// so a user never loses the last thing they wrote by skipping "Add".
class const TextListInput({
  required final ValueChanged<Answer> onSubmit,
  super.key,
}) extends StatefulWidget {
  static const fieldKey = Key('text_list_input.field');
  static const addKey = Key('text_list_input.add');
  static const submitKey = Key('text_list_input.submit');

  /// Key of the chip showing the [index]th added item.
  static Key itemKey(int index) => Key('text_list_input.item.$index');

  @override
  State<TextListInput> createState() => _TextListInputState();
}

class _TextListInputState() extends State<TextListInput> {
  final _controller = TextEditingController();
  final _items = <String>[];

  String get _pending => _controller.text.trim();

  List<String> get _answer => [..._items, if (_pending.isNotEmpty) _pending];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    if (_pending.isEmpty) {
      return;
    }
    setState(() {
      _items.add(_pending);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      if (_items.isNotEmpty)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (index, item) in _items.indexed)
              InputChip(
                key: TextListInput.itemKey(index),
                label: Text(item),
                onDeleted: () => setState(() => _items.removeAt(index)),
              ),
          ],
        ),
      TextField(
        key: TextListInput.fieldKey,
        controller: _controller,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: 'Add an item…',
          suffixIcon: IconButton(
            key: TextListInput.addKey,
            tooltip: 'Add',
            icon: const Icon(Icons.add),
            onPressed: _pending.isEmpty ? null : _add,
          ),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _add(),
      ),
      SubmitButton(
        key: TextListInput.submitKey,
        onPressed: _answer.isEmpty
            ? null
            : () => widget.onSubmit(Answer.textList(_answer)),
      ),
    ],
  );
}
