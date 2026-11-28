// At 1440 a screen's footer keys line up with the page's content column,
// not the window's far corner. A form's key stands at the start of the
// form's column, as wide as its words, under the fields' start edge; a page's
// key spans the page's column, edge for edge with what the page holds. Both
// mirror in a right-to-left language.
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<(Rect key, Rect field)> _rects(
  WidgetTester tester, {
  required bool form,
  required TextDirection direction,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  const body = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [LedgerTextField(labelText: 'Title')],
  );
  final footer = LedgerButton.filled('Save book', onPressed: () {});
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => Directionality(
        textDirection: direction,
        child: LedgerHost(child: child!),
      ),
      home: form
          ? LedgerScreen.form(
              topBar: const LedgerTopBar(title: 'Add a book'),
              footer: footer,
              body: body,
            )
          : LedgerScreen(
              topBar: const LedgerTopBar(title: 'Add a book'),
              footer: footer,
              body: body,
            ),
    ),
  );
  await tester.pumpAndSettle();
  return (
    tester.getRect(find.byType(LedgerButton)),
    tester.getRect(find.byType(LedgerTextField)),
  );
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      "a form's key stands at the start of its column, ${direction.name}",
      (tester) async {
        final (key, field) = await _rects(
          tester,
          form: true,
          direction: direction,
        );
        if (direction == TextDirection.ltr) {
          expect(key.left, moreOrLessEquals(field.left));
        } else {
          expect(key.right, moreOrLessEquals(field.right));
        }
        expect(key.width, lessThan(field.width / 2));
        expect(field.width, moreOrLessEquals(LedgerLayout.formMeasure));
      },
    );

    testWidgets("a page's key spans the page's column, ${direction.name}", (
      tester,
    ) async {
      final (key, field) = await _rects(
        tester,
        form: false,
        direction: direction,
      );
      expect(key.left, moreOrLessEquals(field.left));
      expect(key.right, moreOrLessEquals(field.right));
    });
  }
}
