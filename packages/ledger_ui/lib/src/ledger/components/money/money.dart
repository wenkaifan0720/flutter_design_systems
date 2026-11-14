import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../format.dart';
import '../../internal/face.dart';
import '../../internal/leader.dart';
import '../../internal/whole_pixel.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// How an engraved figure is inked: [plain] in the page ink (its `$` in the
/// second ink), [moneyIn] green throughout (money received), [over]
/// vermilion (spent past a budget, its `$` still in the second ink).
enum LedgerFigureTone {
  /// In the page ink, its `$` in the second ink.
  plain,

  /// Green throughout: money received.
  moneyIn,

  /// Vermilion: spent past a budget, its `$` still in the second ink.
  over,
}

/// How large an engraved figure stands, on a phone and on the desktop, as
/// the source sizes `.fig` where each page sets it. The sizes are the
/// `quire` preset's; another preset scales them with its figure.
enum LedgerFigureSize {
  /// 88 on both: a page's figure that does not grow (a statement's).
  page(88, 88),

  /// 88, 152 on the desktop: a page's head (a balance, a month's spending).
  hero(88, LedgerChromeMetrics.heroFigureWide),

  /// 88, 120 on the desktop: a transaction's receipt.
  receipt(88, LedgerChromeMetrics.receiptFigureWide),

  /// 88, 72 on the desktop: a card's balance beside its card.
  card(88, LedgerChromeMetrics.cardFigureWide),

  /// 56, 72 on the desktop: an amount under review before it moves.
  entry(LedgerChromeMetrics.entryFigure, LedgerChromeMetrics.entryFigureWide),

  /// 44, 56 on the desktop (`.fig-m`): a section's figure.
  section(44, LedgerChromeMetrics.sectionFigureWide),

  /// 28 on a 30 line (`.fig-s`): a figure in a row of facts.
  small(28, 28);

  const LedgerFigureSize(this.phone, this.desk);

  /// Its size on a phone.
  final double phone;

  /// Its size from 1024.
  final double desk;

  /// Its style in [t]: the figure's own step for [small], else the theme's
  /// figure (or a section's) grown to the size.
  TextStyle styleIn(LedgerThemeData t, {required bool wide}) {
    final px = wide ? desk : phone;
    return switch (this) {
      small => t.figureSmall,
      section => t.figureMedium.sized(t.figureMedium.fontSize! * px / phone),
      _ => t.figure.sized(t.figure.fontSize! * px / page.phone),
    };
  }
}

/// The engraved figure, a page's one amount as the source sets it in the
/// serif (`.fig`): its `$` (and its sign) hung at the cap height at .34 of
/// the size in the second ink, the dollars, and the cents raised to the
/// same height and underlined like a cheque's. [tone] inks it; [showSign] puts
/// the plus on money received; [showCents] false drops the cents (a goal's
/// whole dollars). Read aloud as one amount.
///
/// ```dart
/// LedgerFigure(78182.56, size: LedgerFigureSize.hero)
/// ```
///
/// ```dart
/// LedgerFigure(3412.50, tone: LedgerFigureTone.moneyIn, showSign: true, size: LedgerFigureSize.receipt)
/// ```
class LedgerFigure extends StatelessWidget {
  /// The engraved figure of [amount].
  const LedgerFigure(
    this.amount, {
    this.size = LedgerFigureSize.page,
    this.tone = LedgerFigureTone.plain,
    this.showSign = false,
    this.showCents = true,
    super.key,
  });

  /// The amount in dollars; a negative carries the true minus.
  final num amount;

  /// How large it stands.
  final LedgerFigureSize size;

  /// How it is inked.
  final LedgerFigureTone tone;

  /// Whether a positive amount carries its plus.
  final bool showSign;

