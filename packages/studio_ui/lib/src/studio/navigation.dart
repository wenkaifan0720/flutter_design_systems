/// Studio's navigation: the faceplate [StudioAppBar]; the places of an app as
/// latching keys in a bank ([StudioNavigationBar] on a phone,
/// [StudioNavigationRail] from 600 px) or as legends on a panel with the
/// chosen one in a lit glass slot ([StudioSideNavigation] from 1024 px);
/// [StudioTabBar]; and [StudioScaffold], which picks among them by width.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'internal/strip.dart';
import 'internal/control_light.dart';
import 'surface.dart';
import 'theme.dart';

/// One of an app's places.
@immutable
class StudioDestination {
  /// A place named [label], shown by [icon].
  const StudioDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.key,
  });

  /// The key on its key, rail key or side row: what a test or a walk
  /// finds the place by.
  final Key? key;

  /// Its glyph.
  final Widget icon;

  /// Its glyph while chosen; [icon] when null.
  final Widget? selectedIcon;

  /// Its name, sentence case.
  final String label;
}

// The metal of a bar: full bleed, brushed, its edge toward the content
// catching the light (top) or casting its shadow (bottom).
class _Faceplate extends StatelessWidget {
  const _Faceplate({required this.child, this.style});

  final Widget child;
  final DesignStyleOf? style;

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    final face = StudioFace(
      fill: c.bar,
      fillLow: c.barLow,
      depth: StudioDepth.level,
      radius: 0,
      foreground: c.legend,
      brushed: true,
    );
    return RepaintBoundary(
      child: StudioSurface(face: style?.on(face) ?? face, child: child),
    );
  }
}

// An app bar's height in [theme]: a control with room above and below.
double _barHeight(StudioThemeData theme) =>
    theme.controlHeight + 2 * StudioSpacing.small + 4;

/// The top bar: a faceplate across the screen, the page's title printed on
/// it, a back key at its start on a pushed page (a close key in a sheet),
/// the page's actions as keys at its end. A [bottom] (a [StudioTabBar])
/// stands under the title.
///
/// Reads [style]'s `fill`, `foreground` and `minimumSize` (its height), then
/// [StudioThemeData.appBarStyle].
///
/// ```dart
/// StudioAppBar(title: 'Library', actions: [StudioIconButton(icon: const Icon(LucideIcons.search), tooltip: 'Search', onPressed: search)])
/// ```
class StudioAppBar extends StatelessWidget {
  /// A bar titled [title].
  const StudioAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions = const [],
    this.bottom,
    this.automaticallyImplyLeading = true,
    this.style,
  });

  /// The way out the route implies, for [leading]: a back key on a pushed
  /// page, a close key in a sheet ([RoutePresentation.sheet]), nothing at a
  /// root. Either pops the route. [key] goes on the key, for a test or a
  /// walk to find it by.
  ///
  /// ```dart
  /// StudioAppBar(title: 'Episode', leading: StudioAppBar.autoLeading(context))
  /// ```
  static Widget? autoLeading(BuildContext context, {Key? key}) {
    final words = RawWidgetsLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return switch (RoutePresentation.of(context)) {
      RoutePresentation.root => null,
      RoutePresentation.pushed => StudioIconButton(
        key: key,
        icon: Icon(rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft),
        tooltip: words.backButtonTooltip,
        onPressed: () => Navigator.maybePop(context),
      ),
      RoutePresentation.sheet => StudioIconButton(
        key: key,
        icon: const Icon(LucideIcons.x),
        tooltip: words.closeButtonLabel,
        onPressed: () => Navigator.maybePop(context),
      ),
    };
  }

  /// The page's name.
  final String? title;

  /// What stands at its start in place of the back key.
  final Widget? leading;

  /// Keys at its end.
  final List<Widget> actions;

  /// What stands under the title: a [StudioTabBar]. It stands in the bar's
  /// content column, set in by the page margin as the title and the actions
  /// are.
  final Widget? bottom;

  /// Whether a pushed page gets a back key (a sheet a close key) when
  /// [leading] is null.
  final bool automaticallyImplyLeading;

  /// Its style, over [StudioThemeData.appBarStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final layered = DesignStyleOf([style, theme.appBarStyle], const {});
    final height = layered.minimumSize?.height ?? _barHeight(theme);
    final margin = StudioSpacing.pageMargin(MediaQuery.sizeOf(context).width);
    final lead =
        leading ?? (automaticallyImplyLeading ? autoLeading(context) : null);
    return _Faceplate(
      style: layered,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: height,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: margin),
                child: Row(
                  children: [
                    if (lead != null) ...[
                      lead,
                      const SizedBox(width: StudioSpacing.medium),
                    ],
                    Expanded(
                      child: title == null
                          ? const SizedBox.shrink()
                          : Semantics(
                              header: true,
                              child: DesignCapCenter(
                                capHeightFactor: theme.capHeightFactor,
                                child: Text(
                                  title!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.title.copyWith(
                                    fontSize: 18,
                                    height: 24 / 18,
                                    color:
                                        layered.foreground ??
                                        theme.colors.legend,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    for (final (i, a) in actions.indexed) ...[
                      if (i > 0) const SizedBox(width: StudioSpacing.small),
                      a,
                    ],
                  ],
                ),
              ),
            ),
            // In the bar's content column: the tabs' first legend under the
            // title's start, the strip's groove ending under the actions'.
            if (bottom case final bottom?)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: margin),
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
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(
        FlagProperty(
          'automaticallyImplyLeading',
          value: automaticallyImplyLeading,
          ifFalse: 'no implied leading',
        ),
      )
      ..add(
        DiagnosticsProperty<StudioStyle>('style', style, defaultValue: null),
      );
  }
}

