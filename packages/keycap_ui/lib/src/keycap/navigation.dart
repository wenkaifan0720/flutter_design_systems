/// Keycap's way round an app. The places are legends printed on the case;
/// the current place is a modifier key latched down under its legend. A
/// phone has them in a row at its foot, a tablet in a rail, a desktop in a
/// side column. A top bar is a strip of the case with the page's name and
/// a back key.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'cap.dart';
import 'theme.dart';

/// A page's top bar: a strip of the case holding a back key (or [leading]),
/// the page's [title] and its [actions].
///
/// ```dart
/// KeycapAppBar(title: 'Settings', onBack: () => Navigator.pop(context))
/// ```
class KeycapAppBar extends StatelessWidget {
  /// A top bar.
  const KeycapAppBar({
    super.key,
    this.title,
    this.onBack,
    this.leading,
    this.actions = const [],
    this.bottom,
    this.style,
  });

  /// The page's name.
  final String? title;

  /// Called by the back key; shows one when given.
  final VoidCallback? onBack;

  /// A key at the bar's start, when there is no back key.
  final Widget? leading;

  /// Keys at the bar's end.
  final List<Widget> actions;

  /// A row under the bar (a tab bar, a search field).
  final Widget? bottom;

  /// Overrides, over [KeycapThemeData.appBarStyle]: [RawStyle.foreground]
  /// the title's colour, [RawStyle.textStyle] its style,
  /// [RawStyle.padding] the bar's.
  final KeycapStyle? style;

  /// The bar's height, under the status bar.
  static const double height = 60;

  /// The side of a key in the bar.
  static const double keySide = 40;

  /// A back key: a square key with an arrow pointing against the reading
  /// direction.
  static Widget backKey(BuildContext context, VoidCallback onBack) =>
      KeycapIconButton(
        icon: Transform.flip(
          flipX: Directionality.of(context) == TextDirection.rtl,
          child: const Icon(LucideIcons.arrowLeft),
        ),
        semanticLabel: RawWidgetsLocalizations.of(context).backButtonTooltip,
        onPressed: onBack,
        style: const RawStyle(
          minimumSize: WidgetStatePropertyAll(Size.square(keySide)),
        ),
      );

  /// A close key, for a page raised as a sheet.
  static Widget closeKey(BuildContext context, VoidCallback onClose) =>
      KeycapIconButton(
        icon: const Icon(LucideIcons.x),
        semanticLabel: RawWidgetsLocalizations.of(context).closeButtonLabel,
        onPressed: onClose,
        style: const RawStyle(
          minimumSize: WidgetStatePropertyAll(Size.square(keySide)),
        ),
      );

  /// The key the route at [context] wants at a bar's start: back on a
  /// pushed page, close on a sheet, none on a root page.
  static Widget? autoLeading(BuildContext context) {
    final presentation = RoutePresentation.of(context);
    if (presentation == RoutePresentation.root) return null;
    void leave() => Navigator.of(context).maybePop();
    return presentation == RoutePresentation.sheet
        ? closeKey(context, leave)
        : backKey(context, leave);
  }

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final layered = RawStyleOf([style, theme.appBarStyle], const {});
    final media = MediaQuery.of(context);
    final margin = KeycapSpacing.pageMargin(media.size.width);
    final start = onBack != null ? backKey(context, onBack!) : leading;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: ColoredBox(
        color: layered.fill ?? theme.colors.ground,
        child: Padding(
          padding:
              layered.padding(Directionality.of(context)) ??
              EdgeInsets.fromLTRB(margin, media.padding.top, margin, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: height,
                child: Row(
                  children: [
                    if (start != null) ...[
                      start,
                      const SizedBox(width: KeycapSpacing.medium),
                    ],
                    Expanded(
                      child: title == null
                          ? const SizedBox()
                          : Semantics(
                              header: true,
                              child: RawCapCenter(
                                capHeightFactor: theme.capHeightFactor,
                                child: Text(
                                  title!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.heading
                                      .merge(layered.textStyle)
                                      .copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: layered.foreground,
                                      ),
                                ),
                              ),
                            ),
                    ),
                    for (final (i, action) in actions.indexed) ...[
                      SizedBox(
                        width: i == 0
                            ? KeycapSpacing.medium
                            : KeycapMetrics.keyGap * 2,
                      ),
                      action,
                    ],
                  ],
                ),
              ),
              if (bottom != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: KeycapSpacing.medium),
                  child: bottom,
                ),
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
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(FlagProperty('back', value: onBack != null, ifTrue: 'back'))
      ..add(IntProperty('actions', actions.length));
  }
}

