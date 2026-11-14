// The shell's frame without its router: the act it floats and the bottom
// allowance it asks a branch root to reserve. The preview, the screen and the
// toast read these, so they stand without go_router.
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart' show ShellAction, ShellInsets;

import '../chrome_metrics.dart';
import 'nav_bar.dart';

/// The app-level act beside the tabs, as Fluent 2 draws it: the floating
/// action button over the tab bar's end on a phone (extended with its
/// [label]), and the primary button under the nav pane's head at desktop
/// width.
///
/// ```dart
/// Fluent2ShellAction(icon: Fluent2Icons.edit, label: 'New message', accent: true, onPressed: (context) => Navigator.of(context).pushNamed('/compose'))
/// ```
class Fluent2ShellAction extends ShellAction {
  /// The act: [icon], [label] when extended, [onPressed] with the context.
  // Not const: ui_core's ShellAction still carries its old name's fallback, so its constructor is not.
  // ignore: prefer_const_constructors_in_immutables
  Fluent2ShellAction({
    required super.icon,
    required super.onPressed,
    super.label,
    super.accent,
    super.key,
  });
}

/// The bottom allowance the shell asks each branch root to reserve: the
/// tab bar over the device inset, the act and any accessory over it. The
/// shell publishes it through the design kit's `ShellInsets`; a screen
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
