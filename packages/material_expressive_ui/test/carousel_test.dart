/// Carousel: the keyline strategies worked by hand from Compose's
/// `Keylines.kt` / `Arrangement.kt`, the strategy's end steps and snap
/// offsets, the laid-out items (masks, pinned edges, snapping, the
/// controller, RTL, full-screen paging) and the page indicator.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

Widget _app(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    ExpressiveHost(
      light: _theme,
      brightness: Brightness.light,
      child: Directionality(
        textDirection: direction,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    );

List<(double, double)> _sizesAndOffsets(ExpressiveCarouselKeylines k) => [
  for (final keyline in k.keylines) (keyline.size, keyline.offset),
];

Widget _item(BuildContext context, int index) =>
    ColoredBox(color: const Color(0xFF336699), child: Text('item $index'));

/// The visible span of item [index] along x: its mask, in global
/// coordinates.
(double, double) _mask(WidgetTester tester, int index) {
  final origin = tester.getTopLeft(find.byKey(ValueKey<int>(index))).dx;
  final info = ExpressiveCarouselItemInfo.of(
    tester.element(find.text('item $index')),
  );
  return (origin + info.maskRect.left, origin + info.maskRect.right);
}

void main() {
  group('keylines (Keylines.kt)', () {
    test('multi-browse, 400 wide, preferring 186: two large, one small', () {
      final k = expressiveMultiBrowseKeylines(
        mainAxisSize: 400,
        preferredItemSize: 186,
        itemSpacing: 0,
        itemCount: 10,
        minSmallItemSize: 40,
        maxSmallItemSize: 56,
        anchorSize: 10,
      );
      expect(_sizesAndOffsets(k), [
        (10, -5),
        (180, 90),
        (180, 270),
        (40, 380),
        (10, 405),
      ]);
      expect(k.firstFocalIndex, 1);
      expect(k.lastFocalIndex, 2);
      expect(k.first.isAnchor && k.last.isAnchor, isTrue);
    });

    test('multi-browse drops the small item when there are too few items', () {
      final k = expressiveMultiBrowseKeylines(
        mainAxisSize: 400,
        preferredItemSize: 186,
        itemCount: 2,
        itemSpacing: 0,
        minSmallItemSize: 40,
        maxSmallItemSize: 56,
        anchorSize: 10,
      );
      expect(k.keylines.where((k) => !k.isAnchor).length, 2);
    });

    test('uncontained, 400 wide, items 186: two whole, one cut off', () {
      final k = expressiveUncontainedKeylines(
        mainAxisSize: 400,
        itemSize: 186,
        itemSpacing: 0,
        anchorSize: 10,
      );
      expect(_sizesAndOffsets(k), [
        (21, -10.5),
        (186, 93),
        (186, 279),
        (42, 393),
        (10, 419),
      ]);
      expect(k[3].cutoff, 14);
    });

    test('centred hero, 400 wide: one large between two small', () {
      final k = expressiveHeroKeylines(
        mainAxisSize: 400,
        maxItemSize: null,
        itemSpacing: 0,
        itemCount: 10,
        centered: true,
        minSmallItemSize: 40,
        maxSmallItemSize: 56,
        anchorSize: 10,
      );
      expect(_sizesAndOffsets(k), [
        (10, -5),
        (40, 20),
        (320, 200),
        (40, 380),
        (10, 405),
      ]);
    });

    test('hero with two items is start-aligned', () {
      final k = expressiveHeroKeylines(
        mainAxisSize: 400,
        maxItemSize: null,
        itemSpacing: 0,
        itemCount: 2,
        centered: true,
        minSmallItemSize: 40,
        maxSmallItemSize: 56,
        anchorSize: 10,
      );
      expect(k.firstFocal.offset - k.firstFocal.size / 2, 0);
    });

    test('spacing separates keylines', () {
      final k = expressiveMultiBrowseKeylines(
        mainAxisSize: 400,
        preferredItemSize: 186,
        itemSpacing: 8,
        itemCount: 10,
        minSmallItemSize: 40,
        maxSmallItemSize: 56,
        anchorSize: 10,
      );
      final visible = k.keylines.where((k) => !k.isAnchor).toList();
      for (var i = 1; i < visible.length; i++) {
        final gap =
            (visible[i].offset - visible[i].size / 2) -
            (visible[i - 1].offset + visible[i - 1].size / 2);
        expect(gap, closeTo(8, 1e-9));
      }
      final end = visible.last.offset + visible.last.size / 2;
      expect(end, closeTo(400, 1e-9));
    });
  });

  group('strategy (Strategy.kt)', () {
    final keylines = expressiveMultiBrowseKeylines(
      mainAxisSize: 400,
      preferredItemSize: 186,
      itemSpacing: 0,
      itemCount: 10,
      minSmallItemSize: 40,
      maxSmallItemSize: 56,
      anchorSize: 10,
    );
    final strategy = ExpressiveCarouselStrategy(keylines, availableSpace: 400);

    test('the rest keylines in the middle, shifted steps at the end', () {
      expect(strategy.isValid, isTrue);
      expect(strategy.itemMainAxisSize, 180);
      expect(strategy.startKeylineSteps, hasLength(1));
      expect(strategy.endKeylineSteps.length, greaterThan(1));
      final max = strategy.maxScrollOffset(10);
      expect(max, 180 * 10 - 400);
      expect(strategy.keylinesFor(500, max), keylines);
      // At the end the last item is focal and flush with the end.
      final end = strategy.keylinesFor(max, max);
      expect(end.lastFocal.offset + end.lastFocal.size / 2, closeTo(400, 1e-6));
    });

    test('snap offsets: 0 from the start, the end steps at the end', () {
      expect(strategy.snapPositionOffset(0, 10), 0);
      expect(strategy.snapPositionOffset(5, 10), 0);
      final layout = ExpressiveCarouselLayout(
        strategy: strategy,
        itemCount: 10,
        pageSpacing: 0,
      );
      expect(layout.snapScrollOffset(9), layout.maxScrollOffset);
      for (var i = 1; i < 10; i++) {
        expect(
          layout.snapScrollOffset(i),
          greaterThanOrEqualTo(layout.snapScrollOffset(i - 1)),
        );
      }
    });

    test('content padding shifts the first item in', () {
      final padded = ExpressiveCarouselStrategy(
        keylines,
        availableSpace: 400,
        beforeContentPadding: 16,
      );
      final start = padded.keylinesFor(0, padded.maxScrollOffset(10));
      expect(
        start.firstFocal.offset - start.firstFocal.size / 2,
        closeTo(16, 1e-6),
      );
    });
  });

  group('ExpressiveCarouselView', () {
    testWidgets('multi-browse at rest: masks pinned edge to edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 400,
            child: ExpressiveCarouselView.multiBrowse(
              itemCount: 10,
              preferredItemWidth: 186,
              height: 200,
              itemBuilder: _item,
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(ExpressiveCarouselView)).height, 200);
      expect(_mask(tester, 0).$1, closeTo(0, 0.01));
      expect(_mask(tester, 0).$2, closeTo(180, 0.01));
      expect(_mask(tester, 1).$1, closeTo(180, 0.01));
      expect(_mask(tester, 2).$1, closeTo(360, 0.01));
      expect(_mask(tester, 2).$2, closeTo(400, 0.01));
      // Items are laid out at the focal size; the content is not squeezed.
      expect(
        tester.getSize(find.byKey(const ValueKey<int>(2))).width,
        closeTo(180, 0.01),
      );
      expect(find.text('item 5'), findsNothing);
    });

    testWidgets('a fling advances one item and snaps', (tester) async {
      final controller = ExpressiveCarouselController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 400,
            child: ExpressiveCarouselView.multiBrowse(
              itemCount: 10,
              preferredItemWidth: 186,
              height: 200,
              controller: controller,
              itemBuilder: _item,
            ),
          ),
        ),
      );
      await tester.fling(
        find.byType(ExpressiveCarouselView),
        const Offset(-600, 0),
        3000,
      );
      await tester.pumpAndSettle();
      expect(controller.currentItem, 1);
      expect(controller.offset, closeTo(180, 0.01));
      expect(_mask(tester, 1).$1, closeTo(0, 0.01));
    });

    testWidgets('the controller springs to an item and to the end', (
      tester,
    ) async {
      final controller = ExpressiveCarouselController(initialItem: 3);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 400,
            child: ExpressiveCarouselView.hero(
              itemCount: 6,
              height: 200,
              controller: controller,
              itemBuilder: _item,
            ),
          ),
        ),
      );
      expect(controller.currentItem, 3);
      controller.animateToItem(5);
      await tester.pumpAndSettle();
      expect(controller.currentItem, 5);
      expect(controller.offset, controller.position.maxScrollExtent);
      // The last item is the large one, flush with the end.
      expect(_mask(tester, 5).$2, closeTo(400, 0.01));
      expect(_mask(tester, 5).$2 - _mask(tester, 5).$1, closeTo(320, 0.5));
    });

    testWidgets('RTL mirrors the layout', (tester) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 400,
            child: ExpressiveCarouselView.multiBrowse(
              itemCount: 10,
              preferredItemWidth: 186,
              height: 200,
              itemBuilder: _item,
            ),
          ),
          direction: TextDirection.rtl,
        ),
      );
      expect(_mask(tester, 0).$2, closeTo(400, 0.01));
      expect(_mask(tester, 0).$1, closeTo(220, 0.01));
      expect(_mask(tester, 2).$1, closeTo(0, 0.01));
    });

    testWidgets(
      'an interactive mask follows a jump before its shape spring settles',
      (tester) async {
        final controller = ExpressiveCarouselController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _app(
            SizedBox(
              width: 400,
              child: ExpressiveCarouselView.multiBrowse(
                itemCount: 10,
                preferredItemWidth: 186,
                height: 200,
                controller: controller,
                onItemTap: (_) {},
                itemBuilder: _item,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        controller.jumpToItem(3);
        await tester.pump();
        final text = find.text('item 3');
        final info = ExpressiveCarouselItemInfo.of(tester.element(text));
        final clip = find
            .ancestor(of: text, matching: find.byType(ClipPath))
            .first;
        final widget = tester.widget<ClipPath>(clip);
        final painted = widget.clipper!
            .getClip(tester.getSize(clip))
            .getBounds();
        expect(painted.left, closeTo(info.maskRect.left, .01));
        expect(painted.right, closeTo(info.maskRect.right, .01));
      },
    );

    testWidgets('an item tap reports its index', (tester) async {
      int? tapped;
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 400,
            child: ExpressiveCarouselView.uncontained(
              itemCount: 5,
              itemWidth: 186,
              height: 200,
              onItemTap: (i) => tapped = i,
              itemBuilder: _item,
            ),
          ),
        ),
      );
      await tester.tapAt(const Offset(250, 100));
      expect(tapped, 1);
    });

    testWidgets('full-screen pages vertically, one item per swipe', (
      tester,
    ) async {
      final controller = ExpressiveCarouselController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 360,
            height: 480,
            child: ExpressiveCarouselView.fullScreen(
              itemCount: 4,
              controller: controller,
              itemBuilder: _item,
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const ValueKey<int>(0))).height, 480);
      await tester.fling(
        find.byType(ExpressiveCarouselView),
        const Offset(0, -300),
        2500,
      );
      await tester.pumpAndSettle();
      expect(controller.currentItem, 1);
      expect(controller.offset, closeTo(480, 0.01));
    });
  });

  group('ExpressivePageDots', () {
    testWidgets('a dot per page, the current one a pill', (tester) async {
      await tester.pumpWidget(
        _app(const ExpressivePageDots(count: 4, selectedIndex: 1)),
      );
      await tester.pumpAndSettle();
      final boxes = tester
          .widgetList<SizedBox>(
            find.descendant(
              of: find.byType(ExpressivePageDots),
              matching: find.byWidgetPredicate(
                (w) => w is SizedBox && w.height == ExpressiveSpacing.s8,
              ),
            ),
          )
          .map((box) => box.width)
          .toList();
      expect(boxes, [8, 24, 8, 8]);
    });

    testWidgets('the current pill is primary, the other dots outline '
        '(3:1 against the page, as a control needs)', (tester) async {
      await tester.pumpWidget(
        _app(const ExpressivePageDots(count: 3, selectedIndex: 0)),
      );
      await tester.pumpAndSettle();
      final colors = tester
          .element(find.byType(ExpressivePageDots))
          .expressiveTheme
          .colors;
      final fills = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(ExpressivePageDots),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => (box.decoration as ShapeDecoration).color)
          .toList();
      expect(fills, [colors.primary, colors.outline, colors.outline]);
    });

    testWidgets('centred page-dot hit bounds follow both layout directions', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        for (final width in [72.0, 240.0]) {
          int? chosen;
          await tester.pumpWidget(
            _app(
              SizedBox(
                width: width,
                child: ExpressivePageDots(
                  count: 4,
                  selectedIndex: 0,
                  onChanged: (index) => chosen = index,
                ),
              ),
              direction: direction,
            ),
          );
          final rect = tester.getRect(find.byType(ExpressivePageDots));
          await tester.tapAt(
            Offset(
              direction == TextDirection.ltr ? rect.right - 4 : rect.left + 4,
              rect.center.dy,
            ),
          );
          expect(chosen, 3, reason: '$direction at $width');
        }
      }
    });

    testWidgets('a tap chooses a page; semantics step through pages', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var page = 0;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => ExpressivePageDots(
              count: 4,
              selectedIndex: page,
              onChanged: (i) => setState(() => page = i),
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(ExpressivePageDots));
      // The last dot is at the row's end.
      await tester.tapAt(Offset(rect.right - 4, rect.center.dy));
      await tester.pumpAndSettle();
      expect(page, 3);
      expect(
        tester.getSemantics(find.byType(ExpressivePageDots)),
        isSemantics(value: 'Slide 4 of 4', hasDecreaseAction: true),
      );
      handle.dispose();
    });
  });
}
