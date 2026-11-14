import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'styled_controls_test.dart' show mount;
import 'support.dart';

CustomPainter painter(WidgetTester tester, String name) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .whereType<CustomPainter>()
    .firstWhere((p) => p.runtimeType.toString() == name);

void main() {
  setUpAll(loadNeumorphicFonts);
  testWidgets('changing chart scales or grid ticks invalidates its paint', (
    tester,
  ) async {
    const readings = [(0.0, 2.0), (12.0, 4.0), (24.0, 3.0)];
    const steps = [(0.0, 2.0), (12.0, 3.0), (24.0, 3.0)];
    Future<CustomPainter> draw({
      double xMin = 0,
      double xMax = 24,
      double yMin = 0,
      double yMax = 5,
      List<double> ticks = const [1, 3, 5],
    }) async {
      await mount(
        tester,
        NeumorphicStepLine(
          readings: [...readings],
          steps: [...steps],
          now: 12,
          xMin: xMin,
          xMax: xMax,
          yMin: yMin,
          yMax: yMax,
          yTicks: ticks,
        ),
        NeumorphicThemeData.porcelain(),
        width: 390,
      );
      return painter(tester, '_StepPainter');
    }

    final baseline = await draw();
    expect(
      (await draw()).shouldRepaint(baseline),
      isFalse,
      reason:
          'Equal samples in newly allocated lists do not change the drawing',
    );
    for (final next in [
      await draw(xMin: -1),
      await draw(xMax: 30),
      await draw(yMin: -1),
      await draw(yMax: 6),
      await draw(ticks: [2, 4]),
    ]) {
      expect(next.shouldRepaint(baseline), isTrue);
    }
  });

  testWidgets('changing dial tick ranks invalidates its paint', (tester) async {
    Future<CustomPainter> draw(double major) async {
      await mount(
        tester,
        NeumorphicDial(value: 50, figure: '50', step: 10, major: major),
        NeumorphicThemeData.porcelain(),
        width: 390,
      );
      return painter(tester, '_DialPainter');
    }

    final baseline = await draw(20);
    expect((await draw(20)).shouldRepaint(baseline), isFalse);
    expect(
      (await draw(10)).shouldRepaint(baseline),
      isTrue,
      reason: 'The positions and active ticks are identical, but major ticks changed',
    );
  });

  for (final kind in ['columns', 'two-way']) {
    testWidgets('$kind compares sample values rather than list identity', (
      tester,
    ) async {
      Future<CustomPainter> draw(double value) async {
        await mount(
          tester,
          kind == 'columns'
              ? NeumorphicColumnBars(values: [2, value, 1])
              : NeumorphicTwoWayBars(
                  above: [2, value, 1],
                  below: {1: 1},
                  slots: 3,
                ),
          NeumorphicThemeData.porcelain(),
          width: 390,
        );
        return painter(
          tester,
          kind == 'columns' ? '_ColumnPainter' : '_TwoWayPainter',
        );
      }

      final baseline = await draw(4);
      expect((await draw(4)).shouldRepaint(baseline), isFalse);
      expect((await draw(5)).shouldRepaint(baseline), isTrue);
    });
  }
}
