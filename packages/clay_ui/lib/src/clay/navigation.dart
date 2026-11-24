/// Clay's way round an app: a top bar on the ground, a floating dock of
/// places on a phone, a rail on a tablet, a sidebar on a desk, the scaffold
/// that picks between them, and tabs.
///
/// One rule for a chosen place: on the ground it rises as a white clay
/// volume (a rail's, a sidebar's, a tab's); on a slab of clay (the dock) it
/// takes the clay warmed toward the accent.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'fonts.dart';
import 'surface.dart';
import 'theme.dart';

/// A Clay top bar, on the ground: a back ball at its start, the place's
/// [title], its [actions] at the end. [large] sets the title big under the
/// bar on a phone and a tablet; on a desk it stays on the bar's line.
///
/// ```dart
/// ClayTopBar(title: 'Habits', onBack: () {})
/// ```
class ClayTopBar extends StatelessWidget {
  /// A bar titled [title].
  const ClayTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.leading,
    this.actions = const [],
    this.large = false,
    this.bottom,
    this.style,
  });

  /// The way back from a pushed page, by the route it is on: a back ball,
  /// a close ball on a sheet, nothing at a root.
  ///
  /// ```dart
  /// ClayTopBar(title: 'Edit habit', leading: ClayTopBar.autoLeading(context))
  /// ```
  static Widget? autoLeading(BuildContext context, {Key? key}) {
    final presentation = RoutePresentation.of(context);
    if (presentation == RoutePresentation.root) return null;
    final close = presentation == RoutePresentation.sheet;
    final words = RawWidgetsLocalizations.of(context);
    return _way(
      context,
      key: key,
      onPressed: () => Navigator.of(context).maybePop(),
      tooltip: close ? words.closeButtonLabel : words.backButtonTooltip,
      close: close,
    );
  }

  static Widget _way(
    BuildContext context, {
    Key? key,
    required VoidCallback? onPressed,
    required String tooltip,
    bool close = false,
  }) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return ClayIconButton(
      key: key,
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(
        close
            ? LucideIcons.x
            : rtl
            ? LucideIcons.chevronRight
            : LucideIcons.chevronLeft,
        size: 20,
      ),
    );
  }

  /// The place's name.
  final String title;

  /// Called by the back ball; null shows none (unless [leading] is set).
  final VoidCallback? onBack;

  /// What stands at the bar's start instead of the back ball.
  final Widget? leading;

  /// Keys at the bar's end (Clay icon buttons).
  final List<Widget> actions;

  /// Whether the title stands big under the bar (a place's root page).
  final bool large;

  /// Something under the bar: a search field, tabs.
  final Widget? bottom;

  /// This bar's own style, over [ClayThemeData.topBarStyle]: `fill` its
  /// ground, `foreground` its title.
  final ClayStyle? style;

  /// The bar's height, under the status bar.
  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.topBarStyle], const {});
    final top = MediaQuery.paddingOf(context).top;
    final width = MediaQuery.sizeOf(context).width;
    final margin = ClaySpacing.pageMargin(width);
    final large = this.large && width < ClayMetrics.sidebarBreakpoint;
    final ink = layered.foreground ?? c.ink;
    final lead =
        leading ??
        (onBack == null
            ? null
            : _way(
                context,
                onPressed: onBack,
                tooltip: RawWidgetsLocalizations.of(context).backButtonTooltip,
              ));
    final row = SizedBox(
      height: height,
      child: Row(
        children: [
          if (lead != null)
            Padding(
              padding: EdgeInsetsDirectional.only(start: margin),
              child: lead,
            ),
          Expanded(
            child: large
                ? const SizedBox.shrink()
                : Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: lead == null ? margin : ClaySpacing.medium,
                      end: ClaySpacing.small,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Semantics(
                        header: true,
                        child: RawCapCenter(
                          capHeightFactor: clayCapHeightFactor,
                          child: Text(
                            title,
                            textScaler: MediaQuery.textScalerOf(context)
                                .clamp(maxScaleFactor: 1.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.title
                                .copyWith(color: ink)
                                .merge(layered.textStyle),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          for (final (i, action) in actions.indexed) ...[
            if (i > 0) const SizedBox(width: ClaySpacing.small),
            action,
          ],
          SizedBox(width: actions.isEmpty ? 0 : margin),
        ],
      ),
    );
    return ColoredBox(
      color: layered.fill ?? c.ground,
      child: Padding(
        padding: EdgeInsets.only(top: top),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row,
            if (large)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: margin,
                  end: margin,
                  bottom: ClaySpacing.medium,
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.display.copyWith(color: ink),
                  ),
                ),
              ),
            if (bottom != null)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: margin,
                  end: margin,
                  bottom: ClaySpacing.medium,
                ),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(FlagProperty('large', value: large, ifTrue: 'large'))
      ..add(FlagProperty('back', value: onBack != null, ifTrue: 'back'));
  }
}

/// One place of an app, for a [ClayNavigationBar], a [ClayNavigationRail],
/// a [ClaySidebar] or a [ClayScaffold].
@immutable
class ClayDestination {
  /// A place reading [label], marked by [icon].
  const ClayDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.key,
  });

  /// A key for the place's control (a test finds it by it).
  final Key? key;

  /// Its glyph.
  final IconData icon;

  /// Its glyph while it is the current place.
  final IconData? selectedIcon;

  /// Its name.
  final String label;
}

