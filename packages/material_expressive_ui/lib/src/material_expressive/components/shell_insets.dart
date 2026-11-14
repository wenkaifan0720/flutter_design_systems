/// [ExpressiveShellInsets]: the bottom allowance the shell asks each branch
/// root to reserve, apart from the shell itself (`shell.dart`), so a part
/// that keeps clear of the shell's bar (the snackbar) never takes the
/// router the shell stands on.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart' show ShellInsets;

import '../chrome_metrics.dart';

/// The bottom allowance the shell asks each branch root to reserve
/// (CONTRACT §4.2 `ExpressiveShellInsets`): the bar (64dp) + the system's
/// bottom inset + the floating action button's clearance + the docked
/// accessory. The shell publishes it through the design kit's
/// `ShellInsets`; a screen reads it with [of].
abstract final class ExpressiveShellInsets {
  /// The allowance [context]'s page reserves: the shell's on a branch root,
  /// 0 on a pushed page, a sheet, or outside a shell (`ShellInsets.of`).
  static double of(BuildContext context) => ShellInsets.of(context);

  /// The allowance of a phone's shell before it has measured itself: the
  /// bar over [systemInset], the [accessory]'s height, and with an
  /// [action] the floating action button and its 16dp gap.
  static double allowance({
    required double systemInset,
    bool action = false,
    double accessory = 0,
  }) =>
      ExpressiveChromeMetrics.navBarHeight +
      systemInset +
      accessory +
      (action ? ExpressiveChromeMetrics.fabClearance : 0);
}
