import 'dart:ui' show CheckedState, Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'faces.dart';
import 'support/display_host.dart';

void main() {
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

    testWidgets('a status glyph with an action is a labelled checkbox', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        displayHost(
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
      final control = tester.getSemantics(find.bySemanticsLabel('Todo'));
      expect(control.getSemanticsData().flagsCollection.isButton, isFalse);
      expect(
        control.getSemanticsData().flagsCollection.isChecked,
        CheckedState.isFalse,
      );
      await tester.tap(find.byType(MinimalStatusIcon).first);
      expect(taps, 1);
      // 18 px paints, the tap floor lands: the glyph on its start keyline, its
      // target reaching on past it.
      final box = faceOf(tester, find.byType(MinimalStatusIcon).first);
      expect(box.width, MinimalIconSize.i18);
      await tester.tapAt(box.centerRight + const Offset(10, 0));
      expect(taps, 2);
      expect(find.bySemanticsLabel('Meditate, done'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a done control says it is checked', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        displayHost(
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
      expect(done.getSemanticsData().flagsCollection.isButton, isFalse);
      expect(
        done.getSemanticsData().flagsCollection.isChecked,
        CheckedState.isTrue,
      );
      final journal = tester.getSemantics(find.bySemanticsLabel('Journal'));
      expect(
        journal.getSemanticsData().flagsCollection.isChecked,
        CheckedState.isTrue,
      );
      handle.dispose();
    });

    testWidgets('done and cancelled cut their mark out of the disc', (
      tester,
    ) async {
      await tester.pumpWidget(
        displayHost(
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
              light: lightTheme,
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
        displayHost(
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
      expect(colorOf(tester, 'Late'), lightTheme.warningInk);
      expect(colorOf(tester, 'Baking'), lightTheme.foreground);
      expect(colorOf(tester, 'Queued'), lightTheme.foreground);
      expect(colorOf(tester, 'Done'), lightTheme.successInk);
    });

    testWidgets('a group header is a header, with its count', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        displayHost(const MinimalSectionHeader('Morning', count: '2/3')),
      );
      expect(find.text('MORNING'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('MORNING')),
      );
      expect(node.getSemanticsData().flagsCollection.isHeader, isTrue);
      expect(node.getSemanticsData().flagsCollection.isButton, isFalse);
      handle.dispose();
    });

    testWidgets('a collapsible header toggles and says whether it is open', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var open = true;
      await tester.pumpWidget(
        displayHost(
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
      expect(node().getSemanticsData().flagsCollection.isButton, isTrue);
      expect(node().getSemanticsData().flagsCollection.isHeader, isTrue);
      expect(
        node().getSemanticsData().flagsCollection.isExpanded,
        Tristate.isTrue,
      );
      await tester.tap(find.text('EVENING'));
      await tester.pumpAndSettle();
      expect(open, isFalse);
      expect(
        node().getSemanticsData().flagsCollection.isExpanded,
        Tristate.isFalse,
      );
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
        displayHost(
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
      expect(toggle.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(add.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(toggle.getSemanticsData().label, isNot(contains('Add habit')));
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
        displayHost(
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
        displayHost(
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
          displayHost(
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
}
