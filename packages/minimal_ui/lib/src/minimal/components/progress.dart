/// A slim progress bar: determinate, or sweeping while the total is unknown.
library;

import 'package:flutter/widgets.dart';

import '../theme.dart';
import 'tag.dart';

/// A quantity in flight — an upload, a goal, a quota — as a 4 px hairline
/// of fill on a quiet track, clamped to 0..1. A new [value] eases to its
/// width in [MinimalMotion.base], and jumps there when the platform asks for
/// reduced motion. A null [value] is work whose total is unknown: a third
/// of the fill sweeps along the track, and stands still at its start under
/// reduced motion.
///
/// ```dart
/// MinimalLinearProgressIndicator(value: 0.62, label: 'Upload')
/// ```
class MinimalLinearProgressIndicator extends StatefulWidget {
  /// A bar showing progress.
  const MinimalLinearProgressIndicator({
    super.key,
    this.value,
    required this.label,
    this.tone = MinimalTone.primary,
    this.height = MinimalLinearProgressIndicator.thickness,
  });

  /// The fraction done, clamped to 0..1; null while the total is unknown.
  final double? value;

  /// What a screen reader announces before the percentage ('Upload').
  final String label;

  /// The fill's colour: the accent for a quantity in flight, success for a
  /// goal met, warn or danger for a quota running out.
  final MinimalTone tone;

  /// Its track's height.
  final double height;

  /// The bar's default thickness.
  static const double thickness = 4;

  /// How long the unknown total's fill takes to sweep across once.
  static const Duration sweep = Duration(milliseconds: 1600);

  @override
  State<MinimalLinearProgressIndicator> createState() =>
      _MinimalLinearProgressIndicatorState();
}

class _MinimalLinearProgressIndicatorState
    extends State<MinimalLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: MinimalLinearProgressIndicator.sweep,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _run();
  }

  @override
  void didUpdateWidget(MinimalLinearProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _run();
  }

  /// Sweeps only while the total is unknown and motion is on.
  void _run() {
    if (widget.value != null || context.minimalStill) {
      _sweep
        ..stop()
        ..value = 0;
    } else if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final height = widget.height;
    final fill = t.tone(widget.tone).indicator;
    final value = widget.value;
    if (value == null) {
      final rtl = Directionality.of(context) == TextDirection.rtl;
      return Semantics(
        label: widget.label,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _sweep,
            builder: (context, _) {
              final head = _sweep.value * 4 / 3;
              return CustomPaint(
                painter: _SweepPainter(
                  from: head - 1 / 3,
                  to: head,
                  track: t.border,
                  fill: fill,
                  rtl: rtl,
                  shape: t.shapes.pill,
                ),
              );
            },
          ),
        ),
      );
    }
    final v = value.clamp(0.0, 1.0);
    final duration = context.minimalStill ? Duration.zero : MinimalMotion.base;
    return Semantics(
      label: widget.label,
      value: '${(v * 100).round()}%',
      // A capsule by role, in the scale's own family; the fill clips to it.
      child: ClipPath(
        clipper: ShapeBorderClipper(
          shape: t.shapes.pill,
          textDirection: Directionality.of(context),
        ),
        child: Container(
          height: height,
          // The track states its width: under a loose width (a start-aligned
          // column) the fractional fill would otherwise shrink-wrap it.
          width: double.infinity,
          color: t.border,
          child: AnimatedFractionallySizedBox(
            duration: duration,
            curve: MinimalMotion.out,
            alignment: AlignmentDirectional.centerStart,
            widthFactor: v,
            child: ColoredBox(color: fill),
          ),
        ),
      ),
    );
  }
}

/// The sweep: the track in [shape], and the fill from [from] to [to]
/// (fractions of the length, from the start edge) in the same shape.
class _SweepPainter extends CustomPainter {
  _SweepPainter({
    required this.from,
    required this.to,
    required this.track,
    required this.fill,
    required this.rtl,
    required this.shape,
  });

  final double from;
  final double to;
  final Color track;
  final Color fill;
  final bool rtl;
  final OutlinedBorder shape;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      shape.getOuterPath(Offset.zero & size),
      Paint()..color = track,
    );
    final start = from.clamp(0.0, 1.0) * size.width;
    final end = to.clamp(0.0, 1.0) * size.width;
    if (end <= start) return;
    final left = rtl ? size.width - end : start;
    canvas.drawPath(
      shape.getOuterPath(Rect.fromLTWH(left, 0, end - start, size.height)),
      Paint()..color = fill,
    );
  }

  @override
  bool shouldRepaint(_SweepPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.track != track ||
      oldDelegate.fill != fill ||
      oldDelegate.rtl != rtl ||
      oldDelegate.shape != shape;
}
