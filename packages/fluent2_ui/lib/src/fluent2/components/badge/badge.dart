import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../internal/cap_label.dart';
import '../../internal/well.dart';
import '../../localizations.dart';
import '../../styled.dart';
import '../../theme.dart';
import '../button/button.dart' show Fluent2IconPosition;

/// How a [Fluent2LabelBadge] wears its colour, Fluent's `appearance`: [filled]
/// the solid fill (the default), [ghost] the ink alone, [outline] the ink
/// in a stroke, [tint] the colour's pale wash with its border.
enum Fluent2BadgeAppearance {
  /// A solid fill.
  filled,

  /// Words alone, no fill or edge.
  ghost,

  /// An outline on no fill.
  outline,

  /// The tone's subtle tint with its edge.
  tint,
}

/// A badge's colour, Fluent's `color`: [brand] (the default), [danger],
/// [important] (the page's own ink, inverted), [informative] (the quiet
/// grey), [severe] (the dark orange between warning and danger),
/// [subtle] (the surface: for a badge on a photograph or a brand fill),
/// [success] and [warning].
enum Fluent2BadgeColor {
  /// The brand colour.
  brand,

  /// Fluent's danger red.
  danger,

  /// The page's own ink, inverted.
  important,

  /// The quiet grey.
  informative,

  /// The dark orange between warning and danger.
  severe,

  /// The surface, for a badge on a photograph or a brand fill.
  subtle,

  /// Fluent's success green.
  success,

  /// Fluent's warning amber.
  warning,
}

/// A badge's size, Fluent's `size`: [tiny] a 6 dot, [extraSmall] a 10
/// dot, [small] 16 tall (caption2Strong), [medium] 20 (caption1Strong,
/// the default), [large] 24, [extraLarge] 32.
enum Fluent2BadgeSize {
  /// A 6 dot.
  tiny(6, 0, 6),

  /// A 10 dot.
  extraSmall(10, 0, 10),

  /// 16 tall, in caption2Strong.
  small(16, 4, 12),

  /// 20 tall, in caption1Strong.
  medium(20, 6, 12),

  /// 24 tall.
  large(24, 6, 16),

  /// 32 tall.
  extraLarge(32, 8, 20);

  /// A size of these measures.
  const Fluent2BadgeSize(this.side, this.padding, this.glyph);

  /// Its height and least width.
  final double side;

  /// The room at its sides, the words' own 2 included.
  final double padding;

  /// Its glyph's size.
  final double glyph;

  /// Whether it is a dot that carries no words (tiny, extra small).
  bool get isDot => padding == 0;
}

/// A badge's corners, Fluent's `shape`: [circular] a pill (the default),
/// [rounded] at 4 (2 on the small sizes), [square] none.
enum Fluent2BadgeShape {
  /// A pill or a disc.
  circular,

  /// Rounded corners.
  rounded,

  /// Square corners.
  square,
}

/// The colours one Fluent Badge wears: its [fill], its words' and glyph's [ink],
/// and the 1 [stroke] laid inside its edge (transparent where it has
/// none). Plumbing of the badges.
///
/// ```dart
/// Fluent2BadgeFace.of(context.fluent2Theme, Fluent2BadgeAppearance.tint, Fluent2BadgeColor.success)
/// ```
@immutable
final class Fluent2BadgeFace {
  /// A face of [fill], [ink] and [stroke].
  const Fluent2BadgeFace({
    required this.fill,
    required this.ink,
    required this.stroke,
  });

  /// The face's fill.
  final Color fill;

  /// The words' and glyph's ink.
  final Color ink;

  /// The face's stroke.
  final Color stroke;