  /// Whether the cents are shown.
  final bool showCents;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final ink = switch (tone) {
      LedgerFigureTone.plain => t.textPrimary,
      LedgerFigureTone.moneyIn => t.moneyIn,
      LedgerFigureTone.over => t.over,
    };
    final hung = tone == LedgerFigureTone.moneyIn ? t.moneyIn : t.textSecondary;
    final style = size
        .styleIn(t, wide: LedgerLayout.isWide(context))
        .colored(ink);
    final small = style.fontSize! * LedgerChromeMetrics.currencyShare;
    final part = style.copyWith(fontSize: small, height: 1, letterSpacing: 0);
    final parts = LedgerFormat.moneyParts(amount, showSign: showSign);
    // A figure reads left to right in any page: in a right-to-left one a
    // lone sign would otherwise stand after its number.
    Text text(String s, TextStyle style) => Text(
      s,
      maxLines: 1,
      softWrap: false,
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      style: style,
    );
    return Semantics(
      label: showCents
          ? LedgerFormat.money(amount, showSign: showSign)
          : '${parts.sign}\$${parts.whole}',
      excludeSemantics: true,
      // Whole at its size wherever it fits; in a room narrower than the
      // figure (the desktop's margin from 1024 to 1180, where the source's
      // `nowrap` figure spills) it scales down whole instead of overflowing.
      // The Align hands the FittedBox loose constraints, so a tight width
      // never stretches the figure's box taller. The hung sign's drop sets
      // it a fraction tall (32.09): it stands a whole pixel, as every box.
      child: LedgerWholeHeight(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.ltr,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: small * LedgerChromeMetrics.currencyDrop,
                    right: small * LedgerChromeMetrics.currencyGap,
                  ),
                  child: text('${parts.sign}\$', part.colored(hung)),
                ),
                text(parts.whole, style),
                if (showCents)
                  Padding(
                    padding: EdgeInsets.only(
                      top: small * LedgerChromeMetrics.centsDrop,
                      left: small * LedgerChromeMetrics.centsGap,
                    ),
                    // The rule stands under the cents' .07em, as CSS's border
                    // does under its padding (a Container insets by the rule).
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: ink,
                            width: LedgerChromeMetrics.centsRule,
                          ),
                        ),
                      ),
                      padding: EdgeInsets.only(
                        bottom: small * LedgerChromeMetrics.centsUnder,
                      ),
                      child: text(parts.cents, part),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// How large a ledger amount stands.
enum LedgerAmountSize {
  /// 14 on 20, medium: a row's amount.
  row(14, FontWeight.w500),

  /// 15 on 20, bold: a statement's total (`.total .amt`). The source asks
  /// 600 of a mono it loads at 400 and 500 only, and the browser thickens
  /// the 500 cut; Flutter thickens a cut only for a weight 200 over its
  /// own, so the total asks 700 of the same 500.
  total(LedgerChromeMetrics.totalAmount, FontWeight.w700),

  /// 13 on 20, medium: an option's amount in a menu, a tile's.
  small(13, FontWeight.w500),

  /// 12 on 20, medium: a holding's change today (`.holding .h-today .amt`).
  today(12, FontWeight.w500);

  const LedgerAmountSize(this.size, this.weight);

  /// Its size in the `quire` preset (another scales it with its amount).
  final double size;

  /// Its weight.
  final FontWeight weight;
}

/// The ledger amount, as the source sets money in its rows (`.amt`): the
/// mono at 14 on 20, its sign and dollars in the [tone]'s ink, its cents
/// receding (regular, in the tone's quieter ink): money out in the ink,
/// [LedgerTone.moneyIn] green, [LedgerTone.over] vermilion, a
/// [LedgerTone.move] between the owner's own accounts quiet and regular.
/// [showSign] puts the plus on a positive amount. Read aloud as one amount.
///
/// ```dart
/// LedgerAmount(-84.25)
/// ```
///
/// ```dart
/// LedgerAmount(3412.50, tone: LedgerTone.moneyIn, showSign: true)
/// ```
class LedgerAmount extends StatelessWidget {
  /// The ledger amount of [amount], inked by [tone].
  const LedgerAmount(
    this.amount, {
    this.tone = LedgerTone.plain,
    this.showSign = false,
    this.size = LedgerAmountSize.row,
    this.textAlign,
    super.key,
  });

  /// A transaction's amount as the activity sets it (`tx_amt`): signed,
  /// green when money came in, quiet when it only [moved] between the
  /// owner's accounts (a transfer, a card's payment).
  const LedgerAmount.entry(
    this.amount, {
    bool moved = false,
    this.size = LedgerAmountSize.row,
    this.textAlign,
    super.key,
  }) : showSign = true,
       tone = moved
           ? LedgerTone.move
           : amount > 0
           ? LedgerTone.moneyIn
           : LedgerTone.plain;

  /// The amount in dollars; a negative carries the true minus.
  final num amount;

  /// How it is inked.
  final LedgerTone tone;

  /// Whether a positive amount carries its plus.
  final bool showSign;

  /// How large it stands.
  final LedgerAmountSize size;