// A place's control: one press target.
class _Place extends StatelessWidget {
  const _Place({
    required this.destination,
    required this.chosen,
    required this.onPressed,
    required this.face,
  });

  final ClayDestination destination;
  final bool chosen;
  final VoidCallback onPressed;
  final Widget Function(Set<WidgetState> states) face;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: destination.key,
    child: RawButton(
      onPressed: onPressed,
      selected: chosen,
      semanticSelected: chosen,
      semanticLabel: destination.label,
      excludeSemantics: true,
      builder: (context, states, _) => face(states),
    ),
  );
}

// A dock place: glyph over name; the chosen one on a warm raised pill.
class _DockFace extends StatelessWidget {
  const _DockFace({
    required this.destination,
    required this.states,
    required this.style,
  });

  final ClayDestination destination;
  final Set<WidgetState> states;
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final chosen = states.contains(WidgetState.selected);
    final layered = RawStyleOf([style, theme.navigationBarStyle], states);
    final ink = chosen ? (layered.foreground ?? c.ink) : c.inkSecondary;
    final weight = chosen ? FontWeight.w600 : FontWeight.w500;
    final pill = layered.fill ?? clayChosenFill(c);
    return TapTargetPadding(
      child: Padding(
        padding: const EdgeInsets.all(ClaySpacing.tight),
        child: AnimatedClaySurface(
          face:
              (chosen
                      ? ClayFace.raised(c, color: pill, radius: 22)
                      : ClayFace.raised(
                          c,
                          color: c.clay.withValues(alpha: 0),
                          radius: 22,
                        ).copyWith(
                          elevation: 0,
                          shadowOpacity: 0,
                          lightOpacity: 0,
                          shadeOpacity: 0,
                        ))
                  .copyWith(
                    press: states.contains(WidgetState.pressed) ? 1 : 0,
                    focus: states.contains(WidgetState.focused) ? 1 : 0,
                  ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                chosen
                    ? destination.selectedIcon ?? destination.icon
                    : destination.icon,
                size: 22,
                color: ink,
              ),
              const SizedBox(height: ClaySpacing.hairline),
              // A name too wide for its place (large text) shrinks to fit
              // whole, rather than lose its end to an ellipsis.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  destination.label,
                  maxLines: 1,
                  style: theme.textTheme.caption.copyWith(
                    color: ink,
                    fontWeight: weight,
                    fontVariations: clayWeight(weight),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A rail place: a pill round the glyph, the name under it; the chosen pill
// rises as white clay out of the ground.
class _RailFace extends StatelessWidget {
  const _RailFace({
    required this.destination,
    required this.states,
    required this.style,
  });

  final ClayDestination destination;
  final Set<WidgetState> states;
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final chosen = states.contains(WidgetState.selected);
    final layered = RawStyleOf([style, theme.navigationRailStyle], states);
    final ink = chosen ? (layered.foreground ?? c.ink) : c.inkSecondary;
    final weight = chosen ? FontWeight.w600 : FontWeight.w500;
    final hovered = states.contains(WidgetState.hovered);
    final rest = ClayFace.well(c, radius: 18).copyWith(
      color: c.well.withValues(alpha: hovered ? 0.6 : 0),
      lightOpacity: 0,
      shadeOpacity: 0,
    );
    final face =
        (chosen
                ? ClayFace.raised(c, color: layered.fill ?? c.risen, radius: 18)
                : states.contains(WidgetState.pressed)
                ? ClayFace.well(c, radius: 18)
                : rest)
            .copyWith(
              press: chosen && states.contains(WidgetState.pressed) ? 1 : 0,
              focus: states.contains(WidgetState.focused) ? 1 : 0,
            );
    return TapTargetPadding(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 36,
            child: AnimatedClaySurface(
              face: face,
              child: Center(
                child: Icon(
                  chosen
                      ? destination.selectedIcon ?? destination.icon
                      : destination.icon,
                  size: 22,
                  color: ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: ClaySpacing.tight),
          Text(
            destination.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.caption.copyWith(
              color: ink,
              fontWeight: weight,
              fontVariations: clayWeight(weight),
            ),
          ),
        ],
      ),
    );
  }
}

// A sidebar place: a row, glyph and name; the chosen row rises as white
// clay out of the ground.
class _SideFace extends StatelessWidget {
  const _SideFace({
    required this.destination,
    required this.states,
    required this.style,
  });

  final ClayDestination destination;
  final Set<WidgetState> states;
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final chosen = states.contains(WidgetState.selected);
    final layered = RawStyleOf([style, theme.sidebarStyle], states);
    final ink = chosen ? (layered.foreground ?? c.ink) : c.inkSecondary;
    final weight = chosen ? FontWeight.w600 : FontWeight.w500;
    final hovered = states.contains(WidgetState.hovered);
    final rest = ClayFace.well(c, radius: ClayRadius.control).copyWith(
      color: c.well.withValues(alpha: hovered ? 0.6 : 0),
      lightOpacity: 0,
      shadeOpacity: 0,
    );
    final face =
        (chosen
                ? ClayFace.raised(
                    c,
                    color: layered.fill ?? c.risen,
                    radius: ClayRadius.control,
                  )
                : states.contains(WidgetState.pressed)
                ? ClayFace.well(c, radius: ClayRadius.control)
                : rest)
            .copyWith(
              press: chosen && states.contains(WidgetState.pressed) ? 1 : 0,
              focus: states.contains(WidgetState.focused) ? 1 : 0,
            );
    return TapTargetPadding(
      child: SizedBox(
        height: theme.density.height(44),
        child: AnimatedClaySurface(
          face: face,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ClaySpacing.medium),
            child: Row(
              children: [
                Icon(
                  chosen
                      ? destination.selectedIcon ?? destination.icon
                      : destination.icon,
                  size: 20,
                  color: chosen ? c.accentInk : ink,
                ),
                const SizedBox(width: ClaySpacing.medium),
                Expanded(
                  child: RawCapCenter(
                    capHeightFactor: clayCapHeightFactor,
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.label.copyWith(
                        fontSize: 15,
                        color: ink,
                        fontWeight: weight,
                        fontVariations: clayWeight(weight),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _ignore(int _) {}

Widget _clamped(Widget child) =>
    MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: child);

/// A phone's places: a floating dock of white clay at the foot of the
/// screen, glyph over name in each place, the current one on a warm raised
/// pill; an [action] (the screen's one key, a coral ball) at its end.
///
/// ```dart
/// ClayNavigationBar(destinations: const [ClayDestination(icon: LucideIcons.sun, label: 'Today'), ClayDestination(icon: LucideIcons.listChecks, label: 'Habits')], selectedIndex: 0, onDestinationSelected: (index) {})
/// ```
class ClayNavigationBar extends StatelessWidget {
  /// A dock of [destinations], [selectedIndex] current.
  const ClayNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.action,
    this.style,
  });

  /// The places.
  final List<ClayDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onDestinationSelected;

  /// A key at the dock's end.
  final Widget? action;

  /// The dock's own style, over [ClayThemeData.navigationBarStyle]: `fill`
  /// the current place's pill, `foreground` its words.
  final ClayStyle? style;

  /// The dock's height.
  static const double height = 68;

  @override
  Widget build(BuildContext context) {
    final c = ClayTheme.of(context).colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final width = MediaQuery.sizeOf(context).width;
    final margin = ClaySpacing.pageMargin(width) - 4;
    return _clamped(
      ColoredBox(
        color: c.ground,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            margin,
            ClaySpacing.small,
            margin,
            math.max(bottom, ClaySpacing.medium),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: height,
                  child: ClaySurface(
                    face: ClayFace.raised(c, radius: 26),
                    child: Padding(
                      padding: const EdgeInsets.all(ClaySpacing.tight),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, d) in destinations.indexed)
                            Expanded(
                              child: _Place(
                                destination: d,
                                chosen: i == selectedIndex,
                                onPressed: () => onDestinationSelected(i),
                                face: (states) => _DockFace(
                                  destination: d,
                                  states: states,
                                  style: style,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: ClaySpacing.regular),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        IterableProperty<String>(
          'destinations',
          destinations.map((d) => d.label),
        ),
      )
      ..add(IntProperty('selectedIndex', selectedIndex));
  }
}

/// A tablet's places: a column on the ground at the start of the screen,
/// glyph over name, the current glyph's pill risen as white clay.
///
/// ```dart
/// ClayNavigationRail(destinations: const [ClayDestination(icon: LucideIcons.sun, label: 'Today'), ClayDestination(icon: LucideIcons.listChecks, label: 'Habits')], selectedIndex: 0, onDestinationSelected: (index) {})
/// ```
class ClayNavigationRail extends StatelessWidget {
  /// A rail of [destinations], [selectedIndex] current.
  const ClayNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.leading,
    this.style,
  }) : _places = null;

  const ClayNavigationRail._shell(
    this._places, {
    required this.selectedIndex,
    this.leading,
  }) : destinations = const [],
       onDestinationSelected = _ignore,
       style = null;

  final List<Widget>? _places;

  /// The places.
  final List<ClayDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onDestinationSelected;

  /// What stands above the places: the app's mark, its one key.
  final Widget? leading;

  /// The rail's own style, over [ClayThemeData.navigationRailStyle].
  final ClayStyle? style;

  /// The rail's width.
  static const double width = ClayMetrics.railWidth;

  @override
  Widget build(BuildContext context) {
    final c = ClayTheme.of(context).colors;
    final top = MediaQuery.paddingOf(context).top;
    final places =
        _places ??
        [
          for (final (i, d) in destinations.indexed)
            _Place(
              destination: d,
              chosen: i == selectedIndex,
              onPressed: () => onDestinationSelected(i),
              face: (states) =>
                  _RailFace(destination: d, states: states, style: style),
            ),
        ];
    return _clamped(
      ColoredBox(
        color: c.ground,
        child: SizedBox(
          width: width,
          child: Padding(
            padding: EdgeInsets.only(top: top + ClaySpacing.regular),
            child: Column(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(height: ClaySpacing.large),
                ],
                for (final place in places) SizedBox(height: 76, child: place),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        IterableProperty<String>(
          'destinations',
          destinations.map((d) => d.label),
        ),
      )
      ..add(IntProperty('selectedIndex', selectedIndex));
  }
}

/// A desk's places: a quiet column on the ground, a row per place, the
/// current row risen as white clay; a [header] (the app's mark, its one key)
/// above and a [footer] under.
///
/// ```dart
/// ClaySidebar(destinations: const [ClayDestination(icon: LucideIcons.sun, label: 'Today'), ClayDestination(icon: LucideIcons.listChecks, label: 'Habits')], selectedIndex: 0, onDestinationSelected: (index) {})
/// ```
class ClaySidebar extends StatelessWidget {
  /// A sidebar of [destinations], [selectedIndex] current.
  const ClaySidebar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.header,
    this.footer,
    this.style,
  }) : _places = null;

  const ClaySidebar._shell(
    this._places, {
    required this.selectedIndex,
    this.header,
    this.footer,
  }) : destinations = const [],
       onDestinationSelected = _ignore,
       style = null;

  final List<Widget>? _places;

  /// The places.
  final List<ClayDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onDestinationSelected;

  /// What stands above the places.
  final Widget? header;

  /// What stands at the foot.
  final Widget? footer;

  /// The sidebar's own style, over [ClayThemeData.sidebarStyle].
  final ClayStyle? style;

  /// The sidebar's width.
  static const double width = ClayMetrics.sidebarWidth;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final top = MediaQuery.paddingOf(context).top;
    final places =
        _places ??
        [
          for (final (i, d) in destinations.indexed)
            _Place(
              destination: d,
              chosen: i == selectedIndex,
              onPressed: () => onDestinationSelected(i),
              face: (states) =>
                  _SideFace(destination: d, states: states, style: style),
            ),
        ];
    return ColoredBox(
      color: c.ground,
      child: SizedBox(
        width: width,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            ClaySpacing.regular,
            top + ClaySpacing.roomy,
            ClaySpacing.regular,
            ClaySpacing.regular,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: ClaySpacing.medium,
                    bottom: ClaySpacing.large,
                  ),
                  child: DefaultTextStyle(
                    style: theme.textTheme.title.copyWith(color: c.ink),
                    child: header!,
                  ),
                ),
              for (final place in places)
                Padding(
                  padding: const EdgeInsets.only(bottom: ClaySpacing.tight),
                  child: place,
                ),
              const Spacer(),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        IterableProperty<String>(
          'destinations',
          destinations.map((d) => d.label),
        ),
      )
      ..add(IntProperty('selectedIndex', selectedIndex));
  }
}

/// A Clay app's frame: the [topBar] over the [body], and the places as a
/// floating dock on a phone (under 600 px), a rail on a tablet, a sidebar on
/// a desk (from 1024 px). Built on ui_core's adaptive shell: the arrows move
/// through the places, a screen reader hears a navigation region.
///
/// ```dart
/// ClayScaffold(topBar: const ClayTopBar(title: 'Today'), destinations: const [ClayDestination(icon: LucideIcons.sun, label: 'Today'), ClayDestination(icon: LucideIcons.listChecks, label: 'Habits')], selectedIndex: 0, onDestinationSelected: (index) {}, body: const SizedBox.expand())
/// ```
class ClayScaffold extends StatelessWidget {
  /// A frame round [body].
  const ClayScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.destinations = const [],
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.brand,
    this.action,
    this.sideFooter,
    this.showNavigation = true,
    this.style,
  });

  /// The page.
  final Widget body;

  /// The bar over it.
  final Widget? topBar;

  /// The app's places; none: a page with no places (a pushed page).
  final List<ClayDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int>? onDestinationSelected;

  /// The app's mark atop a rail or a sidebar.
  final Widget? brand;

  /// The screen's one key: at the dock's end on a phone, under the brand on
  /// a rail or a sidebar.
  final Widget? action;

  /// What stands at the sidebar's foot.
  final Widget? sideFooter;

  /// Whether the places show (a phone page can hide its dock).
  final bool showNavigation;

  /// Its own style, over [ClayThemeData.scaffoldStyle]: `fill` the ground
  /// the page and its navigation stand on.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final ground =
        RawStyleOf([style, theme.scaffoldStyle], const {}).fill ??
        theme.colors.ground;
    final width = MediaQuery.sizeOf(context).width;
    final places = destinations.isNotEmpty && onDestinationSelected != null;
    final phone = width < ClayMetrics.railBreakpoint;
    final bar = places && phone && showNavigation;
    final page = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?topBar,
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: topBar != null,
            removeBottom: bar,
            // The body keeps its children's nodes apart. A Navigator here
            // would otherwise hang its route's node off this one, and a list
            // opening over the route gives the route a node between them:
            // on the web the focused field's input moves into it and the
            // browser blurs it, so the tap that opened the list loses focus.
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              child: body,
            ),
          ),
        ),
      ],
    );
    if (!places || phone) {
      return ColoredBox(
        color: ground,
        child: !bar
            ? page
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(child: page),
                        // The page fades into the ground above the dock,
                        // rather than stopping at a line.
                        PositionedDirectional(
                          start: 0,
                          end: 0,
                          bottom: 0,
                          height: ClaySpacing.large,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [ground.withValues(alpha: 0), ground],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Toasts stand above the dock.
                  RawToasterKeepClear(
                    child: ClayNavigationBar(
                      destinations: destinations,
                      selectedIndex: selectedIndex,
                      onDestinationSelected: onDestinationSelected!,
                      action: action,
                    ),
                  ),
                ],
              ),
      );
    }
    final wide = width >= ClayMetrics.sidebarBreakpoint;
    return ColoredBox(
      color: ground,
      child: RawAdaptiveShell(
        mode: wide ? RawNavigationMode.sidebar : RawNavigationMode.rail,
        destinations: [
          for (final d in destinations)
            RawNavigationDestination(
              label: d.label,
              icon: d.icon,
              selectedIcon: d.selectedIcon,
              data: d,
            ),
        ],
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinationBuilder: (context, destination, details) {
          final d = destination.data! as ClayDestination;
          return KeyedSubtree(
            key: d.key,
            child: details.mode == RawNavigationMode.sidebar
                ? _SideFace(destination: d, states: details.states, style: null)
                : _RailFace(
                    destination: d,
                    states: details.states,
                    style: null,
                  ),
          );
        },
        navigationBuilder: (context, details) => wide
            ? ClaySidebar._shell(
                details.destinations,
                selectedIndex: details.selectedIndex,
                header: _head(true),
                footer: sideFooter,
              )
            : ClayNavigationRail._shell(
                details.destinations,
                selectedIndex: details.selectedIndex,
                leading: _head(false),
              ),
        body: page,
      ),
    );
  }

