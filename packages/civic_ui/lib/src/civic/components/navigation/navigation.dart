import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../internal/frame_scope.dart';
import '../../internal/places.dart';
import '../../theme.dart';

/// One place a [CivicNavigationBar] or a [CivicSideNavigation] goes.
@immutable
class CivicNavigationDestination {
  /// A destination called [label].
  const CivicNavigationDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.key,
  });

  /// Its glyph, in the [CivicNavigationBar] (the side navigation is words
  /// alone).
  final IconData icon;

  /// Its glyph while it is the current place; null keeps [icon].
  final IconData? selectedIcon;

  /// Its name, always shown.
  final String label;

  /// The key its control carries, so a test can find it and press it.
  final Key? key;
}

/// The places of a service in an app, along the bottom under a hairline:
/// each a glyph over its name (always shown: a glyph alone says too
/// little), the current one in bold ink under a bar in the action colour,
/// the rest in the secondary ink. A [CivicScaffold] from
/// [CivicLayout.medium] wide (a tablet) stands the same places down the
/// start as a rail, on the card's face beside a hairline, the current
/// one's bar at its start. On the site (from [CivicLayout.expanded] wide) a
/// page stands a [CivicSideNavigation] instead.
///
/// Reads [CivicStyle]'s fill (the band's ground), foreground (a place's
/// glyph and name, by its states: selected for the current one), edge (the
/// current place's bar) and textStyle (the names): its `style:`, then
/// [CivicThemeData.navigationStyle]. The names always show, and the focus
/// plate is the look's.
///
/// ```dart
/// CivicNavigationBar(
///   selectedIndex: index,
///   onDestinationSelected: (i) => setState(() => index = i),
///   destinations: const [
///     CivicNavigationDestination(icon: LucideIcons.house, label: 'Home'),
///     CivicNavigationDestination(icon: LucideIcons.fileText, label: 'Applications'),
///   ],
/// )
/// ```
class CivicNavigationBar extends StatelessWidget {
  /// The bottom navigation.
  const CivicNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.style,
  });

  /// The places.
  final List<CivicNavigationDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with a place's index when it is pressed.
  final ValueChanged<int>? onDestinationSelected;

  /// Overrides for these places' look.
  final CivicStyle? style;

  /// The bar's height, the safe area aside.
  static const double height = CivicChromeMetrics.navigationBar;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final styles = [style, t.navigationStyle];
    final rail = CivicRailScope.of(context);
    final labels = [for (final d in destinations) d.label];
    final places = [
      for (final (i, d) in destinations.indexed)
        DesignPressable(
          key: d.key,
          onPressed: onDestinationSelected == null
              ? null
              : () => onDestinationSelected!(i),
          tab: true,
          button: false,
          semanticSelected: i == selectedIndex,
          semanticLabel: d.label,
          excludeSemantics: true,
          mouseCursor: SystemMouseCursors.click,
          builder: (context, states, _) => CivicBarPlace(
            styles: styles,
            icon: d.icon,
            selectedIcon: d.selectedIcon,
            label: d.label,
            states: states,
            selected: i == selectedIndex,
            rail: rail,
          ),
        ),
    ];
    return rail
        ? CivicPlacesRail(
            styles: styles,
            labels: labels,
            lead: CivicRailScope.leadingOf(context),
            places: places,
          )
        : CivicPlacesBand(styles: styles, labels: labels, places: places);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('destinations', destinations.length))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

/// The places of a service's site, down the start of the page on its
/// ground: each a row of words in ink, the current one bold on a white face
/// (by night, slate) with the inset rule in the action colour at its start;
/// a pointer over a place lays a paler face under it. Words alone: beside
/// a name this size a place's glyph would only decorate (the bar along a
/// phone's foot keeps them, over its small names). A [header] and a
/// [footer] may stand above and below the places.
///
/// Reads [CivicStyle]'s fill (the band's ground), foreground (a place's
/// name, by its states: selected for the current one), edge (the
/// current place's rule) and textStyle (the names): its `style:`, then
/// [CivicThemeData.navigationStyle]. The names always show, and the focus
/// plate is the look's.
///
/// ```dart
/// CivicSideNavigation(
///   selectedIndex: index,
///   onDestinationSelected: (i) => setState(() => index = i),
///   destinations: destinations,
/// )
/// ```
class CivicSideNavigation extends StatelessWidget {
  /// The side navigation.
  const CivicSideNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.header,
    this.footer,
    this.style,
  });

  /// The places.
  final List<CivicNavigationDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with a place's index when it is pressed.
  final ValueChanged<int>? onDestinationSelected;

  /// Overrides for these places' look.
  final CivicStyle? style;

  /// What stands above the places.
  final Widget? header;

  /// What stands below them.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final styles = [style, t.navigationStyle];
    return CivicPlacesSide(
      styles: styles,
      header: header,
      footer: footer,
      places: [
        for (final (i, d) in destinations.indexed)
          DesignPressable(
            key: d.key,
            onPressed: onDestinationSelected == null
                ? null
                : () => onDestinationSelected!(i),
            link: true,
            button: false,
            semanticSelected: i == selectedIndex,
            semanticLabel: d.label,
            excludeSemantics: true,
            mouseCursor: SystemMouseCursors.click,
            builder: (context, states, _) => CivicSidePlace(
              styles: styles,
              label: d.label,
              states: states,
              selected: i == selectedIndex,
            ),
          ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('destinations', destinations.length))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
