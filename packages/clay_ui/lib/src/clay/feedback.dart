/// Clay's progress: a groove pressed into the ground that fills with a
/// coral volume, as a bar or a ring, and a calm spinner for a wait of
/// unknown length.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/slices.dart';
import 'internal/spring.dart';
import 'internal/volume.dart';
import 'surface.dart';
import 'theme.dart';

/// A Clay progress bar: a groove pressed into the ground, filled from its
/// start by a coral volume as [value] grows (0 to 1). The fill slides to a
/// new value on a calm spring.
///
/// ```dart
/// const ClayProgressBar(value: 0.6, semanticLabel: 'Weekly goal')
/// ```
class ClayProgressBar extends StatelessWidget {
  /// A bar at [value].
  const ClayProgressBar({
    super.key,
    required this.value,
    this.semanticLabel,
    this.height = 12,
    this.color,
    this.style,
  });

  /// How full it is, 0 to 1.
  final double value;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Its thickness.
  final double height;

  /// The fill's colour (a habit's pastel); the accent by default.
  final Color? color;

  /// This bar's own style, over [ClayThemeData.progressStyle]: `fill` the
  /// volume.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.progressStyle], const {});
    final fill = color ?? layered.fill ?? c.accent;
    final v = value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel,
      value: '${(v * 100).round()}%',
      // It spans its parent's width, as a bar does: never shrink-wrapped.
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ClaySurface(
          // The groove halfway to an off control's: its length reads by day
          // and by night.
          face: ClayFace.well(
            c,
            color: Color.lerp(c.well, c.track, 0.45),
            radius: height / 2,
          ),
          child: ClaySpring(
            target: v,
            damping: 1,
            stiffness: ClayMotion.liftStiffness,
            builder: (context, t) => FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: t.clamp(0.0, 1.0),
              child: t <= 0.001
                  ? const SizedBox.shrink()
                  : ClaySurface(
                      face: ClayFace.raised(
                        c,
                        color: fill,
                        radius: height / 2,
                      ).copyWith(shadowOpacity: 0),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('value', value));
  }
}

/// A Clay progress ring: a round groove pressed into the ground that fills
/// with a coral band of clay as [value] grows, [child] (a count, a glyph) in
/// its middle. The band is lit inside its top-leading edge and shaded inside
/// its bottom-trailing one; its round ends stand exactly at 0 and at
/// [value], so they never make it look further round than it is, and they
/// close into a whole ring at 1.
///
/// ```dart
/// const ClayProgressRing(value: 0.6, child: Text('3/5'))
/// ```
class ClayProgressRing extends StatelessWidget {
  /// A ring at [value].
  const ClayProgressRing({
    super.key,
    required this.value,
    this.child,
    this.size = 120,
    this.thickness = 14,
    this.color,
    this.semanticLabel,
    this.style,
  });

  /// How full it is, 0 to 1.
  final double value;

  /// What stands in its middle.
  final Widget? child;

  /// Its side.
  final double size;

  /// Its groove's width.
  final double thickness;

  /// The band's colour; the accent by default.
  final Color? color;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// This ring's own style, over [ClayThemeData.progressStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.progressStyle], const {});
    final fill = color ?? layered.fill ?? c.accent;
    final v = value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel,
      value: '${(v * 100).round()}%',
      // A ring stays round where a column would stretch it.
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: SizedBox.square(
          dimension: size,
          child: ClaySpring(
            target: v,
            damping: 1,
            stiffness: ClayMotion.liftStiffness,
            builder: (context, t) => CustomPaint(
              painter: _RingPainter(
                colors: c,
                band: fill,
                value: t.clamp(0.0, 1.0),
                thickness: thickness,
                rtl: Directionality.of(context) == TextDirection.rtl,
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(DoubleProperty('size', size));
  }
}

// A ring's groove and band. The groove is a stroke on a circle, its soft
// shading a pair of thin offset strokes, no blur; the band is a piece of
// clay with round ends, its light and shade Clay's volume.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.colors,
    required this.band,
    required this.value,
    required this.thickness,
    required this.rtl,
  });

