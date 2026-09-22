import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
/// A whole page — one that brings its own Scaffold — under the app's themes,
/// the way the app's navigator would show it.
Widget pageUnderTest(Widget page, {ThemeMode themeMode = ThemeMode.light}) =>
    MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: page,
    );

/// A feature's own routes under the app's themes and a router of their own,
/// opened at [initialLocation] — the way the app mounts them (ADR 0016),
/// without the app. [above] wraps the navigator, where the app puts what
/// every screen needs over it (the auth bloc, the startup gate); tests
/// hand in only what the routes under test read.
Widget featureUnderTest({
  required List<RouteBase> routes,
  required String initialLocation,
  Widget Function(BuildContext context, Widget child)? above,
  ThemeMode themeMode = ThemeMode.light,
}) => MaterialApp.router(
  theme: lightTheme,
  darkTheme: darkTheme,
  themeMode: themeMode,
  routerConfig: GoRouter(routes: routes, initialLocation: initialLocation),
  builder: above == null
      ? null
      : (context, child) => above(context, child ?? const SizedBox.shrink()),
);

extension PumpApp on WidgetTester {
  /// Pumps [widget] inside a themed [MaterialApp] scaffold.
  Future<void> pumpApp(
    Widget widget, {
    ThemeMode themeMode = ThemeMode.light,
  }) => pumpWidget(appWrapper(widget, themeMode: themeMode));
}
