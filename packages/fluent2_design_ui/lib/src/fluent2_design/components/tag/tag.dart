import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../internal/cap_label.dart';
import '../../internal/hit_slop.dart';
import '../../internal/well.dart';
import '../../localizations.dart';
import '../../styled.dart';
import '../../theme.dart';
import '../avatar/avatar.dart';
import '../pressable/pressable.dart';

/// A tag's fill, Fluent's Tag `appearance`: [filled] the quiet grey (the
/// default), [outline] a stroke on the page, [brand] the brand's tint.
enum Fluent2TagAppearance {
  /// The neutral fill.
  filled,

  /// An outline on no fill.
  outline,

  /// The brand tint.
  brand,
}

/// A tag's size, Fluent's `size`: [medium] 32 tall in body1 (the default),
/// [small] 24 in caption1, [extraSmall] 20 in caption1.
enum Fluent2TagSize {
  /// 32 tall in body1.
  medium(32, 7, 20, 28, 4, 8, Fluent2Spacing.s),

  /// 24 tall in caption1.
  small(24, 5, 16, 20, 2, 6, Fluent2Spacing.sNudge),

  /// 20 tall in caption1.
  extraSmall(20, 5, 12, 16, 2, 6, Fluent2Spacing.xs);

  /// A size of these measures.
  const Fluent2TagSize(
    this.height,
    this.side,
    this.glyph,
    this.avatar,
    this.glyphGap,
    this.mediaGap,
    this.groupGap,
  );

  /// Its height.
  final double height;

  /// The room at a side with nothing at it (7, 5, 5).
  final double side;

  /// A glyph's and the dismiss mark's size (20, 16, 12).
  final double glyph;

  /// The avatar's side (Fluent's `tagAvatarSizeMap`: 28, 20, 16).
  final double avatar;

  /// The room after a glyph and before the dismiss mark (4, 2, 2).
  final double glyphGap;

  /// The room after an avatar (8, 6, 6).
  final double mediaGap;

  /// The gap between the tags of a [Fluent2TagGroup] (8, 6, 4).
  final double groupGap;
}

/// A tag's corners, Fluent's `shape`: [rounded] at 4 (the default) or a
/// [circular] pill; an avatar in a rounded tag is square.
enum Fluent2TagShape {
  /// Rounded corners.
  rounded,

  /// A pill.
  circular,
}

/// The colours of one Fluent Tag in one state: its [fill], its [stroke], its
/// words' [ink] and its glyph's [glyph]. Plumbing of the tags.
///
/// ```dart
/// Fluent2TagFace.of(context.fluent2Theme, Fluent2TagAppearance.brand, Fluent2Press.hover)
/// ```
@immutable
final class Fluent2TagFace {
  /// A face of [fill], [stroke], [ink] and [glyph].
  const Fluent2TagFace({
    required this.fill,
    required this.stroke,
    required this.ink,
    required this.glyph,
    required this.divider,
  });

  /// The face's fill.
  final Color fill;

  /// The face's stroke.
  final Color stroke;

  /// The words' ink.
  final Color ink;

  /// The glyph's ink.
  final Color glyph;

  /// The hairline before an interaction tag's dismiss part.
  final Color divider;

  /// The face a share [t] of the way from [a] to [b]: what a tag wears while
  /// it eases from one state to the next.
  static Fluent2TagFace lerp(Fluent2TagFace a, Fluent2TagFace b, double t) =>
      Fluent2TagFace(
        fill: Color.lerp(a.fill, b.fill, t)!,
        stroke: Color.lerp(a.stroke, b.stroke, t)!,
        ink: Color.lerp(a.ink, b.ink, t)!,
        glyph: Color.lerp(a.glyph, b.glyph, t)!,
        divider: Color.lerp(a.divider, b.divider, t)!,
      );

  @override
  bool operator ==(Object other) =>
      other is Fluent2TagFace &&
      other.fill == fill &&
      other.stroke == stroke &&
      other.ink == ink &&
      other.glyph == glyph &&
      other.divider == divider;

