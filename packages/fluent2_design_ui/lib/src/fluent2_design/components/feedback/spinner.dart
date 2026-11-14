import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme.dart';

import 'package:ui_core/ui_core.dart';

/// A spinner's size, Fluent's `size`: 16, 20, 24, 28, 32 (the default),
/// 36, 40 and 44 across.
enum Fluent2SpinnerSize {
  /// 16 across.
  extraTiny(16, 2),

  /// 20 across.
  tiny(20, 2),

  /// 24 across.
  extraSmall(24, 2),

  /// 28 across.
  small(28, 3),

  /// 32 across.
  medium(32, 3),

  /// 36 across.
  large(36, 3),

  /// 40 across.
  extraLarge(40, 4),

  /// 44 across.
  huge(44, 4);

  /// A size of these measures.
  const Fluent2SpinnerSize(this.side, this.stroke);

  /// Its diameter.
  final double side;

  /// Its ring's width.
  final double stroke;
}

/// Fluent 2's Spinner: a ring in the brand's contrast stroke with the
/// brand's arc running round it (on a brand fill, [inverted]: the light
/// arc on a faint ring), and its [label] after it or under it ([below]) in
/// body1. While Reduce Motion is on it stands still at a
/// quarter. Read as "[label]" (Loading by default), a live region.
///
/// ```dart
/// Fluent2Spinner(label: 'Loading files')
/// ```
class Fluent2Spinner extends StatefulWidget {
  /// A spinner: work under way of unknown length.
  const Fluent2Spinner({
    this.size = Fluent2SpinnerSize.medium,
    this.label,
    this.below = true,
    this.inverted = false,
    this.value,
    super.key,
  });

  /// Fluent's `size`: how large it turns.
  final Fluent2SpinnerSize size;

  /// The words beside it, also spoken; null says "Loading" in the app's
  /// language.
  final String? label;

  /// The label under the ring; false sets it after.
  final bool below;

  /// Drawn on a brand fill.
  final bool inverted;

  /// How far along, 0 to 1: the arc stands at that share from the top and the
  /// ring stops turning. Null turns.
  final double? value;

  @override
  State<Fluent2Spinner> createState() => _Fluent2SpinnerState();
}

class _Fluent2SpinnerState extends State<Fluent2Spinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  void _drive() {
    if (widget.value != null || !Fluent2Motion.on(context)) {
      _turn.stop();
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _drive();
  }

  @override
  void didUpdateWidget(Fluent2Spinner old) {
    super.didUpdateWidget(old);
    if ((old.value == null) != (widget.value == null)) _drive();
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final track = widget.inverted
        ? t.colors.neutralStrokeAlpha2
        : t.colors.brandStroke2Contrast;
    final arc = widget.inverted
        ? t.colors.neutralStrokeOnBrand2
        : t.colors.brandStroke1;
    final s = widget.size;
    final ring = SizedBox.square(
      dimension: s.side,
      child: AnimatedBuilder(
        animation: _turn,
        builder: (context, _) => CustomPaint(
          painter: _RingPainter(
            phase: Fluent2Motion.on(context) ? _turn.value : 0.25,
            track: track,
            arc: arc,
            stroke: s.stroke,
            fraction: widget.value?.clamp(0.0, 1.0),
          ),
        ),
      ),
    );
    final label = widget.label;
    final words = label == null
        ? null
        : Text(
            label,
            textAlign: TextAlign.center,
            style: t.body1.c(
              widget.inverted
                  ? t.colors.neutralForegroundStaticInverted
                  : t.textPrimary,
            ),
          );
    return Semantics(
      liveRegion: true,
      label: label ?? DesignLocalizations.of(context).loadingLabel,
      excludeSemantics: true,
      child: words == null
          ? ring
          : widget.below
          ? Column(
              mainAxisSize: MainAxisSize.min,
              spacing: Fluent2Spacing.s,
              children: [ring, words],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              spacing: Fluent2Spacing.s,
              children: [
                ring,
                Flexible(child: words),
              ],
            ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.phase,
    required this.track,
    required this.arc,
    required this.stroke,
    this.fraction,
  });

  final double phase;
  final Color track;
  final Color arc;
  final double stroke;
  final double? fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    final held = fraction;
    if (held != null) {
      if (held > 0) {
        canvas.drawArc(
          rect,
          -math.pi / 2,
          math.pi * 2 * held,
          false,
          paint..color = arc,
        );
      }
      return;
    }
    // The arc grows and shrinks as it turns, as Fluent's tail does.
    final sweep = math.pi * (0.35 + 0.4 * math.sin(phase * math.pi).abs());
    final start = phase * math.pi * 4 - math.pi / 2;
    canvas.drawArc(rect, start, sweep, false, paint..color = arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.phase != phase ||
      old.track != track ||
      old.arc != arc ||
      old.stroke != stroke ||
      old.fraction != fraction;
}