/// One place in an app's navigation.
///
/// ```dart
/// const KeycapDestination(icon: LucideIcons.notebook, label: 'Notes')
/// ```
@immutable
class KeycapDestination {
  /// A place.
  const KeycapDestination({required this.icon, required this.label, this.key});

  /// Its glyph.
  final IconData icon;

  /// Its name.
  final String label;

  /// A key for its legend, for a test to find it by.
  final Key? key;
}

// A place's legend: printed on the case, a modifier key latched under it
// when it is the current place, a key going down under it while pressed.
KeycapFace _placeFace(
  KeycapThemeData theme,
  Set<WidgetState> states,
  bool current,
) {
  final c = theme.colors;
  final pressed = states.contains(WidgetState.pressed);
  final focused = states.contains(WidgetState.focused);
  final off = states.contains(WidgetState.disabled);
  if (current || pressed) {
    final face = keycapKeyFace(theme, KeycapKind.modifier, {
      if (pressed) WidgetState.pressed,
      if (focused) WidgetState.focused,
    }, latched: current);
    return current ? face : face.copyWith(legend: c.ink);
  }
  KeycapCapColors clear(KeycapCapColors k) => k.copyWith(
    top: k.top.withValues(alpha: 0),
    wall: k.wall.withValues(alpha: 0),
    front: k.front.withValues(alpha: 0),
  );
  final none = clear(c.modifier);
  return KeycapFace.of(none, c).copyWith(
    legend: off ? c.inkDisabled : c.inkMuted,
    edge: c.edge.withValues(alpha: 0),
    shadow: c.shadow.withValues(alpha: 0),
    focus: focused ? c.focus : c.focus.withValues(alpha: 0),
  );
}

