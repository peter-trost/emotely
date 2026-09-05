// coverage:ignore-file
// Composition root; behavior lives in EmotelyApp and is tested there.
import 'package:emotely/app/theme.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const EmotelyApp());
}

/// Root of the emotely client; the GenUI session screen lands next.
class const EmotelyApp({super.key}) extends StatelessWidget {
  /// Creates the root widget.
  this;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'emotely',
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const Scaffold(body: Center(child: Text('emotely'))),
    );
  }
}
