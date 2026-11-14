/// The carousel group's demo: the multi-browse, uncontained, centred hero
/// and full-screen carousels over media slots, each item's label fading
/// with its mask, the hero and full-screen carousels paired with the page
/// indicator, and the page indicator on its own. Pictures resolve from
/// media slots; the gallery bundles none, so each shows the placeholder a
/// pending picture paints.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The carousel group's demo, in [brightness].
Widget kitCarouselDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Carousel',
  sections: const <Widget>[
    _MultiBrowse(),
    _Uncontained(),
    _Hero(),
    _FullScreen(),
    _Indicators(),
  ],
);

/// Places to go: a media slot and a name each.
const List<(String, String)> _places = <(String, String)>[
  ('harbour-dusk', 'Harbour at dusk'),
  ('forest-canopy', 'Forest canopy'),
  ('landscape-dunes', 'The dunes'),
  ('market-stall', 'Saturday market'),
  ('ridge-trail', 'Ridge trail'),
  ('evening-sail', 'Evening sail'),
  ('reading-room', 'Reading room'),
  ('bakery-window', 'Rye & Salt'),
];

/// The narrowest label pill worth showing: a short name and its padding.
const double _labelRoom = 72;

/// One carousel item: the place's picture under the mask, its name fading
/// in over the last stretch of the mask's opening — none on a small item
/// (no room for a word), full on a large one, never a half-faded label that
/// reads as disabled for long.
Widget _place(BuildContext context, int index) {
  final (slot, name) = _places[index % _places.length];
  final t = context.expressiveTheme;
  final info = ExpressiveCarouselItemInfo.of(context);
  final room = info.contentRect.width - ExpressiveSpacing.s24;
  final opacity = room < _labelRoom
      ? 0.0
      : ((info.openness - 0.75) / 0.25).clamp(0.0, 1.0);
  return Stack(
    fit: StackFit.expand,
    children: <Widget>[
      ExpressiveMedia(slotId: slot, semanticLabel: name),
      // Inside the mask, whichever way the item is cut.
      if (opacity > 0)
        Positioned(
          left: info.contentRect.left + ExpressiveSpacing.s12,
          width: room,
          bottom: ExpressiveSpacing.s12,
          child: Opacity(
            opacity: opacity,
            child: Align(
              alignment: AlignmentDirectional.bottomStart,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: t.colors.surfaceContainerHighest,
                  shape: t.shapes.full,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ExpressiveSpacing.s12,
                    vertical: ExpressiveSpacing.s4,
                  ),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.type.labelLarge.copyWith(
                      color: t.colors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _MultiBrowse extends StatelessWidget {
  const _MultiBrowse();

  @override
  Widget build(BuildContext context) => kitSection(
    'Multi-browse · large, medium, small',
    children: <Widget>[
      ExpressiveCarouselView.multiBrowse(
        itemCount: _places.length,
        preferredItemWidth: 186,
        height: 200,
        itemSpacing: ExpressiveSpacing.s8,
        semanticLabel: 'Places',
        itemBuilder: _place,
      ),
    ],
  );
}

class _Uncontained extends StatelessWidget {
  const _Uncontained();

  @override
  Widget build(BuildContext context) => kitSection(
    'Uncontained · free scroll',
    children: <Widget>[
      ExpressiveCarouselView.uncontained(
        itemCount: _places.length,
        itemWidth: 160,
        height: 200,
        itemSpacing: ExpressiveSpacing.s8,
        semanticLabel: 'Places',
        itemBuilder: _place,
      ),
    ],
  );
}

/// A carousel with its page indicator under it, tracking and driving it.
class _WithIndicator extends StatefulWidget {
  const _WithIndicator({required this.builder, this.initialItem = 0});

  final Widget Function(ExpressiveCarouselController controller) builder;

  /// The item the carousel opens on.
  final int initialItem;

  @override
  State<_WithIndicator> createState() => _WithIndicatorState();
}

class _WithIndicatorState extends State<_WithIndicator> {
  late final ExpressiveCarouselController _controller =
      ExpressiveCarouselController(initialItem: widget.initialItem);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: kitGap,
    children: <Widget>[
      widget.builder(_controller),
      ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => Center(
          child: ExpressivePageDots(
            count: _places.length,
            selectedIndex: _controller.currentItem,
            onChanged: _controller.animateToItem,
          ),
        ),
      ),
    ],
  );
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) => kitSection(
    'Hero · centred, one at a time',
    children: <Widget>[
      // Open on the second place: the first sits at the start with both
      // neighbours after it (nothing comes before it), as Compose's does.
      _WithIndicator(
        initialItem: 1,
        builder: (controller) => ExpressiveCarouselView.hero(
          itemCount: _places.length,
          height: 220,
          itemSpacing: ExpressiveSpacing.s8,
          controller: controller,
          semanticLabel: 'Featured places',
          itemBuilder: _place,
        ),
      ),
    ],
  );
}

class _FullScreen extends StatelessWidget {
  const _FullScreen();

  @override
  Widget build(BuildContext context) => kitSection(
    'Full-screen · vertical, one per swipe',
    children: <Widget>[
      _WithIndicator(
        builder: (controller) => SizedBox(
          height: 360,
          child: ExpressiveCarouselView.fullScreen(
            itemCount: _places.length,
            controller: controller,
            semanticLabel: 'Places, full screen',
            itemBuilder: _place,
          ),
        ),
      ),
    ],
  );
}

class _Indicators extends StatelessWidget {
  const _Indicators();

  @override
  Widget build(BuildContext context) => kitSection(
    'Page indicator · first, middle, last',
    children: const <Widget>[
      ExpressivePageDots(count: 5, selectedIndex: 0),
      ExpressivePageDots(count: 5, selectedIndex: 2),
      ExpressivePageDots(count: 5, selectedIndex: 4),
    ],
  );
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// The multi-browse carousel at rest: a large item, a medium and a small.
Widget kitSpecimenCarouselMultiBrowse() => ExpressiveCarouselView.multiBrowse(
  itemCount: _places.length,
  preferredItemWidth: 186,
  height: 200,
  itemSpacing: ExpressiveSpacing.s8,
  semanticLabel: 'Places',
  itemBuilder: _place,
);

/// Five pages, the second current.
Widget kitSpecimenPageIndicatorFive() =>
    const Center(child: ExpressivePageDots(count: 5, selectedIndex: 1));
