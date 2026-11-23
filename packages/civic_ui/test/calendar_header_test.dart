// A calendar's header stands as even as the grid under it: the month's
// name centred on the month, between the way to the month before at the
// start and the way to the month after at the end, each arrow the same
// distance in from its edge. It stood lopsided: the name flush at the start
// and both arrows at the end, the name's words 13 from one edge and the
// last arrow's 28 from the other.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';
import 'screens_matrix.dart';

/// Where [paragraph]'s words stand on the screen.
Rect _ink(RenderParagraph paragraph) {
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(
      baseOffset: 0,
      extentOffset: paragraph.text.toPlainText().length,
    ),
  );
  final local = boxes
      .map((b) => b.toRect())
      .reduce((a, b) => a.expandToInclude(b));
  return local.shift(paragraph.localToGlobal(Offset.zero));
}

void main() {
  setUpAll(loadScreenFonts);

  for (final width in [390.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      testWidgets('the month stands centred between its arrows, at $width, '
          '${direction.name}', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final days = RawCalendarController(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          initialMonth: DateTime(2026, 11),
        );
        addTearDown(days.dispose);
        await tester.pumpWidget(
          kitApp(
            brightness: Brightness.light,
            direction: direction,
            home: Padding(
              padding: const EdgeInsets.all(CivicSpacing.s20),
              child: CivicCalendar(controller: days),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final calendar = find.byType(CivicCalendar);
        final wrap = tester.renderObject<RenderWrap>(
          find.descendant(of: calendar, matching: find.byType(Wrap)).first,
        );
        final box = wrap.firstChild!;
        final month = box.localToGlobal(Offset.zero) & box.size;
        final buttons = find.descendant(
          of: calendar,
          matching: find.byType(CivicIconButton),
        );
        expect(buttons, findsNWidgets(2));
        final a = tester.getRect(buttons.first);
        final b = tester.getRect(buttons.last);
        final (start, end) = direction == TextDirection.ltr ? (a, b) : (b, a);
        // The way back stands at the start, the way on at the end.
        expect(
          start.center.dx,
          lessThan(end.center.dx),
          reason: 'the arrows in reading order',
        );
        expect(
          start.left - month.left,
          moreOrLessEquals(month.right - end.right, epsilon: .5),
        );
        final icons = find.descendant(of: buttons, matching: find.byType(Icon));
        final ia = tester.getRect(icons.first), ib = tester.getRect(icons.last);
        final (startGlyph, endGlyph) = direction == TextDirection.ltr
            ? (ia, ib)
            : (ib, ia);
        expect(
          startGlyph.left - month.left,
          moreOrLessEquals(month.right - endGlyph.right, epsilon: .5),
        );
        // The month's name: the header's words, first in the calendar.
        final name = tester.renderObject<RenderParagraph>(
          find
              .descendant(
                of: find
                    .descendant(of: calendar, matching: find.byType(Text))
                    .first,
                matching: find.byType(RichText),
              )
              .first,
        );
        expect(
          _ink(name).center.dx,
          moreOrLessEquals(month.center.dx, epsilon: .5),
        );
      });
    }
  }
}
