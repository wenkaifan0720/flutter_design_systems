import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';

import '../theme.dart';

/// Space above and below a service or page title in the app header.
double civicHeaderInset(BuildContext context, TextStyle heading) {
  final fontSize = heading.fontSize ?? 19;
  final line =
      MediaQuery.textScalerOf(context).scale(fontSize) * (heading.height ?? 1);
  return math.max(CivicSpacing.s12, (CivicChromeMetrics.topBar - line) / 2);
}

/// Where [CivicScaffold] stands its top bar's words and its page's column:
/// beside the side navigation, the column at the margin; the bar's words,
/// when the bar spans the places (a scaffold's own side navigation), where
/// the centred frame starts, in line with the places under them, and with
/// the column when the bar stands beside them (an app frame's); with no
/// side navigation, in a frame [CivicLayout.pageWidth] wide centred in a
/// wide window, the bar's words and the column starting where the frame
/// starts.
class CivicFrameScope extends InheritedWidget {
  /// The frame for [child].
  const CivicFrameScope({
    super.key,
    required this.besideNavigation,
    this.barOverNavigation = false,
    required super.child,
  });

  /// Whether the page stands beside the side navigation.
  final bool besideNavigation;

  /// Whether the top bar spans the side navigation as well as the page.
  final bool barOverNavigation;

  /// Whether the page at [context] stands beside the side navigation; false
  /// outside a scaffold.
  static bool besideNavigationOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CivicFrameScope>()
          ?.besideNavigation ??
      false;

  /// The inset from its start a top bar's words take at [context], in a
  /// window [width] wide.
  static double startOf(BuildContext context, double width) {
    final scope = context.dependOnInheritedWidgetOfExactType<CivicFrameScope>();
    if (scope == null || !scope.besideNavigation) {
      return CivicLayout.frameInset(width);
    }
    return scope.barOverNavigation
        ? CivicLayout.frameInset(width)
        : CivicLayout.marginFor(width);
  }

  /// The inset from its end a top bar's actions take at [context], in a
  /// window [width] wide.
  static double endOf(BuildContext context, double width) {
    final scope = context.dependOnInheritedWidgetOfExactType<CivicFrameScope>();
    return scope != null && scope.besideNavigation && !scope.barOverNavigation
        ? CivicLayout.marginFor(width)
        : CivicLayout.frameInset(width);
  }

  @override
  bool updateShouldNotify(CivicFrameScope oldWidget) =>
      oldWidget.besideNavigation != besideNavigation ||
      oldWidget.barOverNavigation != barOverNavigation;
}

/// Marks the band a [CivicScaffold] stands across its top: a top bar there
/// takes the frame's insets ([CivicFrameScope]), its words in line with the
/// page's column; one anywhere else (in the page, a pane, a sheet) stands
/// alone and centres the frame on its own width.
class CivicBarSlot extends InheritedWidget {
  /// The scaffold's top band, [child].
  const CivicBarSlot({super.key, required super.child});

  /// Whether [context] is a scaffold's top band.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CivicBarSlot>() != null;

  @override
  bool updateShouldNotify(CivicBarSlot oldWidget) => false;
}

/// Marks a [CivicNavigationBar] a [CivicScaffold] stands down the start as a
/// rail (from [CivicLayout.medium] to [CivicLayout.expanded] wide) rather
/// than along the bottom.
class CivicRailScope extends InheritedWidget {
  /// The rail for [child], [leading] (an app's one act) over its places.
  const CivicRailScope({super.key, this.leading, required super.child});

  /// What stands over the rail's places.
  final Widget? leading;

  /// The rail's [leading] at [context].
  static Widget? leadingOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CivicRailScope>()?.leading;

  /// Whether the bar at [context] stands as a rail.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CivicRailScope>() != null;

  @override
  bool updateShouldNotify(CivicRailScope oldWidget) =>
      oldWidget.leading != leading;
}
