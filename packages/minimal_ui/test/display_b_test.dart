import 'dart:ui' show CheckedState, Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

final MinimalThemeData _light = MinimalThemeData.preset(
  'standard',
  Brightness.light,
);

Widget _host(Widget child) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: _light,
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    body: Center(
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    ),
  ),
);

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  group('stats', () {
    testWidgets('a stat tile prints its label upper-cased and reads as one', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
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
        _host(
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
      expect(_colorOf(tester, '4'), _light.successInk);
      expect(_colorOf(tester, '2'), _light.successInk);
      expect(_colorOf(tester, '1'), _light.destructiveInk);
    });

    testWidgets('a tappable tile is a button and fires', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          MinimalStat(label: 'Kept', value: '5/7', onPressed: () => taps += 1),
        ),
      );
      await tester.tap(find.text('5/7'));
      expect(taps, 1);
      final node = tester.getSemantics(find.bySemanticsLabel(RegExp('KEPT')));
      expect(node.flagsCollection.isButton, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 2);
      handle.dispose();
    });

    testWidgets('a stat row matches its tiles\' heights', (tester) async {
      await tester.pumpWidget(
        _host(
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
        _host(
          const Column(
            children: [
              MinimalLinearProgressIndicator(value: 0.62, label: 'Upload'),
              MinimalLinearProgressIndicator(value: 1.4, label: 'Goal'),
              MinimalLinearProgressIndicator(value: -1, label: 'Empty'),
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
        _host(
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
        _host(
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
      expect(node.flagsCollection.isButton, isFalse);
      handle.dispose();
    });

    testWidgets('a sparkline is decoration unless it is labelled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
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
        _host(
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
        _host(
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
      Widget bar(double v) => _host(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: SizedBox(
            width: 200,
            child: MinimalLinearProgressIndicator(value: v, label: 'Progress'),
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

  group('status', () {
    test('every status has a label and a tone', () {
      expect(MinimalTaskStatus.active.label, 'In progress');
      expect(MinimalTaskStatus.done.tone, MinimalTone.success);
      expect(MinimalTaskStatus.active.tone, MinimalTone.warning);
      expect(
        MinimalTaskStatus.values.map((s) => s.label).toSet().length,
        MinimalTaskStatus.values.length,
      );
    });

    testWidgets('a status glyph with an action is a labelled button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100,
                height: 44,
                child: Center(
                  child: MinimalStatusIcon(
                    MinimalTaskStatus.todo,
                    onPressed: () => taps += 1,
                  ),
                ),
              ),
              const MinimalStatusIcon(
                MinimalTaskStatus.done,
                semanticLabel: 'Meditate, done',
              ),
            ],
          ),
        ),
      );
      final button = tester.getSemantics(find.bySemanticsLabel('Todo'));
      expect(button.flagsCollection.isButton, isTrue);
      expect(button.flagsCollection.isChecked, CheckedState.isFalse);
      await tester.tap(find.byType(MinimalStatusIcon).first);
      expect(taps, 1);
      // 18 px paints, 44 px lands.
      final box = tester.getRect(find.byType(MinimalStatusIcon).first);
      expect(box.width, MinimalIconSize.i18);
      await tester.tapAt(box.centerLeft - const Offset(10, 0));
      expect(taps, 2);
      expect(find.bySemanticsLabel('Meditate, done'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a done control says it is checked', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinimalStatusIcon(
                MinimalTaskStatus.done,
                semanticLabel: 'Meditate',
                onPressed: () {},
              ),
              MinimalStatusIcon(
                MinimalTaskStatus.active,
                semanticLabel: 'Journal',
                checked: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      final done = tester.getSemantics(find.bySemanticsLabel('Meditate'));
      expect(done.flagsCollection.isButton, isTrue);
      expect(done.flagsCollection.isChecked, CheckedState.isTrue);
      final journal = tester.getSemantics(find.bySemanticsLabel('Journal'));
      expect(journal.flagsCollection.isChecked, CheckedState.isTrue);
      handle.dispose();
    });

    testWidgets('done and cancelled cut their mark out of the disc', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinimalStatusIcon(MinimalTaskStatus.done),
              MinimalStatusIcon(MinimalTaskStatus.cancelled),
            ],
          ),
        ),
      );
      // Each glyph's calls, with the blend mode of any mark it strokes.
      List<String> calls(int i) {
        final seen = <String>[];
        expect(
          find
              .descendant(
                of: find.byType(MinimalStatusIcon).at(i),
                matching: find.byType(CustomPaint),
              )
              .first,
          paints..everything((method, args) {
            final paint = args.whereType<Paint>().firstOrNull;
            seen.add(
              paint?.blendMode == BlendMode.clear
                  ? '$method clear'
                  : method.toString(),
            );
            return true;
          }),
        );
        return seen;
      }

      String name(Symbol s) => s.toString();
      // The canvas wraps each paint in its own save and translate.
      expect(
        calls(0),
        containsAllInOrder([
          name(#saveLayer),
          name(#drawCircle),
          '${name(#drawPath)} clear',
          name(#restore),
        ]),
      );
      expect(
        calls(1),
        containsAllInOrder([
          name(#saveLayer),
          name(#drawCircle),
          '${name(#drawLine)} clear',
          '${name(#drawLine)} clear',
          name(#restore),
        ]),
      );
    });

    testWidgets('every glyph paints in light and dark', (tester) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: MinimalHost(
              light: _light,
              dark: MinimalThemeData.preset('standard', Brightness.dark),
              brightness: brightness,
              child: Row(
                children: [
                  for (final s in MinimalTaskStatus.values)
                    MinimalStatusIcon(s),
                ],
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('badges ink the label only for the tones that need '
        'attention', (tester) async {
      await tester.pumpWidget(
        _host(
          Wrap(
            children: [
              const MinimalStatusBadge('Late', tone: MinimalTone.warning),
              const MinimalStatusBadge('Baking', tone: MinimalTone.primary),
              const MinimalStatusBadge('Queued'),
              MinimalStatusBadge.status(MinimalTaskStatus.done),
            ],
          ),
        ),
      );
      expect(_colorOf(tester, 'Late'), _light.warningInk);
      expect(_colorOf(tester, 'Baking'), _light.foreground);
      expect(_colorOf(tester, 'Queued'), _light.foreground);
      expect(_colorOf(tester, 'Done'), _light.successInk);
    });

    testWidgets('a group header is a header, with its count', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const MinimalSectionHeader('Morning', count: '2/3')),
      );
      expect(find.text('MORNING'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('MORNING')),
      );
      expect(node.flagsCollection.isHeader, isTrue);
      expect(node.flagsCollection.isButton, isFalse);
      handle.dispose();
    });

    testWidgets('a collapsible header toggles and says whether it is open', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var open = true;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => MinimalSectionHeader(
              'Evening',
              count: '1/2',
              expanded: open,
              onExpansionChanged: (_) => setState(() => open = !open),
            ),
          ),
        ),
      );
      SemanticsNode node() =>
          tester.getSemantics(find.bySemanticsLabel(RegExp('EVENING')));
      expect(node().flagsCollection.isButton, isTrue);
      expect(node().flagsCollection.isHeader, isTrue);
      expect(node().flagsCollection.isExpanded, Tristate.isTrue);
      await tester.tap(find.text('EVENING'));
      await tester.pumpAndSettle();
      expect(open, isFalse);
      expect(node().flagsCollection.isExpanded, Tristate.isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(open, isTrue);
      handle.dispose();
    });

    testWidgets('a collapsible header keeps its trailing action outside '
        'the toggle', (tester) async {
      final handle = tester.ensureSemantics();
      var toggles = 0;
      var adds = 0;
      await tester.pumpWidget(
        _host(
          MinimalSectionHeader(
            'Evening',
            trailing: MinimalIconButton(
              Icons.add,
              label: 'Add habit',
              size: MinimalButtonSize.small,
              onPressed: () => adds += 1,
            ),
            onExpansionChanged: (_) => toggles += 1,
          ),
        ),
      );
      final toggle = tester.getSemantics(
        find.bySemanticsLabel(RegExp('EVENING')),
      );
      final add = tester.getSemantics(find.bySemanticsLabel('Add habit'));
      expect(toggle.flagsCollection.isButton, isTrue);
      expect(add.flagsCollection.isButton, isTrue);
      expect(toggle.label, isNot(contains('Add habit')));
      await tester.tap(find.bySemanticsLabel('Add habit'));
      expect(adds, 1);
      expect(toggles, 0);
      await tester.tap(find.text('EVENING'));
      expect(toggles, 1);
      expect(adds, 1);
      handle.dispose();
    });

    testWidgets('a segment bar counts n of m and prints its figure', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              MinimalSegmentBar(
                value: 3,
                total: 5,
                label: 'kept',
                showPercent: true,
              ),
              MinimalSegmentBar(value: 0, total: 0, semanticLabel: 'Weekends'),
              MinimalSegmentBar(value: 9, total: 4, semanticLabel: 'Over'),
            ],
          ),
        ),
      );
      final kept = tester.getSemantics(find.bySemanticsLabel('3 of 5 kept'));
      expect(kept.value, '60%');
      expect(find.text('60%'), findsOneWidget);
      expect(tester.getSemantics(find.bySemanticsLabel('Weekends')).value, '—');
      expect(tester.getSemantics(find.bySemanticsLabel('Over')).value, '100%');
      handle.dispose();
    });

    testWidgets('week dots draw seven squares and count the kept days', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const MinimalWeekDots(
            completedDays: [false, true, true, true, true, false, false],
            currentDay: 4,
          ),
        ),
      );
      expect(find.bySemanticsLabel('4 of 7 days kept'), findsOneWidget);
      final size = tester.getSize(find.byType(MinimalWeekDots));
      expect(size.width, 7 * MinimalWeekDots.square + 6 * MinimalWeekDots.gap);
      expect(size.height, MinimalWeekDots.square);
      handle.dispose();
    });

    testWidgets('today is ringed in the week dots, its own day inside', (
      tester,
    ) async {
      final t = MinimalThemeData.preset('standard', Brightness.light);
      for (final keptToday in [true, false]) {
        await tester.pumpWidget(
          _host(
            MinimalWeekDots(
              completedDays: [true, true, true, true, keptToday, false, false],
              currentDay: 4,
            ),
          ),
        );
        final squares = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byType(MinimalWeekDots),
                matching: find.byType(Container),
              ),
            )
            .map((c) => c.decoration! as BoxDecoration)
            .toList();
        expect(squares, hasLength(7));
        final today = squares[4];
        expect(today.color, keptToday ? squares[3].color : t.border);
        expect(today.border, Border.all(color: t.foreground, width: 1.5));
        expect(squares[3].color, isNotNull);
        expect(squares[3].border, isNull);
      }
    });
  });

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
      await tester.pumpWidget(_host(orders));
      final cells = find.byType(MinimalStat);
      final a = tester.getSize(cells.at(0));
      final b = tester.getSize(cells.at(1));
      final c = tester.getSize(cells.at(2));
      expect(a.height, b.height);
      expect(b.height, c.height);
      expect(a.width / b.width, closeTo(1.3, 0.02));
      expect(find.text('REVENUE'), findsOneWidget);
      expect(_colorOf(tester, '4'), _light.warningInk);
      expect(_colorOf(tester, '38'), _light.foreground);
    });

    testWidgets('a row too narrow for its figures stacks them, never '
        'shrinking one', (tester) async {
      // The strip's three cells cannot share 200 px: one under another.
      await tester.pumpWidget(_host(SizedBox(width: 200, child: orders)));
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
        _host(
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
              light: _light,
              dark: MinimalThemeData.preset('standard', Brightness.dark),
              brightness: brightness,
              child: MinimalStatRow.joined(
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
      await tester.pumpWidget(_host(orders));
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
        _host(
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
        _host(
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
        _host(
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
          _host(
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
      expect(MinimalHeatmap.levelColor(_light, 0), _light.border);
      expect(MinimalHeatmap.levelColor(_light, 2), _light.success);
      expect(MinimalHeatmap.levelColor(_light, 7), _light.success);
      // By night an empty day takes the stronger hairline, so it does not
      // sink into the dark ground.
      final dark = MinimalThemeData.preset('standard', Brightness.dark);
      expect(MinimalHeatmap.levelColor(dark, 0), dark.borderStrong);
    });
  });
}
