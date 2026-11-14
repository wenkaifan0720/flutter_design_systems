import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../format.dart';
import '../../internal/engraving.dart';
import '../../internal/whole_pixel.dart';
import '../../theme.dart';

/// How a [LedgerGauge] is inked: the [ink] (money spent) or the [green]
/// (money saved toward a goal).
enum LedgerGaugeTone {
  /// The ink: money spent.
  ink,

  /// The green: money saved toward a goal.
  green,
}

/// The hatched gauge (`art.gauge`), drawn on its 300 by 16 grid scaled to
/// its width: a faint frame to the budget, the part spent hatched and
/// edged in its ink to its mark, past the budget vermilion on its wash;
/// the budget's [tick] across it; the month's [pace] as a green line on
/// the paper. [budgetAt] places the budget along it (a category's stands
/// at 250 of 300, room left for going over). Its [paceLabel] stands over
/// the pace's line, its [startLabel] and [endLabel] under its ends, its
/// [budgetLabel] under the budget. Spending past its end stops at its
/// end, clipped to its box as the source's svg is. In right to left it runs
/// from the right, its labels mirrored with it. Read as its label and the
/// share spent.
///
/// ```dart
/// LedgerGauge(ratio: 2486.12 / 2700, pace: 28 / 31, tick: false, paceLabel: 'Pace · day 28', startLabel: '\$0', endLabel: '\$2,700')
/// ```
class LedgerGauge extends StatelessWidget {
  /// A gauge filled to [ratio], read as [semanticLabel].
  const LedgerGauge({
    required this.ratio,
    this.pace,
    this.budgetAt = 1,
    this.tick = true,
    this.tone = LedgerGaugeTone.ink,
    this.paceLabel,
    this.startLabel,
    this.endLabel,
    this.budgetLabel,
    this.semanticLabel = 'Spent',
    super.key,
  });

  /// Spent over budget (or saved over target): 1 is the budget.
  final double ratio;

  /// The share of the month gone, its line on the gauge.
  final double? pace;

  /// Where the budget stands along the gauge, a share of its width.
  final double budgetAt;

  /// Whether the budget's tick stands across the gauge.
  final bool tick;

  /// How the part spent or saved is inked.
  final LedgerGaugeTone tone;

  /// Words over the pace's line (Today).
  final String? paceLabel;

  /// Words under the gauge's start.
  final String? startLabel;

  /// Words under the gauge's end.
  final String? endLabel;

  /// Words under the budget's tick.
  final String? budgetLabel;

  /// What a screen reader says the gauge is, before the share.
  final String semanticLabel;

