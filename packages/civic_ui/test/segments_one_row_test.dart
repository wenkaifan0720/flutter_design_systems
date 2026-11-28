// Three one-word answers stay one row on a phone, and answers that need two
// rows split evenly. A Settings page's "System / Light / Dark" and "Added /
// Title / Author" stacked into three full-width faces at 390, three times as
// tall and read as three separate buttons; four answers wrapped 3 + 1.
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget band, double width) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CivicTheme(
        data: CivicThemeData.light(),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: band),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// The rows the labels stand on, top to bottom: how many labels each holds.
List<int> _rows(WidgetTester tester, List<String> labels) {
  final tops = <double, int>{};
  for (final label in labels) {
    final top = tester.getTopLeft(find.text(label)).dy.roundToDouble();
    tops.update(top, (n) => n + 1, ifAbsent: () => 1);
  }
  final keys = tops.keys.toList()..sort();
  return [for (final k in keys) tops[k]!];
}

Widget _segmented(List<String> labels) => CivicSegmentedControl<String>(
  segments: [for (final l in labels) CivicSegment(value: l, label: l)],
  value: labels.first,
  onChanged: (_) {},
);

Widget _toggles(List<String> labels) => CivicToggleGroup<String>(
  segments: [for (final l in labels) CivicSegment(value: l, label: l)],
  selected: {labels.first},
  onSelectionChanged: (_) {},
);

void main() {
  setUpAll(civicLoadFonts);

  // A 390 phone's column, inside the page's 16 margins.
  const phone = 358.0;
  for (final labels in [
    ['System', 'Light', 'Dark'],
    ['Added', 'Title', 'Author'],
  ]) {
    testWidgets('${labels.join(' / ')} stays one row on a phone', (
      tester,
    ) async {
      await _pump(tester, _segmented(labels), phone);
      expect(_rows(tester, labels), [3]);
      final band = tester.getSize(find.byType(CivicSegmentedControl<String>));
      expect(band.width, phone, reason: 'the band fills its column');
    });
  }

  const four = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  for (final (name, band) in [
    ('segmented control', _segmented(four)),
    ('toggle group', _toggles(four)),
  ]) {
    testWidgets('a $name that needs two rows splits them 2 + 2', (
      tester,
    ) async {
      // Too narrow for four, wide enough for two.
      await _pump(tester, band, 260);
      expect(_rows(tester, four), [2, 2]);
    });
  }

  testWidgets('answers that fit no two to a row stack, one to a row', (
    tester,
  ) async {
    await _pump(tester, _segmented(four), 150);
    expect(_rows(tester, four), [1, 1, 1, 1]);
  });
}
