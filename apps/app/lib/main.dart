import 'package:flutter/material.dart';

void main() {
  runApp(const EmotelyApp());
}

/// Placeholder shell; the GenUI session screen lands with issue #6.
class EmotelyApp extends StatelessWidget {
  /// Creates the app root.
  const EmotelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'emotely',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Scaffold(body: Center(child: Text('emotely'))),
    );
  }
}
