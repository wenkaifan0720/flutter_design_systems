import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';

/// Takes taps over at least a [target] square round its child while laying
/// out at the child's own size. Ledger's parts reach their floor through
/// ui_core's [TapTargetPadding] since 0.2.0, whose screen-reader box is the
/// reach a tap has; this forwards to it, for a component copied from 0.1.
@Deprecated(
  'Use TapTargetPadding(minSize: Size.square(target), child: child). '
  'This feature was deprecated after ledger_ui 0.2.0.',
)
class LedgerHitSlop extends StatelessWidget {
  /// [child] answering taps over a [target] square.
  const LedgerHitSlop({
    required this.child,
    this.target = LedgerLayout.minHitTarget,
    super.key,
  }) : assert(target >= 0);

  /// The control.
  final Widget child;

  /// The least square a tap on it reaches.
  final double target;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('target', target));
  }

  @override
  Widget build(BuildContext context) =>
      TapTargetPadding(minSize: Size.square(target), child: child);
}
