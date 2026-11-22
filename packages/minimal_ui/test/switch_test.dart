import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'faces.dart';
import 'support/padded_host.dart';
import 'support/value_owner.dart';

void main() {
  group('MinimalSwitch', () {
    testWidgets('a tap flips it, and it announces a labelled switch', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <bool>[];
      await tester.pumpWidget(
        paddedHost(
          ValueOwner<bool>(
            initial: false,
            builder: (v, set) => MinimalSwitch(
              value: v,
              label: 'Reminders',
              onChanged: (next) {
                seen.add(next);
                set(next);
              },
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Reminders')),
        matchesSemantics(
          label: 'Reminders',
          isButton: false,
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await tester.tap(find.byType(MinimalSwitch));
      await tester.pumpAndSettle();
      expect(seen, [true]);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Reminders')),
        matchesSemantics(
          label: 'Reminders',
          isButton: false,
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a drag throws the thumb; Space flips it from the keyboard', (
      tester,
    ) async {
      final seen = <bool>[];
      await tester.pumpWidget(
        paddedHost(
          ValueOwner<bool>(
            initial: false,
            builder: (v, set) => MinimalSwitch(
              value: v,
              label: 'Digest',
              onChanged: (next) {
                seen.add(next);
                set(next);
              },
            ),
          ),
        ),
      );
      await tester.drag(find.byType(MinimalSwitch), const Offset(30, 0));
      await tester.pumpAndSettle();
      expect(seen, [true]);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(seen, [true, false]);
    });

    testWidgets('with no onChanged it is disabled and swallows taps', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        paddedHost(const MinimalSwitch(value: true, label: 'Sync')),
      );
      await tester.tap(find.byType(MinimalSwitch), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Sync')),
        matchesSemantics(
          label: 'Sync',
          isButton: false,
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
        ),
      );
      handle.dispose();
    });

    testWidgets("an on thumb is the paper in light and the accent's words "
        'colour in dark', (tester) async {
      Color thumb() => tester
          .widgetList<AnimatedContainer>(
            find.descendant(
              of: find.byType(MinimalSwitch),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .map((c) => c.decoration)
          .whereType<ShapeDecoration>()
          .firstWhere((d) => d.shape is CircleBorder)
          .color!;
      Widget host(String preset, Brightness b) => MaterialApp(
        builder: (context, navigator) => MinimalHost(
          light: MinimalThemeData.preset(preset, Brightness.light),
          dark: MinimalThemeData.preset(preset, Brightness.dark),
          brightness: b,
          child: navigator!,
        ),
        home: Center(child: MinimalSwitch(value: true, onChanged: (_) {})),
      );
      for (final preset in MinimalThemeData.presets) {
        await tester.pumpWidget(host(preset, Brightness.light));
        await tester.pumpAndSettle();
        expect(thumb(), MinimalThemeData.preset(preset, Brightness.light).card);
        await tester.pumpWidget(host(preset, Brightness.dark));
        await tester.pumpAndSettle();
        expect(
          thumb(),
          MinimalThemeData.preset(preset, Brightness.dark).primaryForeground,
        );
      }
    });

    testWidgets('its 18 px track lands taps across a 44 px target', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        paddedHost(MinimalSwitch(value: false, onChanged: (_) => taps += 1)),
      );
      final box = faceOf(tester, find.byType(MinimalSwitch));
      expect(box.height, 18);
      await tester.tapAt(box.topCenter - const Offset(0, 12));
      expect(taps, 1);
    });
  });
}