// A key of a navigation bank: its glyph over its name, its lamp at its top
// corner. Chosen, it is latched in, its lamp lit, its glyph and name lit.
class _BankKey extends StatelessWidget {
  const _BankKey({
    super.key,
    required this.destination,
    required this.selected,
    required this.onPressed,
    required this.style,
  });

  final StudioDestination destination;
  final bool selected;
  final VoidCallback onPressed;
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) => RawButton(
    onPressed: onPressed,
    selected: selected,
    semanticSelected: selected,
    semanticLabel: destination.label,
    excludeSemantics: true,
    builder: (context, states, _) => _BankFace(
      destination: destination,
      selected: selected,
      states: states,
      style: style,
    ),
  );
}

// A bank key's face, in its states: the standalone bar's and rail's keys and
// the shell's places paint it.
class _BankFace extends StatelessWidget {
  const _BankFace({
    required this.destination,
    required this.selected,
    required this.states,
    required this.style,
  });

  final StudioDestination destination;
  final bool selected;
  final Set<WidgetState> states;
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf(
      [style],
      {...states, if (selected) WidgetState.selected},
    );
    final pressed = states.contains(WidgetState.pressed);
    final ink = layered.foreground ?? (selected ? c.litLegend : c.onKey);
    final face = layered.on(
      c.keyFace
          .copyWith(
            radius: StudioRadii.bank - StudioMetrics.recessInset,
            travel: selected || pressed ? 1 : 0,
            foreground: ink,
            focus: states.contains(WidgetState.focused)
                ? c.focusRing
                : c.focusRing.withValues(alpha: 0),
          )
          .backlitIf(
            c,
            selected,
            focused: states.contains(WidgetState.focused),
          ),
    );
    return AnimatedStudioSurface.inBank(
      face: face,
      child: Stack(
        children: [
          PositionedDirectional(
            top: 6,
            end: 6,
            child: StudioLamp(on: selected, size: 5),
          ),
          Center(
            child: Padding(
              // Room between the legend and the key's walls.
              padding: const EdgeInsets.symmetric(
                horizontal: StudioSpacing.small,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTheme.merge(
                    data: IconThemeData(
                      size: StudioIconSizes.regular,
                      color: ink,
                    ),
                    child: selected
                        ? destination.selectedIcon ?? destination.icon
                        : destination.icon,
                  ),
                  const SizedBox(height: StudioSpacing.hair),
                  // A bank key's legend is engraved: it grows with the
                  // reader's text to half again its size, no more (the
                  // key's height is the bank's), and a word wider than
                  // its key is set smaller, never cut. A screen reader
                  // reads it whole.
                  MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.5,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.caption.copyWith(
                          fontSize: 12,
                          height: 16 / 12,
                          color: ink,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The phone's bottom bar: a faceplate holding the app's places as a bank
/// of latching keys in a recess. The chosen key is latched in, its lamp lit.
///
/// Reads [style]'s `fill`, `foreground` and `minimumSize` (a key's height),
/// then [StudioThemeData.navigationBarStyle].
///
/// ```dart
/// StudioNavigationBar(destinations: places, selectedIndex: tab, onDestinationSelected: go)
/// ```
class StudioNavigationBar extends StatelessWidget {
  /// A bar over [destinations].
  const StudioNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.style,
  }) : _places = null;

  // A bar round the places ui_core's shell presses ([StudioScaffold]).
  const StudioNavigationBar._shell(this._places, {required this.selectedIndex})
    : destinations = const [],
      onDestinationSelected = _ignore,
      style = null;

  final List<Widget>? _places;

  /// The places.
  final List<StudioDestination> destinations;

  /// The chosen place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onDestinationSelected;

  /// Its style, over [StudioThemeData.navigationBarStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final layered = DesignStyleOf([style, theme.navigationBarStyle], const {});
    final key = layered.minimumSize?.height ?? theme.controlHeight + 8;
    const inset = StudioMetrics.recessInset;
    final places =
        _places ??
        [
          for (final (i, d) in destinations.indexed)
            _BankKey(
              key: d.key,
              destination: d,
              selected: i == selectedIndex,
              onPressed: () => onDestinationSelected(i),
              style: style ?? theme.navigationBarStyle,
            ),
        ];
    return _Faceplate(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            StudioSpacing.medium,
            StudioSpacing.small,
            StudioSpacing.medium,
            StudioSpacing.small,
          ),
          // The shell's bar is a tab bar whose children are its tabs: the
          // group stands only round the standalone bar's keys.
          child: Semantics(
            container: _places == null,
            explicitChildNodes: true,
            child: StudioSurface(
              face: theme.colors.recessFace,
              child: Padding(
                padding: const EdgeInsets.all(inset),
                child: SizedBox(
                  height: key,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, place) in places.indexed) ...[
                        if (i > 0) const SizedBox(width: inset),
                        Expanded(child: place),
                      ],
                    ],
                  ),
                ),
              ),
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
      ..add(IterableProperty<StudioDestination>('destinations', destinations))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(
        DiagnosticsProperty<StudioStyle>('style', style, defaultValue: null),
      );
  }
}

/// The tablet's rail: a column of metal at the start holding the app's
/// places as a vertical bank of latching keys, a [leading] mark above them.
///
/// Reads [style]'s `fill`, `foreground` and `minimumSize` (a key's height),
/// then [StudioThemeData.navigationRailStyle].
///
/// ```dart
/// StudioNavigationRail(destinations: places, selectedIndex: tab, onDestinationSelected: go)
/// ```
class StudioNavigationRail extends StatelessWidget {
  /// A rail over [destinations].
  const StudioNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.leading,
    this.style,
  }) : _places = null;

  // A rail round the places ui_core's shell presses ([StudioScaffold]).
  const StudioNavigationRail._shell(
    this._places, {
    required this.selectedIndex,
    this.leading,
  }) : destinations = const [],
       onDestinationSelected = _ignore,
       style = null;

  final List<Widget>? _places;

  /// The places.
  final List<StudioDestination> destinations;

  /// The chosen place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onDestinationSelected;

  /// A mark above the keys.
  final Widget? leading;

  /// Its style, over [StudioThemeData.navigationRailStyle].
  final StudioStyle? style;

  /// Its width.
  static const double width = 92;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final layered = DesignStyleOf([style, theme.navigationRailStyle], const {});
    final key = layered.minimumSize?.height ?? 60.0;
    const inset = StudioMetrics.recessInset;
    final places =
        _places ??
        [
          for (final (i, d) in destinations.indexed)
            _BankKey(
              key: d.key,
              destination: d,
              selected: i == selectedIndex,
              onPressed: () => onDestinationSelected(i),
              style: style ?? theme.navigationRailStyle,
            ),
        ];
    return SizedBox(
      width: width,
      child: _Faceplate(
        child: SafeArea(
          right: false,
          child: Padding(
            padding: const EdgeInsets.all(StudioSpacing.medium),
            child: Column(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(height: StudioSpacing.large),
                ],
                Semantics(
                  container: true,
                  explicitChildNodes: true,
                  child: StudioSurface(
                    face: theme.colors.recessFace,
                    child: Padding(
                      padding: const EdgeInsets.all(inset),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, place) in places.indexed) ...[
                            if (i > 0) const SizedBox(height: inset),
                            SizedBox(height: key, child: place),
                          ],
                        ],
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<StudioDestination>('destinations', destinations))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(
        DiagnosticsProperty<StudioStyle>('style', style, defaultValue: null),
      );
  }
}

/// The desktop's side navigation: a panel at the start with the app's name
/// ([header]) and its places as a column of keys set in a recess, the
/// rack's key column. The chosen place's key is latched in, its legend and
/// lamp lit (by day its cap backlit), as the phone's key bank and the
/// tablet's rail are. A key does not light under the pointer.
///
/// Reads [style]'s `fill`, `foreground` and `minimumSize` (a row's height),
/// then [StudioThemeData.sideNavigationStyle].
///
/// ```dart
/// StudioSideNavigation(header: const Text('Roomtone'), destinations: places, selectedIndex: tab, onDestinationSelected: go)
/// ```
class StudioSideNavigation extends StatelessWidget {
  /// Side navigation over [destinations].
  const StudioSideNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.header,
    this.footer,
    this.style,
  }) : _places = null;

  // Side navigation round the places ui_core's shell presses
  // ([StudioScaffold]).
  const StudioSideNavigation._shell(
    this._places, {
    required this.selectedIndex,
    this.header,
    this.footer,
  }) : destinations = const [],
       onDestinationSelected = _ignore,
       style = null;

  final List<Widget>? _places;

  /// The places.
  final List<StudioDestination> destinations;

  /// The chosen place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onDestinationSelected;

  /// The app's name or mark, at the top.
  final Widget? header;

  /// What stands at the foot: an account, a readout.
  final Widget? footer;

  /// Its style, over [StudioThemeData.sideNavigationStyle].
  final StudioStyle? style;

  /// Its width.
  static const double width = 248;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.sideNavigationStyle], const {});
    final row = layered.minimumSize?.height ?? theme.controlHeight;
    final places =
        _places ??
        [
          for (final (i, d) in destinations.indexed)
            _SideRow(
              key: d.key,
              destination: d,
              selected: i == selectedIndex,
              height: row,
              onPressed: () => onDestinationSelected(i),
              style: style ?? theme.sideNavigationStyle,
            ),
        ];
    return SizedBox(
      width: width,
      child: _Faceplate(
        child: SafeArea(
          right: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              StudioSpacing.medium,
              header == null ? StudioSpacing.large : 0,
              StudioSpacing.medium,
              StudioSpacing.medium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The header stands in a band as tall as an app bar, so the
                // app's name sits on the line of the page title beside it.
                if (header != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: _barHeight(theme)),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: StudioSpacing.medium,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: 1,
                        child: DefaultTextStyle.merge(
                          style: theme.textTheme.title.copyWith(
                            color: c.legend,
                          ),
                          child: header!,
                        ),
                      ),
                    ),
                  ),
                if (header != null) const SizedBox(height: StudioSpacing.small),
                Semantics(
                  container: true,
                  explicitChildNodes: true,
                  child: StudioSurface(
                    face: c.recessFace,
                    child: Padding(
                      padding: const EdgeInsets.all(StudioMetrics.recessInset),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, place) in places.indexed)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: i == places.length - 1
                                    ? 0
                                    : StudioMetrics.recessInset,
                              ),
                              child: place,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                ?footer,
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
      ..add(IterableProperty<StudioDestination>('destinations', destinations))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(
        DiagnosticsProperty<StudioStyle>('style', style, defaultValue: null),
      );
  }
}

