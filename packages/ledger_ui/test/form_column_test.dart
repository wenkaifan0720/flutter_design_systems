// Ledger's form column: on a page of a form every field, words, a select, a
// sum and a date, stands on one width, the column's, and the column keeps
// to a form's measure on a wide window (LedgerLayout.formMeasure, a sheet's
// 640), at the start of the page.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

Future<void> _pump(WidgetTester t, double width) async {
  t.view.physicalSize = Size(width, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      builder: (context, _) => LedgerHost(
        brightness: Brightness.light,
        child: Navigator(
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (_, _, _) => LedgerScreen.form(
              topBar: const LedgerTopBar(title: 'Add a book'),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LedgerTextField(key: Key('title'), labelText: 'Title'),
                  LedgerSelect<String>(
                    key: const Key('shelf'),
                    labelText: 'Shelf',
                    value: 'read',
                    items: const [
                      LedgerSelectItem(value: 'read', label: 'Read'),
                      LedgerSelectItem(value: 'want', label: 'Want to read'),
                    ],
                    onChanged: (_) {},
                  ),
                  const LedgerTextField(
                    key: Key('price'),
                    labelText: 'Price',
                    prefix: r'$',
                  ),
                  LedgerDatePicker(
                    key: const Key('date'),
                    labelText: 'Date started',
                    value: null,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  for (final width in const [390.0, 800.0, 1440.0]) {
    testWidgets('at $width every field stands on the column\'s width', (
      tester,
    ) async {
      await _pump(tester, width);
      // Each field as drawn: its rule's frame (the date's leader line), not
      // the slot it is laid out in.
      Rect drawn(String key, String part) => tester.getRect(
        find
            .descendant(
              of: find.byKey(Key(key)),
              matching: find.byWidgetPredicate(
                (w) => w.runtimeType.toString() == part,
              ),
            )
            .first,
      );
      final title = drawn('title', 'LedgerFieldFrame');
      for (final (key, part) in const [
        ('shelf', 'LedgerFieldFrame'),
        ('price', 'LedgerFieldFrame'),
        ('date', 'LedgerLeaderLine'),
      ]) {
        final rect = drawn(key, part);
        expect(rect.left, moreOrLessEquals(title.left), reason: key);
        expect(rect.width, moreOrLessEquals(title.width), reason: key);
      }
      expect(title.width, lessThanOrEqualTo(LedgerLayout.formMeasure));
      if (width >= 1440) {
        expect(title.width, LedgerLayout.formMeasure);
      }
    });
  }

  testWidgets("at 1440 a form's footer acts keep to its column", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        localizationsDelegates: const [RawWidgetsLocalizations.delegate],
        builder: (context, _) => LedgerHost(
          brightness: Brightness.light,
          child: Navigator(
            onGenerateRoute: (_) => PageRouteBuilder<void>(
              pageBuilder: (_, _, _) => const LedgerScreen.form(
                topBar: LedgerTopBar(title: 'Change book'),
                footer: LedgerButton.filled(
                  'Save changes',
                  onPressed: null,
                  expand: true,
                ),
                body: LedgerTextField(key: Key('title'), labelText: 'Title'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final field = tester.getRect(find.byKey(const Key('title')));
    final save = tester.getRect(find.byType(LedgerButton));
    expect(save.left, moreOrLessEquals(field.left));
    expect(save.right, lessThanOrEqualTo(field.right + .5));
  });
}
