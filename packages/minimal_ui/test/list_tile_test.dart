import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'support/column_host.dart';

void main() {
  group('MinimalListTile', () {
    testWidgets('is 44 tall, 36 dense, and taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        columnHost(
          Column(
            children: [
              MinimalListTile(
                key: const Key('row'),
                title: 'Drink water',
                meta: '10d',
                chevron: true,
                onTap: () => taps += 1,
              ),
              const MinimalListTile(
                key: Key('dense'),
                title: 'Hanna Berg',
                dense: true,
              ),
            ],
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('row'))).height, 44);
      expect(tester.getSize(find.byKey(const Key('dense'))).height, 36);
      expect(find.text('10d'), findsOneWidget);
      await tester.tap(find.text('Drink water'));
      expect(taps, 1);
    });

    testWidgets('a disabled row swallows taps and says it is disabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        columnHost(
          MinimalListTile(
            title: 'Water the plants',
            enabled: false,
            onTap: () => taps += 1,
          ),
        ),
      );
      await tester.tap(find.text('Water the plants'), warnIfMissed: false);
      expect(taps, 0);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Water the plants')),
        matchesSemantics(
          label: 'Water the plants',
          isButton: true,
          hasEnabledState: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('selected is announced, tappable or not', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        columnHost(
          Column(
            children: [
              MinimalListTile(
                title: 'Morning run',
                selected: true,
                onTap: () {},
              ),
              const MinimalListTile(title: 'Journal', selected: true),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Morning run')),
        matchesSemantics(
          label: 'Morning run',
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
      expect(
        tester.getSemantics(find.bySemanticsLabel('Journal')),
        matchesSemantics(
          label: 'Journal',
          hasSelectedState: true,
          isSelected: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a row activates from the keyboard', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        columnHost(MinimalListTile(title: 'Meditate', onTap: () => taps += 1)),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('keyboard focus draws the ring inside the row', (tester) async {
      await tester.pumpWidget(
        columnHost(MinimalListTile(title: 'Meditate', onTap: () {})),
      );
      Iterable<Container> ringed() => tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(MinimalListTile),
              matching: find.byType(Container),
            ),
          )
          .where(
            (c) =>
                (c.foregroundDecoration as BoxDecoration?)?.border ==
                Border.all(
                  color: lightTheme.ring,
                  width: MinimalChromeMetrics.focusRing,
                ),
          );
      expect(ringed(), isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(ringed(), hasLength(1));
    });

    testWidgets('a long title ellipsizes instead of overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        columnHost(
          MinimalListTile(
            title: 'A habit with a name far longer than any row could hold',
            subtitle: 'And a caption that is also far too long to fit here',
            trailing: const MinimalTag('Late', tone: MinimalTone.warning),
            meta: '09:30',
            chevron: true,
            onTap: () {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
