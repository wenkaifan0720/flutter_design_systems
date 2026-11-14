import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../format.dart';
import '../../theme.dart';

/// How large a [FrostedMoney] stands, as the source's `.money--96/--64/--40/
/// --28`: the whole dollars at the size, its `$` (with any sign) and its
/// cents stepped down to the cents size and dropped from the top.
enum FrostedMoneySize {
  /// 96, cents 40: the desktop's hero figure (`.money--96`; a phone draws
  /// it at [large]).
  extraLarge(
    FrostedChromeMetrics.moneyGiant,
    FrostedChromeMetrics.moneyCentsGiant,
    FrostedChromeMetrics.moneyDropGiant,
    -0.035,
  ),

  /// 64, cents 28: a page's one figure on a phone (a net worth, a month's
  /// spend).
  large(
    FrostedChromeMetrics.moneyDisplay,
    FrostedChromeMetrics.moneyCentsDisplay,
    FrostedChromeMetrics.moneyDropDisplay,
    -0.035,
  ),

  /// 40, cents 16: a figure in a tile (a category's spend, a card's
  /// balance).
  regular(
    FrostedChromeMetrics.moneyFigure,
    FrostedChromeMetrics.moneyCentsFigure,
    FrostedChromeMetrics.moneyDropFigure,
    -0.03,
  ),

  /// 28, cents 16: a smaller figure (a rent band's, a transaction's, a
  /// goal's saved).
  small(
    FrostedChromeMetrics.moneyFigureSmall,
    FrostedChromeMetrics.moneyCentsFigureSmall,
    FrostedChromeMetrics.moneyDropFigureSmall,
    -0.025,
  );

  const FrostedMoneySize(this.size, this.cents, this.drop, this.tracking);

  /// The whole dollars' size.
  final double size;

  /// The `$`, sign and cents' size.
  final double cents;

  /// How far the `$` and cents drop from the top, in em of [cents].
  final double drop;

  /// The whole dollars' letter spacing, in em.
  final double tracking;
}

/// A figure that stands alone, as the source's `.money` sets it: the whole
/// dollars carry the weight in the display face; the `$` (with its sign when
/// [sign]) before it and the cents after step down to the cents size, ride
/// the cap line and go quiet. Money in ([flow] inflow, or [sign] with a
/// positive amount) is set in the green of money in, its `$` and cents at
/// 0.72. [unsigned] drops a negative's minus (a card's balance owed);
/// [cents] false prints whole dollars; [ink] recolours the dollars (a pane's
/// figure in its own ink); [fit] shrinks one wider than its room. Read aloud
/// as one amount.
///
/// ```dart
/// FrostedMoney(48210.66)
/// ```
///
/// ```dart
/// FrostedMoney(286.40, size: FrostedMoneySize.regular)
/// ```
class FrostedMoney extends StatelessWidget {
  /// Creates a [FrostedMoney].
  const FrostedMoney(
    this.amount, {
    this.flow = FrostedMoneyFlow.balance,
    this.size = FrostedMoneySize.large,
    this.sign = false,
    this.cents = true,
    this.fit = true,
    this.ink,
    this.unsigned = false,
    this.tabular = false,
    super.key,
  });

  /// The amount in dollars; negative is money out (or owed).
  final num amount;

  /// Which way the money moved: inflow sets the figure in the green.
  final FrostedMoneyFlow flow;

  /// How large the figure stands.
  final FrostedMoneySize size;

  /// Whether a positive amount carries its plus (and the green).
  final bool sign;

  /// Whether the cents are shown; false rounds to whole dollars.
  final bool cents;

  /// Whether a figure wider than its room shrinks to fit it.
  final bool fit;

  /// The dollars' colour; null takes the flow's ink.
  final Color? ink;

  /// Whether a negative amount drops its minus (a card's balance owed is
  /// printed as what is owed).
  final bool unsigned;

