import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../../internal/well.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../charts/charts.dart';

/// A progress bar's thickness, Fluent's `thickness`: [medium] 2 (the
/// default), [large] 4.
enum Fluent2ProgressThickness {
  /// 2 thick.
  medium(2),

  /// 4 thick.
  large(4);

  /// A thickness of [height].
  const Fluent2ProgressThickness(this.height);

  /// The bar's thickness.
  final double height;
}

/// A progress bar's ends, Fluent's `shape`: [rounded] at 4 (the default),
/// [square].
enum Fluent2ProgressShape {
  /// Rounded ends.
  rounded,

  /// Square ends.
  square,
}

/// What a progress measure's fill says, Fluent's `color`: [brand] (the
/// default), [success], [warning], [error].
enum Fluent2ProgressColor {
  /// The brand colour.
  brand,

  /// Fluent's success green.
  success,

  /// Fluent's warning amber.
  warning,

  /// Fluent's danger red.
  error,
}

/// The track a progress measure runs in: Fluent's `neutralBackground6`,
/// by day laid over its ground (`fluent2Rail`) so the tinted page never
/// swallows it.
Color fluent2ProgressTrack(Fluent2ThemeData t) => fluent2Rail(t);

/// The fill of [color]: Fluent's (`compoundBrandBackground`, the red,
/// dark orange and green `Background3`), or the tone's ink where Fluent's
/// reads under 3:1 on the track (its status fills on the dark track).
Color fluent2ProgressFill(Fluent2ThemeData t, Fluent2ProgressColor color) {
  final c = t.colors;
  final s = t.sharedColors;
  final (Color fluent, Color ink) = switch (color) {
    Fluent2ProgressColor.brand => (
      c.compoundBrandBackground,
      c.brandForeground1,
    ),
    Fluent2ProgressColor.success => (s.paletteGreenBackground3, t.success),
    Fluent2ProgressColor.warning => (s.paletteDarkOrangeBackground3, t.warning),
    Fluent2ProgressColor.error => (s.paletteRedBackground3, t.danger),
  };
  // The track as it stands on a card and on the page.
  final track = fluent2ProgressTrack(t);
  return [t.surface, t.background].every(
        (g) =>
            Fluent2ThemeData.contrast(fluent, Color.alphaBlend(track, g)) >= 3,
      )
      ? fluent
      : ink;
}

String _percent(double fraction) => '${(fraction * 100).round()}%';

/// Fluent 2's ProgressBar: how far a task has come, a fill of its [color]
/// running in Fluent's grey track, 2 or 4 thick; [value] of [max] (0..1 by
/// default) is determinate and eases to a new value over 300 ms; a null
/// [value] is indeterminate, a third of the track sliding across it every
/// 3 s (still at the middle under Reduce Motion). Fluent's
/// Field round it is optional: a [label] over it in body1 and a [hint]
/// under it in caption1 (what the value means: "6.2 GB of 10 GB").
/// Read as a progress bar named [label] with its percentage, or as busy.
///
/// ```dart
/// Fluent2ProgressBar(value: 0.62, label: 'Uploading Launch plan.docx', hint: '3 of 5 files')
/// ```
class Fluent2ProgressBar extends StatefulWidget {
  /// A progress bar at [value] of [max], or moving while [value] is null.
  const Fluent2ProgressBar({
    this.value,
    this.max = 1,
    this.thickness = Fluent2ProgressThickness.medium,
    this.shape = Fluent2ProgressShape.rounded,
    this.color = Fluent2ProgressColor.brand,
    this.label,
    this.hint,
    this.semanticLabel,
    super.key,
  });

  /// How far along, of [max]; null is indeterminate.
  final double? value;

  /// The value that fills the bar.
  final double max;

  /// Fluent's `thickness`.
  final Fluent2ProgressThickness thickness;

  /// Fluent's `shape`: rounded or square ends.
  final Fluent2ProgressShape shape;

  /// Fluent's `color`: the fill's colour.
  final Fluent2ProgressColor color;

  /// The field's label over the bar.
  final String? label;

  /// The field's hint under the bar.
  final String? hint;

  /// What a screen reader calls it; null says [label] (else "Progress").
  final String? semanticLabel;

  @override
  State<Fluent2ProgressBar> createState() => _Fluent2ProgressBarState();
}

