/// Shares of a whole and a line's short history, in Ledger's hand: a ruled
/// ring of shares and a sparkline.
library;

import 'package:flutter/foundation.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../theme.dart';

/// One share of a [LedgerPieChart]: its [label] and its [value].
@immutable
class LedgerShare {
  /// A share worded [label] of [value].
  const LedgerShare(this.label, this.value) : assert(value >= 0);

  /// Its words.
  final String label;

  /// Its amount.
  final double value;
}

/// Shares of a whole (October's spending by category): a ring cut into its
/// shares, each in one of Ledger's inks (the ink, the green, the vermilion,
/// the second ink, the light rule), parted by a hair of the paper, the
/// whole in the serif in its middle; beside or under it a key, each share's
/// swatch, its words, its amount in the mono and its part of the whole.
/// Five shares at most; fold the rest into one ("Other"). A screen reader
/// hears the whole and each share with its part. The figures and parts are
/// in the reader's digits; the word under the whole is [totalLabel].
///
/// ```dart
/// LedgerPieChart(label: 'October by category', format: LedgerFormat.money, shares: const [LedgerShare('Rent', 1150), LedgerShare('Groceries', 486)])
/// ```
class LedgerPieChart extends StatelessWidget {
  /// A ring of [shares].
  const LedgerPieChart({
    required this.label,
    required this.shares,
    this.format,
    this.totalLabel,
    super.key,
  });

  /// What the whole is.
  final String label;

  /// The shares, largest first.
  final List<LedgerShare> shares;

  /// How an amount prints; null: the plain number in the reader's digits
  /// ("1,150"). Money is the caller's: `format: LedgerFormat.money`.
  final String Function(double value)? format;

  /// The word under the whole, in the small capitals; null: Total in
  /// English, and in another language none (the whole stands alone; pass
  /// the app's word, 'الإجمالي', 'Gesamt').
  final String? totalLabel;

