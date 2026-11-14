import 'package:flutter/widgets.dart';

import '../theme.dart';

/// One label of a plot, placed as the source places its HTML over the SVG
/// (`style="left:…%;top:…%"` in the plot's own units): its box's start at
/// [left] (or its end at [right] from the plot's end), its top at [top],
/// then moved by [shift] of its own size (CSS's `translate(-100%, -50%)` is
/// `Offset(-1, -.5)`). Plumbing of the engravings.
class LedgerPlotLabel {
  /// A label holding [child], placed at [left] or [right] and [top].
  const LedgerPlotLabel({
    required this.top,
    required this.child,
    this.left,
    this.right,
    this.shift = Offset.zero,
  }) : assert((left == null) != (right == null), 'left or right');

  /// Where the label's start stands, in the plot's units.
  final double? left;

  /// Where the label's end stands from the plot's end, when [left] is null.
  final double? right;

  /// Where the label's top stands, in the plot's units.
  final double top;

  /// How far the label moves by its own size (`Offset(-1, -.5)` is CSS's
  /// `translate(-100%, -50%)`).
  final Offset shift;

  /// The label's words.
  final Widget child;
}

/// A drawn plot: its engraving and the labels over it.
typedef LedgerPlotParts = ({
  CustomPainter painter,
  List<LedgerPlotLabel> labels,
});

/// A plot sized by its constraints: as wide as it may be, as tall as
/// [height] or the source's aspect for its width class ([phoneAspect] up to
/// 1024, [deskAspect] from it), its engraving drawn by [draw] at that size
/// in the source's own units (one unit a pixel), and its labels over it.
/// Plumbing of the engravings.
class LedgerPlot extends StatelessWidget {
  /// A plot drawn by [draw], sized by [height] or its aspects.
  const LedgerPlot({
    required this.phoneAspect,
    required this.deskAspect,
    required this.draw,
    this.height,
    super.key,
  });

  /// Height over width, as the source's phone and desktop plots stand.
  final double phoneAspect;

  /// Height over width from 1024.
  final double deskAspect;

  /// The plot's height; null takes the aspect's.
  final double? height;

  /// Draws the engraving and its labels at the plot's size.
  final LedgerPlotParts Function(Size size, bool wide) draw;

