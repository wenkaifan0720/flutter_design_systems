/// Content: text in the 30 type styles, Material Symbols icons, and — on
/// tokens — the stat (with its counter), the rating and the message bubble
/// (CONTRACT §4.1 `text`, `icon`, `stat`, `message-bubble`, `rating`; the
/// chart is its own family, chart.dart). Owner: w3-media.
///
/// Compose ports:
/// - [ExpressiveText] is Compose's `Text(style = MaterialTheme.typography.X)`:
///   the style's colour is the ambient content colour (the host's
///   `onSurface`) unless given. Emphasized display and headline styles are a
///   hero moment (CONTRACT §3) and assert an [ExpressiveHeroMoment] ancestor.
/// - [ExpressiveIcon] is Compose's `Icon` over the Material Symbols font:
///   the tint is the ambient content colour, the FILL follows `selected` on
///   the fast effects spring ([ExpressiveIcon]).
///
/// Material has no stat, rating or message bubble component; these
/// are built for the host app only from the scheme's roles, the type scale, the
/// corner scale, the spacing scale, component tokens and springs.
library;

import 'package:flutter/widgets.dart';

import '../icons.dart';
import '../internal/styled_content.dart';
import '../component_themes.dart';
import '../elevation.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/large_icon_button_tokens.g.dart';
import '../internal/tokens/small_icon_button_tokens.g.dart';
import '../internal/tokens/x_large_icon_button_tokens.g.dart';
import '../internal/tokens/x_small_icon_button_tokens.g.dart';
import '../motion.dart';
import '../shape.dart';
import '../spacing.dart';
import '../states.dart';
import '../strings.dart';
import '../theme.dart';
import 'hero.dart';

// ---------------------------------------------------------------------------
// Text
// ---------------------------------------------------------------------------

/// The five families of Material's type scale.
enum ExpressiveTextRole {
  /// Display: the largest, for a short hero number or phrase.
  display,

  /// Headline: a page's or a section's lead line.
  headline,

  /// Title: a row's, a card's or a dialog's title.
  title,

  /// Body: running text.
  body,

  /// Label: a button's, a chip's, a caption's text.
  label,
}

/// The three sizes of each family.
enum ExpressiveTextSize {
  /// The family's large style.
  large,

  /// The family's medium style.
  medium,

  /// The family's small style.
  small,
}

/// The type-scale key of [role] at [size], emphasized or not: one of the
/// 30 (`displayLarge` … `labelSmallEmphasized`).
ExpressiveTypeKey expressiveTypeKeyOf(
  ExpressiveTextRole role,
  ExpressiveTextSize size, {
  bool emphasized = false,
}) {
  final name = size.name;
  final key =
      '${role.name}${name[0].toUpperCase()}${name.substring(1)}'
      '${emphasized ? 'Emphasized' : ''}';
  return ExpressiveTypeKey.values.byName(key);
}

/// Whether the emphasized [role] is a hero moment: emphasized display and
/// headline are (CONTRACT §3); emphasized title, body and label are
/// Expressive's default emphasis on selected, unread and primary labels.
bool _emphasisIsHero(ExpressiveTextRole role) =>
    role == ExpressiveTextRole.display || role == ExpressiveTextRole.headline;

/// Text in one of Material's 30 type styles: [role] at [size], [emphasized]
/// or not, in [color] (the ambient content colour when null, as Compose's
/// `Text` takes `LocalContentColor`). Display, headline and title text is
/// announced as a heading.
///
/// Emphasized display and headline text is a hero moment and asserts an
/// [ExpressiveHeroMoment] ancestor.
///
/// ```dart
/// ExpressiveText.headline('Morning pages', size: ExpressiveTextSize.small)
/// ```
class ExpressiveText extends StatelessWidget {
  /// Text showing [data] in the type style of [role] and [size].
  const ExpressiveText(
    this.data, {
    this.role = ExpressiveTextRole.body,
    this.size = ExpressiveTextSize.medium,
    this.emphasized = false,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    super.key,
  });

  /// Display text: a short hero number or phrase.
  const ExpressiveText.display(
    this.data, {
    this.size = ExpressiveTextSize.medium,
    this.emphasized = false,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    super.key,
  }) : role = ExpressiveTextRole.display;

  /// Headline text: a page's or a section's lead line.
  const ExpressiveText.headline(
    this.data, {
    this.size = ExpressiveTextSize.medium,
    this.emphasized = false,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    super.key,
  }) : role = ExpressiveTextRole.headline;

