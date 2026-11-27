import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../internal/shell_faces.dart';
import '../internal/side_inset.dart';
import '../theme.dart';
import 'nav_bar.dart';
import 'side_bar.dart';

/// An app's frame: its places in a tab bar along a phone's foot
/// ([LedgerNavBar]), in a rail from [railFrom] (600) and in the side bar
/// with the [brand]'s wordmark from [LedgerLayout.wide] (1024)
/// ([LedgerSideBar]), the page above the tab bar or beside the rail or the
/// side bar; beside either, the page's masthead heads it.
///
/// [LedgerAppShell.branches] gives each place its own stack of pages: a page
/// pushed with `Navigator.of(context).push` stands over its place, the rail
/// or the side bar still beside it while a phone's tab bar steps away
/// ([hideBarOnPush]), and back pops it. Choosing the place again goes back
/// to its first page. A page pushed on the app's root navigator covers the
/// whole frame, as a full-screen form does. [LedgerAppShell] stands the
/// app's own [body] instead (an `IndexedStack`, or a router's branches).
///
/// The frame is ui_core's [RawAdaptiveShell] under Ledger's painting: the
/// places are one tab stop, the arrows moving along them (mirrored right to
/// left; Up and Down in the rail and the side bar), Enter or Space choosing;
/// F6 moves the focus between the places and the page; a screen reader hears
/// the tab bar's tabs, each with its place ("Tab 1 of 4"), and the side bar
/// as the navigation menu. The page keeps its state as the window crosses a
/// width, and toasts keep clear of the tab bar.
///
/// The middle of five [destinations] is the green act (a disc in the tab
/// bar, the side bar's green button); an [action] stands there instead (in
/// the tab bar it is a button beside the tabs, not one of them).
///
/// ```dart
/// LedgerAppShell.branches(
///   destinations: const [
///     LedgerNavItem(LucideIcons.house, 'Home'),
///     LedgerNavItem(LucideIcons.list, 'Activity'),
///   ],
///   selectedIndex: index,
///   onDestinationSelected: (i) => setState(() => index = i),
///   brand: 'Quill',
///   branches: [
///     (context) => const HomePage(),
///     (context) => const ActivityPage(),
///   ],
/// )
/// ```
class LedgerAppShell extends StatelessWidget {
  /// The frame around the app's own [body].
  const LedgerAppShell({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required Widget this.body,
    this.brand,
    this.action,
    super.key,
  }) : branches = null,
       navigatorKeys = null,
       backBehavior = RawBranchBackBehavior.firstDestination,
       hideBarOnPush = false;

  /// A frame whose places each keep their own stack of pages, starting on
  /// its [branches] page.
  const LedgerAppShell.branches({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required List<WidgetBuilder> this.branches,
    this.navigatorKeys,
    this.backBehavior = RawBranchBackBehavior.firstDestination,
    this.hideBarOnPush = true,
    this.brand,
    this.action,
    super.key,
  }) : body = null;

  /// The app's places, in the tab bar's order.
  final List<LedgerNavItem> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
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

  /// Whether a phone's tab bar steps away while a page is pushed over a
  /// place ([LedgerAppShell.branches]); the rail and the side bar stay.
  final bool hideBarOnPush;

  /// The app's name, for the side bar's wordmark.
  final String? brand;

  /// The app's act beside its places.
  final LedgerShellAction? action;

  /// The width from which the rail replaces the tab bar.
  static const double railFrom = 600;

  /// How the places stand in a frame [width] wide: the tab bar under
  /// [railFrom], the rail to [LedgerLayout.wide], the side bar from there.
  static RawNavigationMode modeFor(double width) => width < railFrom
      ? RawNavigationMode.bar
      : width >= LedgerLayout.wide
      ? RawNavigationMode.sidebar
      : RawNavigationMode.rail;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<LedgerNavItem>('destinations', destinations))
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
      ..add(EnumProperty<RawBranchBackBehavior>('backBehavior', backBehavior))
      ..add(
        FlagProperty(
          'hideBarOnPush',
          value: hideBarOnPush,
          ifTrue: 'bar hidden on push',
        ),
      )
      ..add(StringProperty('brand', brand, defaultValue: null))
      ..add(
        DiagnosticsProperty<LedgerShellAction>(
          'action',
          action,
          defaultValue: null,
        ),
      );
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
        ),
    ];
    Widget face(
      BuildContext context,
      RawNavigationDestination _,
      RawDestinationDetails details,
    ) => LedgerShellFace(index: details.index, states: details.states);
    Widget navigation(BuildContext context, RawNavigationDetails details) {
      if (details.mode != RawNavigationMode.bar &&
          details.mode != RawNavigationMode.top) {
        return LedgerShellDestinations(
          destinations: details.destinations,
          child: LedgerSideBar(
            items: destinations,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            action: act,
            brand: brand,
            extended: details.mode == RawNavigationMode.sidebar,
          ),
        );
      }
      final bar = LedgerShellDestinations(
        destinations: details.destinations,
        child: LedgerNavBar(
          items: destinations,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          action: act,
        ),
      );
      if (act == null) return bar;
      // The tab bar's act stands among the tabs, but a tab bar holds tabs
      // alone: the tab bar's group stands round the bar, and a screen reader
      // hears the act as a button beside it, over the act's column (a
      // pointer goes through to the act itself). It steps away with the bar.
      final count = destinations.length;
      return LayoutBuilder(
        builder: (context, room) {
          final column =
              (room.maxWidth - 2 * LedgerChromeMetrics.tabBarSide) /
              (count + 1);
          return Stack(
            children: [
              details.group(bar),
              PositionedDirectional(
                start:
                    LedgerChromeMetrics.tabBarSide +
                    LedgerNavBar.discAction(count) * column,
                width: column,
                bottom: 0,
                height: LedgerNavBar.bandIn(
                  context,
                  inset: MediaQuery.paddingOf(context).bottom,
                  count: count,
                  action: true,
                  labels: [
                    for (final item in destinations) item.label,
                    ?act.label,
                  ],
                  width: room.maxWidth,
                ),
                child: Semantics(
                  container: true,
                  button: true,
                  label: act.label,
                  onTap: () => act.onPressed(context),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          );
        },
      );
    }

    final pages = branches;
    // Beside the rail or the side bar the page's masthead heads it.
    return LedgerSideInset(
      inset: 0,
      beside: mode != RawNavigationMode.bar,
      child: pages == null
          ? RawAdaptiveShell(
              mode: mode,
              destinations: raw,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinationBuilder: face,
              navigationBuilder: navigation,
              body: body!,
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
              branches: pages,
            ),
    );
  }
}

/// The old name of [LedgerAppShell].
@Deprecated(
  'Use LedgerAppShell. '
  'This name was deprecated in 0.8.0 and is removed in 1.0.0.',
)
typedef LedgerNavigationFrame = LedgerAppShell;
