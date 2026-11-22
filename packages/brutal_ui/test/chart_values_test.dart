// A chart's value axis counts whole 0 and 1 when every value is 0, and an
// app names its values (a unit) on the axis and in what a screen reader
// hears.
import 'dart:ui' as ui;

import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _days = ['Mon', 'Tue', 'Wed'];

Future<void> _pump(WidgetTester tester, Widget chart) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: BrutalTheme(
        data: BrutalThemeData.light(),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 600, child: chart),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// How many words the chart paints, and how far in its value axis stands
/// (the widest tick's words and 8 px): the axis is its leftmost upright line.
(int, double) _axis(WidgetTester tester) {
  var words = 0;
  var axis = double.infinity;
  expect(
    find.byType(BrutalBarChart),
    paints..everything((method, arguments) {
      if (method == #drawParagraph) words++;
      if (method == #drawLine) {
        final (a, b) = (arguments[0] as Offset, arguments[1] as Offset);
        if (a.dx == b.dx && a.dx < axis) axis = a.dx;
      }
      return true;
    }),
  );
  return (words, axis);
}

double _width(String words) {
  final painter = TextPainter(
    text: TextSpan(
      text: words,
      style: BrutalThemeData.light().textTheme.caption.copyWith(
        fontFeatures: const [ui.FontFeature.tabularFigures()],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

void main() {
  testWidgets('an all-zero bar chart counts its axis 0 and 1', (tester) async {
    await _pump(
      tester,
      const BrutalBarChart(
        labels: _days,
        series: [
          BrutalSeries('Hours', [0, 0, 0]),
        ],
        semanticLabel: 'Hours a day',
      ),
    );
    // The three days and two ticks, the widest of them 1.
    final (words, axis) = _axis(tester);
    expect(words, _days.length + 2);
    expect(axis, closeTo(_width('1') + 8, 0.01));
  });

  testWidgets("a chart's valueLabel names the axis and the read-out", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      BrutalBarChart(
        labels: _days,
        series: const [
          BrutalSeries('Hours', [2, 6, 3]),
        ],
        semanticLabel: 'Hours a day',
        valueLabel: (v) => '${v.round()} h',
      ),
    );
    expect(_axis(tester).$2, closeTo(_width('6 h') + 8, 0.01));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Hours a day')).value,
      contains('Tue 6 h'),
    );
    semantics.dispose();
  });
}
