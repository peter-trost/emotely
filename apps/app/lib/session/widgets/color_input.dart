import 'package:emotely/contract/contract.dart';
import 'package:emotely/session/widgets/color_text_editing_controller.dart';
import 'package:emotely/session/widgets/submit_button.dart';
import 'package:material_ui/material_ui.dart';

/// A palette color with the name screen readers announce for it.
typedef PaletteColor = ({Color color, String name});

/// Colors offered as one-tap inserts; any typed `#RRGGBB` works as well.
const colorPalette = <PaletteColor>[
  (color: Color(0xFFE53935), name: 'red'),
  (color: Color(0xFFFB8C00), name: 'orange'),
  (color: Color(0xFFFDD835), name: 'yellow'),
  (color: Color(0xFF43A047), name: 'green'),
  (color: Color(0xFF00897B), name: 'teal'),
  (color: Color(0xFF1E88E5), name: 'blue'),
  (color: Color(0xFF3949AB), name: 'indigo'),
  (color: Color(0xFF8E24AA), name: 'purple'),
  (color: Color(0xFFD81B60), name: 'pink'),
  (color: Color(0xFF6D4C41), name: 'brown'),
  (color: Color(0xFF757575), name: 'grey'),
  (color: Color(0xFF212121), name: 'black'),
];

/// Free text in which `#RRGGBB` codes render as swatches; submits every
/// color found as [Answer.color], in order of appearance.
class const ColorInput({
  required final ValueChanged<Answer> onSubmit,
  super.key,
}) extends StatefulWidget {
  static const fieldKey = Key('color_input.field');
  static const submitKey = Key('color_input.submit');

  /// Key of the palette button for [name].
  static Key paletteKey(String name) => Key('color_input.palette.$name');

  @override
  State<ColorInput> createState() => _ColorInputState();
}

class _ColorInputState() extends State<ColorInput> {
  static const _converter = HexColorConverter();
  final _controller = ColorTextEditingController();

  List<Color> get _colors => [
    for (final match in ColorTextEditingController.hexColorRegex.allMatches(
      _controller.text,
    ))
      _converter.fromJson(match.group(0)!),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _insert(Color color) => setState(
    () => _controller.insertTextAtSelection('${_converter.toJson(color)} '),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      Wrap(
        children: [
          for (final entry in colorPalette)
            IconButton(
              key: ColorInput.paletteKey(entry.name),
              tooltip: entry.name,
              icon: CircleAvatar(backgroundColor: entry.color, radius: 14),
              onPressed: () => _insert(entry.color),
            ),
        ],
      ),
      TextField(
        key: ColorInput.fieldKey,
        controller: _controller,
        minLines: 2,
        maxLines: 6,
        decoration: const InputDecoration(
          hintText: 'Pick colors, or type #RRGGBB…',
        ),
        onChanged: (_) => setState(() {}),
      ),
      SubmitButton(
        key: ColorInput.submitKey,
        onPressed: _colors.isEmpty
            ? null
            : () => widget.onSubmit(Answer.color(_colors)),
      ),
    ],
  );
}
