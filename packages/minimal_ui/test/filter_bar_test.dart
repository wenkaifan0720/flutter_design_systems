import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/centred_host.dart';

void main() {
  group('MinimalFilterBar', () {
    testWidgets('a filter announces its count and its selection, and taps', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var view = 0;
      await tester.pumpWidget(
        centredHost(
          StatefulBuilder(
            builder: (context, setState) => MinimalFilterBar(
              children: [
                for (final (i, (label, count)) in const [
                  ('All', 6),
                  ('Open', 2),
                  ('Done', 3),
                ].indexed)
                  MinimalFilter(
                    label,
                    count: count,
                    selected: i == view,
                    onPressed: () => setState(() => view = i),
                  ),
              ],
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('All, 6')),
        matchesSemantics(
          label: 'All, 6',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Done, 3'));
      await tester.pump();
      expect(view, 2);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Done, 3')),
        matchesSemantics(
          label: 'Done, 3',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a filter with no action is disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        centredHost(const MinimalFilter('Archived', count: 0)),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Archived, 0')),
        matchesSemantics(
          label: 'Archived, 0',
          isButton: true,
          hasEnabledState: true,
          hasSelectedState: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('the keyboard reaches a filter and Enter selects it', (
      tester,
    ) async {
      var picked = '';
      await tester.pumpWidget(
        centredHost(
          MinimalFilterBar(
            children: [
              MinimalFilter('Open', onPressed: () => picked = 'Open'),
              MinimalFilter('Done', onPressed: () => picked = 'Done'),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, 'Done');
    });

    testWidgets('right to left, the trailing control holds the left end', (
      tester,
    ) async {
      await tester.pumpWidget(
        centredHost(
          SizedBox(
            width: 360,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: MinimalFilterBar(
                trailing: MinimalIconButton(
                  LucideIcons.slidersHorizontal,
                  label: 'Display',
                  onPressed: () {},
                ),
                children: [
                  MinimalFilter('Open', count: 2, onPressed: () {}),
                  MinimalFilter('Done', count: 3, onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      );
      final bar = tester.getRect(find.byType(MinimalFilterBar));
      final display = tester.getRect(find.bySemanticsLabel('Display'));
      final open = tester.getRect(find.bySemanticsLabel('Open, 2'));
      expect(display.center.dx, lessThan(open.center.dx));
      expect(open.center.dx, greaterThan(bar.center.dx));
      // The strip's end inset sits on the left, outside the control.
      expect(
        display.left - bar.left,
        moreOrLessEquals(MinimalFilterBar.defaultPadding.end),
      );
    });

    testWidgets('filters that outrun the width scroll, and the trailing '
        'control stays put', (tester) async {
      var display = 0;
      await tester.pumpWidget(
        centredHost(
          SizedBox(
            width: 300,
            child: MinimalFilterBar(
              trailing: MinimalIconButton(
                LucideIcons.slidersHorizontal,
                label: 'Display',
                onPressed: () => display += 1,
              ),
              children: [
                for (final label in const [
                  'Backlog',
                  'Todo',
                  'In progress',
                  'In review',
                  'Done',
                  'Cancelled',
                ])
                  MinimalFilter(label, count: 3, onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Display'));
      expect(display, 1);
    });
  });
}
