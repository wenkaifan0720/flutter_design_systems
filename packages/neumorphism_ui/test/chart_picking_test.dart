// The charts' picking on ui_core's RawChart and RawPieChart: a mouse, a finger, the keys (one tab stop) and a
// screen reader choose a sample or a slice; the look marks it and shows its values, in the plot's readout or the
// donut's hole.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/chart.dart'
    show NeumorphicChart, NeumorphicChartKind;

import 'support.dart';

Widget _chart({NeumorphicChartKind kind = NeumorphicChartKind.line}) =>
    neumorphicApp(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 360,
          child: NeumorphicChart(
            semanticLabel: 'Sleep',
            kind: kind,
            labels: const ['Mon', 'Tue', 'Wed', 'Thu'],
            series: const [
              NeumorphicChartSeries('Hours', [7, 6, 8, 5]),
            ],
          ),
        ),
      ),
    );

Widget _pie() => neumorphicApp(
  const Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: 360,
      child: NeumorphicPieChart(
        semanticLabel: 'Energy',
        total: '10 kWh',
        slices: [
          NeumorphicPieSlice('Heating', 5),
          NeumorphicPieSlice('Lights', 3),
          NeumorphicPieSlice('Other', 2),
        ],
      ),
    ),
  ),
);

Finder get _readout => find.byType(NeumorphicTooltipFace);

String _said(WidgetTester tester) =>
    tester.widget<NeumorphicTooltipFace>(_readout).message;

void main() {
  setUpAll(loadNeumorphicFonts);

  testWidgets(
    'a mouse over the plot reads the sample under it; leaving clears it',
    (tester) async {
      await tester.pumpWidget(_chart());
      final plot = tester.getRect(find.byType(CustomPaint).at(1));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      // The third of four samples, two thirds across the plot.
      await mouse.moveTo(
        Offset(plot.left + plot.width * 2 / 3, plot.center.dy),
      );
      await tester.pump();
      expect(_said(tester), 'Wed\nHours 8');
      await mouse.moveTo(const Offset(700, 500));
      await tester.pump();
      expect(_readout, findsNothing);
    },
  );

  testWidgets('a tap on a bar holds its readout', (tester) async {
    await tester.pumpWidget(_chart(kind: NeumorphicChartKind.bar));
    final plot = tester.getRect(find.byType(CustomPaint).at(1));
    await tester.tapAt(
      Offset(plot.left + plot.width * 1.5 / 4, plot.center.dy),
    );
    await tester.pump();
    expect(_said(tester), 'Tue\nHours 6');
  });

  testWidgets('one tab stop: the arrows walk the samples, Escape lets go', (
    tester,
  ) async {
    await tester.pumpWidget(_chart());
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(_said(tester), 'Mon\nHours 7');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(_said(tester), 'Tue\nHours 6');
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(_said(tester), 'Thu\nHours 5');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(_readout, findsNothing);
  });

  testWidgets('a screen reader hears the chart, then steps its samples', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_chart());
    final chart = find.semantics.byLabel('Sleep');
    expect(
      chart,
      isSemantics(
        label: 'Sleep',
        value: 'Hours: 7, 6, 8, 5',
        hasIncreaseAction: true,
      ),
    );
    tester.semantics.increase(chart);
    await tester.pump();
    expect(_said(tester), 'Mon\nHours 7');
    semantics.dispose();
  });

  testWidgets(
    'the donut: a pointer on a slice names it in the hole, not in the hole itself',
    (tester) async {
      await tester.pumpWidget(_pie());
      final ring = tester.getRect(find.byType(CustomPaint).at(1));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      // Heating runs from twelve to six, clockwise: its middle is at three o'clock, on the ring.
      final radius = (ring.width - ring.width * .15) / 2 - 4;
      await mouse.moveTo(ring.center + Offset(radius, 0));
      await tester.pump();
      expect(find.text('Heating, 50%'), findsOneWidget);
      await mouse.moveTo(ring.center);
      await tester.pump();
      expect(find.text('10 kWh'), findsOneWidget);
    },
  );

  testWidgets('the donut: one tab stop, the arrows walk the slices', (
    tester,
  ) async {
    await tester.pumpWidget(_pie());
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('Heating, 50%'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('Lights, 30%'), findsOneWidget);
  });
}
