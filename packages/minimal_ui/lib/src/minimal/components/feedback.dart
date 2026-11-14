/// Work in flight and room left: a spinner, skeletons and a meter.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'tag.dart';

/// A small ring for work in flight — a button's wait, a row that syncs, a
/// panel that loads: a track in the hairline's grey (by night the stronger
/// hairline's) with an arc in the ink (or a status [tone]'s colour) on it.
/// With a
/// [value] it is determinate, the arc that fraction of the ring from the
/// top; without, a quarter arc turns once a second (and stands still under
/// reduced motion, in tests and goldens).
///
/// ```dart
/// MinimalCircularProgressIndicator(label: 'Syncing')
/// ```
class MinimalCircularProgressIndicator extends StatefulWidget {
  /// A spinning ring.
  const MinimalCircularProgressIndicator({
    super.key,
    this.value,
    this.label,
    this.size = 16,
    this.strokeWidth = 2,
    this.tone = MinimalTone.primary,
  });

  /// The fraction done, 0..1; null while the total is unknown.
  final double? value;

  /// What a screen reader hears; null says the localized "Loading".
  final String? label;

  /// Its diameter.
  final double size;

  /// Its ring's width.
  final double strokeWidth;

  /// Its ink: one of the tones. `primary`, the default, is the full ink (a
  /// wait never wears the accent); a status tone its own colour.
  final MinimalTone tone;

  @override
  State<MinimalCircularProgressIndicator> createState() =>
      _MinimalCircularProgressIndicatorState();
}

class _MinimalCircularProgressIndicatorState
    extends State<MinimalCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _run();
  }

  @override
  void didUpdateWidget(MinimalCircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _run();
  }

  void _run() {
    if (widget.value != null || context.minimalStill) {
      _turn
        ..stop()
        ..value = 0;
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final value = widget.value;
    return Semantics(
      label: widget.label ?? MinimalLocalizations.of(context).loading,
      value: value == null ? null : '${(value.clamp(0.0, 1.0) * 100).round()}%',
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _turn,
          builder: (context, _) => CustomPaint(
            painter: _RingPainter(
              // By night the stronger hairline: a ring this thin in the
              // hairline's grey all but sinks into the dark ground.
              track: t.isLightAppearance ? t.border : t.borderStrong,
              // A wait is no act to take: the default ring turns in the
              // ink, as a loading page's spinner does, never the accent.
              arc: widget.tone == MinimalTone.primary
                  ? t.foreground
                  : t.tone(widget.tone).indicator,
              width: widget.strokeWidth,
              start: value == null ? _turn.value : 0,
              sweep: value?.clamp(0.0, 1.0) ?? 0.25,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.track,
    required this.arc,
    required this.width,
    required this.start,
    required this.sweep,
  });

  final Color track;
  final Color arc;
  final double width;

  /// Where the arc starts, in turns from the top.
  final double start;

  /// How much of the ring it covers, in turns.
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, line..color = track);
    if (sweep <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2 + start * 2 * math.pi,
      sweep * 2 * math.pi,
      false,
      line..color = arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.track != track ||
      old.arc != arc ||
      old.width != width ||
      old.start != start ||
      old.sweep != sweep;
}

/// A placeholder in the shape of what is loading — a line of text, an
/// avatar, a card — so the page keeps its layout while it waits: the
/// hairline's grey (by night the stronger hairline's), pulsing gently
/// (still under reduced motion). [MinimalSkeleton]
/// is a block on the `shapes.mark` step; [MinimalSkeleton.text] a run of
/// lines, the last one shorter; [MinimalSkeleton.circle] a face's circle.
/// Skeletons are silent to a screen reader: announce the wait once, around
/// them (a `MinimalLoadingState`, or a Semantics label on their column).
///
/// ```dart
/// MinimalSkeleton.text(lines: 3)
/// ```
class MinimalSkeleton extends StatefulWidget {
  /// A block [width] by [height].
  const MinimalSkeleton({super.key, this.width, this.height = 12, this.shape})
    : lines = 1,
      circle = false;

  /// [lines] lines of text, a body's line apart, the last at 60%.
  const MinimalSkeleton.text({super.key, this.lines = 3})
    : width = null,
      height = 10,
      shape = null,
      circle = false;

  /// A circle [size] across: an avatar loading.
  const MinimalSkeleton.circle({super.key, double size = 32})
    : width = size,
      height = size,
      shape = null,
      lines = 1,
      circle = true;

  /// Null fills the available width.
  final double? width;

  /// Its height.
  final double height;

  /// The block's outline; null takes `shapes.mark`.
  final OutlinedBorder? shape;

  /// How many lines of text it stands for.
  final int lines;

  /// Whether it is a circle.
  final bool circle;

  @override
  State<MinimalSkeleton> createState() => _MinimalSkeletonState();
}

class _MinimalSkeletonState extends State<MinimalSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.minimalStill) {
      _pulse
        ..stop()
        ..value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final shape = widget.circle
        ? const CircleBorder()
        : widget.shape ?? t.shapes.mark;
    // The hairline's grey, not the quiet fill: pulsed down to half, the
    // quiet fill all but vanishes on a white page. By night the stronger
    // hairline's, for the same reason on the dark ground.
    final fill = t.isLightAppearance ? t.border : t.borderStrong;
    Widget block(double? width) => Container(
      width: width,
      height: widget.height,
      decoration: minimalFrame(shape, fill: fill),
    );
    final Widget body;
    if (widget.lines > 1) {
      body = LayoutBuilder(
        builder: (context, box) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < widget.lines; i++) ...[
              if (i > 0) const MinimalGap(MinimalSpacing.s8),
              block(
                i == widget.lines - 1 && box.maxWidth.isFinite
                    ? box.maxWidth * 0.6
                    : null,
              ),
            ],
          ],
        ),
      );
    } else {
      body = block(widget.width);
    }
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 1,
          end: 0.5,
        ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
        child: body,
      ),
    );
  }
}

