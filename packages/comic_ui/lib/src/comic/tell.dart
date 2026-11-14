/// Status in print: marks, announcements, progress and waiting space.
library;

import 'package:ui_core/ui_core.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'glyphs.dart';

import 'controls.dart';
import 'frames.dart';
import 'localizations.dart';
import 'theme.dart';
import 'component_themes.dart';
import 'styled.dart';
import 'layout.dart';
import 'tones.dart';
import 'internal/cap_label.dart';

/// A different mark for every meaning, so colour is never the only cue.
///
/// ```dart
/// ComicToneMark(ComicTone.warning)
/// ```
class ComicToneMark extends StatelessWidget {
  /// Creates a status mark.
  const ComicToneMark(this.tone, {super.key, this.size = 28});

  /// The meaning.
  final ComicTone tone;

  /// Mark size.
  final double size;
  @override
  Widget build(BuildContext context) => Icon(
    switch (tone) {
      ComicTone.info => ComicGlyphs.info,
      ComicTone.success => ComicGlyphs.circleCheck,
      ComicTone.warning => ComicGlyphs.triangleAlert,
      ComicTone.danger => ComicGlyphs.octagonAlert,
    },
    color: ComicTheme.of(context).colors.tones.of(tone),
    size: size,
  );
}

/// A status panel with a mark, words and optional action.
///
/// ```dart
/// ComicBanner('Your issue is ready', tone: ComicTone.success)
/// ```
class ComicBanner extends StatelessWidget {
  /// Creates an in-page announcement.
  const ComicBanner(
    this.message, {
    super.key,
    this.title,
    this.tone = ComicTone.info,
    this.action,
    this.onDismiss,
    this.dismissLabel,
    this.live = false,
    this.leading,
  });

  /// Message text.
  final String message;

  /// Optional heading.
  final String? title;

  /// The meaning, expressed by ink and mark.
  final ComicTone tone;

  /// Optional action below the words.
  final Widget? action;

  /// Dismiss callback; absent hides the control.
  final VoidCallback? onDismiss;

  /// Overrides the localized dismiss label.
  final String? dismissLabel;

  /// Announces changes as they arrive.
  final bool live;

  /// Optional replacement for the tone's mark.
  final Widget? leading;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return Semantics(
      container: true,
      liveRegion: live,
      child: ComicPanel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: leading ?? ComicToneMark(tone)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(title!, style: t.type.title),
                    const SizedBox(height: 4),
                  ],
                  Text(message, style: t.type.body),
                  if (action != null) ...[const SizedBox(height: 8), action!],
                ],
              ),
            ),
            if (onDismiss != null)
              ComicIconButton(
                ComicGlyphs.x,
                label: dismissLabel ?? ComicLocalizations.of(context).dismiss,
                onPressed: onDismiss,
              ),
          ],
        ),
      ),
    );
  }
}

/// A twelve-point burst whose ink advances with progress, or turns while waiting.
///
/// ```dart
/// ComicCircularProgressIndicator(value: .6, label: 'Uploading')
/// ```
class ComicCircularProgressIndicator extends StatefulWidget {
  /// Creates a progress burst. Null value means indeterminate.
  const ComicCircularProgressIndicator({
    super.key,
    this.value,
    this.size = 32,
    this.label,
    this.color,
  }) : assert(value == null || value >= 0 && value <= 1),
       assert(size > 0);

  /// Completed fraction, or null while the end is unknown.
  final double? value;

  /// Width and height of the burst.
  final double size;

  /// Overrides the localized loading label.
  final String? label;

  /// Overrides the ink.
  final Color? color;
  @override
  State<ComicCircularProgressIndicator> createState() =>
      _ComicCircularProgressState();
}

