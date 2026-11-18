// A drag on the wheels turns them and the page under them keeps still, from
// a finger and a mouse, on a column or on the rule between two; and right to
// left Brutal is mirrored as the text reads: the charts (the categories and
// time from the right, the value axis on the right, a pie round the other
// way) and the lift of a row being reordered (against its shadow, which
// falls toward the end side).
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// The direction over the whole app, the overlay a drag lifts a row into
// among it, as a right-to-left locale sets it.
Widget _app(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      builder: (context, page) => Directionality(
        textDirection: direction,
        child: BrutalTheme(data: BrutalThemeData.light(), child: page!),
      ),
      home: Builder(
        builder: (context) => ColoredBox(
          color: BrutalTheme.of(context).colors.paper,
          child: child,
        ),
      ),
    );

// The pixels of the chart's own painting under [key] (its painter's box,
// not the legend's words), row by row, RGBA.
Future<(int, int, Uint8List)> _pixels(WidgetTester tester, Key key) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final painted = find.descendant(
    of: find.byKey(key),
    matching: find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter != null &&
          const {
            '_BarPainter',
            '_LinePainter',
            '_PiePainter',
            '_SparkPainter',
          }.contains(w.painter.runtimeType.toString()),
    ),
  );
  final box = tester.renderObject<RenderBox>(painted.first);
  final at = box.localToGlobal(Offset.zero, ancestor: boundary) & box.size;
  final (w, h, all) = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final out = (image.width, image.height, bytes!.buffer.asUint8List());
    image.dispose();
    return out;
  }))!;
  final (left, top) = (at.left.round(), at.top.round());
  final (cw, ch) = (at.width.round(), at.height.round());
  expect(left >= 0 && top >= 0 && left + cw <= w && top + ch <= h, isTrue);
  final out = Uint8List(cw * ch * 4);
  for (var row = 0; row < ch; row++) {
    final from = ((top + row) * w + left) * 4;
    out.setRange(row * cw * 4, (row + 1) * cw * 4, all, from);
  }
  return (cw, ch, out);
}

// The share of [a]'s pixels that its mirror image [b] repeats (each channel
// within 8).
double _mirrored((int, int, Uint8List) a, (int, int, Uint8List) b) {
  final (w, h, x) = a;
  final y = b.$3;
  expect((b.$1, b.$2), (w, h));
  var same = 0;
  for (var row = 0; row < h; row++) {
    for (var col = 0; col < w; col++) {
      final i = (row * w + col) * 4;
      final j = (row * w + (w - 1 - col)) * 4;
      var close = true;
      for (var k = 0; k < 4; k++) {
        if ((x[i + k] - y[j + k]).abs() > 8) close = false;
      }
      if (close) same++;
    }
  }
  return same / (w * h);
}

