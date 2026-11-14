import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../theme.dart';

import 'package:ui_core/ui_core.dart';

/// How far something has gone, or that it is going: a glass tube 6 tall in
/// its hairline (the slider's), filled from its start as far as [value]
/// with the signature band. With a null [value] it is indeterminate: a
/// third of the band runs along the tube, and under Reduce Motion stands
/// still at its start. A change of [value] eases to the new length. Read
/// aloud as [label] and the share done.
///
/// ```dart
/// FrostedLinearProgressIndicator(value: 0.6, label: 'Uploading')
/// ```
class FrostedLinearProgressIndicator extends StatefulWidget {
  /// A tube filled as far as [value]; indeterminate when null.
  const FrostedLinearProgressIndicator({
    required this.label,
    this.value,
    this.valueLabel,
    this.minHeight = FrostedChromeMetrics.sliderTrack,
    super.key,
  }) : assert(value == null || (value >= 0 && value <= 1));

  /// How far it has gone, 0 to 1; null while it cannot say.
  final double? value;

  /// What a screen reader calls it: what is under way.
  final String label;

  /// What a screen reader says of its value; null says the share done.
  final String? valueLabel;

  /// The tube's height.
  final double minHeight;

  @override
  State<FrostedLinearProgressIndicator> createState() =>
      _FrostedLinearProgressIndicatorState();
}

class _FrostedLinearProgressIndicatorState
    extends State<FrostedLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  void _sync() {
    final moves = FrostedMotion.of(context).moves;
    if (widget.value == null && moves) {
      if (!_run.isAnimating) _run.repeat();
    } else {
      _run.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(FrostedLinearProgressIndicator old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final motion = FrostedMotion.of(context);
    final h = widget.minHeight;
    final end = Radius.circular(h / 2);
    final value = widget.value;
    final band = FrostedFace(
      material: FrostedMaterial.paint,
      radius: BorderRadius.all(end),
      gradients: [t.hues.iris.band],
    );
    final Widget fill = value == null
        ? AnimatedBuilder(
            animation: _run,
            builder: (context, _) =>
                _Running(phase: motion.moves ? _run.value : 0, child: band),
          )
        : TweenAnimationBuilder<double>(
            tween: Tween(end: value),
            duration: motion.base,
            curve: motion.curve,
            builder: (context, v, _) => FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: v,
              child: band,
            ),
          );
    return Semantics(
      label: widget.label,
      value:
          widget.valueLabel ??
          (value == null ? null : '${(value * 100).round()}%'),
      child: SizedBox(
        height: h,
        child: FrostedFace(
          material: FrostedMaterial.paint,
          radius: BorderRadius.all(end),
          color: t.glass.track,
          ring: t.glass.trackEdge,
          clipChild: true,
          child: SizedBox(height: h, width: double.infinity, child: fill),
        ),
      ),
    );
  }
}

/// The indeterminate run: a third of the tube's length, entering at its
/// start and leaving at its end once a cycle.
class _Running extends StatelessWidget {
  const _Running({required this.phase, required this.child});

  final double phase;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth;
      final len = w / 3;
      final start = -len + (w + len) * Curves.easeInOut.transform(phase);
      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          PositionedDirectional(
            start: start,
            top: 0,
            bottom: 0,
            width: len,
            child: child,
          ),
        ],
      );
    },
  );
}

/// How far something has gone, or that it is going, as a ring of light: a
/// thin groove of lit glass with an arc of the signature band shining in
/// it, as far round from the top as [value] reaches; indeterminate when
/// null, the arc a quarter turning once a second (still under Reduce
/// Motion), as the loading state's. Read aloud as [label] (the localized "Loading" by
/// default) and the share done.
///
/// ```dart
/// FrostedCircularProgressIndicator(value: 0.25, label: 'Syncing')
/// ```
class FrostedCircularProgressIndicator extends StatefulWidget {
  /// A ring filled as far round as [value]; indeterminate when null.
  const FrostedCircularProgressIndicator({
    this.value,
    this.label,
    this.valueLabel,
    this.size = FrostedChromeMetrics.loadingRing,
    this.strokeWidth = FrostedChromeMetrics.loadingStroke,
    super.key,
  }) : assert(value == null || (value >= 0 && value <= 1));

