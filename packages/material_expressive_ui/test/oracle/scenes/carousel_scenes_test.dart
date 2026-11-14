/// The `carousel` oracle group (Compose twin: `CarouselScenes.kt`): the
/// multi-browse, uncontained and centred hero carousels at rest, and the
/// hero carousel started on its third item — 360 × 200dp, items 8dp apart,
/// ten items filled in turn with the three accent containers and masked at
/// `corner.extraLarge`. Tags `mask-<i>` measure the visible items' masks
/// (and so where each item is pinned); the rounded corners are held by
/// their pixels. Compose has no
/// public full-screen (vertical) carousel and no page indicator, so neither
/// has a scene.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../harness/oracle.dart';

const Size _crop = Size(376, 216);
const Size _carousel = Size(360, 200);
const int _count = 10;
const double _spacing = 8;

/// Item [index], filled with an accent container; when it is one of
/// [tagged], its mask is tagged `mask-<i>` (the oracle places a box at
/// `carouselItemDrawInfo.maskRect`): the visible part, which stays inside
/// the crop where the item's full box does not.
IndexedWidgetBuilder _item(Set<int> tagged) => (context, index) {
  final colors = context.expressiveTheme.colors;
  final fill = ColoredBox(
    color: [
      colors.primaryContainer,
      colors.secondaryContainer,
      colors.tertiaryContainer,
    ][index % 3],
  );
  if (!tagged.contains(index)) return fill;
  final mask = ExpressiveCarouselItemInfo.of(context).maskRect;
  return Stack(
    fit: StackFit.expand,
    children: [
      fill,
      Positioned.fromRect(
        rect: mask,
        child: OracleTag('mask-$index', child: const SizedBox.expand()),
      ),
    ],
  );
};

final OracleGroup carouselScenes = OracleGroup(
  id: 'carousel',
  scenes: [
    OracleScene(
      key: 'carousel/multi-browse',
      size: _crop,
      build: (context) => SizedBox.fromSize(
        size: _carousel,
        child: ExpressiveCarouselView.multiBrowse(
          itemCount: _count,
          preferredItemWidth: 186,
          itemSpacing: _spacing,
          itemBuilder: _item({0, 1, 2}),
        ),
      ),
    ),
    OracleScene(
      key: 'carousel/uncontained',
      size: _crop,
      build: (context) => SizedBox.fromSize(
        size: _carousel,
        child: ExpressiveCarouselView.uncontained(
          itemCount: _count,
          itemWidth: 186,
          itemSpacing: _spacing,
          itemBuilder: _item({0}),
        ),
      ),
    ),
    OracleScene(
      key: 'carousel/hero',
      size: _crop,
      build: (context) => SizedBox.fromSize(
        size: _carousel,
        child: ExpressiveCarouselView.hero(
          itemCount: _count,
          itemSpacing: _spacing,
          itemBuilder: _item({0, 1, 2}),
        ),
      ),
    ),
    OracleScene(
      key: 'carousel/hero/item-2',
      size: _crop,
      build: (context) => SizedBox.fromSize(
        size: _carousel,
        child: _Started(
          (controller) => ExpressiveCarouselView.hero(
            itemCount: _count,
            itemSpacing: _spacing,
            controller: controller,
            itemBuilder: _item({1, 2, 3}),
          ),
        ),
      ),
    ),
  ],
);

/// A carousel on a controller started on item 2 (Compose's
/// `rememberCarouselState(initialItem = 2)`).
class _Started extends StatefulWidget {
  const _Started(this.builder);

  final Widget Function(ExpressiveCarouselController controller) builder;

  @override
  State<_Started> createState() => _StartedState();
}

class _StartedState extends State<_Started> {
  final ExpressiveCarouselController _controller = ExpressiveCarouselController(
    initialItem: 2,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}

void main() => runOracleGroup(carouselScenes);
