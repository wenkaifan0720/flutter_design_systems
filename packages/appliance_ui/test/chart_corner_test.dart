// A chart's day labels stand under the glass, clear of the scale's figures at its side: the first day no longer runs
// under the scale's 0.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(applianceLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets('the first day stands clear of the scale (${direction.name})', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: const ApplianceHost(
              brightness: Brightness.light,
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 358,
                  child: ApplianceLineChart(
                    semanticLabel: 'Orders',
                    labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                    series: [
                      ApplianceChartSeries('Orders', [3.5, 12, 7.25, 18, 9]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final texts = <Offset>[];
      final rules = <(Offset, Offset)>[];
      final chart = find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == '_SeriesPainter',
      );
      expect(
        tester.renderObject<RenderBox>(chart),
        paints..everything((method, args) {
          if (method == #drawParagraph) texts.add(args[1] as Offset);
          if (method == #drawLine) {
            rules.add((args[0] as Offset, args[1] as Offset));
          }
          return true;
        }),
      );
      // The glass's width: the scale's rules run across it.
      final across = [
        for (final r in rules)
          if (r.$1.dy == r.$2.dy) r,
      ];
      final start = across.map((r) => r.$1.dx).reduce((a, b) => a < b ? a : b);
      final end = across.map((r) => r.$2.dx).reduce((a, b) => a > b ? a : b);
      final foot = texts.map((t) => t.dy).reduce((a, b) => a > b ? a : b);
      final days = [
        for (final t in texts)
          if (t.dy == foot) t,
      ];
      expect(days, hasLength(5));
      final legend = ApplianceTheme.of(tester.element(chart)).textTheme.legend;
      final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
      final lefts = [...days.map((t) => t.dx)]..sort();
      final ordered = direction == TextDirection.ltr
          ? labels
          : labels.reversed.toList();
      for (final (i, label) in ordered.indexed) {
        final painter = TextPainter(
          text: TextSpan(text: label, style: legend),
          textDirection: direction,
        )..layout();
        addTearDown(painter.dispose);
        expect(lefts[i], greaterThanOrEqualTo(start - 0.5), reason: label);
        expect(
          lefts[i] + painter.width,
          lessThanOrEqualTo(end + 0.5),
          reason: label,
        );
      }
    });
  }
}
