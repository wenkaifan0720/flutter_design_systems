// Where an anchored surface goes, and where its focus starts: opened at a
// point (a context menu at the pointer), clear of the on-screen keyboard,
// the safe area and a look's own chrome (RawPopoverPadding), its placed
// rectangle told to a painter in the frame it lands, and a menu a pointer
// opened holding the keys itself with no item lit.
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/src/internal/placement.dart';
import 'package:ui_core/src/internal/surface_focus.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _anchorKey = ValueKey('anchor');
const _surfaceKey = ValueKey('surface');
const _loose = RawPopoverPlacement(matchAnchorWidth: false);

late RawPopoverInfo _info;
DesignSurfaceFocus? _shared;

// The reference painter: a pressable anchor of [anchorSize] that opens the
// surface at [at] (in the anchor) or from the anchor, and a surface of
// pressable [items], or of [surfaceSize] when there are none.
Widget _menu({
  MenuController? controller,
  Offset? at,
  List<FocusNode> items = const [],
  RawPopoverPlacement placement = _loose,
  Size anchorSize = const Size(200, 44),
  Size surfaceSize = const Size(120, 90),
  FocusNode? anchorNode,
  bool arrowKeyNavigation = true,
  Widget Function(Widget surface)? paint,
}) => RawPopover(
  controller: controller,
  placement: placement,
  arrowKeyNavigation: arrowKeyNavigation,
  semanticLabel: 'Options',
  anchorBuilder: (context, anchor) => RawButton(
    focusNode: anchorNode,
    onPressed: () =>
        anchor.isOpen ? anchor.close() : anchor.controller.open(position: at),
    builder: (context, states, _) => SizedBox.fromSize(
      key: _anchorKey,
      size: anchorSize,
      child: const Text('Open'),
    ),
  ),
  overlayBuilder: (context, info) {
    _info = info;
    Widget surface = SizedBox(
      key: _surfaceKey,
      width: surfaceSize.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) {
              _shared = DesignSurfaceFocus.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
          for (var i = 0; i < items.length; i++)
            RawButton(
              focusNode: items[i],
              onPressed: info.close,
              minimumSize: const Size(44, 44),
              builder: (context, states, _) => plainFace('item $i'),
            ),
          if (items.isEmpty) SizedBox(height: surfaceSize.height),
        ],
      ),
    );
    return paint?.call(surface) ?? surface;
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

MenuController _controller() => MenuController();

Rect _surface(WidgetTester tester) => tester.getRect(find.byKey(_surfaceKey));

bool _anyItemFocused(List<FocusNode> items) => items.any((n) => n.hasFocus);

// Records what [RawPopoverInfo.surfaceRect] says each time it paints.
class _Tail extends CustomPainter {
  _Tail(this.placed) : super(repaint: placed);

  final ValueListenable<Rect?> placed;

  static final List<Rect?> painted = [];

  @override
  void paint(Canvas canvas, Size size) => painted.add(placed.value);

  @override
  bool shouldRepaint(_Tail oldDelegate) => oldDelegate.placed != placed;
}

// Reads the padding above it, counting its builds.
class _PaddingProbe extends StatelessWidget {
  const _PaddingProbe();

  static EdgeInsets? seen;
  static int builds = 0;

  @override
  Widget build(BuildContext context) {
    builds++;
    seen = RawPopoverPadding.of(context);
    return const SizedBox();
  }
}

