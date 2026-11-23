// A pane's title set in a face wider than the grid's cell (here the test
// font, each glyph a whole em, where the grid counts 0.6 em) ends in an
// ellipsis by its drawn width, never cut mid-letter at the frame, and is read
// whole.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('a title in a face wider than the cell, 318 px at 2x, '
        '${direction.name}: an ellipsis, read whole', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: MediaQuery.withClampedTextScaling(
              minScaleFactor: 2,
              maxScaleFactor: 2,
              child: TermTheme(
                data: TermThemeData.light(),
                child: const Center(
                  child: SizedBox(
                    width: 318,
                    child: TermPane(
                      title: 'unsaved changes',
                      child: Text('ok'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final report = const DesignClipCheck(look: 'terminal')
          .check(tester.element(find.byType(TermPane)));
      expect(report.problems, isEmpty);
      expect(find.bySemanticsLabel(RegExp('unsaved changes')), findsOneWidget);
      semantics.dispose();
    });
  }
}
