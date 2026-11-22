import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/scrolling_host.dart';

void main() {
  group('MinimalChoiceRow', () {
    testWidgets('it is a checked radio of a mutually exclusive set', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        scrollingHost(
          MinimalSelectionGroup(
            children: [
              MinimalChoiceRow(
                title: 'Every day',
                selected: true,
                onPressed: () => taps += 1,
              ),
              const MinimalChoiceRow(title: 'Weekly', selected: false),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Every day')),
        matchesSemantics(
          label: 'Every day',
          isButton: false,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      final weekly = tester.getSemantics(find.bySemanticsLabel('Weekly'));
      expect(
        weekly.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      await tester.tap(find.text('Every day'));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('rich content keeps the title as what is announced', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        scrollingHost(
          MinimalChoiceRow(
            title: 'Morning run, HAB-4',
            selected: false,
            onPressed: () {},
            content: const Text('HAB-4'),
          ),
        ),
      );
      expect(
        find.bySemanticsLabel(RegExp('^Morning run, HAB-4')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a group is one Tab stop whose arrow keys choose', (
      tester,
    ) async {
      final chosen = <String>[];
      var choice = 'Morning';
      await tester.pumpWidget(
        scrollingHost(
          StatefulBuilder(
            builder: (context, setState) => MinimalSelectionGroup(
              children: [
                for (final label in const ['Morning', 'Afternoon', 'Evening'])
                  MinimalChoiceRow(
                    title: label,
                    selected: label == choice,
                    onPressed: () => setState(() {
                      chosen.add(label);
                      choice = label;
                    }),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(chosen, ['Afternoon', 'Evening']);
      // Space on the choice presses it again, as its pressable did.
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(chosen, ['Afternoon', 'Evening', 'Evening']);
    });
  });
}
