import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../internal/well.dart';
import '../../theme.dart';
import '../badge/badge.dart';
import '../charts/charts.dart';
import '../pressable/pressable.dart';

/// How large a [Fluent2Stat]'s figure is: [medium] title1 (32/40, the
/// default, a tile in a row), [large] largeTitle (40/52, the one lead
/// figure of a view).
enum Fluent2StatSize {
  /// The medium size.
  medium,

  /// The large size.
  large,
}

/// A stat's change against a named period: its words ([text], "+12%
/// vs last week"), its direction ([up]) and whether that direction is good
/// ([good]; null takes up as good). Drawn as a tint badge in success's
/// green when good, danger's red when not, with the arrow of its
/// direction.
///
/// ```dart
/// Fluent2StatDelta('-3 h vs last week', up: false, good: true)
/// ```
@immutable
class Fluent2StatDelta {
  /// A change reading [text], going [up] or down.
  const Fluent2StatDelta(this.text, {this.up = true, this.good});

  /// The change's words, such as "+12% vs last week".
  final String text;

  /// Whether the figure went up.
  final bool up;

  /// Whether the change is good; null takes up as good.
  final bool? good;

  /// Whether it reads as good news.
  bool get isGood => good ?? up;
}

/// One figure and what it measures, a dashboard's stat tile (Fluent has no stat component; this one is composed
/// from its type ramp, its Card surface and its Badge): the [label] in
/// caption1 over the [value] in title1 (largeTitle at [Fluent2StatSize.large])
/// with figures of one width and an optional [unit] after it in body1, a
/// [delta] badge beside it, a quiet [caption] under it, a [trend]
/// sparkline at its foot and an [icon] at its start. On a Fluent card
/// (`neutralCardBackground`, 4 corners, 12 round, `shadow4`) unless
/// [framed] is false; with [onTap] the card opens what it counts. Read as
/// one: label, value, delta, caption.
///
/// ```dart
/// Fluent2Stat(label: 'Files shared', value: '1,284', delta: Fluent2StatDelta('+12% vs last week'), caption: 'Across 6 channels')
/// ```
class Fluent2Stat extends StatelessWidget {
  /// A stat: [value] under its [label].
  const Fluent2Stat({
    required this.label,
    required this.value,
    this.unit,
    this.delta,
    this.caption,
    this.icon,
    this.trend,
    this.size = Fluent2StatSize.medium,
    this.framed = true,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// What the figure counts.
  final String label;

  /// The figure, formatted ("1,284", "6.2").
  final String value;

  /// The unit after the figure ("GB", "h").
  final String? unit;

  /// The change against a period; null shows none.
  final Fluent2StatDelta? delta;

  /// A quiet line under the figure.
  final String? caption;

  /// A glyph before the label, in the brand.
  final IconData? icon;

  /// The figure's recent values, drawn as a sparkline at the foot.
  final List<double>? trend;

  /// Fluent's `size`: the figure's type.
  final Fluent2StatSize size;

  /// Draw the card round it.
  final bool framed;

  /// What a press on the card does; null is a still tile.
  final VoidCallback? onPressed;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final d = delta;
    final figure = (size == Fluent2StatSize.large ? t.largeTitle : t.title1)
        .tabular
        .c(t.textPrimary);
    final head = Row(
      spacing: Fluent2Spacing.sNudge,
      children: [
        if (icon != null) Icon(icon, size: 16, color: t.accentText),
        // The label runs on to a second line before it would be cut (a
        // tile's half of a phone at a large text size).
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.caption1.c(t.textSecondary),
          ),
        ),
      ],
    );
    // A figure is never cut: where it does not fit (a large text size, a
    // narrow tile) it is drawn smaller, whole.
    final number = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: value, style: figure),
            if (unit != null)
              TextSpan(text: ' ${unit!}', style: t.body1.c(t.textSecondary)),
          ],
        ),
        maxLines: 1,
      ),
    );
    final badge = d == null
        ? null
        : Fluent2LabelBadge(
            label: d.text,
            icon: d.up ? Fluent2Icons.arrowUp : Fluent2Icons.arrowDown,
            appearance: Fluent2BadgeAppearance.tint,
            color: d.isGood
                ? Fluent2BadgeColor.success
                : Fluent2BadgeColor.danger,
          );
    final line = trend;
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        head,
        const SizedBox(height: Fluent2Spacing.xs),
        Wrap(
          spacing: Fluent2Spacing.s,
          runSpacing: Fluent2Spacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [number, ?badge],
        ),
        if (caption != null) ...[
          const SizedBox(height: Fluent2Spacing.xxs),
          Text(
            caption!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.caption1.c(t.textTertiary),
          ),
        ],
        if (line != null && line.length > 1) ...[
          const SizedBox(height: Fluent2Spacing.s),
          Fluent2Sparkline(
            values: line,
            area: true,
            height: 28,
            ground: framed ? t.colors.neutralCardBackground : null,
          ),
        ],
      ],
    );
    final spoken = [
      label,
      unit == null ? value : '$value $unit',
      if (d != null) d.text,
      ?caption,
    ].join(', ');
    if (!framed) {
      return Semantics(label: spoken, excludeSemantics: true, child: body);
    }
    Widget card(Fluent2Press press) => Container(
      padding: const EdgeInsets.all(Fluent2Spacing.m),
      decoration: BoxDecoration(
        color: press.pick(
          t.colors.neutralCardBackground,
          t.colors.neutralCardBackgroundHover,
          t.colors.neutralCardBackgroundPressed,
        ),
        borderRadius: BorderRadius.circular(Fluent2Radius.medium),
        border: Border.all(
          color: t.isDark
              ? fluent2Step(t, t.colors.neutralStroke2)
              : t.colors.transparentStroke,
        ),
        boxShadow: t.shadows.shadow4,
      ),
      child: body,
    );
    final tap = onPressed;
    if (tap == null) {
      return Semantics(
        label: spoken,
        excludeSemantics: true,
        child: card(Fluent2Press.rest),
      );
    }
    return Fluent2Pressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: tap,
      label: spoken,
      radius: Fluent2Radius.medium,
      builder: (context, states) => card(states.press),
    );
  }
}

