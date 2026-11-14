import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/chart.dart'
    show NeumorphicChart, NeumorphicChartKind;

import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);
  testWidgets('gaps, zero observations and target bands draw different data', (
    tester,
  ) async {
    final key = GlobalKey();
    Future<Uint8List> pixels(
      List<double?> values, {
      NeumorphicChartBand? band,
    }) async {
      await tester.pumpWidget(
        neumorphicApp(
          Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 320,
                child: NeumorphicChart(
                  label: 'Sleep',
                  series: [NeumorphicChartSeries('Hours', values)],
                  band: band,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final plot = tester
          .renderObjectList<RenderCustomPaint>(find.byType(CustomPaint))
          .singleWhere((r) => r.size.height == 180 && r.size.width > 100);
      final origin = plot.localToGlobal(Offset.zero, ancestor: boundary);
      return (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final rgba = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final bytes = BytesBuilder();
        for (
          var y = origin.dy.round();
          y < origin.dy.round() + plot.size.height.round();
          y++
        ) {
          final start = (y * image.width + origin.dx.round()) * 4;
          bytes.add(rgba.sublist(start, start + plot.size.width.round() * 4));
        }
        final data = bytes.takeBytes();
        image.dispose();
        return data;
      }))!;
    }

    final missing = await pixels([7, null, 8]);
    final zero = await pixels([7, 0, 8]);
    final range = await pixels([
      7,
      null,
      8,
    ], band: const NeumorphicChartBand(6, 8));
    expect(
      missing,
      isNot(orderedEquals(zero)),
      reason: 'A missing observation must not become zero or connect across the gap.',
    );
    expect(
      missing,
      isNot(orderedEquals(range)),
      reason: 'The target interval must be drawn behind the observations.',
    );
    expect(tester.takeException(), isNull);
  }, tags: ['goldens']);
  testWidgets(
    'in-place data changes repaint and all series share the spoken chart',
    (tester) async {
      final handle = tester.ensureSemantics();
      try {
        final values = <double?>[-2, null, 4];
        Widget chart() => neumorphicApp(
          NeumorphicChart(
            label: 'Balance',
            series: [
              NeumorphicChartSeries('One', values),
              const NeumorphicChartSeries('Two', [1, 2, 3]),
            ],
            format: (v) => '${v.toInt()} units',
          ),
        );
        await tester.pumpWidget(chart());
        expect(
          tester.getSemantics(find.bySemanticsLabel('Balance')).value,
          contains('-2 units, 4 units'),
        );
        final before = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((w) => w.painter)
            .whereType<CustomPainter>()
            .toList();
        values[2] = 3;
        await tester.pumpWidget(chart());
        final after = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((w) => w.painter)
            .whereType<CustomPainter>()
            .toList();
        expect([
          for (var i = 0; i < after.length; i++)
            after[i].shouldRepaint(before[i]),
        ], contains(true));
        expect(
          tester.getSemantics(find.bySemanticsLabel('Balance')).value,
          contains('Two: 1 units, 2 units, 3 units'),
        );
        expect(tester.takeException(), isNull);
      } finally {
        handle.dispose();
      }
    },
  );
  for (final kind in NeumorphicChartKind.values) {
    check(
      'multi-series ${kind.name}',
      () => NeumorphicChart(
        label: 'Balance',
        kind: kind,
        labels: const ['Monday', 'Tuesday', 'Wednesday'],
        band: const NeumorphicChartBand(-2, 4, label: 'Target interval'),
        series: const [
          NeumorphicChartSeries(longLine, [-4, null, 8]),
          NeumorphicChartSeries('Second series', [3, 2, -3]),
        ],
      ),
    );
  }
  testWidgets('no finite observations shows the empty state', (tester) async {
    await tester.pumpWidget(
      neumorphicApp(
        const NeumorphicChart(
          label: 'Reading',
          series: [
            NeumorphicChartSeries('Missing', [
              null,
              double.nan,
              double.infinity,
            ]),
          ],
        ),
      ),
    );
    expect(find.byType(NeumorphicEmptyState), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  const days = ['Mo', 'Tu', 'We', 'Th', 'Fr'];
  for (final kind in [NeumorphicChartKind.line, NeumorphicChartKind.bar]) {
    for (final width in [342.0, 680.0]) {
      testWidgets(
        '${kind.name} at $width: each axis label is centred on its ${kind == NeumorphicChartKind.bar ? 'bar' : 'point'}',
        (tester) async {
          tester.view.physicalSize = const Size(1024, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            neumorphicApp(
              Center(
                child: SizedBox(
                  width: width,
                  child: NeumorphicChart(
                    label: 'Steps',
                    kind: kind,
                    labels: days,
                    series: const [
                      NeumorphicChartSeries('This week', [3, 5, 4, 6, 2]),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final plot = tester.getRect(
            find.byWidgetPredicate(
              (w) =>
                  w is CustomPaint &&
                  w.painter.runtimeType.toString() == '_ChartPainter',
            ),
          );
          // The painter's own scale: the plot is its box less 4 on each side.
          final area = plot.deflate(4);
          for (final (i, day) in days.indexed) {
            final x = kind == NeumorphicChartKind.bar
                ? area.left + area.width / days.length * (i + .5)
                : area.left + area.width * i / (days.length - 1);
            final paragraph = tester.renderObject<RenderParagraph>(
              find.text(day),
            );
            final boxes = paragraph.getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: day.length),
            );
            final ink = boxes
                .map((b) => b.toRect())
                .reduce((a, b) => a.expandToInclude(b));
            final centre = paragraph.localToGlobal(ink.center).dx;
            expect(centre, moreOrLessEquals(x, epsilon: 1), reason: day);
          }
          final key = tester.widget<CustomPaint>(
            find.byWidgetPredicate(
              (w) =>
                  w is CustomPaint &&
                  w.painter.runtimeType.toString() == '_SeriesKeyPainter',
            ),
          );
          // Bars are keyed by a square in their ink; lines by a stroke.
          expect(
            (key.painter as dynamic).bar as bool,
            kind == NeumorphicChartKind.bar,
          );
        },
      );
    }
  }
}
