import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'support/padded_host.dart';
import 'support/value_owner.dart';

void main() {
  group('MinimalTabBar', () {
    testWidgets('a tap picks a tab; counts print; arrows move it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <int>[];
      await tester.pumpWidget(
        paddedHost(
          SizedBox(
            width: 340,
            child: ValueOwner<int>(
              initial: 0,
              builder: (v, set) => MinimalTabBar(
                tabs: const ['Overview', 'Activity', 'Notes'],
                counts: const [null, 12, 3],
                selectedIndex: v,
                onChanged: (next) {
                  seen.add(next);
                  set(next);
                },
              ),
            ),
          ),
        ),
      );
      expect(find.text('12'), findsOneWidget);
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      expect(seen, [1]);
      final node = tester.getSemantics(find.text('Activity'));
      expect(
        node.getSemanticsData().flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(node.getSemanticsData().role, SemanticsRole.tab);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(seen, [1, 2]);
      // Focus moved with the choice: Enter and Space keep it.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(seen, [1, 2]);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(seen, [1, 2, 0]);
      expect(tester.getSize(find.byType(MinimalTabBar)).height, 44);
      handle.dispose();
    });

    testWidgets('the first label sits exactly on the strip inset', (
      tester,
    ) async {
      await tester.pumpWidget(
        paddedHost(
          SizedBox(
            width: 340,
            child: MinimalTabBar(
              tabs: const ['Overview', 'Activity'],
              selectedIndex: 0,
              padding: MinimalInsets.gutter,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      final strip = tester.getRect(find.byType(MinimalTabBar));
      final label = tester.getRect(find.text('Overview'));
      expect(label.left - strip.left, MinimalChromeMetrics.gutter);
    });

    testWidgets('with no onChanged the strip is disabled', (tester) async {
      await tester.pumpWidget(
        paddedHost(
          const SizedBox(
            width: 340,
            child: MinimalTabBar(
              tabs: ['Overview', 'History'],
              selectedIndex: 0,
            ),
          ),
        ),
      );
      await tester.tap(find.text('History'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final node = tester.getSemantics(find.text('History'));
      expect(
        node.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );
    });
  });
}
