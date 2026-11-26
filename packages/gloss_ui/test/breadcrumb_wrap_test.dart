// A breadcrumb that wraps keeps each separator with the place it leads
// to: no row ends on a separator, at any width, in either reading
// direction (one used to end the first row, dangling); and its rows stand
// one touch target apart, the closest two rows of links can come.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  setUpAll(glossLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets('no row ends on a separator, $direction', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const places = ['Recipes', 'Mains', 'Weeknight', 'Lemon risotto'];
      var wrapped = 0;
      for (var width = 120.0; width <= 420; width += 6) {
        tester.view.physicalSize = Size(width + 48, 600);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, app) => GlossHost(
              theme: GlossThemeData.light(),
              darkTheme: GlossThemeData.dark(),
              brightness: Brightness.light,
              child: Directionality(textDirection: direction, child: app!),
            ),
            home: Align(
              alignment: AlignmentDirectional.topStart,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: width,
                  child: GlossBreadcrumb(
                    crumbs: [
                      for (final (i, p) in places.indexed)
                        GlossCrumb(
                          p,
                          onPressed: i < places.length - 1 ? () {} : null,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final separators = find.byIcon(
          direction == TextDirection.rtl
              ? LucideIcons.chevronLeft
              : LucideIcons.chevronRight,
        );
        expect(separators, findsNWidgets(places.length - 1));
        final first = tester.getRect(find.text(places.first)).center.dy;
        final last = tester.getRect(find.text(places.last)).center.dy;
        if (last > first + 1) wrapped++;
        final rows = <double>[];
        for (final p in places) {
          final y = tester.getRect(find.text(p)).center.dy;
          if (rows.every((r) => (r - y).abs() > 2)) rows.add(y);
        }
        rows.sort();
        for (var i = 1; i < rows.length; i++) {
          expect(
            rows[i] - rows[i - 1],
            moreOrLessEquals(40, epsilon: 0.5),
            reason: 'at $width row $i stands ${rows[i] - rows[i - 1]} below',
          );
        }
        for (var i = 1; i < places.length; i++) {
          final mark = tester.getRect(separators.at(i - 1)).center.dy;
          final place = tester.getRect(find.text(places[i])).center.dy;
          expect(
            (mark - place).abs(),
            lessThan(2),
            reason:
                'at $width the separator before ${places[i]} '
                'stands on another row',
          );
        }
      }
      expect(wrapped, greaterThan(0), reason: 'no width wrapped it');
    });
  }
}
