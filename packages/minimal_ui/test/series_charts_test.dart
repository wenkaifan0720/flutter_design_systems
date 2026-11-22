// The series charts' box: its origin's corner, its top figure, its rules, its
// thinned labels, its loading and empty states.
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/chart_host.dart';

/// What a chart's painter drew: its text boxes, its rules and its fills,
/// and the box it drew them in.
({List<Rect> texts, List<(Offset, Offset)> lines, List<Rect> fills, Size size})
_drawn(WidgetTester tester, Finder chart) {
  final plot = find
      .descendant(of: chart, matching: find.byType(CustomPaint))
      .first;
  final texts = <Rect>[];
  final lines = <(Offset, Offset)>[];
  final fills = <Rect>[];
  expect(
    plot,
    paints..everything((method, args) {
      if (method == #drawParagraph) {
        final p = args[0] as ui.Paragraph;
        texts.add((args[1] as Offset) & Size(p.maxIntrinsicWidth, p.height));
      } else if (method == #drawLine) {
        lines.add((args[0] as Offset, args[1] as Offset));
      } else if (method == #drawPath &&
          (args[1] as Paint).style == PaintingStyle.fill) {
        fills.add((args[0] as Path).getBounds());
      }
      return true;
    }),
  );
  return (texts: texts, lines: lines, fills: fills, size: tester.getSize(plot));
}

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'];

void main() {
  group('series charts', () {
    const pro = MinimalChartSeries('Pro', [12, 18, 15, 22, 28, 19, 24]);
    const free = MinimalChartSeries('Free', [30, 26, 34, 31, 38, 42, 40]);
    const revenue = MinimalChartSeries('Revenue', [
      4200,
      4800,
      4600,
      5900,
      6400,
      7100,
      6900,
      8200,
    ]);

    testWidgets('every figure and label stands inside the chart, the lowest '
        'figure clear of the labels', (tester) async {
      for (final scale in [1.0, 1.3]) {
        await tester.pumpWidget(
          chartHost(
            const SizedBox(
              width: 700,
              child: MinimalLineChart(series: [pro, free], labels: _days),
            ),
            scale: scale,
          ),
        );
        final drawn = _drawn(tester, find.byType(MinimalLineChart));
        final box = Offset.zero & drawn.size;
        for (final text in drawn.texts) {
          // The top figure, centred on the top rule, stays inside the
          // chart's top edge, never over it into whatever is above.
          expect(text.top, greaterThanOrEqualTo(box.top - 0.01));
          expect(text.bottom, lessThanOrEqualTo(box.bottom + 0.01));
          expect(text.left, greaterThanOrEqualTo(box.left - 0.5));
          expect(text.right, lessThanOrEqualTo(box.right + 0.5));
        }
        final labelTop = drawn.texts
            .map((r) => r.top)
            .reduce((a, b) => a > b ? a : b);
        final figures = drawn.texts.where((r) => r.top < labelTop - 0.5);
        final lowest = figures
            .map((r) => r.bottom)
            .reduce((a, b) => a > b ? a : b);
        // "0" stands on its rule; "Mon" hangs under it: the corner where
        // the scale meets the labels keeps its air.
        expect(labelTop - lowest, greaterThanOrEqualTo(4), reason: '$scale');
      }
    });

    testWidgets('the rules run as far as the fill, either way round', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          chartHost(
            const SizedBox(
              width: 700,
              child: MinimalAreaChart(series: [revenue], labels: _months),
            ),
            direction: direction,
          ),
        );
        final drawn = _drawn(tester, find.byType(MinimalAreaChart));
        final from = drawn.lines
            .map((l) => l.$1.dx < l.$2.dx ? l.$1.dx : l.$2.dx)
            .reduce((a, b) => a < b ? a : b);
        final to = drawn.lines
            .map((l) => l.$1.dx > l.$2.dx ? l.$1.dx : l.$2.dx)
            .reduce((a, b) => a > b ? a : b);
        final fill = drawn.fills.single;
        expect(fill.left, closeTo(from, 0.5), reason: direction.name);
        expect(fill.right, closeTo(to, 0.5), reason: direction.name);
      }
    });

    testWidgets('thinned labels stand at evenly spaced points, first and '
        'last kept', (tester) async {
      await tester.pumpWidget(
        chartHost(
          // Room for about half the months.
          const SizedBox(
            width: 228,
            child: MinimalAreaChart(series: [revenue], labels: _months),
          ),
        ),
      );
      final drawn = _drawn(tester, find.byType(MinimalAreaChart));
      final labelTop = drawn.texts
          .map((r) => r.top)
          .reduce((a, b) => a > b ? a : b);
      final centres = [
        for (final r in drawn.texts)
          if (r.top >= labelTop - 0.5) r.center.dx,
      ]..sort();
      // The rules run from the first point to the last.
      final from = drawn.lines
          .map((l) => l.$1.dx)
          .reduce((a, b) => a < b ? a : b);
      final to = drawn.lines
          .map((l) => l.$2.dx)
          .reduce((a, b) => a > b ? a : b);
      final last = _months.length - 1;
      final pitch = (to - from) / last;
      final picks = [for (final c in centres) ((c - from) / pitch).round()];
      for (var i = 0; i < centres.length; i++) {
        expect(centres[i], closeTo(from + picks[i] * pitch, 0.5));
      }
      final m = picks.length;
      expect(m, inInclusiveRange(2, last), reason: 'thinned: $picks');
      expect(picks, [for (var i = 0; i < m; i++) (i * last / (m - 1)).round()]);
    });

    testWidgets("loading and empty charts take the loaded chart's box", (
      tester,
    ) async {
      for (final scale in [1.0, 1.3]) {
        await tester.pumpWidget(
          chartHost(
            const SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MinimalLineChart(series: [pro], labels: _days, height: 96),
                  MinimalLineChart(series: [], height: 96, loading: true),
                  MinimalLineChart(series: [], height: 96, emptyLabel: 'None'),
                ],
              ),
            ),
            scale: scale,
          ),
        );
        final charts = find.byType(MinimalLineChart);
        final loaded = tester.getSize(charts.at(0));
        expect(tester.getSize(charts.at(1)), loaded, reason: '$scale');
        expect(tester.getSize(charts.at(2)), loaded, reason: '$scale');
        // The block fills it, labels' band and all: nothing blank below.
        expect(
          tester.getSize(find.byType(MinimalSkeleton)).height,
          loaded.height,
          reason: '$scale',
        );
        // The empty chart's last rule is its bottom edge.
        final empty = _drawn(tester, charts.at(2));
        final lowest = empty.lines
            .map((l) => l.$1.dy)
            .reduce((a, b) => a > b ? a : b);
        expect(lowest, closeTo(empty.size.height, 1), reason: '$scale');
      }
    });
  });
}
