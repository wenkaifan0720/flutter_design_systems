import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const _anchor = ValueKey('anchor');
const _surface = ValueKey('surface');

// A popover whose surface (120 by 80, a button in it) [place] puts where it
// says, opened from a 100 by 40 anchor; [seen] is told what it placed from.
Widget _popover({
  required RawPopoverPositionDelegate place,
  required void Function(RawPopoverPositionContext context) seen,
  void Function(RawPopoverInfo info)? info,
}) => Center(
  child: RawPopover(
    semanticLabel: 'Details',
    positionDelegate: (context) {
      seen(context);
      return place(context);
    },
    anchorBuilder: (context, anchor) => RawButton(
      key: _anchor,
      semanticLabel: 'More',
      excludeSemantics: true,
      onPressed: anchor.toggle,
      builder: (context, states, _) =>
          const SizedBox(width: 100, height: 40, child: Text('More')),
    ),
    overlayBuilder: (context, details) {
      info?.call(details);
      return SizedBox(
        key: _surface,
        width: 120,
        height: 80,
        child: RawButton(
          semanticLabel: 'Share',
          excludeSemantics: true,
          minimumSize: const Size(44, 44),
          onPressed: () {},
          builder: (context, states, _) => const Text('Share'),
        ),
      );
    },
  ),
);

Future<void> _openByKeys(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('${direction.name}: the surface sits at the exact offset the '
        'delegate gives, from the anchor, its size and the room', (
      tester,
    ) async {
      RawPopoverPositionContext? seen;
      RawPopoverInfo? info;
      // 12 under the anchor, 30 in from its leading edge, in the reading
      // direction.
      Offset place(RawPopoverPositionContext c) => Offset(
        c.textDirection == TextDirection.ltr
            ? c.anchorRect.left + 30
            : c.anchorRect.right - c.surfaceSize.width - 30,
        c.anchorRect.bottom + 12,
      );
      await tester.pumpWidget(
        harness(
          _popover(place: place, seen: (c) => seen = c, info: (i) => info = i),
          textDirection: direction,
        ),
      );
      await _openByKeys(tester);
      final anchor = tester.getRect(find.byKey(_anchor));
      final c = seen!;
      expect(c.anchorRect, anchor);
      expect(c.surfaceSize, const Size(120, 80));
      expect(
        c.overlaySize,
        tester.view.physicalSize / tester.view.devicePixelRatio,
      );
      expect(c.side, RawPopoverSide.below);
      expect(c.textDirection, direction);
      expect(c.position, isNull);
      final want = direction == TextDirection.ltr
          ? Offset(anchor.left + 30, anchor.bottom + 12)
          : Offset(anchor.right - 120 - 30, anchor.bottom + 12);
      expect(tester.getTopLeft(find.byKey(_surface)), want);
      expect(info!.surfaceRect.value, want & const Size(120, 80));
    });
  }

  testWidgets('an offset past the margin is kept as given', (tester) async {
    await tester.pumpWidget(
      harness(_popover(place: (c) => const Offset(2, 2), seen: (_) {})),
    );
    await _openByKeys(tester);
    expect(tester.getTopLeft(find.byKey(_surface)), const Offset(2, 2));
  });

  testWidgets('placed by the caller, it keeps the rest: focus moves in, its '
      'node is named, Escape closes it and focus goes back to the anchor', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(
        _popover(
          place: (c) => Offset(c.anchorRect.left, c.anchorRect.top - 90),
          seen: (_) {},
        ),
      ),
    );
    await _openByKeys(tester);
    expect(find.byKey(_surface), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Share')),
      isSemantics(isFocused: true),
      reason: 'focus moved into the surface',
    );
    expect(find.bySemanticsLabel('Details'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(_surface), findsNothing, reason: 'Escape closes it');
    expect(
      tester.getSemantics(find.bySemanticsLabel('More')),
      isSemantics(isFocused: true),
      reason: 'focus goes back to the anchor',
    );
    semantics.dispose();
  });

  testWidgets('placed by the caller, a tap outside closes it', (tester) async {
    await tester.pumpWidget(
      harness(
        _popover(
          place: (c) => Offset(c.anchorRect.left, c.anchorRect.bottom + 12),
          seen: (_) {},
        ),
      ),
    );
    await _openByKeys(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(_surface), findsNothing);
  });
}
