/// Painting for performance (Gilt's `painting_test.dart`): a painter
/// repaints only when what it paints changes, the data it takes compares by
/// value, and what animates for as long as it shows sits on its own layer.
///
/// The data below is built without `const` on purpose: equal values in
/// distinct instances are what a rebuild hands a painter.
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

/// [child] in a 390dp-wide column, under the Expressive host.
Widget _app(Widget child) => ExpressiveHost(
  light: _theme,
  brightness: Brightness.light,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Center(child: SizedBox(width: 390, child: child)),
    ),
  ),
);

/// The painter named [name] that [widget] paints with.
Future<CustomPainter> _painted(
  WidgetTester tester,
  Widget widget,
  String name,
) async {
  await tester.pumpWidget(_app(widget));
  // A chart springs to new values: read the painter once it has arrived.
  await tester.pumpAndSettle();
  final found = find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter.runtimeType.toString() == name,
  );
  expect(found, findsWidgets, reason: '$name paints');
  return tester.widget<CustomPaint>(found.first).painter!;
}

/// The painter named [name] that [build] paints with repaints for a change
/// and not for an equal rebuild.
void _repaints(String name, Widget Function({required bool changed}) build) {
  testWidgets('$name repaints only for a change', (tester) async {
    final first = await _painted(tester, build(changed: false), name);
    final same = await _painted(tester, build(changed: false), name);
    final changed = await _painted(tester, build(changed: true), name);
    expect(same.shouldRepaint(first), isFalse, reason: 'an equal rebuild');
    expect(changed.shouldRepaint(same), isTrue, reason: 'a change');
  });
}

void main() {
  test('chart data compare by value', () {
    final cases = <(Object, Object, Object)>[
      (
        ExpressiveChartPoint('Mon', 8.2, at: 0.5),
        ExpressiveChartPoint('Mon', 8.2, at: 0.5),
        ExpressiveChartPoint('Mon', 8.2),
      ),
      (
        ExpressiveChartTick(1, 'Tue'),
        ExpressiveChartTick(1, 'Tue'),
        ExpressiveChartTick(2, 'Tue'),
      ),
      (
        ExpressiveChartSeries('Systolic', [ExpressiveChartPoint('Mon', 128)]),
        ExpressiveChartSeries('Systolic', [ExpressiveChartPoint('Mon', 128)]),
        ExpressiveChartSeries('Systolic', [ExpressiveChartPoint('Mon', 131)]),
      ),
      (
        ExpressiveChartBand(90, 120, label: 'Your target'),
        ExpressiveChartBand(90, 120, label: 'Your target'),
        ExpressiveChartBand(90, 130, label: 'Your target'),
      ),
      (
        ExpressiveChartTarget(8, label: 'Goal'),
        ExpressiveChartTarget(8, label: 'Goal'),
        ExpressiveChartTarget(7.5, label: 'Goal'),
      ),
      (
        ExpressiveChartAxis(0, 10, 2),
        ExpressiveChartAxis(0, 10, 2),
        ExpressiveChartAxis(0, 12, 2),
      ),
    ];
    for (final (a, b, c) in cases) {
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    }
  });

  _repaints(
    '_ScaledChartPainter',
    ({required changed}) => ExpressiveChart.line(
      points: [
        ExpressiveChartPoint('Mon', 7.5),
        ExpressiveChartPoint('Tue', changed ? 6 : 8),
        ExpressiveChartPoint('Wed', 7),
      ],
      // A goal line: the scaled chart, not the plain count chart.
      target: ExpressiveChartTarget(7, label: 'Goal'),
    ),
  );
  _repaints(
    '_TrackPainter',
    ({required changed}) =>
        ExpressiveSlider(value: changed ? 0.7 : 0.3, onChanged: (_) {}),
  );

  testWidgets('what animates for as long as it shows has its own layer', (
    tester,
  ) async {
    for (final (name, widget) in <(String, Widget)>[
      ('linear', const ExpressiveLinearProgressIndicator()),
      ('circular', const ExpressiveCircularProgressIndicator()),
      ('loading', const ExpressiveLoadingIndicator()),
      ('contained loading', const ExpressiveLoadingIndicator(contained: true)),
    ]) {
      await tester.pumpWidget(_app(Center(child: widget)));
      await tester.pump(const Duration(milliseconds: 100));
      final layered = find.descendant(
        of: find.byWidget(widget),
        matching: find.byType(RepaintBoundary),
      );
      expect(layered, findsWidgets, reason: name);
      final painted = find.descendant(
        of: layered.first,
        matching: find.byType(CustomPaint),
      );
      expect(painted, findsWidgets, reason: '$name paints inside its layer');
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the skeleton pulses on an opacity layer, never repainting', (
    tester,
  ) async {
    final skeleton = ExpressiveSkeleton.text(lines: 3);
    await tester.pumpWidget(_app(skeleton));
    final fade = find.descendant(
      of: find.byWidget(skeleton),
      matching: find.byType(FadeTransition),
    );
    expect(fade, findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
