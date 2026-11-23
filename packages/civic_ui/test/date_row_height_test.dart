// Controls in a row stand one height: a date picker's Choose date button
// and the typed date's well beside it stand as tall as the taller of the
// two (on a touch screen the well's figures keep a finger's 48 inside its
// two edges, 52 in all, where the button stood 48; at twice the text the
// button stood 76 beside a well of 56), on a phone and a wide window, at the
// reader's text and twice it, left to right and right to left; a date
// range's button and its two wells likewise. On a phone the button may take
// a line of its own under the well.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';
import 'screens_matrix.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  required double width,
  required double text,
  required TextDirection direction,
}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = text;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    kitApp(
      brightness: Brightness.light,
      direction: direction,
      home: SingleChildScrollView(
        padding: const EdgeInsets.all(CivicSpacing.s20),
        child: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _platforms = TargetPlatformVariant({
  TargetPlatform.android,
  TargetPlatform.iOS,
  TargetPlatform.macOS,
});

void main() {
  setUpAll(loadScreenFonts);

  for (final width in [390.0, 1440.0]) {
    for (final text in [1.0, 2.0]) {
      for (final direction in TextDirection.values) {
        final at =
            'at $width, text ×${text.toStringAsFixed(0)}, '
            '${direction.name}';
        testWidgets("the Choose date button stands as tall as the date's "
            'well, $at', (tester) async {
          await _show(
            tester,
            CivicDatePicker(
              labelText: 'When do you want the permit to start?',
              value: DateTime(2026, 11, 24),
              firstDate: DateTime(2026),
              lastDate: DateTime(2026, 12, 31),
              onChanged: (_) {},
            ),
            width: width,
            text: text,
            direction: direction,
          );
          final well = tester.getRect(find.byType(CivicWell));
          final button = tester.getRect(find.byType(CivicButton));
          final inRow = button.top < well.bottom;
          // On a wide window they stand side by side; on a phone the button
          // may take a line of its own under the well.
          if (width == 1440) expect(inRow, isTrue, reason: 'not in a row');
          if (inRow) {
            expect(button.height, moreOrLessEquals(well.height, epsilon: .5));
            expect(button.top, moreOrLessEquals(well.top, epsilon: .5));
          }
        }, variant: _platforms);

        testWidgets("the Choose dates button stands as tall as the range's "
            'wells, $at', (tester) async {
          await _show(
            tester,
            CivicDateRangePicker(
              labelText: 'When will your visitor stay?',
              value: RawDateRange(
                DateTime(2026, 12, 28),
                DateTime(2026, 12, 30),
              ),
              firstDate: DateTime(2026),
              lastDate: DateTime(2026, 12, 31),
              onChanged: (_) {},
            ),
            width: width,
            text: text,
            direction: direction,
          );
          final wells = tester.widgetList(find.byType(CivicWell)).length;
          expect(wells, 2);
          final well = tester.getRect(find.byType(CivicWell).first);
          final other = tester.getRect(find.byType(CivicWell).last);
          final button = tester.getRect(find.byType(CivicButton));
          // The two wells on one line stand one height.
          if (other.top < well.bottom) {
            expect(other.height, moreOrLessEquals(well.height, epsilon: .5));
          }
          final inRow = button.top < other.bottom;
          if (width == 1440) expect(inRow, isTrue, reason: 'not in a row');
          if (inRow) {
            expect(button.height, moreOrLessEquals(other.height, epsilon: .5));
            expect(button.top, moreOrLessEquals(other.top, epsilon: .5));
          }
        }, variant: _platforms);
      }
    }
  }
}
