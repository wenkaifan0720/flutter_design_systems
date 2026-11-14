// Status carved into the same material: the mark and the words carry its meaning.
import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/widgets.dart';

import 'controls.dart';
import 'frames.dart';
import 'knobs.dart';
import 'internal/geometry.dart' show neumorphicFillPaint;
import 'internal/text_entry.dart' show neumorphicLineHeight;
import 'component_themes.dart';
import 'styled.dart';
import 'shapes.dart';
import 'glyphs.dart';
import 'layout.dart';
import 'localizations.dart';
import 'theme.dart';

/// A message on a soft well, with its tone's own mark and optional next action.
///
/// ```dart
/// NeumorphicBanner('Your card expires soon.', title: 'Renew your card', tone: NeumorphicTone.warning)
/// ```
class NeumorphicBanner extends StatelessWidget {
  /// Creates a [NeumorphicBanner].
  const NeumorphicBanner(
    this.message, {
    super.key,
    this.style,
    this.title,
    this.tone = NeumorphicTone.info,
    this.mark,
    this.action,
    this.onDismiss,
    this.dismissLabel,
    this.live = false,
  });

  /// Frame styling before the shared card component theme.
  final NeumorphicStyle? style;

  /// The explanatory message.
  final String message;

  /// The primary heading.
  final String? title;

  /// The accessible label for dismissal; null uses localizations.
  final String? dismissLabel;

  /// The semantic tone used for the indicator and its colours.
  final NeumorphicTone tone;

  /// Custom status mark; the message still carries its meaning.
  final Widget? mark;

  /// An optional action displayed with the notice.
  final Widget? action;

  /// Called when the dismiss action is activated.
  final VoidCallback? onDismiss;

  /// Whether to emphasize the active state with the pigment colour.
  final bool live;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final words = NeumorphicLocalizations.of(context);
    final (glyph, heading) = switch (tone) {
      NeumorphicTone.info => (NeumorphicGlyphs.info, words.information),
      NeumorphicTone.success => (NeumorphicGlyphs.circleCheck, words.success),
      NeumorphicTone.warning => (NeumorphicGlyphs.triangleAlert, words.warning),
      NeumorphicTone.danger => (NeumorphicGlyphs.circleAlert, words.error),
    };
    final headStyle = t.textTheme.title;
    // The mark grows with the words, a little, and stands on the title's line however tall that line grows.
    final glyphSize = MediaQuery.textScalerOf(context)
        .scale(20)
        .clamp(20.0, 30.0);
    final line = math.max(
      neumorphicLineHeight(context, headStyle),
      glyphSize + 12,
    );
    // What needs you stands up off the notice's floor: a warning's mark on a raised bead, an error's on one warmed by
    // the pigment. Information and success stay carved in the floor, so the four tones differ in the material, not
    // only in their glyph.
    final calls =
        tone == NeumorphicTone.warning || tone == NeumorphicTone.danger;
    final Widget ownMark = calls
        ? CustomPaint(
            painter: _BeadPainter(
              const CircleBorder(),
              t.colors,
              null,
              tone == NeumorphicTone.danger ? 1 : 0,
              t.elevation,
              NeumorphicFlatScope.of(context),
            ),
            child: SizedBox.square(
              dimension: glyphSize + 12,
              child: Center(
                child: Icon(glyph, size: glyphSize, color: t.colors.ink),
              ),
            ),
          )
        // A carved mark takes the bead's width, so stacked notices' words start on one line whatever their tones.
        : SizedBox(
            width: glyphSize + 12,
            child: Center(
              child: Icon(glyph, size: glyphSize + 4, color: t.colors.ink),
            ),
          );
    return Semantics(
      container: true,
      liveRegion: live,
      child: NeumorphicSurface(
        style: style,
        themeStyle: NeumorphicTheme.of(context).cardTheme,
        cast: NeumorphicSurfaceLevel.well,
        outlined: true,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: SizedBox(
                height: line,
                child: Center(child: mark ?? ownMark),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: line),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: 1,
                      heightFactor: 1,
                      child: Text(title ?? heading, style: headStyle),
                    ),
                  ),
                  Text(message, style: t.textTheme.body),
                  if (action != null) ...[const SizedBox(height: 10), action!],
                ],
              ),
            ),
            // The words keep a gap to the close key; at 390 they ran to within 8 px of it.
            if (onDismiss != null) const SizedBox(width: 12),
            if (onDismiss != null)
              NeumorphicIconButton(
                NeumorphicGlyphs.close,
                label: dismissLabel ?? words.dismiss,
                onPressed: onDismiss,
              ),
          ],
        ),
      ),
    );
  }
}

