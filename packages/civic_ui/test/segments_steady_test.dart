// A segmented control's and a toggle group's layout never depends on what
// is chosen: a chosen face's tick has its room in every face, so the band
// stands in a row or stacks by its answers and the width alone (it flipped
// between the two as a long answer was chosen, the tick widening it).
import 'package:civic_ui/civic_parts.dart' show RenderCivicFitRow, CivicFitRow;
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

const _segments = [
  CivicSegment(value: 'week', label: 'Week'),
  CivicSegment(value: 'fortnight', label: 'Every fortnight'),
  CivicSegment(value: 'month', label: 'Month'),
];

Future<RenderCivicFitRow> _pump(
  WidgetTester tester,
  Widget Function(Set<String> chosen) band,
  Set<String> chosen, {
  double width = 1000,
  double text = 1,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(text)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: CivicTheme(
          data: CivicThemeData.light(),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: band(chosen)),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.renderObject<RenderCivicFitRow>(find.byType(CivicFitRow));
}

void main() {
  // Each band, and the answers it can have chosen.
  final bands = <String, (Widget Function(Set<String>), List<Set<String>>)>{
    'segmented control': (
      (chosen) => CivicSegmentedControl<String>(
        segments: _segments,
        value: chosen.single,
        onChanged: (_) {},
      ),
      [
        for (final s in _segments) {s.value},
      ],
    ),
    'toggle group': (
      (chosen) => CivicToggleGroup<String>(
        segments: _segments,
        selected: chosen,
        onSelectionChanged: (_) {},
      ),
      [
        <String>{},
        {'fortnight'},
        {'week', 'month'},
        {for (final s in _segments) s.value},
      ],
    ),
  };
  for (final MapEntry(key: name, value: (band, choices)) in bands.entries) {
    for (final text in [1.0, 2.0]) {
      testWidgets('a $name stands the same whichever answer is chosen '
          '(text ×${text.round()})', (tester) async {
        final needs = <String, double>{};
        for (final chosen in choices) {
          final row = await _pump(tester, band, chosen, text: text);
          needs['$chosen'] = row.getMaxIntrinsicWidth(double.infinity);
        }
        expect(
          needs.values.toSet(),
          hasLength(1),
          reason: 'the width the row needs, by the answer chosen: $needs',
        );
        // At a width the row just fits, and one it just misses, every
        // answer stands the same way.
        final need = needs.values.first;
        for (final width in [need + 1, need - 1]) {
          final stacked = <bool>{};
          for (final chosen in choices) {
            final row = await _pump(
              tester,
              band,
              chosen,
              width: width,
              text: text,
            );
            stacked.add(row.stacked);
          }
          expect(stacked, hasLength(1), reason: 'at $width wide');
        }
      });
    }
  }
}
