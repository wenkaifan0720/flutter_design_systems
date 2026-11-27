/// The app's adaptive shell: its places in Expressive's navigation at every
/// width, on ui_core's `RawAdaptiveShell`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../internal/shell_destinations.dart';
import 'fab.dart';
import 'nav.dart';

/// An app's frame: its places in the flexible navigation bar along a
/// phone's foot ([ExpressiveNavigationBar]), in the collapsed navigation
/// rail from [railFrom] (600dp) and in the expanded rail, its labels beside
/// the icons, from [expandedFrom] (1200dp) ([ExpressiveNavigationRail]):
/// Material's adaptive navigation, the page above the bar or beside the
/// rail.
///
/// [ExpressiveAppShell.branches] gives each place its own stack of pages: a
/// page pushed with `Navigator.of(context).push` stands over its place, the
/// rail still beside it while a phone's bar steps away ([hideBarOnPush]),
/// and back pops it. Choosing the place again goes back to its first page.
/// A page pushed on the app's root navigator covers the whole frame, as a
/// full-screen dialog does. [ExpressiveAppShell] stands the app's own [body]
/// instead (an `IndexedStack`, or a router's branches), and hides the bar
/// with [showNavigation] while a page of its own is pushed.
///
/// The frame is ui_core's [RawAdaptiveShell] under Expressive's painting:
/// the places are one tab stop, the arrows moving along them (mirrored right
/// to left; Up and Down in the rail), Enter or Space choosing; F6 moves the
/// focus between the places and the page; a screen reader hears the bar's
/// tabs, each with its place ("Tab 1 of 3"), and the expanded rail as the
/// navigation menu. The page keeps its state as the window crosses a width,
/// and toasts keep clear of the bar and of the [action].
///
/// The [action] is the app's floating action button: on a phone it stands
/// 16dp in from the end and 16dp above the bar on each place's first page
/// (Compose `Scaffold`'s placement), and a pushed page covers it; from
/// 600dp it heads the rail.
///
/// ```dart
/// ExpressiveAppShell.branches(
///   destinations: const [
///     ExpressiveNavItem(ExpressiveSymbols.home, 'Home'),
///     ExpressiveNavItem(ExpressiveSymbols.search, 'Search'),
///     ExpressiveNavItem(ExpressiveSymbols.settings, 'Settings'),
///   ],
///   selectedIndex: index,
///   onDestinationSelected: (i) => setState(() => index = i),
///   branches: [
///     (context) => const HomePage(),
///     (context) => const SearchPage(),
///     (context) => const SettingsPage(),
///   ],
/// )
/// ```
class ExpressiveAppShell extends StatelessWidget {
  /// The frame around the app's own [body].
  const ExpressiveAppShell({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required Widget this.body,
    this.showNavigation = true,
    this.action,
    super.key,
  }) : branches = null,
       navigatorKeys = null,
       backBehavior = RawBranchBackBehavior.firstDestination,
       hideBarOnPush = false;

  /// A frame whose places each keep their own stack of pages, starting on
  /// its [branches] page.
  const ExpressiveAppShell.branches({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required List<WidgetBuilder> this.branches,
    this.navigatorKeys,
    this.backBehavior = RawBranchBackBehavior.firstDestination,
    this.hideBarOnPush = true,
    this.action,
    super.key,
  }) : body = null,
       showNavigation = true;

  /// The app's places, in the bar's order: three to five on a phone.
  final List<ExpressiveNavItem> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen (the current one again included).
  final ValueChanged<int> onDestinationSelected;

  /// The current place's page, or the router's branches; null with
  /// [branches].
  final Widget? body;

  /// Each place's first page; null with [body].
  final List<WidgetBuilder>? branches;

  /// The places' navigators' keys, to push onto a place from outside (a
  /// notification opening a record); null: the frame's own.
  final List<GlobalKey<NavigatorState>>? navigatorKeys;

  /// Where back goes from a place at its first page: to the first place,
  /// then out of the app.
  final RawBranchBackBehavior backBehavior;

  /// Whether a phone's bar steps away while a page is pushed over a place
  /// ([ExpressiveAppShell.branches]); the rail stays.
  final bool hideBarOnPush;

