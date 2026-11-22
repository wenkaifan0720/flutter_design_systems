import 'dart:ui' show SemanticsAction, Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'faces.dart';
import 'support/padded_host.dart';
import 'support/value_owner.dart';

void main() {
  group('MinimalSegmentedButton', () {
    testWidgets('a tap picks a segment, which announces itself selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <int>[];
      await tester.pumpWidget(
        paddedHost(
          SizedBox(
            width: 300,
            child: ValueOwner<int>(
              initial: 0,
              builder: (v, set) => MinimalSegmentedButton(
                segments: const [
                  MinimalButtonSegment(0, 'Week'),
                  MinimalButtonSegment(1, 'Month'),
                  MinimalButtonSegment(2, 'Year'),
                ],
                value: v,
                label: 'Range',
                onChanged: (next) {
                  seen.add(next);
                  set(next);
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();
      expect(seen, [2]);
      final year = tester.getSemantics(find.text('Year')).getSemanticsData();
      expect(year.label, 'Year');
      expect(year.flagsCollection.isButton, isTrue);
      expect(year.flagsCollection.isSelected, Tristate.isTrue);
      expect(year.flagsCollection.isEnabled, Tristate.isTrue);
      expect(year.hasAction(SemanticsAction.tap), isTrue);
      // Tapping the current segment reports nothing.
      await tester.tap(find.text('Year'));
      expect(seen, [2]);
      handle.dispose();
    });

    testWidgets('the arrow keys move the choice; taps above the strip land', (
      tester,
    ) async {
      final seen = <int>[];
      // The strip stands in a taller band, as in a row, so its padded hit
      // area is not clipped by a parent hugging its 32 px.
      await tester.pumpWidget(
        paddedHost(
          SizedBox(
            width: 300,
            height: 60,
            child: ValueOwner<int>(
              initial: 0,
              builder: (v, set) => Center(
                child: MinimalSegmentedButton(
                  segments: const [
                    MinimalButtonSegment(0, 'List'),
                    MinimalButtonSegment(1, 'Board'),
                  ],
                  value: v,
                  onChanged: (next) {
                    seen.add(next);
                    set(next);
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(seen, [1]);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(seen, [1, 0]);

      final strip = faceOf(
        tester,
        find.bySubtype<MinimalSegmentedButton<Object?>>(),
      );
      expect(strip.height, MinimalChromeMetrics.control);
      await tester.tapAt(strip.topRight + const Offset(-20, -5));
      await tester.pumpAndSettle();
      expect(seen, [1, 0, 1]);
    });

    testWidgets('it is one focus stop: after an arrow, Enter and Space keep '
        'the new choice', (tester) async {
      final seen = <int>[];
      await tester.pumpWidget(
        paddedHost(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 300,
                child: ValueOwner<int>(
                  initial: 0,
                  builder: (v, set) => MinimalSegmentedButton(
                    segments: const [
                      MinimalButtonSegment(0, 'Week'),
                      MinimalButtonSegment(1, 'Month'),
                      MinimalButtonSegment(2, 'Year'),
                    ],
                    value: v,
                    onChanged: (next) {
                      seen.add(next);
                      set(next);
                    },
                  ),
                ),
              ),
              MinimalButton('After', onPressed: () {}),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(seen, [1]);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(seen, [1, 2]);
      // The next Tab leaves the control rather than visiting each segment.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        find.ancestor(
          of: find.byWidget(focused.widget),
          matching: find.byType(MinimalButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets('expand: false hugs its labels; small is 28 px; no onChanged '
        'disables it', (tester) async {
      await tester.pumpWidget(
        paddedHost(
          const SizedBox(
            width: 300,
            child: Align(
              alignment: Alignment.centerRight,
              child: MinimalSegmentedButton(
                segments: [
                  MinimalButtonSegment(0, 'List'),
                  MinimalButtonSegment(1, 'Board'),
                ],
                value: 0,
                small: true,
                expand: false,
              ),
            ),
          ),
        ),
      );
      final box = faceOf(
        tester,
        find.bySubtype<MinimalSegmentedButton<Object?>>(),
      );
      expect(box.width, lessThan(300));
      expect(box.height, MinimalChromeMetrics.controlSm);
      final list = tester.getSize(find.text('List')).width;
      final board = tester.getSize(find.text('Board')).width;
      // The two segments share the widest label's width.
      expect(box.width, greaterThan(2 * (list > board ? list : board)));
      // Disabled, the whole track dims — thumb and frame, not just labels.
      final dim = tester.widget<Opacity>(
        find
            .descendant(
              of: find.bySubtype<MinimalSegmentedButton<Object?>>(),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(dim.opacity, 0.45);
      expect(find.byType(MinimalPressable), findsNothing);
      // The disabled choice is the thumb's hairline alone: its words keep
      // the rest's muted ink and regular weight.
      final t = MinimalThemeData.preset('standard', Brightness.light);
      final chosen = tester.widget<Text>(find.text('List')).style!;
      expect(chosen.color, t.mutedForeground);
      expect(chosen.fontWeight, FontWeight.w400);
    });
  });
}
