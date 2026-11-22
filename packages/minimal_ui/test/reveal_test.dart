import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/column_host.dart';

/// A child that keeps a count in its State.
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => taps += 1),
    child: SizedBox(height: 44, child: Text('taps $taps')),
  );
}

void main() {
  group('MinimalReveal', () {
    Widget reveal(bool visible, {bool disable = false}) => columnHost(
      Column(
        children: [
          MinimalReveal(
            visible: visible,
            child: const SizedBox(height: 44, child: Text('Note')),
          ),
          const Text('Below'),
        ],
      ),
      disableAnimations: disable,
    );

    testWidgets('grows in and folds away over 120 ms', (tester) async {
      await tester.pumpWidget(reveal(false));
      expect(find.text('Note'), findsNothing);
      final below = tester.getTopLeft(find.text('Below')).dy;

      await tester.pumpWidget(reveal(true));
      await tester.pump(const Duration(milliseconds: 60));
      final mid = tester.getTopLeft(find.text('Below')).dy;
      expect(mid, greaterThan(below));
      expect(mid, lessThan(below + 44));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Below')).dy, below + 44);

      await tester.pumpWidget(reveal(false));
      await tester.pump(const Duration(milliseconds: 60));
      // Leaving: still painted, but out of the page's hit testing.
      expect(find.text('Note'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Note'),
          matching: find.byWidgetPredicate(
            (w) => w is IgnorePointer && w.ignoring,
          ),
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(find.text('Note'), findsNothing);
      expect(tester.getTopLeft(find.text('Below')).dy, below);
    });

    testWidgets('clips only while it moves, so a focus ring survives', (
      tester,
    ) async {
      Widget page(bool visible) => columnHost(
        Column(
          children: [
            MinimalReveal(
              visible: visible,
              child: MinimalButton('Save', onPressed: () {}),
            ),
          ],
        ),
      );
      Clip clip() => tester
          .renderObject<RenderClipRect>(
            find.descendant(
              of: find.byType(MinimalReveal),
              matching: find.byType(ClipRect),
            ),
          )
          .clipBehavior;
      await tester.pumpWidget(page(true));
      expect(clip(), Clip.none);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      // The button's ring stands outside its edge, and nothing cuts it.
      final ring = tester
          .widgetList<AnimatedContainer>(
            find.descendant(
              of: find.byType(MinimalButton),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .map((c) => c.foregroundDecoration)
          .nonNulls
          .where(
            (d) => d.toDiagnosticsNode().getProperties().any(
              (p) => p.name == 'ring' && p.value is Color,
            ),
          );
      expect(ring, isNotEmpty);
      expect(clip(), Clip.none);
      await tester.pumpWidget(page(false));
      await tester.pump(const Duration(milliseconds: 60));
      expect(clip(), Clip.hardEdge);
      await tester.pumpAndSettle();
    });

    testWidgets('a child keeps its state when the reveal turns back', (
      tester,
    ) async {
      Widget page(bool visible) => columnHost(
        Column(
          children: [MinimalReveal(visible: visible, child: const _Counter())],
        ),
      );
      await tester.pumpWidget(page(true));
      await tester.tap(find.text('taps 0'));
      await tester.pump();
      final state = tester.state<_CounterState>(find.byType(_Counter));
      await tester.pumpWidget(page(false));
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.state<_CounterState>(find.byType(_Counter)), same(state));
      await tester.pumpWidget(page(true));
      await tester.pumpAndSettle();
      expect(tester.state<_CounterState>(find.byType(_Counter)), same(state));
      expect(find.text('taps 1'), findsOneWidget);
    });

    testWidgets('switches at once with MinimalMotion.animate off', (
      tester,
    ) async {
      MinimalMotion.animate = false;
      addTearDown(() => MinimalMotion.animate = true);
      await tester.pumpWidget(reveal(true));
      await tester.pumpWidget(reveal(false));
      await tester.pump();
      expect(find.text('Note'), findsNothing);
    });

    testWidgets('switches at once when animations are disabled', (
      tester,
    ) async {
      await tester.pumpWidget(reveal(true, disable: true));
      await tester.pumpWidget(reveal(false, disable: true));
      await tester.pump();
      expect(find.text('Note'), findsNothing);
    });
  });
}
