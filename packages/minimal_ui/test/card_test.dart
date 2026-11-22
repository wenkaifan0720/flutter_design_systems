import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/column_host.dart';

void main() {
  group('MinimalCard', () {
    testWidgets('a static card is not a control', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        columnHost(const MinimalCard(child: Text('Summary'))),
      );
      expect(find.byType(MinimalPressable), findsNothing);
      expect(
        tester.getSemantics(find.text('Summary')),
        isNot(matchesSemantics(isButton: true)),
      );
      handle.dispose();
    });

    testWidgets('a tappable card taps, and a selected one says so', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        columnHost(
          MinimalCard(
            selected: true,
            onPressed: () => taps += 1,
            child: const Text('Evening'),
          ),
        ),
      );
      await tester.tap(find.text('Evening'));
      expect(taps, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Evening')),
        matchesSemantics(
          label: 'Evening',
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

    testWidgets('a card activates from the keyboard', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        columnHost(
          MinimalCard(onPressed: () => taps += 1, child: const Text('Plan')),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('flat is the surfaceAlt panel, plain is the surface', (
      tester,
    ) async {
      Color fill() {
        final box = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(MinimalCard),
                matching: find.byType(Container),
              )
              .first,
        );
        return (box.decoration! as BoxDecoration).color!;
      }

      await tester.pumpWidget(columnHost(const MinimalCard(child: Text('a'))));
      expect(fill(), lightTheme.card);
      await tester.pumpWidget(
        columnHost(const MinimalCard(flat: true, child: Text('a'))),
      );
      await tester.pumpAndSettle();
      expect(fill(), lightTheme.muted);
    });

    testWidgets('an unselected option of a set announces it', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        columnHost(
          MinimalCard(
            selected: false,
            onPressed: () {},
            child: const Text('Morning'),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Morning')),
        matchesSemantics(
          label: 'Morning',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a lone row in a padded card stands at the card inset', (
      tester,
    ) async {
      await tester.pumpWidget(
        columnHost(
          const MinimalCard(child: MinimalListTile(title: 'Meditate')),
        ),
      );
      // The card's hairline and its 14 px padding; the row adds none.
      expect(
        tester.getTopLeft(find.text('Meditate')).dx -
            tester.getTopLeft(find.byType(MinimalCard)).dx,
        lightTheme.hairline + MinimalCard.inset,
      );
    });
  });
}