  Widget? _head(bool wide) {
    final act = action;
    if (act == null) return brand;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: wide
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        ?brand,
        Padding(
          padding: EdgeInsets.only(top: brand == null ? 0 : ClaySpacing.large),
          child: wide
              ? Align(alignment: AlignmentDirectional.centerStart, child: act)
              : act,
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        IterableProperty<String>(
          'destinations',
          destinations.map((d) => d.label),
        ),
      )
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        FlagProperty(
          'showNavigation',
          value: showNavigation,
          ifFalse: 'hidden',
        ),
      );
  }
}

/// Clay's tabs: their names on the ground, the current one on a white clay
/// pill risen out of it, sliding from tab to tab. They fill their row below
/// 600 px; above, they hug their names. The arrows move between them.
///
/// ```dart
/// ClayTabBar(tabs: const ['Week', 'Month', 'Year'], selectedIndex: 0, onTap: (index) {})
/// ```
class ClayTabBar extends StatefulWidget {
  /// Tabs named [tabs], [selectedIndex] current.
  const ClayTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
    this.expand,
    this.style,
  });

  /// The tabs' names, two or more.
  final List<String> tabs;

  /// The current tab.
  final int selectedIndex;

  /// Called with the tab chosen.
  final ValueChanged<int> onTap;

  /// Whether they fill their row; null: below 600 px of window.
  final bool? expand;

  /// The tabs' own style, over [ClayThemeData.tabBarStyle]: `fill` the
  /// pill, `foreground` the current name.
  final ClayStyle? style;

  @override
  State<ClayTabBar> createState() => _ClayTabBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex));
  }
}

