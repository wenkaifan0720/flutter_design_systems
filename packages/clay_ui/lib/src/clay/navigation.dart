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
/// [title], its [actions] at the end. The title keeps to one line and ends
/// in an ellipsis where it is too long, and grows with the text size to
/// 150%. [large] sets the title big under the bar on a phone and a tablet,
/// on up to two lines; on a desk it stays on the bar's line. From 600 the
/// bar stands on the page's column ([ClayMetrics.pageWidth]), over the body.
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
        // On a tablet and a desk the bar stands on the page's column
        // ([ClayMetrics.pageWidth] in its margins), as the page's body does.
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ClayMetrics.pageWidth + 2 * margin,
            ),
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
              // whole, rather than lose its end to an ellipsis, and keeps
              // clear of its pill's round ends.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClaySpacing.tight,
                ),
                child: FittedBox(
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
    final rest = ClayFace.well(c, radius: theme.shapeScheme.corners.medium)
        .copyWith(
          color: c.well.withValues(alpha: hovered ? 0.6 : 0),
          lightOpacity: 0,
          shadeOpacity: 0,
        );
    final face =
        (chosen
                ? ClayFace.raised(
                    c,
                    color: layered.fill ?? c.risen,
                    radius: theme.shapeScheme.corners.medium,
                  )
                : states.contains(WidgetState.pressed)
                ? ClayFace.well(c, radius: theme.shapeScheme.corners.medium)
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
                  // The chosen place's glyph in the accent's ink, as dark (or
                  // as light) as standing 3:1 on its risen clay takes: a
                  // brand's ink that reads on the ground can sink into it.
                  color: chosen
                      ? RawPalette.readableTone(
                          c.accentInk,
                          on: [layered.fill ?? c.risen],
                          ratio: 3,
                        )
                      : ink,
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
  }) : _places = null,
       _group = null;

  const ClayNavigationBar._shell(
    this._places,
    this._group, {
    required this.selectedIndex,
    this.action,
  }) : destinations = const [],
       onDestinationSelected = _ignore,
       style = null;

  final List<Widget>? _places;

  // The shell's tab bar, round the places alone (the action stands apart).
  final Widget Function(Widget places)? _group;

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
    final places =
        _places ??
        [
          for (final (i, d) in destinations.indexed)
            _Place(
              destination: d,
              chosen: i == selectedIndex,
              onPressed: () => onDestinationSelected(i),
              face: (states) =>
                  _DockFace(destination: d, states: states, style: style),
            ),
        ];
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final place in places) Expanded(child: place)],
    );
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
                      child: _group?.call(row) ?? row,
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

  /// The sidebar's width at the reader's usual text size. With larger text
  /// it grows, as Material's extended rail grows to its labels, up to the
  /// width of Material's navigation drawer (360 at twice the text), so its
  /// key, its places and its foot keep their words on a line.
  static const double width = ClayMetrics.sidebarWidth;

  /// The width at the reader's text size: [width], and from there 96 more
  /// by twice the text.
  static double _widthFor(BuildContext context) {
    final grown = MediaQuery.textScalerOf(context).scale(16) / 16 - 1;
    return (width + 96 * grown).clamp(width, width + 96);
  }

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
        width: _widthFor(context),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            ClaySpacing.regular,
            // The first place stands on the top bar's line, level with the
            // page's title and its back ball.
            top +
                ((ClayTopBar.height - theme.density.height(44)) / 2).clamp(
                  0.0,
                  ClaySpacing.roomy,
                ),
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

