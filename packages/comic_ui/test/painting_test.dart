// Equal rebuilt data must not repaint; changes with the same row count must.
// Distinct non-const values model data rebuilt by a parent.
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

class _CountedDrawing extends CustomPainter {
  _CountedDrawing(this.painted, this.color) : super(repaint: color);
  final VoidCallback painted;
  final ValueNotifier<Color> color;

  @override
  void paint(Canvas canvas, Size size) {
    painted();
    canvas.drawRect(Offset.zero & size, Paint()..color = color.value);
  }

  @override
  bool shouldRepaint(_CountedDrawing old) => old.color != color;
}

Future<CustomPainter> _painter(
  WidgetTester tester,
  Widget widget,
  String name,
) async {
  await tester.pumpWidget(
    comicApp(SingleChildScrollView(child: SizedBox(width: 360, child: widget))),
  );
  final found = find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter.runtimeType.toString() == name,
  );
  expect(found, findsWidgets);
  return tester.widget<CustomPaint>(found.first).painter!;
}

void _repaints(String name, Widget Function(bool changed) build) {
  testWidgets('$name repaints only when its drawing changes', (tester) async {
    final first = await _painter(tester, build(false), name);
    final equal = await _painter(tester, build(false), name);
    final changed = await _painter(tester, build(true), name);
    expect(equal.shouldRepaint(first), isFalse, reason: 'equal rebuilt data');
    expect(changed.shouldRepaint(equal), isTrue, reason: 'changed drawing');
  });
}

void main() {
  testWidgets(
    'scrolling a screen reuses static drawing and keeps live updates',
    (tester) async {
      final scroll = ScrollController();
      final color = ValueNotifier(const Color(0xff17345a));
      addTearDown(scroll.dispose);
      addTearDown(color.dispose);
      var paints = 0;
      await tester.pumpWidget(
        comicApp(
          ComicScaffold(
            scrollController: scroll,
            body: SizedBox(
              height: 1600,
              child: CustomPaint(
                painter: _CountedDrawing(() => paints++, color),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final initial = paints;
      expect(initial, greaterThan(0));
      expect(scroll.position.maxScrollExtent, greaterThan(180));
      for (final offset in [60.0, 120.0, 180.0]) {
        scroll.jumpTo(offset);
        await tester.pump();
      }
      expect(paints, initial, reason: 'Moving the viewport reuses the drawing');
      color.value = const Color(0xffbd315d);
      await tester.pump();
      expect(paints, initial + 1, reason: 'A changed drawing still repaints');
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'loading timings interpolate, copy and compare with the motion theme',
    () {
      const base = ComicMotion();
      final custom = base.copyWith(
        spinner: const Duration(seconds: 2),
        progress: const Duration(seconds: 3),
        pulse: const Duration(seconds: 4),
      );
      expect(custom, custom.copyWith());
      expect(custom.hashCode, custom.copyWith().hashCode);
      expect(ComicMotion.lerp(base, custom, 1), custom);
      expect(
        ComicMotion.lerp(ComicMotion.still, custom, .5).spinner,
        const Duration(seconds: 1),
      );
    },
  );

  testWidgets('zero motion timings stop all loading animations', (
    tester,
  ) async {
    for (final motion in [const ComicMotion(), ComicMotion.still]) {
      await tester.pumpWidget(
        comicApp(
          ComicTheme(
            data: ComicThemeData.offset().copyWith(motion: motion),
            child: Column(
              children: [
                ComicCircularProgressIndicator(),
                ComicLinearProgressIndicator(),
                ComicSkeleton(),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (motion == ComicMotion.still) {
        await tester.pumpAndSettle();
        expect(tester.binding.transientCallbackCount, 0);
      } else {
        expect(tester.binding.transientCallbackCount, greaterThan(0));
      }
    }
  });

  test(
    'chart values compare by value, including gaps and optional captions',
    () {
      final cases = <(Object, Object, Object)>[
        (
          ComicChartSeries('Pages', [1, null, 3]),
          ComicChartSeries('Pages', [1, null, 3]),
          ComicChartSeries('Pages', [1, 2, 3]),
        ),
        (
          ComicChartBand(1, 4, label: 'Goal'),
          ComicChartBand(1, 4, label: 'Goal'),
          ComicChartBand(2, 4, label: 'Goal'),
        ),
        (
          ComicSlice('Pages', 4, figure: '4', share: '40%'),
          ComicSlice('Pages', 4, figure: '4', share: '40%'),
          ComicSlice('Pages', 5, figure: '5', share: '50%'),
        ),
        (
          ComicShare('Pages', 4, ink: ComicShareFill.dots),
          ComicShare('Pages', 4, ink: ComicShareFill.dots),
          ComicShare('Pages', 4, ink: ComicShareFill.lamp),
        ),
      ];
      for (final (a, b, c) in cases) {
        expect(a, b);
        expect(a.hashCode, b.hashCode);
        expect(a, isNot(c));
      }
    },
  );

  _repaints(
    '_CoverPainter',
    (changed) => ComicCoverPrint(wedges: changed ? 20 : 30),
  );
  _repaints('_BurstPainter', (changed) => ComicPop('5', seed: changed ? 2 : 7));
  _repaints(
    '_BarPainter',
    (changed) => ComicBar(value: 3, of: 5, height: changed ? 18 : 22),
  );
  _repaints(
    '_FlowArt',
    (changed) => ComicFlow(
      into: 'Sam',
      from: [
        ComicFlowFrom('You', changed ? 20 : 10, isCurrentUser: true),
        ComicFlowFrom('Alex', changed ? 10 : 20),
      ],
    ),
  );
  _repaints(
    '_SharesPainter',
    (changed) => ComicShares(
      parts: [
        ComicShare('Reading', changed ? 2 : 3),
        ComicShare('Writing', changed ? 3 : 2),
      ],
    ),
  );
  _repaints(
    '_PiePainter',
    (changed) => ComicPieChart(
      slices: [
        ComicSlice('Reading', changed ? 2 : 3),
        ComicSlice('Writing', changed ? 3 : 2),
      ],
    ),
  );
  _repaints(
    '_ChartInk',
    (changed) => ComicChart(
      label: 'Pages',
      series: [
        ComicChartSeries('Pages', [1, changed ? 2 : 3, 4]),
      ],
      band: ComicChartBand(1, 3),
    ),
  );

  testWidgets('ongoing animation stays inside a repaint boundary', (
    tester,
  ) async {
    for (final widget in <Widget>[
      ComicCircularProgressIndicator(),
      ComicLinearProgressIndicator(),
      ComicSkeleton(),
    ]) {
      await tester.pumpWidget(comicApp(Center(child: widget)));
      final boundary = find.descendant(
        of: find.byWidget(widget),
        matching: find.byType(RepaintBoundary),
      );
      expect(boundary, findsWidgets);
      expect(
        find.descendant(
          of: boundary.first,
          matching: find.byWidgetPredicate(
            (w) => w is AnimatedBuilder || w is FadeTransition,
          ),
        ),
        findsWidgets,
      );
    }
  });
}
