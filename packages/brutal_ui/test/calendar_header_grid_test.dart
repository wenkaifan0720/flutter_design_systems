// A calendar's header is a row of the day grid: the way back stands over
// the first column, the way on over the last, the month's name over the five
// between, on the grid's rules, from the table's top to the weekdays' row.
// Its cells stood a fixed width, off the grid's columns, and 1 below the
// table's top (the arrows' tap target is taller than a cell).
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  double width = 390,
  double height = 844,
  TextDirection direction = TextDirection.ltr,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) => Directionality(
        textDirection: direction,
        child: BrutalTheme(
          data: brightness == Brightness.light
              ? BrutalThemeData.light()
              : BrutalThemeData.dark(),
          child: BrutalToaster(child: navigator!),
        ),
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

// A cell of the table: the nearest box round [inside] with a height of its
// own.
Rect _cell(WidgetTester tester, Finder inside) => tester.getRect(
  find
      .ancestor(
        of: inside,
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.height != null && w.width == null,
        ),
      )
      .first,
);

void main() {
  for (final width in [320.0, 358.0, 420.0]) {
    for (final direction in TextDirection.values) {
      testWidgets('the header stands on the day grid at ${width.round()}, '
          '${direction.name}', (tester) async {
        await _pump(
          tester,
          Center(
            child: SizedBox(
              width: width,
              child: BrutalCalendar(
                firstDate: DateTime(2026),
                lastDate: DateTime(2027, 12, 31),
                currentDate: DateTime(2026, 11, 2),
                selectedDate: DateTime(2026, 11, 20),
                onDateChanged: (_) {},
              ),
            ),
          ),
          direction: direction,
        );
        // The second week, 8 to 14 November: a day in each column.
        final columns = [
          for (var d = 8; d <= 14; d++) _cell(tester, find.text('$d')),
        ]..sort((a, b) => a.left.compareTo(b.left));
        final back = _cell(tester, find.byIcon(LucideIcons.chevronLeft));
        final on = _cell(tester, find.byIcon(LucideIcons.chevronRight));
        final name = _cell(tester, find.text('November 2026'));
        final rtl = direction == TextDirection.rtl;
        final first = rtl ? columns.last : columns.first;
        final last = rtl ? columns.first : columns.last;
        for (final (part, column) in [(back, first), (on, last)]) {
          expect(part.left, moreOrLessEquals(column.left, epsilon: .5));
          expect(part.right, moreOrLessEquals(column.right, epsilon: .5));
        }
        expect(name.left, moreOrLessEquals(columns[1].left, epsilon: .5));
        expect(name.right, moreOrLessEquals(columns[5].right, epsilon: .5));
        // Top to bottom: from the table's top to the weekdays' row.
        final table = tester.getRect(find.byType(BrutalCalendar));
        final weekdays = _cell(tester, find.text('SU'));
        for (final part in [back, name, on]) {
          expect(part.top, moreOrLessEquals(table.top, epsilon: .25));
          expect(part.bottom, moreOrLessEquals(weekdays.top, epsilon: .25));
        }
      });
    }
  }
}
