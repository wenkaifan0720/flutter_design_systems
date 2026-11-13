import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _anchorKey = ValueKey('anchor');
const _surfaceKey = ValueKey('surface');

late DesignOverlayInfo _info;

// The bare reference painter: a pressable anchor and a column of pressable
// items.
Widget _overlay({
  DesignOverlayTrigger trigger = DesignOverlayTrigger.press,
  DesignOverlayPlacement placement = const DesignOverlayPlacement(),
  bool arrowKeyNavigation = false,
  bool focusOnOpen = true,
  FocusNode? anchorNode,
  List<FocusNode> itemNodes = const [],
  ValueChanged<String>? onItem,
  double dampingRatio = 1,
  ValueChanged<double>? onPresence,
  Size surfaceSize = const Size(120, 90),
}) => DesignAnchoredOverlay(
  trigger: trigger,
  placement: placement,
  arrowKeyNavigation: arrowKeyNavigation,
  focusOnOpen: focusOnOpen,
  dampingRatio: dampingRatio,
  semanticLabel: 'Options',
  anchorBuilder: (context, anchor) => DesignPressable(
    focusNode: anchorNode,
    expanded: anchor.isOpen,
    onPressed: trigger == DesignOverlayTrigger.press ? anchor.toggle : () {},
    builder: (context, states, _) => plainFace('Open', key: _anchorKey),
  ),
  overlayBuilder: (context, info) {
    _info = info;
    return AnimatedBuilder(
      animation: info.animation,
      builder: (context, child) {
        onPresence?.call(info.animation.value);
        return child!;
      },
      child: SizedBox(
        key: _surfaceKey,
        width: surfaceSize.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < itemNodes.length; i++)
              DesignPressable(
                focusNode: itemNodes[i],
                onPressed: () {
                  onItem?.call('item $i');
                  info.close();
                },
                builder: (context, states, _) => plainFace('item $i'),
              ),
            if (itemNodes.isEmpty)
              Flexible(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: surfaceSize.height,
                    child: const Text('Card'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  },
);

Widget _at(Alignment alignment, Widget child, {TextDirection? direction}) =>
    harness(
      Align(alignment: alignment, child: child),
      textDirection: direction ?? TextDirection.ltr,
    );

List<FocusNode> _nodes(int n) {
  final nodes = [for (var i = 0; i < n; i++) FocusNode(debugLabel: 'item $i')];
  addTearDown(() {
    for (final node in nodes) {
      node.dispose();
    }
  });
  return nodes;
}

void main() {
  final items = [FocusNode(), FocusNode()];
  tearDownAll(() {
    for (final n in items) {
      n.dispose();
    }
  });
  behaviourContract(
    'DesignAnchoredOverlay',
    build: (c) => Center(child: _overlay(itemNodes: items)),
    node: () => find.byKey(_anchorKey),
    // The anchor is the look's press; the behaviour gives it its state.
    semantics: isSemantics(
      isButton: true,
      hasExpandedState: true,
      isExpanded: false,
      hasTapAction: true,
      isFocusable: true,
    ),
    noDisabledState:
        'the anchor is the look\'s DesignPressable, whose contract covers '
        'a disabled anchor',
    keyboard: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.enter);
      expect(
        p.tester.getSemantics(find.bySemanticsLabel('Options')),
        isSemantics(label: 'Options'),
        reason: 'the surface carries its name',
      );
      expect(p.data.flagsCollection.isExpanded, Tristate.isTrue);
      expect(items.first.hasPrimaryFocus, isTrue, reason: 'focus moves in');
      await p.key(LogicalKeyboardKey.escape);
      expect(find.byKey(_surfaceKey), findsNothing, reason: 'Escape closes');
      expect(p.focused, isTrue, reason: 'focus returns to the anchor');
    },
    rtl: (p) async {
      await p.tester.tap(p.node);
      await p.tester.pumpAndSettle();
      expect(
        p.tester.getTopRight(find.byKey(_surfaceKey)).dx,
        p.tester.getTopRight(p.node).dx,
        reason: 'start alignment is the right edge',
      );
    },
    motion: (p) async {
      await p.tester.tap(p.node);
      await p.tester.pump();
    },
    // The anchor's size is the look's press (DesignPressable.minimumSize).
    targets: false,
  );

  testWidgets('a popover: Enter opens it and focus moves in, Tab stays '
      'inside, Escape closes it and focus returns to the anchor', (
    tester,
  ) async {
    final anchor = FocusNode(debugLabel: 'anchor');
    addTearDown(anchor.dispose);
    final items = _nodes(2);
    await tester.pumpWidget(
      _at(Alignment.center, _overlay(anchorNode: anchor, itemNodes: items)),
    );
    anchor.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byKey(_surfaceKey), findsOneWidget);
    expect(items[0].hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(items[1].hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(items[0].hasPrimaryFocus, isTrue, reason: 'Tab wraps inside');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(_surfaceKey), findsNothing);
    expect(anchor.hasPrimaryFocus, isTrue);
  });

  testWidgets('choosing an item closes it and returns focus', (tester) async {
    final anchor = FocusNode(debugLabel: 'anchor');
    addTearDown(anchor.dispose);
    final items = _nodes(3);
    String? chosen;
    await tester.pumpWidget(
      _at(
        Alignment.topCenter,
        _overlay(
          anchorNode: anchor,
          itemNodes: items,
          arrowKeyNavigation: true,
          onItem: (item) => chosen = item,
        ),
      ),
    );
    anchor.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(items[0].hasPrimaryFocus, isTrue);
    // A menu: Up wraps to the last, Home and End go to the ends.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(items[2].hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(items[0].hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(items[1].hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(items[2].hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chosen, 'item 2');
    expect(find.byKey(_surfaceKey), findsNothing);
    expect(anchor.hasPrimaryFocus, isTrue);
  });

  testWidgets('a tap outside closes it', (tester) async {
    await tester.pumpWidget(_at(Alignment.center, _overlay()));
    await tester.tap(find.byKey(_anchorKey));
    await tester.pumpAndSettle();
    expect(find.byKey(_surfaceKey), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(_surfaceKey), findsNothing);
  });

  testWidgets('it flips to the side with room and says so', (tester) async {
    await tester.pumpWidget(_at(Alignment.bottomCenter, _overlay()));
    await tester.tap(find.byKey(_anchorKey));
    await tester.pumpAndSettle();
    expect(_info.side, DesignOverlaySide.above);
    final anchor = tester.getRect(find.byKey(_anchorKey));
    final surface = tester.getRect(find.byKey(_surfaceKey));
    expect(surface.bottom, lessThanOrEqualTo(anchor.top));

    // Below when below has room.
    await tester.pumpWidget(_at(Alignment.topCenter, _overlay()));
    await tester.pumpAndSettle();
    if (find.byKey(_surfaceKey).evaluate().isEmpty) {
      await tester.tap(find.byKey(_anchorKey));
      await tester.pumpAndSettle();
    }
    expect(_info.side, DesignOverlaySide.below);
  });

  testWidgets('start alignment follows the text direction, and it shifts to '
      'stay on screen', (tester) async {
    await tester.pumpWidget(
      _at(
        Alignment.center,
        _overlay(surfaceSize: const Size(160, 40)),
        direction: TextDirection.rtl,
      ),
    );
    await tester.tap(find.byKey(_anchorKey));
    await tester.pumpAndSettle();
    final anchor = tester.getRect(find.byKey(_anchorKey));
    final surface = tester.getRect(find.byKey(_surfaceKey));
    expect(surface.right, moreOrLessEquals(anchor.right));

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _at(Alignment.topRight, _overlay(surfaceSize: const Size(300, 40))),
    );
    await tester.tap(find.byKey(_anchorKey));
    await tester.pumpAndSettle();
    final shifted = tester.getRect(find.byKey(_surfaceKey));
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(shifted.right, lessThanOrEqualTo(width - 8));
  });

  testWidgets('above or below, a surface is at least as wide as its anchor, '
      'on its leading edge, unless told otherwise; beside it, its own width', (
    tester,
  ) async {
    Widget wide(DesignOverlayPlacement placement) => _at(
      Alignment.center,
      DesignAnchoredOverlay(
        placement: placement,
        focusOnOpen: false,
        anchorBuilder: (context, anchor) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: anchor.toggle,
          child: const SizedBox(key: _anchorKey, width: 200, height: 40),
        ),
        overlayBuilder: (context, info) =>
            const SizedBox(key: _surfaceKey, width: 80, height: 40),
      ),
    );
    Future<Rect> surface(DesignOverlayPlacement placement) async {
      await tester.pumpWidget(wide(placement));
      await tester.tap(find.byKey(_anchorKey));
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byKey(_surfaceKey));
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      return rect;
    }

    final below = await surface(const DesignOverlayPlacement());
    final anchor = tester.getRect(find.byKey(_anchorKey));
    expect(below.width, 200);
    expect(below.left, moreOrLessEquals(anchor.left));
    final above = await surface(
      const DesignOverlayPlacement(side: DesignOverlaySide.above),
    );
    expect(above.width, 200);
    final own = await surface(
      const DesignOverlayPlacement(matchAnchorWidth: false),
    );
    expect(own.width, 80);
    final beside = await surface(
      const DesignOverlayPlacement(side: DesignOverlaySide.end),
    );
    expect(beside.width, 80);
  });

  testWidgets('a hover card opens after the pointer rests, survives the trip '
      'into it, and closes after the pointer leaves', (tester) async {
    await tester.pumpWidget(
      _at(
        Alignment.center,
        _overlay(
          trigger: DesignOverlayTrigger.hover,
          focusOnOpen: false,
          placement: const DesignOverlayPlacement(gap: 0),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byKey(_anchorKey)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(_surfaceKey), findsNothing, reason: 'still resting');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(find.byKey(_surfaceKey), findsOneWidget);

    // Across the gap into the card: it stays.
    await mouse.moveTo(tester.getCenter(find.byKey(_surfaceKey)));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(_surfaceKey), findsOneWidget);

    await mouse.moveTo(Offset.zero);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(_surfaceKey), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.byKey(_surfaceKey), findsNothing);
  });

  testWidgets('a hover card opens on keyboard focus and Escape closes it', (
    tester,
  ) async {
    final anchor = FocusNode(debugLabel: 'anchor');
    addTearDown(anchor.dispose);
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.pumpWidget(
      _at(
        Alignment.center,
        _overlay(
          trigger: DesignOverlayTrigger.hover,
          focusOnOpen: false,
          anchorNode: anchor,
        ),
      ),
    );
    anchor.requestFocus();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.byKey(_surfaceKey), findsOneWidget);
    expect(anchor.hasPrimaryFocus, isTrue, reason: 'focus stays put');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(_surfaceKey), findsNothing);
    expect(anchor.hasPrimaryFocus, isTrue);
  });

  testWidgets('the anchor reads expanded; the surface carries its label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_at(Alignment.center, _overlay()));
    expect(
      tester.getSemantics(find.byKey(_anchorKey)),
      isSemantics(isButton: true, hasExpandedState: true),
    );
    await tester.tap(find.byKey(_anchorKey));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byKey(_anchorKey)),
      isSemantics(hasExpandedState: true, isExpanded: true),
    );
    expect(find.bySemanticsLabel('Options'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Reduce Motion: the surface never overshoots', (tester) async {
    var most = 0.0;
    void watch(double v) => most = v > most ? v : most;
    await tester.pumpWidget(
      harness(
        Center(child: _overlay(dampingRatio: 0.3, onPresence: watch)),
        reduceMotion: true,
      ),
    );
    await tester.tap(find.byKey(_anchorKey));
    await tester.pumpAndSettle(const Duration(milliseconds: 8));
    expect(most, lessThanOrEqualTo(1.0));
    expect(most, greaterThan(0.99));
  });

  testWidgets('at 200% text a tall surface is held to its side\'s room', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        Align(
          alignment: Alignment.topCenter,
          child: _overlay(surfaceSize: const Size(120, 2000)),
        ),
        textScale: 2,
      ),
    );
    await tester.tap(find.byKey(_anchorKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final height =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final anchor = tester.getRect(find.byKey(_anchorKey));
    expect(_info.side, DesignOverlaySide.below);
    expect(_info.maxSize.height, lessThan(height - anchor.bottom));
    final surface = tester.getRect(find.byKey(_surfaceKey));
    expect(surface.bottom, lessThanOrEqualTo(height - 8));
    expect(tester.takeException(), isNull);
  });
}