  @override
  int get hashCode => Object.hash(fill, stroke, ink, glyph, divider);

  /// Fluent's `useTagStyles` / `useInteractionTagPrimaryStyles` face of
  /// [appearance] in [press], [selected] or not. The brand tag's hover and
  /// pressed words keep `brandForeground2Hover` / `Pressed`: Fluent's
  /// `compoundBrandForeground1` steps read 3.8:1 on the pressed brand tint
  /// in the generated presets.
  static Fluent2TagFace of(
    Fluent2ThemeData t,
    Fluent2TagAppearance appearance,
    Fluent2Press press, {
    bool selected = false,
  }) {
    final c = t.colors;
    if (press == Fluent2Press.disabled) {
      final outline = appearance == Fluent2TagAppearance.outline;
      return Fluent2TagFace(
        fill: outline ? c.subtleBackground : fluent2WellDisabled(t),
        stroke: outline
            ? fluent2Step(t, c.neutralStrokeDisabled)
            : c.transparentStrokeDisabled,
        ink: c.neutralForegroundDisabled,
        glyph: c.neutralForegroundDisabled,
        divider: fluent2Step(t, c.neutralStrokeDisabled),
      );
    }
    if (selected) {
      return Fluent2TagFace(
        fill: press.pick(
          c.brandBackground,
          c.brandBackgroundHover,
          c.brandBackgroundPressed,
        ),
        stroke: c.brandStroke1,
        ink: c.neutralForegroundOnBrand,
        glyph: c.neutralForegroundOnBrand,
        divider: c.neutralStrokeOnBrand2,
      );
    }
    switch (appearance) {
      case Fluent2TagAppearance.filled:
        final ink = press.pick(
          c.neutralForeground2,
          c.neutralForeground2Hover,
          c.neutralForeground2Pressed,
        );
        // Fluent's neutralBackground3 step laid over the ground, so a tag
        // shows on the tinted page as on a card.
        return Fluent2TagFace(
          fill: fluent2Well(t, press),
          stroke: c.transparentStroke,
          ink: ink,
          glyph: ink,
          divider: c.neutralStroke1,
        );
      case Fluent2TagAppearance.outline:
        return Fluent2TagFace(
          fill: press.pick(
            c.subtleBackground,
            c.subtleBackgroundHover,
            c.subtleBackgroundPressed,
          ),
          stroke: c.neutralStroke1,
          ink: press.pick(
            c.neutralForeground2,
            c.neutralForeground2Hover,
            c.neutralForeground2Pressed,
          ),
          glyph: press.pick(
            c.neutralForeground2,
            c.neutralForeground2BrandHover,
            c.neutralForeground2BrandPressed,
          ),
          divider: c.neutralStroke1,
        );
      case Fluent2TagAppearance.brand:
        final ink = press.pick(
          c.brandForeground2,
          c.brandForeground2Hover,
          c.brandForeground2Pressed,
        );
        return Fluent2TagFace(
          fill: press.pick(
            c.brandBackground2,
            c.brandBackground2Hover,
            c.brandBackground2Pressed,
          ),
          stroke: c.transparentStroke,
          ink: ink,
          glyph: ink,
          divider: c.brandStroke2,
        );
    }
  }

  /// The dismiss mark's ink in [press] (Fluent's `dismissIcon` styles:
  /// the compound brand under the pointer, on brand when selected).
  static Color dismissOf(
    Fluent2ThemeData t,
    Fluent2TagFace face,
    Fluent2Press press, {
    bool selected = false,
  }) {
    if (press == Fluent2Press.disabled || press == Fluent2Press.rest) {
      return face.glyph;
    }
    if (selected) return t.colors.neutralForegroundOnBrand;
    return press == Fluent2Press.hover
        ? t.colors.compoundBrandForeground1Hover
        : t.colors.compoundBrandForeground1Pressed;
  }
}