class _ClayTabBarState extends State<ClayTabBar> with TickerProviderStateMixin {
  late RawTabController _tabs = _controller();
  late int _reported = widget.selectedIndex;

  RawTabController _controller() => RawTabController(
    length: widget.tabs.length,
    initialIndex: widget.selectedIndex,
    vsync: this,
    dampingRatio: ClayMotion.slideDamping,
    stiffness: ClayMotion.slideStiffness,
  )..addListener(_chosen);

  void _chosen() {
    if (_tabs.index == _reported) return;
    _reported = _tabs.index;
    widget.onTap(_tabs.index);
  }

  @override
  void didUpdateWidget(ClayTabBar old) {
    super.didUpdateWidget(old);
    _reported = widget.selectedIndex;
    if (old.tabs.length != widget.tabs.length) {
      _tabs.dispose();
      _tabs = _controller();
    } else if (_tabs.index != widget.selectedIndex) {
      _tabs.animateTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: 1.5,
    child: Builder(builder: _build),
  );

  Widget _build(BuildContext context) {
    final tabs = widget.tabs;
    assert(tabs.length >= 2, 'A tab bar has two tabs or more.');
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final fill = widget.expand ?? MediaQuery.sizeOf(context).width < 600;
    final height = theme.controlHeight - 4;
    final label = theme.textTheme.label.copyWith(
      fontWeight: FontWeight.w600,
      fontVariations: clayWeight(FontWeight.w600),
    );
    final painter = TextPainter(textDirection: TextDirection.ltr);
    var widest = 0.0;
    for (final t in tabs) {
      painter
        ..text = TextSpan(text: t, style: label)
        ..layout();
      widest = math.max(widest, painter.width);
    }
    painter.dispose();
    final slot =
        widest * MediaQuery.textScalerOf(context).scale(1) +
        2 * ClaySpacing.roomy;
    final layered = RawStyleOf(
      [widget.style, theme.tabBarStyle],
      const {WidgetState.selected},
    );
    return LayoutBuilder(
      builder: (context, box) {
        final width = fill && box.hasBoundedWidth
            ? box.maxWidth
            : math.min(
                slot * tabs.length,
                box.hasBoundedWidth ? box.maxWidth : double.infinity,
              );
        return Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          child: SizedBox(
            width: width,
            height: height,
            child: RawTabBar(
              controller: _tabs,
              tabs: [for (final t in tabs) RawTab(label: t)],
              indicatorBuilder: (context, details) => ClaySurface(
                face: ClayFace.raised(
                  c,
                  color: layered.fill ?? c.risen,
                  radius: height / 2,
                ),
              ),
              tabBuilder: (context, tab, details) =>
                  _tab(context, tab, details, height),
            ),
          ),
        );
      },
    );
  }

