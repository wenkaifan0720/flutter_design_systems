// On a phone the top bar's strip stands over the page: a field brought into
// view (focused after a form's check, say) stands under the strip, never
// behind it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

void main() {
  testWidgets('a field focused far up the page shows under the strip', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final title = FocusNode();
    addTearDown(title.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: LedgerTheme(
          data: LedgerThemeData.light(),
          child: LedgerScreen(
            topBar: const LedgerTopBar(title: 'New book'),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LedgerTextField(labelText: 'Title', focusNode: title),
                for (var i = 0; i < 24; i++)
                  LedgerTextField(labelText: 'Line ${i + 1}'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The strip: the bar at the window's top (the masthead under it heads
    // the page).
    final strip =
        [
              for (final bar in find.byType(LedgerTopBar).evaluate())
                bar.renderObject! as RenderBox,
            ]
            .map((box) => box.localToGlobal(Offset.zero) & box.size)
            .firstWhere((rect) => rect.top == 0);
    // Down the page, past the title.
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -2000),
    );
    await tester.pumpAndSettle();
    // Out of sight, behind the strip or above it.
    expect(
      tester.getRect(find.byType(EditableText).first).bottom,
      lessThanOrEqualTo(strip.bottom),
    );
    title.requestFocus();
    await tester.pumpAndSettle();
    final field = tester.getRect(find.byType(EditableText).first);
    expect(field.top, greaterThanOrEqualTo(strip.bottom));
    // Its name with it: the label above the line shows whole, with a
    // form's 24 of room under the strip.
    expect(
      tester.getRect(find.text('TITLE')).top,
      moreOrLessEquals(strip.bottom + 24, epsilon: 1),
    );
    // The page at rest stands where it stood: its first field under the strip.
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, 4000),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(EditableText).first).top,
      greaterThan(strip.bottom),
    );
  });
}