class _SideRow extends StatelessWidget {
  const _SideRow({
    super.key,
    required this.destination,
    required this.selected,
    required this.height,
    required this.onPressed,
    required this.style,
  });

  final StudioDestination destination;
  final bool selected;
  final double height;
  final VoidCallback onPressed;
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) => RawButton(
    onPressed: onPressed,
    selected: selected,
    semanticSelected: selected,
    semanticLabel: destination.label,
    excludeSemantics: true,
    builder: (context, states, _) => _SideFace(
      destination: destination,
      selected: selected,
      states: states,
      height: height,
      style: style,
    ),
  );
}

// A side row's face, in its states: the standalone side navigation's rows
// and the shell's places paint it.
class _SideFace extends StatelessWidget {
  const _SideFace({
    required this.destination,
    required this.selected,
    required this.states,
    required this.height,
    required this.style,
  });

  final StudioDestination destination;
  final bool selected;
  final Set<WidgetState> states;
  final double height;
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf(
      [style],
      {...states, if (selected) WidgetState.selected},
    );
    final pressed = states.contains(WidgetState.pressed);
    // A key of the column: latched in and lit when chosen, as the bank's
    // and the rail's are.
    final ink = layered.foreground ?? (selected ? c.litLegend : c.onKey);
    final face = layered.on(
      c.keyFace
          .copyWith(
            radius: StudioRadii.bank - StudioMetrics.recessInset,
            travel: selected || pressed ? 1 : 0,
            foreground: ink,
            focus: states.contains(WidgetState.focused)
                ? c.focusRing
                : c.focusRing.withValues(alpha: 0),
          )
          .backlitIf(
            c,
            selected,
            focused: states.contains(WidgetState.focused),
          ),
    );
    return SizedBox(
      height: height,
      child: AnimatedStudioSurface.inBank(
        face: face,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.medium),
          child: Row(
            children: [
              IconTheme.merge(
                data: IconThemeData(size: StudioIconSizes.regular, color: ink),
                child: selected
                    ? destination.selectedIcon ?? destination.icon
                    : destination.icon,
              ),
              const SizedBox(width: StudioSpacing.medium),
              Expanded(
                child: DesignCapCenter(
                  capHeightFactor: theme.capHeightFactor,
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.label.copyWith(
                      color: ink,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              StudioLamp(on: selected, size: StudioMetrics.lampSize),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tabs: legends engraved along a groove, the chosen one lit with a bar of
/// light under it that slides to the next choice on a spring. Arrows move
/// among them.
///
/// Reads [style]'s `foreground` (the unlit legends), `fill` (the lit bar)
/// and `minimumSize` (its height), then [StudioThemeData.tabBarStyle].
///
/// ```dart
/// StudioTabBar(tabs: const ['Notes', 'Chapters'], selectedIndex: tab, onChanged: (i) => setState(() => tab = i))
/// ```
class StudioTabBar extends StatefulWidget {
  /// Tabs named [tabs].
  const StudioTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.style,
  });

  /// The tabs' names.
  final List<String> tabs;

  /// The chosen tab.
  final int selectedIndex;

  /// Called with the tab chosen.
  final ValueChanged<int> onChanged;

  /// Its style, over [StudioThemeData.tabBarStyle].
  final StudioStyle? style;

  @override
  State<StudioTabBar> createState() => _StudioTabBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onChanged', onChanged))
      ..add(
        DiagnosticsProperty<StudioStyle>('style', style, defaultValue: null),
      );
  }
}

class _StudioTabBarState extends State<StudioTabBar>
    with TickerProviderStateMixin {
  late RawTabController _controller = _make();
  final List<GlobalKey> _keys = [];
  final GlobalKey _row = GlobalKey();

  RawTabController _make() => RawTabController(
    length: widget.tabs.length,
    initialIndex: widget.selectedIndex,
    vsync: this,
    dampingRatio: StudioMotion.dampingRatio,
    stiffness: StudioMotion.moveStiffness,
  )..addListener(_chosen);

  @override
  void didUpdateWidget(StudioTabBar old) {
    super.didUpdateWidget(old);
    if (widget.tabs.length != _controller.length) {
      final gone = _controller..removeListener(_chosen);
      _controller = _make();
      WidgetsBinding.instance.addPostFrameCallback((_) => gone.dispose());
    } else if (_controller.index != widget.selectedIndex) {
      // A choice made elsewhere (a page swiped, a parent): the bar of light
      // slides to it on its spring.
      _controller.animateTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_chosen)
      ..dispose();
    super.dispose();
  }

  // The bar chose a tab (a press, the arrows): the page hears it; a page
  // that keeps its own choice puts the bar back.
  void _chosen() {
    final i = _controller.index;
    if (i == widget.selectedIndex) return;
    widget.onChanged(i);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.index != widget.selectedIndex) {
        _controller.index = widget.selectedIndex;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    while (_keys.length < widget.tabs.length) {
      _keys.add(GlobalKey());
    }
    final layered = DesignStyleOf([widget.style, theme.tabBarStyle], const {});
    final height = layered.minimumSize?.height ?? theme.controlHeight;
    // The gap from a legend's words to its neighbour's is twice this.
    const half = StudioSpacing.regular;
    final bar = layered.fill ?? c.indicator;
    return SizedBox(
      height: height + 2,
      child: StudioStrip(
        fill: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: StudioGroove(),
            ),
            // The lit bar, under the chosen legend, on the tabs' spring.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _TabLightPainter(
                    at: _controller.animation,
                    tabs: _keys.take(widget.tabs.length).toList(),
                    row: _row,
                    color: bar,
                  ),
                ),
              ),
            ),
            // The tabs stand in the content column: the first legend's words
            // start on its edge, with room for the indicator beneath them.
            RawTabBar(
              key: _row,
              controller: _controller,
              tabs: [for (final name in widget.tabs) RawTab(label: name)],
              tabBuilder: (context, tab, details) {
                final i = details.index;
                final chosen = i == widget.selectedIndex;
                final states = details.states;
                final pressed = states.contains(WidgetState.pressed);
                // A press brings an unlit legend up to full ink and dims
                // a lit one a little, as a backlit legend under a thumb.
                final Color ink;
                if (chosen) {
                  ink = pressed
                      ? Color.lerp(c.litLegend, c.legend, 0.4)!
                      : c.litLegend;
                } else {
                  ink = pressed
                      ? c.legend
                      : layered.foreground ?? c.legendMuted;
                }
                return TapTargetPadding(
                  child: SizedBox(
                    height: height,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: i == 0 ? 0 : half,
                        end: half,
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: CustomPaint(
                          key: _keys[i],
                          foregroundPainter: _TabLegendLight(
                            color: Color.lerp(
                              bar,
                              const Color(0xFFFFFFFF),
                              0.5,
                            )!,
                            amount: studioControlLight(states),
                            height: height,
                          ),
                          child: TweenAnimationBuilder<Color?>(
                            tween: ColorTween(end: ink),
                            duration:
                                MediaQuery.maybeDisableAnimationsOf(context) ??
                                    false
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            builder: (context, color, _) => Text(
                              tab.label,
                              maxLines: 1,
                              style: theme.textTheme.label.copyWith(
                                color: color,
                                // One weight chosen or not: choosing never
                                // moves the legends beside it.
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// The brighter centre of the indicator lies in the groove beneath the legend.
class _TabLegendLight extends CustomPainter {
  const _TabLegendLight({
    required this.color,
    required this.amount,
    required this.height,
  });
  final Color color;
  final double amount;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    if (amount == 0) return;
    final y = (height + size.height) / 2 - 0.5;
    canvas.drawLine(
      Offset(-StudioSpacing.tight + 1, y),
      Offset(size.width + StudioSpacing.tight - 1, y),
      Paint()
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: amount),
    );
  }

  @override
  bool shouldRepaint(_TabLegendLight old) =>
      old.color != color || old.amount != amount || old.height != height;
}

class _TabLightPainter extends CustomPainter {
  _TabLightPainter({
    required this.at,
    required this.tabs,
    required this.row,
    required this.color,
  }) : super(repaint: at);

  // Where the selection stands: a tab's index at rest, between two as the
  // spring runs.
  final Animation<double> at;
  final List<GlobalKey> tabs;
  final GlobalKey row;
  final Color color;

  // The tabs' boxes in the painter's frame, read at paint time, after
  // layout: the bar stands under the legends as they are laid out now.
  List<Rect> _rects() {
    final origin = row.currentContext?.findRenderObject() as RenderBox?;
    final stack = origin?.parent;
    if (origin == null || stack is! RenderBox || !origin.hasSize) {
      return const [];
    }
    final rects = <Rect>[];
    for (final key in tabs) {
      final tab = key.currentContext?.findRenderObject() as RenderBox?;
      if (tab == null || !tab.hasSize || !tab.attached) return const [];
      rects.add(tab.localToGlobal(Offset.zero, ancestor: stack) & tab.size);
    }
    return rects;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rects = _rects();
    if (rects.isEmpty) return;
    final at = this.at.value;
    final i = at.floor().clamp(0, rects.length - 1);
    final j = (i + 1).clamp(0, rects.length - 1);
    final t = (at - i).clamp(0.0, 1.0);
    final a = rects[i].inflate(StudioSpacing.tight);
    final b = rects[j].inflate(StudioSpacing.tight);
    final left = a.left + (b.left - a.left) * t;
    final right = a.right + (b.right - a.right) * t;
    final r = RRect.fromLTRBR(
      left,
      size.height - 4,
      right,
      size.height - 1,
      const Radius.circular(1.5),
    );
    canvas
      ..drawRRect(
        r.inflate(1),
        Paint()
          ..color = color.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawRRect(r, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TabLightPainter old) => true;
}

/// An app's frame: its [body] under its [appBar], with its places as the
/// width asks: under 600 px a [StudioNavigationBar] at the foot; to 1024 px
/// a [StudioNavigationRail] at the start; wider a [StudioSideNavigation].
/// On a phone the page is one sheet of metal; wider, the rail or the side
/// navigation and the page stand as modules in a rack, the chassis between
/// them.
///
/// ui_core's adaptive shell runs the places: they are one tab stop, the
/// arrows moving along them (Up and Down in the rail and the side
/// navigation), Home and End to the ends, Enter or Space choosing; F6 moves
/// focus between them and the page; a screen reader hears each as a tab and
/// its place ("Tab 1 of 3"), the side navigation as the navigation menu.
///
/// ```dart
/// StudioScaffold(destinations: places, selectedIndex: tab, onDestinationSelected: go, appBar: const StudioAppBar(title: 'Home'), body: page)
/// ```
class StudioScaffold extends StatelessWidget {
  /// A frame round [body].
  const StudioScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.destinations = const [],
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.header,
    this.navigationFooter,
    this.bottom,
  });

  /// The page.
  final Widget body;

  /// The bar above it.
  final Widget? appBar;

  /// The app's places; none for a pushed page.
  final List<StudioDestination> destinations;

  /// The chosen place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int>? onDestinationSelected;

  /// The app's name or mark, at the top of the rail or the side navigation.
  final Widget? header;

  /// What stands at the foot of the side navigation.
  final Widget? navigationFooter;

  /// What stands at the page's foot above the bar: a transport, a key row.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final width = MediaQuery.sizeOf(context).width;
    final places = destinations.isNotEmpty && onDestinationSelected != null;
    final page = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?appBar,
        Expanded(
          child: RepaintBoundary(
            child: StudioSurface(
              face: StudioFace(
                fill: c.panel,
                fillLow: c.panelLow,
                depth: StudioDepth.level,
                radius: 0,
                brushed: true,
                foreground: c.legend,
              ),
              // The body a semantics container of its own: a navigator in it
              // (a desk's pages) puts a modal barrier over its routes, which
              // would otherwise hide the places beside it from a screen
              // reader. Its routes keep nodes of their own, as the app's
              // navigator's do: merged into the body, a route gains a node
              // only when a list opens over it, and on the web the focused
              // field's input moves into that node and loses its focus.
              child: SizedBox.expand(
                child: Semantics(
                  container: true,
                  explicitChildNodes: true,
                  child: body,
                ),
              ),
            ),
          ),
        ),
        ?bottom,
      ],
    );
    if (!places) return ColoredBox(color: c.chassis, child: page);
    // Studio's own widths: the rail from 600, the side navigation from 1024
    // (ui_core's classes open the sidebar at 1200).
    final mode = width < StudioMetrics.tablet
        ? DesignNavigationMode.bar
        : width < StudioMetrics.desk
        ? DesignNavigationMode.rail
        : DesignNavigationMode.sidebar;
    // The chassis between two modules: a seam, dark, its far lip lit.
    final seam = SizedBox(
      width: 3,
      child: Row(
        children: [
          Expanded(flex: 2, child: ColoredBox(color: c.chassisLow)),
          Expanded(
            child: ColoredBox(
              color: c.edgeLight.withValues(alpha: c.edgeLight.a * 0.5),
            ),
          ),
        ],
      ),
    );
    return ColoredBox(
      color: c.chassis,
      child: DesignAdaptiveShell(
        mode: mode,
        destinations: [
          for (final d in destinations)
            DesignNavigationDestination(
              label: d.label,
              // ui_core's shell reads no glyph (Studio paints its own); an
              // [Icon]'s is passed on.
              icon: _glyphOf(d.icon),
              selectedIcon: switch (d.selectedIcon) {
                final Widget w => _glyphOf(w),
                null => null,
              },
              data: d,
            ),
        ],
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        dampingRatio: StudioMotion.dampingRatio,
        stiffness: StudioMotion.moveStiffness,
        destinationBuilder: (context, destination, details) {
          final d = destination.data! as StudioDestination;
          final selected = details.states.contains(WidgetState.selected);
          return KeyedSubtree(
            key: d.key,
            child: details.mode == DesignNavigationMode.sidebar
                ? _SideFace(
                    destination: d,
                    selected: selected,
                    states: details.states,
                    height:
                        DesignStyleOf([
                          theme.sideNavigationStyle,
                        ], const {}).minimumSize?.height ??
                        theme.controlHeight,
                    style: theme.sideNavigationStyle,
                  )
                : _BankFace(
                    destination: d,
                    selected: selected,
                    states: details.states,
                    style: details.mode == DesignNavigationMode.bar
                        ? theme.navigationBarStyle
                        : theme.navigationRailStyle,
                  ),
          );
        },
        navigationBuilder: (context, details) => switch (details.mode) {
          DesignNavigationMode.bar => StudioNavigationBar._shell(
            details.destinations,
            selectedIndex: details.selectedIndex,
          ),
          DesignNavigationMode.rail => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudioNavigationRail._shell(
                details.destinations,
                selectedIndex: details.selectedIndex,
                leading: header == null
                    ? null
                    : DefaultTextStyle.merge(
                        style: theme.textTheme.caption.copyWith(
                          color: c.legend,
                        ),
                        child: header!,
                      ),
              ),
              seam,
            ],
          ),
          DesignNavigationMode.sidebar => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudioSideNavigation._shell(
                details.destinations,
                selectedIndex: details.selectedIndex,
                header: header,
                footer: navigationFooter,
              ),
              seam,
            ],
          ),
        },
        body: page,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<StudioDestination>('destinations', destinations))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      );
  }
}

// What a standalone part's unused callback is: the shell's places press
// themselves.
void _ignore(int _) {}

// A glyph's data for ui_core's destination: an [Icon]'s, else none (Studio
// paints its destinations' glyphs itself).
IconData _glyphOf(Widget glyph) =>
    glyph is Icon ? glyph.icon ?? _noGlyph : _noGlyph;

const IconData _noGlyph = IconData(0x20);
