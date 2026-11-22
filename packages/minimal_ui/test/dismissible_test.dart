import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/centred_host.dart';
import 'support/swipe_row.dart';

void main() {
  group('MinimalDismissible', () {
    testWidgets('a trailing swipe removes the row and reports it', (
      tester,
    ) async {
      final habits = ['Meditate', 'Journal'];
      await tester.pumpWidget(
        centredHost(
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 390,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final habit in habits)
                    MinimalDismissible(
                      key: ValueKey(habit),
                      onDismissed: () => setState(() => habits.remove(habit)),
                      child: swipeRow(habit),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      // The wrong way does nothing: the leading edge is the back gesture's.
      await tester.fling(find.text('Journal'), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      expect(habits, ['Meditate', 'Journal']);
      await tester.fling(find.text('Journal'), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(habits, ['Meditate']);
    });

    testWidgets('held open, its glyph leads its word in the page\'s '
        'direction, the word at the trailing gutter', (tester) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          centredHost(
            Directionality(
              textDirection: direction,
              child: SizedBox(
                width: 390,
                child: MinimalDismissible(
                  key: ValueKey(direction),
                  label: 'Remove',
                  onDismissed: () {},
                  child: swipeRow('Morning run'),
                ),
              ),
            ),
          ),
        );
        final row = tester.getRect(find.byType(MinimalDismissible));
        final rtl = direction == TextDirection.rtl;
        // A short pull from the trailing edge holds the word open.
        final gesture = await tester.startGesture(
          rtl
              ? row.centerLeft + const Offset(20, 0)
              : row.centerRight - const Offset(20, 0),
        );
        for (var i = 0; i < 8; i++) {
          await gesture.moveBy(Offset(rtl ? 10 : -10, 0));
          await tester.pump();
        }
        await gesture.up();
        await tester.pumpAndSettle();
        final glyph = tester.getRect(
          find.descendant(
            of: find.byType(MinimalDismissible),
            matching: find.byType(MinimalIcon),
          ),
        );
        final word = tester.getRect(find.text('Remove'));
        if (rtl) {
          expect(
            glyph.left,
            greaterThan(word.right),
            reason: 'rtl: glyph, then word',
          );
          expect(
            word.left - row.left,
            closeTo(MinimalInsets.gutter.horizontal / 2, 1),
          );
        } else {
          expect(
            glyph.right,
            lessThan(word.left),
            reason: 'ltr: glyph, then word',
          );
          expect(
            row.right - word.right,
            closeTo(MinimalInsets.gutter.horizontal / 2, 1),
          );
        }
      }
    });

    testWidgets('the delete is offered as a custom semantics action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var dismissed = 0;
      await tester.pumpWidget(
        centredHost(
          SizedBox(
            width: 390,
            child: MinimalDismissible(
              key: const ValueKey('HAB-4'),
              label: 'Remove',
              onDismissed: () => dismissed += 1,
              child: swipeRow('Morning run'),
            ),
          ),
        ),
      );
      tester.semantics.customAction(
        find.semantics.byLabel('Morning run'),
        const CustomSemanticsAction(label: 'Remove'),
      );
      expect(dismissed, 1);
      handle.dispose();
    });
  });
}
