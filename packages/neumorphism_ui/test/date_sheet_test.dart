// The date sheet (showNeumorphicDatePicker) fits its month: on a desk the sheet narrows round the month, so the month,
// its arrows and the sheet's close and buttons span one width; on a phone the sheet spans the screen and the month the
// sheet. A day that arrives under a still pointer, as the sheet opens, stays at rest until the pointer moves.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/internal/day_face.dart';

import 'support.dart';

Finder _day(int day) => find.byWidgetPredicate(
  (w) => w is NeumorphicTap && (w.label ?? '').contains('November $day, 2026'),
);

/// The days whose face shows the pointer.
List<int> _hovered(WidgetTester tester) => [
  for (var d = 1; d <= 30; d++)
    if (tester
        .widgetList<NeumorphicDayFace>(
          find.descendant(
            of: _day(d),
            matching: find.byType(NeumorphicDayFace),
          ),
        )
        .any((f) => f.hovered || f.states.contains(WidgetState.hovered)))
      d,
];

Future<TestGesture> _open(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    neumorphicApp(
      Builder(
        builder: (context) => Center(
          child: NeumorphicButton(
            'Due',
            onPressed: () => showNeumorphicDatePicker(
              context,
              value: DateTime(2026, 11, 20),
              currentDate: DateTime(2026, 11, 18),
              title: 'Due date',
            ),
          ),
        ),
      ),
      width: size.width,
    ),
  );
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(mouse.removePointer);
  final at = tester.getCenter(find.text('Due'));
  await mouse.addPointer(location: at);
  await mouse.down(at);
  await mouse.up();
  await tester.pumpAndSettle();
  return mouse;
}

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final size in const [Size(1440, 900), Size(700, 1000), Size(390, 844)]) {
    final wide = size.width.toInt();
    testWidgets('at $wide, the month spans its sheet', (tester) async {
      await _open(tester, size);
      final sheet = tester.getRect(find.byType(NeumorphicBottomSheet));
      final month = tester.getRect(find.byType(NeumorphicDatePicker));
      expect(
        month.left - sheet.left,
        closeTo(20, 1),
        reason: '$month in $sheet',
      );
      expect(
        sheet.right - month.right,
        closeTo(20, 1),
        reason: '$month in $sheet',
      );
      if (wide < 600) {
        expect(sheet.width, size.width, reason: "a phone's sheet spans it");
      } else {
        expect(sheet.width, lessThan(560), reason: 'the sheet fits its month');
      }
    });
  }

  testWidgets('a day the sheet opens under a still pointer stays at rest until '
      'the pointer moves, and rests again when it leaves', (tester) async {
    final mouse = await _open(tester, const Size(1440, 900));
    final under = [
      for (var d = 1; d <= 30; d++)
        if (tester.getRect(_day(d)).contains(const Offset(720, 450))) d,
    ];
    expect(under, hasLength(1), reason: 'the pointer rests on a day');
    expect(_hovered(tester), isEmpty, reason: 'nothing lit before it moves');
    await mouse.moveBy(const Offset(1, 0));
    await tester.pumpAndSettle();
    expect(_hovered(tester), under, reason: 'the day under it, once it moves');
    await mouse.moveTo(tester.getCenter(_day(6)));
    await tester.pumpAndSettle();
    expect(_hovered(tester), [6]);
    await mouse.moveTo(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(_hovered(tester), isEmpty, reason: 'off the sheet');
  });
}
