import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart' show ShellAction;

import '../chrome_metrics.dart';
import '../internal/shell_faces.dart';
import '../internal/side_inset.dart';
import '../theme.dart';
import 'nav_bar.dart';
import 'side_bar.dart';

/// An app's frame: the current destination's [body] with the navigation
/// the window earns. Under [railFrom] (600) the tab bar stands at the foot
/// ([LedgerNavBar]); from it the rail stands at the start
/// ([LedgerSideBar] with `extended: false`); from [LedgerLayout.wide]
/// (1024) the full side bar with the [brand]'s wordmark. The page stands
/// above the tab bar or beside the rail or side bar; beside either, its
/// masthead heads it (the phone's strip is the tab bar's partner only).
///
/// The frame is ui_core's [DesignAdaptiveShell], Ledger's bars painting
/// it: the destinations are one tab stop, the arrows moving along them
/// (mirrored right to left; Up and Down in the rail and the side bar),
/// Enter or Space choosing; F6 moves the focus between the bar and the
/// page; a screen reader hears the tab bar's tabs, each with its place
/// ("Tab 1 of 4"), and the side bar as the navigation menu. The page keeps
/// its state as the window crosses a width.
///
/// The middle of five [destinations] is the green act (a disc in the tab
/// bar, the side bar's green button); an [action] stands there instead (in
/// the tab bar it is a button beside the tabs, not one of them).
/// Pages pushed over the frame (a record) cover it, as the source's do.
///
/// ```dart
/// LedgerNavigationFrame(destinations: tabs, selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), brand: 'Quill', body: pages[tab])
/// ```
class LedgerNavigationFrame extends StatelessWidget {
  /// An app's frame: [body] with the navigation the window earns.
  const LedgerNavigationFrame({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.brand,
    this.action,
    super.key,
  });

  /// The app's destinations, in the tab bar's order.
  final List<LedgerNavItem> destinations;

  /// The current destination.
  final int selectedIndex;

  /// Called with the destination chosen.
  final ValueChanged<int> onDestinationSelected;

  /// The current destination's page.
  final Widget body;

  /// The app's name, for the side bar's wordmark.
  final String? brand;

  /// The app's act beside its destinations.
  final ShellAction? action;

  /// The width from which the rail replaces the tab bar.
  static const double railFrom = 600;

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
      ..add(StringProperty('brand', brand, defaultValue: null))
      ..add(
        DiagnosticsProperty<ShellAction>('action', action, defaultValue: null),
      );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mode = width < railFrom
        ? DesignNavigationMode.bar
        : width >= LedgerLayout.wide
        ? DesignNavigationMode.sidebar
        : DesignNavigationMode.rail;
    final shell = DesignAdaptiveShell(
      mode: mode,
      destinations: [
        for (final item in destinations)
          DesignNavigationDestination(
            label: item.label,
            icon: item.icon,
            selectedIcon: item.selectedIcon,
          ),
      ],
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinationBuilder: (context, _, details) =>
          LedgerShellFace(index: details.index, states: details.states),
      navigationBuilder: (context, details) => LedgerShellDestinations(
        destinations: details.destinations,
        child: details.mode == DesignNavigationMode.bar
            ? LedgerNavBar(
                items: destinations,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                action: action,
              )
            : SizedBox(
                width: details.mode == DesignNavigationMode.sidebar
                    ? LedgerSideBar.width
                    : LedgerSideBar.railWidth,
                child: LedgerSideBar(
                  items: destinations,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  action: action,
                  brand: brand,
                  extended: details.mode == DesignNavigationMode.sidebar,
                ),
              ),
      ),
      // Beside the rail or the side bar the page's masthead heads it.
      body: LedgerSideInset(
        inset: 0,
        beside: mode != DesignNavigationMode.bar,
        child: body,
      ),
    );
    final act = action;
    if (mode != DesignNavigationMode.bar || act == null) return shell;
    // The tab bar's act stands among the tabs, but ui_core's tab bar holds
    // tabs alone: a screen reader hears the act as a button beside it, over
    // the act's column (a pointer goes through to the act itself).
    final count = destinations.length;
    return LayoutBuilder(
      builder: (context, room) {
        final column =
            (room.maxWidth - 2 * LedgerChromeMetrics.tabBarSide) / (count + 1);
        return Stack(
          children: [
            Positioned.fill(child: shell),
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
}
