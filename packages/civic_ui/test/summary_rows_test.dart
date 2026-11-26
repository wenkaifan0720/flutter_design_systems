// In a summary list each row's question stands as far under the rule above
// it as its last words stand over its own rule. Stacked (under 560), a row
// with a Change link makes room for the link's target out of its padding;
// a row without one has no target, so it keeps its padding whole (it stood
// 6 nearer its rule than its neighbours on the 40 floor).
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _pump(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  CivicSummaryRow row(String label, String answer, {bool change = true}) =>
      CivicSummaryRow(
        label: label,
        value: Text(answer),
        actionLabel: change ? 'Change' : null,
        onActionPressed: change ? () {} : null,
      );
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, navigator) =>
          CivicTheme(data: CivicThemeData.light(), child: navigator!),
      home: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: width - 32,
            child: CivicSummaryList(
              rows: [
                row('Name', 'Amara Okafor'),
                row('Reference', 'HDJ2123F', change: false),
                row('Date of birth', '5 January 1978'),
                row('Council tax band', 'Band C', change: false),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Rect _row(WidgetTester tester, String label) => tester.getRect(
  find
      .ancestor(of: find.text(label), matching: find.byType(DecoratedBox))
      .first,
);

void main() {
  for (final (name, width) in const [('stacked', 390.0), ('wide', 900.0)]) {
    testWidgets('$name, a row without a Change link stands its answer as far '
        'over its rule as its question under the rule above', (tester) async {
      await _pump(tester, width);
      for (final (label, answer) in const [
        ('Reference', 'HDJ2123F'),
        ('Council tax band', 'Band C'),
      ]) {
        // Wide, the question and the answer share a baseline: the row's
        // words reach from the higher top to the lower bottom of the two.
        final row = _row(tester, label);
        final words = tester
            .getRect(find.text(label))
            .expandToInclude(tester.getRect(find.text(answer)));
        final over = words.top - row.top;
        final under = row.bottom - words.bottom;
        expect(under, moreOrLessEquals(over, epsilon: .01), reason: label);
      }
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }

  testWidgets('stacked, the rows keep their questions the same way under '
      'their rules, and a Change row keeps its link', (tester) async {
    await _pump(tester, 390);
    final tops = [
      for (final label in const [
        'Name',
        'Reference',
        'Date of birth',
        'Council tax band',
      ])
        tester.getRect(find.text(label)).top - _row(tester, label).top,
    ];
    for (final top in tops) {
      expect(top, moreOrLessEquals(tops.first, epsilon: .01));
    }
    // A Change row: the link's words stand under the answer, the rule under
    // its underline as far as the question under the rule above.
    final name = _row(tester, 'Name');
    final change = tester.getRect(find.text('Change').first);
    expect(
      change.top,
      greaterThan(tester.getRect(find.text('Amara Okafor')).bottom - .01),
    );
    // (The link's line box stands a twentieth of a pixel off the body's.)
    expect(
      name.bottom - change.bottom - 4,
      moreOrLessEquals(tops.first, epsilon: .1),
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
