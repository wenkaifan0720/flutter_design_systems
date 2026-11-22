// A surface that cannot shrink (a calendar, a grid) wants its whole height
// before it picks a side; a list keeps wanting the placement's preferred
// extent, shrinking to the room and scrolling inside.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const _anchorKey = ValueKey('anchor');
const _surfaceKey = ValueKey('surface');

late RawPopoverInfo _info;

// A phone 390 x 844, an anchor 44 high [top] down, opening a surface
// [height] high that does not shrink.
Future<void> _open(
  WidgetTester tester, {
  required double top,
  required double height,
  required RawPopoverPlacement placement,
  bool capped = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    harness(
      Padding(
        padding: EdgeInsets.only(top: top),
        child: Align(
          alignment: Alignment.topLeft,
          child: RawPopover(
            placement: placement,
            semanticLabel: 'Due date',
            anchorBuilder: (context, anchor) => RawButton(
              onPressed: anchor.toggle,
              builder: (context, states, _) =>
                  const SizedBox(key: _anchorKey, width: 200, height: 44),
            ),
            overlayBuilder: (context, info) {
              _info = info;
              final surface = SizedBox(width: 300, height: height);
              // A look's panel that caps itself at the room it is given and
              // scrolls past it.
              return capped
                  ? ConstrainedBox(
                      key: _surfaceKey,
                      constraints: BoxConstraints(
                        maxHeight: info.maxSize.height,
                      ),
                      child: SingleChildScrollView(child: surface),
                    )
                  : KeyedSubtree(key: _surfaceKey, child: surface);
            },
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(_anchorKey));
  await tester.pumpAndSettle();
}

void main() {
  const whole = RawPopoverPlacement(
    matchAnchorWidth: false,
    fit: RawPopoverFit.whole,
  );
  const list = RawPopoverPlacement(matchAnchorWidth: false);

  testWidgets('a calendar 300 high with 250 below and more above opens '
      'above, whole', (tester) async {
    // Below: 844 - 8 margin - (540 + 44) - 4 gap = 248.
    await _open(tester, top: 540, height: 300, placement: whole);
    expect(_info.side, RawPopoverSide.above);
    final surface = tester.getRect(find.byKey(_surfaceKey));
    expect(surface.height, 300);
    expect(surface.top, greaterThanOrEqualTo(0));
    expect(surface.bottom, lessThanOrEqualTo(844));
  });

  testWidgets('a calendar that caps itself at the room it is given opens '
      'above, whole, rather than shrink below', (tester) async {
    await _open(tester, top: 540, height: 300, placement: whole, capped: true);
    expect(_info.side, RawPopoverSide.above);
    expect(tester.getSize(find.byKey(_surfaceKey)).height, 300);
  });

  testWidgets('a list keeps today\'s rule: 200 below holds it, so it stays '
      'below, shrunk to the room', (tester) async {
    await _open(tester, top: 540, height: 300, placement: list);
    expect(_info.side, RawPopoverSide.below);
    tester.takeException();
  });

  testWidgets('a calendar that fits below stays below', (tester) async {
    await _open(tester, top: 200, height: 300, placement: whole);
    expect(_info.side, RawPopoverSide.below);
  });

  testWidgets('a calendar that fits neither side takes the roomier one', (
    tester,
  ) async {
    await _open(tester, top: 300, height: 600, placement: whole);
    // Above: 300 - 8 - 4 = 288; below: 844 - 8 - 344 - 4 = 488.
    expect(_info.side, RawPopoverSide.below);
    tester.takeException();
  });

  test('its fit is part of the placement', () {
    expect(whole, isNot(list));
    expect(list.fit, RawPopoverFit.scroll);
    expect(
      whole,
      const RawPopoverPlacement(
        matchAnchorWidth: false,
        fit: RawPopoverFit.whole,
      ),
    );
  });
}