/// One item of a [Fluent2MetaLine]: its [text] and an optional [icon]
/// before it; [keepOnPhone] holds it whole while the others shorten (a time, a
/// count).
///
/// ```dart
/// Fluent2MetaItem('Edited 2h ago', icon: Fluent2Icons.clock, keepOnPhone: true)
/// ```
@immutable
class Fluent2MetaItem {
  /// One item of a meta line, reading [text].
  const Fluent2MetaItem(this.text, {this.icon, this.keepOnPhone = false});

  /// The item's words.
  final String text;

  /// The glyph before [text]; null shows none.
  final IconData? icon;

  /// Whether the item stays whole while the others shorten on a narrow screen.
  final bool keepOnPhone;
}

/// What parts a [Fluent2MetaLine]'s items: a middle [dot] (the default) or
/// a [bullet].
enum Fluent2MetaSeparator {
  /// A middle dot between the items.
  dot,

  /// A bullet between the items.
  bullet,
}

/// One dense line of facts about an item, as Fluent's list rows and file
/// cards set them ("Kai Tanaka · Edited 2h ago · 4 comments"): [items] in
/// caption1 in the second ink, each after its optional 12 glyph, parted
/// by the [separator] in the third ink; the items not kept shorten with an
/// ellipsis so the line never wraps (the kept ones too, once even they
/// overrun the width). Derived: composed from Fluent's
/// caption1 and inks. Read as one, the items in order.
///
/// ```dart
/// Fluent2MetaLine(items: const [Fluent2MetaItem('Kai Tanaka', icon: Fluent2Icons.person), Fluent2MetaItem('Edited 2h ago', keepOnPhone: true)])
/// ```
class Fluent2MetaLine extends StatelessWidget {
  /// A line of [items] with a mark between each.
  const Fluent2MetaLine({
    required this.items,
    this.separator = Fluent2MetaSeparator.dot,
    super.key,
  });

  /// The items, in order.
  final List<Fluent2MetaItem> items;