  Widget _tab(
    BuildContext context,
    RawTab tab,
    RawTabDetails details,
    double height,
  ) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final chosen = details.selection >= 0.5;
    final layered = RawStyleOf(
      [widget.style, theme.tabBarStyle],
      {...details.states, if (chosen) WidgetState.selected},
    );
    final weight = chosen ? FontWeight.w600 : FontWeight.w500;
    final focused = details.states.contains(WidgetState.focused);
    final hovered = details.states.contains(WidgetState.hovered);
    return TapTargetPadding(
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: !chosen && hovered
              ? _Plate(c.well.withValues(alpha: 0.6), height / 2)
              : null,
          foregroundPainter: focused ? _Rim(c.focus, height / 2) : null,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ClaySpacing.small,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: RawCapCenter(
                  capHeightFactor: clayCapHeightFactor,
                  child: Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.label
                        .copyWith(
                          color:
                              layered.foreground ??
                              (chosen ? c.ink : c.inkSecondary),
                          fontWeight: weight,
                          fontVariations: clayWeight(weight),
                        )
                        .merge(layered.textStyle),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Plate extends CustomPainter {
  _Plate(this.color, this.radius);

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_Plate old) => old.color != color || old.radius != radius;
}

class _Rim extends CustomPainter {
  _Rim(this.color, this.radius);

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(1),
        Radius.circular(radius - 1),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_Rim old) => old.color != color || old.radius != radius;
}