class _Fluent2ProgressBarState extends State<Fluent2ProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Fluent2ProgressBar old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final spin = widget.value == null && Fluent2Motion.on(context);
    if (spin && !_slide.isAnimating) {
      _slide.repeat();
    } else if (!spin && _slide.isAnimating) {
      _slide.stop();
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final w = widget;
    final track = fluent2ProgressTrack(t);
    final fill = fluent2ProgressFill(t, w.color);
    final radius = w.shape == Fluent2ProgressShape.rounded
        ? Fluent2Radius.medium
        : Fluent2Radius.none;
    final v = w.value;
    final fraction = v == null || w.max <= 0
        ? null
        : (v / w.max).clamp(0.0, 1.0).toDouble();
    Widget bar(double? shown) => CustomPaint(
      painter: _BarPainter(
        fraction: shown,
        slide: _slide,
        moving: Fluent2Motion.on(context),
        track: track,
        fill: fill,
        radius: radius,
        rtl: Directionality.of(context) == TextDirection.rtl,
      ),
      child: SizedBox(height: w.thickness.height, width: double.infinity),
    );
    final Widget drawn = fraction == null
        ? bar(null)
        : TweenAnimationBuilder<double>(
            tween: Tween(end: fraction),
            duration: Fluent2Motion.on(context) && fraction > 0.01
                ? Fluent2Motion.slow
                : Duration.zero,
            curve: Curves.ease,
            builder: (context, shown, _) => bar(shown),
          );
    final name =
        w.semanticLabel ?? w.label ?? Fluent2Localizations.of(context).progress;
    final measured = Semantics(
      label: name,
      role: fraction == null
          ? SemanticsRole.loadingSpinner
          : SemanticsRole.progressBar,
      value: fraction == null ? null : _percent(fraction),
      minValue: fraction == null ? null : '0',
      maxValue: fraction == null ? null : '100',
      hint: w.hint,
      excludeSemantics: true,
      child: drawn,
    );
    if (w.label == null && w.hint == null) return measured;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (w.label != null)
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(
                top: Fluent2Spacing.xxs,
                bottom: Fluent2Spacing.xxs * 2,
              ),
              child: Text(w.label!, style: t.body1.c(t.textPrimary)),
            ),
          ),
        measured,
        if (w.hint != null)
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(top: Fluent2Spacing.xxs),
              child: Text(w.hint!, style: t.caption1.c(t.textTertiary)),
            ),
          ),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.fraction,
    required this.slide,
    required this.moving,
    required this.track,
    required this.fill,
    required this.radius,
    required this.rtl,
  }) : super(repaint: fraction == null ? slide : null);

  final double? fraction;
  final Animation<double> slide;
  final bool moving;
  final Color track;
  final Color fill;
  final double radius;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final whole = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.save();
    canvas.clipRRect(whole);
    canvas.drawRect(Offset.zero & size, Paint()..color = track);
    final f = fraction;
    if (f != null) {
      if (f > 0) {
        final w = size.width * f;
        final rect = rtl
            ? Rect.fromLTWH(size.width - w, 0, w, size.height)
            : Rect.fromLTWH(0, 0, w, size.height);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(radius)),
          Paint()..color = fill,
        );
      }
    } else {
      // A third of the track, its ends fading into it, sliding from one
      // bar's width before the start to past the end. The fill fades out
      // over the track already drawn (the track is see-through by day, so
      // it is never laid twice).
      final w = size.width / 3;
      final phase = moving ? slide.value : 0.5;
      final run = -w + phase * (size.width + w);
      final x = rtl ? size.width - w - run : run;
      final rect = Rect.fromLTWH(x, 0, w, size.height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              fill.withValues(alpha: 0),
              fill,
              fill.withValues(alpha: 0),
            ],
            stops: const [0, 0.5, 1],
          ).createShader(rect),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.fraction != fraction ||
      old.track != track ||
      old.fill != fill ||
      old.radius != radius ||
      old.rtl != rtl ||
      old.moving != moving;
}

/// One part of a [Fluent2SegmentBar]: what it is ([label]), how much
/// ([value], in the bar's unit), the words its amount is said in
/// ([valueText], "3.1 GB"; null prints the number) and its [hue] (null
/// takes the next of [Fluent2ChartHue.categorical]).
///
/// ```dart
/// Fluent2SegmentBarPart('Documents', 3.2, valueText: '3.2 GB')
/// ```
@immutable
class Fluent2SegmentBarPart {
  /// A part called [label] worth [value].
  const Fluent2SegmentBarPart(
    this.label,
    this.value, {
    this.valueText,
    this.hue,
  });

  /// The part's name, in the legend.
  final String label;

  /// How much of the whole the part is.
  final double value;

  /// The value's words in the legend; null prints [value].
  final String? valueText;

  /// The part's colour; null takes the next chart hue.
  final Fluent2ChartHue? hue;
}

