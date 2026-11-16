/// The measures Civic's chrome stands on: the top bar and its rule, the
/// phone's navigation bar and the wider window's side navigation. The
/// chrome reads these; a page never does (its spacing is [CivicSpacing]'s,
/// its column [CivicLayout]'s).
///
/// Every control's least target is the design kit's: 48 square where a
/// touch reaches it, 24 for a pointer.
library;

import 'theme.dart';

/// The chrome's measures, by the part that draws them.
abstract final class CivicChromeMetrics {
  /// The top bar's band, under the safe area, its rule aside.
  static const double topBar = 56;

  /// The rule in the action colour under the top bar's band.
  static const double topBarRule = 6;

  /// The phone's navigation bar, the safe area aside.
  static const double navigationBar = 64;

  /// The rail a [CivicScaffold] stands an app's places in, down the start,
  /// from [CivicLayout.medium] to [CivicLayout.expanded] wide.
  static const double navigationRail = 96;

  /// One place of the rail: its glyph over its name.
  static const double railPlace = 72;

  /// The side navigation's column from [CivicLayout.expanded] wide.
  static const double sideNavigation = CivicLayout.sideNavigationWidth;
}
