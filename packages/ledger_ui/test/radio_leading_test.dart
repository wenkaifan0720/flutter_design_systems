// A radio's leading part stands between its ring and its words, 12 from
// each, on their line, in either direction, out of its name.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

const _swatch = ValueKey('swatch');

Future<void> _pump(WidgetTester tester, TextDirection direction) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: LedgerTheme(
          data: LedgerThemeData.light(),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: RadioGroup<String>(
              groupValue: 'quire',
              onChanged: (_) {},
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LedgerRadio<String>(
                    value: 'quire',
                    label: 'Quire',
                    leading: SizedBox.square(key: _swatch, dimension: 20),
                  ),
                  LedgerRadio<String>(value: 'slate', label: 'Slate'),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('the leading part stands between the ring and the words '
        '(${direction.name})', (tester) async {
      await _pump(tester, direction);
      final ltr = direction == TextDirection.ltr;
      final swatch = tester.getRect(find.byKey(_swatch));
      final words = tester.getRect(find.text('Quire'));
      final plain = tester.getRect(find.text('Slate'));
      expect(ltr ? words.left - swatch.right : swatch.left - words.right, 12);
      // Where a plain radio's words start, 12 after the ring.
      expect(ltr ? swatch.left : swatch.right, ltr ? plain.left : plain.right);
      expect(swatch.center.dy, moreOrLessEquals(words.center.dy, epsilon: 0.5));
    });
  }

  testWidgets("the leading part adds nothing to the radio's name", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, TextDirection.ltr);
    expect(find.bySemanticsLabel('Quire'), findsOneWidget);
    handle.dispose();
  });
}