  /// How it aligns in a box wider than itself.
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final inks = t.inks(tone);
    final base = t.amount;
    final line = base.fontSize! * base.height!;
    final style = base
        .sized(base.fontSize! * size.size / LedgerAmountSize.row.size)
        .line(line)
        .copyWith(
          fontWeight: tone == LedgerTone.move ? FontWeight.w400 : size.weight,
          color: inks.ink,
        );
    final parts = LedgerFormat.moneyParts(amount, showSign: showSign);
    // A figure reads left to right in any page (in a right-to-left one its
    // sign would otherwise stand after it); start and end stay the page's.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final align = switch (textAlign ?? TextAlign.start) {
      TextAlign.start => rtl ? TextAlign.right : TextAlign.left,
      TextAlign.end => rtl ? TextAlign.left : TextAlign.right,
      final other => other,
    };
    return Semantics(
      label: LedgerFormat.money(amount, showSign: showSign),
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            TextSpan(text: '${parts.sign}\$${parts.whole}'),
            TextSpan(
              text: '.${parts.cents}',
              style: TextStyle(color: inks.cents, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        maxLines: 1,
        softWrap: false,
        textDirection: TextDirection.ltr,
        textAlign: align,
      ),
    );
  }
}

/// The statement's total, an accountant's double rule (`.double`, two
/// rules of the ink 4 apart outside to outside) and 14 under it the
/// [title] in the semibold on a dot leader to its [amount] (15 bold).
///
/// ```dart
/// LedgerStatementTotal(title: 'Net worth', amount: 78182.56)
/// ```
class LedgerStatementTotal extends StatelessWidget {
  /// A statement's total: [title] and its [amount].
  const LedgerStatementTotal({
    required this.title,
    required this.amount,
    this.tone = LedgerTone.plain,
    super.key,
  });

  /// The total's words (New balance).
  final String title;

  /// The total.
  final num amount;

  /// How the total is inked.
  final LedgerTone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Container(
            height: LedgerChromeMetrics.doubleRule,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: t.headRule),
                bottom: BorderSide(color: t.headRule),
              ),
            ),
          ),
        ),
        const SizedBox(height: LedgerChromeMetrics.totalTop),
        MergeSemantics(
          child: LedgerLeaderLine(
            start: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.rowTitle.semibold,
            ),
            end: LedgerAmount(amount, tone: tone, size: LedgerAmountSize.total),
          ),
        ),
      ],
    );
  }
}

/// A line of a name and its value on one baseline, the dot leader between
/// them (`.leader`): dots of the faint ink (the full ink while the row
/// above is hovered or pressed) every 5, 3 tall, standing on
/// the baseline 8 clear of each, at least 16 long. The line fills its
/// width; the [end] keeps its own, and the [start] gives way first. Where
/// the start cannot keep its longest word, or (at the reader's larger text)
/// cannot stand whole, the line turns over: the start on a line of its own,
/// the leader under it running to the end, so neither is cut. A
/// setting's line stands its leader 6 clear and lets it shrink to 8
/// ([inset], [minLength]). [centred] stands the parts and the leader
/// centred on the line instead (a goal's line, `.goal .line`: align-items
/// center, the leader align-self center).
///
/// ```dart
/// LedgerLeaderLine(start: Text('Checking', style: t.rowTitle), end: LedgerAmount(6248.30))
/// ```
class LedgerLeaderLine extends StatelessWidget {
  /// A line of [start] on the dot leader to [end].
  const LedgerLeaderLine({
    required this.start,
    required this.end,
    this.inset = LedgerChromeMetrics.leaderInset,
    this.minLength = LedgerChromeMetrics.leaderMin,
    this.centred = false,
    super.key,
  });

  /// The name, at the line's start.
  final Widget start;

  /// The value, at the line's end.
  final Widget end;

  /// How far the leader stands clear of each part (8).
  final double inset;

  /// The leader's least length (16).
  final double minLength;

  /// Whether the parts and the leader stand centred on the line rather
  /// than on one baseline.
  final bool centred;

  @override
  Widget build(BuildContext context) => LedgerFace(
    // Hovered or pressed, the row's leader inks in (in Ledger's one motion):
    // the eye runs the line from its name to its figure.
    style: LedgerFaceStyle(
      ink: LedgerPressStates.isHot(context)
          ? context.ledgerTheme.textPrimary
          : context.ledgerTheme.textFaint,
    ),
    builder: (context, s, _) => _LeaderLine(
      dots: s.ink,
      textDirection: Directionality.of(context),
      inset: inset,
      minLength: minLength,
      centred: centred,
      larger: MediaQuery.textScalerOf(context).scale(1) > 1,
      start: start,
      end: end,
    ),
  );
}

