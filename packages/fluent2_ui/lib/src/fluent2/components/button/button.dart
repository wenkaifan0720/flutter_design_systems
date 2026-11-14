import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../icons.dart';
import '../../internal/cap_label.dart';
import '../../internal/hit_slop.dart';
import '../../internal/icon_fill.dart';
import '../../internal/measure.dart';
import '../../internal/menu_surface.dart';
import '../../internal/well.dart';
import '../../localizations.dart';
import '../../styled.dart';
import '../../theme.dart';
import '../menu/menu.dart';
import '../pressable/pressable.dart';

/// Which side of the words a part's glyph stands on, Fluent's
/// `iconPosition`: [before] (the default) or [after] (a "Next" that points
/// on).
enum Fluent2IconPosition {
  /// The glyph before the label.
  before,

  /// The glyph after the label.
  after,
}

/// How loud a [Fluent2Button] is, Fluent's `appearance`: [secondary] the
/// default (the surface with its stroke), [primary] the brand fill (the
/// one act a view exists for), [outline] the stroke alone, [subtle] no
/// fill until the pointer is over it, [transparent] never a fill, its
/// words in the brand under the pointer.
enum Fluent2ButtonAppearance {
  /// The surface with its stroke, the default.
  secondary,

  /// The brand fill, for the one act a view exists for.
  primary,

  /// The stroke alone, no fill.
  outline,

  /// No fill until the pointer is over it.
  subtle,

  /// Never a fill; its words in the brand under the pointer.
  transparent,
}

/// A button's size, Fluent's `size`: [small] 24 tall (caption1), [medium]
/// 32 (body1Strong), [large] 40 (subtitle2's 16/22).
enum Fluent2ButtonSize {
  /// The small size.
  small,

  /// The medium size.
  medium,

  /// The large size.
  large,
}

/// A button's corners, Fluent's `shape`: [rounded] at 4, [circular] a
/// pill, [square] none.
enum Fluent2ButtonShape {
  /// Rounded corners.
  rounded,

  /// A pill, or a disc when icon-only.
  circular,

  /// Square corners.
  square,
}

/// The faces a button wears in each state: Fluent's button styles, read
/// from `useButtonStyles` per appearance. Plumbing of the buttons.
@immutable
final class Fluent2ButtonFace {
  /// A face of [fill], [stroke], [ink] and [glyph].
  const Fluent2ButtonFace({
    required this.fill,
    required this.stroke,
    required this.ink,
    required this.glyph,
  });

  /// The face's fill.
  final Color fill;

  /// The face's stroke.
  final Color stroke;

  /// The words' ink.
  final Color ink;

  /// The glyph's ink.
  final Color glyph;

