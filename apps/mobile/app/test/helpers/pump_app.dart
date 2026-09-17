import 'package:emotely/app/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Wraps [child] the way the app does: real themes, a scaffold, no mocked
/// chrome. Use it wherever a bare widget must be pumped, e.g. for the
/// accessibility check.
Widget appWrapper(Widget child, {ThemeMode themeMode = ThemeMode.light}) =>
    MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );

/// Standard app wrapper for widget tests.
extension PumpApp on WidgetTester {
  /// Pumps [widget] inside a themed [MaterialApp] scaffold.
  Future<void> pumpApp(
    Widget widget, {
    ThemeMode themeMode = ThemeMode.light,
  }) => pumpWidget(appWrapper(widget, themeMode: themeMode));
}
