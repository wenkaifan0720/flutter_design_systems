/// The `app-bars` oracle group (Compose twin: `AppBarsScenes.kt`): four app
/// bars — small, small centred with a subtitle, medium flexible and large
/// flexible with a subtitle — at scroll 0, half and collapsed; the search
/// app bar at rest and scrolled; the search view's expanded header (its
/// field, divider and filter chips); and the motion row app-bar collapse
/// (a large flexible bar settling from half open to collapsed on the snap
/// spring).
///
/// Scroll is given as Compose's `TopAppBarState`: a small bar's content
/// offset (half: 32dp under a 64dp bar; collapsed: 64dp), a flexible bar's
/// height offset (half and the whole of its collapse range). The icon slots
/// hold a blank glyph of the icon's size: the oracle app bundles no
/// Material Symbols, so its twin holds a blank 24dp box.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';

import '../harness/oracle.dart';

/// A glyph that draws nothing: the icon's box without its ink.
const IconData _blank = IconData(
  0x20,
  fontFamily: ExpressiveSymbolsFont.family,
);

/// Frames recorded for the collapse row (0.96 s).
const int _frames = 60;

/// Scroll 0, half and collapsed.
enum _At { rest, half, collapsed }

/// The medium bar's collapse range: 112 - 64.
const double _mediumRange = 48;

/// The large bar's (with a subtitle) collapse range: 152 - 64.
const double _largeRange = 88;

void _noop() {}

const Widget _nav = ExpressiveIconButton(
  _blank,
  onPressed: _noop,
  semanticLabel: 'Menu',
);

List<Widget> _actions(int count) => <Widget>[
  for (var i = 0; i < count; i++)
    ExpressiveAppBarAction(_blank, label: 'Action $i', onPressed: _noop),
];

ExpressiveAppBarScroll _pinned(_At at) => ExpressiveAppBarScroll(
  contentOffset: switch (at) {
    _At.rest => 0,
    _At.half => -32,
    _At.collapsed => -64,
  },
);

ExpressiveAppBarScroll _flexible(_At at, double range) =>
    ExpressiveAppBarScroll(
      heightOffset: _onDevicePixels(switch (at) {
        _At.rest => 0,
        _At.half => -range / 2,
        _At.collapsed => -range,
      }, range),
    );

/// A flexible bar's height offset as Compose lays it out: the bar's height
/// in whole device pixels (`roundToInt`, half up), so a half-open large bar
/// is 284px (108.19dp) where Flutter would lay out 108dp, and a settling
/// bar snaps to its collapsed row once within half a pixel of it instead
/// of creeping the last fraction. The scene's rounding only; the
/// component keeps Flutter's fractional layout. [range] is the bar's
/// collapse range, above its 64dp row.
double _onDevicePixels(double heightOffset, double range) {
  final expanded = (64 + range) * oracleDensity;
  final px = (expanded + heightOffset * oracleDensity + 0.5).floorToDouble();
  return math.min(0, (px - expanded) / oracleDensity);
}

Widget _small(_At at) => OracleTag(
  'bar',
  child: ExpressiveAppBar(
    title: 'Inbox',
    leading: _nav,
    actions: _actions(2),
    scroll: _pinned(at),
  ),
);

Widget _centered(_At at) => OracleTag(
  'bar',
  child: ExpressiveAppBar(
    title: 'Photos',
    subtitle: '1,204 items',
    centered: true,
    leading: _nav,
    actions: _actions(1),
    scroll: _pinned(at),
  ),
);

Widget _medium(_At at) => OracleTag(
  'bar',
  child: ExpressiveAppBar(
    title: 'Journal',
    size: ExpressiveAppBarSize.medium,
    leading: _nav,
    actions: _actions(1),
    scroll: _flexible(at, _mediumRange),
  ),
);

Widget _large(ExpressiveAppBarScroll scroll) => OracleTag(
  'bar',
  child: ExpressiveAppBar(
    title: 'Journal',
    subtitle: 'May · 8 entries',
    size: ExpressiveAppBarSize.large,
    leading: _nav,
    actions: _actions(2),
    scroll: scroll,
  ),
);

