/// Dimensions for Civic’s top bar, bottom navigation and side navigation.
/// Values are logical pixels and exclude the device safe area.
library;

import 'theme.dart';

/// The chrome's measures, by the part that draws them.
abstract final class CivicChromeMetrics {
  /// Minimum height of the title band, excluding the safe area and bottom rule.
  static const double topBar = 56;

  /// The rule in the action colour under the top bar's band.
  static const double topBarRule = 6;

  /// Minimum height of a row in the bottom navigation, excluding the safe area.
  static const double navigationBar = 64;

  /// The rail a [CivicScaffold] stands an app's places in, down the start,
  /// from [CivicLayout.medium] to [CivicLayout.expanded] wide.
  static const double navigationRail = 96;

  /// Minimum height of a rail destination.
  static const double railPlace = 72;

  /// The side navigation's column from [CivicLayout.expanded] wide.
  static const double sideNavigation = CivicLayout.sideNavigationWidth;
}