  /// Whether the digits are set at one width (a figure that rolls).
  final bool tabular;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // The 96 is the desktop's; a phone has no room for it.
    final s =
        size == FrostedMoneySize.extraLarge &&
            !FrostedBreakpoints.isWide(context)
        ? FrostedMoneySize.large
        : size;
    final shown = unsigned ? amount.abs() : amount;
    final green = flow == FrostedMoneyFlow.inflow || (sign && shown > 0);
    final base = switch (s) {
      FrostedMoneySize.extraLarge => t.textTheme.displayLarge,
      FrostedMoneySize.large => t.textTheme.displayMedium,
      FrostedMoneySize.regular => t.textTheme.displaySmall,
      FrostedMoneySize.small => t.textTheme.headlineLarge,
    };
    var whole = base.tracked(s.tracking).c(ink ?? t.flowInk(flow));
    if (green) whole = whole.c(ink ?? t.colorScheme.moneyIn);
    if (tabular) whole = whole.tabular;
    // `.money .cur, .money .cts`: the cents size, on a line of their own
    // height, -.01em, in the quiet ink (the green itself for money in: the
    // source's 0.72 of it read 2.9:1).
    final quiet = base
        .at(s.cents)
        .copyWith(height: 1)
        .tracked(-0.01)
        .c(green ? t.colorScheme.moneyIn : t.colorScheme.textTertiary);
    Widget figure = _Stepped(
      amount: shown,
      sign: sign,
      cents: cents,
      size: s,
      whole: whole,
      quiet: quiet,
    );
    if (fit) {
      figure = FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: figure,
      );
    }
    return Semantics(
      label: FrostedFormat.money(shown, sign: sign, cents: cents),
      excludeSemantics: true,
      child: figure,
    );
  }
}

/// The three parts on one top line (`.money { display: flex; align-items:
/// flex-start }`): the `$` with its sign, the dollars, the cents; the small
/// parts dropped by the size's share of their own height and spaced by the
/// source's gaps.
class _Stepped extends StatelessWidget {
  const _Stepped({
    required this.amount,
    required this.sign,
    required this.cents,
    required this.size,
    required this.whole,
    required this.quiet,
  });

  final num amount;
  final bool sign;
  final bool cents;
  final FrostedMoneySize size;
  final TextStyle whole;
  final TextStyle quiet;

  @override
  Widget build(BuildContext context) {
    final parts = FrostedFormat.moneyParts(amount, sign: sign);
    final small = size.cents;
    final dollars = cents
        ? parts.whole
        : FrostedFormat.count(FrostedFormat.wholeDollars(amount));
    Widget part(String text, {required double before, required double after}) =>
        Padding(
          padding: EdgeInsetsDirectional.only(
            top: small * size.drop,
            start: before,
            end: after,
          ),
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            textScaler: TextScaler.noScaling,
            style: quiet,
          ),
        );
    // Figures read left to right in every language: the sign and the
    // currency stay in front, right to left too.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          part(
            '${parts.sign}\$',
            before: 0,
            after: small * FrostedChromeMetrics.moneyCurrencyGap,
          ),
          Text(
            dollars,
            maxLines: 1,
            softWrap: false,
            textScaler: TextScaler.noScaling,
            style: whole,
          ),
          if (cents)
            part(
              '.${parts.cents}',
              before: small * FrostedChromeMetrics.moneyCentsGap,
              after: 0,
            ),
        ],
      ),
    );
  }
}

/// How large a [FrostedAmount] stands.
enum FrostedAmountSize {
  /// 12, in the text face and the quieter ink: a day head's net.
  extraSmall,

  /// 14: a part's or a menu option's amount.
  small,

  /// 16: an amount at a row's end (`.amt`).
  regular,

  /// 20, -.02em: a stat's figure (`.stat-v`, `.fig-v`, `.cfig-v`).
  large,

  /// 28, -.025em: a stat's figure on the desktop.
  extraLarge,
}