void main() {
  group('a drag on the wheels turns them; the page keeps still', () {
    for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
      for (final (where, dx) in [
        ('on the rule between them', 0.0),
        ('on the hours', -44.0),
      ]) {
        testWidgets('${kind.name}, $where', (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          var time = const BrutalTime(hour: 19, minute: 30);
          final page = ScrollController();
          addTearDown(page.dispose);
          await tester.pumpWidget(
            _app(
              StatefulBuilder(
                builder: (context, setState) => ListView(
                  controller: page,
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 200),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: BrutalTimePicker(
                        value: time,
                        onChanged: (t) => setState(() => time = t),
                      ),
                    ),
                    const SizedBox(height: 2000),
                  ],
                ),
              ),
            ),
          );
          final at =
              tester.getCenter(find.byType(BrutalTimePicker)) + Offset(dx, 0);
          final drag = await tester.startGesture(at, kind: kind);
          for (var i = 0; i < 5; i++) {
            await drag.moveBy(const Offset(0, -20));
            await tester.pump(const Duration(milliseconds: 16));
          }
          await drag.up();
          await tester.pumpAndSettle();
          expect(page.offset, 0, reason: 'the page moved under the drag');
          expect(
            time,
            isNot(const BrutalTime(hour: 19, minute: 30)),
            reason: 'the wheel did not turn',
          );
          if (dx < 0) expect(time.hour, isNot(19));
        });
      }
    }
  });

  group('right to left, the charts are mirrored', () {
    // No words in the picture (they read the same way both sides), so the
    // right-to-left chart is the left-to-right one in a mirror.
    const quiet = BrutalStyle(
      foreground: WidgetStatePropertyAll(Color(0x00000000)),
    );
    final charts = <String, Widget>{
      'bars': const BrutalBarChart(
        semanticLabel: 'Sold',
        labels: ['Mon', 'Tue', 'Wed', 'Thu'],
        series: [
          BrutalSeries('Door', [12, 30, 22, 48]),
          BrutalSeries('Online', [40, 18, 35, 9]),
        ],
        style: quiet,
      ),
      'line': const BrutalLineChart(
        semanticLabel: 'Sold',
        labels: ['Mon', 'Tue', 'Wed', 'Thu'],
        series: [
          BrutalSeries('Sold', [12, 30, 22, 48]),
        ],
        style: quiet,
      ),
      'area': const BrutalAreaChart(
        semanticLabel: 'Sold',
        labels: ['Mon', 'Tue', 'Wed', 'Thu'],
        series: [
          BrutalSeries('Sold', [12, 30, 22, 48]),
        ],
        style: quiet,
      ),
      'sparkline': const BrutalSparkline(
        semanticLabel: 'Sold',
        values: [3, 5, 4, 8, 7, 2],
        width: 160,
        height: 40,
      ),
      'pie': const BrutalPieChart(
        semanticLabel: 'Seats',
        slices: [
          BrutalSlice('Stalls', 50),
          BrutalSlice('Circle', 30),
          BrutalSlice('Standing', 20),
        ],
      ),
    };
    for (final MapEntry(key: name, value: chart) in charts.entries) {
      testWidgets(name, (tester) async {
        tester.view.physicalSize = const Size(400, 400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const key = Key('picture');
        Widget only(TextDirection direction) => _app(
          direction: direction,
          Center(
            child: SizedBox(
              width: 360,
              child: RepaintBoundary(key: key, child: chart),
            ),
          ),
        );
        await tester.pumpWidget(only(TextDirection.ltr));
        final ltr = await _pixels(tester, key);
        await tester.pumpWidget(only(TextDirection.rtl));
        final rtl = await _pixels(tester, key);
        expect(_mirrored(ltr, rtl), greaterThan(0.995));
        // And it is not symmetric in itself: the mirror says something.
        expect(_mirrored(ltr, ltr), lessThan(0.99));
      });
    }
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      '${direction.name}: a row being reordered lifts against its shadow',
      (tester) async {
        const items = ['Doors', 'Support', 'Headline'];
        await tester.pumpWidget(
          _app(
            direction: direction,
            Padding(
              padding: const EdgeInsets.all(40),
              child: Builder(
                builder: (context) => BrutalReorderableList<String>(
                  items: items,
                  labelOf: (s) => s,
                  // Only the lift is read; the row is never let go elsewhere.
                  onReorder: (from, to) {},
                  itemBuilder: (context, s) => Text(s),
                  shrinkWrap: true,
                ),
              ),
            ),
          ),
        );
        final before = tester.getTopLeft(find.text('Doors'));
        // A drag on the first row's handle, past the slop, lifts it.
        final hold = await tester.startGesture(
          tester.getCenter(find.byType(Icon).first),
        );
        for (var i = 0; i < 4; i++) {
          await hold.moveBy(const Offset(0, 5));
          await tester.pump();
        }
        await tester.pumpAndSettle();
        // The row rides in the overlay (its place in the list stands empty),
        // 20 px down with the pointer, then lifted.
        final lifted =
            tester.getTopLeft(find.text('Doors').last) - const Offset(0, 20);
        final theme = BrutalThemeData.light();
        final away = -theme.shadowIn(direction);
        expect(
          (lifted - before).dx.sign,
          away.dx.sign,
          reason: '${direction.name}: lifted the wrong way across',
        );
        expect((lifted - before).dy, lessThan(0));
        await hold.up();
        await tester.pumpAndSettle();
      },
    );
  }
}
