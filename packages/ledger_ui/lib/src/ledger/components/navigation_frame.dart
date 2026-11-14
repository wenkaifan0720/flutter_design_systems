import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart' show ShellAction, ShellInsets;

import '../internal/side_inset.dart';
import '../theme.dart';
import 'nav_bar.dart';
import 'side_bar.dart';

/// An app's frame: the current destination's [body] with the navigation
/// the window earns. Under [railFrom] (600) the tab bar stands at the foot
/// ([LedgerNavBar]); from it the rail stands at the start
/// ([LedgerSideBar] with `extended: false`); from [LedgerLayout.wide]
/// (1024) the full side bar with the [brand]'s wordmark. A page under it
/// keeps clear of the bar (a [LedgerScreen] pads for it) and lays its
/// content beside the rail or side bar; beside either, its masthead heads
/// it (the phone's strip is the tab bar's partner only).
///
/// The middle of five [destinations] is the green act (a disc in the tab
/// bar, the side bar's green button); an [action] stands there instead.
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
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < railFrom) {
      final band = LedgerNavBar.bandIn(
        context,
        inset: MediaQuery.paddingOf(context).bottom,
        count: destinations.length,
        action: action != null,
      );
      return Stack(
        children: [
          Positioned.fill(
            child: ShellInsets(bottomInset: band, child: body),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LedgerNavBar(
              items: destinations,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              action: action,
            ),
          ),
        ],
      );
    }
    final extended = width >= LedgerLayout.wide;
    final side = extended ? LedgerSideBar.width : LedgerSideBar.railWidth;
    return Stack(
      children: [
        Positioned.fill(
          child: LedgerSideInset(inset: side, child: body),
        ),
        // The rail or the side bar at the reading start.
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: side,
          child: LedgerSideBar(
            items: destinations,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            action: action,
            brand: brand,
            extended: extended,
          ),
        ),
      ],
    );
  }
}
