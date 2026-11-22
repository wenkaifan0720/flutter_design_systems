import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'faces.dart';
import 'support/padded_host.dart';

void main() {
  group('MinimalChip', () {
    testWidgets('a chip taps, prints its count and announces selection', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        paddedHost(
          MinimalChip(
            'Open',
            count: 2,
            selected: true,
            onPressed: () => taps += 1,
          ),
        ),
      );
      expect(find.text('2'), findsOneWidget);
      expect(faceOf(tester, find.byType(MinimalChip)).height, 28);
      await tester.tap(find.text('Open'));
      expect(taps, 1);
      final node = tester.getSemantics(find.text('Open'));
      expect(
        node.getSemanticsData().flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(
        node.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isTrue,
      );
      handle.dispose();
    });

    testWidgets('with no onPressed it is disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(paddedHost(const MinimalChip('Archived')));
      final node = tester.getSemantics(find.text('Archived'));
      expect(
        node.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      handle.dispose();
    });

    testWidgets('a disabled chosen chip keeps the muted ink, so it never '
        'reads stronger than an enabled one', (tester) async {
      final t = MinimalThemeData.preset('standard', Brightness.light);
      await tester.pumpWidget(
        paddedHost(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinimalChip('Idle', onPressed: () {}),
              MinimalChip('Live', selected: true, onPressed: () {}),
              const MinimalChip('Off', selected: true),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      Color? ink(String label) =>
          tester.widget<Text>(find.text(label)).style?.color;
      expect(ink('Live'), t.foreground);
      expect(ink('Idle'), t.mutedForeground);
      expect(ink('Off'), t.mutedForeground);
    });

    testWidgets('a chip row wraps instead of overflowing', (tester) async {
      await tester.pumpWidget(
        paddedHost(
          SizedBox(
            width: 200,
            child: MinimalChipRow(
              children: [
                for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'])
                  MinimalChip(day, onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final first = tester.getRect(find.text('Mon'));
      final last = tester.getRect(find.text('Sat'));
      expect(last.top, greaterThan(first.bottom));
    });

    testWidgets('a chip row keeps every chip a 44 px target above its first '
        'line and below its last', (tester) async {
      final taps = <String>[];
      await tester.pumpWidget(
        // A 200 px column with room above and below the row, as a page has.
        paddedHost(
          SizedBox(
            width: 200,
            height: 200,
            child: Center(
              child: MinimalChipRow(
                children: [
                  for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'])
                    MinimalChip(day, onPressed: () => taps.add(day)),
                ],
              ),
            ),
          ),
        ),
      );
      final mon = faceOf(
        tester,
        find.ancestor(of: find.text('Mon'), matching: find.byType(MinimalChip)),
      );
      final sat = faceOf(
        tester,
        find.ancestor(of: find.text('Sat'), matching: find.byType(MinimalChip)),
      );
      expect(mon.height, MinimalChromeMetrics.controlSm);
      await tester.tapAt(mon.topCenter - const Offset(0, 6));
      await tester.tapAt(sat.bottomCenter + const Offset(0, 6));
      expect(taps, ['Mon', 'Sat']);
      // Past the 44 px square, nothing lands.
      await tester.tapAt(mon.topCenter - const Offset(0, 10));
      expect(taps, ['Mon', 'Sat']);
    });

    testWidgets('a lone chip in a row takes a tap 6 px above its edge', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        paddedHost(
          MinimalChipRow(
            children: [MinimalChip('Open', onPressed: () => taps++)],
          ),
        ),
      );
      final chip = faceOf(tester, find.byType(MinimalChip));
      await tester.tapAt(chip.topCenter - const Offset(0, 6));
      expect(taps, 1);
    });
  });
}
