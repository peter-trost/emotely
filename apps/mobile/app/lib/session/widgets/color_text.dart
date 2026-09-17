import 'package:emotely/contract/hex_color_converter.dart';
import 'package:emotely/session/widgets/color_text_editing_controller.dart';
import 'package:material_ui/material_ui.dart';

/// Text with every `#RRGGBB` code replaced by a colored box.
///
/// Ported from the original emotely app; the read-only counterpart of
/// [ColorTextEditingController].
class const ColorText(final String text, {final TextStyle? style, super.key})
    extends StatelessWidget {
  static const _converter = HexColorConverter();

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(children: _spans()),
    style: style,
    semanticsLabel: text,
  );

  List<InlineSpan> _spans() {
    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in ColorTextEditingController.hexColorRegex.allMatches(
      text,
    )) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      final hexColor = match.group(0)!;
      spans.add(
        WidgetSpan(
          child: ColorBox(
            color: _converter.fromJson(hexColor),
            semanticLabel: hexColor,
          ),
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }
}

/// A small rounded swatch of [color], labeled for screen readers.
class const ColorBox({
  required final Color color,
  required final String semanticLabel,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    container: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        width: 16,
        height: 16,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    ),
  );
}
