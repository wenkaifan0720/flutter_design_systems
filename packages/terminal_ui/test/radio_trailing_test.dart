// A radio's trailing cells stand a cell after its label, on its line, in
// either direction, out of its name.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

const _cells = ValueKey('cells');

Future<void> _pump(WidgetTester tester, TextDirection direction) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: TermTheme(
          data: TermThemeData.dark(),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: RadioGroup<String>(
              groupValue: 'amber',
              onChanged: (_) {},
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TermRadio<String>(
                    value: 'amber',
                    label: 'Amber',
                    trailing: Text('██', key: _cells),
                  ),
                  TermRadio<String>(value: 'mono', label: 'Mono'),
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
    testWidgets('the trailing cells stand a cell after the label '
        '(${direction.name})', (tester) async {
      await _pump(tester, direction);
      final ltr = direction == TextDirection.ltr;
      final cells = tester.getRect(find.byKey(_cells));
      final words = tester.getRect(find.text('Amber'));
      final cell = tester.element(find.text('Amber')).termGrid.cellWidth;
      expect(
        ltr ? cells.left - words.right : words.left - cells.right,
        moreOrLessEquals(cell, epsilon: 0.01),
      );
      expect(cells.top, words.top);
    });
  }

  testWidgets('the trailing cells add nothing to the radio\'s name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, TextDirection.ltr);
    expect(find.bySemanticsLabel('Amber'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('█')), findsNothing);
    handle.dispose();
  });
}
