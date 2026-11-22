import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/page_host.dart';

void main() {
  group('MinimalProperty', () {
    testWidgets('an editable row is a labelled button', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        pageApp(
          MinimalDescriptionList(
            properties: [
              MinimalProperty(
                icon: LucideIcons.circleDot,
                label: 'Status',
                value: 'Active',
                tone: MinimalTone.success,
                onPressed: () => taps++,
              ),
              const MinimalProperty(
                icon: LucideIcons.flame,
                label: 'Streak',
                value: '12d',
                mono: true,
                detail: 'best 21d',
              ),
              const MinimalProperty(icon: LucideIcons.target, label: 'Goal'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Status'));
      expect(taps, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Status, Active')),
        isSemantics(isButton: true, isEnabled: true),
      );
      expect(find.text('Empty'), findsOneWidget);
      expect(
        find.textContaining('best 21d', findRichText: true),
        findsOneWidget,
      );
      // A row that only reads is not a control.
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Streak'))),
        isSemantics(isButton: false),
      );
    });

    testWidgets('a widget value speaks for itself after the label', (
      tester,
    ) async {
      await tester.pumpWidget(
        pageApp(
          MinimalDescriptionList(
            properties: [
              MinimalProperty(
                icon: LucideIcons.user,
                label: 'Owner',
                onPressed: () {},
                child: const Text('Ana Berg'),
              ),
              MinimalProperty(
                icon: LucideIcons.user,
                label: 'Reviewer',
                semanticValue: 'Ines Duarte',
                onPressed: () {},
                child: const Text('ID'),
              ),
              const MinimalProperty(
                icon: LucideIcons.flame,
                label: 'Streak',
                value: '12d',
                mono: true,
                detail: 'best 21d',
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Owner, Empty'), findsNothing);
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(RegExp(r'^Owner\s+Ana Berg$')),
        ),
        isSemantics(isButton: true, isEnabled: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Reviewer, Ines Duarte')),
        isSemantics(isButton: true),
      );
      expect(find.bySemanticsLabel('Streak, 12d, best 21d'), findsOneWidget);
    });

    testWidgets('a pill announces its property and state', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        pageApp(
          MinimalPropertyBar(
            pills: [
              MinimalPropertyPill(
                icon: LucideIcons.bell,
                label: '21:30',
                name: 'Reminder',
                mono: true,
                hasValue: true,
                onPressed: () => taps++,
              ),
              MinimalPropertyPill(
                icon: LucideIcons.target,
                label: 'Goal',
                onPressed: () => taps++,
              ),
              const MinimalPropertyPill(icon: LucideIcons.lock, label: 'Area'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('21:30'));
      await tester.tap(find.text('Goal'));
      expect(taps, 2);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Reminder, 21:30')),
        isSemantics(isButton: true, isEnabled: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Goal, not set')),
        isSemantics(isButton: true, isEnabled: true),
      );
      // No handler: disabled, and a tap does nothing.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Area, not set')),
        isSemantics(isButton: true, isEnabled: false),
      );
      await tester.tap(find.text('Area'), warnIfMissed: false);
      expect(taps, 2);
    });
  });
}
