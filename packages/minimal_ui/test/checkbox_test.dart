import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/padded_host.dart';
import 'support/value_owner.dart';

void main() {
  group('MinimalCheckbox', () {
    testWidgets('a tap ticks it, and it announces its checked state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <bool>[];
      await tester.pumpWidget(
        paddedHost(
          ValueOwner<bool>(
            initial: false,
            builder: (v, set) => MinimalCheckbox(
              value: v,
              semanticLabel: 'Meditate',
              onChanged: (next) {
                seen.add(next);
                set(next);
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byType(MinimalCheckbox));
      await tester.pumpAndSettle();
      expect(seen, [true]);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Meditate')),
        matchesSemantics(
          label: 'Meditate',
          isButton: false,
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('MinimalCheckMark is a mark: checked, not a control', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        paddedHost(const MinimalCheckMark(value: true, semanticLabel: 'Kept')),
      );
      expect(find.byType(MinimalPressable), findsNothing);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Kept')),
        matchesSemantics(label: 'Kept', hasCheckedState: true, isChecked: true),
      );
      handle.dispose();
    });

    testWidgets('a null onChanged disables it: it dims', (tester) async {
      await tester.pumpWidget(
        paddedHost(const MinimalCheckbox(value: false, onChanged: null)),
      );
      final opacity = tester.widget<AnimatedOpacity>(
        find
            .descendant(
              of: find.byType(MinimalPressable),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      );
      expect(opacity.opacity, 0.45);
    });
  });
}