void main() {
  group('the placement, alone', () {
    const overlay = Size(800, 600);

    test('bounds: the larger of the safe area and the keyboard, then a '
        'look\'s padding and the margin', () {
      expect(
        designOverlayBounds(
          overlaySize: overlay,
          view: null,
          padding: EdgeInsets.zero,
          margin: 8,
        ),
        const Rect.fromLTRB(8, 8, 792, 592),
      );
      expect(
        designOverlayBounds(
          overlaySize: overlay,
          view: const MediaQueryData(
            padding: EdgeInsets.only(top: 40, bottom: 30),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          padding: const EdgeInsets.only(left: 280),
          margin: 8,
        ),
        const Rect.fromLTRB(288, 48, 792, 292),
      );
      // Padding past the overlay leaves an empty rectangle, never an
      // inverted one.
      final none = designOverlayBounds(
        overlaySize: overlay,
        view: null,
        padding: const EdgeInsets.only(left: 900, top: 700),
        margin: 8,
      );
      expect(none.width, 0);
      expect(none.height, 0);
    });

    test('the side flips only when its own has less than the preferred '
        'extent and the other more', () {
      const bounds = Rect.fromLTRB(8, 8, 792, 592);
      RawPopoverSide sideFor(Rect anchor, RawPopoverPlacement p) =>
          designResolveSide(anchor, bounds, p, TextDirection.ltr);
      const low = Rect.fromLTWH(100, 500, 100, 44);
      expect(sideFor(low, _loose), RawPopoverSide.above);
      expect(
        sideFor(low, const RawPopoverPlacement(flip: false)),
        RawPopoverSide.below,
      );
      const left = Rect.fromLTWH(10, 300, 40, 40);
      expect(
        sideFor(left, const RawPopoverPlacement(side: RawPopoverSide.start)),
        RawPopoverSide.end,
      );
      expect(
        designResolveSide(
          left,
          bounds,
          const RawPopoverPlacement(side: RawPopoverSide.end),
          TextDirection.rtl,
        ),
        RawPopoverSide.start,
        reason: 'right to left, the end is the left',
      );
      expect(
        designOverlayMaxSize(
          left,
          bounds,
          RawPopoverSide.end,
          4,
          TextDirection.ltr,
        ),
        const Size(792 - 50 - 4, 584),
      );
    });

    test('at a point, a surface short of room turns across it before it '
        'shifts', () {
      const bounds = Rect.fromLTRB(8, 8, 792, 592);
      const size = Size(120, 90);
      Offset place(
        Offset point, {
        RawPopoverSide side = RawPopoverSide.below,
        RawPopoverAlign align = RawPopoverAlign.start,
        TextDirection direction = TextDirection.ltr,
      }) => designPlaceOverlay(
        anchor: Rect.fromLTWH(point.dx, point.dy, 0, 0),
        bounds: bounds,
        size: size,
        side: side,
        align: align,
        gap: 4,
        textDirection: direction,
      );
      expect(place(const Offset(100, 100)), const Offset(100, 104));
      expect(place(const Offset(750, 100)), const Offset(630, 104));
      expect(
        place(const Offset(400, 100), direction: TextDirection.rtl),
        const Offset(280, 104),
      );
      expect(
        place(const Offset(60, 100), direction: TextDirection.rtl),
        const Offset(60, 104),
      );
      expect(
        place(const Offset(100, 550), side: RawPopoverSide.above),
        const Offset(100, 456),
      );
      // Beside the point, it turns from below it to above it.
      expect(
        place(const Offset(400, 560), side: RawPopoverSide.end),
        const Offset(404, 470),
      );
      expect(
        place(
          const Offset(400, 20),
          side: RawPopoverSide.end,
          align: RawPopoverAlign.end,
        ),
        const Offset(404, 20),
      );
      // Centred, it only shifts.
      expect(
        place(const Offset(20, 100), align: RawPopoverAlign.center),
        const Offset(8, 104),
      );
    });

    test('a menu at the screen edge aligns with the opposite edge of the '
        'anchor before shifting into view', () {
      const bounds = Rect.fromLTRB(8, 8, 792, 592);
      Offset place(Size size, TextDirection direction, {bool flip = true}) =>
          designPlaceOverlay(
            anchor: const Rect.fromLTWH(700, 100, 80, 40),
            flipAlignment: flip,
            bounds: bounds,
            size: size,
            side: RawPopoverSide.below,
            align: RawPopoverAlign.start,
            gap: 4,
            textDirection: direction,
          );
      expect(place(const Size(120, 90), TextDirection.ltr).dx, 660);
      expect(
        place(const Size(120, 90), TextDirection.ltr, flip: false).dx,
        672,
      );
      expect(place(const Size(900, 90), TextDirection.ltr).dx, 8);
      expect(place(const Size(900, 90), TextDirection.rtl).dx, 792 - 900);
    });

    test('a surface rectangle tells its listeners only when it moves', () {
      final placed = DesignSurfaceRect();
      addTearDown(placed.dispose);
      var told = 0;
      placed.addListener(() => told++);
      placed.value = const Rect.fromLTWH(0, 0, 10, 10);
      placed.value = const Rect.fromLTWH(0, 0, 10, 10);
      placed.value = null;
      expect(told, 2);
    });
  });

  group('opened at a point', () {
    // A whole-screen anchor: the point in it is the point on screen.
    Future<MenuController> open(
      WidgetTester tester,
      Offset at, {
      TextDirection direction = TextDirection.ltr,
    }) async {
      final controller = _controller();
      await tester.pumpWidget(
        _at(
          Alignment.topLeft,
          _menu(controller: controller, anchorSize: const Size(800, 600)),
          direction: direction,
        ),
      );
      controller.open(position: at);
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('it opens below the point, from its start, and says where', (
      tester,
    ) async {
      await open(tester, const Offset(100, 100));
      expect(_surface(tester), const Rect.fromLTWH(100, 104, 120, 90));
      expect(_info.position, const Offset(100, 100));
      expect(_info.side, RawPopoverSide.below);
      expect(_info.anchorRect, const Rect.fromLTWH(0, 0, 800, 600));
    });

    testWidgets('short of room at the end, it opens towards the start', (
      tester,
    ) async {
      await open(tester, const Offset(750, 100));
      expect(_surface(tester).right, 750);
    });

    testWidgets('short of room below, it opens above the point', (
      tester,
    ) async {
      await open(tester, const Offset(100, 550));
      expect(_info.side, RawPopoverSide.above);
      expect(_surface(tester).bottom, 546);
    });

    testWidgets('right to left, it opens from the point leftwards', (
      tester,
    ) async {
      await open(tester, const Offset(400, 100), direction: TextDirection.rtl);
      expect(_surface(tester).right, 400);
    });

    testWidgets('a list at a point does not take the anchor\'s width', (
      tester,
    ) async {
      final controller = _controller();
      await tester.pumpWidget(
        _at(
          Alignment.topLeft,
          _menu(
            controller: controller,
            anchorSize: const Size(800, 600),
            placement: const RawPopoverPlacement(),
          ),
        ),
      );
      controller.open(position: const Offset(100, 100));
      await tester.pumpAndSettle();
      expect(_surface(tester).width, 120);
      controller.close();
      await tester.pumpAndSettle();
      controller.open();
      await tester.pumpAndSettle();
      expect(_info.position, isNull);
    });
  });

  group('the bounds it keeps to', () {
    late MenuController ctl;
    setUp(() => ctl = _controller());

    // An anchor in the middle of the screen: 278 to 322 down.
    Widget middle({bool scaffoldLike = false, Widget? chrome}) => harness(
      Builder(
        builder: (context) {
          Widget page = Align(child: _menu(controller: ctl));
          if (chrome != null) page = chrome;
          if (!scaffoldLike) return page;
          // As a scaffold does round its body: the keyboard's inset and the
          // padding taken out of what the anchor sees.
          return MediaQuery.removeViewInsets(
            context: context,
            removeBottom: true,
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              removeTop: true,
              child: page,
            ),
          );
        },
      ),
    );

    for (final scaffoldLike in [false, true]) {
      final round = scaffoldLike ? ' (inside a scaffold-like page)' : '';
      testWidgets('it stays above the on-screen keyboard$round', (
        tester,
      ) async {
        await tester.pumpWidget(middle(scaffoldLike: scaffoldLike));
        ctl.open();
        await tester.pumpAndSettle();
        expect(_info.side, RawPopoverSide.below);
        // The keyboard comes up under the open surface: 300 tall.
        tester.view.viewInsets = FakeViewPadding(
          bottom: 300 * tester.view.devicePixelRatio,
        );
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(_info.side, RawPopoverSide.above);
        expect(_surface(tester).bottom, lessThanOrEqualTo(300 - 8));
      });

      testWidgets('it keeps clear of the safe area$round', (tester) async {
        tester.view.padding = FakeViewPadding(
          bottom: 100 * tester.view.devicePixelRatio,
        );
        addTearDown(tester.view.resetPadding);
        await tester.pumpWidget(middle(scaffoldLike: scaffoldLike));
        ctl.open();
        await tester.pumpAndSettle();
        // 166 below (600 - 100 - 8 - 322 - 4) is short of 200.
        expect(_info.side, RawPopoverSide.above);
      });
    }

    for (final direction in TextDirection.values) {
      testWidgets('it keeps clear of a look\'s chrome (${direction.name})', (
        tester,
      ) async {
        final controller = _controller();
        await tester.pumpWidget(
          _at(
            AlignmentDirectional.topStart.resolve(direction),
            RawPopoverPadding(
              padding: const EdgeInsetsDirectional.only(start: 280),
              child: _menu(
                controller: controller,
                anchorSize: const Size(44, 44),
              ),
            ),
            direction: direction,
          ),
        );
        controller.open();
        await tester.pumpAndSettle();
        final surface = _surface(tester);
        if (direction == TextDirection.ltr) {
          expect(surface.left, 288);
        } else {
          expect(surface.right, 800 - 288);
        }
      });
    }

    testWidgets('RawPopoverPadding.of: none is zero; a change tells its '
        'dependents', (tester) async {
      Widget app(EdgeInsetsGeometry? padding) => harness(
        padding == null
            ? const _PaddingProbe()
            : RawPopoverPadding(padding: padding, child: const _PaddingProbe()),
        textDirection: TextDirection.rtl,
      );
      await tester.pumpWidget(app(null));
      expect(_PaddingProbe.seen, EdgeInsets.zero);
      await tester.pumpWidget(app(const EdgeInsetsDirectional.only(start: 10)));
      expect(_PaddingProbe.seen, const EdgeInsets.only(right: 10));
      final before = _PaddingProbe.builds;
      await tester.pumpWidget(app(const EdgeInsetsDirectional.only(start: 10)));
      expect(_PaddingProbe.builds, before, reason: 'the same padding: quiet');
      await tester.pumpWidget(app(const EdgeInsetsDirectional.only(start: 20)));
      expect(_PaddingProbe.seen, const EdgeInsets.only(right: 20));
      expect(_PaddingProbe.builds, before + 1);
      const padding = RawPopoverPadding(
        padding: EdgeInsets.all(1),
        child: SizedBox(),
      );
      expect(padding.toString(), contains('padding'));
      final properties = DiagnosticPropertiesBuilder();
      padding.debugFillProperties(properties);
      expect(properties.properties.map((p) => p.name), contains('padding'));
    });
  });

  group('its placed rectangle', () {
    testWidgets('a painter reads it in the frame the surface lands, and '
        'again when it moves', (tester) async {
      _Tail.painted.clear();
      final controller = _controller();
      await tester.pumpWidget(
        _at(
          Alignment.center,
          _menu(
            controller: controller,
            paint: (surface) =>
                CustomPaint(painter: _Tail(_info.surfaceRect), child: surface),
          ),
        ),
      );
      controller.open();
      await tester.pump();
      expect(_Tail.painted, isNotEmpty);
      expect(_Tail.painted.first, _surface(tester));
      tester.view.viewInsets = FakeViewPadding(
        bottom: 300 * tester.view.devicePixelRatio,
      );
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(_Tail.painted.last, _surface(tester));
      expect(_info.side, RawPopoverSide.above);
    });

    test('a surface built by hand has none', () {
      final info = RawPopoverInfo(
        side: RawPopoverSide.below,
        anchorRect: Rect.zero,
        maxSize: Size.zero,
        animation: kAlwaysCompleteAnimation,
        close: () {},
      );
      void listener() {}
      info.surfaceRect
        ..addListener(listener)
        ..removeListener(listener);
      expect(info.surfaceRect.value, isNull);
      expect(info.position, isNull);
    });
  });

  group('where a menu\'s focus starts', () {
    testWidgets('opened by a pointer: on the surface, no item lit; Down goes '
        'to the first, Up to the last', (tester) async {
      final items = _nodes(3);
      await tester.pumpWidget(_at(Alignment.center, _menu(items: items)));
      await tester.tap(find.byKey(_anchorKey));
      await tester.pumpAndSettle();
      expect(_anyItemFocused(items), isFalse, reason: 'no item lit');
      expect(_shared, isNotNull);
      expect(_shared!.byPointer.value, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(items[0].hasPrimaryFocus, isTrue);
      expect(_shared!.byPointer.value, isFalse, reason: 'the keys moved last');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(_surfaceKey), findsNothing);
      expect(
        Focus.of(tester.element(find.byKey(_anchorKey))).hasFocus,
        isTrue,
        reason: 'focus goes to the anchor that opened it',
      );
      await tester.tap(find.byKey(_anchorKey));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(items[2].hasPrimaryFocus, isTrue);
      // Down from an item still goes on round.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(items[0].hasPrimaryFocus, isTrue);
    });

    testWidgets('opened by a pointer: Tab goes to the first item, Shift+Tab '
        'to the last', (tester) async {
      final items = _nodes(3);
      await tester.pumpWidget(_at(Alignment.center, _menu(items: items)));
      await tester.tap(find.byKey(_anchorKey));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(items[0].hasPrimaryFocus, isTrue);
      _shared!.focusSurface();
      await tester.pump();
      expect(_anyItemFocused(items), isFalse);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();
      expect(items[2].hasPrimaryFocus, isTrue);
    });

    testWidgets('opened from the keys: on the first item', (tester) async {
      final items = _nodes(2);
      final anchor = FocusNode(debugLabel: 'anchor');
      addTearDown(anchor.dispose);
      await tester.pumpWidget(
        _at(Alignment.center, _menu(items: items, anchorNode: anchor)),
      );
      anchor.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(items[0].hasPrimaryFocus, isTrue);
    });

    testWidgets('opened by a screen reader: on the first item', (tester) async {
      final semantics = tester.ensureSemantics();
      final items = _nodes(2);
      await tester.pumpWidget(_at(Alignment.center, _menu(items: items)));
      tester.semantics.tap(find.semantics.byLabel('Open'));
      await tester.pumpAndSettle();
      expect(items[0].hasPrimaryFocus, isTrue);
      semantics.dispose();
    });

    testWidgets('a click that arrives as a screen reader\'s tap (the web with '
        'semantics on), the mouse on the anchor: no item lit', (tester) async {
      final semantics = tester.ensureSemantics();
      final items = _nodes(2);
      await tester.pumpWidget(_at(Alignment.center, _menu(items: items)));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byKey(_anchorKey)));
      await tester.pump();
      tester.semantics.tap(find.semantics.byLabel('Open'));
      await tester.pumpAndSettle();
      expect(find.byKey(_surfaceKey), findsOneWidget);
      expect(_anyItemFocused(items), isFalse);
      // The mouse gone, a reader's tap starts on the first item again.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      tester.semantics.tap(find.semantics.byLabel('Open'));
      await tester.pumpAndSettle();
      expect(items[0].hasPrimaryFocus, isTrue);
      semantics.dispose();
    });

    testWidgets('a popover (no arrow keys) a pointer opened still focuses its '
        'first item', (tester) async {
      final items = _nodes(2);
      await tester.pumpWidget(
        _at(Alignment.center, _menu(items: items, arrowKeyNavigation: false)),
      );
      await tester.tap(find.byKey(_anchorKey));
      await tester.pumpAndSettle();
      expect(items[0].hasPrimaryFocus, isTrue);
    });

    testWidgets('the surface\'s own keys: typed letters reach its handler '
        'while no item holds them, and the pointer takes over on a move', (
      tester,
    ) async {
      final items = _nodes(2);
      await tester.pumpWidget(_at(Alignment.center, _menu(items: items)));
      await tester.tap(find.byKey(_anchorKey));
      await tester.pumpAndSettle();
      final got = <LogicalKeyboardKey>[];
      // A menu's typed letters: letters only; the arrows go on to the menu.
      _shared!.onKey.value = (node, event) {
        final letter = event.character?.trim().isNotEmpty ?? false;
        if (!letter) return KeyEventResult.ignored;
        if (event is KeyDownEvent) got.add(event.logicalKey);
        return KeyEventResult.handled;
      };
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      expect(got, [LogicalKeyboardKey.keyA]);
      expect(_shared!.byPointer.value, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      expect(got, [LogicalKeyboardKey.keyA], reason: 'an item has the keys');
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: tester.getCenter(find.text('item 1')));
      await mouse.moveBy(const Offset(1, 1));
      await tester.pump();
      expect(_shared!.byPointer.value, isTrue);
      _shared!.onKey.value = null;
      _shared!.focusSurface();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      expect(got, [LogicalKeyboardKey.keyA], reason: 'no handler, no letters');
    });

    testWidgets('outside a surface there is none to share', (tester) async {
      DesignSurfaceFocus? outside;
      await tester.pumpWidget(
        harness(
          Builder(
            builder: (context) {
              outside = DesignSurfaceFocus.maybeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(outside, isNull);
    });
  });

  final contractItems = [FocusNode(), FocusNode()];
  tearDownAll(() {
    for (final n in contractItems) {
      n.dispose();
    }
  });
  behaviourContract(
    'RawPopover at a point',
    build: (c) => Align(
      alignment: Alignment.topLeft,
      child: _menu(
        at: const Offset(200, 20),
        items: contractItems,
        anchorSize: const Size(300, 200),
      ),
    ),
    open: (tester) async {
      await tester.tap(find.byKey(_anchorKey));
    },
    node: () => find.bySemanticsLabel('Options'),
    semantics: isSemantics(label: 'Options'),
    noDisabledState:
        'a surface has no disabled state: what opens it (the anchor\'s '
        'press, a context menu) has one',
    keyboard: (p) async {
      expect(contractItems.any((n) => n.hasFocus), isFalse);
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(contractItems[0].hasPrimaryFocus, isTrue);
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(contractItems[1].hasPrimaryFocus, isTrue);
      await p.key(LogicalKeyboardKey.escape);
      expect(find.byKey(_surfaceKey), findsNothing);
    },
    rtl: (p) async {
      // From the point (200 in from the anchor's left) towards the start,
      // the left.
      expect(
        p.tester.getTopRight(find.byKey(_surfaceKey)),
        p.tester.getTopLeft(find.byKey(_anchorKey)) + const Offset(200, 24),
      );
    },
    motion: (p) async {
      await p.key(LogicalKeyboardKey.escape);
      await p.tester.tap(find.byKey(_anchorKey));
      await p.tester.pump();
    },
  );

  group('every side, alignment and direction, round an anchor and at a '
      'point, stays on screen', () {
    const xs = [0.0, 370.0, 740.0];
    const ys = [0.0, 285.0, 570.0];
    for (final side in RawPopoverSide.values) {
      for (final align in RawPopoverAlign.values) {
        for (final direction in TextDirection.values) {
          testWidgets('${side.name} ${align.name} ${direction.name}', (
            tester,
          ) async {
            final placement = RawPopoverPlacement(
              side: side,
              align: align,
              matchAnchorWidth: false,
            );
            const bounds = Rect.fromLTRB(8, 8, 792, 592);
            for (final x in xs) {
              for (final y in ys) {
                final controller = _controller();
                await tester.pumpWidget(
                  harness(
                    Stack(
                      children: [
                        Positioned(
                          left: x,
                          top: y,
                          child: _menu(
                            controller: controller,
                            placement: placement,
                            anchorSize: const Size(60, 30),
                          ),
                        ),
                      ],
                    ),
                    textDirection: direction,
                  ),
                );
                final anchor = tester.getRect(find.byKey(_anchorKey));
                controller.open();
                await tester.pumpAndSettle();
                var surface = _surface(tester);
                expect(bounds.inflate(0.01).contains(surface.topLeft), isTrue);
                expect(
                  bounds.inflate(0.01).contains(surface.bottomRight),
                  isTrue,
                );
                expect(
                  surface.overlaps(anchor.deflate(0.5)),
                  isFalse,
                  reason: 'round $anchor it covers none of it',
                );
                controller.close();
                await tester.pumpAndSettle();
                final point = anchor.center - anchor.topLeft;
                controller.open(position: point);
                await tester.pumpAndSettle();
                surface = _surface(tester);
                expect(bounds.inflate(0.01).contains(surface.topLeft), isTrue);
                expect(
                  surface.deflate(0.5).contains(anchor.center),
                  isFalse,
                  reason: 'at ${anchor.center} it never lies under the point',
                );
                controller.close();
                await tester.pumpAndSettle();
              }
            }
          }, tags: 'sweep');
        }
      }
    }
  });
}