  /// Whether the bar shows over the app's own [body]: false while a page
  /// of the app's is pushed over a place, and the bar springs away (the
  /// rail stays).
  final bool showNavigation;

  /// The app's main act, an [ExpressiveFloatingActionButton]: above the bar
  /// at the end on each place's first page, at the head of the rail.
  final Widget? action;

  /// The width from which the rail replaces the bar.
  static const double railFrom = ExpressiveChromeMetrics.railMinWindowWidth;

  /// The width from which the rail stands expanded.
  static const double expandedFrom =
      ExpressiveChromeMetrics.expandedRailMinWindowWidth;

  /// How the places stand in a frame [width] wide: the bar under
  /// [railFrom], the rail to [expandedFrom], the expanded rail (the
  /// shell's sidebar) from there.
  static RawNavigationMode modeFor(double width) => width < railFrom
      ? RawNavigationMode.bar
      : width >= expandedFrom
      ? RawNavigationMode.sidebar
      : RawNavigationMode.rail;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<ExpressiveNavItem>('destinations', destinations))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
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
          ifTrue: 'bar hidden on push',
        ),
      )
      ..add(
        FlagProperty(
          'showNavigation',
          value: showNavigation,
          ifFalse: 'navigation hidden',
          defaultValue: true,
        ),
      )
      ..add(DiagnosticsProperty<Widget>('action', action, defaultValue: null));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, room) => _frame(
      context,
      modeFor(
        room.hasBoundedWidth ? room.maxWidth : MediaQuery.sizeOf(context).width,
      ),
    ),
  );

  Widget _frame(BuildContext context, RawNavigationMode mode) {
    final act = action;
    final raw = [
      for (final item in destinations)
        RawNavigationDestination(
          label: item.label,
          icon: item.icon,
          selectedIcon: item.selectedIcon,
          enabled: item.enabled,
        ),
    ];
    Widget face(
      BuildContext context,
      RawNavigationDestination _,
      RawDestinationDetails details,
    ) => ExpressiveShellFace(index: details.index, states: details.states);
    Widget navigation(BuildContext context, RawNavigationDetails details) =>
        ExpressiveShellDestinations(
          destinations: details.destinations,
          group: details.group,
          child:
              details.mode == RawNavigationMode.bar ||
                  details.mode == RawNavigationMode.top
              ? ExpressiveNavigationBar(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                )
              : ExpressiveNavigationRail(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  expanded: details.mode == RawNavigationMode.sidebar,
                  header: act == null
                      ? null
                      : SizedBox(
                          width: ExpressiveChromeMetrics.railWidth,
                          child: Center(child: act),
                        ),
                ),
        );
    final bar = mode == RawNavigationMode.bar;
    // On a phone the action stands over each place's first page, above the
    // bar at the end.
    Widget page(Widget child) =>
        bar && act != null ? _ActionOver(action: act, child: child) : child;
    final pages = branches;
    return pages == null
        ? RawAdaptiveShell(
            mode: mode,
            showNavigation: showNavigation,
            destinations: raw,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinationBuilder: face,
            navigationBuilder: navigation,
            body: page(body!),
          )
        : RawAdaptiveShell.branches(
            mode: mode,
            hideBarOnPush: hideBarOnPush,
            backBehavior: backBehavior,
            navigatorKeys: navigatorKeys,
            destinations: raw,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinationBuilder: face,
            navigationBuilder: navigation,
            branches: [
              for (final branch in pages) (context) => page(branch(context)),
            ],
          );
  }
}

/// [child] with the shell's [action] 16dp in from its end and 16dp above
/// its foot (Compose `Scaffold`'s FAB placement). The action and the room
/// under it stand on the bar, so toasts keep above both, as Material's
/// `Scaffold` lifts a floating snackbar over its FAB.
class _ActionOver extends StatelessWidget {
  const _ActionOver({required this.action, required this.child});

  final Widget action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final end = Directionality.of(context) == TextDirection.ltr
        ? padding.right
        : padding.left;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        PositionedDirectional(
          end: end + ExpressiveChromeMetrics.fabMargin,
          bottom: padding.bottom,
          child: RawToasterKeepClear(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: ExpressiveChromeMetrics.fabMargin,
              ),
              child: action,
            ),
          ),
        ),
      ],
    );
  }
}
