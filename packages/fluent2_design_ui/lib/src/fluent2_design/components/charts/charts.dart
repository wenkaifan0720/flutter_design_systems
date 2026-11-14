import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../internal/presets.g.dart' show sharedDark, sharedLight;
import '../../internal/well.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// The colours Fluent 2's charts draw data in: the [brand] (Fluent's
/// `compoundBrandBackground`, a single series' default), five of Fluent's
/// shared palette hues for parts and categories ([cornflower], [pumpkin],
/// [magenta], [forest], [lavender], in that fixed order:
/// [categorical]), and [neutral] for "Other" (`neutralStrokeAccessible`).
///
/// Light wears each hue's own Fluent primary (`palette<Hue>BorderActive`);
/// dark the midpoint of its light and dark primaries (a step nearer the
/// dark one where the midpoint misses 3:1 on a card), since the dark
/// tokens are pastel steps (OKLCH L above 0.7) a fill reads washed out
/// in. Both sets hold 3:1 on the surfaces and the colour-blind separation
/// between neighbours (checked with the dataviz validator).
enum Fluent2ChartHue {
  /// The brand colour, for a single series.
  brand,

  /// Fluent's cornflower, the first categorical hue.
  cornflower,

  /// Fluent's pumpkin, the second.
  pumpkin,

  /// Fluent's magenta, the third.
  magenta,

  /// Fluent's forest, the fourth.
  forest,

  /// Fluent's lavender, the fifth.
  lavender,

  /// The neutral grey, for "Other".
  neutral;

  /// The parts' hues in their fixed order: a part keeps its hue whatever
  /// else is shown.
  static const List<Fluent2ChartHue> categorical = [
    cornflower,
    pumpkin,
    magenta,
    forest,
    lavender,
  ];

  /// This hue in [t]'s appearance.
  Color of(Fluent2ThemeData t) {
    // Dark: from the midpoint toward the dark primary, the first step
    // that holds 3:1 on the surface and on a card (magenta's midpoint
    // reads 2.6 on the card, so it takes a lighter step).
    Color pair(Color light, Color dark) {
      if (!t.isDark) return light;
      for (var at = 0.5; at < 1; at += 0.05) {
        final mixed = Color.lerp(light, dark, at)!;
        if (Fluent2ThemeData.contrast(mixed, t.surface) >= 3 &&
            Fluent2ThemeData.contrast(mixed, t.colors.neutralCardBackground) >=
                3) {
          return mixed;
        }
      }
      return dark;
    }

    final l = sharedLight;
    final d = sharedDark;
    return switch (this) {
      brand => t.colors.compoundBrandBackground,
      cornflower => pair(
        l.paletteCornflowerBorderActive,
        d.paletteCornflowerBorderActive,
      ),
      pumpkin => pair(
        l.palettePumpkinBorderActive,
        d.palettePumpkinBorderActive,
      ),
      magenta => pair(
        l.paletteMagentaBorderActive,
        d.paletteMagentaBorderActive,
      ),
      forest => pair(l.paletteForestBorderActive, d.paletteForestBorderActive),
      lavender => pair(
        l.paletteLavenderBorderActive,
        d.paletteLavenderBorderActive,
      ),
      neutral => t.colors.neutralStrokeAccessible,
    };
  }
}

/// An axis-less inline trend: [values] as one 2 line in its [hue] (the
/// brand by default) across the width, its last point marked with an 8
/// dot in a 2 ring of the ground ([ground], the surface by default), an
/// [area] wash of the hue at 10% under it. Derived: Fluent's charting has
/// a Sparkline; this one is drawn from the tokens to common chart
/// mark specs. Read as [label] with where it starts and ends.
///
/// ```dart
/// Fluent2Sparkline(values: const [3, 5, 4, 7, 6, 9], label: 'Files shared this week', area: true)
/// ```
class Fluent2Sparkline extends StatelessWidget {
  /// A sparkline of [values].
  const Fluent2Sparkline({
    required this.values,
    this.hue = Fluent2ChartHue.brand,
    this.area = false,
    this.height = 32,
    this.width,
    this.ground,
    this.label,
    super.key,
  });

  /// The values, oldest first.
  final List<double> values;

  /// The line's colour.
  final Fluent2ChartHue hue;

  /// Wash the area under the line.
  final bool area;

  /// The sparkline's height.
  final double height;

  /// Its width; null takes the parent's.
  final double? width;

  /// The colour it stands on (the ring round the last point); null is the
  /// surface.
  final Color? ground;

  /// What it shows ("Files shared this week").
  final String? label;

  static String _num(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final name = label ?? Fluent2Localizations.of(context).trend;
    final spoken = values.isEmpty
        ? name
        : '$name, from ${_num(values.first)} to '
              '${_num(values.last)}';
    return Semantics(
      label: spoken,
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
        // Right to left the run starts at the right, as the charts' do; a
        // sparkline has no words, so the picture itself mirrors.
        child: Transform.flip(
          flipX: Directionality.of(context) == TextDirection.rtl,
          child: CustomPaint(
            painter: _SparkPainter(
              values: values,
              color: hue.of(t),
              ground: ground ?? t.surface,
              area: area,
            ),
          ),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.values,
    required this.color,
    required this.ground,
    required this.area,
  });

  final List<double> values;
  final Color color;
  final Color ground;
  final bool area;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const dot = 4.0;
    const ring = 2.0;
    const inset = dot + ring;
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final span = hi - lo == 0 ? 1.0 : hi - lo;
    final w = size.width - inset;
    final h = size.height - inset * 2;
    Offset at(int i) => Offset(
      values.length == 1 ? w : w * i / (values.length - 1),
      inset + h - h * (values[i] - lo) / span,
    );
    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }
    if (area && values.length > 1) {
      final wash = Path.from(line)
        ..lineTo(at(values.length - 1).dx, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(wash, Paint()..color = color.withValues(alpha: 0.1));
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    final end = at(values.length - 1);
    canvas.drawCircle(end, dot + ring, Paint()..color = ground);
    canvas.drawCircle(end, dot, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.color != color ||
      old.ground != ground ||
      old.area != area ||
      !_sameValues(old.values, values);
}

bool _sameValues(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// One bar of a [Fluent2BarChart]: its axis [label] ("Mon"), its [value]
/// and the words that value is printed and said in ([valueText], "3 h";
/// null prints the number).
///
/// ```dart
/// Fluent2Bar('Mon', 3, valueText: '3 h')
/// ```
@immutable
class Fluent2Bar {
  /// A bar called [label] worth [value].
  const Fluent2Bar(this.label, this.value, {this.valueText});

  /// The bar's name, beside or under it.
  final String label;

  /// The bar's value.
  final double value;

  /// The value's words; null prints [value].
  final String? valueText;
}

/// Vertical bars across categories or days: [bars] grown from one hairline
/// baseline in their [hue] (the brand by default), at most 24 wide with a
/// 4 rounded top; the [highlight]ed one in the full hue and the rest at a
/// lighter wash of it, each value printed over its cap in caption1 (the
/// highlighted one in the first ink, strong) and each label under the
/// baseline in caption1. With [onHighlight] each bar is a button that
/// picks it. Derived: Fluent's charting has a VerticalBarChart; this one
/// is drawn from the tokens to common chart mark specs. Read as [label],
/// then every bar and its value.
///
/// ```dart
/// Fluent2BarChart(label: 'Meeting hours this week', highlight: 2, bars: const [Fluent2Bar('Mon', 3), Fluent2Bar('Tue', 5), Fluent2Bar('Wed', 6)])
/// ```
class Fluent2BarChart extends StatelessWidget {
  /// A bar chart of [bars].
  const Fluent2BarChart({
    required this.bars,
    this.highlight,
    this.onHighlight,
    this.hue = Fluent2ChartHue.brand,
    this.height = 160,
    this.label,
    super.key,
  });

  /// The bars, in order.
  final List<Fluent2Bar> bars;

  /// The bar drawn in the full hue; null draws them all full.
  final int? highlight;

  /// Told the bar pressed; null leaves the bars still.
  final ValueChanged<int>? onHighlight;

  /// The bars' colour.
  final Fluent2ChartHue hue;

  /// The whole chart's height, labels included.
  final double height;

  /// What it shows ("Meeting hours this week").
  final String? label;

  static String _text(Fluent2Bar b) =>
      b.valueText ??
      (b.value == b.value.roundToDouble()
          ? '${b.value.round()}'
          : b.value.toStringAsFixed(1));

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final color = hue.of(t);
    final rest = highlight == null ? color : color.withValues(alpha: 0.4);
    final top = bars.fold<double>(0, (a, b) => math.max(a, b.value));
    final scaler = MediaQuery.textScalerOf(context);
    final line = scaler.scale(t.caption1.fontSize!) * t.caption1.height!;
    final pick = onHighlight;
    final spoken = [
      ?label,
      for (final b in bars) '${b.label} ${_text(b)}',
    ].join(', ');
    Widget column(int i) {
      final b = bars[i];
      final lit = highlight == i;
      return LayoutBuilder(
        builder: (context, box) {
          final room = math.max(0.0, box.maxHeight - line * 2 - 12);
          final h = top <= 0 ? 0.0 : room * math.max(0, b.value) / top;
          final width = math.min(24.0, box.maxWidth * 0.6);
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                _text(b),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: lit
                    ? t.caption1Strong.tabular.c(t.textPrimary)
                    : t.caption1.tabular.c(t.textSecondary),
              ),
              const SizedBox(height: Fluent2Spacing.xs),
              Container(
                width: width,
                height: h,
                decoration: BoxDecoration(
                  color: highlight == null || lit ? color : rest,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(Fluent2Radius.medium),
                  ),
                ),
              ),
              SizedBox(
                height: 1,
                width: double.infinity,
                child: ColoredBox(
                  color: fluent2Step(t, t.colors.neutralStroke2),
                ),
              ),
              const SizedBox(height: Fluent2Spacing.sNudge),
              Text(
                b.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: lit
                    ? t.caption1Strong.c(t.textPrimary)
                    : t.caption1.c(t.textTertiary),
              ),
            ],
          );
        },
      );
    }

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < bars.length; i++)
          Expanded(
            child: pick == null
                ? column(i)
                : Fluent2Pressable(
                    onPressed: () => pick(i),
                    label: bars[i].label,
                    value: _text(bars[i]),
                    selected: highlight == i,
                    radius: Fluent2Radius.medium,
                    child: column(i),
                  ),
          ),
      ],
    );
    return SizedBox(
      height: height,
      child: pick == null
          ? Semantics(label: spoken, excludeSemantics: true, child: row)
          : Semantics(
              container: true,
              explicitChildNodes: true,
              label: label,
              child: row,
            ),
    );
  }
}