  /// How far it has gone, 0 to 1; null while it cannot say.
  final double? value;

  /// What a screen reader calls it.
  final String? label;

  /// What a screen reader says of its value; null says the share done.
  final String? valueLabel;

  /// The ring's diameter.
  final double size;

  /// The ring's line.
  final double strokeWidth;

  @override
  State<FrostedCircularProgressIndicator> createState() =>
      _FrostedCircularProgressIndicatorState();
}

class _FrostedCircularProgressIndicatorState
    extends State<FrostedCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  void _sync() {
    if (widget.value == null && FrostedMotion.of(context).moves) {
      if (!_turn.isAnimating) _turn.repeat();
    } else {
      _turn.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(FrostedCircularProgressIndicator old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final motion = FrostedMotion.of(context);
    final value = widget.value;
    Widget ring(double sweep) => CustomPaint(
      size: Size.square(widget.size),
      painter: _ArcPainter(
        // The groove: lit glass, white light by day, the night glass's
        // own by night.
        track: t.isDark ? const Color(0x24FFFFFF) : const Color(0xCCFFFFFF),
        arc: t.hues.iris.band.colors,
        sweep: sweep,
        width: widget.strokeWidth,
      ),
    );
    final Widget face = value == null
        ? RotationTransition(turns: _turn, child: ring(0.25))
        : TweenAnimationBuilder<double>(
            tween: Tween(end: value),
            duration: motion.base,
            curve: motion.curve,
            builder: (context, v, _) => ring(v),
          );
    return Semantics(
      label: widget.label ?? DesignLocalizations.of(context).loadingLabel,
      value:
          widget.valueLabel ??
          (value == null ? null : '${(value * 100).round()}%'),
      child: SizedBox.square(dimension: widget.size, child: face),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.track,
    required this.arc,
    required this.sweep,
    required this.width,
  });

  final Color track;

  /// The band's colours, swept round the ring from the top.
  final List<Color> arc;

  /// The share of the turn the arc covers.
  final double sweep;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      width / 2,
      width / 2,
      size.width - width,
      size.height - width,
    );
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
    if (sweep <= 0) return;
    // The band runs the arc's length, from its start at the top to its end.
    final band = SweepGradient(
      colors: arc,
      endAngle: math.pi * 2 * sweep.clamp(.01, 1),
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);
    // The arc's glow, then the arc: light shining in the groove.
    for (final glow in [true, false]) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * sweep,
        false,
        Paint()
          ..shader = band
          ..style = PaintingStyle.stroke
          ..strokeWidth = glow ? width * 2 : width
          ..strokeCap = StrokeCap.round
          ..maskFilter = glow
              ? const MaskFilter.blur(BlurStyle.normal, 3)
              : null,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.track != track ||
      !listEquals(old.arc, arc) ||
      old.sweep != sweep ||
      old.width != width;
}

/// Where content will stand while it loads: a pane of glass in the place
/// and shape of what is coming, in its lit edge, with a slow light passing
/// over it (none under Reduce Motion). Every bone on a page shines together.
/// [FrostedSkeleton.text] stands [lines] lines of body text, the last one
/// shorter; [FrostedSkeleton.circle] an avatar's round. Silent to a screen
/// reader: say what is loading on what holds the bones.
///
/// ```dart
/// FrostedSkeleton(width: 120, height: 16)
/// ```
///
/// ```dart
/// FrostedSkeleton.text(lines: 3)
/// ```
///
/// ```dart
/// FrostedSkeleton.circle(size: 40)
/// ```
class FrostedSkeleton extends StatelessWidget {
  /// A block [width] by [height] (null width takes the room it is given),
  /// cut to [shape] (the theme's small corner by default).
  const FrostedSkeleton({this.width, this.height = 16, this.shape, super.key})
    : lines = 0;