/// A Clay app's frame: the places as a floating dock on a phone (under
/// 600 px), a rail on a tablet, a sidebar on a desk (from 1024 px), and the
/// page beside them. Built on ui_core's adaptive shell at every width: the
/// places are one tab stop, the arrows moving along them; a screen reader
/// hears the dock's tabs, each with its place ("Tab 1 of 3"), and the
/// sidebar as the navigation menu; toasts keep clear of the dock.
///
/// [ClayScaffold.branches] gives each place its own stack of pages: a page
/// pushed with `Navigator.of(context).push` stands over its place, the rail
/// or the sidebar still beside it while a phone's dock steps away
/// ([hideBarOnPush]), and back pops it. Choosing the place again goes back
/// to its first page. A page pushed on the app's root navigator covers the
/// whole frame. [ClayScaffold] stands the app's own [body] under its
/// [topBar] instead (an `IndexedStack`, or a router's branches), and hides
/// the dock with [showNavigation] while a page of its own is pushed.
///
/// ```dart
/// ClayScaffold.branches(destinations: const [ClayDestination(icon: LucideIcons.sun, label: 'Today'), ClayDestination(icon: LucideIcons.listChecks, label: 'Habits')], selectedIndex: 0, onDestinationSelected: (index) {}, branches: [(context) => const Text('Today'), (context) => const Text('Habits')])
/// ```
class ClayScaffold extends StatelessWidget {
  /// A frame round the app's own [body].
  const ClayScaffold({
    super.key,
    required Widget this.body,
    this.topBar,
    this.destinations = const [],
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.brand,
    this.action,
    this.sideFooter,
    this.showNavigation = true,
    this.style,
  }) : branches = null,
       navigatorKeys = null,
       backBehavior = RawBranchBackBehavior.firstDestination,
       hideBarOnPush = false;

  /// A frame whose places each keep their own stack of pages, starting on
  /// its [branches] page (a [ClayScreen] with its own top bar).
  const ClayScaffold.branches({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required ValueChanged<int> this.onDestinationSelected,
    required List<WidgetBuilder> this.branches,
    this.navigatorKeys,
    this.backBehavior = RawBranchBackBehavior.firstDestination,
    this.hideBarOnPush = true,
    this.brand,
    this.action,
    this.sideFooter,
    this.style,
  }) : body = null,
       topBar = null,
       showNavigation = true;

  /// The page, or a router's branches; null with [branches].
  final Widget? body;

  /// The bar over [body]; null with [branches], whose pages bring their own.
  final Widget? topBar;

  /// The app's places; none: a page with no places (a pushed page).
  final List<ClayDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen (the current one again included).
  final ValueChanged<int>? onDestinationSelected;

  /// Each place's first page; null with [body].
  final List<WidgetBuilder>? branches;

  /// The places' navigators' keys, to push onto a place from outside (a
  /// notification opening a record); null: the frame's own.
  final List<GlobalKey<NavigatorState>>? navigatorKeys;

  /// Where back goes from a place at its first page: to the first place,
  /// then out of the app.
  final RawBranchBackBehavior backBehavior;

  /// Whether a phone's dock steps away while a page is pushed over a place
  /// ([ClayScaffold.branches]); the rail and the sidebar stay.
  final bool hideBarOnPush;

  /// The app's mark atop a rail or a sidebar: its name, or a small mark of
  /// its own.
  ///
  /// It keeps its own size, at the start of a sidebar's head and in the
  /// middle of a rail's. A rail is 96 wide and a sidebar 264, so a mark that
  /// shows the app's name beside it on a sidebar reads its room with a
  /// [LayoutBuilder]: `brand: LayoutBuilder(builder: (context, room) => room.maxWidth < 160 ? mark : Row(mainAxisSize: MainAxisSize.min, spacing: 12, children: [mark, const Text('Shelf')]))`.
  final Widget? brand;

  /// The screen's one key: at the dock's end on a phone, under the brand on
  /// a rail or a sidebar.
  final Widget? action;

  /// What stands at the sidebar's foot.
  final Widget? sideFooter;

  /// Whether a phone's dock shows over the app's own [body]: false while a
  /// page of the app's is pushed over a place, and the dock steps away (the
  /// rail and the sidebar stay).
  final bool showNavigation;

  /// Its own style, over [ClayThemeData.scaffoldStyle]: `fill` the ground
  /// the page and its navigation stand on.
  final ClayStyle? style;

  static RawNavigationMode _modeFor(double width) =>
      width < ClayMetrics.railBreakpoint
      ? RawNavigationMode.bar
      : width >= ClayMetrics.sidebarBreakpoint
      ? RawNavigationMode.sidebar
      : RawNavigationMode.rail;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final ground =
        RawStyleOf([style, theme.scaffoldStyle], const {}).fill ??
        theme.colors.ground;
    final open = body;
    final places = destinations.isNotEmpty && onDestinationSelected != null;
    if (!places) {
      return ColoredBox(
        color: ground,
        child: _page(context, open ?? const SizedBox.shrink()),
      );
    }
    final raw = [
      for (final d in destinations)
        RawNavigationDestination(
          label: d.label,
          icon: d.icon,
          selectedIcon: d.selectedIcon,
          data: d,
        ),
    ];
    Widget face(
      BuildContext context,
      RawNavigationDestination destination,
      RawDestinationDetails details,
    ) {
      final d = destination.data! as ClayDestination;
      return KeyedSubtree(
        key: d.key,
        child: switch (details.mode) {
          RawNavigationMode.sidebar => _SideFace(
            destination: d,
            states: details.states,
            style: null,
          ),
          RawNavigationMode.rail => _RailFace(
            destination: d,
            states: details.states,
            style: null,
          ),
          RawNavigationMode.bar || RawNavigationMode.top => _DockFace(
            destination: d,
            states: details.states,
            style: null,
          ),
        },
      );
    }