class _ComicCircularProgressState extends State<ComicCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(vsync: this);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ComicCircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final duration = ComicMotion.of(context).spinner;
    final changed = _motion.duration != duration;
    _motion.duration = duration;
    if (widget.value == null &&
        duration > Duration.zero &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled) {
      if (!_motion.isAnimating || changed) _motion.repeat();
    } else {
      _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    return Semantics(
      label: widget.label ?? DesignLocalizations.of(context).loadingLabel,
      value: widget.value == null ? null : '${(widget.value! * 100).round()}%',
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _motion,
          builder: (context, _) => comicOwnSize(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _BurstProgress(
                widget.value,
                _motion.value,
                widget.color ?? c.primaryText,
                c.track,
                // The line's colour, cream at night: the hero burst keeps black because its fill is lit, but this star's
                // unlit track is navy, and a black contour sank it into the night ground (r5).
                c.nightLine,
                t.rim(1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BurstProgress extends CustomPainter {
  _BurstProgress(
    this.value,
    this.turn,
    this.ink,
    this.track,
    this.line,
    this.lineWidth,
  );
  final double? value;
  final double turn;
  final Color ink, track, line;
  final double lineWidth;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero),
            // The contour stands inside the box: half its line in from the tips.
            radius =
            math.min(size.width, size.height) / 2 - lineWidth / 2;
    // The star's one contour, round every ray's tip and the notches between them: a burst is printed with its
    // outline, so the unlit rays read as paper inside it rather than a pale smudge on the ground.
    final outline = Path();
    var first = true;
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6 - math.pi / 2;
      for (final (a, r) in [
        (angle - .25, .68),
        (angle, 1.0),
        (angle + .25, .68),
      ]) {
        final p = center + Offset(math.cos(a), math.sin(a)) * radius * r;
        if (first) {
          outline.moveTo(p.dx, p.dy);
          first = false;
        } else {
          outline.lineTo(p.dx, p.dy);
        }
      }
    }
    outline.close();
    // The star in its track's ink, then the lit rays as one shape over it: twelve rays filled one by one left a pale
    // seam between neighbours (r4, a fan of slices).
    canvas.drawPath(outline, Paint()..color = track);
    final lit = Path();
    for (var i = 0; i < 12; i++) {
      final on = value == null
          ? (i - (turn * 12).floor()) % 12 < 3
          : i < (value! * 12).ceil();
      if (!on) continue;
      final angle = i * math.pi / 6 - math.pi / 2;
      Offset point(double a, double r) =>
          center + Offset(math.cos(a), math.sin(a)) * radius * r;
      lit
        ..moveTo(center.dx, center.dy)
        ..lineTo(point(angle - .25, .68).dx, point(angle - .25, .68).dy)
        ..lineTo(point(angle, 1).dx, point(angle, 1).dy)
        ..lineTo(point(angle + .25, .68).dx, point(angle + .25, .68).dy)
        ..close();
    }
    canvas.drawPath(lit, Paint()..color = ink);
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth
        ..strokeJoin = StrokeJoin.round
        ..color = line,
    );
  }

  @override
  bool shouldRepaint(_BurstProgress old) =>
      old.value != value ||
      old.turn != turn ||
      old.ink != ink ||
      old.track != track ||
      old.line != line ||
      old.lineWidth != lineWidth;
}

/// A ruled progress strip. Unknown progress advances a small inked segment.
///
/// ```dart
/// ComicLinearProgressIndicator(value: .4, label: 'Reading progress')
/// ```
class ComicLinearProgressIndicator extends StatefulWidget {
  /// Creates a progress strip.
  const ComicLinearProgressIndicator({
    super.key,
    this.value,
    this.label,
    this.height = 12,
  }) : assert(value == null || value >= 0 && value <= 1);

  /// Completed fraction, or null while unknown.
  final double? value;

  /// Overrides the localized loading label.
  final String? label;

  /// Strip height.
  final double height;
  @override
  State<ComicLinearProgressIndicator> createState() =>
      _ComicLinearProgressIndicatorState();
}

class _ComicLinearProgressIndicatorState
    extends State<ComicLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(vsync: this);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ComicLinearProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final duration = ComicMotion.of(context).progress;
    final changed = _motion.duration != duration;
    _motion.duration = duration;
    if (widget.value == null &&
        duration > Duration.zero &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled) {
      if (!_motion.isAnimating || changed) _motion.repeat(reverse: true);
    } else {
      _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    return Semantics(
      label: widget.label ?? DesignLocalizations.of(context).loadingLabel,
      value: widget.value == null ? null : '${(widget.value! * 100).round()}%',
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _motion,
          builder: (context, _) => Container(
            height: widget.height,
            decoration: ShapeDecoration(
              color: c.track,
              shape: t.shapes.capsule.copyWith(
                side: BorderSide(color: c.nightLine, width: t.rim(2)),
              ),
            ),
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: comicInsetShape(t.shapes.capsule, t.rim(2)),
              ),
              child: Align(
                alignment: AlignmentDirectional(
                  widget.value == null ? -1 + _motion.value * 2 : -1,
                  0,
                ),
                child: FractionallySizedBox(
                  widthFactor: widget.value ?? .25,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: c.primaryText,
                      shape: comicInsetShape(t.shapes.capsule, t.rim(2)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A quiet placeholder that pulses unless reduced motion is requested.
///
/// ```dart
/// ComicSkeleton(width: 160, height: 20)
/// ```
class ComicSkeleton extends StatefulWidget {
  /// Creates a placeholder.
  const ComicSkeleton({super.key, this.width, this.height = 20, this.label});

  /// Width, or the available width.
  final double? width;

  /// Height.
  final double height;

  /// Optional accessible loading label; null is decorative.
  final String? label;
  @override
  State<ComicSkeleton> createState() => _ComicSkeletonState();
}

class _ComicSkeletonState extends State<ComicSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(vsync: this);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final duration = ComicMotion.of(context).pulse;
    final changed = _motion.duration != duration;
    _motion.duration = duration;
    if (duration > Duration.zero &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled) {
      if (!_motion.isAnimating || changed) _motion.repeat(reverse: true);
    } else {
      _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: FadeTransition(
          opacity: Tween<double>(begin: .5, end: 1).animate(_motion),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: ComicTheme.of(context).colors.track,
                shape: ComicTheme.of(context).shapes.small,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A count in a small square caption, with room for large text.
///
/// ```dart
/// ComicBadge(12, label: 'Unread issues')
/// ```
class ComicBadge extends StatelessWidget {
  /// Creates a count badge.
  const ComicBadge(this.count, {super.key, this.label, this.style});

  /// Appearance above the badge component theme.
  final ComicStyle? style;

  /// Count displayed without clipping.
  final int count;

  /// What is being counted.
  final String? label;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final look = ComicStyleOf([style, t.badgeTheme], const {}),
        rim = comicRim(
          t,
          ComicStyleOf([style, t.badgeTheme], const {}),
          t.colors.nightLine,
          2,
        );
    return Semantics(
      label: label,
      value: '$count',
      child: ExcludeSemantics(
        child: AnimatedComicShape(
          shape: look.shape ?? t.shapes.capsule,
          builder: (context, shape) => Container(
            constraints: BoxConstraints(
              minWidth: look.minimumSize?.width ?? 0,
              minHeight: look.minimumSize?.height ?? 0,
            ),
            padding:
                (look.padding(Directionality.of(context)) ??
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2))
                    .add(
                      shape == null ? EdgeInsets.zero : const EdgeInsets.all(6),
                    ),
            decoration: ShapeDecoration(
              color: look.fill ?? t.colors.caption,
              shape: (shape ?? const RoundedRectangleBorder()).copyWith(
                side: rim,
              ),
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: CapLabel(
                child: Text(
                  '$count',
                  style: t.type.small
                      .merge(look.textStyle)
                      .copyWith(color: look.foreground ?? t.colors.onCaption),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A successful result with optional follow-up action.
///
/// ```dart
/// ComicSuccessState(title: 'All set', message: 'Your issue is saved')
/// ```
class ComicSuccessState extends StatelessWidget {
  /// Creates a success panel.
  const ComicSuccessState({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });

  /// Result heading.
  final String title;

  /// Supporting words.
  final String message;

  /// Optional next action.
  final Widget? action;
  @override
  Widget build(BuildContext context) => ComicBanner(
    message,
    title: title,
    tone: ComicTone.success,
    action: action,
    live: true,
  );
}