/// An amount in a column, as the source's `.amt`: the display face at 16 in
/// figures of one width, right-aligned, its cents in the quiet ink. [signed]
/// (the default) reads its direction: a positive amount is money in, in the
/// green with its plus; a negative carries a true minus. [signed] false is a
/// balance or a legend's figure, unsigned. [ink] recolours the dollars; the
/// cents stay quiet unless the amount is money in. Read aloud as one amount.
///
/// ```dart
/// FrostedAmount(-10.99)
/// ```
///
/// ```dart
/// FrostedAmount(6248.30, signed: false)
/// ```
class FrostedAmount extends StatelessWidget {
  /// Creates a [FrostedAmount].
  const FrostedAmount(
    this.amount, {
    this.signed = true,
    this.size = FrostedAmountSize.regular,
    this.cents = true,
    this.ink,
    this.textAlign,
    this.style,
    super.key,
  });

  /// The amount in dollars; negative is money out.
  final num amount;

  /// Whether the amount carries its direction (a plus and the green for
  /// money in, a minus for money out).
  final bool signed;

  /// How large the figure stands.
  final FrostedAmountSize size;

  /// Whether the cents are shown; false rounds to whole dollars.
  final bool cents;

  /// The dollars' colour; null takes the page ink.
  final Color? ink;

  /// Where the line sits in its room; null is the end (`text-align: right`).
  final TextAlign? textAlign;

  /// The figure's own text style, merged over its [size]'s: a part that
  /// sets its figure its own way (a pane's, in the stat face at its own
  /// tracking).
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Semantics(
    label: FrostedFormat.money(amount, sign: signed, cents: cents),
    excludeSemantics: true,
    child: Text.rich(
      _span(context),
      maxLines: 1,
      softWrap: false,
      textDirection: TextDirection.ltr,
      textAlign: _figureAlign(context, textAlign ?? TextAlign.end),
    ),
  );

  /// The figure's width on one line at the page's text scale, as [build]
  /// lays it out (a set of figures that shares one scale measures each).
  double _naturalWidth(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [_span(context)],
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  TextSpan _span(BuildContext context) {
    final t = context.frostedTheme;
    final parts = FrostedFormat.moneyParts(amount, sign: signed);
    final green = signed && amount > 0;
    final micro = size == FrostedAmountSize.extraSmall;
    final style = switch (size) {
      // `.amt { font: 500 16px/1.2 }`: a 19.2 line, and 16.8 where a row
      // sets it at 14 (`.part .amt`, `.fan-l .amt`); the theme's 20 and 16
      // stood every legend entry 0.8 taller (Home's October tile 2.4 by
      // its fourth row).
      FrostedAmountSize.regular =>
        t.textTheme.amount.tracked(-0.005).line(16 * 1.2),
      FrostedAmountSize.small =>
        t.textTheme.amountSmall.tracked(-0.005).line(14 * 1.2),
      // `.day .amt`: 500 12/1 in the text face.
      FrostedAmountSize.extraSmall =>
        t.textTheme.labelSmall.text.tabular.copyWith(height: 1),
      FrostedAmountSize.large => t.textTheme.stat.tracked(-0.02),
      // `.stat-v`, `.cell-amt { font: 500 20px/1.1 }`: the line a tenth
      // over the size at every size (30.8 at 28, 17.6 at 16), not the 20's
      // 22 carried to them (a desktop stat stood 8.8 short, its caption 4
      // high; a small pane's figure 2.2 low).
      FrostedAmountSize.extraLarge =>
        t.textTheme.stat.at(28).line(28 * 1.1).tracked(-0.025),
    }.merge(this.style);
    final main = green
        ? t.colorScheme.moneyIn
        : ink ??
              (micro ? t.colorScheme.textSecondary : t.colorScheme.textPrimary);
    final centsInk = green
        ? t.colorScheme.moneyIn
        : size == FrostedAmountSize.extraSmall
        ? main
        : t.colorScheme.textTertiary;
    final whole = cents
        ? parts.whole
        : FrostedFormat.count(FrostedFormat.wholeDollars(amount));
    return TextSpan(
      style: style.c(main),
      children: [
        TextSpan(text: '${parts.sign}\$$whole'),
        if (cents)
          TextSpan(
            text: '.${parts.cents}',
            style: TextStyle(color: centsInk),
          ),
      ],
    );
  }
}

/// Figures inside a line of words, as the source's `.num`: the display face
/// at the line's own size and colour, medium, in figures of one width ("··
/// 4821", "of $4,000 limit", "13 results"). [style] replaces the line's
/// style it would inherit.
///
/// ```dart
/// FrostedNumberText('4,000')
/// ```
class FrostedNumberText extends StatelessWidget {
  /// Creates a [FrostedNumberText].
  const FrostedNumberText(this.text, {this.style, super.key});