  @override
  Widget build(BuildContext context) {
    final wide = LedgerLayout.isWide(context);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth.isFinite ? box.maxWidth : _fallbackWidth;
        final h = height ?? w * (wide ? deskAspect : phoneAspect);
        final size = Size(w, h);
        final parts = draw(size, wide);
        return SizedBox(
          width: w,
          height: h,
          // The plot reads left to right in any page, its labels with it:
          // each stands beside the point it names, and a figure's sign and
          // a date's words keep their order there.
          child: Stack(
            clipBehavior: Clip.none,
            textDirection: TextDirection.ltr,
            children: [
              Positioned.fill(child: CustomPaint(painter: parts.painter)),
              if (parts.labels.isNotEmpty)
                Positioned.fill(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: labelTextScale,
                      child: CustomMultiChildLayout(
                        delegate: _LabelLayout(parts.labels),
                        children: [
                          for (var i = 0; i < parts.labels.length; i++)
                            LayoutId(id: i, child: parts.labels[i].child),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// The most a label in the plot grows with the reader's text (130%): it
  /// stands where the engraving puts it, and past this it would lie over the
  /// line and its neighbours. The chart's keys and rulers grow to the page's
  /// 200%, and a screen reader reads the chart whole.
  static const double labelTextScale = 1.3;

  static const double _fallbackWidth = 342;
}

class _LabelLayout extends MultiChildLayoutDelegate {
  _LabelLayout(this.labels);

  final List<LedgerPlotLabel> labels;

  @override
  void performLayout(Size size) {
    for (var i = 0; i < labels.length; i++) {
      final l = labels[i];
      final s = layoutChild(i, const BoxConstraints());
      final x = l.left != null
          ? l.left! + l.shift.dx * s.width
          : size.width - l.right! - s.width + l.shift.dx * s.width;
      positionChild(i, Offset(x, l.top + l.shift.dy * s.height));
    }
  }

  @override
  bool shouldRelayout(_LabelLayout old) => true;
}

/// The labels' type, as the source sets each kind over its plots. Plumbing
/// of the engravings.
extension LedgerPlotType on LedgerThemeData {
  /// `.ylab`: 400 10 on 12 in the mono, the third ink (11 from 1024).
  TextStyle plotScale(bool wide) =>
      meta.sized(wide ? 11 : 10).line(12).tracked(0).colored(textTertiary);

  /// `.ptlab`: 500 11 on 14, green.
  TextStyle get plotPoint =>
      meta.medium.sized(11).line(14).tracked(0).colored(pace);

  /// `.mark`: 500 10 on 12, green.
  TextStyle get plotMark =>
      meta.medium.sized(11).line(12).tracked(0).colored(pace);

  /// `.anno`: 400 11 on 13, the second ink.
  TextStyle get plotNote =>
      meta.sized(11).line(13).tracked(0).colored(textSecondary);

  /// `.caplab`, `.bracket-lab`: 400 10 on 12, the second ink.
  TextStyle get plotCaption =>
      meta.sized(11).line(12).tracked(0).colored(textSecondary);
}

/// [text] with its `**strong**` runs at 500 in the ink, as a plot's labels
/// set their `<b>`. Plumbing of the engravings.
Widget ledgerPlotText(
  String text,
  TextStyle style,
  Color strong, {
  TextAlign? align,
}) {
  final parts = text.split('**');
  return Text.rich(
    TextSpan(
      children: [
        for (var i = 0; i < parts.length; i++)
          if (parts[i].isNotEmpty)
            TextSpan(
              text: parts[i],
              style: i.isOdd
                  ? TextStyle(fontWeight: FontWeight.w500, color: strong)
                  : null,
            ),
      ],
    ),
    style: style,
    textAlign: align,
    softWrap: false,
  );
}

/// One label of a day ruler under a month's plot (`.xlab`): its words, the
/// x it stands centred on, and whether it is the first (set from the
/// start, unshifted) or today's (in the ink, medium).
typedef LedgerRulerMark = ({String text, double x, bool first, bool today});

/// The day ruler under a month's plot (`.xruler`): 4 under it, 14 tall,
/// each label centred on its day. Plumbing of the engravings.
class LedgerDayRulerLabels extends StatelessWidget {
  /// The day ruler's [marks] across [width].
  const LedgerDayRulerLabels({
    required this.marks,
    required this.width,
    super.key,
  });

  /// The days labelled, in order.
  final List<LedgerRulerMark> marks;

  /// The plot's width the days are spread over.
  final double width;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final base = t.plotScale(wide);
    final scaler = MediaQuery.textScalerOf(context);
    TextStyle style(LedgerRulerMark m) =>
        m.today ? base.medium.colored(t.textPrimary) : base;
    final shown = _uncrowded(scaler, style, base.fontSize ?? _fallbackSize);
    return Padding(
      padding: const EdgeInsets.only(top: _top),
      child: SizedBox(
        height: scaler.scale(_height),
        width: width,
        // Under its plot, which reads left to right in any page.
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: CustomMultiChildLayout(
            delegate: _LabelLayout([
              for (final m in shown)
                LedgerPlotLabel(
                  left: m.x,
                  top: 0,
                  shift: m.first ? Offset.zero : const Offset(-.5, 0),
                  child: const SizedBox.shrink(),
                ),
            ]),
            children: [
              for (var i = 0; i < shown.length; i++)
                LayoutId(
                  id: i,
                  child: Text(
                    shown[i].text,
                    softWrap: false,
                    style: style(shown[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // The marks that stand at least a letter's width (the type's size) clear
  // of each other: the month's first and today always, then each other in
  // order. At a large text size a day that would close up on its
  // neighbour gives way ("Oct 1 8" would read as the 18th).
  List<LedgerRulerMark> _uncrowded(
    TextScaler scaler,
    TextStyle Function(LedgerRulerMark) style,
    double size,
  ) {
    final gap = scaler.scale(size);
    final spans = <int, (double, double)>{};
    bool fixed(LedgerRulerMark m) => m.first || m.today;
    for (final i in [
      for (var i = 0; i < marks.length; i++)
        if (fixed(marks[i])) i,
      for (var i = 0; i < marks.length; i++)
        if (!fixed(marks[i])) i,
    ]) {
      final m = marks[i];
      final painter = TextPainter(
        text: TextSpan(text: m.text, style: style(m)),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = painter.width;
      painter.dispose();
      final left = m.first ? m.x : m.x - w / 2;
      final right = left + w;
      final crowded = spans.values.any(
        (s) => left < s.$2 + gap && right > s.$1 - gap,
      );
      if (crowded && !fixed(m)) continue;
      spans[i] = (left, right);
    }
    return [
      for (var i = 0; i < marks.length; i++)
        if (spans.containsKey(i)) marks[i],
    ];
  }

  static const double _top = 4;
  static const double _height = 14;
  static const double _fallbackSize = 10;
}

/// The keys under a plot of months (`.xlabs`): 8 under it, one per month
/// centred in its column, a [gutter] at the end left empty (the scale's
/// column); the [now] month green, the [end] month in the ink. Plumbing of
/// the engravings.
class LedgerMonthKeys extends StatelessWidget {
  /// The month [keys] under a plot.
  const LedgerMonthKeys({
    required this.keys,
    this.gutter = 0,
    this.now,
    this.end,
    super.key,
  });

  /// One key per month, in order.
  final List<String> keys;

  /// The room left empty at the end (the scale's column).
  final double gutter;

  /// The index of the key that is now, in the green.
  final int? now;

  /// The index of the key that ends the plot, in the ink.
  final int? end;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final base = t.plotScale(wide);
    return Padding(
      padding: const EdgeInsets.only(top: _top),
      // Under its plot, which reads left to right in any page: mirrored,
      // each month would name another month's point. A month's letter
      // stands centred on its column, so it grows as the plot's labels do
      // ([LedgerPlot.labelTextScale]): past that, a run of them would close
      // up into one word.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: LedgerPlot.labelTextScale,
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            for (var i = 0; i < keys.length; i++)
              Expanded(
                child: Text(
                  keys[i],
                  textAlign: TextAlign.center,
                  softWrap: false,
                  style: i == now
                      ? base.medium.colored(t.pace)
                      : i == end
                      ? base.medium.colored(t.textPrimary)
                      : base,
                ),
              ),
            if (gutter > 0) SizedBox(width: gutter),
          ],
        ),
      ),
    );
  }

  static const double _top = 8;
}
