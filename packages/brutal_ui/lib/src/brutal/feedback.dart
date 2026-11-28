/// Brutal's feedback: [BrutalNotice], an inline alert led by a cell of its
/// tone; [BrutalStateView], what a page says when it is empty, failed,
/// loading or done; [BrutalSpinner], a heavy bar running round a square;
/// [BrutalProgressBar], a bar filling a ruled track.
library;

import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_core/ui_core.dart';

import 'lists.dart' show BrutalRule;
import 'surface.dart';
import 'theme.dart';

/// What a [BrutalNotice] says about what happened.
enum BrutalNoticeTone {
  /// Plain news: an ink cell.
  info,

  /// It worked: a lime cell.
  success,

  /// Look before going on: an orange cell.
  warning,

  /// It failed: a red cell.
  danger,
}

/// An inline alert: a ruled box whose first cell is filled with its
/// [tone], holding the tone's glyph, then the [title], an optional
/// [message] and [actions] (text buttons, as a rule).
///
/// It is flat: it is read, not pressed. A [BrutalNoticeTone.warning] or
/// [BrutalNoticeTone.danger] notice is announced when it appears.
///
/// Reads [style]'s `fill` (the box), `edge` (its rules), `foreground` (the
/// words), `padding` (round the words), `textStyle` (the title) and
/// `iconSize`, then [BrutalThemeData.noticeStyle]'s. The lead cell keeps its
/// tone's colour: it says what happened.
///
/// ```dart
/// const BrutalNotice(tone: BrutalNoticeTone.danger, title: 'Your bank declined the card', message: 'Nothing was charged.')
/// ```
class BrutalNotice extends StatelessWidget {
  /// A notice reading [title].
  const BrutalNotice({
    super.key,
    required this.title,
    this.message,
    this.tone = BrutalNoticeTone.info,
    this.icon,
    this.actions = const [],
    this.live,
    this.style,
  });

  /// What happened, in one line.
  final String title;

  /// What it means and what to do.
  final String? message;

  /// The kind of news; picks the lead cell's colour and glyph.
  final BrutalNoticeTone tone;

  /// A glyph in place of the tone's own.
  final Widget? icon;

  /// What can be done about it, after the words.
  final List<Widget> actions;

  /// Whether it is announced as it appears; null announces a warning and a
  /// danger notice.
  final bool? live;

  /// Its style, over [BrutalThemeData.noticeStyle].
  final BrutalStyle? style;

  /// The lead cell's colour for [tone] in [colors]: ink for news, the
  /// danger red for a failure, and for a success and a warning the look's
  /// own lime and orange, whatever the palette. A palette recolours the
  /// signal and the lead block, often to one hue; what happened keeps hues
  /// of its own, told apart in every palette.
  static Color fillOf(BrutalColors colors, BrutalNoticeTone tone) {
    final own = colors.brightness == Brightness.dark
        ? const BrutalColors.dark()
        : const BrutalColors.light();
    return switch (tone) {
      BrutalNoticeTone.info => colors.ink,
      BrutalNoticeTone.success => own.lead,
      BrutalNoticeTone.warning => own.signal,
      BrutalNoticeTone.danger => colors.danger,
    };
  }

