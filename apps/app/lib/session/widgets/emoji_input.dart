import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/widgets/submit_button.dart';
import 'package:material_ui/material_ui.dart';

/// An emoji with the name screen readers announce for it.
typedef PaletteEmoji = ({String emoji, String name});

/// The feelings a journaling session tends to reach for, in palette order.
const emojiPalette = <PaletteEmoji>[
  (emoji: '😊', name: 'happy'),
  (emoji: '🥰', name: 'loved'),
  (emoji: '🤩', name: 'excited'),
  (emoji: '😌', name: 'relieved'),
  (emoji: '🙏', name: 'grateful'),
  (emoji: '💪', name: 'strong'),
  (emoji: '🎉', name: 'celebrating'),
  (emoji: '😎', name: 'confident'),
  (emoji: '🤔', name: 'thoughtful'),
  (emoji: '😐', name: 'neutral'),
  (emoji: '😴', name: 'tired'),
  (emoji: '😔', name: 'disappointed'),
  (emoji: '😢', name: 'sad'),
  (emoji: '😰', name: 'anxious'),
  (emoji: '😤', name: 'frustrated'),
  (emoji: '😡', name: 'angry'),
];

/// One or more emoji picked from [emojiPalette]; submits [Answer.emoji]
/// in palette order.
class const EmojiInput({
  required final ValueChanged<Answer> onSubmit,
  super.key,
}) extends StatefulWidget {
  static const submitKey = Key('emoji_input.submit');

  /// Key of the chip for [emoji].
  static Key chipKey(String emoji) => Key('emoji_input.chip.$emoji');

  @override
  State<EmojiInput> createState() => _EmojiInputState();
}

class _EmojiInputState() extends State<EmojiInput> {
  final _selected = <String>{};

  List<String> get _answer => [
    for (final entry in emojiPalette)
      if (_selected.contains(entry.emoji)) entry.emoji,
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in emojiPalette)
            FilterChip(
              key: EmojiInput.chipKey(entry.emoji),
              label: Text(entry.emoji, semanticsLabel: entry.name),
              selected: _selected.contains(entry.emoji),
              onSelected: (selected) => setState(() {
                if (selected) {
                  _selected.add(entry.emoji);
                } else {
                  _selected.remove(entry.emoji);
                }
              }),
            ),
        ],
      ),
      SubmitButton(
        key: EmojiInput.submitKey,
        onPressed: _selected.isEmpty
            ? null
            : () => widget.onSubmit(Answer.emoji(_answer)),
      ),
    ],
  );
}