  /// The figures.
  final String text;

  /// The style the figures take their size and colour from; null inherits
  /// the line's.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    var figures = base.display.medium.tabular;
    if (base.fontSize != null) figures = figures.tracked(-0.005);
    return Text(
      text,
      style: figures,
      textDirection: TextDirection.ltr,
      textAlign: _figureAlign(context, null),
    );
  }
}

/// Where figures set left to right (as figures read in every language, so
/// "−\$1,326.44" keeps its sign in front) align on the line: [align] taken
/// against the line's own reading direction, so `end` is still the line's
/// end right to left.
TextAlign? _figureAlign(BuildContext context, TextAlign? align) {
  final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
  return switch (align) {
    TextAlign.start || null => rtl ? TextAlign.right : align,
    TextAlign.end => rtl ? TextAlign.left : TextAlign.right,
    _ => align,
  };
}

/// `.pct small { margin-left: 1px }`: the room before the `%`.
const double _percentSignGap = 1;

/// How large a [FrostedPercent] stands.
enum FrostedPercentSize {
  /// 20, -.02em: a category's share of its budget (`.pct`), a goal's
  /// progress in its row (`.goal-pct`).
  regular,

  /// 16, -.01em, at least 40 wide and right-aligned: a goal card's share
  /// after its tube (`.gc-p`).
  small,
}

/// A percentage in the display face's own (proportional) figures, its `%`
/// small and quiet after the figure (115%, 71%). The regular size stands in the secondary ink as
/// the category's share does, the small in the page ink as a goal card's;
/// [ink] sets either. Read aloud as the percentage.
///
/// ```dart
/// FrostedPercent(115)
/// ```
///
/// ```dart
/// FrostedPercent(71, size: FrostedPercentSize.small)
/// ```
class FrostedPercent extends StatelessWidget {
  /// Creates a [FrostedPercent].
  const FrostedPercent(
    this.percent, {
    this.size = FrostedPercentSize.regular,
    this.ink,
    super.key,
  });

  /// The whole percentage.
  final int percent;

  /// How large the figure stands.
  final FrostedPercentSize size;

  /// The figure's colour; null takes the size's ink.
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final small = size == FrostedPercentSize.small;
    // The face's own figures, not the stat's tabular ones: `.pct`, `.goal-pct`
    // and `.gc-p` set no `font-variant-numeric` (a tabular 1 stood 71% 6
    // wider than the source's).
    final style =
        (small
                ? t.textTheme.stat.at(16).copyWith(height: 1).tracked(-0.01)
                : t.textTheme.stat.copyWith(height: 1).tracked(-0.02))
            .copyWith(fontFeatures: const []);
    final colour =
        ink ??
        (small ? t.colorScheme.textPrimary : t.colorScheme.textSecondary);
    final digits = '$percent';
    final last = digits.length - 1;
    Widget figure = Text.rich(
      TextSpan(
        style: style.c(colour),
        children: [
          if (last > 0) TextSpan(text: digits.substring(0, last)),
          // The room before the `%` as the last figure's own tracking: a
          // WidgetSpan's placeholder brings the face's own line into the
          // line on CanvasKit (23 for a 20 figure set at height 1).
          TextSpan(
            text: digits.substring(last),
            style: TextStyle(
              letterSpacing: (style.letterSpacing ?? 0) + _percentSignGap,
            ),
          ),
          // `small`: 12, in the quiet ink, 1 after the figure; on its own
          // 12 line (the unitless `line-height: 1` it inherits), not the
          // figure's, which would hang under the figure's and stand the
          // line 1 taller; the figure's tracking as it computed it.
          TextSpan(
            text: '%',
            style: style
                .at(12)
                .c(t.colorScheme.textTertiary)
                .copyWith(letterSpacing: style.letterSpacing, height: 1),
          ),
        ],
      ),
      maxLines: 1,
      softWrap: false,
      textAlign: small ? TextAlign.end : null,
    );
    if (small) {
      figure = ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: FrostedChromeMetrics.goalCardShare,
        ),
        child: figure,
      );
    }
    return Semantics(label: '$percent%', excludeSemantics: true, child: figure);
  }
}