Widget _stackedLegend(
  BuildContext context,
  KeycapDestination d,
  KeycapFace face,
  bool current,
) {
  final theme = KeycapTheme.of(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(d.icon, size: 20, color: face.legend),
      const SizedBox(height: KeycapSpacing.tight),
      // A name is never cut short: past its key's width it prints smaller.
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            d.label,
            maxLines: 1,
            textAlign: TextAlign.center,
            textScaler: _placeNameScaler(context),
            style: theme.textTheme.legend.copyWith(
              letterSpacing: 0.2,
              color: face.legend,
              fontWeight: current ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _rowLegend(
  BuildContext context,
  KeycapDestination d,
  KeycapFace face,
  bool current,
) {
  final theme = KeycapTheme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: KeycapSpacing.medium),
    child: Row(
      children: [
        Icon(d.icon, size: 20, color: face.legend),
        const SizedBox(width: KeycapSpacing.medium),
        Expanded(
          child: RawCapCenter(
            capHeightFactor: theme.capHeightFactor,
            child: Text(
              d.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.label.copyWith(
                color: current ? face.legend : theme.colors.ink,
                fontWeight: current ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// A place's name in a bar or a rail grows a third at most: five names share
// a phone's width, and each stays whole, printing smaller past its key's
// width (the side column carries them at full size from 1024).
TextScaler _placeNameScaler(BuildContext context) =>
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);

// A place's key in a phone's bar: its glyph over its name.
Widget _barKey(
  BuildContext context,
  KeycapDestination d,
  Set<WidgetState> states,
  bool current,
) => TapTargetPadding(
  child: _placeKey(
    context,
    states,
    current,
    KeycapNavigationBar.keyHeight,
    (face) => _stackedLegend(context, d, face, current),
  ),
);

Widget _placeKey(
  BuildContext context,
  Set<WidgetState> states,
  bool current,
  double height,
  Widget Function(KeycapFace face) legend, {
  double? width,
  bool stacked = true,
}) {
  final theme = KeycapTheme.of(context);
  final face = _placeFace(theme, states, current);
  // Taller as its name grows: a stacked name (a bar's, a rail's) grows a
  // third at most, a side column's row of words grows in full.
  final tall = stacked
      ? KeycapMetrics.grown(
          context,
          height,
          theme.textTheme.legend,
          scaler: _placeNameScaler(context),
        )
      : KeycapMetrics.grown(context, height, theme.textTheme.label);
  return SizedBox(
    width: width,
    height: tall,
    child: AnimatedKeycapCap(
      face: face,
      walls: KeycapMetrics.walls(tall),
      child: Center(child: legend(face)),
    ),
  );
}

/// A phone's navigation: the places in a row at the screen's foot.
///
/// ```dart
/// KeycapNavigationBar(destinations: places, selectedIndex: at, onDestinationSelected: go)
/// ```
class KeycapNavigationBar extends StatelessWidget {
  /// A row of places.
  const KeycapNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.style,
  }) : _keys = null;

  // The strip round keys [KeycapScaffold]'s shell has built.
  const KeycapNavigationBar._shell(List<Widget> this._keys)
    : destinations = const [],
      selectedIndex = 0,
      onDestinationSelected = KeycapNavigationRail._ignore,
      style = null;

  final List<Widget>? _keys;

  /// The places.
  final List<KeycapDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onDestinationSelected;

  /// Overrides, over [KeycapThemeData.navigationStyle]: [RawStyle.fill]
  /// the strip's colour.
  final KeycapStyle? style;

  /// A place's key's height.
  static const double keyHeight = 52;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final layered = RawStyleOf([style, theme.navigationStyle], const {});
    final media = MediaQuery.of(context);
    final keys =
        _keys ??
        [
          for (final (i, d) in destinations.indexed)
            KeyedSubtree(
              key: d.key,
              child: RawButton(
                onPressed: () => onDestinationSelected(i),
                selected: i == selectedIndex,
                semanticSelected: i == selectedIndex,
                semanticLabel: d.label,
                excludeSemantics: true,
                builder: (context, states, _) =>
                    _barKey(context, d, states, i == selectedIndex),
              ),
            ),
        ];
    final Widget strip = DecoratedBox(
      decoration: BoxDecoration(
        color: layered.fill ?? theme.colors.ground,
        border: Border(top: BorderSide(color: theme.colors.hairline)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          KeycapSpacing.small,
          KeycapSpacing.small,
          KeycapSpacing.small,
          KeycapSpacing.small + media.padding.bottom,
        ),
        child: Row(
          children: [
            for (final k in keys)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KeycapMetrics.keyGap / 2,
                  ),
                  child: k,
                ),
              ),
          ],
        ),
      ),
    );
    // In the shell the strip is ui_core's tab bar, its keys its tabs; alone
    // it keeps its keys' nodes together.
    if (_keys != null) return strip;
    return Semantics(container: true, explicitChildNodes: true, child: strip);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('destinations', destinations.length))
      ..add(IntProperty('selectedIndex', selectedIndex));
  }
}

/// A tablet's navigation: the places stacked down a rail at the screen's
/// start, an [action] key over them. Most apps want [KeycapScaffold], which
/// chooses it by width.
///
/// ```dart
/// KeycapNavigationRail(destinations: places, selectedIndex: at, onDestinationSelected: go)
/// ```
class KeycapNavigationRail extends StatelessWidget {
  /// A rail of places.
  const KeycapNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.action,
  }) : _keys = null;

  const KeycapNavigationRail._shell(List<Widget> this._keys, {this.action})
    : destinations = const [],
      selectedIndex = 0,
      onDestinationSelected = _ignore;

  static void _ignore(int _) {}

  /// The places.
  final List<KeycapDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onDestinationSelected;

  /// A key over the places (a screen's main action).
  final Widget? action;

  final List<Widget>? _keys;

  /// The rail's width.
  static const double width = 88;

  /// A place's key's size.
  static const Size keySize = Size(68, 56);

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final media = MediaQuery.of(context);
    final keys =
        _keys ??
        [
          for (final (i, d) in destinations.indexed)
            KeyedSubtree(
              key: d.key,
              child: RawButton(
                onPressed: () => onDestinationSelected(i),
                selected: i == selectedIndex,
                semanticSelected: i == selectedIndex,
                semanticLabel: d.label,
                excludeSemantics: true,
                builder: (context, states, _) => _placeKey(
                  context,
                  states,
                  i == selectedIndex,
                  keySize.height,
                  (face) =>
                      _stackedLegend(context, d, face, i == selectedIndex),
                  width: keySize.width,
                ),
              ),
            ),
        ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.ground,
        border: BorderDirectional(
          end: BorderSide(color: theme.colors.hairline),
        ),
      ),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: EdgeInsets.only(
            top: media.padding.top + KeycapSpacing.regular,
            bottom: media.padding.bottom + KeycapSpacing.regular,
          ),
          child: Column(
            children: [
              if (action != null) ...[
                action!,
                const SizedBox(height: KeycapSpacing.large),
              ],
              for (final (i, k) in keys.indexed) ...[
                if (i > 0) const SizedBox(height: KeycapMetrics.keyGap * 2),
                k,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A desktop's navigation: a column at the screen's start, a [header] over
/// the places and a [footer] under them; the current place a wide
/// modifier key latched under its legend.
///
/// ```dart
/// KeycapSideNavigation(destinations: places, selectedIndex: at, onDestinationSelected: go, header: Text('Shelf'))
/// ```
class KeycapSideNavigation extends StatelessWidget {
  /// A column of places.
  const KeycapSideNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.header,
    this.action,
    this.footer,
  }) : _keys = null;

  const KeycapSideNavigation._shell(
    List<Widget> this._keys, {
    this.header,
    this.action,
    this.footer,
  }) : destinations = const [],
       selectedIndex = 0,
       onDestinationSelected = KeycapNavigationRail._ignore;

  /// The places.
  final List<KeycapDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onDestinationSelected;

  /// What stands over the places (the app's name).
  final Widget? header;

  /// A key under the header (a screen's main action).
  final Widget? action;

  /// What stands at the column's foot.
  final Widget? footer;

  final List<Widget>? _keys;

  /// The column's width.
  static const double width = 264;

  /// A place's key's height.
  static const double keyHeight = 44;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final media = MediaQuery.of(context);
    final keys =
        _keys ??
        [
          for (final (i, d) in destinations.indexed)
            KeyedSubtree(
              key: d.key,
              child: RawButton(
                onPressed: () => onDestinationSelected(i),
                selected: i == selectedIndex,
                semanticSelected: i == selectedIndex,
                semanticLabel: d.label,
                excludeSemantics: true,
                builder: (context, states, _) => _placeKey(
                  context,
                  states,
                  i == selectedIndex,
                  keyHeight,
                  (face) => _rowLegend(context, d, face, i == selectedIndex),
                  stacked: false,
                ),
              ),
            ),
        ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.ground,
        border: BorderDirectional(
          end: BorderSide(color: theme.colors.hairline),
        ),
      ),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            KeycapSpacing.regular,
            media.padding.top + KeycapSpacing.large,
            KeycapSpacing.regular,
            media.padding.bottom + KeycapSpacing.regular,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: KeycapSpacing.medium,
                    bottom: KeycapSpacing.large,
                  ),
                  child: header,
                ),
              if (action != null) ...[
                action!,
                const SizedBox(height: KeycapSpacing.large),
              ],
              for (final (i, k) in keys.indexed) ...[
                if (i > 0) const SizedBox(height: KeycapMetrics.keyGap),
                k,
              ],
              const Spacer(),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}

