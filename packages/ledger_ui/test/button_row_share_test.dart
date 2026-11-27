// A row of two acts on a desktop's form column stands side by side, each
// its share of the column: an act that expands keeps the measure alone, but
// in a row the row gives it its share.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

void main() {
  for (final width in [390.0, 1024.0, 1440.0]) {
    testWidgets('two acts share the form column at ${width.toInt()}', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: LedgerTheme(
            data: LedgerThemeData.light(),
            child: LedgerScreen.form(
              topBar: const LedgerTopBar(title: 'Middlemarch'),
              body: LedgerButtonRow(
                children: [
                  LedgerButton.filled('Edit', expand: true, onPressed: () {}),
                  LedgerButton(
                    'Delete',
                    expand: true,
                    isDestructiveAction: true,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final change = tester.getRect(
        find.ancestor(
          of: find.text('Edit'),
          matching: find.byType(LedgerButton),
        ),
      );
      final delete = tester.getRect(
        find.ancestor(
          of: find.text('Delete'),
          matching: find.byType(LedgerButton),
        ),
      );
      final row = tester.getRect(find.byType(LedgerButtonRow));
      // Side by side, on one line.
      expect(delete.top, change.top);
      // Each its share of the row, 12 between.
      expect(change.width, moreOrLessEquals((row.width - 12) / 2));
      expect(delete.width, moreOrLessEquals(change.width));
    });
  }
}
