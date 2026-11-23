import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _anchorKey = ValueKey('anchor');
const _surfaceKey = ValueKey('surface');

late RawPopoverInfo _info;

// The bare reference painter: a pressable anchor and a column of pressable
// items.
Widget _overlay({
  RawPopoverTrigger trigger = RawPopoverTrigger.press,
  RawPopoverPlacement placement = const RawPopoverPlacement(),
  bool arrowKeyNavigation = false,
  bool focusOnOpen = true,
  FocusNode? anchorNode,
  List<FocusNode> itemNodes = const [],
  ValueChanged<String>? onItem,
  double dampingRatio = 1,
  ValueChanged<double>? onPresence,
  Size surfaceSize = const Size(120, 90),
}) => RawPopover(
  trigger: trigger,
  placement: placement,
  arrowKeyNavigation: arrowKeyNavigation,
  focusOnOpen: focusOnOpen,
  dampingRatio: dampingRatio,
  semanticLabel: 'Options',
  anchorBuilder: (context, anchor) => RawButton(
    focusNode: anchorNode,
    expanded: anchor.isOpen,
    onPressed: trigger == RawPopoverTrigger.press ? anchor.toggle : () {},
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
              RawButton(
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
    'RawPopover',
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
        'the anchor is the look\'s RawButton, whose contract covers '
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
    // The anchor's size is the look's press (RawButton.minimumSize).
    targets: false,
  );

  testWidgets('the open surface is a node of its own with no empty node '
      'round it, and its children as the look gives them', (tester) async {
    final semantics = tester.ensureSemantics();
    final controller = MenuController();
    await tester.pumpWidget(
      harness(
        Center(
          child: RawPopover(
            controller: controller,
            semanticLabel: 'Details',
            anchorBuilder: (context, anchor) => GestureDetector(
              onTap: anchor.toggle,
              child: const Text('More'),
            ),
            overlayBuilder: (context, info) => headingAndText(),
          ),
        ),
      ),
    );
    controller.open();
    await tester.pumpAndSettle();
    SemanticsNode? surface;
    bool visit(SemanticsNode n) {
      if (n.label == 'Details') {
        surface = n;
        return false;
      }
      n.visitChildren(visit);
      return surface == null;
    }

    semanticsOwner().rootSemanticsNode!.visitChildren(visit);
    final parent = surface!.parent!;
    // 0.5.0: the surface's keys made a node round it that said nothing, as
    // large as the surface and holding only it.
    expect(
      parent.label.isEmpty &&
          parent.childrenCount == 1 &&
          parent.rect.size == surface!.rect.size,
      isFalse,
    );
    final children = <String>[];
    surface!.visitChildren((c) {
      children.add(c.label);
      return true;
    });
    expect(children, ['Tide tables', 'Low water at 7:10']);
    expectHeadingAndTextApart(tester);
    semantics.dispose();
  });

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
    expect(_info.side, RawPopoverSide.above);
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
    expect(_info.side, RawPopoverSide.below);
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
    Widget wide(RawPopoverPlacement placement) => _at(
      Alignment.center,
      RawPopover(
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
    Future<Rect> surface(RawPopoverPlacement placement) async {
      await tester.pumpWidget(wide(placement));
      await tester.tap(find.byKey(_anchorKey));
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byKey(_surfaceKey));
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      return rect;
    }

    final below = await surface(const RawPopoverPlacement());
    final anchor = tester.getRect(find.byKey(_anchorKey));
    expect(below.width, 200);
    expect(below.left, moreOrLessEquals(anchor.left));
    final above = await surface(
      const RawPopoverPlacement(side: RawPopoverSide.above),
    );
    expect(above.width, 200);
    final own = await surface(
      const RawPopoverPlacement(matchAnchorWidth: false),
    );
    expect(own.width, 80);
    final beside = await surface(
      const RawPopoverPlacement(side: RawPopoverSide.end),
    );
    expect(beside.width, 80);
  });

  group('a list from a field', () {
    const listKey = ValueKey('list');
    // A field of [width] opening a list of [items], each row stretched to
    // the list, the list revealed by an Align growing its height with no
    // widthFactor (inside loose constraints it would spread to the overlay).
    Widget field(
      double width,
      List<String> items, {
      RawPopoverPlacement placement = const RawPopoverPlacement(),
      TextDirection direction = TextDirection.ltr,
      bool lazy = false,
    }) => _at(
      Alignment.topCenter,
      Padding(
        padding: const EdgeInsets.only(top: 40),
        child: RawPopover(
          placement: placement,
          focusOnOpen: false,
          anchorBuilder: (context, anchor) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: anchor.toggle,
            child: SizedBox(key: _anchorKey, width: width, height: 44),
          ),
          overlayBuilder: (context, info) => AnimatedBuilder(
            animation: info.animation,
            builder: (context, child) => Align(
              alignment: AlignmentDirectional.topStart,
              heightFactor: info.animation.value.clamp(0.0, 1.0),
              child: child,
            ),
            child: KeyedSubtree(
              key: listKey,
              child: lazy
                  ? SizedBox(
                      height: 120,
                      child: ListView(
                        children: [for (final i in items) Text(i)],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final i in items)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(i, maxLines: 1, softWrap: false),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
      direction: direction,
    );
    Rect list(WidgetTester tester) => tester.getRect(find.byKey(listKey));
    Rect anchorOf(WidgetTester tester) =>
        tester.getRect(find.byKey(_anchorKey));

    // The harness's test font draws a letter as wide as its size (14).
    testWidgets('short items under a 600 px field: 600 wide, on its edge, '
        'from the first frame', (tester) async {
      await tester.pumpWidget(field(600, ['Day', 'Week']));
      await tester.tap(find.byKey(_anchorKey));
      await tester.pump();
      final first = list(tester);
      expect(first.width, 600, reason: 'the first frame, mid-reveal');
      expect(first.left, anchorOf(tester).left);
      await tester.pumpAndSettle();
      expect(list(tester).width, 600);
      expect(list(tester).left, anchorOf(tester).left);
    });

    testWidgets('a long item under a 120 px field: as wide as it needs, up '
        'to the cap', (tester) async {
      // 'Fortnightly' is 11 letters: 154 with its 24 of padding, 178.
      await tester.pumpWidget(field(120, ['Day', 'Fortnightly']));
      await tester.tap(find.byKey(_anchorKey));
      await tester.pump();
      expect(list(tester).width, 178, reason: 'the first frame');
      expect(list(tester).left, anchorOf(tester).left);
      await tester.pumpAndSettle();
      expect(list(tester).width, 178);
      await tester.tapAt(const Offset(5, 500));
      await tester.pumpAndSettle();

      // 40 letters, 584 with padding: the default cap, 320, stops it.
      await tester.pumpWidget(field(120, ['Day', 'A' * 40]));
      await tester.tap(find.byKey(_anchorKey));
      await tester.pump();
      expect(list(tester).width, 320);
      await tester.tapAt(const Offset(5, 500));
      await tester.pumpAndSettle();

      // A look's own cap.
      await tester.pumpWidget(
        field(120, [
          'Day',
          'A' * 40,
        ], placement: const RawPopoverPlacement(maxWidth: 240)),
      );
      await tester.tap(find.byKey(_anchorKey));
      await tester.pump();
      expect(list(tester).width, 240);
      expect(tester.takeException(), isNull);
    });

    testWidgets('right to left: on the field\'s leading (right) edge from '
        'the first frame', (tester) async {
      await tester.pumpWidget(
        field(120, ['Day', 'Fortnightly'], direction: TextDirection.rtl),
      );
      await tester.tap(find.byKey(_anchorKey));
      await tester.pump();
      expect(list(tester).right, anchorOf(tester).right);
      expect(list(tester).width, 178);
      await tester.pumpAndSettle();
      expect(list(tester).right, anchorOf(tester).right);
    });

    testWidgets('a lazy list, which can\'t say its width ahead, keeps the '
        'field\'s', (tester) async {
      await tester.pumpWidget(field(200, ['Day', 'A' * 40], lazy: true));
      await tester.tap(find.byKey(_anchorKey));
      await tester.pump();
      expect(list(tester).width, 200);
      await tester.pumpAndSettle();
      expect(list(tester).width, 200);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a hover card opens after the pointer rests, survives the trip '
      'into it, and closes after the pointer leaves', (tester) async {
    await tester.pumpWidget(
      _at(
        Alignment.center,
        _overlay(
          trigger: RawPopoverTrigger.hover,
          focusOnOpen: false,
          placement: const RawPopoverPlacement(gap: 0),
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
          trigger: RawPopoverTrigger.hover,
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

  // Android's and the web's flag, then iOS's alone.
  for (final ios in [false, true]) {
    testWidgets(
      'Reduce Motion${ios ? ', iOS\'s alone' : ''}: the surface never '
      'overshoots',
      (tester) async {
        var most = 0.0;
        void watch(double v) => most = v > most ? v : most;
        if (ios) iosReduceMotion(tester);
        await tester.pumpWidget(
          harness(
            Center(child: _overlay(dampingRatio: 0.3, onPresence: watch)),
            reduceMotion: !ios,
          ),
        );
        await tester.tap(find.byKey(_anchorKey));
        await tester.pumpAndSettle(const Duration(milliseconds: 8));
        expect(most, lessThanOrEqualTo(1.0));
        expect(most, greaterThan(0.99));
      },
    );
  }

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
    expect(_info.side, RawPopoverSide.below);
    expect(_info.maxSize.height, lessThan(height - anchor.bottom));
    final surface = tester.getRect(find.byKey(_surfaceKey));
    expect(surface.bottom, lessThanOrEqualTo(height - 8));
    expect(tester.takeException(), isNull);
  });

  group('a route pushed over its anchor', () {
    // A dialog over the anchor's page, its one button taking focus.
    Route<void> dialog() => PageRouteBuilder<void>(
      opaque: false,
      pageBuilder: (context, _, _) => Center(
        child: RawButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          builder: (context, states, _) => plainFace('OK'),
        ),
      ),
    );

    for (final focusOnOpen in [true, false]) {
      testWidgets('closes the surface; focus is the new route\'s '
          '(focus ${focusOnOpen ? 'in' : 'on the anchor'})', (tester) async {
        final nodes = _nodes(2);
        await tester.pumpWidget(
          _at(
            Alignment.topCenter,
            _overlay(itemNodes: nodes, focusOnOpen: focusOnOpen),
          ),
        );
        await tester.tap(find.byKey(_anchorKey));
        await tester.pumpAndSettle();
        expect(find.byKey(_surfaceKey), findsOneWidget);
        final page = ModalRoute.of(tester.element(find.byKey(_anchorKey)))!;
        final pushed = dialog();
        unawaited(page.navigator!.push(pushed));
        await tester.pumpAndSettle();
        expect(find.byKey(_surfaceKey), findsNothing, reason: 'closed');
        final primary = FocusManager.instance.primaryFocus;
        expect(primary?.context, isNotNull);
        expect(
          ModalRoute.of(primary!.context!),
          same(pushed),
          reason: 'focus is in the route pushed over it',
        );
        // Popped: the page is as the anchor left it, closed.
        page.navigator!.pop();
        await tester.pumpAndSettle();
        expect(find.byKey(_surfaceKey), findsNothing);
      });

      testWidgets('closes the surface under an alert on the root navigator, '
          'over a page in a nested one '
          '(focus ${focusOnOpen ? 'in' : 'on the anchor'})', (tester) async {
        final nodes = _nodes(2);
        await tester.pumpWidget(
          harness(
            Navigator(
              onGenerateRoute: (settings) => PageRouteBuilder<void>(
                settings: settings,
                pageBuilder: (_, _, _) => Align(
                  alignment: Alignment.topCenter,
                  child: _overlay(itemNodes: nodes, focusOnOpen: focusOnOpen),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byKey(_anchorKey));
        await tester.pumpAndSettle();
        expect(find.byKey(_surfaceKey), findsOneWidget);
        final anchor = tester.element(find.byKey(_anchorKey));
        final root = Navigator.of(anchor, rootNavigator: true);
        expect(ModalRoute.of(anchor)!.navigator, isNot(same(root)));
        final pushed = dialog();
        unawaited(root.push(pushed));
        await tester.pumpAndSettle();
        expect(find.byKey(_surfaceKey), findsNothing, reason: 'closed');
        final primary = FocusManager.instance.primaryFocus;
        expect(ModalRoute.of(primary!.context!), same(pushed));
        root.pop();
        await tester.pumpAndSettle();
        expect(find.byKey(_surfaceKey), findsNothing);
      });
    }

    testWidgets('stays open while the app is in the background, '
        'and as focus moves on its page', (tester) async {
      final nodes = _nodes(2);
      final other = FocusNode(debugLabel: 'other');
      addTearDown(other.dispose);
      await tester.pumpWidget(
        _at(
          Alignment.topCenter,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _overlay(itemNodes: nodes, focusOnOpen: false),
              Focus(
                focusNode: other,
                child: const SizedBox(width: 10, height: 10),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.byKey(_anchorKey));
      await tester.pumpAndSettle();
      expect(find.byKey(_surfaceKey), findsOneWidget);
      // On a desktop, focus is parked on the root scope meanwhile.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus,
        same(FocusManager.instance.rootScope),
      );
      expect(find.byKey(_surfaceKey), findsOneWidget, reason: 'background');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      other.requestFocus();
      await tester.pumpAndSettle();
      expect(find.byKey(_surfaceKey), findsOneWidget, reason: 'its page');
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  });

  group("Android's back", () {
    // [page] pushed over a home page, as a page an app opens.
    Future<void> pushed(WidgetTester tester, Widget page) async {
      await tester.pumpWidget(harness(const Text('Home')));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push(PageRouteBuilder<void>(pageBuilder: (_, _, _) => page)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsNothing);
    }

    // The system's back: Android's button or gesture.
    Future<void> back(WidgetTester tester) async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    testWidgets(
      'closes an open surface and returns focus to its anchor, the page '
      'staying; the next back pops the page',
      (tester) async {
        final anchor = FocusNode(debugLabel: 'anchor');
        addTearDown(anchor.dispose);
        await pushed(
          tester,
          Align(
            alignment: Alignment.topCenter,
            child: _overlay(itemNodes: _nodes(2), anchorNode: anchor),
          ),
        );
        anchor.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.byKey(_surfaceKey), findsOneWidget);
        expect(anchor.hasPrimaryFocus, isFalse, reason: 'focus moved in');
        await back(tester);
        expect(find.byKey(_surfaceKey), findsNothing, reason: 'closed');
        expect(find.byKey(_anchorKey), findsOneWidget, reason: 'page stays');
        expect(anchor.hasPrimaryFocus, isTrue);
        await back(tester);
        expect(find.byKey(_anchorKey), findsNothing);
        expect(find.text('Home'), findsOneWidget);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );

    testWidgets('closes nested surfaces innermost first, then pops the page', (
      tester,
    ) async {
      Widget face(String label) => plainFace(label, key: ValueKey(label));
      await pushed(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: RawPopover(
            focusOnOpen: false,
            anchorBuilder: (context, anchor) => RawButton(
              onPressed: anchor.toggle,
              builder: (context, states, _) => face('Menu'),
            ),
            overlayBuilder: (context, info) => RawPopover(
              focusOnOpen: false,
              placement: const RawPopoverPlacement(side: RawPopoverSide.end),
              anchorBuilder: (context, anchor) => RawButton(
                onPressed: anchor.toggle,
                builder: (context, states, _) => face('More'),
              ),
              overlayBuilder: (context, info) => face('Submenu'),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('Menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('More')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('Submenu')), findsOneWidget);
      await back(tester);
      expect(find.byKey(const ValueKey('Submenu')), findsNothing);
      expect(find.byKey(const ValueKey('More')), findsOneWidget);
      await back(tester);
      expect(find.byKey(const ValueKey('More')), findsNothing);
      expect(find.byKey(const ValueKey('Menu')), findsOneWidget);
      await back(tester);
      expect(find.text('Home'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });

  testWidgets(
    'closed, a surface its anchor opened gives focus back to the anchor, '
    'though a tap on it left focus elsewhere',
    (tester) async {
      final anchor = FocusNode(debugLabel: 'anchor');
      final other = FocusNode(debugLabel: 'other');
      addTearDown(anchor.dispose);
      addTearDown(other.dispose);
      await tester.pumpWidget(
        _at(
          Alignment.topCenter,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(
                focusNode: other,
                child: const SizedBox(width: 10, height: 10),
              ),
              _overlay(itemNodes: _nodes(2), anchorNode: anchor),
            ],
          ),
        ),
      );
      other.requestFocus();
      await tester.pump();
      await tester.tap(find.byKey(_anchorKey));
      await tester.pumpAndSettle();
      expect(find.byKey(_surfaceKey), findsOneWidget);
      expect(other.hasFocus, isFalse, reason: 'focus moved in');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(_surfaceKey), findsNothing);
      expect(anchor.hasPrimaryFocus, isTrue);
    },
  );

  for (final lazy in [false, true]) {
    testWidgets(
      'Home and End focus the first and last item of a long list and keep it '
      'wholly in view (${lazy ? 'a lazy list' : 'a column'})',
      (tester) async {
        const count = 40;
        Widget item(int i) => RawButton(
          onPressed: () {},
          builder: (context, states, _) => SizedBox(
            key: ValueKey('item $i'),
            height: 30,
            child: Text('Item $i'),
          ),
        );
        final anchor = FocusNode(debugLabel: 'anchor');
        addTearDown(anchor.dispose);
        await tester.pumpWidget(
          _at(
            Alignment.topCenter,
            RawPopover(
              arrowKeyNavigation: true,
              anchorBuilder: (context, overlay) => RawButton(
                focusNode: anchor,
                onPressed: overlay.toggle,
                builder: (context, states, _) =>
                    plainFace('Open', key: _anchorKey),
              ),
              overlayBuilder: (context, info) => SizedBox(
                key: const ValueKey('list'),
                width: 120,
                height: 150,
                child: lazy
                    ? ListView.builder(
                        itemCount: count,
                        itemBuilder: (context, i) => item(i),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [for (var i = 0; i < count; i++) item(i)],
                        ),
                      ),
              ),
            ),
          ),
        );
        bool focused(int i) =>
            Focus.of(tester.element(find.byKey(ValueKey('item $i')))).hasFocus;
        bool inView(int i) {
          final list = tester.getRect(find.byKey(const ValueKey('list')));
          final row = tester.getRect(find.byKey(ValueKey('item $i')));
          return row.top >= list.top - 0.5 && row.bottom <= list.bottom + 0.5;
        }

        anchor.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(focused(0), isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('item ${count - 1}')), findsOneWidget);
        expect(focused(count - 1), isTrue, reason: 'End: the last item');
        expect(inView(count - 1), isTrue, reason: 'End: in view');
        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('item 0')), findsOneWidget);
        expect(focused(0), isTrue, reason: 'Home: the first item');
        expect(inView(0), isTrue, reason: 'Home: in view');
      },
    );
  }

  group(
    'a widget in the surface that asks for focus as it mounts keeps it',
    () {
      // A select's list of 40 options, the chosen one (30) out of the list's
      // first view; or a calendar: its month's arrows ahead of its days, the
      // chosen day (12) asking for focus.
      Widget popover({required FocusNode anchor, required bool menu}) {
        Widget item(String key, {bool chosen = false}) => RawButton(
          autofocus: chosen,
          onPressed: () {},
          builder: (context, states, _) =>
              SizedBox(key: ValueKey(key), height: 30, child: Text(key)),
        );
        return _at(
          Alignment.topCenter,
          RawPopover(
            arrowKeyNavigation: menu,
            anchorBuilder: (context, overlay) => RawButton(
              focusNode: anchor,
              onPressed: overlay.toggle,
              builder: (context, states, _) =>
                  plainFace('Open', key: _anchorKey),
            ),
            overlayBuilder: (context, info) => menu
                ? SizedBox(
                    key: const ValueKey('list'),
                    width: 120,
                    height: 150,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var i = 0; i < 40; i++)
                            item('option $i', chosen: i == 30),
                        ],
                      ),
                    ),
                  )
                : SizedBox(
                    width: 200,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(child: item('previous month')),
                            Expanded(child: item('next month')),
                          ],
                        ),
                        for (var d = 10; d < 14; d++)
                          item('day $d', chosen: d == 12),
                      ],
                    ),
                  ),
          ),
        );
      }

      bool focused(WidgetTester tester, String key) =>
          Focus.of(tester.element(find.byKey(ValueKey(key)))).hasPrimaryFocus;

      testWidgets("a select opened from the keys focuses the chosen option and "
          'keeps it in view', (tester) async {
        final anchor = FocusNode(debugLabel: 'anchor');
        addTearDown(anchor.dispose);
        await tester.pumpWidget(popover(anchor: anchor, menu: true));
        anchor.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(focused(tester, 'option 30'), isTrue);
        final list = tester.getRect(find.byKey(const ValueKey('list')));
        final row = tester.getRect(find.byKey(const ValueKey('option 30')));
        expect(
          row.top >= list.top - 0.5 && row.bottom <= list.bottom + 0.5,
          isTrue,
          reason: 'the chosen option in view: $row in $list',
        );
        // Down goes on from it.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(focused(tester, 'option 31'), isTrue);
      });

      testWidgets('a select opened with a click focuses the chosen option', (
        tester,
      ) async {
        final anchor = FocusNode(debugLabel: 'anchor');
        addTearDown(anchor.dispose);
        await tester.pumpWidget(popover(anchor: anchor, menu: true));
        await tester.tap(find.byKey(_anchorKey));
        await tester.pumpAndSettle();
        expect(focused(tester, 'option 30'), isTrue);
      });

      testWidgets("a calendar opened from the keys focuses the chosen day, not "
          "the month's arrows ahead of it", (tester) async {
        final anchor = FocusNode(debugLabel: 'anchor');
        addTearDown(anchor.dispose);
        await tester.pumpWidget(popover(anchor: anchor, menu: false));
        anchor.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(focused(tester, 'day 12'), isTrue);
        // Opened again, it asks again.
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(anchor.hasPrimaryFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(focused(tester, 'day 12'), isTrue);
      });

      testWidgets('with nothing asking, the first item has it as before', (
        tester,
      ) async {
        final anchor = FocusNode(debugLabel: 'anchor');
        addTearDown(anchor.dispose);
        await tester.pumpWidget(
          _at(
            Alignment.topCenter,
            RawPopover(
              arrowKeyNavigation: true,
              anchorBuilder: (context, overlay) => RawButton(
                focusNode: anchor,
                onPressed: overlay.toggle,
                builder: (context, states, _) =>
                    plainFace('Open', key: _anchorKey),
              ),
              overlayBuilder: (context, info) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final key in ['a', 'b'])
                    RawButton(
                      onPressed: () {},
                      builder: (context, states, _) =>
                          SizedBox(key: ValueKey(key), height: 30, width: 90),
                    ),
                ],
              ),
            ),
          ),
        );
        anchor.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(focused(tester, 'a'), isTrue);
      });
    },
  );
}