  /// Fluent's `useBadgeStyles` face for [appearance] in [color]. A ghost
  /// or outline badge's words stand on the page, so where Fluent's palette
  /// ink misses 4.5:1 on Fluent 2's grounds (its red, dark orange and yellow
  /// foregrounds on the ground) they wear the tone's ink instead, which holds
  /// it on every ground ([Fluent2ThemeData.tone]).
  static Fluent2BadgeFace of(
    Fluent2ThemeData t,
    Fluent2BadgeAppearance appearance,
    Fluent2BadgeColor color,
  ) {
    final c = t.colors;
    final s = t.sharedColors;
    const none = Color(0x00000000);
    switch (appearance) {
      case Fluent2BadgeAppearance.filled:
        final (Color fill, Color ink) = switch (color) {
          Fluent2BadgeColor.brand => (
            c.brandBackground,
            c.neutralForegroundOnBrand,
          ),
          Fluent2BadgeColor.danger => (
            s.paletteRedBackground3,
            c.neutralForegroundOnBrand,
          ),
          Fluent2BadgeColor.important => (
            c.neutralForeground1,
            c.neutralBackground1,
          ),
          // Fluent's neutralBackground5 step under the page's ground, so the
          // badge shows on the tinted page as on a card (solid: a badge is
          // worn over other parts); its words a step darker than Fluent's
          // third ink, to hold 4.5:1 there.
          Fluent2BadgeColor.informative => (
            Color.alphaBlend(fluent2Well(t), t.background),
            c.neutralForeground2,
          ),
          Fluent2BadgeColor.severe => (
            s.paletteDarkOrangeBackground3,
            c.neutralForegroundOnBrand,
          ),
          Fluent2BadgeColor.subtle => (
            c.neutralBackground1,
            c.neutralForeground1,
          ),
          Fluent2BadgeColor.success => (
            s.paletteGreenBackground3,
            c.neutralForegroundOnBrand,
          ),
          Fluent2BadgeColor.warning => (
            s.paletteYellowBackground3,
            c.neutralForeground1Static,
          ),
        };
        return Fluent2BadgeFace(
          fill: fill,
          ink: ink,
          stroke: c.transparentStroke,
        );
      case Fluent2BadgeAppearance.ghost:
        return Fluent2BadgeFace(
          fill: none,
          ink: _pageInk(t, color),
          stroke: none,
        );
      case Fluent2BadgeAppearance.outline:
        final ink = _pageInk(t, color);
        final stroke = switch (color) {
          Fluent2BadgeColor.danger => s.paletteRedBorder2,
          Fluent2BadgeColor.important => c.neutralStrokeAccessible,
          Fluent2BadgeColor.informative => c.neutralStroke2,
          Fluent2BadgeColor.success => s.paletteGreenBorder2,
          _ => ink,
        };
        return Fluent2BadgeFace(fill: none, ink: ink, stroke: stroke);
      case Fluent2BadgeAppearance.tint:
        final (Color fill, Color ink, Color stroke) = switch (color) {
          Fluent2BadgeColor.brand => (
            c.brandBackground2,
            c.brandForeground2,
            c.brandStroke2,
          ),
          Fluent2BadgeColor.danger => (
            s.paletteRedBackground1,
            s.paletteRedForeground1,
            s.paletteRedBorder1,
          ),
          Fluent2BadgeColor.important => (
            c.neutralForeground3,
            c.neutralBackground1,
            c.transparentStroke,
          ),
          Fluent2BadgeColor.informative => (
            c.neutralBackground4,
            c.neutralForeground3,
            c.neutralStroke2,
          ),
          Fluent2BadgeColor.severe => (
            s.paletteDarkOrangeBackground1,
            s.paletteDarkOrangeForeground1,
            s.paletteDarkOrangeBorder1,
          ),
          Fluent2BadgeColor.subtle => (
            c.neutralBackground1,
            c.neutralForeground3,
            c.neutralStroke2,
          ),
          Fluent2BadgeColor.success => (
            s.paletteGreenBackground1,
            s.paletteGreenForeground1,
            s.paletteGreenBorder1,
          ),
          Fluent2BadgeColor.warning => (
            s.paletteYellowBackground1,
            s.paletteYellowForeground1,
            s.paletteYellowBorder1,
          ),
        };
        return Fluent2BadgeFace(fill: fill, ink: ink, stroke: stroke);
    }
  }

  /// The ink of a badge with no fill, set on the page: Fluent's ghost and
  /// outline inks where they hold 4.5:1 on every page ground (the surface,
  /// the ground, a card), else the nearest that does: the status ones from
  /// the tones, the brand's `brandForeground2`, and the subtle one's
  /// `neutralForeground3` (Fluent's static white is for a coloured ground).
  static Color _pageInk(Fluent2ThemeData t, Fluent2BadgeColor color) {
    final c = t.colors;
    Color holding(Color fluent, Color fallback) {
      for (final ground in [t.surface, t.background, c.neutralCardBackground]) {
        if (Fluent2ThemeData.contrast(fluent, ground) < 4.5) return fallback;
      }
      return fluent;
    }

    return switch (color) {
      Fluent2BadgeColor.brand => holding(
        c.brandForeground1,
        c.brandForeground2,
      ),
      Fluent2BadgeColor.danger => t.tone(Fluent2Tone.danger).ink,
      Fluent2BadgeColor.important => c.neutralForeground1,
      Fluent2BadgeColor.informative => c.neutralForeground3,
      Fluent2BadgeColor.severe => t.tone(Fluent2Tone.severe).ink,
      Fluent2BadgeColor.subtle => holding(
        c.neutralForegroundStaticInverted,
        c.neutralForeground3,
      ),
      Fluent2BadgeColor.success => t.tone(Fluent2Tone.success).ink,
      Fluent2BadgeColor.warning => t.tone(Fluent2Tone.warning).ink,
    };
  }
}