  /// The mark between items.
  final Fluent2MetaSeparator separator;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final mark = separator == Fluent2MetaSeparator.dot ? '·' : '•';
    Widget item(Fluent2MetaItem i) {
      final words = Text(
        i.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.caption1.c(t.textSecondary),
      );
      if (i.icon == null) return words;
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: Fluent2Spacing.xs,
        children: [
          Icon(i.icon, size: 12, color: t.textTertiary),
          Flexible(child: words),
        ],
      );
    }

    final style = t.caption1.c(t.textSecondary);
    return Semantics(
      label: items.map((i) => i.text).join(', '),
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          // The kept items stay whole while they and the marks fit; past
          // that every item shortens, so the line never overflows.
          final scaler = MediaQuery.textScalerOf(context);
          final direction = Directionality.of(context);
          double natural(String text) {
            final painter = TextPainter(
              text: TextSpan(text: text, style: style),
              textScaler: scaler,
              textDirection: direction,
              maxLines: 1,
            )..layout();
            final w = painter.width;
            painter.dispose();
            return w;
          }

          var fixed = 0.0;
          for (final (n, i) in items.indexed) {
            if (n > 0) fixed += natural(mark) + Fluent2Spacing.xs * 2;
            if (i.keepOnPhone) {
              fixed += natural(i.text) + (i.icon == null ? 0 : 16);
            }
          }
          final keepWhole = fixed <= box.maxWidth;
          // At a large text size the items run on to more lines, each whole,
          // rather than shrink to a letter; each mark rides the item before
          // it, so no line starts with one.
          final size = style.fontSize ?? 12;
          if (scaler.scale(size) > size * 1.3) {
            return Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (n, i) in items.indexed)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: item(i)),
                      if (n < items.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Fluent2Spacing.xs,
                          ),
                          child: Text(
                            mark,
                            style: t.caption1.c(t.textTertiary),
                          ),
                        ),
                    ],
                  ),
              ],
            );
          }
          return Row(
            children: [
              for (final (n, i) in items.indexed) ...[
                if (n > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Fluent2Spacing.xs,
                    ),
                    child: Text(mark, style: t.caption1.c(t.textTertiary)),
                  ),
                if (i.keepOnPhone && keepWhole)
                  item(i)
                else
                  Flexible(child: item(i)),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// A figure that counts its way to [value] (a total updating, a tile
/// arriving): its digits run from the value before (from [from] on its
/// first showing, when given) over 500 ms, easing out, in figures of one
/// width so the line never jitters; at once under Reduce
/// Motion. Formatted by [format] (whole numbers with thousands commas by
/// default). A screen reader hears only where it lands.
///
/// ```dart
/// Fluent2Counter(value: 1284, from: 0, style: Fluent2CounterStyle.title1)
/// ```
class Fluent2Counter extends StatelessWidget {
  /// A figure that counts to [value].
  const Fluent2Counter({
    required this.value,
    this.from,
    this.format,
    this.style = Fluent2CounterStyle.title1,
    this.color,
    super.key,
  });

  /// The figure shown.
  final double value;

  /// Where it starts on its first showing; null starts at [value].
  final double? from;

  /// The words a value is drawn in; null rounds to a whole number with
  /// thousands commas.
  final String Function(double value)? format;

  /// The figure's type.
  final Fluent2CounterStyle style;

  /// The ink; null is the first ink.
  final Color? color;

  /// [value] rounded with thousands commas: 1284 is "1,284".
  static String grouped(double value) {
    final n = value.round();
    final digits = n.abs().toString();
    final out = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final type = switch (style) {
      Fluent2CounterStyle.body1Strong => t.body1Strong,
      Fluent2CounterStyle.subtitle1 => t.subtitle1,
      Fluent2CounterStyle.title1 => t.title1,
      Fluent2CounterStyle.largeTitle => t.largeTitle,
    }.tabular.c(color ?? t.textPrimary);
    final say = format ?? grouped;
    return Semantics(
      label: say(value),
      liveRegion: true,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: from ?? value, end: value),
        duration: Fluent2Motion.on(context)
            ? Fluent2Motion.ultraSlow
            : Duration.zero,
        curve: Fluent2Motion.decelerateMid,
        // Never cut: drawn smaller, whole, where it does not fit.
        builder: (context, shown, _) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(say(shown), maxLines: 1, style: type),
        ),
      ),
    );
  }
}

/// The ramp step a [Fluent2Counter] is set in.
enum Fluent2CounterStyle {
  /// Set in body1 strong.
  body1Strong,

  /// Set in subtitle1.
  subtitle1,

  /// Set in title1.
  title1,

  /// Set in largeTitle.
  largeTitle,
}
