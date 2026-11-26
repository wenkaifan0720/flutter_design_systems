// A data table's select-all tick stands over the rows' ticks, and each
// heading over its column: a heading of words starts where its words do, a
// number's heading ends where its numbers do, to the pixel, in either
// reading direction (the tick stood 2 px toward the start, a number's
// heading 4 px past its numbers).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  setUpAll(glossLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets('the header tick stands over the row ticks, $direction', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(720, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = GlossTableController<String>(
        rows: const ['Lemon risotto', 'Green curry', 'Pea soup'],
        columns: const [GlossDataColumn<String>(id: 'dish', label: 'Dish')],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, app) => GlossHost(
            theme: GlossThemeData.light(),
            darkTheme: GlossThemeData.dark(),
            brightness: Brightness.light,
            child: Directionality(textDirection: direction, child: app!),
          ),
          home: Padding(
            padding: const EdgeInsets.all(24),
            child: GlossDataTable<String>(
              controller: controller,
              cell: (row, column) => row,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Each tick is a 20 px socket.
      final ticks = find.descendant(
        of: find.byType(GlossDataTable<String>),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 20 && w.height == 20,
        ),
      );
      expect(ticks, findsNWidgets(4));
      final header = tester.getRect(ticks.first).center.dx;
      for (var i = 1; i < 4; i++) {
        expect(
          tester.getRect(ticks.at(i)).center.dx,
          moreOrLessEquals(header, epsilon: 0.5),
          reason: 'row $i',
        );
      }
    });
  }

  for (final direction in TextDirection.values) {
    testWidgets('each heading stands over its column, $direction', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(720, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = GlossTableController<(String, String, int)>(
        rows: const [('Lemon risotto', 'Main', 35), ('Pea soup', 'Soup', 20)],
        columns: const [
          GlossDataColumn(id: 'dish', label: 'Dish'),
          GlossDataColumn(id: 'course', label: 'Course'),
          GlossDataColumn(id: 'minutes', label: 'Minutes', numeric: true),
        ],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, app) => GlossHost(
            theme: GlossThemeData.light(),
            darkTheme: GlossThemeData.dark(),
            brightness: Brightness.light,
            child: Directionality(textDirection: direction, child: app!),
          ),
          home: Padding(
            padding: const EdgeInsets.all(24),
            child: GlossDataTable<(String, String, int)>(
              controller: controller,
              cell: (row, column) => switch (column) {
                'dish' => row.$1,
                'course' => row.$2,
                _ => '${row.$3}',
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final ltr = direction == TextDirection.ltr;
      double start(String words) {
        final r = tester.getRect(find.text(words));
        return ltr ? r.left : r.right;
      }

      double end(String words) {
        final r = tester.getRect(find.text(words));
        return ltr ? r.right : r.left;
      }

      expect(
        start('Dish'),
        moreOrLessEquals(start('Lemon risotto'), epsilon: 0.5),
      );
      expect(start('Course'), moreOrLessEquals(start('Main'), epsilon: 0.5));
      expect(end('Minutes'), moreOrLessEquals(end('35'), epsilon: 0.5));
    });
  }
}
