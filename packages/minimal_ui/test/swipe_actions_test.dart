import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/centred_host.dart';
import 'support/swipe_row.dart';

void main() {
  group('MinimalSwipeActions', () {
    testWidgets('a drag past half reveals the trailing squares, and a '
        'tap on one performs it and closes the row', (tester) async {
      final handle = tester.ensureSemantics();
      var deleted = 0;
      await tester.pumpWidget(
        centredHost(
          SizedBox(
            width: 390,
            child: MinimalSwipeActions(
              trailing: [
                MinimalSwipeAction(
                  'Delete',
                  icon: LucideIcons.trash2,
                  destructive: true,
                  onPressed: () => deleted += 1,
                ),
              ],
              child: swipeRow('Morning run'),
            ),
          ),
        ),
      );
      expect(find.text('Delete'), findsNothing);
      await tester.drag(find.text('Morning run'), const Offset(-60, 0));
      await tester.pumpAndSettle();
      final square = tester.getRect(find.bySemanticsLabel('Delete'));
      // At least its 64 px; the test face's wide glyphs widen it to the word.
      expect(
        square.width,
        greaterThanOrEqualTo(MinimalSwipeActions.actionWidth),
      );
      expect(square.height, MinimalChromeMetrics.row);
      await tester.tap(find.bySemanticsLabel('Delete'));
      await tester.pumpAndSettle();
      expect(deleted, 1);
      expect(find.text('Delete'), findsNothing);
      handle.dispose();
    });

    testWidgets('a short drag snaps back closed', (tester) async {
      await tester.pumpWidget(
        centredHost(
          SizedBox(
            width: 390,
            child: MinimalSwipeActions(
              trailing: [MinimalSwipeAction('Archive', onPressed: () {})],
              child: swipeRow('Journal'),
            ),
          ),
        ),
      );
      await tester.timedDrag(
        find.text('Journal'),
        const Offset(-12, 0),
        const Duration(milliseconds: 400),
      );
      await tester.pumpAndSettle();
      expect(find.text('Archive'), findsNothing);
    });

    testWidgets('while open, a tap on the row closes it instead of opening '
        'the row', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        centredHost(
          SizedBox(
            width: 390,
            child: MinimalSwipeActions(
              initiallyOpen: true,
              leading: [
                MinimalSwipeAction(
                  'Done',
                  tone: MinimalTone.success,
                  onPressed: () {},
                ),
              ],
              child: swipeRow('Meditate', onTap: () => opened += 1),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Done'), findsOneWidget);
      // The open row's own content ignores the tap: the handle takes it.
      await tester.tap(find.text('Meditate'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(opened, 0);
      expect(find.text('Done'), findsNothing);
      await tester.tap(find.text('Meditate'));
      expect(opened, 1);
    });

    testWidgets('a full swipe performs the first action once, when opted '
        'in', (tester) async {
      var done = 0;
      await tester.pumpWidget(
        centredHost(
          SizedBox(
            width: 390,
            child: MinimalSwipeActions(
              allowsFullSwipe: true,
              leading: [
                MinimalSwipeAction('Done', onPressed: () => done += 1),
                MinimalSwipeAction('Pin', onPressed: () {}),
              ],
              child: swipeRow('Read 20 pages'),
            ),
          ),
        ),
      );
      await tester.drag(find.text('Read 20 pages'), const Offset(360, 0));
      await tester.pumpAndSettle();
      expect(done, 1);
    });

    testWidgets('every action is offered as a custom semantics action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var snoozed = 0;
      await tester.pumpWidget(
        centredHost(
          SizedBox(
            width: 390,
            child: MinimalSwipeActions(
              trailing: [
                MinimalSwipeAction(
                  'Delete',
                  destructive: true,
                  onPressed: () {},
                ),
                MinimalSwipeAction(
                  'Snooze',
                  tone: MinimalTone.warning,
                  onPressed: () => snoozed += 1,
                ),
              ],
              child: swipeRow('Drink water'),
            ),
          ),
        ),
      );
      final node = tester.getSemantics(find.text('Drink water'));
      final data = node.getSemanticsData();
      final labels = [
        for (final id in data.customSemanticsActionIds ?? const <int>[])
          CustomSemanticsAction.getAction(id)!.label,
      ];
      expect(labels, containsAll(<String>['Delete', 'Snooze']));
      tester.semantics.customAction(
        find.semantics.byLabel('Drink water'),
        const CustomSemanticsAction(label: 'Snooze'),
      );
      await tester.pump();
      expect(snoozed, 1);
      handle.dispose();
    });

    testWidgets('without a full swipe the row stops at its actions, the '
        'square butted against it', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        centredHost(
          SizedBox(
            width: 390,
            child: MinimalSwipeActions(
              trailing: [
                MinimalSwipeAction(
                  'Delete',
                  destructive: true,
                  onPressed: () {},
                ),
              ],
              child: swipeRow('Morning run'),
            ),
          ),
        ),
      );
      double start() => tester.getTopLeft(find.text('Morning run')).dx;
      final rest = start();
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Morning run')),
      );
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(-30, 0));
        await tester.pump();
      }
      final square = tester.getRect(find.bySemanticsLabel('Delete'));
      // 300 px of finger: the row goes no further than its square.
      expect(rest - start(), moreOrLessEquals(square.width, epsilon: 0.5));
      final row = tester.getRect(find.byType(MinimalSwipeActions));
      expect(square.right, moreOrLessEquals(row.right, epsilon: 0.5));
      expect(
        square.width,
        greaterThanOrEqualTo(MinimalSwipeActions.actionWidth),
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(rest - start(), moreOrLessEquals(square.width, epsilon: 0.5));
      handle.dispose();
    });

    testWidgets('a revealed square keeps its glyph and its word at text '
        'scale 1.3', (tester) async {
      await tester.pumpWidget(
        centredHost(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: SizedBox(
                width: 390,
                child: MinimalSwipeActions(
                  initiallyOpen: true,
                  trailing: [
                    MinimalSwipeAction(
                      'Snooze',
                      icon: LucideIcons.alarmClock,
                      tone: MinimalTone.warning,
                      onPressed: () {},
                    ),
                  ],
                  child: swipeRow('Drink water'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Snooze'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MinimalSwipeActions),
          matching: find.byType(MinimalIcon),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('at text scale 1.3 a square grows to its word rather than '
        'squeezing it to its edges', (tester) async {
      await tester.pumpWidget(
        centredHost(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: SizedBox(
                width: 390,
                child: MinimalSwipeActions(
                  initiallyOpen: true,
                  trailing: [
                    MinimalSwipeAction('Delete', onPressed: () {}),
                    MinimalSwipeAction('Snooze', onPressed: () {}),
                  ],
                  child: swipeRow('Drink water'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final word = find.text('Snooze');
      // Shown at its own width (not shrunk), with air on both sides.
      expect(
        tester.getRect(word).width,
        moreOrLessEquals(tester.getSize(word).width, epsilon: 0.5),
      );
      // Delete, the first, stands at the trailing edge; the words keep apart.
      final delete = tester.getRect(find.text('Delete'));
      final row = tester.getRect(find.byType(MinimalSwipeActions));
      expect(delete.right, lessThan(row.right));
      expect(tester.getRect(word).right, lessThan(delete.left));
    });

    testWidgets('a revealed square is a control: the keyboard reaches it '
        'and Enter performs it', (tester) async {
      var pinned = 0;
      await tester.pumpWidget(
        centredHost(
          SizedBox(
            width: 390,
            child: MinimalSwipeActions(
              initiallyOpen: true,
              leading: [
                MinimalSwipeAction('Pin', onPressed: () => pinned += 1),
              ],
              child: swipeRow('Journal'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(pinned, 1);
      expect(find.text('Pin'), findsNothing);
    });

    test('a swipe action resolves its tone, danger first', () {
      void noop() {}
      expect(
        MinimalSwipeAction('A', onPressed: noop).resolvedTone,
        MinimalTone.primary,
      );
      expect(
        MinimalSwipeAction(
          'B',
          tone: MinimalTone.success,
          destructive: true,
          onPressed: noop,
        ).resolvedTone,
        MinimalTone.destructive,
      );
      expect(
        MinimalSwipeAction(
          'C',
          tone: MinimalTone.neutral,
          onPressed: noop,
        ).resolvedTone,
        MinimalTone.neutral,
      );
    });
  });
}