  /// Title text: a row's, a card's or a dialog's title.
  const ExpressiveText.title(
    this.data, {
    this.size = ExpressiveTextSize.medium,
    this.emphasized = false,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    super.key,
  }) : role = ExpressiveTextRole.title;

  /// Body text: running text.
  const ExpressiveText.body(
    this.data, {
    this.size = ExpressiveTextSize.medium,
    this.emphasized = false,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    super.key,
  }) : role = ExpressiveTextRole.body;

  /// Label text: a caption, a count, a tag.
  const ExpressiveText.label(
    this.data, {
    this.size = ExpressiveTextSize.medium,
    this.emphasized = false,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    super.key,
  }) : role = ExpressiveTextRole.label;

  /// The text.
  final String data;

  /// The type family.
  final ExpressiveTextRole role;

  /// The size within the family.
  final ExpressiveTextSize size;

  /// Whether the emphasized style is used.
  final bool emphasized;

  /// The colour; the ambient content colour when null.
  final Color? color;

  /// How the lines align.
  final TextAlign? textAlign;

  /// The most lines drawn.
  final int? maxLines;

  /// How overflowing text ends.
  final TextOverflow? overflow;

  /// Whether lines wrap.
  final bool? softWrap;

  /// What a screen reader says instead of [data].
  final String? semanticsLabel;

  /// The type-scale key this text is set in.
  ExpressiveTypeKey get typeKey =>
      expressiveTypeKeyOf(role, size, emphasized: emphasized);

  @override
  Widget build(BuildContext context) {
    if (emphasized && _emphasisIsHero(role)) {
      assert(
        ExpressiveHeroMoment.debugCheck(
          context,
          'Emphasized ${role.name} text',
        ),
      );
    }
    final theme = context.expressiveTheme;
    final ink =
        color ??
        DefaultTextStyle.of(context).style.color ??
        theme.colors.onSurface;
    final text = Text(
      data,
      style: theme.type.of(typeKey).copyWith(color: ink),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel,
    );
    final heading =
        role == ExpressiveTextRole.display ||
        role == ExpressiveTextRole.headline ||
        role == ExpressiveTextRole.title;
    return heading ? Semantics(header: true, child: text) : text;
  }
}

// ---------------------------------------------------------------------------
// Icon
// ---------------------------------------------------------------------------

/// The icon sizes: the icon buttons' glyph sizes (`*IconButtonTokens
/// .IconSize`), which are Material Symbols' optical sizes.
enum ExpressiveIconSize {
  /// 20dp (`XSmallIconButtonTokens.IconSize`): dense rows, inline meta.
  small(XSmallIconButtonTokens.iconSize),

  /// 24dp (`SmallIconButtonTokens.IconSize`): Compose `Icon`'s default.
  medium(SmallIconButtonTokens.iconSize),

  /// 32dp (`LargeIconButtonTokens.IconSize`).
  large(LargeIconButtonTokens.iconSize),

  /// 40dp (`XLargeIconButtonTokens.IconSize`): an empty state's glyph.
  extraLarge(XLargeIconButtonTokens.iconSize);

  const ExpressiveIconSize(this.dimension);

  /// The glyph's size, in dp.
  final double dimension;
}

// ---------------------------------------------------------------------------
// Counter and stat
// ---------------------------------------------------------------------------

/// A number that moves: when [value] changes it counts from the number it
/// shows to the new one on the slow effects spring (critically damped, so
/// it never overshoots the answer) and settles on exactly [value]. The
/// first build shows [value] without motion; a change mid-run retargets
/// from where the count is.
///
/// Each step is rounded to [fractionDigits] and rendered by [format]
/// (plain digits when null), so a money counter stays money the whole way.
/// The counter hugs its digits, takes the alignment its parent gives it,
/// and scales down only when the digits would overflow.
///
/// ```dart
/// ExpressiveCounter(steps, style: context.expressiveTheme.type.displaySmall)
/// ```
class ExpressiveCounter extends StatelessWidget {
  /// A counter that shows [value] in [style].
  const ExpressiveCounter(
    this.value, {
    required this.style,
    this.format,
    this.fractionDigits = 0,
    this.semanticsLabel,
    super.key,
  });

  /// The value to show.
  final num value;

  /// The digits' style.
  final TextStyle style;

  /// How each step is rendered; plain digits when null.
  final String Function(num value)? format;