/// Fluent 2's Badge: a short status or category word ([label]) with an
/// optional [icon] before it (after it with [iconAfter]) on the
/// [appearance]'s face in its [color], at one of Fluent's six sizes; the
/// tiny and extra-small sizes are dots that carry no words. It states,
/// never acts. Read as [semanticLabel], else its label; a bare dot or
/// glyph needs a [semanticLabel] to be heard.
///
/// ```dart
/// Fluent2LabelBadge(label: 'Draft', appearance: Fluent2BadgeAppearance.tint, color: Fluent2BadgeColor.informative)
/// ```
class Fluent2LabelBadge extends StatelessWidget {
  /// A badge showing [label].
  const Fluent2LabelBadge({
    this.label,
    this.icon,
    this.iconPosition = Fluent2IconPosition.before,
    this.appearance = Fluent2BadgeAppearance.filled,
    this.color = Fluent2BadgeColor.brand,
    this.size = Fluent2BadgeSize.medium,
    this.shape = Fluent2BadgeShape.circular,
    this.semanticLabel,
    super.key,
  });

  /// The words; null draws the glyph alone (or the dot).
  final String? label;

  /// A glyph beside the words, on the side [iconPosition] says.
  final IconData? icon;

  /// Which side of the words [icon] stands on.
  final Fluent2IconPosition iconPosition;

  /// Fluent's `appearance`: which of its faces it wears.
  final Fluent2BadgeAppearance appearance;

  /// Fluent's `color`.
  final Fluent2BadgeColor color;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2BadgeSize size;

  /// Fluent's `shape`: its corners.
  final Fluent2BadgeShape shape;

  /// What a screen reader says; null says [label].
  final String? semanticLabel;

  /// The corner of [shape] at [size] for a badge [height] tall.
  static double radiusOf(
    Fluent2BadgeShape shape,
    Fluent2BadgeSize size,
    double height,
  ) => switch (shape) {
    Fluent2BadgeShape.circular => height / 2,
    Fluent2BadgeShape.rounded =>
      size.index <= Fluent2BadgeSize.small.index
          ? Fluent2Radius.small
          : Fluent2Radius.medium,
    Fluent2BadgeShape.square => Fluent2Radius.none,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final own = Fluent2BadgeFace.of(t, appearance, color);
    final look = Fluent2StyleOf([t.badgeTheme], const {});
    final face = Fluent2BadgeFace(
      fill: look.fill ?? own.fill,
      ink: look.foreground ?? own.ink,
      stroke: look.side?.color ?? look.edge ?? own.stroke,
    );
    final words = size.isDot ? null : label;
    final spoken = semanticLabel ?? label;
    final type = size.index <= Fluent2BadgeSize.small.index
        ? t.caption2Strong
        : t.caption1Strong;
    final gap = size == Fluent2BadgeSize.extraLarge
        ? Fluent2Spacing.sNudge
        : Fluent2Spacing.xs;
    final glyph = icon == null
        ? null
        : Icon(icon, size: size.glyph, color: face.ink);
    Widget? content;
    if (words != null) {
      final text = fluent2CapCentred(
        Text(
          words,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: type.c(face.ink),
        ),
      );
      content = glyph == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              spacing: gap,
              children: [
                if (iconPosition == Fluent2IconPosition.before) glyph,
                Flexible(child: text),
                if (iconPosition == Fluent2IconPosition.after) glyph,
              ],
            );
    } else if (glyph != null) {
      content = glyph;
    }
    // The words' own 2 at each side are in the padding; a glyph alone
    // reaches into them, as Fluent's negative margin does.
    final side = words == null
        ? (size.padding - Fluent2Spacing.xxs).clamp(0.0, double.infinity)
        : size.padding;
    // A rounded badge takes the badge theme's outline, else the shape
    // scale's small step, as a corner no more than half its height.
    final corner = shape == Fluent2BadgeShape.rounded
        ? fluent2CornerOf(
            look.shape,
            size.side,
            radiusOf(shape, size, size.side),
          ).clamp(0, size.side / 2).toDouble()
        : radiusOf(shape, size, size.side);
    final badge = ConstrainedBox(
      constraints: BoxConstraints(minWidth: size.side, minHeight: size.side),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: face.fill,
          borderRadius: BorderRadius.circular(corner),
          border: Border.all(color: face.stroke),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: side.toDouble()),
          child: Center(widthFactor: 1, heightFactor: 1, child: content),
        ),
      ),
    );
    return Semantics(
      label: spoken,
      excludeSemantics: spoken != null,
      child: size.isDot
          ? SizedBox(width: size.side, height: size.side, child: badge)
          : badge,
    );
  }
}