  final ClayColors colors;
  final Color band;
  final double value;
  final double thickness;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final c = colors;
    final night = c.brightness == Brightness.dark;
    final center = size.center(Offset.zero);
    final r = (math.min(size.width, size.height) - thickness) / 2;
    Paint stroke(Color color, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = color;
    // The groove, its rim shaded at the top-leading inside and lit at the
    // bottom-trailing, as a well is.
    canvas.drawCircle(center, r, stroke(c.well, thickness));
    canvas
      ..save()
      ..clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addOval(Rect.fromCircle(center: center, radius: r + thickness / 2))
          ..addOval(Rect.fromCircle(center: center, radius: r - thickness / 2)),
      );
    canvas.drawCircle(
      center.translate(1.5, 1.5),
      r,
      stroke(c.groundShade.withValues(alpha: night ? 0.5 : 0.12), thickness + 1)
        ..maskFilter = null,
    );
    canvas.drawCircle(
      center.translate(-0.5, -0.5),
      r,
      stroke(c.well, thickness - 3),
    );
    canvas.restore();
    if (value <= 0.001) return;
    final width = thickness - 4;
    final outer = r + width / 2;
    final inner = r - width / 2;
    final sweep = 2 * math.pi * value;
    // Round ends whose tips stand at 0 and at the value; they square off
    // as the two ends meet, closing into a whole ring at 1.
    final half = math.sin(math.min(sweep / 2, math.pi / 2));
    final closing = ((1 - value) * 2 * math.pi * r / width).clamp(0.0, 1.0);
    var corner = width / 2 * 0.999 * closing;
    corner = math.min(corner, outer * half / (1 + half));
    if (half < 1) corner = math.min(corner, inner * half / (1 - half));
    var shape = ClaySliceShape(
      start: -math.pi / 2,
      sweep: sweep,
      outerCorner: corner,
      innerCorner: corner,
    );
    if (rtl) shape = shape.mirrored();
    clayPaintVolume(
      canvas,
      shape.path(center, outer, inner),
      colors: c,
      color: band,
      side: width,
      mirrored: rtl,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.band != band ||
      old.colors != colors ||
      old.thickness != thickness ||
      old.rtl != rtl;
}

/// A calm spinner for a wait of unknown length: a coral ball rolling round a
/// small round groove, once every 1.4 s. Under Reduce Motion the ball
/// stands still and pulses its colour.
///
/// ```dart
/// const ClaySpinner(semanticLabel: 'Loading habits')
/// ```
class ClaySpinner extends StatefulWidget {
  /// A spinner [size] across.
  const ClaySpinner({
    super.key,
    this.size = 32,
    this.semanticLabel,
    this.style,
  });

  /// Its side.
  final double size;

  /// What a screen reader calls the wait.
  final String? semanticLabel;

  /// Its own style, over [ClayThemeData.spinnerStyle]: `fill` the ball,
  /// `edge` the well it rolls round.
  final ClayStyle? style;

  @override
  State<ClaySpinner> createState() => _ClaySpinnerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('size', size));
  }
}

class _ClaySpinnerState extends State<ClaySpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([widget.style, theme.spinnerStyle], const {});
    final still = designReduceMotionOf(context);
    final s = widget.size;
    final ball = s * 0.32;
    return Semantics(
      label: widget.semanticLabel,
      // A ball stays round where a column would stretch it.
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: SizedBox.square(
          dimension: s,
          child: ClaySurface(
            face: ClayFace.well(c, color: layered.edge, radius: s / 2),
            child: AnimatedBuilder(
              animation: _turn,
              builder: (context, _) {
                final a = still ? -math.pi / 2 : _turn.value * 2 * math.pi;
                final r = (s - ball) / 2 - 2;
                final o = Offset(math.cos(a) * r, math.sin(a) * r);
                final pulse = still
                    ? 0.6 + 0.4 * math.sin(_turn.value * 2 * math.pi).abs()
                    : 1.0;
                return Transform.translate(
                  offset: o,
                  child: Center(
                    child: Opacity(
                      opacity: pulse,
                      child: SizedBox.square(
                        dimension: ball,
                        child: ClaySurface(
                          face: ClayFace.raised(
                            c,
                            color: layered.fill ?? c.accent,
                            radius: ball,
                          ).copyWith(shadowOpacity: 0),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