/// How full something is against its limit — storage used, seats taken, a
/// budget spent: [label] and the reading ([valueLabel], else the
/// percentage in mono) over a 6 px bar (`shapes.pill`). The fill is the
/// ink while all is well, turns the warning colour from [warningAt] and the
/// danger colour from [destructiveAt], so the bar says when to act. Unlike a
/// progress bar it is not work in flight: it does not move on its own.
///
/// ```dart
/// MinimalMeter(label: 'Storage', value: 7.2, max: 10, valueLabel: '7.2 of 10 GB', warningAt: 0.8)
/// ```
class MinimalMeter extends StatelessWidget {
  /// A meter showing [value] of [max].
  const MinimalMeter({
    super.key,
    required this.label,
    required this.value,
    this.max = 1,
    this.valueLabel,
    this.warningAt,
    this.destructiveAt,
  }) : assert(max > 0);

  /// What it measures.
  final String label;

  /// How much.
  final double value;

  /// The most it holds.
  final double max;

  /// The reading as words ("7.2 of 10 GB"); null prints the percentage.
  final String? valueLabel;

  /// The fraction (0..1) from which the fill warns.
  final double? warningAt;

  /// The fraction (0..1) from which the fill is danger.
  final double? destructiveAt;

  static const double _height = 6;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final f = (value / max).clamp(0.0, 1.0);
    final danger = destructiveAt;
    final warn = warningAt;
    final fill = danger != null && f >= danger
        ? t.destructive
        : warn != null && f >= warn
        ? t.warning
        : t.foreground;
    final reading = valueLabel ?? '${(f * 100).round()}%';
    final shape = t.shapes.pill;
    final duration = context.minimalStill ? Duration.zero : MinimalMotion.base;
    return Semantics(
      container: true,
      label: label,
      value: reading,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.c(t.mutedForeground),
                  ),
                ),
                const MinimalGap(MinimalSpacing.s8),
                Text(reading, style: t.mono.c(t.foreground)),
              ],
            ),
            const MinimalGap(MinimalSpacing.s8),
            Container(
              height: _height,
              decoration: minimalFrame(shape, fill: t.border),
              child: minimalClip(
                shape,
                child: AnimatedFractionallySizedBox(
                  duration: duration,
                  curve: MinimalMotion.out,
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: f,
                  child: ColoredBox(color: fill),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
