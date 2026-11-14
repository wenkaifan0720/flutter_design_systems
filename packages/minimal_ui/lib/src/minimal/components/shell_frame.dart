/// What the shell gives every page, with no router: the act beside its
/// tabs and the bottom allowance its bar asks a page to keep clear. A page,
/// a preview or a toast reads these; `MinimalShell` publishes them.
library;

import 'package:flutter/widgets.dart';

/// The app-level act beside the shell's tabs: the one thing reachable from
/// every root — new issue, add, capture — with the glyph it wears, what it
/// does, and the words a screen reader says for it. [key] is the
/// walkthrough key of the declared step it performs.
@immutable
class MinimalShellAction {
  /// The act beside the shell's tabs.
  const MinimalShellAction({
    required this.icon,
    required this.onPressed,
    this.label,
    this.primary = false,
    this.key,
  });

  /// The glyph it wears.
  final IconData icon;

  /// The act: the step's write and the typed route it lands on.
  final void Function(BuildContext context) onPressed;

  /// What the act does, announced for the icon-only square; null says
  /// the localized "New".
  final String? label;

  /// Accent-fill the square for the app whose act IS its standing
  /// invitation; otherwise it wears the ink.
  final bool primary;

  /// The walkthrough key of the step it performs.
  final Key? key;
}

/// The bottom allowance the shell's bar asks every nav root to reserve:
/// published by [MinimalShell] over its branch container (and by a preview
/// that stands the bar under a lone page), spent by [MinimalScaffold] on its
/// scroll padding and by [showMinimalSnackBar] on its inset.
class MinimalShellInsets extends InheritedWidget {
  /// Publishes [allowance] to the pages under [child].
  const MinimalShellInsets({
    required this.allowance,
    required super.child,
    super.key,
  });

  /// The reserved height above the screen's bottom edge, the bottom safe
  /// area included.
  final double allowance;

  /// The published allowance, or 0 outside any shell and on a pushed route,
  /// where the bar has yielded.
  static double of(BuildContext context) =>
      ModalRoute.of(context)?.isFirst == false
      ? 0
      : context
                .dependOnInheritedWidgetOfExactType<MinimalShellInsets>()
                ?.allowance ??
            0.0;

  @override
  bool updateShouldNotify(MinimalShellInsets old) => allowance != old.allowance;
}