class _Repeat extends StatefulWidget {
  const _Repeat({required this.enabled, required this.builder});
  final bool enabled;
  final Widget Function(BuildContext context, double phase) builder;
  @override
  State<_Repeat> createState() => _RepeatState();
}

class _RepeatState extends State<_Repeat> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);
  bool _running = false;
  void _sync() {
    final duration = NeumorphicMotion.of(context).travel * 6;
    final run =
        widget.enabled &&
        duration > Duration.zero &&
        TickerMode.valuesOf(context).enabled;
    if (!run) {
      _controller.stop();
    } else if (!_controller.isAnimating || _controller.duration != duration) {
      _controller.duration = duration;
      _controller.repeat();
    }
    _running = run;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Repeat old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) =>
          widget.builder(context, _running ? _controller.value : .25),
    ),
  );
}

/// An arc in the pigment in a pressed round groove: live work. With no value it travels until finished.
///
/// ```dart
/// NeumorphicCircularProgressIndicator(value: .4, label: 'Uploading', size: 32)
/// ```
class NeumorphicCircularProgressIndicator extends StatelessWidget {
  /// Creates a [NeumorphicCircularProgressIndicator].
  const NeumorphicCircularProgressIndicator({
    super.key,
    this.value,
    this.label,
    this.color,
    this.size = 28,
  }) : assert(size >= 12);

  /// The fraction complete, or null for indeterminate motion.
  final double? value;

  /// An accessible description of the operation.
  final String? label;

  /// An optional colour overriding the pigment of the arc (a busy button gives its own words' colour).
  final Color? color;

