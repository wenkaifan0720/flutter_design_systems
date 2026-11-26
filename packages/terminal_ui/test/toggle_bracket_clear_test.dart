// A toggle group's brackets keep clear of a chosen end cell's fill: the
// stem stands at the cell's outer third, its arms a third of a cell short of
// the fill, as the rule between two cells is.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  testWidgets("the brackets' arms stand clear of the chosen end's fill", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TermTheme(
          data: TermThemeData.light(),
          child: Center(
            child: TermToggleGroup<String>(
              options: const ['light', 'dark', 'system'],
              selected: const {'light'},
              labelOf: (v) => v,
              onSelectionChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    final painter = tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byType(TermToggleGroup<String>),
            matching: find.byType(CustomPaint),
          ),
        )
        .map((p) => p.painter)
        .whereType<TermBracketPainter>()
        .single;
    // The square bracket's arm runs a third of a cell in from its stem.
    final armEnd = painter.stemAt + 0.32;
    expect(1 - armEnd, greaterThanOrEqualTo(0.3));
  });
}