enum _LineSlot { start, end }

class _LeaderLine
    extends SlottedMultiChildRenderObjectWidget<_LineSlot, RenderBox> {
  const _LeaderLine({
    required this.dots,
    required this.textDirection,
    required this.inset,
    required this.minLength,
    required this.centred,
    required this.larger,
    required this.start,
    required this.end,
  });

  final Color dots;
  final TextDirection textDirection;
  final double inset;
  final double minLength;
  final bool centred;
  final bool larger;
  final Widget start;
  final Widget end;

  @override
  Iterable<_LineSlot> get slots => _LineSlot.values;

  @override
  Widget childForSlot(_LineSlot slot) => switch (slot) {
    _LineSlot.start => start,
    _LineSlot.end => end,
  };

  @override
  _RenderLeaderLine createRenderObject(BuildContext context) =>
      _RenderLeaderLine(dots, textDirection, inset, minLength, centred, larger);

  @override
  void updateRenderObject(BuildContext context, _RenderLeaderLine line) {
    line
      ..dots = dots
      ..textDirection = textDirection
      ..inset = inset
      ..minLength = minLength
      ..centred = centred
      ..larger = larger;
  }
}

/// Where a leader line's parts stand.
typedef _Plan = ({
  Size size,
  double baseline,
  double startWidth,
  double startTop,
  double endWidth,
  double endTop,
  double leaderTop,
  double leaderLeft,
  double leader,
});

