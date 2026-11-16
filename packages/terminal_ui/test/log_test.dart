// The run's log wraps a line longer than its pane on the grid rather than
// cutting it: every row's words fit, and every line keeps its number. In
// the real faces, so a word is as wide as its cells.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

// The example's screens are the ones under test.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/slipway.dart';
import '../example/lib/kit_gallery/slipway_pages.dart';
import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  testWidgets('a row ends after a space past its indent, a token whole', (
    tester,
  ) async {
    late TermGrid grid;
    await tester.pumpWidget(
      MaterialApp(
        home: TermTheme(
          data: TermThemeData.dark(),
          child: Builder(
            builder: (context) {
              grid = context.termGrid;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    const line = '  const cached = cache.get("token");';
    final rows = [
      for (final (start, end) in logRows(grid, line, 24, 22))
        line.substring(start, end),
    ];
    expect(rows, ['  const cached = ', 'cache.get("token");']);
    // A word longer than a row is still cut, as a terminal cuts it.
    expect(logRows(grid, 'x' * 30, 24, 22), [(0, 24), (24, 30)]);
    // A path longer than a row ends it after a `/`, its parts whole.
    const path = '/work/atlas-api/src';
    expect(
      [
        for (final (start, end) in logRows(grid, path, 12, 12))
          path.substring(start, end),
      ],
      ['/work/', 'atlas-api/', 'src'],
    );
  });

  for (final width in const [390.0, 768.0, 1440.0]) {
    testWidgets('the log wraps and numbers its lines at ${width.toInt()}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        // The failing run's whole log: tiled at a desk, alone elsewhere.
        slipwayApp(Brightness.dark, place: SlipwayPlace.desk),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final log = find.byType(LogPane).first;
      final rows = find.descendant(of: log, matching: find.byType(RichText));
      expect(rows, findsWidgets);
      for (final element in rows.evaluate()) {
        final box = element.renderObject! as RenderBox;
        final words = (element.widget as RichText).text.toPlainText();
        expect(
          box.getMaxIntrinsicWidth(double.infinity),
          lessThanOrEqualTo(box.size.width + 0.5),
          reason: '"$words" is cut',
        );
      }
      for (var i = 1; i <= slipwayLog.length; i++) {
        expect(
          find.descendant(of: log, matching: find.text('$i')),
          findsOneWidget,
        );
      }
    });
  }
}
