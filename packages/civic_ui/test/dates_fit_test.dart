// A calendar's month stands no wider than Material's (seven days of 56,
// wider only as far as larger text needs), from the start of its column,
// on a phone and a wide page, at the reader's usual, twice and three times
// the text, left to right and right to left. On a wide page a month
// stretched to the page spread its days 200 apart. Its words grow at most
// twice, as Material's calendar on a phone: at three times a phone's days
// broke mid-number ("1 / 0") and the month's name beside its arrows.
//
// A typed date's or time's figures grow at most twice, as Material's typed
// date: at three times the text a phone's well held them no more. The
// field's question keeps growing above them.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';
import 'screens_matrix.dart';
import 'words_whole.dart';

/// [child] on a page [width] wide, its text at [text] times, in [direction].
Future<void> _show(
  WidgetTester tester,
  Widget child, {
  required double width,
  required double text,
  required TextDirection direction,
}) async {
  tester.view.physicalSize = Size(width, 1600);
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

String _at(double width, double text, TextDirection direction) =>
    'at $width, text ×${text.toStringAsFixed(0)}, ${direction.name}';

void main() {
  setUpAll(loadScreenFonts);

  for (final width in [390.0, 1440.0]) {
    for (final text in [1.0, 2.0, 3.0]) {
      for (final direction in TextDirection.values) {
        testWidgets('a calendar month stands at most its width from the '
            'start, ${_at(width, text, direction)}', (tester) async {
          final days = DesignCalendarController(
            firstDate: DateTime(2026),
            lastDate: DateTime(2027, 12, 31),
            initialMonth: DateTime(2026, 11),
          );
          addTearDown(days.dispose);
          await _show(
            tester,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [CivicCalendar(controller: days)],
            ),
            width: width,
            text: text,
            direction: direction,
          );
          expect(tester.takeException(), isNull);
          final calendar = find.byType(CivicCalendar);
          final page = tester.getRect(calendar);
          final wrap = tester.renderObject<RenderWrap>(
            find.descendant(of: calendar, matching: find.byType(Wrap)).first,
          );
          final box = wrap.firstChild!;
          final month = box.localToGlobal(Offset.zero) & box.size;
          final widest = CivicCalendar.monthWidthOf(tester.element(calendar));
          if (text == 1) expect(widest, CivicCalendar.monthWidth);
          // As wide as the column where it is narrower, else its own width.
          expect(
            month.width,
            moreOrLessEquals(
              page.width < widest ? page.width : widest,
              epsilon: .5,
            ),
          );
          if (direction == TextDirection.ltr) {
            expect(month.left, moreOrLessEquals(page.left, epsilon: .5));
          } else {
            expect(month.right, moreOrLessEquals(page.right, epsilon: .5));
          }
          // The month's name, the weekdays and the days: at most twice.
          for (final p in tester.renderObjectList<RenderParagraph>(
            find.descendant(of: calendar, matching: find.byType(RichText)),
          )) {
            // An icon's glyph (the months' arrows) is no words.
            final words = p.text.toPlainText();
            if (words.runes.every((r) => r >= 0xE000 && r <= 0xF8FF)) continue;
            expect(
              p.textScaler.scale(10),
              moreOrLessEquals(10 * (text < 2 ? text : 2), epsilon: .01),
              reason:
                  '"${p.text.toPlainText()}" ${_at(width, text, direction)}',
            );
          }
          expectWordsWhole(
            tester,
            where: 'calendar ${_at(width, text, direction)}',
          );
        });
      }
    }
  }

  for (final width in [390.0, 1440.0]) {
    for (final text in [1.0, 2.0, 3.0]) {
      for (final direction in TextDirection.values) {
        testWidgets('typed dates and times fit their wells, their figures '
            'at most twice, ${_at(width, text, direction)}', (tester) async {
          await _show(
            tester,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CivicSpacing.s24,
              children: [
                CivicDatePicker(
                  labelText: 'Start',
                  value: DateTime(2026, 11, 24),
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2026, 12, 31),
                  onChanged: (_) {},
                ),
                CivicDatePicker(
                  labelText: 'End',
                  value: null,
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2026, 12, 31),
                  onChanged: (_) {},
                ),
                CivicDateRangePicker(
                  labelText: 'Stay',
                  value: DesignDateRange(
                    DateTime(2026, 12, 28),
                    DateTime(2026, 12, 30),
                  ),
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2026, 12, 31),
                  onChanged: (_) {},
                ),
                CivicTimeInput(
                  labelText: 'Arrival',
                  value: const DesignTimeOfDay(hour: 12, minute: 45),
                  onChanged: (_) {},
                ),
              ],
            ),
            width: width,
            text: text,
            direction: direction,
          );
          expect(tester.takeException(), isNull);
          final wells = find.byType(CivicWell);
          expect(wells, findsNWidgets(5));
          for (final well in wells.evaluate()) {
            final figures = tester
                .renderObjectList<RenderParagraph>(
                  find.descendant(
                    of: find.byElementPredicate((e) => identical(e, well)),
                    matching: find.byType(RichText),
                  ),
                )
                .toList();
            expect(figures, isNotEmpty);
            for (final p in figures) {
              expect(
                p.textScaler.scale(10),
                moreOrLessEquals(10 * (text < 2 ? text : 2), epsilon: .01),
                reason:
                    '"${p.text.toPlainText()}" ${_at(width, text, direction)}',
              );
            }
          }
          // The question keeps the reader's size.
          final question = tester.renderObject<RenderParagraph>(
            find.text('Start').first,
          );
          expect(question.textScaler.scale(10), moreOrLessEquals(10 * text));
          expectWordsWhole(
            tester,
            where: 'wells ${_at(width, text, direction)}',
          );
        });
      }
    }
  }
}