  /// The decimals each step is rounded to.
  final int fractionDigits;

  /// What a screen reader says; the final value, rendered, when null.
  final String? semanticsLabel;

  num _rounded(double step) => fractionDigits == 0
      ? step.round()
      : double.parse(step.toStringAsFixed(fractionDigits));

  String _render(num step) =>
      format?.call(step) ?? step.toStringAsFixed(fractionDigits);

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel ?? _render(_rounded(value.toDouble())),
    child: ExcludeSemantics(
      child: ExpressiveSpringValue(
        value: value.toDouble(),
        motion: ExpressiveMotionKey.slowEffects,
        builder: (context, step, _) => Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(_render(_rounded(step)), style: style, maxLines: 1),
          ),
        ),
      ),
    ),
  );
}

/// Which way a stat moved.
enum ExpressiveTrend {
  /// Up: `trending_up` in `primary`.
  up,

  /// Down: `trending_down` in `error`.
  down,

  /// Level: no glyph, in `onSurfaceVariant`.
  flat,
}

/// A stat's sizes: the value's style.
enum ExpressiveStatSize {
  /// The value in `titleLarge`: a stat in a row or a dense grid.
  small(ExpressiveTextRole.title, ExpressiveTextSize.large),

  /// The value in `headlineMedium`: a dashboard tile.
  medium(ExpressiveTextRole.headline, ExpressiveTextSize.medium),

  /// The value in `displaySmall`: a page's lead number.
  large(ExpressiveTextRole.display, ExpressiveTextSize.small);

  const ExpressiveStatSize(this.role, this.size);

  /// The value's type family.
  final ExpressiveTextRole role;

  /// The value's size within the family.
  final ExpressiveTextSize size;
}

/// A number and what it counts: [label] (`labelLarge`, `onSurfaceVariant`,
/// with an optional leading [icon]) over [value] in the size's style
/// ([ExpressiveCounter]: a change counts to the new value on a spring),
/// then an optional [supporting] line coloured and marked by [trend].
///
/// [emphasized] sets the value in the emphasized style; on the headline
/// (m) and display (l) sizes that is a hero moment and asserts an
/// [ExpressiveHeroMoment] ancestor. Announced as one node: the label, the value,
/// the supporting line.
///
/// ```dart
/// ExpressiveStat(label: 'Pages this week', value: 42, supporting: '+6 from last week', trend: ExpressiveTrend.up)
/// ```
class ExpressiveStat extends StatelessWidget {
  /// A stat showing [value] under [label].
  const ExpressiveStat({
    required this.label,
    required this.value,
    this.format,
    this.fractionDigits = 0,
    this.supporting,
    this.trend,
    this.icon,
    this.size = ExpressiveStatSize.medium,
    this.emphasized = false,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    super.key,
  });

  /// What the number counts.
  final String label;

  /// The number.
  final num value;

  /// How the number is rendered; plain digits when null.
  final String Function(num value)? format;

  /// The decimals the number is rounded to.
  final int fractionDigits;

  /// A line under the number: a change, a target, a period.
  final String? supporting;

  /// Which way the number moved: colours and marks [supporting].
  final ExpressiveTrend? trend;

  /// A glyph before [label].
  final IconData? icon;

  /// The number's size.
  final ExpressiveStatSize size;

  /// Whether the number is set in the emphasized style.
  final bool emphasized;