/// A counter badge's colours, Fluent's `CounterBadge` `color`: [brand] (the
/// default), [danger], [important], [informative].
enum Fluent2BadgeCountColor {
  /// The brand colour.
  brand,

  /// Fluent's danger red.
  danger,

  /// Fluent's important, the strongest neutral.
  important,

  /// Fluent's informative grey.
  informative,
}

/// Fluent 2's CounterBadge: a [count] on a [Fluent2LabelBadge] (filled brand
/// and circular by default, [Fluent2BadgeAppearance.ghost] for the ink
/// alone), shown as `[overflowCount]+` past [overflowCount] (99), hidden
/// at zero unless [showZero], or a 6 [dot] that says only that something
/// is new ([Fluent2Badge.dot]). Rides [child]'s top end corner, as
/// Material's `Badge` rides an icon, or stands alone at a row's end. Read
/// as [label], else its count ("99+").
///
/// ```dart
/// Fluent2Badge(3, color: Fluent2BadgeCountColor.danger, label: '3 unread messages', child: Icon(Fluent2Icons.mail))
/// ```
class Fluent2Badge extends StatelessWidget {
  /// [count] as words.
  const Fluent2Badge(
    this.count, {
    super.key,
    this.label,
    this.child,
    this.overflowCount = 99,
    this.showZero = false,
    this.color = Fluent2BadgeCountColor.brand,
    this.appearance = Fluent2BadgeAppearance.filled,
    this.size = Fluent2BadgeSize.medium,
    this.shape = Fluent2BadgeShape.circular,
  }) : _dot = false;

  /// The 6 dot that says only that something is new ("New").
  const Fluent2Badge.dot({
    super.key,
    this.label,
    this.child,
    this.color = Fluent2BadgeCountColor.brand,
    this.appearance = Fluent2BadgeAppearance.filled,
    this.shape = Fluent2BadgeShape.circular,
  }) : count = 0,
       overflowCount = 99,
       showZero = false,
       size = Fluent2BadgeSize.tiny,
       _dot = true;

  /// What it counts.
  final int count;

  /// The largest count shown before it reads `N+`.
  final int overflowCount;

  final bool _dot;

  /// Draw a zero count instead of nothing.
  final bool showZero;

  /// Fluent's `color`.
  final Fluent2BadgeCountColor color;

  /// Fluent's two for a counter: [Fluent2BadgeAppearance.filled] or
  /// [Fluent2BadgeAppearance.ghost].
  final Fluent2BadgeAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2BadgeSize size;

  /// Fluent's `shape`: its corners.
  final Fluent2BadgeShape shape;

  /// What a screen reader says ("3 unread messages"); null says the count.
  final String? label;

  /// What it rides; null draws the badge alone.
  final Widget? child;

  /// The words a [count] shows past [overflow].
  static String textOf(int count, int overflow) =>
      count > overflow ? '$overflow+' : '$count';

  @override
  Widget build(BuildContext context) {
    final badgeColor = switch (color) {
      Fluent2BadgeCountColor.brand => Fluent2BadgeColor.brand,
      Fluent2BadgeCountColor.danger => Fluent2BadgeColor.danger,
      Fluent2BadgeCountColor.important => Fluent2BadgeColor.important,
      Fluent2BadgeCountColor.informative => Fluent2BadgeColor.informative,
    };
    final Widget? badge;
    if (_dot) {
      badge = Fluent2LabelBadge(
        appearance: appearance,
        color: badgeColor,
        size: Fluent2BadgeSize.tiny,
        shape: shape,
        semanticLabel: label ?? Fluent2Localizations.of(context).newItem,
      );
    } else if (count == 0 && !showZero) {
      badge = null;
    } else {
      final text = textOf(count, overflowCount);
      badge = Fluent2LabelBadge(
        label: text,
        appearance: appearance,
        color: badgeColor,
        size: size.isDot ? Fluent2BadgeSize.small : size,
        shape: shape,
        semanticLabel: label ?? text,
      );
    }
    final under = child;
    if (under == null) return badge ?? const SizedBox.shrink();
    if (badge == null) return under;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        under,
        PositionedDirectional(
          top: _dot ? 0 : -Fluent2Spacing.xs,
          end: _dot ? 0 : -Fluent2Spacing.xs,
          child: badge,
        ),
      ],
    );
  }
}