Widget _search({required bool scrolled}) => OracleTag(
  'bar',
  child: ExpressiveAppBar.search(
    leading: _nav,
    actions: _actions(1),
    scroll: ExpressiveAppBarScroll(contentOffset: scrolled ? -32 : 0),
    search: const ExpressiveSearchBar(leading: Icon(_blank)),
  ),
);

/// The search view's expanded header: the field on the view's surface,
/// the divider and the filter chips row.
Widget _searchView(BuildContext context) {
  final t = context.expressiveTheme;
  return ColoredBox(
    color: t.colors.surfaceContainerHigh,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const OracleTag(
          'field',
          child: ExpressiveSearchField(leading: Icon(_blank)),
        ),
        SizedBox(height: 1, child: ColoredBox(color: t.colors.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ExpressiveChromeMetrics.margin,
          ),
          child: Row(
            spacing: ExpressiveSpacing.s8,
            children: <Widget>[
              for (final (i, label) in const <String>[
                'Open now',
                'Nearby',
                'Top rated',
              ].indexed)
                ExpressiveChip.filter(
                  label,
                  selected: i == 0,
                  onPressed: () {},
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// A large flexible bar, half open, settling to collapsed on the snap
/// spring (Compose's settleAppBar), started after the first frame (the
/// oracle's LaunchedEffect).
class _Collapsing extends StatefulWidget {
  const _Collapsing();

  @override
  State<_Collapsing> createState() => _CollapsingState();
}

class _CollapsingState extends State<_Collapsing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _offset = AnimationController.unbounded(
    vsync: this,
    value: -_largeRange / 2,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _offset.animateWith(
        designSpringSimulation(
          ExpressiveMotion.of(context).spring(AppBarBehavior.topSnapMotion),
          from: _offset.value,
          to: -_largeRange,
        ),
      );
    });
  }

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _offset,
    builder: (context, _) => _large(
      ExpressiveAppBarScroll(
        heightOffset: _onDevicePixels(_offset.value, _largeRange),
      ),
    ),
  );
}

final OracleGroup appBarsScenes = OracleGroup(
  id: 'app-bars',
  // What the search field needs above it: the host's thin Material theme,
  // the localizations and an overlay (as the text-fields group's frame).
  frame: (context, scene) {
    final theme = context.expressiveTheme;
    return Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<Object>>[
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: ExpressiveHost(
        light: theme,
        dark: theme,
        brightness: theme.brightness,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(builder: (context) => scene),
          ],
        ),
      ),
    );
  },
  scenes: [
    for (final at in _At.values) ...[
      OracleScene(
        key: 'app-bars/small/${at.name}',
        size: const Size(408, 64),
        build: (context) => _small(at),
      ),
      OracleScene(
        key: 'app-bars/centered/${at.name}',
        size: const Size(408, 64),
        build: (context) => _centered(at),
      ),
      OracleScene(
        key: 'app-bars/medium/${at.name}',
        size: const Size(408, 112),
        build: (context) => _medium(at),
      ),
      OracleScene(
        key: 'app-bars/large/${at.name}',
        size: const Size(408, 152),
        build: (context) => _large(_flexible(at, _largeRange)),
      ),
    ],
    OracleScene(
      key: 'app-bars/search/rest',
      size: const Size(408, 64),
      build: (context) => _search(scrolled: false),
    ),
    OracleScene(
      key: 'app-bars/search/scrolled',
      size: const Size(408, 64),
      build: (context) => _search(scrolled: true),
    ),
    OracleScene(
      key: 'app-bars/search-view',
      size: const Size(408, 112),
      build: _searchView,
    ),
    OracleScene(
      key: 'app-bars/collapse',
      size: const Size(408, 152),
      motion: const OracleMotion(tags: ['bar'], frames: _frames, images: true),
      build: (context) => const _Collapsing(),
    ),
  ],
);

void main() => runOracleGroup(appBarsScenes);