  /// How the lines align: start, or centred in a dial or a tile.
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    if (emphasized && _emphasisIsHero(size.role)) {
      assert(
        ExpressiveHeroMoment.debugCheck(
          context,
          'An emphasized ExpressiveStat',
        ),
      );
    }
    final theme = context.expressiveTheme;
    final colors = theme.colors;
    final quiet = colors.onSurfaceVariant;
    final glyph = icon;
    final line = supporting;
    final trendColor = switch (trend) {
      ExpressiveTrend.up => colors.primary,
      ExpressiveTrend.down => colors.error,
      ExpressiveTrend.flat || null => quiet,
    };
    final trendGlyph = switch (trend) {
      ExpressiveTrend.up => ExpressiveSymbols.trendingUp,
      ExpressiveTrend.down => ExpressiveSymbols.trendingDown,
      ExpressiveTrend.flat || null => null,
    };
    final rendered =
        format?.call(value) ?? value.toStringAsFixed(fractionDigits);
    final labelStyle = theme.type.labelLarge.copyWith(color: quiet);
    return Semantics(
      container: true,
      label: '$label, $rendered${line == null ? '' : ', $line'}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxisAlignment,
          spacing: ExpressiveSpacing.s4,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: ExpressiveSpacing.s6,
              children: <Widget>[
                if (glyph != null)
                  ExpressiveIcon(
                    glyph,
                    size: ExpressiveIconSize.small.dimension,
                    opticalSize: ExpressiveIconSize.small.dimension,
                    color: quiet,
                  ),
                Flexible(
                  child: Text(
                    label,
                    style: labelStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            ExpressiveCounter(
              value,
              style: theme.type
                  .of(
                    expressiveTypeKeyOf(
                      size.role,
                      size.size,
                      emphasized: emphasized,
                    ),
                  )
                  .copyWith(color: colors.onSurface),
              format: format,
              fractionDigits: fractionDigits,
            ),
            if (line != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: ExpressiveSpacing.s4,
                children: <Widget>[
                  if (trendGlyph != null)
                    ExpressiveIcon(
                      trendGlyph,
                      size: ExpressiveIconSize.small.dimension,
                      opticalSize: ExpressiveIconSize.small.dimension,
                      color: trendColor,
                    ),
                  Flexible(
                    child: Text(
                      line,
                      style: theme.type.bodyMedium.copyWith(color: trendColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// How large an [ExpressiveAmount] stands.
enum ExpressiveAmountSize {
  /// In a row or a sentence: `bodyLarge`.
  inline,

  /// A card's lead, a price: `titleLarge`, its decimals in `titleSmall`.
  title,

  /// A screen's feature, a balance or a total: `displaySmall`, its
  /// decimals in `headlineSmall`.
  display,
}

/// Money as a screen shows it, already formatted for the currency
/// ([text], `$1,299.00`): tabular figures, and at the title and display
/// sizes the decimals a type step down and quieter (`onSurfaceVariant`)
/// beside the whole units; [was], the price before, struck through after
/// it. Its ink is `onSurface`, or [color] (an error for money out).
/// Announced as one node: the amount, then "was" and the old price.
///
/// ```dart
/// ExpressiveAmount(r'$1,299.00', size: ExpressiveAmountSize.display, was: r'$1,499.00')
/// ```
class ExpressiveAmount extends StatelessWidget {
  /// [text] as an amount.
  const ExpressiveAmount(
    this.text, {
    this.size = ExpressiveAmountSize.inline,
    this.color,
    this.was,
    this.semanticLabel,
    super.key,
  });

  /// The formatted amount (`$1,299.00`, `-€3.50`, `12,50 kr`).
  final String text;

  /// How large it stands.
  final ExpressiveAmountSize size;

  /// Its ink; `onSurface` when null.
  final Color? color;

  /// The formatted price before, struck through; none when null.
  final String? was;

  /// What a screen reader hears; the amount and the old price when null.
  final String? semanticLabel;

  static final RegExp _decimals = RegExp(r'^(.*\d)([.,]\d{1,2})(\D*)$');

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final ink = color ?? t.colors.onSurface;
    const figures = <FontFeature>[FontFeature.tabularFigures()];
    final (wholeKey, decimalKey) = switch (size) {
      ExpressiveAmountSize.inline => (
        ExpressiveTypeKey.bodyLarge,
        ExpressiveTypeKey.bodyLarge,
      ),
      ExpressiveAmountSize.title => (
        ExpressiveTypeKey.titleLarge,
        ExpressiveTypeKey.titleSmall,
      ),
      ExpressiveAmountSize.display => (
        ExpressiveTypeKey.displaySmall,
        ExpressiveTypeKey.headlineSmall,
      ),
    };
    final whole = t.type
        .of(wholeKey)
        .copyWith(color: ink, fontFeatures: figures);
    final quiet = size != ExpressiveAmountSize.inline;
    final decimals = quiet
        ? t.type
              .of(decimalKey)
              .copyWith(
                color: color ?? t.colors.onSurfaceVariant,
                fontFeatures: figures,
              )
        : whole;
    final match = _decimals.firstMatch(text);
    final was = this.was;
    return Semantics(
      container: true,
      label: semanticLabel ?? (was == null ? text : '$text, was $was'),
      child: ExcludeSemantics(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: ExpressiveSpacing.s8,
          children: <Widget>[
            Text.rich(
              TextSpan(
                children: match == null
                    ? <TextSpan>[TextSpan(text: text, style: whole)]
                    : <TextSpan>[
                        TextSpan(text: match.group(1), style: whole),
                        TextSpan(text: match.group(2), style: decimals),
                        if (match.group(3)!.isNotEmpty)
                          TextSpan(text: match.group(3), style: decimals),
                      ],
              ),
              maxLines: 1,
              softWrap: false,
            ),
            if (was != null)
              Text(
                was,
                maxLines: 1,
                softWrap: false,
                style: t.type.bodyMedium.copyWith(
                  color: t.colors.onSurfaceVariant,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: t.colors.onSurfaceVariant,
                  fontFeatures: figures,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rating
// ---------------------------------------------------------------------------

/// A rating's sizes: the star glyph's size.
enum ExpressiveRatingSize {
  /// 20dp stars: a rating in a row or under a title.
  small(ExpressiveIconSize.small),

  /// 24dp stars.
  medium(ExpressiveIconSize.medium),

  /// 32dp stars: the rating a review sheet asks for.
  large(ExpressiveIconSize.large);

  const ExpressiveRatingSize(this.icon);

  /// The star's icon size.
  final ExpressiveIconSize icon;
}

/// Stars out of [max]: Material Symbols' `star`, filled (FILL 1, `primary`)
/// up to [value], a `star_half` at a half, outlined (FILL 0,
/// `onSurfaceVariant`) after. The fill springs when [value] changes.
///
/// With [onChanged] each star is a pressable (state layer, ripple, focus,
/// keyboard, the 48dp touch target around the glyph) that rates the whole
/// number it stands for, announced as "Rate N of max"; without it the
/// rating is one image, announced by [semanticLabel] ("Rated 4.5 of 5"
/// when null).
///
/// ```dart
/// ExpressiveRating(value: 4.5, size: ExpressiveRatingSize.small)
/// ```
class ExpressiveRating extends StatelessWidget {
  /// A rating of [value] stars out of [max].
  const ExpressiveRating({
    required this.value,
    this.max = 5,
    this.onChanged,
    this.size = ExpressiveRatingSize.medium,
    this.semanticLabel,
    this.style,
    super.key,
  }) : assert(max > 0),
       assert(value >= 0 && value <= max);

  /// Stateful visual slots for each star target.
  final ExpressiveComponentThemeData? style;

  /// The rating, 0 to [max], in halves.
  final double value;

  /// How many stars.
  final int max;

  /// Called with the whole number of stars tapped; read-only when null.
  final ValueChanged<int>? onChanged;

  /// Whether it takes input: false when onChanged is null, as in Flutter.
  bool get enabled => onChanged != null;

  /// The stars' size.
  final ExpressiveRatingSize size;

  /// What a screen reader says of a read-only rating.
  final String? semanticLabel;

  static String _number(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final colors = context.expressiveTheme.colors;
    final halves = (value * 2).round();
    final change = onChanged;
    // Without onChanged it is a picture of a rating, read-only, not a
    // disabled control: its stars keep their colours.
    final row = Wrap(
      children: <Widget>[
        for (var i = 1; i <= max; i++)
          _star(
            context,
            index: i,
            filled: halves >= i * 2,
            half: halves == i * 2 - 1,
            on: colors.primary,
            off: colors.onSurfaceVariant,
            control: change != null,
            onPressed: change == null ? null : () => change(i),
          ),
      ],
    );
    if (change != null) return row;
    return Semantics(
      image: true,
      label:
          semanticLabel ??
          ExpressiveLocalizations.of(context).rated(_number(value), max),
      child: ExcludeSemantics(child: row),
    );
  }

  Widget _star(
    BuildContext context, {
    required int index,
    required bool filled,
    required bool half,
    required Color on,
    required Color off,
    required bool control,
    required VoidCallback? onPressed,
  }) {
    final lit = filled || half;
    final t = context.expressiveTheme;
    final visual = t.ratingTheme.merge(style);
    final states = <WidgetState>{if (lit) WidgetState.selected};
    Widget glyph(BuildContext context) => ExpressiveIcon(
      half ? ExpressiveSymbols.starHalf : ExpressiveSymbols.star,
      selected: lit,
      color:
          visual.foregroundColor?.resolve(
            ExpressiveStyleScope.maybeOf(context)?.states ?? states,
          ) ??
          (lit ? on : off),
    );
    if (!control) {
      return ExpressiveSurface(
        componentStyle: visual,
        states: states,
        shape: t.shapes.none,
        color: expressiveTransparent,
        padding: EdgeInsets.zero,
        child: IconTheme.merge(
          data: IconThemeData(
            size: visual.iconSize?.resolve(states) ?? size.icon.dimension,
          ),
          child: Builder(builder: glyph),
        ),
      );
    }
    return ExpressivePressable(
      style: style,
      componentStyle: t.ratingTheme,
      shapes: ExpressivePressShapes.all(
        context.expressiveTheme.shapes.corner(ExpressiveCorner.full),
      ),
      motion: ExpressiveMotionKey.fastSpatial,
      color: on.withValues(alpha: 0),
      contentColor: on,
      bounded: false,
      // The 40dp state layer of an icon control, not Flutter's default
      // splash radius.
      rippleRadius: ExpressiveSpacing.s40 / 2,
      selected: filled,
      semanticLabel: ExpressiveLocalizations.of(context).rate(index, max),
      onPressed: onPressed,
      child: ExpressiveStyledContent(
        iconSize: size.icon.dimension,
        minimumSize: const Size.square(ExpressiveSpacing.s48),
        child: Builder(builder: glyph),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message bubble
// ---------------------------------------------------------------------------

/// Who sent a message.
enum ExpressiveMessageSide {
  /// Someone else: at the start, on `surfaceContainerHigh`.
  incoming,

  /// You: at the end, on `primary`.
  outgoing,
}

/// Where a message sits in a run of messages from one sender: the corners
/// it shares with its neighbours are tightened.
enum ExpressiveMessagePosition {
  /// Alone: every corner round.
  single,

  /// First of a run: the sender-side bottom corner tight.
  first,

  /// Inside a run: both sender-side corners tight.
  middle,

  /// Last of a run: the sender-side top corner tight.
  last,
}

/// What became of an outgoing message.
enum ExpressiveMessageStatus {
  /// On its way: `schedule`.
  sending,

  /// Sent: `check`.
  sent,

  /// Read: a filled `check_circle`, in `primary`.
  read,

  /// Not sent: `error`, in `error`, with "Not sent".
  failed,
}

/// One chat message: [text] in `bodyLarge` on a bubble — incoming on
/// `surfaceContainerHigh` at the start, outgoing on `primary` at the end —
/// at most four fifths of the width, rounded `largeIncreased` except the
/// sender-side corners it shares with the rest of its run ([position]:
/// `extraSmall`). The first of an incoming run can name its [author]; the
/// last of a run carries the [timestamp] and, outgoing, the [status] under
/// the bubble in `labelSmall`.
///
/// The bubble spaces itself from the next: tight inside a run, a step after
/// its last. Announced as one node: the author (or "You"), the text, the
/// time and the status.
///
/// ```dart
/// ExpressiveMessageBubble(text: 'See you at the trailhead', side: ExpressiveMessageSide.outgoing, timestamp: '9:41', status: ExpressiveMessageStatus.read)
/// ```
class ExpressiveMessageBubble extends StatelessWidget {
  /// A message bubble showing [text] on the given [side].
  const ExpressiveMessageBubble({
    required this.text,
    required this.side,
    this.position = ExpressiveMessagePosition.single,
    this.author,
    this.timestamp,
    this.status,
    this.style,
    super.key,
  });

  /// Stateful visual overrides before the message-bubble theme.
  final ExpressiveComponentThemeData? style;

  /// The message.
  final String text;

  /// Who sent it.
  final ExpressiveMessageSide side;

  /// Where it sits in its run.
  final ExpressiveMessagePosition position;

  /// The sender's name, shown over the first of an incoming run.
  final String? author;

  /// When it was sent, shown under the last of a run.
  final String? timestamp;

  /// What became of an outgoing message, shown under the last of a run.
  final ExpressiveMessageStatus? status;

  bool get _outgoing => side == ExpressiveMessageSide.outgoing;

  bool get _closesRun =>
      position == ExpressiveMessagePosition.single ||
      position == ExpressiveMessagePosition.last;

  bool get _opensRun =>
      position == ExpressiveMessagePosition.single ||
      position == ExpressiveMessagePosition.first;

  /// The bubble's shape in [shapes]: round, tight where it meets its run.
  ExpressiveCornerBorder shapeIn(ExpressiveShapes shapes) {
    final round = shapes.corner(ExpressiveCorner.largeIncreased).topStart;
    final tight = shapes.corner(ExpressiveCorner.extraSmall).topStart;
    final tightTop =
        position == ExpressiveMessagePosition.middle ||
        position == ExpressiveMessagePosition.last;
    final tightBottom =
        position == ExpressiveMessagePosition.middle ||
        position == ExpressiveMessagePosition.first;
    return ExpressiveCornerBorder(
      topStart: !_outgoing && tightTop ? tight : round,
      bottomStart: !_outgoing && tightBottom ? tight : round,
      topEnd: _outgoing && tightTop ? tight : round,
      bottomEnd: _outgoing && tightBottom ? tight : round,
    );
  }

  String _statusText(ExpressiveLocalizations strings) => switch (status) {
    ExpressiveMessageStatus.sending => strings.messageSending,
    ExpressiveMessageStatus.sent => strings.messageSent,
    ExpressiveMessageStatus.read => strings.messageRead,
    ExpressiveMessageStatus.failed => strings.messageFailed,
    null => '',
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    final strings = ExpressiveLocalizations.of(context);
    final colors = theme.colors;
    final container = _outgoing ? colors.primary : colors.surfaceContainerHigh;
    final ink = _outgoing ? colors.onPrimary : colors.onSurface;
    final quiet = colors.onSurfaceVariant;
    final name = author;
    final time = timestamp;
    final state = _outgoing ? status : null;
    final showMeta = _closesRun && (time != null || state != null);
    final failed = state == ExpressiveMessageStatus.failed;
    final metaColor = failed ? colors.error : quiet;
    final statusGlyph = switch (state) {
      ExpressiveMessageStatus.sending => ExpressiveSymbols.schedule,
      ExpressiveMessageStatus.sent => ExpressiveSymbols.check,
      ExpressiveMessageStatus.read => ExpressiveSymbols.checkCircle,
      ExpressiveMessageStatus.failed => ExpressiveSymbols.error,
      null => null,
    };
    final metaStyle = theme.type.labelSmall.copyWith(color: metaColor);

    final states = <WidgetState>{if (failed) WidgetState.error};
    final resolved = theme.messageBubbleTheme.merge(style);
    final bubble = ExpressiveSurface(
      style: style,
      componentStyle: theme.messageBubbleTheme,
      states: states,
      color: container,
      contentColor: ink,
      shape: shapeIn(theme.shapes),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: ExpressiveSpacing.s16,
        vertical: ExpressiveSpacing.s10,
      ),
      child: Text(
        text,
        style: theme.type.bodyLarge
            .merge(resolved.textStyle?.resolve(states))
            .copyWith(color: resolved.foregroundColor?.resolve(states) ?? ink),
      ),
    );

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _outgoing
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: <Widget>[
        if (name != null && !_outgoing && _opensRun)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: ExpressiveSpacing.s16,
              bottom: ExpressiveSpacing.s4,
            ),
            child: Text(
              name,
              style: theme.type.labelMedium.copyWith(color: quiet),
            ),
          ),
        bubble,
        if (showMeta)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: ExpressiveSpacing.s4,
              start: ExpressiveSpacing.s4,
              end: ExpressiveSpacing.s4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: ExpressiveSpacing.s4,
              children: <Widget>[
                if (time != null) Text(time, style: metaStyle),
                if (statusGlyph != null)
                  ExpressiveIcon(
                    statusGlyph,
                    selected: state == ExpressiveMessageStatus.read,
                    size: ExpressiveIconSize.small.dimension,
                    opticalSize: ExpressiveIconSize.small.dimension,
                    color: state == ExpressiveMessageStatus.read
                        ? colors.primary
                        : metaColor,
                  ),
                if (failed) Text(_statusText(strings), style: metaStyle),
              ],
            ),
          ),
      ],
    );

    final spoken = <String>[
      if (_outgoing) strings.messageFromYou else ?name,
      text,
      ?time,
      if (state != null) _statusText(strings),
    ].join(', ');

    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: _closesRun ? ExpressiveSpacing.s12 : ExpressiveSpacing.s2,
      ),
      child: Semantics(
        container: true,
        label: spoken,
        child: ExcludeSemantics(
          child: Row(
            children: <Widget>[
              if (_outgoing) const Spacer(),
              Flexible(
                flex: 4,
                child: Align(
                  alignment: _outgoing
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: column,
                ),
              ),
              if (!_outgoing) const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
