/// The `navigation` oracle group (Compose twin: `NavigationScenes.kt`): the
/// flexible navigation bar with 3, 4 and 5 items, with badges and with
/// horizontal items; the collapsed navigation rail; primary and secondary
/// tabs, fixed and scrollable; the dot and count badges; and the motion row
/// nav selection (the indicator pill growing under a newly selected item).
///
/// The icon slots hold a blank glyph of the icon's size: the oracle app
/// bundles no Material Symbols, so its twin holds a blank 24dp box.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/badge_anchor.dart';

import '../harness/oracle.dart';

/// A glyph that draws nothing: the icon's box without its ink.
const IconData _blank = IconData(
  0x20,
  fontFamily: ExpressiveSymbolsFont.family,
);

/// The bar's item labels, in order (as `NavigationScenes.LABELS`).
const List<String> _labels = ['Home', 'Search', 'Library', 'Inbox', 'Profile'];

/// The scrollable rows' tab labels (as `NavigationScenes.MENU`).
const List<String> _menu = [
  'Breakfast',
  'Lunch',
  'Dinner',
  'Snacks',
  'Drinks',
  'Desserts',
  'Sides',
  'Specials',
];

/// Frames recorded for the selection row (0.96 s).
const int _frames = 60;

void _select(int _) {}

List<ExpressiveNavItem> _items(int count, {bool badges = false}) => [
  for (var i = 0; i < count; i++)
    ExpressiveNavItem(
      _blank,
      _labels[i],
      badge: !badges
          ? null
          : i == 1
          ? ExpressiveBadge.count(3)
          : i == 3
          ? const ExpressiveBadge()
          : null,
    ),
];

Widget _bar(
  int count, {
  bool badges = false,
  int selected = 0,
  ExpressiveNavItemPosition position = ExpressiveNavItemPosition.top,
  ExpressiveNavigationBarArrangement arrangement =
      ExpressiveNavigationBarArrangement.equalWeight,
}) => OracleTag(
  'bar',
  child: ExpressiveNavigationBar(
    destinations: _items(count, badges: badges),
    selectedIndex: selected,
    onDestinationSelected: _select,
    itemPosition: position,
    arrangement: arrangement,
  ),
);

Widget _tabs(
  List<ExpressiveTab> tabs,
  ExpressiveTabBarVariant variant, {
  bool scrollable = false,
}) => SizedBox(
  width: 360,
  child: OracleTag(
    'tabs',
    child: ExpressiveTabBar(
      tabs: tabs,
      selectedIndex: 0,
      onChanged: _select,
      variant: variant,
      scrollable: scrollable,
    ),
  ),
);

List<ExpressiveTab> _fixed({bool icons = false}) => [
  for (final label in const ['Flights', 'Trips', 'Explore'])
    ExpressiveTab(label: label, icon: icons ? _blank : null),
];

List<ExpressiveTab> _scrolling() => [
  for (final label in _menu) ExpressiveTab(label: label),
];

Widget _badges() => Row(
  mainAxisSize: MainAxisSize.min,
  // Compose's Row aligns its children to the top.
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: ExpressiveSpacing.s24,
  children: [
    ExpressiveBadgeAnchor(
      badge: const OracleTag('badge-dot', child: ExpressiveBadge()),
      child: const SizedBox.square(dimension: 24),
    ),
    ExpressiveBadgeAnchor(
      badge: OracleTag('badge-count', child: ExpressiveBadge.count(3)),
      child: const SizedBox.square(dimension: 24),
    ),
    OracleTag('badge-max', child: ExpressiveBadge.count(1204)),
  ],
);

/// A 4-item bar whose selection moves from the first item to the second
/// after the first frame (the oracle's LaunchedEffect).
class _Selecting extends StatefulWidget {
  const _Selecting();

  @override
  State<_Selecting> createState() => _SelectingState();
}

class _SelectingState extends State<_Selecting> {
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    // The oracle's LaunchedEffect sets the selection after the first frame;
    // Compose recomposes in the second, where animateFloatAsState launches
    // its animation, whose clock starts on the third. Selecting after the
    // second frame starts the spring on the same frame here (one frame
    // earlier, every motion frame was one step ahead of the oracle's).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selected = 1);
      });
      WidgetsBinding.instance.scheduleFrame();
    });
  }

  @override
  Widget build(BuildContext context) => _bar(4, selected: _selected);
}

final OracleGroup navigationScenes = OracleGroup(
  id: 'navigation',
  scenes: [
    for (final count in const [3, 4, 5])
      OracleScene(
        key: 'navigation/bar/$count',
        size: const Size(408, 80),
        build: (context) => _bar(count),
      ),
    OracleScene(
      key: 'navigation/bar/badge',
      size: const Size(408, 80),
      build: (context) => _bar(4, badges: true),
    ),
    OracleScene(
      key: 'navigation/bar/horizontal',
      size: const Size(408, 80),
      build: (context) => _bar(
        3,
        position: ExpressiveNavItemPosition.start,
        arrangement: ExpressiveNavigationBarArrangement.centered,
      ),
    ),
    OracleScene(
      key: 'navigation/rail',
      size: const Size(112, 360),
      build: (context) => SizedBox(
        height: 336,
        child: OracleTag(
          'rail',
          child: ExpressiveNavigationRail(
            destinations: _items(4),
            selectedIndex: 0,
            onDestinationSelected: _select,
          ),
        ),
      ),
    ),
    OracleScene(
      key: 'navigation/tabs/primary',
      size: const Size(360, 64),
      build: (context) => _tabs(_fixed(), ExpressiveTabBarVariant.primary),
    ),
    OracleScene(
      key: 'navigation/tabs/secondary',
      size: const Size(360, 64),
      build: (context) => _tabs(_fixed(), ExpressiveTabBarVariant.secondary),
    ),
    OracleScene(
      key: 'navigation/tabs/primary-icon',
      size: const Size(360, 88),
      build: (context) =>
          _tabs(_fixed(icons: true), ExpressiveTabBarVariant.primary),
    ),
    OracleScene(
      key: 'navigation/tabs/primary-scrollable',
      size: const Size(360, 64),
      build: (context) => _tabs(
        _scrolling(),
        ExpressiveTabBarVariant.primary,
        scrollable: true,
      ),
    ),
    OracleScene(
      key: 'navigation/tabs/secondary-scrollable',
      size: const Size(360, 64),
      build: (context) => _tabs(
        _scrolling(),
        ExpressiveTabBarVariant.secondary,
        scrollable: true,
      ),
    ),
    OracleScene(
      key: 'navigation/badges',
      size: const Size(160, 48),
      build: (context) => _badges(),
    ),
    OracleScene(
      key: 'navigation/bar/selection',
      size: const Size(408, 80),
      // The indicator is Compose-internal (no test tag): the frames' crops
      // carry the pill; the bar's bounds anchor the recording.
      motion: const OracleMotion(tags: ['bar'], frames: _frames, images: true),
      build: (context) => const _Selecting(),
    ),
  ],
);

void main() => runOracleGroup(navigationScenes);