/// How a set of [FrostedFigure]s is laid out in a [FrostedStats].
enum FrostedStatVariant {
  /// `.stats`: one under the other with hairlines between, each figure at
  /// the line's start and its caption at the end; on the desktop a row of
  /// columns, the caption over its figure at 28, hairlines between.
  lines,

  /// `.figs`: side by side 24 apart, each caption over its figure.
  columns,

  /// `.cfigs`: three across (.8, 1.2 and 1 of the width) with inset
  /// hairlines between, a caption over each figure and its note under; on
  /// the desktop one under the other, label beside figure, hairlines
  /// between.
  cells,
}

/// One stat: a caption and its figure (stat-tile), as the source's `.stat`,
/// `.fig` and `.cfig` set them: the caption in the caption ink over the
/// figure at 20 in the display face, tabular. [flow] inflow sets the figure
/// in the green with its plus; [signed] keeps a negative's minus; [value]
/// replaces the amount with any figure (a percentage, a count); [note] a
/// second caption under the figure (a card's "of $4,000"). Several share a
/// [FrostedStats]. Read aloud as the caption then the figure.
///
/// ```dart
/// FrostedFigure(3214.09, caption: 'Spent')
/// ```
///
/// ```dart
/// FrostedFigure(6825, caption: 'In', flow: FrostedMoneyFlow.inflow)
/// ```
class FrostedFigure extends StatelessWidget {
  /// Creates a [FrostedFigure].
  const FrostedFigure(
    this.amount, {
    required this.caption,
    this.signed = false,
    this.cents = true,
    this.note,
    this.flow = FrostedMoneyFlow.balance,
    this.value,
    super.key,
  });

  /// The amount in dollars.
  final num amount;

  /// The words over the figure.
  final String caption;

  /// Whether the figure carries its direction.
  final bool signed;

  /// Whether the cents are shown.
  final bool cents;

  /// A second caption under the figure.
  final String? note;

  /// Which way the money moved: inflow sets the figure in the green.
  final FrostedMoneyFlow flow;

  /// Any figure in the amount's place.
  final Widget? value;

  /// The figure as drawn, at [size].
  Widget figure(BuildContext context, {required FrostedAmountSize size}) =>
      value ?? _amountAt(context, size);

  FrostedAmount _amountAt(BuildContext context, FrostedAmountSize size) =>
      FrostedAmount(
        amount,
        signed: signed || flow == FrostedMoneyFlow.inflow,
        cents: cents,
        size: size,
        ink: flow == FrostedMoneyFlow.transfer
            ? context.frostedTheme.colorScheme.textSecondary
            : null,
        textAlign: TextAlign.start,
      );

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return Semantics(
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FrostedChromeMetrics.figureLineGap,
        children: [
          Text(caption, style: t.textTheme.labelMedium),
          figure(context, size: FrostedAmountSize.large),
          if (note != null) Text(note!, style: t.textTheme.labelMedium),
        ],
      ),
    );
  }
}

/// A set of [FrostedFigure]s in one of three arrangements: the lines of a
/// spending tile with hairlines between (`.stats`), the columns of a
/// record's summary (`.figs`), or a card's three cells (`.cfigs`). Read
/// as its figures in order.
///
/// ```dart
/// FrostedStats(children: [FrostedFigure(3214.09, caption: 'Spent'), FrostedFigure(285.91, caption: 'Left')])
/// ```
class FrostedStats extends StatelessWidget {
  /// Creates a [FrostedStats].
  const FrostedStats({
    required this.children,
    this.variant = FrostedStatVariant.lines,
    super.key,
  });