  static const double _w = 300;
  static const double _h = 16;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final line = t.meta.sized(11).line(16).tracked(0);
    final percent = LedgerFormat.percent(ratio * 100, 100);
    // It runs from the reading start, as the words around it do: mirrored
    // in right to left, its labels with it.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      label: semanticLabel,
      value: '$percent%',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final at = budgetAt * w;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (paceLabel != null && pace != null) ...[
                _LabelRow(
                  mirrored: rtl,
                  marks: [
                    // `.gauge-pace span`: ending 6 short of the pace line.
                    (
                      x: pace! * at,
                      shift: -1.0,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 6),
                        child: Text(
                          paceLabel!,
                          style: line.medium.colored(t.pace),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
              ],
              LedgerWholeAspect(
                aspectRatio: _w / _h,
                child: Transform.flip(
                  flipX: rtl,
                  child: CustomPaint(painter: _GaugePainter(this, t)),
                ),
              ),
              if (startLabel != null ||
                  endLabel != null ||
                  budgetLabel != null) ...[
                const SizedBox(height: 6),
                _LabelRow(
                  mirrored: rtl,
                  marks: [
                    if (startLabel case final s?)
                      (
                        x: 0.0,
                        shift: 0.0,
                        child: Text(s, style: line.colored(t.textTertiary)),
                      ),
                    if (budgetLabel case final b?)
                      (
                        x: at,
                        shift: -.5,
                        child: Text(b, style: line.colored(t.textPrimary)),
                      ),
                    if (endLabel case final e?)
                      (
                        x: w,
                        shift: -1.0,
                        child: Text(e, style: line.colored(t.textTertiary)),
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

typedef _Mark = ({double x, double shift, Widget child});

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.marks, required this.mirrored});

  final List<_Mark> marks;

  /// Whether each mark stands as far from the right as [_Mark.x] says from
  /// the left (right to left).
  final bool mirrored;

  // The label's 16 line, grown with the reader's text size.
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.textScalerOf(context).scale(16),
    child: CustomMultiChildLayout(
      delegate: _RowLayout(marks, mirrored: mirrored),
      children: [
        for (var i = 0; i < marks.length; i++)
          LayoutId(id: i, child: marks[i].child),
      ],
    ),
  );
}

class _RowLayout extends MultiChildLayoutDelegate {
  _RowLayout(this.marks, {required this.mirrored});

  final List<_Mark> marks;
  final bool mirrored;

  @override
  void performLayout(Size size) {
    for (var i = 0; i < marks.length; i++) {
      final s = layoutChild(i, const BoxConstraints());
      final x = marks[i].x + marks[i].shift * s.width;
      positionChild(i, Offset(mirrored ? size.width - x - s.width : x, 0));
    }
  }

  @override
  bool shouldRelayout(_RowLayout old) => true;
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.g, this.t);

  final LedgerGauge g;
  final LedgerThemeData t;

  @override
  void paint(Canvas canvas, Size size) {
    // The svg's viewport clips what runs past its box (art.gauge): spending
    // past the gauge's end stops at its end.
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..scale(size.width / LedgerGauge._w);
    const b0 = 4.0, b1 = 12.0, h = LedgerGauge._h;
    final at = g.budgetAt * LedgerGauge._w;
    final xs = at * g.ratio;
    final page = t.textPrimary;
    final ink = g.tone == LedgerGaugeTone.green ? t.pace : page;
    final red = t.over;
    canvas.drawRect(
      Rect.fromLTWH(.35, b0, at - .7, b1 - b0),
      ledgerStroke(ledgerInk(page, .22), .7),
    );
    final xin = math.min(xs, at);
    canvas
      ..drawPath(
        ledgerHatchRect(0, b0, xin, b1, 3.3),
        ledgerStroke(ledgerInk(ink, .8), .75),
      )
      ..drawLine(const Offset(0, b0), Offset(xin, b0), ledgerStroke(ink, .9))
      ..drawLine(const Offset(0, b1), Offset(xin, b1), ledgerStroke(ink, .9))
      ..drawLine(
        const Offset(.45, b0),
        const Offset(.45, b1),
        ledgerStroke(ink, .9),
      );
    if (xs > at) {
      final over = Rect.fromLTRB(at, b0, xs, b1);
      canvas
        ..drawRect(over, Paint()..color = ledgerInk(red, .12))
        ..drawRect(over, ledgerStroke(red, .9))
        ..drawPath(
          ledgerHatchRect(at, b0, xs, b1, 3.3 * .8),
          ledgerStroke(red, .85),
        );
    } else if (g.pace == null || (at * g.pace! - xs).abs() >= _clear) {
      // The spent part's edge, unless the pace's line stands on it: one
      // mark to a place, never a stub beside the green.
      canvas.drawLine(
        Offset(xs - .6, b0),
        Offset(xs - .6, b1),
        ledgerStroke(ink, 1.2),
      );
    }
    if (g.tick) {
      canvas.drawLine(
        Offset(at - .5, 1),
        Offset(at - .5, h - 1),
        ledgerStroke(page, 1),
      );
    }
    if (g.pace case final pace?) {
      final px = at * pace;
      canvas
        ..drawLine(Offset(px, 0), Offset(px, h), ledgerStroke(t.background, 3))
        ..drawLine(Offset(px, 0), Offset(px, h), ledgerStroke(t.pace, 1.3));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GaugePainter old) => true;

  // How near (on the 300 grid) the pace's line stands for the spent edge.
  static const double _clear = 4;
}

/// How a part of a [LedgerStackBar] is hatched: close in the [ink], wider
/// in the [green], wide and faint ([pale]).
enum LedgerStackTone {
  /// Hatched close in the ink.
  ink,

  /// Hatched wider in the green.
  green,

  /// Hatched wide and faint.
  pale,
}

/// One part of a [LedgerStackBar]: its value and its hatch.
///
/// ```dart
/// LedgerStackPart(39432.60, LedgerStackTone.ink)
/// ```
class LedgerStackPart {
  /// A part worth [value], hatched in [tone].
  const LedgerStackPart(this.value, this.tone);

  /// What the part holds; the parts share the bar by it.
  final double value;

  /// How the part is hatched.
  final LedgerStackTone tone;
}

/// A ruled bar cut into its [parts] 3 apart (`art.stack_bar`), each
/// hatched in its own way (the allocation): drawn on its 600 by 22 grid
/// stretched across its width, 22 tall. Read as its label.
///
/// ```dart
/// LedgerStackBar(parts: const [LedgerStackPart(80.6, LedgerStackTone.ink), LedgerStackPart(15, LedgerStackTone.green), LedgerStackPart(4.4, LedgerStackTone.pale)])
/// ```
class LedgerStackBar extends StatelessWidget {
  /// A bar cut into [parts].
  const LedgerStackBar({
    required this.parts,
    this.semanticLabel = 'Allocation',
    super.key,
  });

  /// The parts, in order.
  final List<LedgerStackPart> parts;

  /// What a screen reader says the bar is.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    excludeSemantics: true,
    child: SizedBox(
      height: 22,
      width: double.infinity,
      // Wordless: it runs from the reading start, mirrored in right to left.
      child: Transform.flip(
        flipX: Directionality.of(context) == TextDirection.rtl,
        child: CustomPaint(painter: _StackPainter(parts, context.ledgerTheme)),
      ),
    ),
  );
}

class _StackPainter extends CustomPainter {
  _StackPainter(this.parts, this.t);

  final List<LedgerStackPart> parts;
  final LedgerThemeData t;

  @override
  void paint(Canvas canvas, Size size) {
    const w = 600.0, h = 22.0, gap = 3.0;
    // preserveAspectRatio="none": stretched across, strokes and all.
    canvas
      ..save()
      ..scale(size.width / w, size.height / h);
    final total = parts.fold<double>(0, (a, p) => a + p.value);
    final usable = w - gap * (parts.length - 1);
    var x = 0.0;
    for (final p in parts) {
      final pw = usable * p.value / total;
      final color = p.tone == LedgerStackTone.green ? t.pace : t.textPrimary;
      if (p.tone == LedgerStackTone.pale) {
        canvas.drawPath(
          ledgerHatchRect(x, 0, x + pw, h, 4.4),
          ledgerStroke(ledgerInk(t.textPrimary, .35), .6),
        );
      } else {
        canvas.drawPath(
          ledgerHatchRect(
            x,
            0,
            x + pw,
            h,
            p.tone == LedgerStackTone.ink ? 2.6 : 3.4,
          ),
          ledgerStroke(ledgerInk(color, .85), .7),
        );
      }
      canvas.drawRect(
        Rect.fromLTWH(x + .4, .4, math.max(pw - .8, .5), h - .8),
        ledgerStroke(color, .8),
      );
      x += pw + gap;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StackPainter old) => true;
}

/// A budget on a dollar rule (`art.budget_rule`), on its 432 by 30 grid
/// scaled to its width: the month's [spent] hatched to the [budget]'s ink
/// tick (vermilion past it), the [suggested] budget as a dashed green
/// tick on the paper. Read as its label and the three sums.
///
/// ```dart
/// LedgerBudgetRule(spent: 286.40, budget: 250, suggested: 275)
/// ```
class LedgerBudgetRule extends StatelessWidget {
  /// A rule of [spent] against [budget] and the [suggested] budget.
  const LedgerBudgetRule({
    required this.spent,
    required this.budget,
    required this.suggested,
    this.semanticLabel = 'Budget',
    super.key,
  });

  /// What the month spent.
  final double spent;

  /// The month's budget.
  final double budget;

  /// The budget suggested, drawn dashed.
  final double suggested;

  /// What a screen reader says the rule is, before the sums.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    value:
        '${LedgerFormat.money(spent)} spent, budget ${LedgerFormat.money(budget, showCents: false)}, suggested ${LedgerFormat.money(suggested, showCents: false)}',
    excludeSemantics: true,
    child: LedgerWholeAspect(
      aspectRatio: 432 / 30,
      // Wordless: it runs from the reading start, mirrored in right to left.
      child: Transform.flip(
        flipX: Directionality.of(context) == TextDirection.rtl,
        child: CustomPaint(painter: _RulePainter(this, context.ledgerTheme)),
      ),
    ),
  );
}

class _RulePainter extends CustomPainter {
  _RulePainter(this.r, this.t);

  final LedgerBudgetRule r;
  final LedgerThemeData t;

  @override
  void paint(Canvas canvas, Size size) {
    const w = 432.0, h = 30.0, b0 = 9.0, b1 = 21.0, spacing = 3.0;
    canvas
      ..save()
      ..scale(size.width / w);
    final scale = [r.spent, r.budget, r.suggested].reduce(math.max) * 1.14;
    double x(double v) => v / scale * w;
    final xs = x(r.spent), xb = x(r.budget), xg = x(r.suggested);
    final ink = t.textPrimary, red = t.over;
    canvas.drawLine(
      const Offset(0, b1 + 4),
      const Offset(w, b1 + 4),
      ledgerStroke(ledgerInk(ink, .3), .8),
    );
    final xin = math.min(xs, xb);
    canvas
      ..drawPath(
        ledgerHatchRect(0, b0, xin, b1, spacing),
        ledgerStroke(ledgerInk(ink, .8), .75),
      )
      ..drawRect(
        Rect.fromLTWH(.4, b0, xin - .8, b1 - b0),
        ledgerStroke(ink, .9),
      );
    if (xs > xb) {
      final over = Rect.fromLTRB(xb, b0, xs, b1);
      canvas
        ..drawRect(over, Paint()..color = ledgerInk(red, .12))
        ..drawRect(over, ledgerStroke(red, .9))
        ..drawPath(
          ledgerHatchRect(xb, b0, xs, b1, spacing * .8),
          ledgerStroke(red, .85),
        );
    }
    canvas
      ..drawLine(Offset(xb, 2), Offset(xb, h - 1), ledgerStroke(ink, 1.3))
      ..drawLine(Offset(xg, 2), Offset(xg, h - 1), ledgerStroke(t.surface, 3))
      ..drawPath(
        ledgerDashed(
          Path()
            ..moveTo(xg, 2)
            ..lineTo(xg, h - 1),
          const [3, 2],
        ),
        ledgerStroke(t.pace, 1.4),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_RulePainter old) => true;
}

/// A key's swatch, as the source draws each in a chart's legend.
enum LedgerKeySwatch {
  /// An inked line, 18 long (`.sw`).
  line,

  /// The budget's pace, dashed green (`.sw-pace`).
  pace,

  /// A hatched bar, 10 square (`swatch_bar`).
  bar,

  /// A payday's green ring, 8 round (`.sw-pay`).
  payday,

  /// The budget's ink tick (`.sw-tick`).
  tick,

  /// The suggestion's dashed green tick (`.sw-tick-g`).
  suggestion,

  /// The spent bar on its side, hatched (`.sw-bar-h`).
  spent,

  /// The spent bar past its budget, in the vermilion.
  spentOver,

  /// A hatched bar in the green, 10 square (`.sw-bar-g`): Savings' interest.
  barGreen,

  /// An allocation's stocks, hatched in the ink, 12 square (`.sw-ink`).
  allocationInk,

  /// An allocation's bonds, hatched the other way in the green (`.sw-green`).
  allocationGreen,

  /// An allocation's cash, hatched sparse in the faint ink (`.sw-pale`).
  allocationPale,
}

/// One entry of a [LedgerChartKey]: its swatch and its words.
///
/// ```dart
/// LedgerKeyEntry(LedgerKeySwatch.pace, 'Budget pace')
/// ```
class LedgerKeyEntry {
  /// An entry: [swatch] beside [label].
  const LedgerKeyEntry(this.swatch, this.label);

  /// The mark drawn before the words.
  final LedgerKeySwatch swatch;

  /// What the mark stands for.
  final String label;
}

/// A chart's key (`.legend`): each swatch 6 before its words in the third
/// ink's mono, wrapping 16 apart (6 between lines).
///
/// ```dart
/// LedgerChartKey(entries: const [LedgerKeyEntry(LedgerKeySwatch.line, 'Spent, cumulative'), LedgerKeyEntry(LedgerKeySwatch.pace, 'Budget pace')])
/// ```
class LedgerChartKey extends StatelessWidget {
  /// A key of [entries].
  const LedgerChartKey({required this.entries, super.key});

  /// The entries, in order.
  final List<LedgerKeyEntry> entries;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = t.meta.sized(11).line(16).tracked(0).colored(t.textTertiary);
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        for (final e in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              CustomPaint(
                size: switch (e.swatch) {
                  LedgerKeySwatch.line ||
                  LedgerKeySwatch.pace => const Size(18, 1.5),
                  LedgerKeySwatch.bar => const Size(10, 10),
                  LedgerKeySwatch.payday => const Size(8, 8),
                  LedgerKeySwatch.tick ||
                  LedgerKeySwatch.suggestion => const Size(2, 12),
                  LedgerKeySwatch.spent ||
                  LedgerKeySwatch.spentOver => const Size(14, 9),
                  LedgerKeySwatch.barGreen => const Size(10, 10),
                  LedgerKeySwatch.allocationInk ||
                  LedgerKeySwatch.allocationGreen ||
                  LedgerKeySwatch.allocationPale => const Size(12, 12),
                },
                painter: _SwatchPainter(e.swatch, t),
              ),
              // A label wider than the key's line wraps beside its swatch.
              Flexible(child: Text(e.label, style: words)),
            ],
          ),
      ],
    );
  }
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.swatch, this.t);

  final LedgerKeySwatch swatch;
  final LedgerThemeData t;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = t.textPrimary;
    final box = Offset.zero & size;
    switch (swatch) {
      case LedgerKeySwatch.line:
        canvas.drawRect(box, Paint()..color = ink);
      case LedgerKeySwatch.pace:
        // `.sw-pace`: border-top 1.5px dashed, 18 long. Chrome fits a dashed
        // border's dashes flush with both its ends; the captures' 4 dashes
        // of 3 about 2 apart (dashes twice the 3 device pixels' thickness).
        final (dash, gap) = _fittedDashes(size.width, 1.5);
        final paint = Paint()..color = t.pace;
        for (var x = 0.0; x < size.width - .01; x += dash + gap) {
          canvas.drawRect(
            Rect.fromLTWH(x, 0, math.min(dash, size.width - x), 1.5),
            paint,
          );
        }
      case LedgerKeySwatch.bar:
        canvas
          ..drawPath(ledgerHatchRect(0, 0, 10, 10, 2.6), ledgerStroke(ink, .7))
          ..drawRect(const Rect.fromLTWH(.5, .5, 9, 9), ledgerStroke(ink, 1));
      case LedgerKeySwatch.payday:
        canvas.drawCircle(box.center, 4 - .6, ledgerStroke(t.pace, 1.2));
      case LedgerKeySwatch.tick:
        canvas.drawRect(box, Paint()..color = ink);
      case LedgerKeySwatch.suggestion:
        for (var y = 0.0; y < size.height; y += 5) {
          canvas.drawRect(
            Rect.fromLTWH(0, y, 2, math.min(3, size.height - y)),
            Paint()..color = t.pace,
          );
        }
      case LedgerKeySwatch.spent || LedgerKeySwatch.spentOver:
        final c = swatch == LedgerKeySwatch.spentOver ? t.over : ink;
        canvas
          ..save()
          ..clipRect(box)
          ..drawPath(
            ledgerHatchRect(
              0,
              0,
              size.width,
              size.height,
              3 / math.sin(math.pi / 3),
            ),
            ledgerStroke(c, .7),
          )
          ..restore()
          ..drawRect(box.deflate(.5), ledgerStroke(c, 1));
      case LedgerKeySwatch.barGreen:
        _stripes(canvas, box, 120, 3, .7, t.pace);
        canvas.drawRect(box.deflate(.5), ledgerStroke(t.pace, 1));
      case LedgerKeySwatch.allocationInk:
        _stripes(canvas, box, 120, 2.6, .7, ink);
        canvas.drawRect(box.deflate(.5), ledgerStroke(ink, 1));
      case LedgerKeySwatch.allocationGreen:
        _stripes(canvas, box, 60, 3, .7, t.pace);
        canvas.drawRect(box.deflate(.5), ledgerStroke(t.pace, 1));
      case LedgerKeySwatch.allocationPale:
        _stripes(canvas, box, 120, 4.4, .6, t.textFaint);
        canvas.drawRect(box.deflate(.5), ledgerStroke(t.textFaint, 1));
    }
  }

  /// A dashed border's dash and gap along [length], as Chrome draws a
  /// border [width] thick at the captures' scale of 2 (its
  /// `SelectBestDashGap`): dashes twice the width, a gap of the width
  /// fitted so the dashes end flush with both ends, as many as leave the
  /// gap nearest it.
  static (double, double) _fittedDashes(double length, double width) {
    final dash = 2 * width;
    final gap = width;
    // Too short for two dashes, Chrome draws the border solid.
    if (length <= 2 * dash) return (length, 0);
    final fewest = math.max(
      2.0,
      ((length + gap) / (dash + gap)).floorToDouble(),
    );
    final most = fewest + 1;
    final fewGap = (length - fewest * dash) / (fewest - 1);
    final mostGap = (length - most * dash) / (most - 1);
    if (mostGap <= 0 || (fewGap - gap).abs() < (mostGap - gap).abs()) {
      return (dash, fewGap);
    }
    return (dash, mostGap);
  }

  /// CSS's repeating linear gradient over [box]
  /// (`repeating-linear-gradient(deg, color 0 w, transparent w period)`):
  /// stripes across the gradient's line, which runs from the corner behind it
  /// through the box's centre.
  static void _stripes(
    Canvas canvas,
    Rect box,
    double deg,
    double period,
    double width,
    Color color,
  ) {
    final a = deg * math.pi / 180;
    final u = Offset(math.sin(a), -math.cos(a));
    final half = (box.width * u.dx.abs() + box.height * u.dy.abs()) / 2;
    final start = box.center - u * half;
    final across = Offset(-u.dy, u.dx) * (box.width + box.height);
    final paint = ledgerStroke(color, width);
    canvas
      ..save()
      ..clipRect(box);
    for (var d = width / 2; d < 2 * half + width; d += period) {
      final c = start + u * d;
      canvas.drawLine(c - across, c + across, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SwatchPainter old) => old.swatch != swatch || old.t != t;
}