  /// The width of the lead cell.
  static const double leadWidth = 48;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final fill = fillOf(c, tone);
    final glyph = switch (tone) {
      BrutalNoticeTone.info => LucideIcons.info,
      BrutalNoticeTone.success => LucideIcons.check,
      BrutalNoticeTone.warning => LucideIcons.triangleAlert,
      BrutalNoticeTone.danger => LucideIcons.circleAlert,
    };
    final urgent =
        live ??
        (tone == BrutalNoticeTone.warning || tone == BrutalNoticeTone.danger);
    final layered = RawStyleOf([style, theme.noticeStyle], const {});
    final face = layered.on(
      BrutalFace(fill: c.surface, border: c.ink, foreground: c.ink),
    );
    final glyphSize = layered.iconSize ?? _glyph;
    return Semantics(
      container: true,
      liveRegion: urgent,
      child: BrutalSurface(
        face: face,
        child: Stack(
          children: [
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              width: leadWidth,
              child: ColoredBox(
                color: fill,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    // The glyph centred on the title's line.
                    padding: EdgeInsets.only(
                      top:
                          BrutalSpacing.regular +
                          ((t.label.fontSize ?? 16) * (t.label.height ?? 1) -
                                  glyphSize) /
                              2,
                    ),
                    child: ExcludeSemantics(
                      child: IconTheme(
                        data: IconThemeData(
                          color: c.onColor(fill),
                          size: glyphSize,
                        ),
                        child: icon ?? Icon(glyph),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              start: leadWidth,
              top: 0,
              bottom: 0,
              child: BrutalRule(vertical: true, color: face.border),
            ),
            Padding(
              padding:
                  EdgeInsetsDirectional.only(
                    start: leadWidth + theme.borderWidth,
                  ).add(
                    layered.padding(Directionality.of(context)) ??
                        const EdgeInsets.all(BrutalSpacing.regular),
                  ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: layered.text(
                      t.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: face.foreground,
                      ),
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: BrutalSpacing.tight),
                    Text(
                      message!,
                      style: t.secondary.copyWith(color: layered.foreground),
                    ),
                  ],
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: BrutalSpacing.medium),
                    Wrap(
                      spacing: BrutalSpacing.large,
                      runSpacing: BrutalSpacing.small,
                      children: actions,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const double _glyph = 20;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(EnumProperty<BrutalNoticeTone>('tone', tone));
  }
}

/// What a [BrutalStateView] reports.
enum BrutalState {
  /// Nothing here yet, or nothing matches.
  empty,

  /// It failed.
  error,

  /// It is on its way.
  loading,

  /// It worked.
  success,
}

/// What a page or a panel shows in place of its content: a square cell
/// with the [state]'s glyph (a [BrutalSpinner] while loading), a [title],
/// a [message] and [actions], all on the content's leading edge.
///
/// Reads [style]'s `fill`, `edge` and `foreground` for the glyph's cell,
/// `minimumSize` (the cell's side), `textStyle` (the title) and `iconSize`,
/// then [BrutalThemeData.stateViewStyle]'s.
///
/// ```dart
/// BrutalStateView(state: BrutalState.empty, title: 'Nothing matches “jazz”', message: 'Try a venue, or see the whole week.', actions: [BrutalButton('Clear search', onPressed: () {})])
/// ```
class BrutalStateView extends StatelessWidget {
  /// A view of [state] titled [title].
  const BrutalStateView({
    super.key,
    required this.state,
    required this.title,
    this.message,
    this.icon,
    this.actions = const [],
    this.style,
  });

  /// Which state it reports.
  final BrutalState state;

  /// What it is, in a few words.
  final String title;

  /// Why, and what to do next.
  final String? message;

  /// A glyph in place of the state's own (not shown while loading).
  final Widget? icon;

  /// What can be done: one framed or filled button, perhaps a text one.
  final List<Widget> actions;

  /// Its style, over [BrutalThemeData.stateViewStyle].
  final BrutalStyle? style;

  /// The side of the glyph's cell.
  static const double cellSize = 64;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final (fill, glyph) = switch (state) {
      BrutalState.empty => (c.surface, LucideIcons.inbox),
      BrutalState.error => (c.danger, LucideIcons.circleAlert),
      BrutalState.loading => (c.surface, null),
      BrutalState.success => (
        BrutalNotice.fillOf(c, BrutalNoticeTone.success),
        LucideIcons.check,
      ),
    };
    final layered = RawStyleOf([style, theme.stateViewStyle], const {});
    final face = layered.on(
      BrutalFace(fill: fill, border: c.ink, foreground: c.onColor(fill)),
    );
    final words = face.foreground;
    return Semantics(
      container: true,
      liveRegion: state != BrutalState.empty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: layered.minimumSize?.height ?? cellSize,
            child: BrutalSurface(
              face: face,
              child: Center(
                child: glyph == null
                    ? BrutalSpinner(color: words)
                    : ExcludeSemantics(
                        child: IconTheme(
                          data: IconThemeData(
                            color: words,
                            size: layered.iconSize ?? 28,
                          ),
                          child: icon ?? Icon(glyph),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: BrutalSpacing.large),
          Semantics(
            header: true,
            child: Text(title, style: layered.text(t.title)),
          ),
          if (message != null) ...[
            const SizedBox(height: BrutalSpacing.small),
            Text(message!, style: t.body.copyWith(color: c.inkMuted)),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: BrutalSpacing.large),
            Wrap(
              spacing: BrutalSpacing.regular,
              runSpacing: BrutalSpacing.regular,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<BrutalState>('state', state))
      ..add(StringProperty('title', title));
  }
}

/// A heavy bar running round a square, for work of no known length. With
/// animations off it stands still, a quarter of the way round.
///
/// Reads [style]'s `foreground` (under [color]), then
/// [BrutalThemeData.spinnerStyle]'s.
///
/// ```dart
/// const BrutalSpinner(semanticLabel: 'Paying')
/// ```
class BrutalSpinner extends StatefulWidget {
  /// A spinner [size] square.
  const BrutalSpinner({
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
    this.style,
  });

  /// Its side.
  final double size;

  /// Its ink; the text colour around it when null.
  final Color? color;

  /// What a screen reader says it waits for; silent when null (the words
  /// beside it say so).
  final String? semanticLabel;

  /// Its style, over [BrutalThemeData.spinnerStyle].
  final BrutalStyle? style;

  @override
  State<BrutalSpinner> createState() => _BrutalSpinnerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('size', size, defaultValue: 24));
  }
}

class _BrutalSpinnerState extends State<BrutalSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  // From build: iOS's Reduce Motion changes arrive as a build, never as
  // didChangeDependencies (rawReduceMotionOf).
  void _sync() {
    if (!rawReduceMotionOf(context)) {
      if (!_turn.isAnimating) _turn.repeat();
    } else if (_turn.isAnimating || _turn.value != 0) {
      _turn
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    final theme = BrutalTheme.of(context);
    final ink =
        widget.color ??
        RawStyleOf([widget.style, theme.spinnerStyle], const {}).foreground ??
        DefaultTextStyle.of(context).style.color ??
        theme.colors.ink;
    final spinner = SizedBox.square(
      dimension: widget.size,
      child: RepaintBoundary(
        child: CustomPaint(painter: _RunPainter(_turn, ink, theme.borderWidth)),
      ),
    );
    final label = widget.semanticLabel;
    return label == null
        ? ExcludeSemantics(child: spinner)
        : Semantics(label: label, liveRegion: true, child: spinner);
  }
}

class _RunPainter extends CustomPainter {
  _RunPainter(this.turn, this.color, this.track) : super(repaint: turn);

  final Animation<double> turn;
  final Color color;
  final double track;

  @override
  void paint(Canvas canvas, Size size) {
    final heavy = math.max(track * 2, size.shortestSide / 6);
    final square = (Offset.zero & size).deflate(heavy / 2);
    canvas.drawRect(
      square,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = track
        ..color = color,
    );
    final metric = (Path()..addRect(square)).computeMetrics().first;
    final length = metric.length;
    final start = turn.value * length;
    final run = length / 4;
    final bar = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = heavy
      ..strokeCap = StrokeCap.square
      ..color = color;
    _extract(canvas, metric, start, math.min(start + run, length), bar);
    if (start + run > length) {
      _extract(canvas, metric, 0, start + run - length, bar);
    }
  }

  void _extract(Canvas c, PathMetric m, double a, double b, Paint p) =>
      c.drawPath(m.extractPath(a, b), p);

  @override
  bool shouldRepaint(_RunPainter old) =>
      old.color != color || old.track != track;
}

/// A ruled track a solid bar fills: by [value] (0 to 1) when the work's
/// length is known, a block sliding along it while [value] is null.
///
/// Reads [style]'s `fill` (the track), `edge` (its rule), `foreground` (the
/// bar, under [color]) and `minimumSize` (its height, under [height]), then
/// [BrutalThemeData.progressBarStyle]'s.
///
/// ```dart
/// const BrutalProgressBar(value: 0.6, semanticLabel: 'Upload')
/// ```
class BrutalProgressBar extends StatelessWidget {
  /// A bar at [value].
  const BrutalProgressBar({
    super.key,
    this.value,
    this.color,
    this.semanticLabel,
    this.height,
    this.style,
  });

  /// How far along, 0 to 1; null for work of no known length.
  final double? value;

  /// The fill; ink when null.
  final Color? color;

  /// What it measures, for a screen reader.
  final String? semanticLabel;

  /// The track's height, its rule included; 16 when neither this nor a
  /// style says.
  final double? height;

  /// Its style, over [BrutalThemeData.progressBarStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.progressBarStyle], const {});
    final fill = color ?? layered.foreground ?? c.ink;
    final v = value?.clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel,
      value: v == null ? null : '${(v * 100).round()}%',
      child: SizedBox(
        height: height ?? layered.minimumSize?.height ?? 16,
        child: BrutalSurface(
          face: BrutalFace(
            fill: layered.fill ?? c.surface,
            border: layered.side?.color ?? layered.edge ?? c.ink,
            foreground: c.ink,
          ),
          child: v == null
              ? _Sliding(color: fill)
              : TweenAnimationBuilder<double>(
                  tween: Tween(end: v),
                  duration: rawReduceMotionOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  builder: (context, f, _) => FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: f,
                    heightFactor: 1,
                    child: ColoredBox(color: fill),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('value', value, ifNull: 'indeterminate'));
  }
}

class _Sliding extends StatefulWidget {
  const _Sliding({required this.color});

  final Color color;

  @override
  State<_Sliding> createState() => _SlidingState();
}

class _SlidingState extends State<_Sliding>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  // From build: iOS's Reduce Motion changes arrive as a build, never as
  // didChangeDependencies (rawReduceMotionOf).
  void _sync() {
    if (!rawReduceMotionOf(context)) {
      if (!_run.isAnimating) _run.repeat();
    } else if (_run.isAnimating || _run.value != 0.5) {
      _run
        ..stop()
        ..value = 0.5;
    }
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    return LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: _run,
        builder: (context, _) {
          final block = box.maxWidth * 0.3;
          final x = -block + (box.maxWidth + block) * _run.value;
          return ClipRect(
            child: Stack(
              children: [
                PositionedDirectional(
                  start: x,
                  top: 0,
                  bottom: 0,
                  width: block,
                  child: ColoredBox(color: widget.color),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
