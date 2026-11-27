/// The bottom allowance a bar drawn over the pages asks each page to keep
/// clear. A page or a toast reads it; a preview that stands the bar under a
/// lone page publishes it. [MinimalAppShell] lays its pages above its bar,
/// so its pages keep none.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_shell.dart';

/// The bottom allowance a bar drawn over the pages asks every first page to
/// reserve: published by a shell whose bar overlays its pages (and by a
/// preview that stands the bar under a lone page), spent by [MinimalScaffold]
/// on its scroll padding and by [showMinimalSnackBar] on its inset.
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('allowance', allowance));
  }
}