/// An app's frame: its places in a bar at a phone's foot below 600 wide,
/// down a rail to 1024, in a side column wider ([modeForWidth] moves those
/// widths), and its pages beside them, at every width on ui_core's
/// `RawAdaptiveShell`. A screen reader hears the places as tabs ("Tags,
/// tab 2 of 3"), the chosen one selected; the arrows move along them and F6
/// moves between them and the page. A toast stands above the phone's bar.
///
/// [KeycapScaffold.branches] keeps a stack of pages for each place: a page
/// pushed on one (`Navigator.of(context).push`) keeps the rail or the side
/// column beside it while the phone's bar steps away, and back pops it.
/// [KeycapScaffold] stands round the app's own [body] (an `IndexedStack`,
/// a router's shell), and [showNavigation] hides the phone's bar.
///
/// ```dart
/// KeycapScaffold.branches(destinations: const [KeycapDestination(icon: LucideIcons.notebook, label: 'Notes'), KeycapDestination(icon: LucideIcons.tag, label: 'Tags')], selectedIndex: place, onDestinationSelected: (i) => setState(() => place = i), branches: [(context) => const NotesPage(), (context) => const TagsPage()])
/// ```
class KeycapScaffold extends StatelessWidget {
  /// The app's places round its own [body].
  const KeycapScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required Widget this.body,
    this.header,
    this.action,
    this.wideAction,
    this.sideFooter,
    this.showNavigation = true,
    this.modeForWidth = KeycapScaffold.modeFor,
  }) : branches = null,
       navigatorKeys = null,
       backBehavior = RawBranchBackBehavior.firstDestination,
       hideBarOnPush = false;

  /// The app's places, each with a stack of pages of its own, starting on
  /// its [branches] page.
  const KeycapScaffold.branches({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required List<WidgetBuilder> this.branches,
    this.navigatorKeys,
    this.backBehavior = RawBranchBackBehavior.firstDestination,
    this.hideBarOnPush = true,
    this.header,
    this.action,
    this.wideAction,
    this.sideFooter,
    this.showNavigation = true,
    this.modeForWidth = KeycapScaffold.modeFor,
  }) : body = null;

  /// Keycap's places for a shell [width] wide: the bar under 600, the rail
  /// to 1024, the side column past it.
  static RawNavigationMode modeFor(double width) => width < 600
      ? RawNavigationMode.bar
      : width < 1024
      ? RawNavigationMode.rail
      : RawNavigationMode.sidebar;

  /// The places.
  final List<KeycapDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onDestinationSelected;

  /// The app's own pages ([KeycapScaffold]); null for
  /// [KeycapScaffold.branches].
  final Widget? body;

  /// Each place's first page ([KeycapScaffold.branches]); null round a
  /// [body].
  final List<WidgetBuilder>? branches;

  /// The places' navigators, to push onto one from outside it (a
  /// notification opening a page).
  final List<GlobalKey<NavigatorState>>? navigatorKeys;

  /// Where back goes from a place's first page.
  final RawBranchBackBehavior backBehavior;

  /// Whether the phone's bar steps away while a page is pushed over a
  /// place's first page; the rail and the side column stay.
  final bool hideBarOnPush;

  /// The side column's header (from 1024).
  final Widget? header;

  /// A square key over the rail's places (600 to 1024): the main action.
  final Widget? action;

  /// The same action as a key with words, under the side column's header
  /// (from 1024).
  final Widget? wideAction;

  /// The side column's foot.
  final Widget? sideFooter;

  /// Whether a phone's bar stands: false while a page of the app's own
  /// covers a root (a rail or a side column stays).
  final bool showNavigation;

  /// How the places show for the shell's width: [modeFor] by default.
  final RawNavigationModeForWidth modeForWidth;

  Widget _destination(
    BuildContext context,
    RawNavigationDestination _,
    RawDestinationDetails details,
  ) {
    final d = destinations[details.index];
    final current = details.index == selectedIndex;
    return KeyedSubtree(
      key: d.key,
      child: switch (details.mode) {
        RawNavigationMode.bar => _barKey(context, d, details.states, current),
        RawNavigationMode.rail || RawNavigationMode.top => _placeKey(
          context,
          details.states,
          current,
          KeycapNavigationRail.keySize.height,
          (face) => _stackedLegend(context, d, face, current),
          width: KeycapNavigationRail.keySize.width,
        ),
        RawNavigationMode.sidebar => _placeKey(
          context,
          details.states,
          current,
          KeycapSideNavigation.keyHeight,
          (face) => _rowLegend(context, d, face, current),
          stacked: false,
        ),
      },
    );
  }

  Widget _navigation(BuildContext context, RawNavigationDetails details) =>
      switch (details.mode) {
        RawNavigationMode.bar => KeycapNavigationBar._shell(
          details.destinations,
        ),
        RawNavigationMode.rail || RawNavigationMode.top =>
          KeycapNavigationRail._shell(details.destinations, action: action),
        RawNavigationMode.sidebar => KeycapSideNavigation._shell(
          details.destinations,
          header: header,
          action: wideAction ?? action,
          footer: sideFooter,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final destinations = [
      for (final d in this.destinations)
        RawNavigationDestination(label: d.label, icon: d.icon),
    ];
    final branches = this.branches;
    if (branches != null) {
      return RawAdaptiveShell.branches(
        modeForWidth: modeForWidth,
        showNavigation: showNavigation,
        hideBarOnPush: hideBarOnPush,
        backBehavior: backBehavior,
        navigatorKeys: navigatorKeys,
        dampingRatio: KeycapMotion.panel.dampingRatio,
        stiffness: KeycapMotion.panel.stiffness,
        destinations: destinations,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinationBuilder: _destination,
        navigationBuilder: _navigation,
        branches: branches,
      );
    }
    return RawAdaptiveShell(
      modeForWidth: modeForWidth,
      showNavigation: showNavigation,
      dampingRatio: KeycapMotion.panel.dampingRatio,
      stiffness: KeycapMotion.panel.stiffness,
      destinations: destinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinationBuilder: _destination,
      navigationBuilder: _navigation,
      // The body keeps its children's nodes apart. A Navigator here would
      // otherwise hang its route's node off this one, and a list opening
      // over the route gives the route a node between them: on the web the
      // focused field's input moves into it and the browser blurs it, so the
      // tap that opened the list loses focus.
      body: Semantics(container: true, explicitChildNodes: true, child: body),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('destinations', destinations.length))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(IntProperty('branches', branches?.length, defaultValue: null))
      ..add(
        EnumProperty<RawBranchBackBehavior>(
          'backBehavior',
          backBehavior,
          defaultValue: RawBranchBackBehavior.firstDestination,
        ),
      )
      ..add(
        FlagProperty(
          'showNavigation',
          value: showNavigation,
          ifFalse: 'navigation hidden',
        ),
      );
  }
}

