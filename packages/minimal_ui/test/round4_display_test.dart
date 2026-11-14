// Round 4's display fixes: the KPI strip's straight foot; the series
// charts' box (its origin's corner, its top figure, its rules, its thinned
// labels, its loading and empty states); every count's numerals on their
// fill; the night's skeleton and spinner track.
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

final MinimalThemeData _light = MinimalThemeData.preset(
  'standard',
  Brightness.light,
);

final MinimalThemeData _dark = MinimalThemeData.preset(
  'standard',
  Brightness.dark,
);

Widget _host(
  Widget child, {
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
  String preset = 'standard',
}) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset(preset, Brightness.light),
    dark: MinimalThemeData.preset(preset, Brightness.dark),
    brightness: brightness,
    child: MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: Directionality(textDirection: direction, child: navigator!),
    ),
  ),
  home: Scaffold(
    body: Center(
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    ),
  ),
);

double _contrast(Color a, Color b) {
  final x = a.computeLuminance() + 0.05;
  final y = b.computeLuminance() + 0.05;
  return x > y ? x / y : y / x;
}

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
  group('the KPI strip', () {
    testWidgets('a selected cell stands on one straight bar, clear of the '
        "strip's round corners", (tester) async {
      final corner = MinimalShapes.radiusOf(
        MinimalShapes.inset(_light.shapes.medium, _light.hairline),
      );
      for (final direction in TextDirection.values) {
        for (final picked in [0, 1, 2]) {
          await tester.pumpWidget(
            _host(
              SizedBox(
                width: 600,
                child: MinimalStatRow.joined(
                  children: [
                    for (var i = 0; i < 3; i++)
                      MinimalStat(
                        label: 'Cell $i',
                        value: '$i',
                        selected: i == picked,
                      ),
                  ],
                ),
              ),
              direction: direction,
            ),
          );
          await tester.pumpAndSettle();
          final cell = find.byType(MinimalStat).at(picked);
          final size = tester.getSize(cell);
          Rect? bar;
          // A paint keeps 8-bit channels; the theme's colours are floats.
          expect(
            cell,
            paints..something((method, args) {
              if (method != #drawRect) return false;
              final paint = args[1] as Paint;
              if (paint.color.toARGB32() != _light.foreground.toARGB32()) {
                return false;
              }
              bar = args[0] as Rect;
              return true;
            }),
          );
          final foot = bar!;
          final why = '${direction.name}, cell $picked';
          expect(
            foot.height,
            closeTo(MinimalStat.footWidth, 0.01),
            reason: why,
          );
          expect(foot.bottom, closeTo(size.height, 0.01), reason: why);
          final ltr = direction == TextDirection.ltr;
          final start = ltr ? foot.left : size.width - foot.right;
          final end = ltr ? size.width - foot.right : foot.left;
          // In the strip's bottom-start corner (the first cell) and its
          // bottom-end one (the last), the bar stands in by the corner's
          // radius; a middle cell's runs edge to edge.
          expect(start, closeTo(picked == 0 ? corner : 0, 0.01), reason: why);
          expect(end, closeTo(picked == 2 ? corner : 0, 0.01), reason: why);
        }
      }
    });
  });

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
          _host(
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
          // The top figure, centred on the top rule, no longer stands over
          // the chart's top edge (into whatever is above it).
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
          _host(
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
        _host(
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
          _host(
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

  group('badges', () {
    const tones = [
      ('12', MinimalTone.neutral),
      ('4', MinimalTone.primary),
      ('5', MinimalTone.success),
      ('6', MinimalTone.warning),
      ('3', MinimalTone.destructive),
    ];

    Container capsule(WidgetTester tester, String count) =>
        tester.widget<Container>(
          find
              .ancestor(of: find.text(count), matching: find.byType(Container))
              .first,
        );

    Color fillOf(Container box) => switch (box.decoration) {
      BoxDecoration(:final color?) => color,
      ShapeDecoration(:final color?) => color,
      _ => throw StateError('no fill'),
    };

    testWidgets("every count's numerals clear 4.5:1 on its fill, in every "
        'preset and either mode', (tester) async {
      for (final preset in MinimalThemeData.presets) {
        for (final brightness in Brightness.values) {
          final t = MinimalThemeData.preset(preset, brightness);
          await tester.pumpWidget(
            _host(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (count, tone) in tones)
                    MinimalBadge(count: int.parse(count), tone: tone),
                ],
              ),
              brightness: brightness,
              preset: preset,
            ),
          );
          // The host cross-fades between modes: read the settled colours.
          await tester.pumpAndSettle();
          for (final (count, tone) in tones) {
            final ink = tester.widget<Text>(find.text(count)).style!.color!;
            final fill = fillOf(capsule(tester, count));
            expect(
              _contrast(ink, fill),
              greaterThanOrEqualTo(4.5),
              reason: '$preset, ${brightness.name}, ${tone.name}',
            );
          }
          // A plain count is a neutral tag's: the muted fill in a hairline,
          // not a mid-grey capsule.
          final plain = capsule(tester, '12');
          expect(fillOf(plain), t.muted, reason: '$preset, $brightness');
          final rim = switch (plain.foregroundDecoration) {
            ShapeDecoration(:final OutlinedBorder shape) => shape.side,
            BoxDecoration(:final Border border) => border.top,
            _ => BorderSide.none,
          };
          expect(rim.color, t.border, reason: '$preset, $brightness');
          expect(rim.width, t.hairline, reason: '$preset, $brightness');
        }
      }
    });
  });

  group('by night', () {
    testWidgets("a skeleton and a spinner's track take the stronger "
        'hairline, clear of the ground', (tester) async {
      // Still, so the pulse and the turn let the host settle.
      MinimalMotion.animate = false;
      addTearDown(() => MinimalMotion.animate = true);
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [MinimalSkeleton(), MinimalCircularProgressIndicator()],
            ),
          ),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();
      final block = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(MinimalSkeleton),
              matching: find.byType(Container),
            )
            .first,
      );
      final fill = switch (block.decoration) {
        BoxDecoration(:final color?) => color,
        ShapeDecoration(:final color?) => color,
        _ => throw StateError('no fill'),
      };
      expect(fill, _dark.borderStrong);
      // At full strength and at the pulse's half (the hairline's grey was
      // 1.30:1 and 1.12:1 on the dark ground).
      expect(_contrast(fill, _dark.background), greaterThan(1.6));
      expect(
        _contrast(
          Color.alphaBlend(fill.withValues(alpha: 0.5), _dark.background),
          _dark.background,
        ),
        greaterThan(1.2),
      );
      // The spinner's track is the first ring it draws.
      expect(
        find
            .descendant(
              of: find.byType(MinimalCircularProgressIndicator),
              matching: find.byType(CustomPaint),
            )
            .first,
        paints..something(
          (method, args) =>
              method == #drawArc &&
              (args[4] as Paint).color.toARGB32() ==
                  _dark.borderStrong.toARGB32(),
        ),
      );
    });
  });
}
