import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Taps the [Slider] under [slider] where [value] sits on its track, which
/// with divisions snaps to the nearest stop. The track is inset by the
/// overlay radius on both ends, which is how the slider itself lays it out.
Future<void> tapSliderAt(WidgetTester tester, Finder slider, num value) async {
  final widget = tester.widget<Slider>(slider);
  final rect = tester.getRect(slider);
  const inset = 24.0;
  final fraction = (value - widget.min) / (widget.max - widget.min);
  final x = rect.left + inset + fraction * (rect.width - 2 * inset);
  await tester.tapAt(Offset(x, rect.center.dy));
  await tester.pump();
}