/// The words and the leading part of a tag, laid as Fluent's Tag grid
/// lays them. Plumbing of the tags.
class _TagContent extends StatelessWidget {
  const _TagContent({
    required this.label,
    required this.secondary,
    required this.icon,
    required this.avatar,
    required this.size,
    required this.shape,
    required this.face,
    required this.endRoom,
  });

  final String label;
  final String? secondary;
  final IconData? icon;
  final String? avatar;
  final Fluent2TagSize size;
  final Fluent2TagShape shape;
  final Fluent2TagFace face;

  /// The room after the words (none where a dismiss mark follows).
  final double endRoom;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final type = size == Fluent2TagSize.medium ? t.body1 : t.caption1;
    final two = secondary != null;
    // One line of words has its capitals on the tag's middle (Fluent's Tag
    // grid keeps 2 of room under its line box for the same end). Two lines (caption1 16 over caption2
    // 14) share the grid's two equal rows of the 30 inside the stroke, each
    // centred in its own, the first by a margin box 2 shorter at its top
    // (`margin-top: -2px`): 1 apart, the pair 1 over the middle.
    final words = two
        ? Transform.translate(
            offset: const Offset(0, -Fluent2Spacing.xxs / 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.caption1.c(face.ink),
                ),
                const SizedBox(height: Fluent2Stroke.thin),
                Text(
                  secondary!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.caption2.c(face.ink),
                ),
              ],
            ),
          )
        : fluent2CapCentred(
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: type.c(face.ink),
            ),
          );
    final who = avatar;
    final Widget? lead = who != null
        ? Padding(
            padding: EdgeInsetsDirectional.only(start: 1, end: size.mediaGap),
            child: Fluent2Avatar(
              name: who,
              size: size.avatar,
              color: Fluent2AvatarColor.colorful,
              shape: shape == Fluent2TagShape.rounded
                  ? Fluent2AvatarShape.square
                  : Fluent2AvatarShape.circular,
            ),
          )
        : icon != null
        ? Padding(
            padding: EdgeInsetsDirectional.only(
              start: size.side,
              end: size.glyphGap,
            ),
            child: Icon(icon, size: size.glyph, color: face.glyph),
          )
        : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        lead ?? SizedBox(width: size.side),
        Flexible(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: Fluent2Spacing.xxs,
              end: Fluent2Spacing.xxs + endRoom,
            ),
            child: words,
          ),
        ),
      ],
    );
  }
}

