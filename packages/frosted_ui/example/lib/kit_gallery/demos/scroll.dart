/// Frosted's scrolling parts: [FrostedScrollArea]'s thin thumb,
/// [FrostedResizable]'s two panes and the handle between them,
/// [FrostedCarouselView]'s slides, [FrostedReorderableListView]'s rows
/// dragged by their grips and [FrostedRefreshIndicator] over a list.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

const _items = [
  'Inbox',
  'Today',
  'Upcoming',
  'Anytime',
  'Someday',
  'Logbook',
  'Archive',
  'Trash',
  'Shared',
  'Starred',
];

Widget kitScrollDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Scroll',
  sections: [
    kitSection('Scroll area', children: const [_Area()]),
    kitSection(
      'Resizable',
      children: [
        SizedBox(
          height: 180,
          child: FrostedResizable(
            initialFraction: .4,
            minFirst: 80,
            minSecond: 80,
            first: const _Pane('List'),
            second: const _Pane('Detail'),
          ),
        ),
      ],
    ),
    kitSection(
      'Carousel',
      children: [
        // Whole slides: a peeking slide starts the row ~40 in from the
        // gutter (the page view centres its first page).
        FrostedCarouselView(
          height: 160,
          label: 'Highlights',
          children: [
            // Warm and cool by turns: two warm slides side by side (sunset,
            // lemon) still read as one pane mid-swipe (self-review round 5).
            _Pane('Morning', round: false, hue: (h) => h.sunset.a),
            _Pane('Noon', round: false, hue: (h) => h.sky.a),
            _Pane('Evening', round: false, hue: (h) => h.coral.a),
            _Pane('Night', round: false, hue: (h) => h.iris.a),
          ],
        ),
      ],
    ),
    kitSection(
      'Reorderable list',
      children: [
        KitHeld<List<String>>(
          const ['Write the brief', 'Review the plan', 'Book the room'],
          (tasks, set) => FrostedReorderableListView<String>(
            items: tasks,
            shrinkWrap: true,
            labelOf: (task) => task,
            onReorder: (from, to) {
              final next = [...tasks];
              set(next..insert(to, next.removeAt(from)));
            },
            itemBuilder: (context, task) => Text(task),
          ),
        ),
      ],
    ),
    kitSection(
      'Pull to refresh',
      children: [
        SizedBox(
          height: 200,
          child: FrostedRefreshIndicator(
            onRefresh: () => Future<void>.delayed(const Duration(seconds: 1)),
            child: ListView(
              children: [
                for (final item in _items.take(5)) FrostedListTile(title: item),
              ],
            ),
          ),
        ),
      ],
    ),
  ],
);

/// A plain pane of the glass with its name.
class _Pane extends StatelessWidget {
  const _Pane(this.name, {this.round = true, this.hue});

  final String name;

  /// Its own corners; a carousel's slide leaves them to the carousel, which
  /// rounds the frame or the peeking slide (with its own as well, a sliver
  /// of the next slide was an almond pinched at both ends).
  final bool round;

  /// A slide's own tint over the wash, so one slide is told from the next
  /// as it moves (alike, two whole slides side by side read as one still
  /// pane with its word sliding over it, self-review round 4).
  final Color Function(FrostedHues hues)? hue;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final tint = hue?.call(t.hues);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint == null
            ? t.glass.wash
            // By night a light tint lifts the slide toward its word: at the
            // day's 0.4 the word sat on a mid-tone under 4.5:1.
            : Color.alphaBlend(
                tint.withValues(alpha: t.isDark ? 0.16 : 0.4),
                t.glass.wash,
              ),
        borderRadius: round ? BorderRadius.circular(FrostedCorners.r18) : null,
      ),
      child: Center(
        child: Text(
          name,
          style: t.textTheme.labelLarge.c(
            tint == null
                ? t.colorScheme.textSecondary
                : t.colorScheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _Area extends StatefulWidget {
  const _Area();

  @override
  State<_Area> createState() => _AreaState();
}

class _AreaState extends State<_Area> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 200,
    child: FrostedScrollArea(
      controller: _scroll,
      label: 'Lists',
      child: ListView(
        controller: _scroll,
        children: [for (final item in _items) FrostedListTile(title: item)],
      ),
    ),
  );
}

/// Slides, the next peeking in.
Widget kitSpecimenCarousel() => FrostedCarouselView(
  height: 160,
  viewportFraction: .8,
  label: 'Highlights',
  children: const [
    _Pane('Morning', round: false),
    _Pane('Noon', round: false),
    _Pane('Evening', round: false),
  ],
);

/// Bills in the order they are paid, each with its grip.
Widget kitSpecimenReorderable() => FrostedReorderableListView<String>(
  items: const ['Rent', 'Phone', 'Insurance'],
  shrinkWrap: true,
  labelOf: (bill) => bill,
  onReorder: (from, to) {},
  itemBuilder: (context, bill) => Text(bill),
);
