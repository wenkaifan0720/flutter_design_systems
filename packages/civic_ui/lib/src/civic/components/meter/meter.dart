import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/corners.dart';
import '../../internal/spring.dart';
import '../../theme.dart';

/// An amount against its limit, said in words first: its [label] over a
/// bar ("Visitor days used this year"), the bar filled to [value] between
/// [min] and [max] on the action's tint and its hairline, and under it the
/// amount in words
/// ([valueLabel]: "38 of 60 days used"). With [high] an ink mark stands
/// across the bar where the amount gets high, and past it the bar turns to
/// the error colour, with [highLabel] said under it in words ("You have
/// 6 days left"), so the colour is never alone. A new value springs to it.
///
/// It measures a quantity that is not under way (an allowance, a store);
/// for a task the reader is waiting on, [CivicProgressBar]. A screen
/// reader hears [label] and the amount in words.
///
/// Reads [CivicStyle]'s fill (the track), foreground (the bar), edge (the
/// high mark), textStyle (the label) and corners (or shape, the track's):
/// its `style:`, then
/// [CivicThemeData.meterStyle].
///
/// ```dart
/// CivicMeter(
///   label: 'Visitor days used this year',
///   value: 38,
///   max: 60,
///   high: 50,
///   valueLabel: '38 of 60 days used',
/// )
/// ```
class CivicMeter extends StatelessWidget {
  /// A meter.
  const CivicMeter({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    this.min = 0,
    this.high,
    this.valueLabel,
    this.highLabel,
    this.style,
  }) : assert(max > min);

  /// What it measures, over the bar.
  final String label;

  /// The amount.
  final double value;

  /// The least it can be.
  final double min;

  /// The most it can be.
  final double max;

  /// Where the amount gets high; null: no mark.
  final double? high;

  /// The amount in words, under the bar; null: "[value] of [max]" in the
  /// reader's numbers.
  final String? valueLabel;

  /// Said under the amount once it is past [high]; null: nothing more.
  final String? highLabel;

  /// Overrides for this meter's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = RawStyleOf([style, t.meterStyle], const {});
    final l = RawWidgetsLocalizations.of(context);
    final span = max - min;
    double share(double v) => ((v - min) / span).clamp(0.0, 1.0);
    final mark = high;
    final over = mark != null && value > mark;
    final amount =
        valueLabel ??
        (value == value.roundToDouble() && max == max.roundToDouble()
            ? l.positionLabel(value.round(), max.round())
            : '${l.formatDecimal(value)} / ${l.formatDecimal(max)}');
    final warning = over ? highLabel : null;
    return Semantics(
      container: true,
      label: label,
      value: warning == null ? amount : '$amount${l.listSeparator}$warning',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: text.label
                .copyWith(color: t.textPrimary)
                .merge(so.textStyle),
          ),
          const SizedBox(height: CivicSpacing.s8),
          CivicSpringValue(
            value: share(value),
            spring: CivicMotion.state,
            builder: (context, at, _) => CivicSpringValue(
              value: over ? 1 : 0,
              spring: CivicMotion.state,
              effects: true,
              builder: (context, warn, _) => SizedBox(
                height: 16,
                child: CustomPaint(
                  painter: _Gauge(
                    at: at.clamp(0.0, 1.0),
                    high: mark == null ? null : share(mark),
                    track: so.fill ?? t.secondaryFill,
                    bar: Color.lerp(so.foreground ?? t.action, t.danger, warn)!,
                    mark: so.edge ?? t.textPrimary,
                    rule: t.rule,
                    outline: civicShape(t, so, RawCorner.extraSmall),
                    rtl: Directionality.of(context) == TextDirection.rtl,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: CivicSpacing.s8),
          Text(amount, style: text.body.copyWith(color: t.textSecondary)),
          if (warning != null)
            Text(
              warning,
              style: text.body.copyWith(
                color: t.danger,
                fontWeight: text.label.fontWeight,
              ),
            ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(DoubleProperty('value', value))
      ..add(DoubleProperty('min', min, defaultValue: 0))
      ..add(DoubleProperty('max', max))
      ..add(DoubleProperty('high', high, defaultValue: null))
      ..add(StringProperty('valueLabel', valueLabel, defaultValue: null))
      ..add(StringProperty('highLabel', highLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _Gauge extends CustomPainter {
  _Gauge({
    required this.at,
    required this.high,
    required this.track,
    required this.bar,
    required this.mark,
    required this.rule,
    required this.outline,
    required this.rtl,
  });

  final double at;
  final double? high;
  final Color track;
  final Color bar;
  final Color mark;
  final Color rule;
  final OutlinedBorder outline;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    // The bar is 10 tall in the middle of 16; the high mark stands over it.
    const thick = 10.0;
    final top = (size.height - thick) / 2;
    final whole = Rect.fromLTWH(0, top, size.width, thick);
    double x(double share) =>
        rtl ? size.width * (1 - share) : size.width * share;
    final direction = rtl ? TextDirection.rtl : TextDirection.ltr;
    canvas
      ..save()
      ..clipPath(outline.getOuterPath(whole, textDirection: direction))
      ..drawRect(whole, Paint()..color = track)
      ..drawRect(
        Rect.fromLTRB(
          rtl ? x(at) : 0,
          top,
          rtl ? size.width : x(at),
          top + thick,
        ),
        Paint()..color = bar,
      )
      ..restore();
    outline
        .copyWith(side: BorderSide(color: rule))
        .paint(canvas, whole, textDirection: direction);
    final h = high;
    if (h != null) {
      final at = x(h).clamp(1.0, size.width - 1);
      canvas.drawRect(
        Rect.fromLTWH(at - 1, 0, 2, size.height),
        Paint()..color = mark,
      );
    }
  }

  @override
  bool shouldRepaint(_Gauge old) =>
      old.at != at ||
      old.high != high ||
      old.track != track ||
      old.bar != bar ||
      old.mark != mark ||
      old.rule != rule ||
      old.outline != outline ||
      old.rtl != rtl;
}
