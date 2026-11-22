// A chart's bars are printed on the wall in one flat ink (no lit, shaded tube), an empty week still has a scale of
// round steps, and every chart reads in the page's direction: right to left, its first sample, its first word and its
// scale stand at the right.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

final _key = GlobalKey();

class _Shot {
  _Shot(this.bytes, this.width, this.height, this.ground);
  final ByteData bytes;
  final int width, height;
  final Color ground;

  Color at(int x, int y) {
    final i = (y * width + x) * 4;
    return Color.fromARGB(
      255,
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
  }

  /// How far [c] stands from the ground, the widest of its three channels.
  int off(Color c) => [
    ((c.r - ground.r) * 255).abs().round(),
    ((c.g - ground.g) * 255).abs().round(),
    ((c.b - ground.b) * 255).abs().round(),
  ].reduce((a, b) => a > b ? a : b);

  /// The bars across [band] (in image pixels, top to bottom): each run of image columns whose longest run of inked
  /// pixels is over [tall], as its middle x and that height.
  List<(int x, int height, int top)> bars(Rect band, {int tall = 12}) {
    final columns = <(int, int, int)>[];
    for (var x = band.left.ceil(); x < band.right.floor(); x++) {
      var best = 0, bestTop = 0, run = 0, top = 0;
      for (var y = band.top.ceil(); y < band.bottom.floor(); y++) {
        if (off(at(x, y)) > 40) {
          if (run == 0) top = y;
          run++;
          if (run > best) {
            best = run;
            bestTop = top;
          }
        } else {
          run = 0;
        }
      }
      columns.add((x, best, bestTop));
    }
    final found = <(int, int, int)>[];
    var start = -1;
    for (var i = 0; i <= columns.length; i++) {
      final inked = i < columns.length && columns[i].$2 > tall;
      if (inked && start < 0) start = i;
      if (!inked && start >= 0) {
        final mid = columns[(start + i - 1) ~/ 2];
        found.add(mid);
        start = -1;
      }
    }
    return found;
  }
}

Future<_Shot> _shoot(
  WidgetTester tester,
  Widget chart, {
  bool dark = false,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(640, 520);
  addTearDown(tester.view.reset);
  late Color ground;
  await tester.pumpWidget(
    neumorphicApp(
      RepaintBoundary(
        key: _key,
        child: Builder(
          builder: (context) {
            ground = NeumorphicTheme.of(context).colors.ground;
            return ColoredBox(
              color: ground,
              child: Padding(padding: const EdgeInsets.all(16), child: chart),
            );
          },
        ),
      ),
      dark: dark,
      direction: direction,
      width: 640,
    ),
  );
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_key));
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final shot = _Shot(bytes, image.width, image.height, ground);
  image.dispose();
  return shot;
}

String _hours(double v) => '${v.round()}h';

const _week = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// The plot a chart paints with [painter] (its painter's type name).
Rect _plot(WidgetTester tester, String painter) => tester.getRect(
  find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter.runtimeType.toString() == painter,
  ),
);