/// A piece of work's state, as a [Fluent2StatusGlyph] draws it.
enum Fluent2TaskStatus {
  /// Not begun: the empty circle in the quiet grey.
  notStarted,

  /// Under way: the clock in the brand.
  inProgress,

  /// Finished: the filled tick in success's green.
  done,

  /// Needs a look: the filled warning triangle in warning's ink.
  atRisk,

  /// Stopped by a fault: the filled error circle in danger's red.
  blocked,

  /// Called off: the dismiss circle in the quiet grey.
  cancelled;

  /// What a screen reader says for it.
  String get spoken => switch (this) {
    notStarted => 'Not started',
    inProgress => 'In progress',
    done => 'Done',
    atRisk => 'At risk',
    blocked => 'Blocked',
    cancelled => 'Cancelled',
  };
}

/// A status glyph's size: 16 (in a dense row, beside caption words) or 20
/// (a control's, the default).
enum Fluent2StatusGlyphSize {
  /// 16, in a dense row beside caption words.
  small(16),

  /// 20, a control's.
  medium(20);

  /// A size [side] across.
  const Fluent2StatusGlyphSize(this.side);

  /// The glyph's side.
  final double side;
}

/// A workflow state as Fluent draws one in Planner and To Do: Fluent UI
/// System Icons' status set, each [status] its glyph in its tone's ink
/// (the empty circle, the clock, the filled tick, the warning, the error
/// circle, the dismiss circle), with an optional [label] in body1 (caption1
/// at the small size) after it. The glyph never stands alone as the only
/// cue to a sighted reader of a dense list: pair it with words or a column
/// heading. Read as its [label] or the status's own name.
///
/// ```dart
/// Fluent2StatusGlyph(Fluent2TaskStatus.done, label: 'Done')
/// ```
class Fluent2StatusGlyph extends StatelessWidget {
  /// A glyph for [status].
  const Fluent2StatusGlyph(
    this.status, {
    this.label,
    this.size = Fluent2StatusGlyphSize.medium,
    this.semanticLabel,
    super.key,
  });

  /// The task status it shows.
  final Fluent2TaskStatus status;

  /// The words after the glyph; null draws the glyph alone.
  final String? label;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2StatusGlyphSize size;

  /// What a screen reader says; null says [label], else the status.
  final String? semanticLabel;

  /// The glyph and its ink for [status].
  static (IconData, Color) glyphOf(
    Fluent2ThemeData t,
    Fluent2TaskStatus status,
  ) => switch (status) {
    Fluent2TaskStatus.notStarted => (
      Fluent2Icons.circle,
      t.colors.neutralForeground3,
    ),
    Fluent2TaskStatus.inProgress => (
      Fluent2Icons.clock,
      t.colors.brandForeground1,
    ),
    Fluent2TaskStatus.done => (
      Fluent2Icons.checkmarkCircleFilled,
      t.tone(Fluent2Tone.success).ink,
    ),
    Fluent2TaskStatus.atRisk => (
      Fluent2Icons.warningFilled,
      t.tone(Fluent2Tone.warning).ink,
    ),
    Fluent2TaskStatus.blocked => (
      Fluent2Icons.errorCircleFilled,
      t.tone(Fluent2Tone.danger).ink,
    ),
    Fluent2TaskStatus.cancelled => (
      Fluent2Icons.dismissCircle,
      t.colors.neutralForeground3,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final (glyph, ink) = glyphOf(t, status);
    final mark = Icon(glyph, size: size.side, color: ink);
    final words = label;
    return Semantics(
      label: semanticLabel ?? words ?? status.spoken,
      excludeSemantics: true,
      child: words == null
          ? mark
          : Row(
              mainAxisSize: MainAxisSize.min,
              spacing: size == Fluent2StatusGlyphSize.small
                  ? Fluent2Spacing.xs
                  : Fluent2Spacing.sNudge,
              children: [
                mark,
                Flexible(
                  child: Text(
                    words,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (size == Fluent2StatusGlyphSize.small
                                ? t.caption1
                                : t.body1)
                            .c(t.textPrimary),
                  ),
                ),
              ],
            ),
    );
  }
}
