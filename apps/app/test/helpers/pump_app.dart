import 'package:emotely/app/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Standard app wrapper for widget tests: real themes, no mocked chrome.
extension PumpApp on WidgetTester {
  /// Pumps [widget] inside a themed [MaterialApp].
  Future<void> pumpApp(Widget widget, {ThemeMode themeMode = ThemeMode.light}) {
    return pumpWidget(
      MaterialApp(
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        home: widget,
      ),
    );
  }
}