/// A page on the case: its [topBar], its [body] inside the page margin (16
/// on a phone, 24 on a tablet, 32 on a desktop) and at most [maxWidth]
/// wide on its start edge (under the bar's title), scrolling, and a
/// [footer] of keys at its foot, on the same column: from 600 wide at the
/// column's end.
///
/// ```dart
/// KeycapScreen(topBar: const KeycapAppBar(title: 'Settings'), body: settings)
/// ```
class KeycapScreen extends StatelessWidget {
  /// A page.
  const KeycapScreen({
    super.key,
    required this.body,
    this.topBar,
    this.footer,
    this.scroll = true,
    this.fullBleed = false,
    this.maxWidth = pageWidth,
    this.scrollController,
  });

  /// The page's content.
  final Widget body;

  /// Its top bar.
  final Widget? topBar;

  /// Keys at its foot (a form's Save).
  final Widget? footer;

  /// Whether the body scrolls.
  final bool scroll;

  /// Whether the body runs edge to edge, with no margin.
  final bool fullBleed;

  /// The widest the body stands.
  final double maxWidth;

  /// The body's scroll controller.
  final ScrollController? scrollController;

  /// The widest a page's content stands by default.
  static const double pageWidth = 1040;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final media = MediaQuery.of(context);
    final margin = KeycapSpacing.pageMargin(media.size.width);
    final bar = topBar;
    final foot = footer;
    final top = bar == null ? media.padding.top : 0.0;
    final bottom = foot == null ? media.padding.bottom : 0.0;
    final Widget page = fullBleed
        ? body
        : Padding(
            padding: EdgeInsets.fromLTRB(
              margin,
              (bar == null ? KeycapSpacing.large : KeycapSpacing.small) + top,
              margin,
              // A scrolling page's last row clears the foot by a huge step;
              // a page that fills the window ends a large step above it.
              (scroll ? KeycapSpacing.huge : KeycapSpacing.large) + bottom,
            ),
            child: body,
          );
    final Widget column = fullBleed
        ? page
        // On the page's start edge, under the top bar's title: one margin
        // from the bar to the last row, whatever the window's width.
        : Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: scroll ? 1 : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth + 2 * margin),
              child: page,
            ),
          );
    final Widget content = scroll
        ? SingleChildScrollView(
            controller: scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: column,
          )
        : column;
    return ColoredBox(
      color: theme.colors.ground,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: _UnderBar(
          rule: theme.colors.hairline,
          // The bar's title and keys stand over the content's column.
          bar: bar == null
              ? null
              : fullBleed
              ? bar
              : Align(
                  alignment: AlignmentDirectional.topStart,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth + 2 * margin,
                    ),
                    child: bar,
                  ),
                ),
          content: content,
          // The foot, ruled along its top. A toast stands above it, as a
          // Scaffold keeps a snackbar above its persistent footer buttons.
          foot: foot == null
              ? null
              : RawToasterKeepClear(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colors.ground,
                      border: Border(
                        top: BorderSide(color: theme.colors.hairline),
                      ),
                    ),
                    // Its keys stand on the content's column: from 600 wide at
                    // the column's end, under the last field, not the window's.
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: fullBleed
                              ? double.infinity
                              : maxWidth + 2 * margin,
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            margin,
                            KeycapSpacing.medium,
                            margin,
                            KeycapSpacing.medium + media.padding.bottom,
                          ),
                          child: media.size.width >= 600
                              ? Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: foot,
                                )
                              : foot,
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
      ..add(FlagProperty('scroll', value: scroll, ifTrue: 'scroll'))
      ..add(FlagProperty('fullBleed', value: fullBleed, ifTrue: 'fullBleed'));
  }
}

