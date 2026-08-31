import 'package:material_ui/material_ui.dart';

/// The emotely brand seed — carried over from the original app.
const Color emotelyOrange = Color.fromARGB(255, 255, 136, 0);

ThemeData _theme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: emotelyOrange,
    brightness: brightness,
  );
  final base = ThemeData(colorScheme: scheme);
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Baskervville'),
    appBarTheme: base.appBarTheme.copyWith(
      elevation: 0,
      scrolledUnderElevation: 4,
    ),
  );
}

/// Light theme: emotely orange seed + Baskervville serif.
ThemeData get lightTheme => _theme(Brightness.light);

/// Dark counterpart of [lightTheme].
ThemeData get darkTheme => _theme(Brightness.dark);