  /// [lines] lines of text, 8 apart, the last at 60%.
  const FrostedSkeleton.text({this.lines = 3, super.key})
    : width = null,
      height = 12,
      shape = null;

  /// An avatar's round, [size] across.
  const FrostedSkeleton.circle({double size = 40, super.key})
    : width = size,
      height = size,
      shape = const CircleBorder(),
      lines = 0;

  /// The block's width; null takes the room it is given.
  final double? width;

  /// The block's height.
  final double height;

  /// The block's outline; null is the theme's small corner (a line of text
  /// a capsule).
  final OutlinedBorder? shape;

  /// How many lines of text it stands for, for [FrostedSkeleton.text].
  final int lines;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    Widget bone(double? w, OutlinedBorder outline) => _Bone(
      width: w,
      height: height,
      shape: outline,
      color: t.isDark ? const Color(0x12FFFFFF) : t.glass.fill,
      edge: t.isDark ? t.glass.edge : FrostedChromeMetrics.litEdge,
      light: t.isDark ? const Color(0x29FFFFFF) : const Color(0xF2FFFFFF),
    );
    if (lines > 0) {
      return ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: FrostedSpacing.s8,
            children: [
              for (var i = 0; i < lines; i++)
                bone(
                  i == lines - 1 && lines > 1 && box.maxWidth.isFinite
                      ? box.maxWidth * .6
                      : null,
                  const StadiumBorder(),
                ),
            ],
          ),
        ),
      );
    }
    return ExcludeSemantics(child: bone(width, shape ?? FrostedCorners.small));
  }
}

/// One bone: its block, and the light passing over it on the page's one
/// clock.
class _Bone extends StatefulWidget {
  const _Bone({
    required this.width,
    required this.height,
    required this.shape,
    required this.color,
    required this.edge,
    required this.light,
  });

  final double? width;
  final double height;
  final OutlinedBorder shape;
  final Color color;

  /// The pane's lit edge.
  final Color edge;
  final Color light;

  @override
  State<_Bone> createState() => _BoneState();
}

class _BoneState extends State<_Bone> with SingleTickerProviderStateMixin {
  static const _period = Duration(milliseconds: 1600);

  /// The frame the first of the bones now shown began on: every bone's
  /// light takes its phase from it, so the bones on a page shine together.
  /// Read from the frame clock, not the wall's, and forgotten once no bone
  /// is shown, so a page's light starts the same way every time.
  static Duration? _epoch;
  static int _shown = 0;

  late final AnimationController _light = AnimationController(
    vsync: this,
    duration: _period,
  );

  @override
  void initState() {
    super.initState();
    _shown++;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (FrostedMotion.of(context).moves) {
      if (!_light.isAnimating) {
        final now = SchedulerBinding.instance.currentSystemFrameTimeStamp;
        final since = now - (_epoch ??= now);
        _light.value =
            (since.inMicroseconds % _period.inMicroseconds) /
            _period.inMicroseconds;
        _light.repeat();
      }
    } else {
      _light.stop();
      _light.value = 0;
    }
  }

  @override
  void dispose() {
    if (--_shown == 0) _epoch = null;
    _light.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final block = DecoratedBox(
      decoration: ShapeDecoration(
        shape: widget.shape.copyWith(side: BorderSide(color: widget.edge)),
        color: widget.color,
      ),
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
      ),
    );
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _light,
        child: block,
        builder: (context, block) {
          final moving = _light.isAnimating;
          if (!moving) return block!;
          final x = -1.5 + 3 * _light.value;
          return ClipPath(
            clipper: ShapeBorderClipper(shape: widget.shape),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(x - .6, 0),
                  end: Alignment(x + .6, 0),
                  colors: [
                    widget.light.withValues(alpha: 0),
                    widget.light.withValues(alpha: .55),
                    widget.light.withValues(alpha: 0),
                  ],
                ),
              ),
              child: block,
            ),
          );
        },
      ),
    );
  }
}
