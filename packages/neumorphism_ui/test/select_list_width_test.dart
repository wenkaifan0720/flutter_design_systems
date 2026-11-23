// A select's open list starts on its field's leading edge at the field's width, and widens past it only as far as its
// widest option needs: the chosen one is set bold with its check at its end, so a face that hugs its options would
// break "Living room" onto two lines in a list held to the face. An option's words stay on one line.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

const _rooms = ['Living room', 'Kitchen', 'Hall', 'Bedroom', 'Study'];

Future<(Rect field, Rect list)> _open(
  WidgetTester tester, {
  required double width,
  TextDirection direction = TextDirection.ltr,
  bool stretch = false,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final select = NeumorphicSelect<String>(
    key: const Key('room'),
    labelText: 'Room',
    value: 'Living room',
    options: [for (final r in _rooms) NeumorphicMenuItem(r, r)],
    onChanged: (_) {},
  );
  await tester.pumpWidget(
    neumorphicApp(
      Padding(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: stretch ? select : SizedBox(width: width - 48, child: select),
        ),
      ),
      direction: direction,
      width: width,
    ),
  );
  final face = find.byWidgetPredicate(
    (w) => w is NeumorphicTap && w.label == 'Room, Living room',
  );
  final field = tester.getRect(face);
  await tester.tap(face);
  await tester.pumpAndSettle();
  return (field, tester.getRect(find.byType(NeumorphicMenu<String>)));
}

void _oneLineEach(WidgetTester tester) {
  final menu = find.byType(NeumorphicMenu<String>);
  final line = tester
      .getSize(find.descendant(of: menu, matching: find.text('Kitchen')))
      .height;
  for (final r in _rooms) {
    expect(
      tester.getSize(find.descendant(of: menu, matching: find.text(r))).height,
      line,
      reason: '"$r" on one line',
    );
  }
}

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final direction in TextDirection.values) {
    testWidgets(
      'a face that hugs its options opens a list that fits the chosen one ($direction)',
      (tester) async {
        final (field, list) = await _open(
          tester,
          width: 1440,
          direction: direction,
        );
        _oneLineEach(tester);
        expect(list.width, greaterThanOrEqualTo(field.width - .01));
        // No wider than a control's most (320): it widens for its words, never toward the screen.
        expect(list.width, lessThanOrEqualTo(320));
        if (direction == TextDirection.ltr) {
          expect(list.left, moreOrLessEquals(field.left, epsilon: .01));
        } else {
          expect(list.right, moreOrLessEquals(field.right, epsilon: .01));
        }
      },
    );
  }

  testWidgets('a field wider than its options opens a list of its own width', (
    tester,
  ) async {
    final (field, list) = await _open(tester, width: 390, stretch: true);
    _oneLineEach(tester);
    expect(list.left, moreOrLessEquals(field.left, epsilon: .01));
    expect(list.width, moreOrLessEquals(field.width, epsilon: .01));
  });
}
