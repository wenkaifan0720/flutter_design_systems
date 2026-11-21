import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

void main() {
  setUpAll(loadFaces);
  for (final direction in TextDirection.values) {
    testWidgets(
      'range values and day fills fit their cells at 2× ${direction.name}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        final selected = RawDateRange(
          DateTime(2026, 11, 9),
          DateTime(2026, 11, 14),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                textScaler: TextScaler.linear(2),
              ),
              child: Directionality(
                textDirection: direction,
                child: TermTheme(
                  data: TermThemeData.light(),
                  child: Center(
                    child: SizedBox(
                      width: 318,
                      child: TermDateRangePicker(
                        value: selected,
                        labelText: 'runs between',
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2028),
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final value = find.textContaining('2026-11-09');
        final words = tester.widget<Text>(value);
        expect(
          (words.data ?? '').replaceAll(RegExp(r'\s+'), ' '),
          '2026-11-09 → 2026-11-14',
        );
        final paragraph = tester.renderObject<RenderParagraph>(value);
        final end = (words.data ?? '').indexOf('2026-11-14') + 9;
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: end, extentOffset: end + 1),
        );
        expect(
          boxes,
          isNotEmpty,
          reason: 'the final digit of the end date is visible',
        );
        expect(boxes.last.right, lessThanOrEqualTo(paragraph.size.width + 0.1));
        await tester.tap(value);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final calendar = find.byType(TermCalendar);
        Rect faceOf(int n) {
          final day = find.descendant(
            of: calendar,
            matching: find.text(n.toString().padLeft(2)),
          );
          final block = tester
              .element(day)
              .findAncestorWidgetOfExactType<ColoredBox>()!;
          return tester.getRect(find.byWidget(block));
        }

        for (final (a, b) in [(8, 9), (13, 14)]) {
          final first = faceOf(a);
          final second = faceOf(b);
          expect(
            first.overlaps(second),
            isFalse,
            reason: 'days $a and $b overlap: $first / $second',
          );
          expect(first.width, greaterThanOrEqualTo(36));
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(TermCalendar), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
