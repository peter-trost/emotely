import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Taps [color] on the open color picker's Material swatch page. The picker
/// hands back a plain color, so a caller expecting it back compares values,
/// not the swatch it was picked from.
Future<void> tapSwatch(WidgetTester tester, Color color) async {
  await tester.tap(
    find
        .byWidgetPredicate(
          (widget) =>
              widget is ColorIndicator &&
              widget.color.toARGB32() == color.toARGB32(),
        )
        .first,
  );
  await tester.pump();
}