  /// The face a share [t] of the way from [a] to [b]: what a button wears
  /// while it eases from one state to the next.
  static Fluent2ButtonFace lerp(
    Fluent2ButtonFace a,
    Fluent2ButtonFace b,
    double t,
  ) => Fluent2ButtonFace(
    fill: Color.lerp(a.fill, b.fill, t)!,
    stroke: Color.lerp(a.stroke, b.stroke, t)!,
    ink: Color.lerp(a.ink, b.ink, t)!,
    glyph: Color.lerp(a.glyph, b.glyph, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is Fluent2ButtonFace &&
      other.fill == fill &&
      other.stroke == stroke &&
      other.ink == ink &&
      other.glyph == glyph;

  @override
  int get hashCode => Object.hash(fill, stroke, ink, glyph);

  /// The face of [appearance] in [press], checked or not (a toggle).
  static Fluent2ButtonFace of(
    Fluent2ThemeData t,
    Fluent2ButtonAppearance appearance,
    Fluent2Press press, {
    bool checked = false,
  }) {
    final c = t.colors;
    if (press == Fluent2Press.disabled) {
      final quiet =
          appearance == Fluent2ButtonAppearance.subtle ||
          appearance == Fluent2ButtonAppearance.transparent;
      // Fluent's disabled greys laid as steps over the ground, so a
      // disabled primary keeps its shape on the brand-tinted page.
      return Fluent2ButtonFace(
        fill: quiet ? c.transparentBackground : fluent2WellDisabled(t),
        stroke: quiet || appearance == Fluent2ButtonAppearance.primary
            ? c.transparentStroke
            : fluent2Step(t, c.neutralStrokeDisabled),
        ink: c.neutralForegroundDisabled,
        glyph: c.neutralForegroundDisabled,
      );
    }
    switch (appearance) {
      case Fluent2ButtonAppearance.secondary:
        final fill = checked
            ? press.pick(
                c.neutralBackground1Selected,
                c.neutralBackground1Hover,
                c.neutralBackground1Pressed,
              )
            : press.pick(
                c.neutralBackground1,
                c.neutralBackground1Hover,
                c.neutralBackground1Pressed,
              );
        final ink = checked
            ? c.neutralForeground1Selected
            : press.pick(
                c.neutralForeground1,
                c.neutralForeground1Hover,
                c.neutralForeground1Pressed,
              );
        return Fluent2ButtonFace(
          fill: fill,
          stroke: press.pick(
            c.neutralStroke1,
            c.neutralStroke1Hover,
            c.neutralStroke1Pressed,
          ),
          ink: ink,
          glyph: ink,
        );
      case Fluent2ButtonAppearance.primary:
        return Fluent2ButtonFace(
          fill: checked
              ? press.pick(
                  c.brandBackgroundSelected,
                  c.brandBackgroundHover,
                  c.brandBackgroundPressed,
                )
              : press.pick(
                  c.brandBackground,
                  c.brandBackgroundHover,
                  c.brandBackgroundPressed,
                ),
          stroke: c.transparentStroke,
          ink: c.neutralForegroundOnBrand,
          glyph: c.neutralForegroundOnBrand,
        );
      case Fluent2ButtonAppearance.outline:
        final ink = press.pick(
          c.neutralForeground1,
          c.neutralForeground1Hover,
          c.neutralForeground1Pressed,
        );
        return Fluent2ButtonFace(
          fill: checked
              ? c.transparentBackgroundSelected
              : press.pick(
                  c.transparentBackground,
                  c.transparentBackgroundHover,
                  c.transparentBackgroundPressed,
                ),
          stroke: press.pick(
            c.neutralStroke1,
            c.neutralStroke1Hover,
            c.neutralStroke1Pressed,
          ),
          ink: ink,
          glyph: ink,
        );
      case Fluent2ButtonAppearance.subtle:
        return Fluent2ButtonFace(
          fill: checked
              ? c.subtleBackgroundSelected
              : press.pick(
                  c.subtleBackground,
                  c.subtleBackgroundHover,
                  c.subtleBackgroundPressed,
                ),
          stroke: c.transparentStroke,
          ink: checked
              ? c.neutralForeground2Selected
              : press.pick(
                  c.neutralForeground2,
                  c.neutralForeground2Hover,
                  c.neutralForeground2Pressed,
                ),
          glyph: checked
              ? c.neutralForeground2BrandSelected
              : press.pick(
                  c.neutralForeground2,
                  c.neutralForeground2BrandHover,
                  c.neutralForeground2BrandPressed,
                ),
        );
      case Fluent2ButtonAppearance.transparent:
        final ink = checked
            ? c.neutralForeground2BrandSelected
            : press.pick(
                c.neutralForeground2,
                c.neutralForeground2BrandHover,
                c.neutralForeground2BrandPressed,
              );
        return Fluent2ButtonFace(
          fill: c.transparentBackground,
          stroke: c.transparentStroke,
          ink: ink,
          glyph: ink,
        );
    }
  }
}

/// The geometry of a button size: its height, its room at the sides, its
/// least width with words, its glyph and the gap before the words, its
/// type.
@immutable
final class Fluent2ButtonMetrics {
  const Fluent2ButtonMetrics._(
    this.height,
    this.side,
    this.minWidth,
    this.glyph,
    this.gap,
  );

  /// The button's height.
  final double height;

  /// The room at either side of its words.
  final double side;

  /// The least width of a button with words.
  final double minWidth;

  /// The glyph's size.
  final double glyph;

  /// The gap between the glyph and the words.
  final double gap;

  /// The room from the button's outer edge to its content at a side:
  /// Fluent's padding inside its 1 stroke (CSS's border box), where
  /// [Fluent2ButtonBox] draws the stroke without taking room for it.
  double get sideRoom => side + Fluent2Stroke.thin;

  /// The room from the outer edge to the glyph of a glyph-only button
  /// (Fluent's 1, 5, 7 of padding inside the stroke): the glyph centred.
  double get glyphRoom => (height - glyph) / 2;

  /// The down chevron a menu button ends in, Fluent's `menuIcon`: 12 on
  /// a small or medium button, 16 on a large, 4 after the words.
  double get chevron => height > 32 ? 16 : 12;

  /// Fluent's three: small 24 tall, 8 at the sides, at least 64 wide, a
  /// 20 glyph 4 before the words; medium 32, 12, 96, 20, 6; large 40, 16,
  /// 96, 24, 6.
  static Fluent2ButtonMetrics of(Fluent2ButtonSize size) => switch (size) {
    Fluent2ButtonSize.small => const Fluent2ButtonMetrics._(24, 8, 64, 20, 4),
    Fluent2ButtonSize.medium => const Fluent2ButtonMetrics._(32, 12, 96, 20, 6),
    Fluent2ButtonSize.large => const Fluent2ButtonMetrics._(40, 16, 96, 24, 6),
  };

  /// The words' type at [size]: caption1 on a small button, body1Strong on
  /// a medium, 16/22 semibold on a large.
  static TextStyle typeOf(Fluent2ThemeData t, Fluent2ButtonSize size) =>
      switch (size) {
        Fluent2ButtonSize.small => t.caption1,
        Fluent2ButtonSize.medium => t.body1Strong,
        Fluent2ButtonSize.large => t.subtitle2,
      };

  /// The corner of [shape] at [size].
  static double radiusOf(Fluent2ButtonShape shape, double height) =>
      switch (shape) {
        Fluent2ButtonShape.rounded => Fluent2Radius.medium,
        Fluent2ButtonShape.circular => height / 2,
        Fluent2ButtonShape.square => Fluent2Radius.none,
      };
}

/// The box every button draws: the face's fill inside its stroke at the
/// shape's corner (or along a styled [shape]), [child] centred in it.
/// Plumbing of the buttons.
class Fluent2ButtonBox extends StatelessWidget {
  /// A button's box in [face], [child] centred in it.
  const Fluent2ButtonBox({
    required this.face,
    required this.radius,
    required this.height,
    required this.child,
    this.minWidth = 0,
    this.padding = EdgeInsets.zero,
    this.width,
    this.border,
    this.side,
    this.shape,
    super.key,
  });

  /// The fill, stroke and inks it draws in.
  final Fluent2ButtonFace face;

  /// The corners.
  final BorderRadiusGeometry radius;

  /// The box's height.
  final double height;

  /// The narrowest the box stands.
  final double minWidth;

  /// A fixed width; null sizes to [child], at least [minWidth].
  final double? width;

  /// The room from the outer edge to [child]: the stroke takes none.
  final EdgeInsetsGeometry padding;

  /// The stroke at chosen sides (a split button's half); null is [side] all
  /// round.
  final BoxBorder? border;

  /// The stroke all round; null is 1 of the face's stroke.
  final BorderSide? side;

  /// A styled outline; it wins over [radius]. Null draws Fluent's corner.
  final OutlinedBorder? shape;

  /// The box's content: its glyph and words.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rim = side ?? BorderSide(color: face.stroke);
    final drawn = shape;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height, minWidth: minWidth),
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: drawn != null && border == null
              ? ShapeDecoration(
                  color: face.fill,
                  shape: drawn.copyWith(side: rim),
                )
              : BoxDecoration(
                  color: face.fill,
                  // Square, no radius at all: Flutter paints a stroke on some
                  // sides only with a radius of null, never of zero.
                  borderRadius: radius == BorderRadius.zero ? null : radius,
                  border:
                      border ?? Border.all(color: rim.color, width: rim.width),
                ),
          child: Padding(
            padding: padding,
            child: Center(
              widthFactor: width == null ? 1 : null,
              heightFactor: 1,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A button appearance's component theme on [t].
Fluent2Style fluent2ButtonThemeOf(
  Fluent2ThemeData t,
  Fluent2ButtonAppearance appearance,
) => switch (appearance) {
  Fluent2ButtonAppearance.primary => t.primaryButtonTheme,
  Fluent2ButtonAppearance.secondary => t.secondaryButtonTheme,
  Fluent2ButtonAppearance.outline => t.outlineButtonTheme,
  Fluent2ButtonAppearance.subtle => t.subtleButtonTheme,
  Fluent2ButtonAppearance.transparent => t.transparentButtonTheme,
};

/// A button's look in its states, slot by slot: its own `style:`, then the
/// icon button's theme (for one) and its appearance's theme, then
/// Fluent's own, moved by the theme's `density`. Plumbing of the buttons.
@immutable
final class Fluent2ButtonLook {
  /// The look of a button of [appearance] at [size].
  const Fluent2ButtonLook(
    this.t, {
    required this.appearance,
    required this.size,
    this.style,
    this.shape,
    this.icon = false,
    this.touch = false,
  });

  /// The theme it reads.
  final Fluent2ThemeData t;

  /// The button's appearance.
  final Fluent2ButtonAppearance appearance;

  /// The button's size.
  final Fluent2ButtonSize size;

  /// The button's own style.
  final Fluent2Style? style;

  /// The button's own corners; null leaves them to the style and the
  /// theme, then Fluent's rounded.
  final Fluent2ButtonShape? shape;

  /// An icon button, which reads the icon button theme first.
  final bool icon;

  /// Under a finger ([Fluent2Layout.padded]): the face stands the whole
  /// 48 target, as a field's and a strip's do, so controls that
  /// share a row show one top and one bottom.
  final bool touch;

  /// Fluent's measures at [size].
  Fluent2ButtonMetrics get metrics => Fluent2ButtonMetrics.of(size);

  List<Fluent2Style?> get _themes => [
    if (icon) t.iconButtonTheme,
    fluent2ButtonThemeOf(t, appearance),
  ];

  /// Every layer, first wins.
  List<Fluent2Style?> get layers => [style, ..._themes];

  /// The styled outline in [states]: the style's, else (no [shape] given)
  /// the themes'. Null draws Fluent's
  /// corner, [radius].
  OutlinedBorder? outline(Set<WidgetState> states) {
    final own = Fluent2Style.first([style], (s) => s.shape, states);
    if (own != null || shape != null) return own;
    return Fluent2Style.first(_themes, (s) => s.shape, states);
  }

  /// [outline] for any states, as the focus ring reads it.
  WidgetStateProperty<OutlinedBorder?> get outlines =>
      WidgetStateProperty.resolveWith(outline);

  /// The face's height at rest: the style's least height, else Fluent's at
  /// the theme's density, never under 20 (Fluent's smallest control, the
  /// extra-small tag: a small button two steps in would stand 16, its
  /// strokes on its words' line); under a finger at least the 48 target,
  /// whatever the size, the density or the style.
  double get height {
    final own =
        Fluent2Style.first(layers, (s) => s.minimumSize, const {})?.height ??
        t.density.height(metrics.height, least: 20);
    return touch ? math.max(own, Fluent2Layout.touchHitTarget) : own;
  }

  /// Fluent's corner for [shape] at [height].
  double get radius => Fluent2ButtonMetrics.radiusOf(
    shape ?? Fluent2ButtonShape.rounded,
    height,
  );

  /// The room at each side at the theme's density.
  double get sideRoom =>
      math.max(Fluent2Spacing.xs, metrics.sideRoom + t.density.paddingDelta);

  /// The face in [states] ([checked] for a toggled button), the style's
  /// fill, foreground, edge and overlay over Fluent's.
  Fluent2ButtonFace face(Set<WidgetState> states, {bool checked = false}) {
    final own = Fluent2ButtonFace.of(
      t,
      appearance,
      states.press,
      checked: checked,
    );
    final look = Fluent2StyleOf(layers, states);
    final wash = Fluent2Style.first(layers, (s) => s.overlay, states);
    final fill = look.fill ?? own.fill;
    final ink = look.foreground;
    return Fluent2ButtonFace(
      fill: wash == null ? fill : Color.alphaBlend(wash, fill),
      stroke: look.edge ?? own.stroke,
      ink: ink ?? own.ink,
      glyph: ink ?? own.glyph,
    );
  }

  /// The rim in [states] on [face]: the style's side, else the face's
  /// stroke at the theme's regular width.
  BorderSide side(Set<WidgetState> states, Fluent2ButtonFace face) =>
      Fluent2Style.first(layers, (s) => s.side, states) ??
      BorderSide(color: face.stroke, width: Fluent2Stroke.thin);

  /// The least width in [states]: the style's, else Fluent's [fallback].
  double minWidth(Set<WidgetState> states, double fallback) =>
      Fluent2Style.first(layers, (s) => s.minimumSize, states)?.width ??
      fallback;

  /// The room inside in [states]: the style's, else [fallback].
  EdgeInsetsGeometry padding(
    Set<WidgetState> states,
    EdgeInsetsGeometry fallback,
  ) => Fluent2Style.first(layers, (s) => s.padding, states) ?? fallback;

  /// The words' type in [ink], the style's merged over Fluent's.
  TextStyle type(Set<WidgetState> states, Color ink) =>
      Fluent2ButtonMetrics.typeOf(
        t,
        size,
      ).merge(Fluent2Style.first(layers, (s) => s.textStyle, states)).c(ink);

  /// A glyph's size in [states].
  double glyph(Set<WidgetState> states) =>
      Fluent2Style.first(layers, (s) => s.iconSize, states) ?? metrics.glyph;

  /// The box for [states], [child] inside: the styled outline eases to each
  /// new one.
  Widget box(
    Set<WidgetState> states, {
    required Fluent2ButtonFace face,
    required Widget child,
    double? minWidth,
    double? width,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) => AnimatedFluent2Shape(
    shape: outline(states),
    builder: (context, drawn) => Fluent2ButtonBox(
      face: face,
      radius: BorderRadius.circular(radius),
      shape: drawn,
      side: side(states, face),
      height: height,
      minWidth: this.minWidth(states, minWidth ?? 0),
      width: width,
      padding: this.padding(states, padding),
      child: child,
    ),
  );
}

/// Where a button fills the width it is given: the acts of a phone's sheet
/// foot, a narrow dialog's stacked acts. Plumbing of those surfaces; a
/// page asks a button to fill with its `expand`.
class Fluent2ActsFill extends InheritedWidget {
  /// Buttons under [child] fill their cells.
  const Fluent2ActsFill({super.key, required super.child});

  /// Whether a button at [context] fills its cell.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Fluent2ActsFill>() != null;

  @override
  bool updateShouldNotify(Fluent2ActsFill oldWidget) => false;
}

/// [button] at the width it shows wherever its parent would stretch it (a
/// column that stretches its children, a cell of a row): its face at the
/// start and centred on the height, the rest of the room empty and not
/// pressed (the user's review, 11-11: a control spanning a 1440 page reads
/// as a banner). Under [Fluent2ActsFill] it fills, as before.
Widget fluent2OwnWidth(BuildContext context, Widget button) =>
    Fluent2ActsFill.of(context) ? button : _OwnWidth(child: button);

class _OwnWidth extends Align {
  const _OwnWidth({required super.child})
    : super(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
      );

  @override
  RenderPositionedBox createRenderObject(BuildContext context) =>
      _RenderOwnWidth(
        alignment: alignment,
        widthFactor: widthFactor,
        heightFactor: heightFactor,
        textDirection: Directionality.maybeOf(context),
      );
}

/// The button's hit slop reaches past its face (the 44 or 48 target), so a
/// hit is offered to it even outside this box.
class _RenderOwnWidth extends RenderPositionedBox {
  _RenderOwnWidth({
    super.alignment,
    super.widthFactor,
    super.heightFactor,
    super.textDirection,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// Fluent 2's Button: [label] in the size's type, an optional [icon]
/// before it (after it with [iconAfter]), on the [appearance]'s face at the
/// [shape]'s corner, stepping through its rest, hover and pressed colours.
/// [expand] stretches it across its parent (a sheet's one act). Read as a
/// button named [label]; null [onTap] draws it disabled. Use one
/// [Fluent2ButtonAppearance.primary] per view.
///
/// [style] restyles it slot by slot (fill, foreground, edge, overlay, side,
/// shape, padding, minimumSize, textStyle, iconSize) over its appearance's
/// component theme (`Fluent2ThemeData.primaryButtonTheme` and its
/// siblings), then Fluent's own, moved by the theme's `density`.
///
/// ```dart
/// Fluent2Button('Save', appearance: Fluent2ButtonAppearance.primary, icon: Fluent2Icons.save, onPressed: save)
/// ```
class Fluent2Button extends StatelessWidget {
  /// A button labelled [label] that calls [onPressed].
  const Fluent2Button(
    this.label, {
    required this.onPressed,
    this.appearance = Fluent2ButtonAppearance.secondary,
    this.size = Fluent2ButtonSize.medium,
    this.shape,
    this.icon,
    this.iconPosition = Fluent2IconPosition.before,
    this.expand = false,
    this.semanticLabel,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The words on its face.
  final String label;

  /// Called when it is pressed; null puts it out of use.
  final VoidCallback? onPressed;

  /// Fluent's `appearance`: which of its faces it wears.
  final Fluent2ButtonAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2ButtonSize size;

  /// Fluent's corners; null leaves them to [style], the theme and its
  /// shape scale, then [Fluent2ButtonShape.rounded].
  final Fluent2ButtonShape? shape;

  /// A glyph beside the words, on the side [iconPosition] says.
  final IconData? icon;

  /// Which side of the words [icon] stands on.
  final Fluent2IconPosition iconPosition;

  /// Stretch across the parent's width.
  final bool expand;

  /// What a screen reader says; null says [label].
  final String? semanticLabel;

  /// This button's own look, slot by slot, over its theme's.
  final Fluent2Style? style;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final look = Fluent2ButtonLook(
      context.fluent2Theme,
      touch: Fluent2Layout.padded(context),
      appearance: appearance,
      size: size,
      style: style,
      shape: shape,
    );
    final m = look.metrics;
    return fluent2OwnWidth(
      context,
      Fluent2HitSlop(
        child: Fluent2Pressable(
          focusNode: focusNode,
          autofocus: autofocus,
          onPressed: onPressed,
          label: semanticLabel ?? label,
          radius: look.radius,
          shape: look.outlines,
          builder: (context, states) {
            return Fluent2Eased<Fluent2ButtonFace>(
              value: look.face(states),
              lerp: Fluent2ButtonFace.lerp,
              builder: (context, face) {
                final words = fluent2CapCentred(
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: look.type(states, face.ink),
                  ),
                );
                final glyph = icon == null
                    ? null
                    : Icon(
                        fluent2FillOn(icon!, states),
                        size: look.glyph(states),
                        color: face.glyph,
                      );
                return look.box(
                  states,
                  face: face,
                  minWidth: m.minWidth,
                  // Filling, from 600 it stops at 320 (a cell's width still
                  // holds it).
                  width: expand
                      ? (fluent2Roomy(context)
                            ? fluent2ControlMax
                            : double.infinity)
                      : null,
                  padding: EdgeInsets.symmetric(horizontal: look.sideRoom),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: m.gap,
                    children: [
                      if (iconPosition == Fluent2IconPosition.before) ?glyph,
                      Flexible(child: words),
                      if (iconPosition == Fluent2IconPosition.after) ?glyph,
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Fluent 2's icon-only Button: one glyph in a square of the size's height
/// (24, 32, 40), on the [appearance]'s face (subtle by default, as a
/// toolbar's and a bar's commands are), named by [label] for a screen
/// reader. [filled] is the glyph worn while [selected] (a toggled
/// command); its hit target reaches 44 where there is room. [style]
/// restyles it over `Fluent2ThemeData.iconButtonTheme`, then its
/// appearance's button theme and the theme's knobs.
///
/// ```dart
/// Fluent2IconButton(Fluent2Icons.moreHorizontal, label: 'More options', onPressed: openMenu)
/// ```
class Fluent2IconButton extends StatelessWidget {
  /// An icon-only button showing [icon], read as [semanticLabel].
  const Fluent2IconButton(
    this.icon, {
    required this.label,
    required this.onPressed,
    this.appearance = Fluent2ButtonAppearance.subtle,
    this.size = Fluent2ButtonSize.medium,
    this.shape,
    this.selected,
    this.filled,
    this.color,
    this.badge,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The glyph on its face.
  final IconData icon;

  /// What a screen reader says.
  final String label;

  /// Called when it is pressed; null puts it out of use.
  final VoidCallback? onPressed;

  /// Fluent's `appearance`: which of its faces it wears.
  final Fluent2ButtonAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2ButtonSize size;

  /// Fluent's corners; null leaves them to [style], the theme and its
  /// shape scale, then [Fluent2ButtonShape.rounded].
  final Fluent2ButtonShape? shape;

  /// This button's own look, slot by slot, over its theme's.
  final Fluent2Style? style;

  /// Set for a toggled command: on or off.
  final bool? selected;

  /// The glyph worn while [selected]; null wears [icon]'s filled twin.
  final IconData? filled;

  /// The glyph's colour, overriding the face's (a bar on a photograph).
  final Color? color;

  /// What rides the button's top end corner (a counter badge).
  final Widget? badge;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final look = Fluent2ButtonLook(
      context.fluent2Theme,
      touch: Fluent2Layout.padded(context),
      appearance: appearance,
      size: size,
      style: style,
      shape: shape,
      icon: true,
    );
    final on = selected ?? false;
    return fluent2OwnWidth(
      context,
      Fluent2HitSlop(
        child: Fluent2Pressable(
          focusNode: focusNode,
          autofocus: autofocus,
          onPressed: onPressed,
          label: label,
          toggled: selected,
          radius: look.radius,
          shape: look.outlines,
          builder: (context, states) {
            return Fluent2Eased<Fluent2ButtonFace>(
              value: look.face(states, checked: on),
              lerp: Fluent2ButtonFace.lerp,
              builder: (context, face) {
                final box = look.box(
                  states,
                  face: face,
                  width: look.minWidth(states, look.height),
                  child: Icon(
                    on
                        ? (filled ?? fluent2Filled(icon))
                        : fluent2FillOn(icon, states),
                    size: look.glyph(states),
                    color: color ?? face.glyph,
                  ),
                );
                final b = badge;
                if (b == null) return box;
                // The badge rides the face a pointer sees (32 at medium), its
                // corner by the glyph's, under a finger as with a pointer: the
                // 48 target round it is room, not face.
                final shown = Fluent2ButtonLook(
                  context.fluent2Theme,
                  appearance: appearance,
                  size: size,
                  style: style,
                  shape: shape,
                  icon: true,
                ).height;
                final room = math.max(0.0, (look.height - shown) / 2) - 2;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    box,
                    PositionedDirectional(top: room, end: room, child: b),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Fluent 2's ToggleButton: a [Fluent2Button] that stays pressed while
/// [checked], on the appearance's selected face, its glyph turning to
/// [checkedIcon]; a press asks [onChanged] for the other state. Read as a
/// toggle named [label].
///
/// ```dart
/// Fluent2ToggleButton('Bold', value: bold, icon: Fluent2Icons.edit, onChanged: (v) => setState(() => bold = v))
/// ```
class Fluent2ToggleButton extends StatelessWidget {
  /// A button labelled [label] that holds [value] on or off.
  const Fluent2ToggleButton(
    this.label, {
    required this.value,
    required this.onChanged,
    this.appearance = Fluent2ButtonAppearance.secondary,
    this.size = Fluent2ButtonSize.medium,
    this.shape,
    this.icon,
    this.checkedIcon,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The words on its face.
  final String label;

  /// Whether it is on (drawn in the brand fill).
  final bool value;

  /// Called with the new value when the user changes it; null puts it out of
  /// use.
  final ValueChanged<bool>? onChanged;

  /// Fluent's `appearance`: which of its faces it wears.
  final Fluent2ButtonAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2ButtonSize size;

  /// Fluent's corners; null leaves them to [style], the theme and its
  /// shape scale, then [Fluent2ButtonShape.rounded].
  final Fluent2ButtonShape? shape;

  /// The glyph before [label]; null shows none.
  final IconData? icon;

  /// The glyph worn while [checked]; null wears [icon]'s filled twin.
  final IconData? checkedIcon;

  /// This button's own look, slot by slot, over its appearance's theme;
  /// [WidgetState.selected] while [value].
  final Fluent2Style? style;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final look = Fluent2ButtonLook(
      context.fluent2Theme,
      touch: Fluent2Layout.padded(context),
      appearance: appearance,
      size: size,
      style: style,
      shape: shape,
    );
    final m = look.metrics;
    final change = onChanged;
    return fluent2OwnWidth(
      context,
      Fluent2HitSlop(
        child: Fluent2Pressable(
          focusNode: focusNode,
          autofocus: autofocus,
          onPressed: change == null ? null : () => change(!value),
          label: label,
          toggled: value,
          radius: look.radius,
          shape: look.outlines,
          builder: (context, states) {
            return Fluent2Eased<Fluent2ButtonFace>(
              value: look.face(states, checked: value),
              lerp: Fluent2ButtonFace.lerp,
              builder: (context, face) {
                final glyph = icon == null
                    ? null
                    : Icon(
                        value
                            ? (checkedIcon ?? fluent2Filled(icon!))
                            : fluent2FillOn(icon!, states),
                        size: look.glyph(states),
                        color: face.glyph,
                      );
                return look.box(
                  states,
                  face: face,
                  minWidth: m.minWidth,
                  padding: EdgeInsets.symmetric(horizontal: look.sideRoom),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: m.gap,
                    children: [
                      ?glyph,
                      Flexible(
                        child: fluent2CapCentred(
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: look.type(states, face.ink),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Fluent 2's CompoundButton: a 40 glyph before two lines, the [label] in
/// body1Strong over its [secondary] line in caption1, 14 over and under
/// and 12 at the sides; for a choice that needs its consequence said
/// ("Join now / With camera and mic on"). [style] restyles it over its
/// appearance's button theme and the theme's knobs.
///
/// ```dart
/// Fluent2CompoundButton('Join now', secondary: 'With camera and mic on', icon: Fluent2Icons.video, appearance: Fluent2ButtonAppearance.primary, onPressed: join)
/// ```
class Fluent2CompoundButton extends StatelessWidget {
  /// A button with [label] over the quieter [secondary] line.
  const Fluent2CompoundButton(
    this.label, {
    required this.secondary,
    required this.onPressed,
    this.icon,
    this.appearance = Fluent2ButtonAppearance.secondary,
    this.expand = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The main words.
  final String label;

  /// The quieter line under [label].
  final String secondary;

  /// Called when it is pressed; null puts it out of use.
  final VoidCallback? onPressed;

  /// The glyph before the words; null shows none.
  final IconData? icon;

  /// Fluent's `appearance`: which of its faces it wears.
  final Fluent2ButtonAppearance appearance;

  /// Whether it fills its row's width.
  final bool expand;

  /// This button's own look, slot by slot, over its theme's.
  final Fluent2Style? style;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final look = Fluent2ButtonLook(
      t,
      touch: Fluent2Layout.padded(context),
      appearance: appearance,
      size: Fluent2ButtonSize.medium,
      style: style,
    );
    // Fluent's medium CompoundButton: 14 12 16 12 inside its 1 stroke, a 40
    // glyph 12 before the words.
    final room =
        t.density.padding(const EdgeInsets.fromLTRB(12, 14, 12, 16)) +
        const EdgeInsets.all(Fluent2Stroke.thin);
    return fluent2OwnWidth(
      context,
      Fluent2Pressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: onPressed,
        label: '$label, $secondary',
        radius: look.radius,
        shape: look.outlines,
        builder: (context, states) {
          final press = states.press;
          return Fluent2Eased<Fluent2ButtonFace>(
            value: look.face(states),
            lerp: Fluent2ButtonFace.lerp,
            builder: (context, face) {
              final quiet = appearance == Fluent2ButtonAppearance.primary
                  ? face.ink
                  : press == Fluent2Press.disabled
                  ? face.ink
                  : t.colors.neutralForeground2;
              // Fluent's secondary content: caption1 on a line as tall as its
              // type (`lineHeight: 100%`).
              final words = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: look.type(states, face.ink)),
                  Text(
                    secondary,
                    style: t.caption1.copyWith(height: 1).c(quiet),
                  ),
                ],
              );
              return look.box(
                states,
                face: face,
                width: expand
                    ? (fluent2Roomy(context)
                          ? fluent2ControlMax
                          : double.infinity)
                    : null,
                padding: room,
                child: Row(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  spacing: Fluent2Spacing.m,
                  children: [
                    if (icon != null)
                      Icon(
                        fluent2FillOn(icon!, states),
                        size: 40,
                        color: face.glyph,
                      ),
                    if (expand)
                      Expanded(child: words)
                    else
                      Flexible(child: words),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Fluent 2's MenuButton: a [Fluent2Button] whose words end in the down
/// chevron, saying it opens a menu; [onTap] opens it (a [Fluent2Menu]).
///
/// ```dart
/// Fluent2MenuButton('Sort', icon: Fluent2Icons.arrowSort, onPressed: () => Fluent2Menu.show(context, items: sorts))
/// ```
class Fluent2MenuButton extends StatelessWidget {
  /// A button labelled [label] with a chevron that opens a menu.
  const Fluent2MenuButton(
    this.label, {
    required this.onPressed,
    this.appearance = Fluent2ButtonAppearance.secondary,
    this.size = Fluent2ButtonSize.medium,
    this.icon,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The words on its face.
  final String label;

  /// Called when it is pressed; null puts it out of use.
  final VoidCallback? onPressed;

  /// Fluent's `appearance`: which of its faces it wears.
  final Fluent2ButtonAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2ButtonSize size;

  /// The glyph before [label]; null shows none.
  final IconData? icon;

  /// This button's own look, slot by slot, over its appearance's theme.
  final Fluent2Style? style;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final look = Fluent2ButtonLook(
      context.fluent2Theme,
      touch: Fluent2Layout.padded(context),
      appearance: appearance,
      size: size,
      style: style,
    );
    final m = look.metrics;
    return fluent2OwnWidth(
      context,
      Fluent2HitSlop(
        child: Fluent2Pressable(
          focusNode: focusNode,
          autofocus: autofocus,
          onPressed: onPressed,
          label: label,
          hint: Fluent2Localizations.of(context).opensMenu,
          radius: look.radius,
          shape: look.outlines,
          builder: (context, states) {
            return Fluent2Eased<Fluent2ButtonFace>(
              value: look.face(states),
              lerp: Fluent2ButtonFace.lerp,
              builder: (context, face) {
                return look.box(
                  states,
                  face: face,
                  padding: EdgeInsets.symmetric(horizontal: look.sideRoom),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          fluent2FillOn(icon!, states),
                          size: look.glyph(states),
                          color: face.glyph,
                        ),
                        SizedBox(width: m.gap),
                      ],
                      Flexible(
                        child: fluent2CapCentred(
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: look.type(states, face.ink),
                          ),
                        ),
                      ),
                      const SizedBox(width: Fluent2Spacing.xs),
                      Icon(
                        m.chevron > 12
                            ? Fluent2Icons.chevronDown16
                            : Fluent2Icons.chevronDown12,
                        size: m.chevron,
                        color: face.glyph,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// One of a [Fluent2SplitButton]'s other choices: its [label] (and [icon])
/// on a menu row, [onPressed] run when it is chosen; a null [onPressed]
/// draws the row in the disabled ink and passes it over.
///
/// ```dart
/// Fluent2SplitAction('Reply', onPressed: reply, icon: Fluent2Icons.arrowReply)
/// ```
@immutable
class Fluent2SplitAction {
  /// A choice labelled [label] that calls [onPressed].
  const Fluent2SplitAction(this.label, {required this.onPressed, this.icon});

  /// The menu row's words.
  final String label;

  /// Called when the choice is picked; null disables it.
  final VoidCallback? onPressed;

  /// The menu row's glyph; null shows none.
  final IconData? icon;
}

/// Fluent 2's SplitButton: the act ([label], [onPressed]) and, joined to it
/// past a hairline, the chevron that opens a menu of its other choices
/// ([actions]) under its end. Two tap targets, two buttons to a screen
/// reader ("[label]", "More options for [label]", which says whether its
/// menu is open); Down on either half opens the menu, the arrows walk it,
/// Escape closes it and gives focus back. The behaviour is the design kit's
/// DesignSplitButton; Fluent 2 paints both halves and the menu.
///
/// ```dart
/// Fluent2SplitButton('Reply', icon: Fluent2Icons.arrowReply, appearance: Fluent2ButtonAppearance.primary, onPressed: reply, actions: [Fluent2SplitAction('Reply all', onPressed: replyAll), Fluent2SplitAction('Forward', onPressed: forward)])
/// ```
class Fluent2SplitButton extends StatelessWidget {
  /// A button labelled [label] beside a chevron that opens its other choices.
  const Fluent2SplitButton(
    this.label, {
    required this.onPressed,
    required this.actions,
    this.menuLabel,
    this.appearance = Fluent2ButtonAppearance.secondary,
    this.size = Fluent2ButtonSize.medium,
    this.icon,
    this.style,
    super.key,
  });

  /// The main act's words.
  final String label;

  /// The main act; null draws that half disabled.
  final VoidCallback? onPressed;

  /// The menu's choices; none draws the chevron half disabled.
  final List<Fluent2SplitAction> actions;

  /// What a screen reader calls the chevron half; null:
  /// [Fluent2Localizations.moreOptionsFor] the label.
  final String? menuLabel;

  /// Fluent's `appearance`: which of its faces it wears.
  final Fluent2ButtonAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2ButtonSize size;

  /// The glyph before [label]; null shows none.
  final IconData? icon;

  /// Both halves' own look, slot by slot, over the appearance's theme. A
  /// styled shape lends the halves its corner radius: the act takes the
  /// start corners, the chevron the end ones.
  final Fluent2Style? style;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final look = Fluent2ButtonLook(
      t,
      touch: Fluent2Layout.padded(context),
      appearance: appearance,
      size: size,
      style: style,
    );
    final m = look.metrics;
    final h = look.height;
    final divider = appearance == Fluent2ButtonAppearance.primary
        ? t.colors.neutralStrokeOnBrand
        : t.colors.neutralStroke1;
    final words = Fluent2Localizations.of(context);
    final direction = Directionality.of(context);
    Radius corner(Set<WidgetState> states) => Radius.circular(
      fluent2CornerOf(look.outline(states), h, Fluent2Radius.medium),
    );
    // The halves keep the button's own height. Under a finger each half is
    // its own 48 target: it stands 48 tall round its face, and each face is
    // at least 48 wide, so the halves still meet at the divider.
    final touch = Fluent2Layout.padded(context);
    final least = touch ? Fluent2Layout.touchHitTarget : 0.0;
    Widget ring(Widget face, Set<WidgetState> states) => !states.focused
        ? face
        : Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.none,
            children: [
              face,
              Positioned.fill(
                child: IgnorePointer(
                  child: Fluent2FocusRing(radius: corner(states).x),
                ),
              ),
            ],
          );
    Widget main(Set<WidgetState> states) {
      return Fluent2Eased<Fluent2ButtonFace>(
        value: look.face(states),
        lerp: Fluent2ButtonFace.lerp,
        builder: (context, face) {
          final stroke = look.side(states, face);
          // Fluent's act is a button whose end stroke is the divider: here the
          // hairline after it.
          return ring(
            Fluent2ButtonBox(
              face: face,
              radius: BorderRadiusDirectional.horizontal(start: corner(states))
                  .resolve(direction),
              height: h,
              minWidth: math.max(
                least,
                look.minWidth(states, m.minWidth - Fluent2Stroke.thin),
              ),
              border: BorderDirectional(
                top: stroke,
                bottom: stroke,
                start: stroke,
              ),
              padding: look.padding(
                states,
                EdgeInsetsDirectional.only(
                  start: look.sideRoom,
                  end: look.sideRoom - Fluent2Stroke.thin,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: m.gap,
                children: [
                  if (icon != null)
                    Icon(
                      fluent2FillOn(icon!, states),
                      size: look.glyph(states),
                      color: face.glyph,
                    ),
                  fluent2CapCentred(
                    Text(
                      label,
                      maxLines: 1,
                      style: look.type(states, face.ink),
                    ),
                  ),
                ],
              ),
            ),
            states,
          );
        },
      );
    }

    Widget toggle(Set<WidgetState> states, bool open) {
      // While its menu is open the chevron half holds its pressed face.
      final held = open && states.press != Fluent2Press.disabled
          ? {...states, WidgetState.pressed}
          : states;
      return Fluent2Eased<Fluent2ButtonFace>(
        value: look.face(held),
        lerp: Fluent2ButtonFace.lerp,
        builder: (context, face) {
          final stroke = look.side(held, face);
          // Fluent's menu part: a glyph-only button's room (1, 5, 7) round the
          // chevron, its stroke at the end only, at least 24 wide.
          return ring(
            Fluent2ButtonBox(
              face: face,
              radius: BorderRadiusDirectional.horizontal(end: corner(held))
                  .resolve(direction),
              height: h,
              width: math.max(
                math.max(24, least),
                2 * ((h - m.glyph) / 2 - Fluent2Stroke.thin) +
                    m.chevron +
                    Fluent2Stroke.thin,
              ),
              border: BorderDirectional(
                top: stroke,
                bottom: stroke,
                end: stroke,
              ),
              child: Icon(
                m.chevron > 12
                    ? Fluent2Icons.chevronDown16
                    : Fluent2Icons.chevronDown12,
                size: m.chevron,
                color: face.glyph,
              ),
            ),
            states,
          );
        },
      );
    }

    return fluent2OwnWidth(
      context,
      Fluent2HitSlop(
        child: DesignSplitButton(
          label: label,
          onPressed: onPressed,
          menuLabel: menuLabel ?? words.moreOptionsFor(label),
          minimumSize: Size(0, least),
          actions: [
            for (final a in actions)
              DesignSplitAction(
                label: a.label,
                onPressed: a.onPressed,
                data: a,
              ),
          ],
          buttonBuilder: (context, part, states, open) =>
              part == DesignSplitPart.main
              ? main(states)
              : toggle(states, open),
          layoutBuilder: (context, main, toggle) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              main,
              SizedBox(
                width: Fluent2Stroke.thin,
                height: h,
                child: ColoredBox(color: divider),
              ),
              toggle,
            ],
          ),
          itemBuilder: (context, action, states) => Fluent2MenuRowFace(
            label: action.label,
            icon: (action.data as Fluent2SplitAction?)?.icon,
            states: {
              ...states,
              if (action.onPressed == null) WidgetState.disabled,
            },
            ring: true,
          ),
          surfaceBuilder: (context, info, items) =>
              Fluent2MenuSurface(info: info, items: items),
        ),
      ),
    );
  }
}
