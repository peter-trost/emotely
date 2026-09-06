import 'package:emotely/contract/hex_color_converter.dart';
import 'package:material_ui/material_ui.dart';

/// A [TextEditingController] that renders `#RRGGBB` codes in the text as
/// colored boxes while keeping normal editing behavior.
///
/// Ported from the original emotely app. Each character of a color code is
/// drawn as a thin colored slice so caret positions stay one-to-one with the
/// text, and the selection can never land inside a code: it is pushed to the
/// code's start or end depending on the direction it came from.
class ColorTextEditingController({super.text}) extends TextEditingController {
  /// Matches hex-encoded color strings in the format `#RRGGBB`.
  static final RegExp hexColorRegex = RegExp(r'#[0-9a-fA-F]{6}\b');

  static const _converter = HexColorConverter();

  /// Semantics label of the [index]th slice of [hexColor].
  static String sliceLabel(String hexColor, int index) =>
      'Color $hexColor $index';

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) => TextSpan(style: style, children: _parseText(style));

  List<InlineSpan> _parseText(TextStyle? style) {
    final spans = <InlineSpan>[];
    var start = 0;

    for (final match in hexColorRegex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      final hexColor = match.group(0)!;
      final color = _converter.fromJson(hexColor);
      final lastIndex = hexColor.length - 1;
      for (var i = 0; i <= lastIndex; i++) {
        spans.add(
          WidgetSpan(
            child: Semantics(
              label: sliceLabel(hexColor, i),
              container: true,
              child: SizedBox(
                width: 2.3,
                height: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: switch (i) {
                      0 => const BorderRadius.horizontal(
                        left: Radius.circular(4),
                      ),
                      _ when i == lastIndex => const BorderRadius.horizontal(
                        right: Radius.circular(4),
                      ),
                      _ => null,
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      }
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }

  /// Inserts [textToInsert] at the current selection, replacing any selected
  /// text, and collapses the selection after it.
  void insertTextAtSelection(String textToInsert) {
    final selection = _adjustSelection(
      previousSelection: value.selection,
      newSelection: value.selection,
      newText: value.text,
    );
    final newText = text.replaceRange(
      selection.baseOffset,
      selection.extentOffset,
      textToInsert,
    );
    value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.baseOffset + textToInsert.length,
      ),
    );
  }

  @override
  set value(TextEditingValue newValue) {
    super.value = newValue.copyWith(
      selection: _adjustSelection(
        previousSelection: value.selection,
        newSelection: newValue.selection,
        newText: newValue.text,
      ),
    );
  }

  /// Keeps the selection out of color codes. A caret entering a code from
  /// the left jumps to its end, from the right to its start; a range that
  /// touches a code grows to include it whole.
  TextSelection _adjustSelection({
    required TextSelection previousSelection,
    required TextSelection newSelection,
    required String newText,
  }) {
    var leading = newSelection.baseOffset < newSelection.extentOffset
        ? newSelection.baseOffset
        : newSelection.extentOffset;
    var trailing = newSelection.extentOffset > newSelection.baseOffset
        ? newSelection.extentOffset
        : newSelection.baseOffset;

    // Deleting a character: let the caret land where the deletion put it.
    if (previousSelection.isCollapsed && (leading - trailing) == -1) {
      return newSelection;
    }
    final isSelecting = leading != trailing;

    for (final match in hexColorRegex.allMatches(newText)) {
      final leadingInside = leading > match.start && leading < match.end;
      if (leadingInside) {
        leading = isSelecting || leading == match.end - 1
            ? match.start
            : match.end;
      }
      final trailingInside = trailing > match.start && trailing < match.end;
      if (trailingInside) {
        trailing = !isSelecting && trailing == match.end - 1
            ? match.start
            : match.end;
      }
    }

    return newSelection.copyWith(
      baseOffset: leading.clamp(0, newText.length),
      extentOffset: trailing.clamp(0, newText.length),
    );
  }
}