class _RenderLeaderLine extends RenderBox
    with SlottedContainerRenderObjectMixin<_LineSlot, RenderBox> {
  _RenderLeaderLine(
    this._dots,
    this._textDirection,
    this._inset,
    this._min,
    this._centred,
    this._larger,
  );

  bool _larger;
  set larger(bool value) {
    if (value == _larger) return;
    _larger = value;
    markNeedsLayout();
  }

  Color _dots;
  set dots(Color value) {
    if (value == _dots) return;
    _dots = value;
    markNeedsPaint();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  double _inset;
  set inset(double value) {
    if (value == _inset) return;
    _inset = value;
    markNeedsLayout();
  }

  double _min;
  set minLength(double value) {
    if (value == _min) return;
    _min = value;
    markNeedsLayout();
  }

  bool _centred;
  set centred(bool value) {
    if (value == _centred) return;
    _centred = value;
    markNeedsLayout();
  }

  static const double _height = LedgerChromeMetrics.leaderHeight;

  RenderBox get _start => childForSlot(_LineSlot.start)!;
  RenderBox get _end => childForSlot(_LineSlot.end)!;

  double _baseline = 0;
  double _leaderTop = 0;
  double _leaderLeft = 0;
  double _leader = 0;

  /// The line's layout: the end at its own width, the start in what is left
  /// past the leader's least, both on the lower of their baselines (a part
  /// without one stands on its foot, as Chrome synthesises it).
  _Plan _plan(
    BoxConstraints constraints,
    Size Function(RenderBox, BoxConstraints) layout,
    double? Function(RenderBox, BoxConstraints) baselineOf,
  ) {
    final maxWidth = constraints.maxWidth;
    final endIn = BoxConstraints(
      maxWidth: maxWidth,
      maxHeight: constraints.maxHeight,
    );
    final end = layout(_end, endIn);
    final room = maxWidth.isFinite
        ? math.max(0.0, maxWidth - end.width - 2 * _inset - _min)
        : double.infinity;
    final ltr = _textDirection == TextDirection.ltr;
    if (!_centred &&
        maxWidth.isFinite &&
        (room < _start.getMinIntrinsicWidth(double.infinity) ||
            (_larger && room < _start.getMaxIntrinsicWidth(double.infinity)))) {
      // The turnover: the start whole on its own line, the leader under it
      // from the line's start to the end, which stands on that line.
      final startIn = BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: constraints.maxHeight,
      );
      final start = layout(_start, startIn);
      final startBase = baselineOf(_start, startIn) ?? start.height;
      final endBase = baselineOf(_end, endIn) ?? end.height;
      final second = math.max(endBase, _height);
      final below = math.max(0.0, end.height - endBase);
      final size = constraints.constrain(
        Size(maxWidth, (start.height + second + below).roundToDouble()),
      );
      final leader = math.max(0.0, maxWidth - end.width - _inset);
      return (
        size: size,
        baseline: startBase,
        startWidth: start.width,
        startTop: 0,
        endWidth: end.width,
        endTop: start.height + second - endBase,
        leaderTop: start.height + second - _height,
        leaderLeft: ltr ? 0 : end.width + _inset,
        leader: leader < _min ? 0 : leader,
      );
    }
    final startIn = BoxConstraints(
      maxWidth: room,
      maxHeight: constraints.maxHeight,
    );
    final start = layout(_start, startIn);
    final startBase = baselineOf(_start, startIn) ?? start.height;
    final endBase = baselineOf(_end, endIn) ?? end.height;
    final width = maxWidth.isFinite
        ? maxWidth
        : start.width + end.width + 2 * _inset + _min;
    if (_centred) {
      // `.goal .line`: each part, and the leader, centred on the line.
      final tall = math
          .max(math.max(start.height, end.height), _height)
          .roundToDouble();
      final size = constraints.constrain(Size(width, tall));
      final startTop = (size.height - start.height) / 2;
      return (
        size: size,
        baseline: startTop + startBase,
        startWidth: start.width,
        startTop: startTop,
        endWidth: end.width,
        endTop: (size.height - end.height) / 2,
        leaderTop: (size.height - _height) / 2,
        leaderLeft: (ltr ? start.width : end.width) + _inset,
        leader: math.max(
          0.0,
          size.width - start.width - end.width - 2 * _inset,
        ),
      );
    }
    final baseline = math.max(math.max(startBase, endBase), _height);
    final below = math.max(start.height - startBase, end.height - endBase);
    // Two faces on one baseline stand a fraction tall (20.21): the line
    // stands the nearest whole pixel, so the rows under it do too.
    final size = constraints.constrain(
      Size(width, (baseline + math.max(0.0, below)).roundToDouble()),
    );
    return (
      size: size,
      baseline: baseline,
      startWidth: start.width,
      startTop: baseline - startBase,
      endWidth: end.width,
      endTop: baseline - endBase,
      leaderTop: baseline - _height,
      leaderLeft: (ltr ? start.width : end.width) + _inset,
      leader: math.max(0.0, size.width - start.width - end.width - 2 * _inset),
    );
  }

  static Size _dryLayout(RenderBox child, BoxConstraints c) =>
      child.getDryLayout(c);

  static double? _dryBaseline(RenderBox child, BoxConstraints c) =>
      child.getDryBaseline(c, TextBaseline.alphabetic);

  static Size _layout(RenderBox child, BoxConstraints c) {
    child.layout(c, parentUsesSize: true);
    return child.size;
  }

  static double? _baselineOf(RenderBox child, BoxConstraints c) =>
      child.getDistanceToBaseline(TextBaseline.alphabetic, onlyReal: true);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _plan(constraints, _dryLayout, _dryBaseline).size;

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) => _plan(constraints, _dryLayout, _dryBaseline).baseline;

  @override
  void performLayout() {
    final plan = _plan(constraints, _layout, _baselineOf);
    size = plan.size;
    _baseline = plan.baseline;
    _leaderTop = plan.leaderTop;
    _leaderLeft = plan.leaderLeft;
    _leader = plan.leader;
    final ltr = _textDirection == TextDirection.ltr;
    (_start.parentData! as BoxParentData).offset = Offset(
      ltr ? 0 : size.width - plan.startWidth,
      plan.startTop,
    );
    (_end.parentData! as BoxParentData).offset = Offset(
      ltr ? size.width - plan.endWidth : 0,
      plan.endTop,
    );
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => _baseline;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _start.getMinIntrinsicWidth(height) +
      _end.getMinIntrinsicWidth(height) +
      2 * _inset +
      _min;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _start.getMaxIntrinsicWidth(height) +
      _end.getMaxIntrinsicWidth(height) +
      2 * _inset +
      _min;

  @override
  double computeMinIntrinsicHeight(double width) => math.max(
    math.max(
      _start.getMinIntrinsicHeight(width),
      _end.getMinIntrinsicHeight(width),
    ),
    _height,
  );

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(
    math.max(
      _start.getMaxIntrinsicHeight(width),
      _end.getMaxIntrinsicHeight(width),
    ),
    _height,
  );

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in [_start, _end]) {
      context.paintChild(
        child,
        (child.parentData! as BoxParentData).offset + offset,
      );
    }
    if (_leader <= 0) return;
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx + _leaderLeft, offset.dy + _leaderTop);
    LedgerLeaderPainter(_dots).paint(canvas, Size(_leader, _height));
    canvas.restore();
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in [_end, _start]) {
      final at = (child.parentData! as BoxParentData).offset;
      final hit = result.addWithPaintOffset(
        offset: at,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}
