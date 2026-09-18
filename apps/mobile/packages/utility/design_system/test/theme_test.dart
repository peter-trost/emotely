import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('theme', () {
    test('the light theme is seeded from emotely orange in Baskervville', () {
      final theme = lightTheme;

      expect(theme.brightness, Brightness.light);
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Baskervville');
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.scrolledUnderElevation, 4);
    });

    test('the dark theme is its counterpart', () {
      final theme = darkTheme;

      expect(theme.brightness, Brightness.dark);
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Baskervville');
    });
  });
}
