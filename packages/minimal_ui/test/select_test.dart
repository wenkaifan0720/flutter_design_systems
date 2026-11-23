import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/scrolling_host.dart';
import 'support/select_options.dart';

void main() {
  group('MinimalSelect', () {
    testWidgets('the menu shows the choice checked and picks another', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      String? chosen;
      await tester.pumpWidget(
        scrollingHost(
          MinimalSelect(
            labelText: 'Repeats',
            value: 'evening',
            options: selectOptions,
            onChanged: (v) => chosen = v,
          ),
        ),
      );
      await tester.tap(find.text('Every evening'));
      await tester.pumpAndSettle();
      // The row's value and the menu's item.
      expect(find.text('Every evening'), findsNWidgets(2));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Every day')),
        matchesSemantics(
          label: 'Every day',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasSelectedState: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      // A disabled option does nothing and keeps the menu open.
      await tester.tap(find.text('Custom…'));
      await tester.pumpAndSettle();
      expect(chosen, isNull);
      await tester.tap(find.text('Every day'));
      await tester.pumpAndSettle();
      expect(chosen, 'daily');
      expect(find.text('Every day'), findsNothing);
      handle.dispose();
    });

    testWidgets('the sheet presentation returns the chosen value', (
      tester,
    ) async {
      String? chosen;
      await tester.pumpWidget(
        scrollingHost(
          MinimalSelect(
            labelText: 'Repeats',
            value: 'daily',
            options: selectOptions,
            presentation: MinimalSelectPresentation.sheet,
            onChanged: (v) => chosen = v,
          ),
        ),
      );
      await tester.tap(find.text('Every day'));
      await tester.pumpAndSettle();
      expect(find.text('After 18:00'), findsOneWidget);
      await tester.tap(find.text('Every evening'));
      await tester.pumpAndSettle();
      expect(chosen, 'evening');
      expect(find.text('After 18:00'), findsNothing);
    });

    testWidgets('with no onChanged it is disabled and opens nothing', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        scrollingHost(
          const MinimalSelect(
            labelText: 'Owner',
            value: 'daily',
            options: selectOptions,
          ),
        ),
      );
      await tester.tap(find.text('Every day'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Every evening'), findsNothing);
      final node = tester.getSemantics(find.bySemanticsLabel(RegExp('Owner')));
      expect(
        node.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      // Its value drops to the quiet ink, so dimmed it never reads
      // stronger than an enabled row's.
      final t = MinimalThemeData.preset('standard', Brightness.light);
      expect(
        tester.widget<Text>(find.text('Every day')).style?.color,
        t.mutedForeground,
      );
      handle.dispose();
    });

    testWidgets('a placeholder stands in for no value', (tester) async {
      await tester.pumpWidget(
        scrollingHost(
          MinimalSelect(
            labelText: 'Area',
            value: null,
            options: selectOptions,
            hintText: 'None',
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('None'), findsOneWidget);
    });
  });
}
