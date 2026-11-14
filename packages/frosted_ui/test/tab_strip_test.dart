// A scrolling tab strip leaves its chosen plate whole (round 10: the strip's viewport clipped at its own line, so the
// first tab's plate lost its start cap's edge and its lift under it, cut flat). With the first tab chosen at the
// strip's start, the plate's glass edge shows a pixel before the strip, and its lift a few pixels under it, by day
// and by night; the strip still stands 40 tall with its first tab at its start.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

const _stage = ValueKey('stage');
const _width = 480;
const _height = 160;

typedef _Read = Color Function(int x, int y);

double _apart(Color a, Color b) =>
    [(a.r - b.r).abs(), (a.g - b.g).abs(), (a.b - b.b).abs()].reduce(math.max);

Future<_Read> _shot(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_stage),
  );
  final px = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      return (await image.toByteData())!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }))!;
  return (int x, int y) {
    final i = (y * _width + x) * 4;
    return Color.fromARGB(px[i + 3], px[i], px[i + 1], px[i + 2]);
  };
}

Widget _app(FrostedThemeData t) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => FrostedHost(
    light: t,
    dark: t,
    brightness: t.isDark ? Brightness.dark : Brightness.light,
    child: RepaintBoundary(key: _stage, child: page!),
  ),
  home: ColoredBox(
    color: t.colorScheme.background,
    child: Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: SizedBox(
          width: 300,
          child: FrostedTabBar(
            tabs: const ['Spending', 'Income', 'Transfers', 'Refunds'],
            onChanged: (_) {},
          ),
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(frostedLoadFonts);

  for (final brightness in Brightness.values) {
    final day = brightness == Brightness.light ? 'day' : 'night';
    final t = FrostedThemeData.preset(
      FrostedThemeData.presets.first,
      brightness,
    );

    testWidgets('by $day the scrolling strip leaves its chosen plate whole', (
      tester,
    ) async {
      tester.view.physicalSize = Size(_width.toDouble(), _height.toDouble());
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(t));
      await tester.pumpAndSettle();

      final strip = tester.getRect(find.byType(FrostedTabBar));
      expect(strip.topLeft, const Offset(40, 40));
      expect(strip.height, FrostedChromeMetrics.tabHeight);
      // Four tabs run past 300: the strip scrolls.
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      final first = tester.getRect(find.text('Spending'));
      expect(
        first.left - strip.left,
        closeTo(FrostedChromeMetrics.tabInset, 1),
        reason: 'the first tab stands at the strip start',
      );

      final read = await _shot(tester);
      final ground = read(4, 4);
      final midY = strip.center.dy.floor();
      final midX = first.center.dx.floor();
      final edge = _apart(read(strip.left.floor() - 1, midY), ground);
      final lift = [
        for (var dy = 1; dy <= 4; dy++)
          _apart(read(midX, strip.bottom.floor() - 1 + dy), ground),
      ].reduce(math.max);
      expect(
        edge,
        greaterThan(2 / 255),
        reason: "the plate's edge a pixel before the strip",
      );
      expect(
        lift,
        greaterThan(2 / 255),
        reason: "the plate's lift under the strip",
      );
    }, tags: const ['goldens']);
  }
}
