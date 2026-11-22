import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'support/display_host.dart';

void main() {
  group('kpi', () {
    const orders = MinimalStatRow.joined(
      children: [
        MinimalStat(
          label: 'Revenue',
          value: '€1,284',
          delta: '+12%',
          detail: 'vs last Fri',
          spark: [20, 15, 22, 12, 8, 13, 4],
          weight: 1.3,
        ),
        MinimalStat(label: 'Orders', value: '38', detail: '6 open'),
        MinimalStat(label: 'Late', value: '4', tone: MinimalTone.warning),
      ],
    );

    testWidgets('a KPI strip matches its cells and weighs their widths', (
      tester,
    ) async {
      await tester.pumpWidget(displayHost(orders));
      final cells = find.byType(MinimalStat);
      final a = tester.getSize(cells.at(0));
      final b = tester.getSize(cells.at(1));
      final c = tester.getSize(cells.at(2));
      expect(a.height, b.height);
      expect(b.height, c.height);
      expect(a.width / b.width, closeTo(1.3, 0.02));
      expect(find.text('REVENUE'), findsOneWidget);
      expect(colorOf(tester, '4'), lightTheme.warningInk);
      expect(colorOf(tester, '38'), lightTheme.foreground);
    });

    testWidgets('a row too narrow for its figures stacks them, never '
        'shrinking one', (tester) async {
      // The strip's three cells cannot share 200 px: one under another.
      await tester.pumpWidget(
        displayHost(const SizedBox(width: 200, child: orders)),
      );
      final cells = find.byType(MinimalStat);
      final first = tester.getRect(cells.at(0));
      final second = tester.getRect(cells.at(1));
      expect(second.top, greaterThan(first.top));
      expect(second.left, first.left);
      expect(
        find.descendant(
          of: find.byType(MinimalStatRow),
          matching: find.byType(FittedBox),
        ),
        findsNothing,
      );
      // Four tiles at 280 px go two to a row.
      const tile = MinimalStat(label: 'Kept', value: '12d');
      await tester.pumpWidget(
        displayHost(
          const SizedBox(
            width: 280,
            child: MinimalStatRow(children: [tile, tile, tile, tile]),
          ),
        ),
      );
      final tiles = [
        for (var i = 0; i < 4; i++)
          tester.getRect(find.byType(MinimalStat).at(i)),
      ];
      expect(tiles[1].top, tiles[0].top);
      expect(tiles[2].top, greaterThan(tiles[0].bottom));
      expect(tiles[2].left, tiles[0].left);
    });

    testWidgets('a selected KPI stands on a foot in ink, no fill', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        final t = MinimalThemeData.preset('standard', brightness);
        await tester.pumpWidget(
          MaterialApp(
            home: MinimalHost(
              light: lightTheme,
              dark: MinimalThemeData.preset('standard', Brightness.dark),
              brightness: brightness,
              child: const MinimalStatRow.joined(
                children: [
                  MinimalStat(label: 'Open', value: '6', selected: true),
                  MinimalStat(label: 'Late', value: '4'),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final open = find.byType(MinimalStat).first;
        final fills = tester
            .widgetList<DecoratedBox>(
              find.descendant(of: open, matching: find.byType(DecoratedBox)),
            )
            .map((b) => b.decoration)
            .whereType<BoxDecoration>()
            .where((d) => d.color != null);
        expect(fills, isEmpty);
        // The foot: one straight bar of its width along the bottom edge,
        // standing in from the strip's bottom-start corner rather than
        // bending round it (or running over the strip's rim).
        final size = tester.getSize(open);
        const foot = MinimalStat.footWidth;
        // A paint keeps 8-bit channels; the theme's colours are floats.
        bool inInk(Symbol method, List<dynamic> args) =>
            method == #drawRect &&
            (args[1] as Paint).color.toARGB32() == t.foreground.toARGB32();
        expect(
          open,
          paints..something((method, args) {
            if (!inInk(method, args)) return false;
            final bar = args[0] as Rect;
            return (bar.bottom - size.height).abs() < 0.01 &&
                (bar.height - foot).abs() < 0.01 &&
                bar.left > 0 &&
                (bar.right - size.width).abs() < 0.01;
          }),
        );
        expect(find.byType(MinimalStat).last, isNot(paints..something(inInk)));
      }
    });

    testWidgets('each KPI reads as one line', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(displayHost(orders));
      final node = tester.getSemantics(find.byType(MinimalStat).first);
      expect(node.label, contains('REVENUE'));
      expect(node.label, contains('€1,284'));
      expect(node.label, contains('+12% vs last Fri'));
      handle.dispose();
    });

    testWidgets('tappable KPI cells fire and say which one is selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var showing = 'Open';
      await tester.pumpWidget(
        displayHost(
          StatefulBuilder(
            builder: (context, setState) => MinimalStatRow.joined(
              children: [
                for (final (label, value) in const [
                  ('Open', '6'),
                  ('Late', '4'),
                ])
                  MinimalStat(
                    label: label,
                    value: value,
                    selected: showing == label,
                    onPressed: () => setState(() => showing = label),
                  ),
              ],
            ),
          ),
        ),
      );
      bool selected(String label) =>
          tester
              .getSemantics(find.bySemanticsLabel(RegExp(label)))
              .getSemanticsData()
              .flagsCollection
              .isSelected ==
          Tristate.isTrue;
      expect(selected('OPEN'), isTrue);
      expect(selected('LATE'), isFalse);
      await tester.tap(find.text('LATE'));
      await tester.pump();
      expect(showing, 'Late');
      expect(selected('LATE'), isTrue);
      expect(selected('OPEN'), isFalse);
      handle.dispose();
    });

    testWidgets('a heatmap draws weeks by seven and announces the record', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        displayHost(
          MinimalHeatmap(
            levels: [for (var i = 0; i < 82; i++) i % 3],
            today: 81,
          ),
        ),
      );
      final size = tester.getSize(
        find
            .descendant(
              of: find.byType(MinimalHeatmap),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      // Today's rim stands inside its square: the grid is its squares and
      // gaps alone, flush with the column's start.
      expect(
        size.width,
        12 * (MinimalHeatmap.cell + MinimalHeatmap.gap) - MinimalHeatmap.gap,
      );
      expect(
        size.height,
        7 * (MinimalHeatmap.cell + MinimalHeatmap.gap) - MinimalHeatmap.gap,
      );
      expect(find.bySemanticsLabel('54 of 82 days kept'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a long heatmap shrinks its squares to fit the width', (
      tester,
    ) async {
      await tester.pumpWidget(
        displayHost(
          SizedBox(
            width: 200,
            child: MinimalHeatmap(
              levels: List<int>.filled(30 * 7, 2),
              legend: true,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final grid = find.descendant(
        of: find.byType(MinimalHeatmap),
        matching: find.byType(CustomPaint),
      );
      expect(tester.getSize(grid.first).width, lessThanOrEqualTo(200));
      expect(find.text('Less'), findsOneWidget);
    });

    testWidgets('a heatmap of any length stays inside its width', (
      tester,
    ) async {
      for (final weeks in [70, 120]) {
        await tester.pumpWidget(
          displayHost(
            SizedBox(
              width: 358,
              child: MinimalHeatmap(
                levels: List<int>.filled(weeks * 7, 1),
                today: weeks * 7 - 1,
              ),
            ),
          ),
        );
        final grid = find.descendant(
          of: find.byType(MinimalHeatmap),
          matching: find.byType(CustomPaint),
        );
        expect(tester.getSize(grid.first).width, lessThanOrEqualTo(358));
        // Every square is painted inside the grid's box.
        final box = Offset.zero & tester.getSize(grid.first);
        expect(
          grid.first,
          paints..everything((method, args) {
            if (method != #drawRRect) return true;
            final rrect = args[0] as RRect;
            final paint = args[1] as Paint;
            final outer = paint.style == PaintingStyle.stroke
                ? rrect.outerRect.inflate(paint.strokeWidth / 2)
                : rrect.outerRect;
            return box.inflate(0.001).contains(outer.topLeft) &&
                box.inflate(0.001).contains(outer.bottomRight);
          }),
        );
      }
    });

    test('heatmap levels map to the success ramp', () {
      expect(MinimalHeatmap.levelColor(lightTheme, 0), lightTheme.border);
      expect(MinimalHeatmap.levelColor(lightTheme, 2), lightTheme.success);
      expect(MinimalHeatmap.levelColor(lightTheme, 7), lightTheme.success);
      // By night an empty day takes the stronger hairline, so it does not
      // sink into the dark ground.
      final dark = MinimalThemeData.preset('standard', Brightness.dark);
      expect(MinimalHeatmap.levelColor(dark, 0), dark.borderStrong);
    });
  });
}
