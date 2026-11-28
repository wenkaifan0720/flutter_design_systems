/// A scrolling region with Ledger's margin rule for a scrollbar, on ui_core's
/// scroll area.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../internal/corners.dart';
import '../../theme.dart';

/// A scrolling region (the terms of a transfer, a long note) whose scrollbar
/// is a fine rule in the margin: the light ink 3 wide, the second ink and 5
/// wide under a pointer or while dragged, fading after scrolling stops (at
/// once with reduced motion). Its pointer target is 12 across. It is a tab
/// stop the arrow keys scroll; while the keyboard is on it the double rule
/// stands round it. [child] is the scroll view, on the same [controller].
///
/// ```dart
/// LedgerScrollArea(controller: scroll, semanticLabel: 'Terms', child: SingleChildScrollView(controller: scroll, child: const Text('Terms')))
/// ```
class LedgerScrollArea extends StatelessWidget {
  /// [child] scrolling on [controller] with Ledger's rule for a scrollbar.
  const LedgerScrollArea({
    required this.controller,
    required this.child,
    this.axis = Axis.vertical,
    this.semanticLabel,
    super.key,
  });

  /// The controller [child] scrolls on; the caller's, who disposes it.
  final ScrollController controller;

  /// The scroll view.
  final Widget child;

  /// The way it scrolls.
  final Axis axis;

  /// What a screen reader calls the region.
  final String? semanticLabel;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ScrollController>('controller', controller))
      ..add(DiagnosticsProperty<Axis>('axis', axis))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final motion = LedgerMotion.of(context, LedgerMotion.base);
    return RawScrollArea(
      controller: controller,
      axis: axis,
      semanticLabel: semanticLabel,
      thumbBuilder: (context, thumb) {
        final hot =
            thumb.states.contains(WidgetState.hovered) ||
            thumb.states.contains(WidgetState.pressed);
        final across = hot ? _hot : _rest;
        return AnimatedOpacity(
          opacity: thumb.visible ? 1 : 0,
          duration: motion,
          child: Center(
            child: AnimatedContainer(
              duration: motion,
              width: axis == Axis.vertical ? across : null,
              height: axis == Axis.horizontal ? across : null,
              decoration: BoxDecoration(
                color: hot ? t.textSecondary : t.textFaint,
                borderRadius: BorderRadius.circular(across / 2),
              ),
            ),
          ),
        );
      },
      frameBuilder: (context, focused, area) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: ledgerStep(t, RawCorner.small),
          border: focused
              ? Border.all(
                  color: t.textPrimary,
                  width: LedgerChromeMetrics.focusRing,
                )
              : null,
        ),
        child: area,
      ),
      child: child,
    );
  }

  static const double _rest = 3;
  static const double _hot = 5;
}