/// One whole split into its parts (what fills the team's storage, where a
/// sprint's hours went): [segments] side by side in the chart hues, each
/// as wide as its share of [total] (the parts' sum when null; what is left
/// of a larger total stays the progress track), parted by 2 of the ground,
/// the ends round, [thickness] 8 by default; with [legend], a wrapping key
/// under it, each part's swatch, name and amount in caption1. Derived:
/// Fluent has no segmented bar; this is its ProgressBar's track holding
/// the chart palette. Read as one image: [label], then every part and its
/// amount.
///
/// ```dart
/// Fluent2SegmentBar(label: 'Storage', total: 10, segments: const [Fluent2SegmentBarPart('Documents', 3.1, valueText: '3.1 GB'), Fluent2SegmentBarPart('Photos', 2, valueText: '2 GB')])
/// ```
class Fluent2SegmentBar extends StatelessWidget {
  /// A bar of [segments], one whole in parts.
  const Fluent2SegmentBar({
    required this.segments,
    this.total,
    this.thickness = 8,
    this.legend = true,
    this.label,
    super.key,
  });

  /// The parts, in order.
  final List<Fluent2SegmentBarPart> segments;

  /// The whole; null is the parts' sum.
  final double? total;

  /// The bar's thickness.
  final double thickness;

  /// Draw the key under the bar.
  final bool legend;

  /// What the bar measures ("Storage, 6.2 GB of 10 GB").
  final String? label;

  /// The hue of the part at [index].
  Fluent2ChartHue hueAt(int index) =>
      segments[index].hue ??
      Fluent2ChartHue.categorical[index % Fluent2ChartHue.categorical.length];

  static String _amount(Fluent2SegmentBarPart s) {
    final v = s.value;
    return s.valueText ??
        (v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final sum = segments.fold<double>(0, (a, s) => a + math.max(0, s.value));
    final whole = math.max(total ?? sum, sum);
    final colors = [for (var i = 0; i < segments.length; i++) hueAt(i).of(t)];
    final spoken = [
      ?label,
      for (final s in segments) '${s.label} ${_amount(s)}',
    ].join(', ');
    final bar = SizedBox(
      height: thickness,
      width: double.infinity,
      child: CustomPaint(
        painter: _SegmentPainter(
          shares: [
            for (final s in segments)
              whole <= 0 ? 0.0 : math.max(0.0, s.value) / whole,
          ],
          colors: colors,
          track: fluent2ProgressTrack(t),
          rtl: Directionality.of(context) == TextDirection.rtl,
        ),
      ),
    );
    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: !legend
          ? bar
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                bar,
                const SizedBox(height: Fluent2Spacing.s),
                Wrap(
                  spacing: Fluent2Spacing.l,
                  runSpacing: Fluent2Spacing.xs,
                  children: [
                    for (final (i, s) in segments.indexed)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: Fluent2Spacing.sNudge,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors[i],
                              shape: BoxShape.circle,
                            ),
                          ),
                          Flexible(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${s.label} ',
                                    style: t.caption1.c(t.textSecondary),
                                  ),
                                  TextSpan(
                                    text: _amount(s),
                                    style: t.caption1Strong.tabular.c(
                                      t.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SegmentPainter extends CustomPainter {
  _SegmentPainter({
    required this.shares,
    required this.colors,
    required this.track,
    required this.rtl,
  });

  final List<double> shares;
  final List<Color> colors;
  final Color track;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final r = Radius.circular(h / 2);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, r));
    var x = 0.0;
    const gap = 2.0;
    final drawn = <(double, double, Color)>[];
    for (var i = 0; i < shares.length; i++) {
      final w = shares[i] * size.width;
      if (w <= 0) continue;
      drawn.add((x, w, colors[i]));
      x += w;
    }
    final used = x;
    if (used < size.width - 0.5) {
      final start = used == 0 ? 0.0 : used + gap;
      final rest = Rect.fromLTRB(start, 0, size.width, h);
      canvas.drawRect(_flip(rest, size), Paint()..color = track);
    }
    for (final (i, (left, w, color)) in drawn.indexed) {
      final last = i == drawn.length - 1 && used >= size.width - 0.5;
      final right = left + w - (last ? 0 : gap);
      if (right <= left) continue;
      canvas.drawRect(
        _flip(Rect.fromLTRB(left, 0, right, h), size),
        Paint()..color = color,
      );
    }
    canvas.restore();
  }

  Rect _flip(Rect r, Size size) => rtl
      ? Rect.fromLTRB(
          size.width - r.right,
          r.top,
          size.width - r.left,
          r.bottom,
        )
      : r;

  @override
  bool shouldRepaint(_SegmentPainter old) =>
      old.track != track ||
      old.rtl != rtl ||
      !_same(old.shares, shares) ||
      !_same(old.colors, colors);

  static bool _same<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
