import 'package:emotely/contract/contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The button inside the submit widget under [key] (the widget itself is a
/// full-width [Align], so its center is empty space).
Finder submitButton(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(FilledButton));

/// Whether the submit button under [key] is enabled.
bool isSubmitEnabled(WidgetTester tester, Key key) =>
    tester.widget<FilledButton>(submitButton(key)).onPressed != null;

/// Taps the submit button under [key] and pumps one frame.
Future<void> tapSubmit(WidgetTester tester, Key key) async {
  await tester.tap(submitButton(key));
  await tester.pump();
}

/// Collects what an answer widget submits.
class Submitted() {
  final answers = <Answer>[];

  void call(Answer answer) => answers.add(answer);

  Answer get single => answers.single;
}

/// An `onSubmit` for accessibility pumps that only need a valid widget.
void ignoreAnswer(Answer _) {}
