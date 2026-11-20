import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../components/pressable/pressable.dart';
import '../theme.dart';
import 'face.dart';

/// What [LedgerPressable] draws round a face, for a face one of ui_core's
/// behaviours presses (a toggle group's pill, a split button's half): the
/// accountant's double rule under it while the keyboard holds it, and the
/// stamp's impression while it is held, its marks a shade deeper and the
/// bare paper of its box taking the same ink ([LedgerImpression]), each in
/// Ledger's one motion. [states] also reach the face's own ink through
/// [LedgerPressStates].
class LedgerStateFace extends StatelessWidget {
  /// The states' marks round [child].
  const LedgerStateFace({
    required this.states,
    required this.radius,
    required this.child,
    this.ringInsets = EdgeInsets.zero,
    this.sinks = true,
    this.washes = true,
    super.key,
  });

  /// The face's states, as the behaviour reports them.
  final Set<WidgetState> states;

  /// The face's corner, which the focus rule keeps clear of.
  final double radius;

  /// How far the face stands inside the box (the rule rules under the face).
  final EdgeInsetsGeometry ringInsets;

  /// Whether a press deepens the face's ink ([LedgerImpression]). False
  /// where the face answers a press in its own fill, as a split button's
  /// halves do.
  final bool sinks;

  /// Whether a press also washes the bare paper of the face's box, its
  /// corners [radius] round. False where the box holds more than the mark
  /// the press deepens, as the tab bar's disc column holds its name.
  final bool washes;

  /// The face.
  final Widget child;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<WidgetState>('states', states))
      ..add(DoubleProperty('radius', radius))
      ..add(DiagnosticsProperty<EdgeInsetsGeometry>('ringInsets', ringInsets))
      ..add(FlagProperty('sinks', value: sinks, ifTrue: 'sinks'))
      ..add(FlagProperty('washes', value: washes, ifTrue: 'washes'));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final held = states.contains(WidgetState.pressed);
    final face = LedgerPressStates(states: states, child: child);
    return LedgerFocusRing(
      radius: radius,
      insets: ringInsets,
      color: t.textPrimary,
      shown: states.contains(WidgetState.focused),
      child: sinks
          ? LedgerEase(
              value: held ? LedgerImpression.pressed : 0,
              builder: (context, depth, face) => LedgerImpression(
                ink: t.textPrimary,
                depth: depth,
                wash: washes ? radius : null,
                child: face,
              ),
              child: face,
            )
          : face,
    );
  }
}
