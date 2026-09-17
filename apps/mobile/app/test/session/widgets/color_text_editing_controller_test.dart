import 'package:emotely/session/widgets/color_text_editing_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/helpers.dart';

/// A selection move on `text`: the selection before the move (absent for a
/// fresh controller), the requested selection, and where it must end up.
typedef _SelectionCase = ({
  String name,
  String text,
  TextSelection? previous,
  TextSelection requested,
  TextSelection expected,
});

TextSelection _caret(int offset) => TextSelection.collapsed(offset: offset);

TextSelection _range(int base, int extent) =>
    TextSelection(baseOffset: base, extentOffset: extent);

// Ported from the original emotely app, where every case was its own test.
const _single = 'some #FF5733 text';
const _multiple = '#FF5733 some #33FF57 text #5733FF';
const _packed = '#FF5733 #33FF57 #5733FF';
const _adjacent = '#FF5733#33FF57#5733FF';

final _selectionCases = <_SelectionCase>[
  (
    name: 'empty text',
    text: '',
    previous: _caret(0),
    requested: _caret(0),
    expected: _caret(0),
  ),
  (
    name: 'no colors',
    text: 'Hello World',
    previous: _caret(5),
    requested: _caret(5),
    expected: _caret(5),
  ),
  (
    name: 'caret before a color at the start',
    text: '#FF5733 some text',
    previous: _caret(0),
    requested: _caret(0),
    expected: _caret(0),
  ),
  (
    name: 'caret before a color at the end',
    text: 'some text #FF5733',
    previous: _caret(10),
    requested: _caret(10),
    expected: _caret(10),
  ),
  (
    name: 'caret before a color in the middle',
    text: _single,
    previous: _caret(5),
    requested: _caret(5),
    expected: _caret(5),
  ),
  (
    name: 'caret one before a color',
    text: _single,
    previous: _caret(4),
    requested: _caret(4),
    expected: _caret(4),
  ),
  (
    name: 'fresh caret inside a color jumps to its end',
    text: _single,
    previous: null,
    requested: _caret(6),
    expected: _caret(12),
  ),
  (
    name: 'caret entering a color from before jumps to its end',
    text: _single,
    previous: _caret(2),
    requested: _caret(6),
    expected: _caret(12),
  ),
  (
    name: 'caret entering a color from after jumps to its end',
    text: _single,
    previous: _caret(14),
    requested: _caret(6),
    expected: _caret(12),
  ),
  (
    name: 'caret moving past a color',
    text: _single,
    previous: _caret(12),
    requested: _caret(13),
    expected: _caret(13),
  ),
  (
    name: 'caret moving to before a color',
    text: _single,
    previous: _caret(12),
    requested: _caret(5),
    expected: _caret(5),
  ),
  (
    name: 'caret stepping left into a color jumps to its start',
    text: _single,
    previous: _caret(12),
    requested: _caret(11),
    expected: _caret(5),
  ),
  (
    name: 'multiple colors, caret before the first',
    text: _multiple,
    previous: _caret(0),
    requested: _caret(0),
    expected: _caret(0),
  ),
  (
    name: 'multiple colors, caret after the last',
    text: _multiple,
    previous: _caret(33),
    requested: _caret(33),
    expected: _caret(33),
  ),
  (
    name: 'multiple colors, caret between colors',
    text: _multiple,
    previous: _caret(12),
    requested: _caret(13),
    expected: _caret(13),
  ),
  (
    name: 'packed colors, caret into the first from after it',
    text: _packed,
    previous: _caret(8),
    requested: _caret(4),
    expected: _caret(7),
  ),
  (
    name: 'packed colors, caret into the first from the left',
    text: _packed,
    previous: _caret(0),
    requested: _caret(1),
    expected: _caret(7),
  ),
  (
    name: 'packed colors, fresh caret inside the first',
    text: _packed,
    previous: null,
    requested: _caret(1),
    expected: _caret(7),
  ),
  (
    name: 'packed colors, caret into the first from the right',
    text: _packed,
    previous: _caret(7),
    requested: _caret(6),
    expected: _caret(0),
  ),
  (
    name: 'packed colors, caret into the second',
    text: _packed,
    previous: _caret(0),
    requested: _caret(13),
    expected: _caret(15),
  ),
  (
    name: 'packed colors, caret into the third',
    text: _packed,
    previous: _caret(0),
    requested: _caret(18),
    expected: _caret(23),
  ),
  (
    name: 'packed colors, caret into the third from the right',
    text: _packed,
    previous: _caret(23),
    requested: _caret(22),
    expected: _caret(16),
  ),
  (
    name: 'packed colors, caret into the third from the left',
    text: _packed,
    previous: _caret(16),
    requested: _caret(17),
    expected: _caret(23),
  ),
  (
    name: 'a lone # is not a color',
    text: '#F some text',
    previous: _caret(2),
    requested: _caret(2),
    expected: _caret(2),
  ),
  (
    name: 'a too-short code is not a color',
    text: '#FF573 some text',
    previous: _caret(5),
    requested: _caret(5),
    expected: _caret(5),
  ),
  (
    name: 'adjacent colors, caret before the first',
    text: _adjacent,
    previous: _caret(0),
    requested: _caret(0),
    expected: _caret(0),
  ),
  (
    name: 'adjacent colors, caret after the last',
    text: _adjacent,
    previous: _caret(21),
    requested: _caret(21),
    expected: _caret(21),
  ),
  (
    name: 'adjacent colors, caret before the middle',
    text: _adjacent,
    previous: _caret(7),
    requested: _caret(7),
    expected: _caret(7),
  ),
  (
    name: 'adjacent colors, caret after the middle',
    text: _adjacent,
    previous: _caret(14),
    requested: _caret(14),
    expected: _caret(14),
  ),
  (
    name: 'adjacent colors, into the first from the left',
    text: _adjacent,
    previous: _caret(0),
    requested: _caret(1),
    expected: _caret(7),
  ),
  (
    name: 'adjacent colors, into the first from the right',
    text: _adjacent,
    previous: _caret(7),
    requested: _caret(6),
    expected: _caret(0),
  ),
  (
    name: 'adjacent colors, into the second from the left',
    text: _adjacent,
    previous: _caret(7),
    requested: _caret(8),
    expected: _caret(14),
  ),
  (
    name: 'adjacent colors, into the second from the right',
    text: _adjacent,
    previous: _caret(14),
    requested: _caret(13),
    expected: _caret(7),
  ),
  (
    name: 'adjacent colors, into the third from the left',
    text: _adjacent,
    previous: _caret(14),
    requested: _caret(15),
    expected: _caret(21),
  ),
  (
    name: 'adjacent colors, into the third from the right',
    text: _adjacent,
    previous: _caret(21),
    requested: _caret(20),
    expected: _caret(14),
  ),
  (
    name: 'caret inside an invalid code next to a valid one stays',
    text: '#FF573 #FF5733 some text',
    previous: _caret(5),
    requested: _caret(5),
    expected: _caret(5),
  ),
  (
    name: 'caret inside an invalid code stays',
    text: '#FF573 some text',
    previous: _caret(3),
    requested: _caret(3),
    expected: _caret(3),
  ),
  (
    name: 'a range inside a color grows to the whole color',
    text: '#FFFFFF',
    previous: null,
    requested: _range(1, 4),
    expected: _range(0, 7),
  ),
  (
    name: 'a range shrinking into a color grows back to the whole color',
    text: '#FFFFFF',
    previous: _range(0, 7),
    requested: _range(6, 7),
    expected: _range(0, 7),
  ),
  (
    name: 'a one-character range after a caret (a deletion) is left alone',
    text: _single,
    previous: _caret(13),
    requested: _range(11, 12),
    expected: _range(11, 12),
  ),
];