/// Fluent 2's Tag: a compact label for a category, a person or a picked
/// value: [label] (over a [secondary] line in caption2 at the medium
/// size) after an [icon] or a person's [avatar], on the [appearance]'s
/// face at Fluent's three sizes. Static, it states (a file's labels, a
/// task's project); with [onDismiss] it is a removable token (a picked
/// recipient) whose whole face is one button ending in the dismiss mark.
/// [enabled] false draws the disabled face. Read as its
/// label (and "remove" with [onDismiss]).
///
/// ```dart
/// Fluent2Tag('Launch', icon: Fluent2Icons.folder, appearance: Fluent2TagAppearance.brand)
/// ```
class Fluent2Tag extends StatelessWidget {
  /// A tag showing [label].
  const Fluent2Tag(
    this.label, {
    this.secondary,
    this.icon,
    this.avatar,
    this.appearance = Fluent2TagAppearance.filled,
    this.size = Fluent2TagSize.medium,
    this.shape = Fluent2TagShape.rounded,
    this.onDeleted,
    this.enabled = true,
    this.deleteLabel,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// This tag's own look over the chip theme: `fill`, `edge`, `side`,
  /// `foreground` and `shape` (its corner radius, at most half its height)
  /// in its states.
  final Fluent2Style? style;

  /// The tag's words.
  final String label;

  /// A second line under the label (the medium size only).
  final String? secondary;

  /// A glyph before the words.
  final IconData? icon;

  /// A person's name: their colourful avatar before the words (square in a
  /// rounded tag); wins over [icon].
  final String? avatar;

  /// Fluent's `appearance`: which of its faces it wears.
  final Fluent2TagAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2TagSize size;

  /// Fluent's `shape`: its corners.
  final Fluent2TagShape shape;

  /// Removes the tag; null draws no dismiss mark.
  final VoidCallback? onDeleted;

  /// False draws the disabled face (a dismissible tag goes inert).
  final bool enabled;

  /// What a screen reader says for the dismiss; null says "[label],
  /// remove".
  final String? deleteLabel;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final layers = [style, t.tagTheme];
    final radius = _tagCorner(
      t,
      shape,
      size,
      Fluent2Style.first(layers, (s) => s.shape, const {}),
    );
    Widget face(Fluent2Press press) {
      final look = Fluent2StyleOf(layers, _statesOf(press));
      return Fluent2Eased<Fluent2TagFace>(
        value: _restyled(Fluent2TagFace.of(t, appearance, press), look),
        lerp: Fluent2TagFace.lerp,
        builder: (context, f) {
          final dismissing = onDeleted != null;
          return Container(
            constraints: BoxConstraints(minHeight: size.height),
            decoration: BoxDecoration(
              color: f.fill,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: f.stroke,
                width: look.side?.width ?? Fluent2Stroke.thin,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: _TagContent(
                    label: label,
                    secondary: size == Fluent2TagSize.medium ? secondary : null,
                    icon: icon,
                    avatar: avatar,
                    size: size,
                    shape: shape,
                    face: f,
                    endRoom: dismissing ? 0 : size.side,
                  ),
                ),
                if (dismissing)
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: size.glyphGap,
                      end: size.side,
                    ),
                    child: Icon(
                      _dismissGlyph(size),
                      size: size.glyph,
                      color: Fluent2TagFace.dismissOf(t, f, press),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    final dismiss = onDeleted;
    if (dismiss == null) {
      return Semantics(
        label: label + (secondary == null ? '' : ', $secondary'),
        enabled: enabled ? null : false,
        excludeSemantics: true,
        child: face(enabled ? Fluent2Press.rest : Fluent2Press.disabled),
      );
    }
    return Fluent2HitSlop(
      child: Fluent2Pressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: enabled ? dismiss : null,
        label: deleteLabel ?? '$label, remove',
        radius: radius,
        builder: (context, states) => face(states.press),
      ),
    );
  }
}

// A tag's corner: a circular tag's pill; a rounded one takes the style's
// or the tag theme's outline, else Fluent's medium corner, as a corner radius no more than half its height.
double _tagCorner(
  Fluent2ThemeData t,
  Fluent2TagShape shape,
  Fluent2TagSize size,
  OutlinedBorder? styled,
) => shape == Fluent2TagShape.circular
    ? size.height / 2
    : fluent2CornerOf(
        styled,
        size.height,
        Fluent2Radius.medium,
      ).clamp(0, size.height / 2).toDouble();

Set<WidgetState> _statesOf(Fluent2Press press, {bool selected = false}) => {
  if (press == Fluent2Press.disabled) WidgetState.disabled,
  if (press == Fluent2Press.hover) WidgetState.hovered,
  if (press == Fluent2Press.pressed) WidgetState.pressed,
  if (selected) WidgetState.selected,
};

// [f] with the style's colours over Fluent's.
Fluent2TagFace _restyled(Fluent2TagFace f, Fluent2StyleOf look) {
  final ink = look.foreground;
  return Fluent2TagFace(
    fill: look.fill ?? f.fill,
    stroke: look.side?.color ?? look.edge ?? f.stroke,
    ink: ink ?? f.ink,
    glyph: ink ?? f.glyph,
    divider: f.divider,
  );
}

IconData _dismissGlyph(Fluent2TagSize size) => switch (size) {
  Fluent2TagSize.medium => Fluent2Icons.dismiss,
  Fluent2TagSize.small => Fluent2Icons.dismiss16,
  Fluent2TagSize.extraSmall => Fluent2Icons.dismiss12,
};

/// Fluent 2's InteractionTag: a tag that acts. Its primary part ([onTap])
/// opens what it names, or, with [selected] set, toggles the tag in and
/// out of a choice (the brand fill while chosen: a filter, a topic, a
/// day); a [onDismiss] adds its secondary part past a hairline, the
/// dismiss mark as its own button. Both parts take the 44 touch target
/// where there is room. Null [onTap] and [onDismiss] draw it disabled.
/// Read as a button named [label], selected or not, and "Remove [label]".
///
/// ```dart
/// Fluent2InteractionTag('Design', selected: true, onPressed: () => toggle('design'))
/// ```
class Fluent2InteractionTag extends StatelessWidget {
  /// An interaction tag showing [label], pressed as one control.
  const Fluent2InteractionTag(
    this.label, {
    required this.onPressed,
    this.selected,
    this.onDeleted,
    this.secondary,
    this.icon,
    this.avatar,
    this.appearance = Fluent2TagAppearance.filled,
    this.size = Fluent2TagSize.medium,
    this.shape = Fluent2TagShape.rounded,
    this.deleteLabel,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// This chip's own look over the chip theme: `fill`, `edge`, `side`,
  /// `foreground` and `shape` (its corner radius, at most half its height)
  /// in its states (selected while chosen).
  final Fluent2Style? style;

  /// The tag's words.
  final String label;

  /// What a press on the primary part does; null makes it inert.
  final VoidCallback? onPressed;

  /// Set for a choosable tag: chosen (the brand fill) or not; null is a
  /// plain act.
  final bool? selected;

  /// What the secondary part does (remove the tag); null draws none.
  final VoidCallback? onDeleted;

  /// A second line under the label (the medium size only).
  final String? secondary;

  /// The glyph before [label]; null shows none.
  final IconData? icon;

  /// A person's name: their avatar before the words.
  final String? avatar;

  /// Fluent's `appearance`: which of its faces it wears.
  final Fluent2TagAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2TagSize size;

  /// Fluent's `shape`: its corners.
  final Fluent2TagShape shape;

  /// What a screen reader says for the secondary part; null says "Remove
  /// [label]".
  final String? deleteLabel;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final on = selected ?? false;
    final layers = [style, t.tagTheme];
    final radius = _tagCorner(
      t,
      shape,
      size,
      Fluent2Style.first(layers, (s) => s.shape, const {}),
    );
    final r = Radius.circular(radius);
    final rimWidth =
        Fluent2Style.first(layers, (s) => s.side, const {})?.width ??
        Fluent2Stroke.thin;
    final dismiss = onDeleted;
    final live = onPressed != null || dismiss != null;
    // With a dismiss the two parts share one face height (the words' line
    // at the text scale inside the strokes, at least the size's), each in
    // its own touch target, the faces pushed together inside them: stretched
    // to a 48 target they would draw 48 tall with a gap between.
    final scaler = MediaQuery.textScalerOf(context);
    double line(TextStyle s) =>
        scaler.scale(s.fontSize ?? 14) * (s.height ?? 1);
    final faceHeight = math.max(
      size.height,
      2 * rimWidth +
          (size == Fluent2TagSize.medium && secondary != null
              ? line(t.caption1) + Fluent2Stroke.thin + line(t.caption2)
              : line(size == Fluent2TagSize.medium ? t.body1 : t.caption1)),
    );
    final primary = Fluent2Pressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      label: label + (secondary == null ? '' : ', $secondary'),
      selected: selected,
      radius: radius,
      faceAlignment: dismiss == null
          ? AlignmentDirectional.center
          : AlignmentDirectional.centerEnd,
      builder: (context, states) {
        final press = states.press;
        final p = live && press == Fluent2Press.disabled && onPressed == null
            ? Fluent2Press.rest
            : press;
        final shown = live ? p : Fluent2Press.disabled;
        return Fluent2Eased<Fluent2TagFace>(
          value: _restyled(
            Fluent2TagFace.of(t, appearance, shown, selected: on),
            Fluent2StyleOf(layers, _statesOf(shown, selected: on)),
          ),
          lerp: Fluent2TagFace.lerp,
          builder: (context, f) {
            final edge = BorderSide(color: f.stroke, width: rimWidth);
            return Container(
              constraints: BoxConstraints(
                minHeight: dismiss == null ? size.height : faceHeight,
              ),
              decoration: BoxDecoration(
                color: f.fill,
                // Square, a stroke on three sides takes no radius at all
                // (Flutter refuses a zero one).
                borderRadius: dismiss == null
                    ? BorderRadius.all(r)
                    : r == Radius.zero
                    ? null
                    : BorderRadiusDirectional.horizontal(start: r)
                          .resolve(Directionality.of(context)),
                border: dismiss == null
                    ? Border.all(color: f.stroke, width: rimWidth)
                    : BorderDirectional(start: edge, top: edge, bottom: edge),
              ),
              child: _TagContent(
                label: label,
                secondary: size == Fluent2TagSize.medium ? secondary : null,
                icon: icon,
                avatar: avatar,
                size: size,
                shape: shape,
                face: f,
                endRoom: dismiss == null
                    ? size.side
                    : size == Fluent2TagSize.medium
                    ? Fluent2Spacing.s
                    : Fluent2Spacing.sNudge,
              ),
            );
          },
        );
      },
    );
    // A tag keeps its own width at its start: a column that stretches its
    // children never runs it across.
    Widget own(Widget tag) => Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: tag,
    );
    if (dismiss == null) return own(Fluent2HitSlop(child: primary));
    final secondaryPart = Fluent2Pressable(
      onPressed: dismiss,
      label: deleteLabel ?? Fluent2Localizations.of(context).remove(label),
      radius: radius,
      faceAlignment: AlignmentDirectional.centerStart,
      builder: (context, states) {
        final press = states.press;
        return Fluent2Eased<Fluent2TagFace>(
          value: _restyled(
            Fluent2TagFace.of(t, appearance, press, selected: on),
            Fluent2StyleOf(layers, _statesOf(press, selected: on)),
          ),
          lerp: Fluent2TagFace.lerp,
          builder: (context, f) {
            final ink =
                press == Fluent2Press.disabled || press == Fluent2Press.rest
                ? f.glyph
                : on
                ? t.colors.neutralForegroundOnBrand
                : appearance == Fluent2TagAppearance.brand
                ? press.pick(
                    f.glyph,
                    t.colors.compoundBrandForeground1Hover,
                    t.colors.compoundBrandForeground1Pressed,
                  )
                : press.pick(
                    f.glyph,
                    t.colors.neutralForeground2BrandHover,
                    t.colors.neutralForeground2BrandPressed,
                  );
            // Fluent's divider is the dismiss part's start border; a rounded
            // box takes one stroke colour, so it is drawn as its own line.
            return Container(
              constraints: BoxConstraints.tightFor(height: faceHeight),
              decoration: BoxDecoration(
                color: f.fill,
                borderRadius: r == Radius.zero
                    ? null
                    : BorderRadiusDirectional.horizontal(end: r)
                          .resolve(Directionality.of(context)),
                border: BorderDirectional(
                  end: BorderSide(color: f.stroke, width: rimWidth),
                  top: BorderSide(color: f.stroke, width: rimWidth),
                  bottom: BorderSide(color: f.stroke, width: rimWidth),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 1, child: ColoredBox(color: f.divider)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size == Fluent2TagSize.small ? 3 : 5,
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Icon(
                        _dismissGlyph(size),
                        size: size.glyph,
                        color: ink,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    return own(
      Fluent2HitSlop(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: primary),
            secondaryPart,
          ],
        ),
      ),
    );
  }
}

/// One tag of a [Fluent2TagGroup]: its [value], its [label] and what leads
/// it ([icon] or a person's [avatar]); [dismissible] false keeps it in a
/// group that removes the others.
///
/// ```dart
/// Fluent2TagItem('docs', 'Documents', icon: Fluent2Icons.document)
/// ```
@immutable
class Fluent2TagItem<T> {
  /// A tag for [value], labelled [label].
  const Fluent2TagItem(
    this.value,
    this.label, {
    this.secondary,
    this.icon,
    this.avatar,
    this.dismissible = true,
    this.enabled = true,
  });

  /// The value the tag stands for.
  final T value;

  /// The tag's words.
  final String label;

  /// A quieter word after [label]; null shows none.
  final String? secondary;

  /// The glyph before [label]; null shows none.
  final IconData? icon;

  /// A person's name, whose avatar leads the tag; null shows none.
  final String? avatar;

  /// Whether the tag can be removed from its group.
  final bool dismissible;

  /// False puts it out of use: drawn disabled and deaf to input.
  final bool enabled;
}

/// Fluent 2's TagGroup: [items] in one wrapping row at the size's gap (8,
/// 6, 4), sharing a size, an appearance and a shape. With [selected] and
/// [onSelectedChanged] each is a choosable [Fluent2InteractionTag] (one at
/// a time unless [multiple]): the filters over a list, the topics of a
/// post. With [onDismiss] each is removable (the recipients picked, the
/// labels set). Neither: static [Fluent2Tag]s. Null [onSelectedChanged]
/// draws a choosable group inert. Read as a group named [label].
///
/// ```dart
/// Fluent2TagGroup<String>(items: const [Fluent2TagItem('all', 'All'), Fluent2TagItem('docs', 'Documents')], selected: {'all'}, onSelectionChanged: (v) => setState(() => picked = v))
/// ```
class Fluent2TagGroup<T> extends StatelessWidget {
  /// A group of [items].
  const Fluent2TagGroup({
    required this.items,
    this.selected,
    this.onSelectionChanged,
    this.multiple = false,
    this.onDeleted,
    this.appearance = Fluent2TagAppearance.filled,
    this.size = Fluent2TagSize.medium,
    this.shape = Fluent2TagShape.rounded,
    this.label,
    super.key,
  });

  /// The tags, in order.
  final List<Fluent2TagItem<T>> items;

  /// The chosen values; null makes the tags not choosable.
  final Set<T>? selected;

  /// Told the new choice; null draws a choosable group inert.
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// Whether more than one may be chosen (else choosing one drops the
  /// other).
  final bool multiple;

  /// Told which tag to remove; null draws no dismiss marks.
  final ValueChanged<T>? onDeleted;

  /// Fluent's `appearance`: which of its faces it wears.
  final Fluent2TagAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2TagSize size;

  /// Fluent's `shape`: its corners.
  final Fluent2TagShape shape;

  /// What a screen reader calls the group.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final picked = selected;
    final change = onSelectionChanged;
    final dismiss = onDeleted;
    final tags = <Widget>[
      for (final item in items)
        if (picked != null)
          Fluent2InteractionTag(
            item.label,
            key: ValueKey<T>(item.value),
            secondary: item.secondary,
            icon: item.icon,
            avatar: item.avatar,
            appearance: appearance,
            size: size,
            shape: shape,
            selected: picked.contains(item.value),
            onPressed: change == null || !item.enabled
                ? null
                : () {
                    final on = picked.contains(item.value);
                    final next = multiple ? {...picked} : <T>{};
                    if (on) {
                      next.remove(item.value);
                    } else {
                      next.add(item.value);
                    }
                    change(next);
                  },
            onDeleted: dismiss == null || !item.dismissible || !item.enabled
                ? null
                : () => dismiss(item.value),
          )
        else
          Fluent2Tag(
            item.label,
            key: ValueKey<T>(item.value),
            secondary: item.secondary,
            icon: item.icon,
            avatar: item.avatar,
            appearance: appearance,
            size: size,
            shape: shape,
            enabled: item.enabled,
            onDeleted: dismiss == null || !item.dismissible
                ? null
                : () => dismiss(item.value),
          ),
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: Wrap(
        spacing: size.groupGap,
        runSpacing: size.groupGap,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: tags,
      ),
    );
  }
}
