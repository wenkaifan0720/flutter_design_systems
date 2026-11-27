import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/display_host.dart';

void main() {
  group('stats', () {
    testWidgets('a stat tile prints its label upper-cased and reads as one', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        displayHost(
          const MinimalStat(
            label: 'Streak',
            value: '12d',
            delta: '3d',
            detail: 'best 21d',
          ),
        ),
      );
      expect(find.text('STREAK'), findsOneWidget);
      expect(find.text('12d'), findsOneWidget);
      final node = tester.getSemantics(find.byType(MinimalStat));
      expect(node.label, contains('STREAK'));
      expect(node.label, contains('12d'));
      expect(node.label, contains('up 3d'));
      expect(node.label, contains('best 21d'));
      handle.dispose();
    });

    testWidgets('the delta colours by goodness, not direction', (tester) async {
      await tester.pumpWidget(
        displayHost(
          const Column(
            children: [
              MinimalStat(label: 'Kept', value: '23', delta: '4'),
              MinimalStat(
                label: 'Missed',
                value: '5',
                delta: '2',
                deltaUp: false,
                deltaGood: true,
              ),
              MinimalStat(
                label: 'Late',
                value: '9',
                delta: '1',
                deltaGood: false,
              ),
            ],
          ),
        ),
      );
      // The delta is words: the tone's ink, not its fill.
      expect(colorOf(tester, '4'), lightTheme.successInk);
      expect(colorOf(tester, '2'), lightTheme.successInk);
      expect(colorOf(tester, '1'), lightTheme.destructiveInk);
    });

    testWidgets('a tappable tile is a button and fires', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        displayHost(
          MinimalStat(label: 'Kept', value: '5/7', onPressed: () => taps += 1),
        ),
      );
      await tester.tap(find.text('5/7'));
      expect(taps, 1);
      final node = tester.getSemantics(find.bySemanticsLabel(RegExp('KEPT')));
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 2);
      handle.dispose();
    });

    testWidgets('a stat row matches its tiles\' heights', (tester) async {
      await tester.pumpWidget(
        displayHost(
          const MinimalStatRow(
            children: [
              MinimalStat(
                label: 'Streak',
                value: '12d',
                delta: '3d',
                spark: [1, 3, 2, 5],
              ),
              MinimalStat(label: 'August', value: '23/28'),
            ],
          ),
        ),
      );
      final tiles = find.byType(MinimalStat);
      expect(
        tester.getSize(tiles.at(0)).height,
        tester.getSize(tiles.at(1)).height,
      );
    });

    testWidgets('a progress bar clamps and announces its percentage', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        displayHost(
          const Column(
            children: [
              MinimalLinearProgressIndicator(
                value: 0.62,
                semanticLabel: 'Upload',
              ),
              MinimalLinearProgressIndicator(value: 1.4, semanticLabel: 'Goal'),
              MinimalLinearProgressIndicator(value: -1, semanticLabel: 'Empty'),
            ],
          ),
        ),
      );
      expect(tester.getSemantics(find.bySemanticsLabel('Upload')).value, '62%');
      expect(tester.getSemantics(find.bySemanticsLabel('Goal')).value, '100%');
      expect(tester.getSemantics(find.bySemanticsLabel('Empty')).value, '0%');
      final bar = tester.getSize(
        find.byType(MinimalLinearProgressIndicator).first,
      );
      expect(bar.height, MinimalLinearProgressIndicator.thickness);
      handle.dispose();
    });

    testWidgets('the bars chart lights the highest bar, or the one named', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      int? picked;
      await tester.pumpWidget(
        displayHost(
          StatefulBuilder(
            builder: (context, setState) => MinimalBarChart(
              const [4, 9, 6],
              labels: const ['M', 'T', 'W'],
              highlight: picked,
              onBarPressed: (i) => setState(() => picked = i),
            ),
          ),
        ),
      );
      bool selected(String label) =>
          tester
              .getSemantics(find.bySemanticsLabel(label))
              .getSemanticsData()
              .flagsCollection
              .isSelected ==
          Tristate.isTrue;
      expect(selected('T: 9'), isTrue);
      expect(selected('M: 4'), isFalse);
      await tester.tap(find.text('M'));
      await tester.pump();
      expect(picked, 0);
      expect(selected('M: 4'), isTrue);
      expect(selected('T: 9'), isFalse);
      handle.dispose();
    });

    testWidgets('a static chart is not a control, and survives an empty '
        'series', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        displayHost(
          const Column(
            children: [
              MinimalBarChart([0, 0, 0], labels: ['M', 'T', 'W'], height: 40),
              MinimalBarChart([], height: 40),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final node = tester.getSemantics(find.bySemanticsLabel('M: 0'));
      expect(node.getSemanticsData().flagsCollection.isButton, isFalse);
      handle.dispose();
    });

    testWidgets('a sparkline is decoration unless it is labelled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        displayHost(
          const Column(
            children: [
              MinimalSparkline([1, 2, 3], height: 20),
              MinimalSparkline([4], height: 20),
              MinimalSparkline([3, 1, 4], height: 20, semanticLabel: 'Rising'),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Rising'), findsOneWidget);
      expect(tester.getSize(find.byType(MinimalSparkline).first).height, 20);
      handle.dispose();
    });

    testWidgets('a flat sparkline runs through the middle, not the floor', (
      tester,
    ) async {
      await tester.pumpWidget(
        displayHost(
          const SizedBox(
            width: 100,
            child: MinimalSparkline([5, 5, 5, 5], height: 40),
          ),
        ),
      );
      // The first path is the faint area: from the line down to the foot.
      expect(
        find.descendant(
          of: find.byType(MinimalSparkline),
          matching: find.byType(CustomPaint),
        ),
        paints..path(
          includes: const [Offset(50, 22), Offset(50, 38)],
          excludes: const [Offset(50, 18), Offset(50, 4)],
        ),
      );
    });

    testWidgets('a tile and a KPI share one delta contract', (tester) async {
      await tester.pumpWidget(
        displayHost(
          const Column(
            children: [
              MinimalStat(label: 'Kept', value: '23', delta: '+12%'),
              MinimalStatRow.joined(
                children: [
                  MinimalStat(
                    label: 'Prep',
                    value: '14m',
                    delta: '2m',
                    deltaUp: false,
                  ),
                  MinimalStat(label: 'Orders', value: '38', delta: '+6'),
                ],
              ),
            ],
          ),
        ),
      );
      // The tile draws its sign as the arrow, the KPI prints it.
      expect(find.text('12%'), findsOneWidget);
      expect(find.textContaining('−2m'), findsOneWidget);
      expect(find.textContaining('+6'), findsOneWidget);
      expect(find.textContaining('++6'), findsNothing);
      expect(MinimalStat.magnitude('−3'), '3');
      expect(MinimalStat.magnitude('- 3'), '3');
      expect(MinimalStat.magnitude('3%'), '3%');
    });

    testWidgets('a progress bar jumps under reduced motion', (tester) async {
      Widget bar(double v) => displayHost(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: SizedBox(
            width: 200,
            child: MinimalLinearProgressIndicator(
              value: v,
              semanticLabel: 'Progress',
            ),
          ),
        ),
      );
      await tester.pumpWidget(bar(0.25));
      await tester.pumpWidget(bar(0.75));
      await tester.pump();
      // The innermost coloured box is the fill; the outer one the track.
      final fill = tester.getSize(
        find
            .descendant(
              of: find.byType(MinimalLinearProgressIndicator),
              matching: find.byType(ColoredBox),
            )
            .last,
      );
      expect(fill.width, closeTo(150, 0.01));
    });
  });
}