void main() {
  group(ColorTextEditingController, () {
    group('selection', () {
      for (final c in _selectionCases) {
        test(c.name, () {
          final controller = ColorTextEditingController();
          addTearDown(controller.dispose);

          if (c.previous case final previous?) {
            controller.value = controller.value.copyWith(
              text: c.text,
              selection: previous,
            );
            expect(controller.selection, previous);
          }
          controller.value = controller.value.copyWith(
            text: c.text,
            selection: c.requested,
          );

          expect(controller.text, c.text);
          expect(controller.selection, c.expected);
        });
      }
    });

    group('insertTextAtSelection', () {
      const insertCases =
          <
            ({
              String name,
              String text,
              TextSelection selection,
              String insert,
              String expected,
              int caret,
            })
          >[
            (
              name: 'at the start',
              text: 'Hello World',
              selection: TextSelection.collapsed(offset: 0),
              insert: 'Hi, ',
              expected: 'Hi, Hello World',
              caret: 4,
            ),
            (
              name: 'at the end',
              text: 'Hello World',
              selection: TextSelection.collapsed(offset: 11),
              insert: '!',
              expected: 'Hello World!',
              caret: 12,
            ),
            (
              name: 'in the middle',
              text: 'Hello World',
              selection: TextSelection.collapsed(offset: 5),
              insert: ' beautiful',
              expected: 'Hello beautiful World',
              caret: 15,
            ),
            (
              name: 'replacing a range',
              text: 'Hello World',
              selection: TextSelection(baseOffset: 0, extentOffset: 5),
              insert: 'Hi,',
              expected: 'Hi, World',
              caret: 3,
            ),
            (
              name: 'replacing a range that covers a color',
              text: '#FF5733 some text',
              selection: TextSelection(baseOffset: 0, extentOffset: 12),
              insert: 'This is',
              expected: 'This is text',
              caret: 7,
            ),
          ];

      for (final c in insertCases) {
        test(c.name, () {
          final controller = ColorTextEditingController();
          addTearDown(controller.dispose);
          controller.value = controller.value.copyWith(
            text: c.text,
            selection: c.selection,
          );

          controller.insertTextAtSelection(c.insert);

          expect(controller.text, c.expected);
          expect(
            controller.selection,
            TextSelection.collapsed(offset: c.caret),
          );
        });
      }
    });

    group('buildTextSpan', () {
      Future<ColorTextEditingController> pumpTestWidget(
        WidgetTester tester,
      ) async {
        final controller = ColorTextEditingController();
        addTearDown(controller.dispose);
        await tester.pumpApp(TextField(controller: controller));
        return controller;
      }

      Finder slice(String hexColor, int index) => find.bySemanticsLabel(
        ColorTextEditingController.sliceLabel(hexColor, index),
      );

      testWidgets('renders no slices without colors', (tester) async {
        await pumpTestWidget(tester);

        await tester.enterText(find.byType(TextField), 'Hello World');
        await tester.pump();

        expect(find.bySemanticsLabel(RegExp('^Color ')), findsNothing);
      });

      testWidgets('renders one slice per character of a color', (tester) async {
        await pumpTestWidget(tester);

        await tester.enterText(find.byType(TextField), '#FF5733 some text');
        await tester.pump();

        for (var i = 0; i < '#FF5733'.length; i++) {
          expect(slice('#FF5733', i), findsOneWidget);
        }
      });

      testWidgets('renders every color in the text', (tester) async {
        await pumpTestWidget(tester);

        await tester.enterText(find.byType(TextField), _multiple);
        await tester.pump();

        for (final hexColor in ['#FF5733', '#33FF57', '#5733FF']) {
          for (var i = 0; i < hexColor.length; i++) {
            expect(slice(hexColor, i), findsOneWidget);
          }
        }
      });

      testWidgets('rounds the outer corners of a color only', (tester) async {
        await pumpTestWidget(tester);

        await tester.enterText(find.byType(TextField), '#FF5733 some text');
        await tester.pump();

        DecoratedBox boxOf(int index) => tester.widget<DecoratedBox>(
          find.descendant(
            of: slice('#FF5733', index),
            matching: find.byType(DecoratedBox),
          ),
        );

        expect(
          boxOf(0).decoration,
          const BoxDecoration(
            color: Color(0xFFFF5733),
            borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
          ),
        );
        expect(
          boxOf(3).decoration,
          const BoxDecoration(color: Color(0xFFFF5733)),
        );
        expect(
          boxOf(6).decoration,
          const BoxDecoration(
            color: Color(0xFFFF5733),
            borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
          ),
        );
      });

      testWidgets('meets accessibility guidelines', (tester) async {
        final controller = ColorTextEditingController(text: 'a #FF5733 day');
        addTearDown(controller.dispose);

        await tester.expectMeetsAccessibilityGuidelines(
          appWrapper(TextField(controller: controller)),
        );
      });
    });
  });
}