  /// The figures, in order.
  final List<FrostedFigure> children;

  /// How they stand.
  final FrostedStatVariant variant;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    final hairline = BorderSide(color: t.colorScheme.border);
    switch (variant) {
      case FrostedStatVariant.lines when !wide:
        // `.stats { border-top }` and `.stat + .stat { border-top }`: a
        // hairline over every line. `.stat { flex-direction: row-reverse;
        // justify-content: space-between; padding: 10px 0 }`: the figure,
        // first in the markup, is drawn at the far end and its caption at
        // the start (the pilot's phone: "Left to spend · 3 days to go" ...
        // "$213.88"), 10 over and under.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final f in children)
              Container(
                decoration: BoxDecoration(border: Border(top: hairline)),
                padding: const EdgeInsets.symmetric(
                  vertical: FrostedChromeMetrics.statInset,
                ),
                child: Semantics(
                  container: true,
                  child: Row(
                    spacing: FrostedChromeMetrics.statGap,
                    children: [
                      Expanded(
                        child: Text(f.caption, style: t.textTheme.bodyMedium),
                      ),
                      f.figure(context, size: FrostedAmountSize.large),
                    ],
                  ),
                ),
              ),
          ],
        );
      case FrostedStatVariant.lines:
        // The desktop: a row of columns, each figure at 28 over its caption
        // (12, the caption ink), as `.stat { flex-direction: column }` keeps
        // the markup's order (the `.stat-v` first); 24 between them with a
        // hairline. Nothing under them: the 4 under the spending hero's is
        // that hero's (`.spent .stats { padding: 0 0 4px }`), not a
        // category's or a record's (`.stats--cat`), which it stood 4 tall.
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, f) in children.indexed)
              Container(
                margin: EdgeInsetsDirectional.only(
                  start: i == 0 ? 0 : FrostedChromeMetrics.statGapWide,
                ),
                // `.stat + .stat`: 24 of margin, a 1 hairline (an inset
                // shadow, so it takes none of the 24 of padding).
                padding: EdgeInsetsDirectional.only(
                  start: i == 0
                      ? 0
                      : FrostedChromeMetrics.statGapWide -
                            FrostedChromeMetrics.outline,
                ),
                decoration: BoxDecoration(
                  border: i == 0 ? null : BorderDirectional(start: hairline),
                ),
                child: Semantics(
                  container: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: FrostedChromeMetrics.statLineGapWide,
                    children: [
                      f.figure(context, size: FrostedAmountSize.extraLarge),
                      Text(f.caption, style: t.textTheme.labelMedium),
                    ],
                  ),
                ),
              ),
          ],
        );
      case FrostedStatVariant.columns:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: FrostedChromeMetrics.figuresGap,
          children: [for (final f in children) f],
        );
      case FrostedStatVariant.cells when !wide:
        // `.cfigs`: .8, 1.2 and 1 of the width (the middle cell holds the
        // longest figure), the second and third 12 past a hairline 12 in.
        const shares = [8, 12, 10];
        int share(int i) => shares[i % shares.length];
        return LayoutBuilder(
          builder: (context, box) {
            // One scale for every figure: the cell that runs out of room
            // first sets it for all (fitted each to its own cell, large text
            // stood the three at three sizes). A figure given as [value]
            // fits its own cell alone.
            final total = [for (var i = 0; i < children.length; i++) share(i)]
                .fold(0, (a, b) => a + b);
            final inset =
                2 * FrostedChromeMetrics.cardFigureGap -
                FrostedChromeMetrics.outline +
                hairline.width;
            final amounts = [
              for (final f in children)
                f.value == null
                    ? f._amountAt(context, FrostedAmountSize.large)
                    : null,
            ];
            final naturals = [
              for (final a in amounts) a?._naturalWidth(context),
            ];
            var scale = 1.0;
            for (final (i, natural) in naturals.indexed) {
              if (natural == null || natural <= 0) continue;
              final room =
                  box.maxWidth * share(i) / total - (i == 0 ? 0 : inset);
              if (room < natural * scale) {
                scale = room.clamp(0, natural) / natural;
              }
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, f) in children.indexed)
                  Expanded(
                    flex: share(i),
                    child: Container(
                      margin: EdgeInsetsDirectional.only(
                        start: i == 0 ? 0 : FrostedChromeMetrics.cardFigureGap,
                      ),
                      // `.cfig + .cfig`: 12 of margin, an inset hairline and
                      // 12 of padding (the hairline takes none of it).
                      padding: EdgeInsetsDirectional.only(
                        start: i == 0
                            ? 0
                            : FrostedChromeMetrics.cardFigureGap -
                                  FrostedChromeMetrics.outline,
                      ),
                      decoration: BoxDecoration(
                        border: i == 0
                            ? null
                            : BorderDirectional(start: hairline),
                      ),
                      child: Semantics(
                        container: true,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: FrostedChromeMetrics.cardFigureLineGap,
                          children: [
                            Text(f.caption, style: t.textTheme.labelMedium),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: amounts[i] == null || scale >= 1
                                  ? f.figure(
                                      context,
                                      size: FrostedAmountSize.large,
                                    )
                                  : SizedBox(
                                      width: naturals[i]! * scale,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: amounts[i],
                                      ),
                                    ),
                            ),
                            if (f.note != null)
                              Text(f.note!, style: t.textTheme.labelMedium),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      case FrostedStatVariant.cells:
        // The desktop: label beside figure (its note under the figure, at
        // the end), 10 over and under, hairlines between.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, f) in children.indexed)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: FrostedChromeMetrics.cardFigureInsetWide,
                ),
                decoration: BoxDecoration(
                  border: i == 0 ? null : Border(top: hairline),
                ),
                child: Semantics(
                  container: true,
                  child: Row(
                    spacing: FrostedChromeMetrics.cardFigureGap,
                    children: [
                      Expanded(
                        child: Text(f.caption, style: t.textTheme.bodyMedium),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: FrostedChromeMetrics.cardFigureLineGap,
                        children: [
                          f.figure(context, size: FrostedAmountSize.large),
                          if (f.note != null)
                            Text(f.note!, style: t.textTheme.labelMedium),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
    }
  }
}

/// A figure that rolls to its new value (animated-number): a [FrostedMoney]
/// in digits of one width that counts from where it stood to [amount] when
/// it changes, easing out over [duration]; a screen reader hears the amount
/// it lands on, never the ones between. With animation off it stands
/// still. Drawn from the tokens: the source never rolls a figure.
///
/// ```dart
/// FrostedCounter(balance, size: FrostedMoneySize.regular)
/// ```
class FrostedCounter extends StatelessWidget {
  /// Creates a [FrostedCounter].
  const FrostedCounter(
    this.amount, {
    this.flow = FrostedMoneyFlow.balance,
    this.size = FrostedMoneySize.large,
    this.sign = false,
    this.duration,
    super.key,
  });

  /// The amount it stands at, and rolls to when it changes.
  final num amount;

  /// Which way the figure reads (in, out, neither).
  final FrostedMoneyFlow flow;

  /// How large the figure stands.
  final FrostedMoneySize size;

  /// Whether a positive amount carries its plus.
  final bool sign;

  /// How long the roll takes; null is the theme's slow timing.
  final Duration? duration;

  @override
  Widget build(BuildContext context) => Semantics(
    label: FrostedFormat.money(amount, sign: sign),
    excludeSemantics: true,
    child: TweenAnimationBuilder<double>(
      tween: Tween<double>(end: amount.toDouble()),
      duration: FrostedMotion.of(context).moves
          ? duration ?? FrostedMotion.of(context).slow
          : Duration.zero,
      curve: FrostedMotion.of(context).curve,
      builder: (context, rolled, _) => FrostedMoney(
        rolled,
        flow: flow,
        size: size,
        sign: sign,
        tabular: true,
      ),
    ),
  );
}
