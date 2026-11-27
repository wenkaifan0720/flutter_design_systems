// A bar's value too wide for its column (a length in Arabic on a phone) takes a second line, whole, rather than being
// cut; the bars stay on one scale. The chart measures a value as it draws it, strong and with tabular figures (a face
// whose tabular figures are wider, as Arabic-Indic digits are in SF Arabic, cut values that measured as fitting).
import 'dart:math' as math;

import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A value as the chart draws it, each figure kept with its unit (a no-break
/// space between them).
Finder _value(String value) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      widget.data?.replaceAll(String.fromCharCode(0xA0), ' ') == value,
);

void main() {
  setUpAll(fluent2LoadFonts);

  testWidgets('long values wrap whole, the bars on one scale', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const hours = [2.5, 3.0, 3.25, 4.0, 2.75, 0.0, 0.0];
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        builder: (context, _) => Fluent2Host(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 326,
              child: Fluent2BarChart(
                height: 180,
                bars: [
                  for (var i = 0; i < 7; i++)
                    Fluent2Bar(
                      days[i],
                      hours[i],
                      valueText: '${10 + i} hrs ${40 + i} min',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 7; i++) {
      final words = tester.renderObject<RenderParagraph>(
        _value('${10 + i} hrs ${40 + i} min'),
      );
      expect(words.didExceedMaxLines, isFalse, reason: days[i]);
    }
    expect(tester.getSize(find.byType(Fluent2BarChart)).height, 180);
  });

  testWidgets('a value just past its column takes a second line too', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    // Widths around the one where "12 h 45 m" just fills a seventh, drawn
    // with tabular figures as every value is.
    for (var width = 300.0; width <= 420; width += 2) {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, _) => Fluent2Host(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: width,
                child: Fluent2BarChart(
                  height: 180,
                  highlight: 0,
                  bars: [
                    for (var i = 0; i < 7; i++)
                      Fluent2Bar('D$i', 1.0 + i, valueText: '1$i h 45 m'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 7; i++) {
        final words = tester.renderObject<RenderParagraph>(
          _value('1$i h 45 m'),
        );
        expect(words.didExceedMaxLines, isFalse, reason: 'at $width, D$i');
      }
    }
  });

  testWidgets('a wrapped value keeps each figure with its unit', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        builder: (context, _) => Fluent2Host(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 300,
              child: Fluent2BarChart(
                height: 180,
                highlight: 3,
                bars: [
                  for (var i = 0; i < 7; i++)
                    Fluent2Bar('D$i', 1.0 + i, valueText: '1$i h 45 m'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final words = tester.renderObject<RenderParagraph>(
      find.textContaining('13'),
    );
    // Each line's width, from the boxes of the whole text.
    final all = words.text.toPlainText();
    final rows = <double, (double, double)>{};
    for (final box in words.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: all.length),
    )) {
      final row = rows[box.top.roundToDouble()];
      rows[box.top.roundToDouble()] = row == null
          ? (box.left, box.right)
          : (math.min(row.$1, box.left), math.max(row.$2, box.right));
    }
    final widths = [for (final (left, right) in rows.values) right - left];
    expect(widths, hasLength(2));
    // "13 h" over "45 m", not "13 h 45" over a lone "m".
    expect(widths[1], greaterThan(0.6 * widths[0]));
  });
}
