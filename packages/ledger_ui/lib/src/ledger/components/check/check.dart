import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// The mark that fills when a thing is done: a ring of the rule that the
/// green fills and a tick, pressed a few degrees off square like the seal,
/// draws across. A task, a habit, a line ticked off a list. [onChanged]
/// null makes it a MARK, not a control (as a null callback holds any
/// Flutter control): a finished line's tick, undimmed, that lets taps
/// through. Give a check that stands without words a
/// [semanticLabel], spoken and never printed. It lays out at the tap floor round its
/// ring (40 for a finger, 24 for a pointer), and a tap anywhere in that
/// room reaches it.
///
/// ```dart
/// LedgerCheck(value: done, semanticLabel: 'Pay rent', onChanged: (v) => setState(() => done = v))
/// ```
class LedgerCheck extends StatelessWidget {
  /// A check at [value], changed by [onChanged].
  const LedgerCheck({
    required this.value,
    this.onChanged,
    this.size = 26,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.tapAlignment = AlignmentDirectional.centerStart,
    super.key,
  }) : assert(size > 0);

  /// Whether it is done.
  final bool value;

  /// Where the disc stands in its tap target where the target is larger:
  /// on the start keyline by default (a task's check heads its line), or centred, or on the edge a keyline runs ([AlignmentDirectional.centerStart]
  /// at the start of a column, [AlignmentDirectional.centerEnd] at its end),
  /// the target growing away from it.
  final AlignmentDirectional tapAlignment;

  /// Called with the new state; null makes the check a mark.
  final ValueChanged<bool>? onChanged;

  /// {@macro ledger.focusNode}
  final FocusNode? focusNode;

  /// {@macro ledger.autofocus}
  final bool autofocus;

  /// The ring's side: 26 in a row, 22 beside small words.
  final double size;

  /// What is being ticked off, spoken.
  final String? semanticLabel;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('value', value: value, ifTrue: 'value'))
      ..add(
        DiagnosticsProperty<AlignmentDirectional>('tapAlignment', tapAlignment),
      )
      ..add(ObjectFlagProperty<ValueChanged<bool>>.has('onChanged', onChanged))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(DoubleProperty('size', size))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final face = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value ? 1 : 0),
      duration: LedgerMotion.of(context, LedgerMotion.base),
      curve: LedgerMotion.out,
      builder: (context, done, _) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _CheckPainter(
            done: done,
            ring: t.borderStrong,
            fill: t.accent,
            tick: t.onAccent,
            turn: LedgerChromeMetrics.sealTurn * math.pi / 180,
          ),
        ),
      ),
    );
    if (onChanged == null) {
      return Semantics(
        checked: value,
        label: semanticLabel,
        child: ExcludeSemantics(child: face),
      );
    }
    // Laid out at the floor round its disc, so where a tap lands, what a
    // screen reader outlines and the room it takes are one; one node, a
    // checkbox (no button) whose press ticks it.
    return TapTargetPadding(
      alignment: tapAlignment,
      child: LedgerPressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onTap: () => onChanged!(!value),
        semanticLabel: semanticLabel,
        checked: value,
        radius: size / 2,
        child: face,
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({
    required this.done,
    required this.ring,
    required this.fill,
    required this.tick,
    required this.turn,
  });

  /// 0 undone, 1 done; the fill and the tick travel between.
  final double done;
  final Color ring;
  final Color fill;
  final Color tick;

  /// How far the tick is pressed off square, in radians.
  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas
      ..drawCircle(c, r, Paint()..color = fill.withValues(alpha: done))
      ..drawCircle(
        c,
        r - .75,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Color.lerp(ring, fill, done)!,
      );
    if (done == 0) return;
    // The tick on a 24 grid, drawn from its foot to its tip as `done` runs.
    final path = Path()
      ..moveTo(7, 12.5)
      ..lineTo(10.5, 16)
      ..lineTo(17, 8.5);
    final metric = path.computeMetrics().first;
    canvas
      ..save()
      ..translate(c.dx, c.dy)
      ..rotate(turn)
      ..scale(size.shortestSide / 28)
      ..translate(-12, -12)
      ..drawPath(
        metric.extractPath(0, metric.length * done),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 2.2
          ..color = tick,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.done != done ||
      old.ring != ring ||
      old.fill != fill ||
      old.tick != tick ||
      old.turn != turn;
}
