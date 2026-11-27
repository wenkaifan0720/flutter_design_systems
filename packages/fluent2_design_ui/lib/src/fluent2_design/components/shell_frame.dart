// The shell's frame without its router: the act it floats and the bottom
// allowance it asks a branch root to reserve. The preview, the screen and the
// toast read these, so they stand without go_router.
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart'
    show ChromeGround, NavTab, ShellAction, ShellInsets;

import '../chrome_metrics.dart';
import 'app_shell.dart';
import 'nav_bar.dart';

/// The bottom allowance the shell asks each branch root to reserve: the
/// tab bar over the device inset, the act and any accessory over it. The
/// shell publishes it through the shared `ShellInsets`; a screen
/// reads it with [of].
abstract final class Fluent2ShellInsets {
  /// The allowance [context]'s page reserves: the shell's on a branch
  /// root, 0 on a pushed page, a sheet, at desktop width, or outside a
  /// shell (`ShellInsets.of`).
  static double of(BuildContext context) => ShellInsets.of(context);

  /// The allowance of a shell before it has measured itself.
  static double allowance({
    required double systemInset,
    bool action = false,
    double accessory = 0,
  }) =>
      fluent2BarAllowance(systemInset, action: action) +
      (accessory > 0 ? accessory + Fluent2ChromeMetrics.accessoryGap : 0);
}

/// The app's act a declared shell names, as the look's bar and pane take it.
Fluent2ShellAction? fluent2ActionOf(ShellAction? action) => action == null
    ? null
    : Fluent2ShellAction(
        icon: action.icon,
        onPressed: action.onPressed,
        label: action.label,
        accent: action.accent,
        key: action.key,
      );

/// A destination a declared shell names: a [Fluent2NavItem] that keeps the
/// ground its root page stands on.
class Fluent2ShellTab extends Fluent2NavItem {
  /// The destination [tab] declares.
  Fluent2ShellTab.of(NavTab tab)
    : ground = tab.ground,
      super(tab.icon, tab.label, tab.key, tab.selectedIcon);

  /// The ground its root page stands on.
  final ChromeGround ground;
}

/// Whether the place at [index] of [tabs] stands on the media ground.
bool fluent2OnMedia(List<Fluent2NavItem> tabs, int index) =>
    index < tabs.length &&
    switch (tabs[index]) {
      Fluent2ShellTab(:final ground) => ground == ChromeGround.media,
      _ => false,
    };