// A page's bar over its content and its foot under it. While the content
// has scrolled under the bar, the bar is ruled along its foot, as the foot
// is along its top, so a row cut at the bar's edge reads as going on above.
class _UnderBar extends StatefulWidget {
  const _UnderBar({
    required this.rule,
    required this.bar,
    required this.content,
    required this.foot,
  });

  final Color rule;
  final Widget? bar;
  final Widget content;
  final Widget? foot;

  @override
  State<_UnderBar> createState() => _UnderBarState();
}

class _UnderBarState extends State<_UnderBar> {
  bool _under = false;

  bool _scrolled(Notification notification) {
    final metrics = switch (notification) {
      ScrollUpdateNotification(depth: 0, :final metrics) => metrics,
      ScrollMetricsNotification(depth: 0, :final metrics) => metrics,
      _ => null,
    };
    if (metrics != null && metrics.axis == Axis.vertical) {
      final under = metrics.extentBefore > 0;
      if (under != _under) setState(() => _under = under);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bar = widget.bar;
    final foot = widget.foot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (bar != null)
          DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _under
                      ? widget.rule
                      : widget.rule.withValues(alpha: 0),
                ),
              ),
            ),
            child: bar,
          ),
        Expanded(
          child: NotificationListener<Notification>(
            onNotification: _scrolled,
            child: widget.content,
          ),
        ),
        ?foot,
      ],
    );
  }
}

/// A short title printed on the case over a page's content, with an
/// optional line under it: the page's name where it has no top bar title.
///
/// ```dart
/// const KeycapPageTitle('Notes', subtitle: '42 notes in 5 folders')
/// ```
class KeycapPageTitle extends StatelessWidget {
  /// A page title.
  const KeycapPageTitle(this.text, {super.key, this.subtitle, this.trailing});

  /// The title.
  final String text;

  /// A line under it.
  final String? subtitle;

  /// A key at its end.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final words = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(text, style: theme.textTheme.title),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: KeycapSpacing.tight),
            child: Text(subtitle!, style: theme.textTheme.secondary),
          ),
      ],
    );
    if (trailing == null) return words;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: words),
        const SizedBox(width: KeycapSpacing.regular),
        trailing!,
      ],
    );
  }
}
