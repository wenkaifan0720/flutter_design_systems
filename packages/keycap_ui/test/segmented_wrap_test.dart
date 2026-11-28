// A row of segmented keys too wide for its line reflows onto as few rows
// as hold the keys, balanced (four keys: two and two, not three and one),
// each row sharing the line's width below 600; a row that fits stays one
// row. A Density row at 390 (Auto, Compact, Comfortable,
// Standard) wrapped three and one, the first row short of the edge.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';

const _density = ['Auto', 'Compact', 'Comfortable', 'Standard'];
const _mode = ['System', 'Light', 'Dark'];

Future<void> _phone(
  WidgetTester tester,
  List<String> labels, {
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: direction,
          child: KeycapHost(brightness: Brightness.light, child: page!),
        ),
      ),
      home: KeycapScreen(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KeycapField(
              labelText: 'Density',
              child: KeycapSegmentedButton<String>(
                key: const ValueKey('row'),
                segments: [
                  for (final l in labels) KeycapSegment(value: l, label: l),
                ],
                selected: {labels.first},
                onSelectionChanged: (_) {},
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

// Each key's box, in the row's order.
List<Rect> _keys(WidgetTester tester) => [
  for (final e
      in find
          .descendant(
            of: find.byKey(const ValueKey('row')),
            matching: find.byType(KeycapRowKey),
          )
          .evaluate())
    tester.getRect(find.byElementPredicate((x) => x == e)),
];

// The keys row by row, by their tops.
List<List<Rect>> _rows(List<Rect> keys) {
  final rows = <List<Rect>>[];
  for (final k in keys) {
    if (rows.isEmpty ||
        (k.center.dy - rows.last.first.center.dy).abs() > k.height / 2) {
      rows.add([k]);
    } else {
      rows.last.add(k);
    }
  }
  return rows;
}

void main() {
  setUpAll(keycapLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets('at 390 four keys too wide for one row stand two and two, '
        'each row the line\'s width (${direction.name})', (tester) async {
      await _phone(tester, _density, direction: direction);
      expect(tester.takeException(), isNull);
      final line = tester.getRect(find.byKey(const ValueKey('row')));
      final rows = _rows(_keys(tester));
      expect(rows.map((r) => r.length), [2, 2]);
      for (final row in rows) {
        final left = row.map((k) => k.left).reduce((a, b) => a < b ? a : b);
        final right = row.map((k) => k.right).reduce((a, b) => a > b ? a : b);
        expect(left, closeTo(line.left, 0.5));
        expect(right, closeTo(line.right, 0.5));
      }
      // Both rows' keys line up: two columns.
      expect(rows[1][0].left, closeTo(rows[0][0].left, 0.5));
      expect(rows[1][1].right, closeTo(rows[0][1].right, 0.5));
      // Each legend whole.
      for (final l in _density) {
        final p = tester.renderObject<RenderParagraph>(find.text(l));
        expect(
          p.getMaxIntrinsicWidth(double.infinity),
          lessThanOrEqualTo(p.size.width + 0.5),
          reason: l,
        );
      }
    });
  }

  testWidgets('a row that fits stays one row', (tester) async {
    await _phone(tester, _mode);
    expect(_rows(_keys(tester)).map((r) => r.length), [3]);
  });

  testWidgets('at 200% text the keys take more rows, still balanced', (
    tester,
  ) async {
    await _phone(tester, _density, scale: 2);
    expect(tester.takeException(), isNull);
    final counts = _rows(_keys(tester)).map((r) => r.length).toList();
    expect(counts.fold(0, (a, b) => a + b), 4);
    expect(counts.length, greaterThan(1));
    // As even as they go, the longer rows first.
    expect(counts.first - counts.last, inInclusiveRange(0, 1));
    for (var i = 1; i < counts.length; i++) {
      expect(counts[i], lessThanOrEqualTo(counts[i - 1]));
    }
  });
}
