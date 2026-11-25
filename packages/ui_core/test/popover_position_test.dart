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

// A menu of [rows] rows (each 160 by 40) in a scroll view, as a menu scrolls
// where it lacks room, opened from a 100 by 40 anchor whose top-left corner
// is at (40, [anchorTop]) and placed by [place] (none: by [placement]).
// [pressed] is told each row's press, [seen] what [place] placed it from and
// [info] what the surface was built with.
Widget _menu({
  required int rows,
  required double anchorTop,
  RawPopoverPositionDelegate? place,
  RawPopoverPlacement placement = const RawPopoverPlacement(
    matchAnchorWidth: false,
  ),
  List<int>? pressed,
  void Function(RawPopoverPositionContext context)? seen,
  void Function(RawPopoverInfo info)? info,
}) => Stack(
  children: [
    Positioned(
      left: 40,
      top: anchorTop,
      child: RawPopover(
        placement: placement,
        positionDelegate: place == null
            ? null
            : (context) {
                seen?.call(context);
                return place(context);
              },
        anchorBuilder: (context, anchor) => RawButton(
          key: _anchor,
          semanticLabel: 'Sort',
          excludeSemantics: true,
          onPressed: anchor.toggle,
          builder: (context, states, _) =>
              const SizedBox(width: 100, height: 40, child: Text('Sort')),
        ),
        overlayBuilder: (context, details) {
          info?.call(details);
          return SizedBox(
            key: _surface,
            width: 160,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < rows; i++)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => pressed?.add(i),
                      child: SizedBox(
                        key: ValueKey('row $i'),
                        height: 40,
                        child: Text('row $i'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  ],
);

// Each of the [rows] rows lies whole in the surface, its middle hits it, and
// a press on each reaches it ([pressed] is told them all, in order).
Future<void> _everyRowTakesItsPress(
  WidgetTester tester,
  int rows,
  List<int> pressed,
) async {
  final surface = tester.getRect(find.byKey(_surface));
  for (var i = 0; i < rows; i++) {
    final row = find.byKey(ValueKey('row $i'));
    final rect = tester.getRect(row);
    expect(
      rect.top >= surface.top - 0.01 && rect.bottom <= surface.bottom + 0.01,
      isTrue,
      reason: 'row $i ($rect) is laid out whole in the surface ($surface)',
    );
    final box = tester.renderObject(row);
    expect(
      tester
          .hitTestOnBinding(rect.center)
          .path
          .any((entry) => entry.target == box),
      isTrue,
      reason: 'row $i takes a press at its middle',
    );
  }
  for (var i = 0; i < rows; i++) {
    await tester.tap(find.byKey(ValueKey('row $i')));
    await tester.pump();
  }
  expect(pressed, [for (var i = 0; i < rows; i++) i]);
}

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

  // The window is 800 by 600, its bounds 8 in from each edge (the margin):
  // 784 by 584 from (8, 8).
  group('a surface the delegate places is sized by the bounds it keeps to, '
      'not by the room on one side', () {
    testWidgets('a tall menu turned over its anchor near the foot (no flip, '
        'as an app places one where its page drew it): every row is laid out '
        'whole and takes a press', (tester) async {
      // 10 rows (400) over an anchor at 540 to 580: below it, 8.
      final pressed = <int>[];
      RawPopoverPositionContext? seen;
      RawPopoverInfo? info;
      await tester.pumpWidget(
        harness(
          _menu(
            rows: 10,
            anchorTop: 540,
            placement: const RawPopoverPlacement(
              flip: false,
              matchAnchorWidth: false,
            ),
            place: (c) => Offset(
              c.anchorRect.left,
              c.anchorRect.top - 4 - c.surfaceSize.height,
            ),
            pressed: pressed,
            seen: (c) => seen = c,
            info: (i) => info = i,
          ),
        ),
      );
      await _openByKeys(tester);
      final c = seen!;
      expect(c.bounds, const Rect.fromLTRB(8, 8, 792, 592));
      expect(c.side, RawPopoverSide.below);
      expect(c.surfaceSize, const Size(160, 400));
      expect(info!.maxSize, c.bounds.size);
      expect(
        tester.getRect(find.byKey(_surface)),
        const Rect.fromLTWH(40, 136, 160, 400),
      );
      await _everyRowTakesItsPress(tester, 10, pressed);
    });

    testWidgets('where neither side holds it and the bounds do, it is laid '
        'out whole where the delegate centres it', (tester) async {
      // 12 rows (480) by an anchor at 280 to 320: 268 below it and 268 above.
      final pressed = <int>[];
      RawPopoverPositionContext? seen;
      await tester.pumpWidget(
        harness(
          _menu(
            rows: 12,
            anchorTop: 280,
            place: (c) => Offset(
              c.anchorRect.left,
              c.bounds.center.dy - c.surfaceSize.height / 2,
            ),
            pressed: pressed,
            seen: (c) => seen = c,
          ),
        ),
      );
      await _openByKeys(tester);
      expect(seen!.surfaceSize, const Size(160, 480));
      expect(
        tester.getRect(find.byKey(_surface)),
        const Rect.fromLTWH(40, 60, 160, 480),
      );
      await _everyRowTakesItsPress(tester, 12, pressed);
    });

    testWidgets('a menu taller than the bounds is held to them and scrolls '
        'in them', (tester) async {
      // 20 rows (800).
      RawPopoverPositionContext? seen;
      RawPopoverInfo? info;
      await tester.pumpWidget(
        harness(
          _menu(
            rows: 20,
            anchorTop: 280,
            place: (c) => Offset(c.anchorRect.left, c.bounds.top),
            seen: (c) => seen = c,
            info: (i) => info = i,
          ),
        ),
      );
      await _openByKeys(tester);
      expect(seen!.surfaceSize, const Size(160, 584));
      expect(info!.maxSize, const Size(784, 584));
      expect(
        tester.getRect(find.byKey(_surface)),
        const Rect.fromLTWH(40, 8, 160, 584),
      );
    });

    testWidgets('NEGATIVE: with no delegate, the surface keeps to the room on '
        'its side, as before', (tester) async {
      // 10 rows (400) under an anchor at 400 to 440: 148 below it, no flip.
      RawPopoverInfo? info;
      await tester.pumpWidget(
        harness(
          _menu(
            rows: 10,
            anchorTop: 400,
            placement: const RawPopoverPlacement(
              flip: false,
              matchAnchorWidth: false,
            ),
            info: (i) => info = i,
          ),
        ),
      );
      await _openByKeys(tester);
      expect(info!.maxSize, const Size(784, 148));
      expect(
        tester.getRect(find.byKey(_surface)),
        const Rect.fromLTWH(40, 444, 160, 148),
      );
    });
  });
}