void main() {
  for (final dark in [false, true]) {
    final mode = dark ? 'night' : 'day';
    testWidgets('a column is printed in one flat ink, top to foot, by $mode', (
      tester,
    ) async {
      final shot = await _shoot(
        tester,
        const NeumorphicColumnBars(
          values: [3, 3, 3, 3, 3, 3, 3],
          labels: _week,
        ),
        dark: dark,
      );
      final plot = _plot(tester, '_ColumnPainter');
      final bars = shot.bars(plot);
      expect(bars, hasLength(7), reason: 'seven columns found');
      for (final (x, height, top) in bars) {
        final head = shot.at(x, top + height ~/ 5);
        final foot = shot.at(x, top + height * 4 ~/ 5);
        final apart = [
          ((head.r - foot.r) * 255).abs(),
          ((head.g - foot.g) * 255).abs(),
          ((head.b - foot.b) * 255).abs(),
        ].reduce((a, b) => a > b ? a : b);
        expect(
          apart,
          lessThan(3),
          reason:
              'the column at $x reads $head near its top, $foot near its foot',
        );
      }
    });
  }

  testWidgets('an empty week stands on round steps, each written once', (
    tester,
  ) async {
    await _shoot(
      tester,
      const NeumorphicColumnBars(values: [0, 0, 0], labels: ['A', 'B', 'C']),
    );
    for (final tick in ['0', '0.25', '0.5', '0.75', '1']) {
      expect(find.text(tick), findsOneWidget, reason: 'the gridline $tick');
    }
  });

  group('right to left', () {
    testWidgets(
      'the week columns run from the right, their scale beside them',
      (tester) async {
        final shot = await _shoot(
          tester,
          const NeumorphicColumnBars(
            values: [1, 2, 3, 4, 5, 6, 7],
            labels: _week,
            format: _hours,
          ),
          direction: TextDirection.rtl,
        );
        final plot = _plot(tester, '_ColumnPainter');
        final bars = shot.bars(plot);
        expect(bars, hasLength(7));
        // Left to right on the page: Sunday's tallest column first, Monday's shortest last.
        final heights = <int>[for (final b in bars) b.$2];
        final falling = <int>[...heights]..sort((a, b) => b.compareTo(a));
        expect(heights, orderedEquals(falling));
        expect(
          tester.getCenter(find.text('Mon')).dx,
          greaterThan(tester.getCenter(find.text('Sun')).dx),
        );
        expect(
          tester.getCenter(find.text('Mon')).dx,
          closeTo(bars.last.$1, 6),
          reason: 'Monday under its own column',
        );
        // The scale stands at the start, the right.
        final scale = tester.getCenter(find.text('0h')).dx;
        expect(scale, greaterThan(plot.right));
      },
    );

    testWidgets('a bar chart runs from the right, each word under its bar', (
      tester,
    ) async {
      await _shoot(
        tester,
        const NeumorphicBarChart(
          label: 'Visits',
          series: [
            NeumorphicChartSeries('Visits', [2, 4, 6]),
          ],
          labels: ['A', 'B', 'C'],
        ),
        direction: TextDirection.rtl,
      );
      expect(
        tester.getCenter(find.text('A')).dx,
        greaterThan(tester.getCenter(find.text('C')).dx),
      );
    });

    testWidgets('the two-way bars run their day from the right', (
      tester,
    ) async {
      final shot = await _shoot(
        tester,
        const NeumorphicTwoWayBars(
          above: [.2, .4, .6, .8, 1, 1.2],
          slots: 6,
          labels: {0: '00', 5: '05'},
        ),
        direction: TextDirection.rtl,
      );
      final plot = _plot(tester, '_TwoWayPainter');
      final bars = shot.bars(plot, tall: 6);
      expect(bars, hasLength(6));
      final heights = <int>[for (final b in bars) b.$2];
      final falling = <int>[...heights]..sort((a, b) => b.compareTo(a));
      expect(heights, orderedEquals(falling));
      expect(
        tester.getCenter(find.text('00')).dx,
        greaterThan(tester.getCenter(find.text('05')).dx),
      );
    });

    testWidgets('the step line runs its day from the right', (tester) async {
      await _shoot(
        tester,
        const NeumorphicStepLine(
          readings: [(0, 18), (12, 20), (24, 19)],
          xMax: 24,
          yMin: 16,
          yMax: 22,
          yTicks: [17, 21],
          yLabel: '°',
          xLabels: [(0, '00'), (24, '24')],
        ),
        direction: TextDirection.rtl,
      );
      expect(
        tester.getCenter(find.text('00')).dx,
        greaterThan(tester.getCenter(find.text('24')).dx),
      );
      final plot = _plot(tester, '_StepPainter');
      expect(
        tester.getCenter(find.text('17°')).dx,
        greaterThan(plot.right),
        reason: 'the scale stands at the start, the right',
      );
    });
  });
}