  String _print(BuildContext context, double v) =>
      format?.call(v) ?? RawWidgetsLocalizations.of(context).formatDecimal(v);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<Object?>.has('format', format));
    properties
      ..add(StringProperty('label', label))
      ..add(IterableProperty<LedgerShare>('shares', shares))
      ..add(StringProperty('totalLabel', totalLabel, defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    assert(shares.isNotEmpty && shares.length <= 5);
    final t = context.ledgerTheme;
    final english =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'en';
    final word = totalLabel ?? (english ? 'Total' : null);
    final inks = [
      t.textPrimary,
      t.moneyIn,
      t.accent,
      t.textTertiary,
      t.borderStrong,
    ];
    final total = shares.fold<double>(0, (a, s) => a + s.value);
    String part(double v) =>
        RawWidgetsLocalizations.of(context)
            .formatPercent(total == 0 ? 0 : v / total);
    final ring = SizedBox.square(
      dimension: _across,
      child: CustomPaint(
        painter: _Ring(
          values: [for (final s in shares) s.value],
          inks: inks,
          paper: t.background,
          drawn: 1,
        ),
        // The whole inside the ring, set smaller at a large text size rather
        // than spill over it.
        child: Padding(
          padding: const EdgeInsets.all(_Ring._thick + LedgerSpacing.s8),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _print(context, total),
                    style: t.figureSmall.colored(t.textPrimary),
                  ),
                  if (word != null)
                    Text(
                      word.toUpperCase(),
                      style: t.meta.colored(t.textTertiary),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final key = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, s) in shares.indexed)
          Container(
            padding: const EdgeInsets.symmetric(vertical: LedgerSpacing.s8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.hairline)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: LedgerSpacing.s10,
              runSpacing: LedgerSpacing.s4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: LedgerSpacing.s10,
                  children: [
                    Container(
                      width: _swatch,
                      height: _swatch,
                      decoration: BoxDecoration(
                        color: inks[i],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        s.label,
                        style: t.rowTitle.colored(t.textPrimary),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: LedgerSpacing.s10,
                  children: [
                    Text(
                      _print(context, s.value),
                      style: t.amount.colored(t.textPrimary),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: _partWidth),
                      child: Text(
                        part(s.value),
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.end,
                        style: t.meta.colored(t.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
    return Semantics(
      container: true,
      label: [
        '$label, ${_print(context, total)}',
        for (final s in shares)
          '${s.label} ${_print(context, s.value)}, ${part(s.value)}',
      ].join('; '),
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) =>
            box.maxWidth >= MediaQuery.textScalerOf(context).scale(_beside)
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: LedgerSpacing.s24,
                children: [
                  ring,
                  Expanded(child: key),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: LedgerSpacing.s16,
                children: [
                  Center(child: ring),
                  key,
                ],
              ),
      ),
    );
  }

  static const double _across = 168;
  static const double _swatch = 10;
  static const double _partWidth = 40;
  static const double _beside = 480;
}

class _Ring extends CustomPainter {
  _Ring({
    required this.values,
    required this.inks,
    required this.paper,
    required this.drawn,
  });

  final List<double> values;
  final List<Color> inks;
  final Color paper;
  final double drawn;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, v) => a + v);
    if (total <= 0) return;
    final rect = (Offset.zero & size).deflate(_thick / 2);
    var start = -math.pi / 2;
    final reach = 2 * math.pi * drawn;
    var used = 0.0;
    for (final (i, v) in values.indexed) {
      final sweep = v / total * 2 * math.pi;
      final shown = math.min(sweep, math.max(0.0, reach - used));
      if (shown > 0) {
        canvas.drawArc(
          rect,
          start,
          shown,
          false,
          Paint()
            ..color = inks[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = _thick,
        );
      }
      start += sweep;
      used += sweep;
    }
    // A hair of the paper between shares.
    if (values.length > 1) {
      var at = -math.pi / 2;
      final c = size.center(Offset.zero);
      final outer = size.width / 2;
      final inner = outer - _thick;
      for (final v in values) {
        final p = Offset(math.cos(at), math.sin(at));
        canvas.drawLine(
          c + p * (inner - 1),
          c + p * (outer + 1),
          Paint()
            ..color = paper
            ..strokeWidth = 2,
        );
        at += v / total * 2 * math.pi;
      }
    }
  }

  static const double _thick = 18;

  @override
  bool shouldRepaint(_Ring old) =>
      old.drawn != drawn || old.paper != paper || old.values != values;
}

/// A figure's short history (a balance's last 30 days) as one fine line in
/// the ink, its last point a dot, set beside a figure or in a row; with
/// [baseline] a dotted rule where the figure started. It says its [label]
/// and its first and last values to a screen reader.
///
/// ```dart
/// LedgerSparkline(label: 'Balance, 30 days', values: const [4.2, 4.6, 4.1, 5.0, 6.2])
/// ```
class LedgerSparkline extends StatelessWidget {
  /// A line through [values].
  const LedgerSparkline({
    required this.label,
    required this.values,
    this.baseline = false,
    this.width = 96,
    this.height = 28,
    this.format,
    super.key,
  }) : assert(width > 0),
       assert(height > 0);

  /// What the line follows.
  final String label;

  /// The values, oldest first.
  final List<double> values;

  /// Whether a dotted rule marks the first value.
  final bool baseline;

  /// Its width.
  final double width;

  /// Its height.
  final double height;

  /// How a value prints to a screen reader; null: as a number.
  final String Function(double value)? format;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<Object?>.has('format', format));
    properties
      ..add(StringProperty('label', label))
      ..add(IterableProperty<double>('values', values))
      ..add(FlagProperty('baseline', value: baseline, ifTrue: 'baseline'))
      ..add(DoubleProperty('width', width))
      ..add(DoubleProperty('height', height));
  }

  @override
  Widget build(BuildContext context) {
    assert(values.length > 1);
    final t = context.ledgerTheme;
    String p(double v) => format?.call(v) ?? v.toStringAsFixed(2);
    final up = values.last >= values.first;
    return Semantics(
      label: label,
      value: 'from ${p(values.first)} to ${p(values.last)}',
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _Spark(
            values: values,
            ink: t.textPrimary,
            dot: up ? t.moneyIn : t.accent,
            rule: baseline ? t.textTertiary : null,
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}

class _Spark extends CustomPainter {
  // The last value's dot.
  static const double _endDot = 2.5;

  _Spark({
    required this.values,
    required this.ink,
    required this.dot,
    required this.rule,
    required this.rtl,
  });

  final List<double> values;
  final Color ink;
  final Color dot;
  final Color? rule;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final span = hi - lo == 0 ? 1 : hi - lo;
    // Room for the end dot's radius and half a point of its edge, so the
    // dot stays whole inside the box.
    const pad = _endDot + .5;
    Offset at(int i) {
      final f = i / (values.length - 1);
      final x = pad + (rtl ? 1 - f : f) * (size.width - 2 * pad);
      final y = pad + (1 - (values[i] - lo) / span) * (size.height - 2 * pad);
      return Offset(x, y);
    }

    if (rule case final r?) {
      final y = at(0).dy;
      final paint = Paint()..color = r;
      for (var x = 0.0; x < size.width; x += 4) {
        canvas.drawCircle(Offset(x, y), .7, paint);
      }
    }
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(at(values.length - 1), _endDot, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(_Spark old) =>
      old.values != values ||
      old.ink != ink ||
      old.dot != dot ||
      old.rule != rule ||
      old.rtl != rtl;
}