  /// The indicator diameter in logical pixels.
  final double size;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final words = NeumorphicLocalizations.of(context);
    final progress = value?.clamp(0.0, 1.0);
    return Semantics(
      role: progress == null
          ? SemanticsRole.loadingSpinner
          : SemanticsRole.progressBar,
      label: label ?? words.loading,
      // Flutter's progress role requires a machine-readable numeric range.
      minValue: progress == null ? null : '0',
      maxValue: progress == null ? null : '100',
      value: progress == null ? null : (progress * 100).round().toString(),
      child: neumorphicOwnSize(
        width: size,
        height: size,
        child: ExcludeSemantics(
          child: _Repeat(
            enabled: progress == null,
            builder: (context, phase) => CustomPaint(
              painter: _CircleProgressPainter(
                t.colors,
                color ?? t.colors.pigment,
                progress,
                phase,
                NeumorphicFlatScope.of(context),
                t.highContrast,
                t.elevation,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  const _CircleProgressPainter(
    this.colors,
    this.ink,
    this.value,
    this.phase,
    this.flat,
    this.highContrast,
    this.elevation,
  );
  final NeumorphicColors colors;
  final Color ink;
  final double? value;
  final double phase;
  final bool flat, highContrast;
  final NeumorphicElevation elevation;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(2);
    final width = (size.shortestSide / 8).clamp(2.0, 5.0);
    final track = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(rect.inflate(width / 2))
      ..addOval(rect.deflate(width / 2));
    neumorphicPaintPressed(
      canvas,
      track,
      colors,
      light: (const Offset(-1, -1), 2),
      dark: (const Offset(1, 1), 2),
      // A busy action supplies its own material beneath the progress ring.
      face: const LinearGradient(colors: [Color(0x00000000), Color(0x00000000)])
          .createShader(rect),
      flat: flat,
      elevation: elevation,
    );
    if (highContrast) {
      canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        Paint()
          ..color = colors.edge
          ..style = PaintingStyle.stroke
          ..strokeWidth = width,
      );
    }
    canvas.drawArc(
      rect,
      -math.pi / 2 + (value == null ? phase * math.pi * 2 : 0),
      (value ?? .25) * math.pi * 2,
      false,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CircleProgressPainter old) =>
      old.colors != colors ||
      old.ink != ink ||
      old.value != value ||
      old.phase != phase ||
      old.flat != flat ||
      old.highContrast != highContrast ||
      old.elevation != elevation;
}

/// A task's progress: a groove that fills with the pigment, or a slug of it travelling while the end is unknown.
///
/// ```dart
/// NeumorphicLinearProgressIndicator(value: .4, label: 'Uploading', note: '4 of 10 files')
/// ```
class NeumorphicLinearProgressIndicator extends StatelessWidget {
  /// Creates a [NeumorphicLinearProgressIndicator].
  const NeumorphicLinearProgressIndicator({
    super.key,
    this.value,
    required this.label,
    this.note,
    this.quiet = false,
  });

  /// The fraction complete, or null for indeterminate motion.
  final double? value;

  /// The text identifying this item or control.
  final String label;

  /// Supporting text displayed with the primary content.
  final String? note;

  /// Whether to use the quieter progress treatment.
  final bool quiet;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final progress = value?.clamp(0.0, 1.0);
    final percent = progress == null
        ? null
        : NeumorphicLocalizations.of(context).formatPercent(progress);
    final bar = SizedBox(
      height: 8,
      width: double.infinity,
      child: _Repeat(
        enabled: progress == null,
        builder: (context, phase) => CustomPaint(
          painter: _LineProgressPainter(
            t.colors,
            progress,
            phase,
            Directionality.of(context),
            NeumorphicFlatScope.of(context),
            t.highContrast,
            t.elevation,
            t.shapes.capsule,
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      role: progress == null
          ? SemanticsRole.loadingSpinner
          : SemanticsRole.progressBar,
      label: label,
      hint: note,
      minValue: progress == null ? null : '0',
      maxValue: progress == null ? null : '100',
      value: progress == null ? null : (progress * 100).round().toString(),
      child: ExcludeSemantics(
        child: quiet
            ? bar
            : NeumorphicColumn(
                gap: 8,
                children: [
                  // With no figure its label stands alone (an empty end dropped under a wrapped label as a blank line).
                  if (note == null && percent == null)
                    Text(label, style: t.textTheme.body)
                  else
                    NeumorphicSplit(
                      start: Text(label, style: t.textTheme.body),
                      end: Text(
                        (note ?? percent)!,
                        style: t.textTheme.caption.tabular,
                      ),
                    ),
                  bar,
                ],
              ),
      ),
    );
  }
}

class _LineProgressPainter extends CustomPainter {
  const _LineProgressPainter(
    this.colors,
    this.value,
    this.phase,
    this.direction,
    this.flat,
    this.highContrast,
    this.elevation,
    this.border,
  );
  final OutlinedBorder border;
  final NeumorphicColors colors;
  final double? value;
  final double phase;
  final TextDirection direction;
  final bool flat, highContrast;
  final NeumorphicElevation elevation;
  @override
  void paint(Canvas canvas, Size size) {
    final shape = border.getOuterPath((Offset.zero & size).deflate(.75));
    // The groove, then the pigment poured into it, then the groove's own shading again over the pigment, so the fill
    // lies in the groove and does not sit on it.
    const light = (Offset(-1.5, -1.5), 3.0), dark = (Offset(1.5, 1.5), 3.0);
    neumorphicPaintPressed(
      canvas,
      shape,
      colors,
      light: light,
      dark: dark,
      flat: flat,
      elevation: elevation,
    );
    final start = value == null ? phase * .75 : 0.0;
    final amount = value ?? .25;
    if (amount > 0) _pour(canvas, size, shape, start, amount, light, dark);
    if (highContrast) {
      canvas.drawPath(
        shape,
        Paint()
          ..color = colors.edge
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _pour(
    Canvas canvas,
    Size size,
    Path shape,
    double start,
    double amount,
    (Offset, double) light,
    (Offset, double) dark,
  ) {
    var fill = Rect.fromLTWH(
      start * size.width,
      0,
      amount * size.width,
      size.height,
    );
    if (direction == TextDirection.rtl) {
      fill = Rect.fromLTRB(
        size.width - fill.right,
        0,
        size.width - fill.left,
        size.height,
      );
    }
    final pour = border.getOuterPath(fill.deflate(.75));
    canvas.save();
    canvas.clipPath(shape);
    canvas.clipPath(pour);
    canvas.drawRect(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.pigmentDk, colors.pigment, colors.pigmentHi],
          stops: const [0, .45, 1],
        ).createShader(fill),
    );
    neumorphicPaintPressed(
      canvas,
      shape,
      colors,
      light: light,
      dark: dark,
      face: const LinearGradient(colors: [Color(0x00000000), Color(0x00000000)])
          .createShader(fill),
      tone: colors.pigment,
      flat: flat,
      elevation: elevation,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LineProgressPainter old) =>
      old.colors != colors ||
      old.value != value ||
      old.phase != phase ||
      old.direction != direction ||
      old.flat != flat ||
      old.highContrast != highContrast ||
      old.elevation != elevation ||
      old.border != border;
}

/// The shape of content being loaded, pressed into the wall as wells that slowly breathe (deeper, shallower); still
/// under Reduce Motion.
///
/// ```dart
/// NeumorphicSkeleton.lines(3)
/// ```
class NeumorphicSkeleton extends StatelessWidget {
  /// Creates a [NeumorphicSkeleton.lines].
  const NeumorphicSkeleton.lines(this.lines, {super.key, this.label})
    : aspect = null,
      row = false,
      assert(lines > 0);

  /// Creates a [NeumorphicSkeleton.box].
  const NeumorphicSkeleton.box({super.key, this.aspect = 16 / 9, this.label})
    : lines = 0,
      row = false,
      assert(aspect != null && aspect > 0);

  /// Creates a [NeumorphicSkeleton.row].
  const NeumorphicSkeleton.row({super.key, this.label})
    : lines = 2,
      aspect = null,
      row = true;

  /// The number of placeholder text lines.
  final int lines;

  /// The width divided by the height of the media or placeholder.
  final double? aspect;

  /// Whether to include a leading avatar placeholder.
  final bool row;

  /// The text identifying this item or control.
  final String? label;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    return Semantics(
      container: true,
      label: label ?? NeumorphicLocalizations.of(context).loading,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) {
            final width = box.hasBoundedWidth
                ? math.min(box.maxWidth, 640.0)
                : 240.0;
            final height = aspect != null
                ? width / aspect!
                : row
                ? 48.0
                : lines * 12.0 + (lines - 1) * 10;
            return neumorphicOwnSize(
              width: width,
              height: height,
              child: _Repeat(
                enabled: true,
                builder: (context, phase) => CustomPaint(
                  painter: _SkeletonPainter(
                    c,
                    phase,
                    lines,
                    row,
                    t.shapes,
                    t.elevation,
                    NeumorphicFlatScope.of(context),
                    Directionality.of(context) == TextDirection.rtl,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  const _SkeletonPainter(
    this.colors,
    this.phase,
    this.lines,
    this.row,
    this.shapes,
    this.elevation,
    this.flat,
    this.rtl,
  );
  final NeumorphicShapes shapes;
  final NeumorphicColors colors;
  final double phase;
  final int lines;
  final bool row, flat;

  /// The shape of the content mirrors as the content would (its avatar at the start, a short last line ending
  /// early); the light stays top-left.
  final bool rtl;
  final NeumorphicElevation elevation;
  @override
  void paint(Canvas canvas, Size size) {
    // One breath per turn: the wells deepen and ease back, never quite flat.
    final breath = .5 - .5 * math.cos(phase * math.pi * 2);
    final k = .55 + .45 * breath;
    final well = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colors.wellStart, colors.wellEnd],
    ).createShader(Offset.zero & size);
    Rect start(Rect r) => rtl
        ? Rect.fromLTRB(
            size.width - r.right,
            r.top,
            size.width - r.left,
            r.bottom,
          )
        : r;
    void bone(Rect rect, double radius) => neumorphicPaintPressed(
      canvas,
      shapes.corner(radius).getOuterPath(start(rect)),
      colors,
      light: (Offset(-2, -2) * k, 4 * k),
      dark: (Offset(2, 2) * k, 4 * k),
      face: well,
      flat: flat,
      elevation: elevation,
    );
    if (lines == 0) {
      bone(Offset.zero & size, NeumorphicRadii.control);
      return;
    }
    final offset = row ? math.min(62.0, size.width / 3) : 0.0;
    if (row) bone(Rect.fromLTWH(0, 0, math.max(0, offset - 10), 48), 12);
    for (var i = 0; i < lines; i++) {
      bone(
        Rect.fromLTWH(
          offset,
          (row ? 7 : 0) + i * 22,
          (size.width - offset) * (i == lines - 1 && lines > 1 ? .65 : 1),
          12,
        ),
        4,
      );
    }
  }

  @override
  bool shouldRepaint(_SkeletonPainter old) =>
      old.colors != colors ||
      old.phase != phase ||
      old.lines != lines ||
      old.row != row ||
      old.shapes != shapes ||
      old.elevation != elevation ||
      old.flat != flat ||
      old.rtl != rtl;
}

/// A completed task, with a pressed check and the next action below its explanation.
///
/// ```dart
/// NeumorphicSuccessState(title: 'All set', message: 'Your changes are saved.', action: nextButton)
/// ```
class NeumorphicSuccessState extends StatelessWidget {
  /// Creates a [NeumorphicSuccessState].
  const NeumorphicSuccessState({
    super.key,
    required this.title,
    this.message,
    this.action,
  });

  /// The primary heading.
  final String title;

  /// The explanatory message.
  final String? message;

  /// An optional action beneath the success message.
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: SizedBox.square(
                dimension: 56,
                child: NeumorphicSurface(
                  cast: NeumorphicSurfaceLevel.groove,
                  round: true,
                  outlined: true,
                  child: Center(
                    child: Icon(
                      NeumorphicGlyphs.check,
                      size: 30,
                      color: t.colors.ink,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: t.textTheme.value,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: t.textTheme.body,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

/// How far a badge's bead reaches in over its child's end edge: none. The bead is a bump of the wall, and so is a
/// portrait or a key: two bumps of one surface stand side by side and never stack.
const double _badgeOverlap = 0;

/// A count on a small raised bead, its figure in the ink. A count that goes up warms the bead with the pigment for a
/// moment, the look's sign of something new. Zero disappears, and large counts use a plus sign.
///
/// ```dart
/// NeumorphicBadge(3, label: '3 unread', child: Icon(NeumorphicGlyphs.bell))
/// ```
class NeumorphicBadge extends StatelessWidget {
  /// Creates a [NeumorphicBadge].
  const NeumorphicBadge(
    this.count, {
    super.key,
    this.label,
    this.max = 99,
    this.child,
    this.style,
  }) : assert(max > 0);

  /// Count plate and type before the badge theme.
  final NeumorphicStyle? style;

  /// The number represented by the badge.
  final int count;

  /// The highest count shown exactly; larger counts gain a plus sign.
  final int max;

  /// An optional accessible description of the count.
  final String? label;

  /// Optional content carrying the badge.
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child ?? const SizedBox.shrink();
    final t = NeumorphicTheme.of(context);
    final words = NeumorphicLocalizations.of(context);
    final number = count > max
        ? '${words.formatNumber(max)}+'
        : words.formatNumber(count);
    final look = NeumorphicStyleOf([style, t.badgeTheme], const {});
    var shape = look.shape ?? t.shapes.capsule;
    final text = t.textTheme.micro
        .copyWith(color: t.colors.ink, fontWeight: FontWeight.w700)
        .merge(look.textStyle)
        .copyWith(color: look.foreground);
    final padding =
        look.padding(Directionality.of(context)) ??
        const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
    final measure = TextPainter(
      text: TextSpan(text: number, style: text),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    double? diameter;
    if (shape is NeumorphicCircleBorder) {
      diameter =
          math.max(
            measure.width + padding.horizontal,
            measure.height + padding.vertical,
          ) *
          math.sqrt2;
      diameter = math.max(
        diameter,
        math.max(look.minimumSize?.width ?? 0, look.minimumSize?.height ?? 0),
      );
      shape = shape.fit(Size.square(diameter));
    }
    // The plate's size, so a badge on a child overlaps the child's corner by the same amount whatever its count.
    final rimInsets = shape.dimensions.resolve(Directionality.of(context));
    final plateHeight = math.max(
      measure.height + padding.vertical + rimInsets.vertical,
      look.minimumSize?.height ?? 0,
    );
    // A bead is never narrower than it is tall: one figure is a round bead at any text size (at 2.0 a "3" stood in a
    // tall narrow pill).
    final plate = diameter != null
        ? Size.square(diameter)
        : Size(
            math.max(
              math.max(
                measure.width + padding.horizontal + rimInsets.horizontal,
                look.minimumSize?.width ?? 0,
              ),
              plateHeight,
            ),
            plateHeight,
          );
    measure.dispose();
    final badge = Semantics(
      label: label ?? words.formatNumber(count),
      child: ExcludeSemantics(
        child: _Fresh(
          count: count,
          builder: (context, fresh) => AnimatedNeumorphicShape(
            shape: shape,
            builder: (context, border) {
              final outline = border ?? t.shapes.corner(6);
              final rim =
                  look.side ??
                  (look.edge == null
                      ? BorderSide.none
                      : BorderSide(
                          color: look.edge!,
                          width: neumorphicEdgeWidth,
                        ));
              Widget content = Padding(
                padding:
                    padding +
                    (border?.dimensions.resolve(Directionality.of(context)) ??
                        EdgeInsets.zero),
                // A count past the most is a number with its sign, and reads "99+" in either direction, as the
                // avatar cluster's "+3" does: set in the page's direction it read "+99" right to left.
                child: Text(
                  number,
                  style: text,
                  textAlign: TextAlign.center,
                  textDirection: count > max ? TextDirection.ltr : null,
                ),
              );
              if (diameter != null) {
                content = SizedBox.square(
                  dimension: diameter,
                  child: Center(child: content),
                );
              } else {
                content = ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: plate.width,
                    minHeight: plate.height,
                  ),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: content,
                  ),
                );
              }
              return CustomPaint(
                painter: _BeadPainter(
                  outline,
                  t.colors,
                  look.fill,
                  fresh,
                  t.elevation,
                  NeumorphicFlatScope.of(context),
                ),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: outline.copyWith(side: rim),
                  ),
                  child: content,
                ),
              );
            },
          ),
        ),
      ),
    );
    if (child == null) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: badge,
      );
    }
    // On a child the bead stands beside its top-end corner, on the wall, its middle level with the child's top edge: it
    // never lies over what the child shows (an avatar's face, a key, an icon's middle). The child keeps its own line, level with the plain ones beside it: the plate rises half its height
    // into the space above, as Material's badge does, and only the room it reaches past the end is kept, so it never
    // covers the words beside the child.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            end: math.max(0, plate.width - _badgeOverlap),
          ),
          child: child!,
        ),
        PositionedDirectional(top: -plate.height / 2, end: 0, child: badge),
      ],
    );
  }
}

/// How new a badge's count is: 1 the moment it goes up, easing to 0. Still under Reduce Motion.
class _Fresh extends StatefulWidget {
  const _Fresh({required this.count, required this.builder});
  final int count;
  final Widget Function(BuildContext context, double fresh) builder;
  @override
  State<_Fresh> createState() => _FreshState();
}

class _FreshState extends State<_Fresh> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, value: 0);

  @override
  void didUpdateWidget(_Fresh old) {
    super.didUpdateWidget(old);
    final motion = NeumorphicMotion.of(context);
    if (widget.count > old.count && motion.leave > Duration.zero) {
      _controller.duration = motion.leave * 12;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => widget.builder(
      context,
      _controller.isAnimating
          ? 1 - Curves.easeIn.transform(_controller.value)
          : 0,
    ),
  );
}

/// A badge's bead: raised off what it sits on, its face the material's (or an app's fill), its lit side and face
/// warmed by the pigment while the count is [fresh].
class _BeadPainter extends CustomPainter {
  const _BeadPainter(
    this.border,
    this.c,
    this.fill,
    this.fresh,
    this.elevation,
    this.flat,
  );
  final ShapeBorder border;
  final NeumorphicColors c;
  final Color? fill;
  final double fresh;
  final NeumorphicElevation elevation;
  final bool flat;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final shape = border.getOuterPath(box);
    final warm = Color.lerp(c.highlight, c.pigmentHi, .6 * fresh)!;
    neumorphicPaintRaised(
      canvas,
      shape,
      c,
      light: (const Offset(-1.5, -1.5), 3),
      dark: (const Offset(1.5, 1.5), 4),
      lightColor: warm,
      face: fill == null
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.faceStart, c.faceEnd],
            ).createShader(box)
          : LinearGradient(colors: [fill!, fill!]).createShader(box),
      flat: flat,
      elevation: elevation,
    );
    if (fresh > 0) {
      canvas.drawPath(
        shape,
        neumorphicFillPaint(c.wash.withValues(alpha: c.wash.a * 2 * fresh)),
      );
    }
  }

  @override
  bool shouldRepaint(_BeadPainter old) =>
      old.border != border ||
      old.c != c ||
      old.fill != fill ||
      old.fresh != fresh ||
      old.elevation != elevation ||
      old.flat != flat;
}