    Widget navigation(BuildContext context, RawNavigationDetails details) =>
        switch (details.mode) {
          RawNavigationMode.sidebar => ClaySidebar._shell(
            details.destinations,
            selectedIndex: details.selectedIndex,
            header: _head(true),
            footer: sideFooter,
          ),
          RawNavigationMode.rail => ClayNavigationRail._shell(
            details.destinations,
            selectedIndex: details.selectedIndex,
            leading: _head(false),
          ),
          RawNavigationMode.bar || RawNavigationMode.top => _Dock(
            ground: ground,
            visibility: details.visibility,
            child: ClayNavigationBar._shell(
              details.destinations,
              details.group,
              selectedIndex: details.selectedIndex,
              action: action,
            ),
          ),
        };
    // The width the window gives, as Clay's dock, its page margins and its
    // action read it.
    final mode = _modeFor(MediaQuery.sizeOf(context).width);
    final stacks = branches;
    return ColoredBox(
      color: ground,
      child: stacks == null
          ? RawAdaptiveShell(
              destinations: raw,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinationBuilder: face,
              navigationBuilder: navigation,
              mode: mode,
              showNavigation: showNavigation,
              body: _page(context, open!),
            )
          : RawAdaptiveShell.branches(
              destinations: raw,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinationBuilder: face,
              navigationBuilder: navigation,
              mode: mode,
              branches: stacks,
              navigatorKeys: navigatorKeys,
              backBehavior: backBehavior,
              hideBarOnPush: hideBarOnPush,
            ),
    );
  }

  // The top bar over the page; the page keeps its children's nodes apart.
  // A Navigator here would otherwise hang its route's node off this one,
  // and a list opening over the route gives the route a node between them:
  // on the web the focused field's input moves into it and the browser
  // blurs it, so the tap that opened the list loses focus.
  Widget _page(BuildContext context, Widget page) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ?topBar,
      Expanded(
        child: MediaQuery.removePadding(
          context: context,
          removeTop: topBar != null,
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            child: page,
          ),
        ),
      ),
    ],
  );

  Widget? _head(bool wide) {
    // The mark keeps its own size: a sidebar's head would stretch it across.
    final own = brand;
    final mark = own == null || !wide
        ? own
        : Align(alignment: AlignmentDirectional.centerStart, child: own);
    final act = action;
    if (act == null) return mark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: wide
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        ?mark,
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
      ..add(IntProperty('branches', branches?.length, defaultValue: null))
      ..add(
        IterableProperty<GlobalKey<NavigatorState>>(
          'navigatorKeys',
          navigatorKeys,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<RawBranchBackBehavior>(
          'backBehavior',
          backBehavior,
          defaultValue: RawBranchBackBehavior.firstDestination,
        ),
      )
      ..add(
        FlagProperty(
          'hideBarOnPush',
          value: hideBarOnPush,
          ifTrue: 'dock hidden on push',
        ),
      )
      ..add(
        FlagProperty(
          'showNavigation',
          value: showNavigation,
          ifFalse: 'hidden',
        ),
      );
  }
}

// A phone's dock in the frame: the page fades into the ground above it,
// rather than stopping at a line, and the fade goes as the dock steps away.
class _Dock extends StatelessWidget {
  const _Dock({
    required this.ground,
    required this.visibility,
    required this.child,
  });

  final Color ground;
  final Animation<double> visibility;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      child,
      PositionedDirectional(
        start: 0,
        end: 0,
        top: -ClaySpacing.large,
        height: ClaySpacing.large,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: visibility,
            builder: (context, fade) =>
                Opacity(opacity: visibility.value.clamp(0.0, 1.0), child: fade),
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
      ),
    ],
  );
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
