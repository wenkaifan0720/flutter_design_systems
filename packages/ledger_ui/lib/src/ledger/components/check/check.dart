import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../internal/hit_slop.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// The mark that fills when a thing is done: a ring of the rule that the
/// green fills and a tick, pressed a few degrees off square like the seal,
/// draws across. A task, a habit, a line ticked off a list. [onChanged]
/// null makes it a MARK, not a control (as a null callback holds any
/// Flutter control): a finished line's tick, undimmed, that lets taps
/// through. Give a check that stands without words a
/// [label], spoken and never printed. Its 44 point target reaches past the
/// ring.
///
/// ```dart
/// LedgerCheck(value: done, label: 'Pay rent', onChanged: (v) => setState(() => done = v))
/// ```
class LedgerCheck extends StatelessWidget {
  /// A check at [value], changed by [onChanged].
  const LedgerCheck({
    required this.value,
    this.onChanged,
    this.size = 26,
    this.label,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Whether it is done.
  final bool value;

  /// Called with the new state; null makes the check a mark.
  final ValueChanged<bool>? onChanged;

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  /// The ring's side: 26 in a row, 22 beside small words.
  final double size;

  /// What is being ticked off, spoken.
  final String? label;

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
        label: label,
        child: ExcludeSemantics(child: face),
      );
    }
    // The slop is the one node (it merges what is under it), so a screen
    // reader outlines, and the tap-target guideline measures, its 44.
    return LedgerHitSlop(
      child: Semantics(
        checked: value,
        child: LedgerPressable(
          focusNode: focusNode,
          autofocus: autofocus,
          onTap: () => onChanged!(!value),
          label: label,
          radius: size / 2,
          child: face,
        ),
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
