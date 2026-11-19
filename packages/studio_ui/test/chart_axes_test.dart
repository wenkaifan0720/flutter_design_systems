// A chart's axes read cleanly: the scale steps by round figures (a
// five-hour top reads 0, 1, 2, 3, 4, 5, never 0, 1.3, 2.5, 3.8, 5), and
// when the labels crowd (a week at 200%), every other one stays, or every
// third..., evenly, no two closer than a word's space (Mon, Wed, Fri,
// Sun, never Mon, Wed, Fri, Sat with Fri and Sat touching).
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

const _week = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// A recording canvas that takes each paragraph's box as it is drawn (the
// painter disposes its words once painted).
class _Canvas extends TestRecordingCanvas {
  final words = <Rect>[];

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    words.add(offset & Size(paragraph.longestLine, paragraph.height));
    super.drawParagraph(paragraph, offset);
  }
}

// What the chart's painter draws: its rules across the plot and its words.
Future<({List<(Offset, Offset)> rules, List<Rect> words})> _paint(
  WidgetTester tester,
  List<double> hours, {
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 600 * 2);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: StudioHost(brightness: Brightness.light, child: app!),
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 300,
            child: StudioBarChart(
              semanticLabel: 'Hours logged',
              height: 150,
              labels: _week,
              series: [StudioSeries('Hours logged', hours)],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final paint = tester
      .renderObjectList<RenderCustomPaint>(
        find.descendant(
          of: find.byType(StudioBarChart),
          matching: find.byType(CustomPaint),
        ),
      )
      .firstWhere((r) => '${r.painter.runtimeType}' == '_BarPainter');
  final canvas = _Canvas();
  paint.painter!.paint(canvas, paint.size);
  // A rule may be engraved in two strokes a pixel apart: one rule.
  final rules = <(Offset, Offset)>[];
  for (final call in canvas.invocations) {
    final args = call.invocation.positionalArguments;
    if (call.invocation.memberName == #drawLine) {
      final (a, b) = (args[0] as Offset, args[1] as Offset);
      if (a.dy == b.dy &&
          b.dx - a.dx > 100 &&
          rules.every((r) => (r.$1.dy - a.dy).abs() > 1.5)) {
        rules.add((a, b));
      }
    }
  }
  return (rules: rules, words: canvas.words);
}

void main() {
  setUpAll(studioLoadFonts);

  testWidgets('a five-hour top steps by whole hours', (tester) async {
    final (:rules, :words) = await _paint(tester, [2.5, 3, 3.5, 4, 5, 0, 0]);
    // 0, 1, 2, 3, 4, 5: six rules, evenly apart.
    expect(rules, hasLength(6));
    final ys = [for (final (a, _) in rules) a.dy]..sort();
    for (var i = 2; i < ys.length; i++) {
      expect(ys[i] - ys[i - 1], closeTo(ys[1] - ys[0], 0.01));
    }
    // A figure beside every rule at this size.
    final figures = words.where((w) => w.right < rules.first.$1.dx).toList();
    expect(figures, hasLength(6));
  });

  testWidgets('crowded labels thin evenly, a word\'s space apart', (
    tester,
  ) async {
    final (:rules, :words) = await _paint(tester, [
      2.5,
      3,
      3.5,
      4,
      2.75,
      0,
      0,
    ], scale: 2);
    final plotLeft = rules.first.$1.dx;
    final plotRight = rules.first.$2.dx;
    final foot = words.map((w) => w.top).reduce((a, b) => a > b ? a : b);
    final steps = words.where((w) => w.top == foot).toList()
      ..sort((a, b) => a.left.compareTo(b.left));
    // Crowded: fewer than all seven, more than one.
    expect(steps.length, inExclusiveRange(1, _week.length));
    for (var i = 1; i < steps.length; i++) {
      expect(
        steps[i].left - steps[i - 1].right,
        greaterThanOrEqualTo(StudioSpacing.small - 0.01),
        reason: 'labels ${i - 1} and $i',
      );
    }
    // Evenly: the labels not held in at an end of the frame or the plot
    // stand a like step apart.
    bool held(Rect w) =>
        w.left < 0.5 ||
        w.right > 299.5 ||
        (w.left - plotLeft).abs() < 0.5 ||
        (w.right - plotRight).abs() < 0.5;
    final free = [
      for (final w in steps)
        if (!held(w)) w.center.dx,
    ];
    for (var i = 2; i < free.length; i++) {
      expect(free[i] - free[i - 1], closeTo(free[1] - free[0], 0.5));
    }
    // The scale's figures thin evenly too, from 0 up.
    final figures = [
      for (final w in words)
        if (w.right < plotLeft) w.center.dy,
    ]..sort();
    expect(figures.length, greaterThan(1));
    for (var i = 2; i < figures.length; i++) {
      expect(
        figures[i] - figures[i - 1],
        closeTo(figures[1] - figures[0], 0.5),
      );
    }
  });
}
