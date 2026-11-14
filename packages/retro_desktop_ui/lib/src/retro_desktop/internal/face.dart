import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:ui_core/ui_core.dart';

import '../behavior.dart';
import '../component_themes.dart';
import '../glyphs.dart';
import '../theme.dart';
import '../pixels.dart';
import '../press.dart';
import '../shapes.dart';

/// Internal surface scale; public shape slots remain OutlinedBorder values.
enum RetroDesktopFaceScale {
  /// A compact interactive control face: a field, a checkbox, a stepper.
  control,

  /// A push button, popup or chip: the appearance's button outline.
  button,

  /// A content surface with the look's rim.
  surface,

  /// A desktop window face.
  window,

  /// A small identifying mark or avatar face.
  mark,
}

/// The outline that content flush inside the nearest face meets, so a row's
/// fill and highlight take the group's corners on its first and last rows.
class RetroDesktopInnerOutline extends InheritedWidget {
  /// Provides [outline] to the face's content.
  const RetroDesktopInnerOutline({
    super.key,
    required this.outline,
    required super.child,
  });

  /// The face's outline, inset by its rim and padding.
  final OutlinedBorder outline;

  /// The nearest face's inner outline, if any.
  static OutlinedBorder? maybeOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<RetroDesktopInnerOutline>()
      ?.outline;
  @override
  bool updateShouldNotify(RetroDesktopInnerOutline old) =>
      old.outline != outline;
}

/// Where a row stands in its group: first and last rows take the group's
/// corners, rows between are square.
class RetroDesktopRowPlace extends InheritedWidget {
  /// Places the rows below.
  const RetroDesktopRowPlace({
    super.key,
    required this.first,
    required this.last,
    required super.child,
  });

  /// Whether the row meets the group's top or bottom edge.
  final bool first, last;

  /// The nearest place, if any.
  static RetroDesktopRowPlace? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<RetroDesktopRowPlace>();
  @override
  bool updateShouldNotify(RetroDesktopRowPlace old) =>
      old.first != first || old.last != last;
}

/// A row's outline in its group: the group's inner corners on the edges it
/// meets, square elsewhere, so its fill and highlight never cross the group.
OutlinedBorder retroDesktopRowShape(BuildContext context) {
  final place = RetroDesktopRowPlace.maybeOf(context);
  return retroDesktopEdgeShape(
    context,
    top: place?.first ?? true,
    bottom: place?.last ?? true,
  );
}

/// The outline of content flush inside the nearest face, [inset] further in:
/// the face's inner corners on the [top] and [bottom] edges it meets, square
/// on the others (concentric with the face where they meet it).
OutlinedBorder retroDesktopEdgeShape(
  BuildContext context, {
  required bool top,
  required bool bottom,
  double inset = 0,
}) {
  final found = RetroDesktopInnerOutline.maybeOf(context);
  final inner = found == null || inset == 0
      ? found
      : RetroDesktopShapes.inset(found, inset);
  if (inner is RoundedRectangleBorder && (top || bottom)) {
    final r = inner.borderRadius.resolve(Directionality.of(context));
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: top ? r.topLeft : Radius.zero,
        topRight: top ? r.topRight : Radius.zero,
        bottomLeft: bottom ? r.bottomLeft : Radius.zero,
        bottomRight: bottom ? r.bottomRight : Radius.zero,
      ),
    );
  }
  if (inner is RetroDesktopBorder && inner.cut > 0 && top && bottom) {
    return inner;
  }
  // Square, in the kind of outline the family draws: outside any face, the
  // theme's own steps say which.
  final kind = inner ?? RetroDesktopTheme.of(context).shapes.medium;
  return kind is RetroDesktopBorder
      ? const RetroDesktopBorder.square()
      : const RoundedRectangleBorder();
}

/// Draws the shared state-resolved face for a control or surface, in the
/// theme's appearance: Platinum's outline and soft one-step bevel (a [gradient]
/// face, darkened when pressed), or Chisel's hard two-step bevel on a [flat]
/// face whose label moves a pixel down and right when pressed.
/// [openBottom] joins a selected folder tab to its panel without covering content;
/// [openDepth] is how far the tab's foot reaches into the panel below the
/// panel's outline, where the tab's sides stop (its outline at the panel's
/// rule, its bevel a row lower, meeting the panel's).
/// [defaultRing] draws the appearance's default-button ring outside the face;
/// with [ringInBox] the ring stands inside the part's box, the face giving it
/// its room, so the part shows the size of every button beside it.
Widget retroDesktopFace({
  required Widget child,
  required Set<WidgetState> states,
  required RetroDesktopStyle component,
  RetroDesktopStyle? style,
  RetroDesktopFaceScale scale = RetroDesktopFaceScale.control,
  bool sunken = false,
  bool bevel = true,
  bool dashed = false,
  bool openBottom = false,
  double openDepth = 0,
  bool ringInside = false,
  bool defaultRing = false,
  bool ringInBox = false,
  ({Color light, Color shade})? bevelTint,
  Gradient? gradient,
  Color? flat,
  List<BoxShadow>? shadows,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  ),
}) => _Face(
  states: states,
  component: component,
  style: style,
  scale: scale,
  padding: padding,
  sunken: sunken,
  bevel: bevel,
  dashed: dashed,
  openBottom: openBottom,
  openDepth: openDepth,
  ringInside: ringInside,
  defaultRing: defaultRing,
  ringInBox: ringInBox,
  bevelTint: bevelTint,
  gradient: gradient,
  flat: flat,
  shadows: shadows,
  child: child,
);

/// A field's note under it: its helper in the meta grey, or its error in ink
/// after the warning sign. The look has no red; the sign and the darker words
/// are how an error reads as one, in both appearances.
Widget retroDesktopFieldNote(
  RetroDesktopThemeData t,
  String text, {
  required bool error,
}) {
  if (!error) return Text(text, style: t.type.meta);
  final style = t.type.meta.copyWith(color: t.colors.text);
  final size = (style.fontSize ?? 12) + 2;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.only(
          top: ((style.fontSize ?? 12) * (style.height ?? 1.3) - size) / 2,
        ),
        child: Icon(RetroDesktopGlyphs.warning, size: size, color: style.color),
      ),
      const SizedBox(width: 5),
      Expanded(child: Text(text, style: style)),
    ],
  );
}

/// The fill of a Chisel checkbox or radio while the pointer holds it: the PC
/// greyed the white box until the button came up. By night the box is darker
/// than the face, so it lifts to the lighter grey.
Color retroDesktopChiselHeldBox(RetroDesktopColors c) =>
    c.dark ? c.platinumLight : c.platinum;

/// The one flat tone a part's [gradient] stands for: its colour half way along. No part fades (the material law); a
/// part keeps its tones as a gradient so a pressed face and a default face read as they did, and paints this one.
Color retroDesktopMiddleTone(Gradient gradient) {
  final colors = gradient.colors;
  if (colors.length == 1) return colors.single;
  final stops =
      gradient.stops ??
      [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)];
  for (var i = 1; i < colors.length; i++) {
    if (stops[i] >= .5) {
      final span = stops[i] - stops[i - 1];
      final t = span <= 0 ? 0.0 : (.5 - stops[i - 1]) / span;
      return Color.lerp(colors[i - 1], colors[i], t.clamp(0.0, 1.0))!;
    }
  }
  return colors.last;
}

/// A plain glyph that presses, inside a field's box at its end: a password's
/// eye, a search's clear. It has no face of its own (the field is its face),
/// its glyph in the field's secondary ink, the ink's own colour while held;
/// on a desk its reach is only pressed, so the field keeps one line's height.
Widget retroDesktopFieldButton(
  BuildContext context, {
  required IconData icon,
  required String label,
  VoidCallback? onPressed,
}) {
  final t = RetroDesktopTheme.of(context);
  return RetroDesktopPressable(
    onPressed: onPressed,
    label: label,
    inside: true,
    builder: (context, states) => Padding(
      padding: const EdgeInsets.all(2),
      child: Icon(
        icon,
        size: 15,
        color: states.contains(WidgetState.pressed)
            ? t.colors.text
            : t.colors.textSecondary,
      ),
    ),
  );
}

/// The rim a face draws around its content: its outline and its bevel.
double retroDesktopFaceRim(RetroDesktopThemeData t) =>
    t.strokes.regular + t.strokes.hairline;

/// The height a button's face shows, a line button's: one line of its words,
/// its padding at the theme's density, and its rim. Every control that stands
/// in a row with buttons (a popup, an icon button, a joined strip) shows it,
/// so a row has one top and one bottom.
double retroDesktopButtonFaceHeight(BuildContext context) {
  final t = RetroDesktopTheme.of(context);
  final style = t.type.chrome;
  final line =
      MediaQuery.textScalerOf(context).scale(style.fontSize ?? 14) *
      (style.height ?? 1.2);
  final pad = t.density
      .apply(const EdgeInsets.symmetric(vertical: 7), TextDirection.ltr)
      .top;
  return line + 2 * pad + 2 * retroDesktopFaceRim(t);
}

/// The height a small line button's face shows: one line of its words, its
/// small padding at the theme's density, and its rim. A small icon button that
/// stands beside one (a month head's arrows beside its Today) shows it too.
double retroDesktopSmallButtonFaceHeight(BuildContext context) {
  final t = RetroDesktopTheme.of(context);
  final style = t.type.chrome;
  final line =
      MediaQuery.textScalerOf(context).scale(style.fontSize ?? 14) *
      (style.height ?? 1.2);
  final pad = t.density
      .apply(const EdgeInsets.symmetric(vertical: 3), TextDirection.ltr)
      .top;
  return line + 2 * pad + 2 * retroDesktopFaceRim(t);
}

/// How far outside a default button's face the appearance's ring reaches:
/// Chisel's one more black line, Platinum's heavier ring a pixel away.
double retroDesktopDefaultRingExtent(RetroDesktopThemeData t) =>
    t.chisel ? t.strokes.hairline : 1 + 2 * t.strokes.regular;

/// Paints a Chisel bevel on the square [rect]: an [outer] step, then an
/// [inner] one, each light along the top and left and shade along the bottom
/// and right, as [edge] gives them. For square parts drawn by hand: a caption
/// button, a scroll arrow, a progress trough.
void retroDesktopPaintChiselRect(
  Canvas canvas,
  Rect rect,
  ({Color outerLight, Color outerShade, Color innerLight, Color innerShade})
  edge, {
  double outer = 1,
  double inner = 1,
}) {
  void step(Rect r, double w, Color light, Color shade) {
    if (w <= 0 || r.isEmpty) return;
    final paint = Paint()..isAntiAlias = false;
    paint.color = shade;
    canvas.drawRect(
      Rect.fromLTRB(r.left, r.bottom - w, r.right, r.bottom),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(r.right - w, r.top, r.right, r.bottom),
      paint,
    );
    paint.color = light;
    canvas.drawRect(
      Rect.fromLTRB(r.left, r.top, r.right - w, r.top + w),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(r.left, r.top, r.left + w, r.bottom - w),
      paint,
    );
  }

  step(rect, outer, edge.outerLight, edge.outerShade);
  step(rect.deflate(outer), inner, edge.innerLight, edge.innerShade);
}

/// The two colours of each step of a Chisel bevel, outer step first:
/// raised (light above and left), sunken (a field) or pressed (inverted).
({Color outerLight, Color outerShade, Color innerLight, Color innerShade})
retroDesktopChiselEdge(
  RetroDesktopColors c, {
  bool sunken = false,
  bool pressed = false,
}) {
  // By night hi sits barely above the grey (1.7:1), and a Chisel button read
  // as a flat slab; its light step leans halfway to the control line instead.
  final light = c.dark
      ? Color.lerp(c.bevelLight, c.control, .5)!
      : c.bevelLight;
  return sunken
      ? (
          outerLight: c.bevelDark,
          outerShade: light,
          innerLight: c.outline,
          innerShade: c.platinumLight,
        )
      : pressed
      ? (
          outerLight: c.outline,
          outerShade: light,
          innerLight: c.bevelDark,
          innerShade: c.platinumLight,
        )
      : (
          outerLight: light,
          outerShade: c.outline,
          innerLight: c.platinumLight,
          innerShade: c.bevelDark,
        );
}

class _Face extends StatelessWidget {
  const _Face({
    required this.child,
    required this.states,
    required this.component,
    required this.scale,
    required this.padding,
    required this.sunken,
    required this.bevel,
    required this.dashed,
    required this.openBottom,
    required this.ringInside,
    required this.defaultRing,
    required this.ringInBox,
    this.openDepth = 0,
    this.style,
    this.gradient,
    this.flat,
    this.shadows,
    this.bevelTint,
  });
  final Gradient? gradient;
  // Platinum's bevel in a coloured face's own light and shade, so the colour
  // runs to the outline instead of stopping at a grey line inside it.
  final ({Color light, Color shade})? bevelTint;
  // The face a Chisel part takes in place of [gradient]: flat, as the PC drew.
  final Color? flat;
  final bool defaultRing;
  // The ring stands inside the box (a default button beside its others).
  final bool ringInBox;
  // Drop shadows cast by the face's own outline, never by its bounding box.
  final List<BoxShadow>? shadows;
  // A row flush in a group rings its focus inside its outline: outside, the
  // ring would cross the next row and the group's edge.
  final bool sunken, bevel, dashed, openBottom, ringInside;
  final double openDepth;
  final Widget child;
  final Set<WidgetState> states;
  final RetroDesktopStyle component;
  final RetroDesktopStyle? style;
  final RetroDesktopFaceScale scale;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = RetroDesktopTheme.of(context);
    final c = theme.colors;
    final motion = RetroDesktopMotion.of(context);
    T? slot<T>(WidgetStateProperty<T?>? Function(RetroDesktopStyle) get) =>
        RetroDesktopStyle.first([style, component], get, states);
    final down = states.contains(WidgetState.pressed);
    final selected = states.contains(WidgetState.selected);
    final chisel = theme.chisel;
    // A disabled well on the PC took the window's grey, not the paper: an
    // empty one then reads as off by its fill, not only by a flatter bevel.
    // A fill the caller's own style sets still wins.
    final greyWell =
        chisel &&
        sunken &&
        states.contains(WidgetState.disabled) &&
        RetroDesktopStyle.first([style], (s) => s.fill, states) == null;
    // No face fades (the material law): a face given its tones as a gradient
    // is painted flat in their middle, its bevel doing the modelling.
    final fill =
        (greyWell ? c.platinum : null) ??
        slot((s) => s.fill) ??
        (!chisel && gradient != null
            ? retroDesktopMiddleTone(gradient!)
            : null) ??
        (selected
            ? c.highlight
            : chisel
            ? (flat ?? c.platinum)
            : down
            ? c.platinumDark
            : c.platinumLight);
    final ink =
        slot((s) => s.foreground) ?? (selected ? c.onHighlight : c.text);
    final overlay = slot((s) => s.overlay);
    final edge = slot((s) => s.edge);
    final side =
        slot((s) => s.side) ??
        BorderSide(color: edge ?? c.control, width: theme.strokes.regular);
    // A coloured edge (an error, an app's own) stands in for Chisel's outer step.
    final chiselEdge = !chisel
        ? null
        : retroDesktopChiselEdge(c, sunken: sunken, pressed: down && !sunken);
    final keepSide =
        slot((s) => s.side) != null || (edge != null && edge != c.control);
    final shape =
        (slot((s) => s.shape) ??
                switch (scale) {
                  RetroDesktopFaceScale.control => theme.shapes.small,
                  RetroDesktopFaceScale.button => theme.shapes.button,
                  RetroDesktopFaceScale.surface => theme.shapes.medium,
                  RetroDesktopFaceScale.window => theme.shapes.large,
                  RetroDesktopFaceScale.mark => theme.shapes.full,
                })
            .copyWith(side: side);
    // Chisel's label moves a pixel down and right while its button is held.
    final moves = chisel && down && !sunken && bevel;
    // A ring inside the box takes its room from the face: the least size and
    // the padding, so the box shows what a button without one shows.
    final inBox = defaultRing && ringInBox
        ? retroDesktopDefaultRingExtent(theme)
        : 0.0;
    final least = slot((s) => s.minimumSize) ?? Size.zero;
    final minimum = Size(
      (least.width - 2 * inBox).clamp(0.0, double.infinity),
      (least.height - 2 * inBox).clamp(0.0, double.infinity),
    );
    final given =
        slot((s) => s.padding) ??
        theme.density.apply(padding, Directionality.of(context));
    final EdgeInsetsGeometry spacing;
    if (inBox == 0) {
      spacing = given;
    } else {
      final g = given.resolve(Directionality.of(context));
      double less(double v) => (v - inBox).clamp(0.0, double.infinity);
      spacing = EdgeInsets.fromLTRB(
        less(g.left),
        less(g.top),
        less(g.right),
        less(g.bottom),
      );
    }
    final textStyle = theme.type.body
        .merge(slot((s) => s.textStyle))
        .copyWith(color: ink);
    // Cache only while a decoration changes. Once it settles, paint on the
    // parent's current grid rather than retaining old snapped coordinates.
    // Chisel's raised bevel lights its top and leading rows white: a check
    // that reads a custom paint over white would start the face a row late.
    // A sunken one (a chosen chip) starts with its shade row, by night barely
    // off the window's grey: read from its pixels it started a row late too.
    // The box is the face, as the eye sees it on the grey ground. Buttons
    // only: a raised surface or window holds items the checks read inside it.
    final raisedChisel =
        chisel && bevel && scale == RetroDesktopFaceScale.button;
    final face = TweenAnimationBuilder<OutlinedBorder>(
      tween: _OutlineTween(begin: shape, end: shape),
      duration: motion.state,
      curve: motion.standard,
      builder: (context, outline, _) => _decorate(
        context,
        outline,
        overlay,
        fill,
        ink,
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minimum.width,
            minHeight: minimum.height,
          ),
          child: TweenAnimationBuilder<Decoration?>(
            duration: motion.state,
            curve: motion.standard,
            tween: DecorationTween(
              end: ShapeDecoration(
                color: fill,
                shape: outline.copyWith(side: BorderSide.none),
              ),
            ),
            builder: (context, decoration, child) =>
                TweenAnimationBuilder<Decoration?>(
                  duration: motion.state,
                  curve: motion.standard,
                  tween: DecorationTween(
                    end: ShapeDecoration(
                      color: overlay ?? const Color(0x00000000),
                      shape: outline.copyWith(side: BorderSide.none),
                    ),
                  ),
                  builder: (context, foreground, child) => _MotionPaintBoundary(
                    active:
                        outline != shape ||
                        decoration !=
                            ShapeDecoration(
                              color: fill,
                              shape: outline.copyWith(side: BorderSide.none),
                            ) ||
                        foreground !=
                            ShapeDecoration(
                              color: overlay ?? const Color(0x00000000),
                              shape: outline.copyWith(side: BorderSide.none),
                            ),
                    child: RetroDesktopPixelPaint(
                      painter: _SurfacePainter(
                        decoration! as ShapeDecoration,
                        Directionality.of(context),
                      ),
                      child: RetroDesktopPixelPaint(
                        foreground: true,
                        painter: _SurfacePainter(
                          foreground! as ShapeDecoration,
                          Directionality.of(context),
                        ),
                        child: child,
                      ),
                    ),
                  ),
                  child: child,
                ),
            child: RetroDesktopPixelPaint(
              foreground: true,
              painter: _BevelPainter(
                outline,
                bevel ? theme.strokes.hairline : 0,
                down || sunken
                    ? (bevelTint?.shade ?? c.bevelDark)
                    : (bevelTint?.light ?? c.bevelLight),
                down || sunken
                    ? (bevelTint?.light ?? c.bevelLight)
                    : (bevelTint?.shade ?? c.bevelDark),
                Directionality.of(context),
                dashed,
                openBottom: openBottom,
                openDepth: openDepth,
                chisel: bevel ? chiselEdge : null,
                keepSide: keepSide || !bevel,
              ),
              child: Padding(
                padding: outline.dimensions.add(
                  EdgeInsets.all(bevel ? theme.strokes.hairline : 0),
                ),
                // Content is clipped inside the rim, concentric with the
                // outline: a fill flush with it (a header, a selected row)
                // takes the face's inner corners rather than square ones.
                child: ClipPath(
                  clipper: ShapeBorderClipper(
                    shape: RetroDesktopShapes.inset(
                      outline.copyWith(side: BorderSide.none),
                      outline.dimensions
                              .resolve(Directionality.of(context))
                              .left +
                          (bevel ? theme.strokes.hairline : 0),
                      textDirection: Directionality.of(context),
                    ),
                    textDirection: Directionality.of(context),
                  ),
                  child: Padding(
                    padding: spacing,
                    child: Transform.translate(
                      offset: moves ? const Offset(1, 1) : Offset.zero,
                      child: DefaultTextStyle.merge(
                        style: textStyle,
                        child: IconTheme.merge(
                          data: IconThemeData(
                            color: ink,
                            size: slot((s) => s.iconSize) ?? 18,
                          ),
                          child: RetroDesktopInnerOutline(
                            outline: _inner(context, outline, spacing),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return raisedChisel ? DesignKeylineFace(child: face) : face;
  }

  // The outline that content flush with this face's padding meets: the face's
  // own, inset by its rim, bevel and the least of its padding (concentric).
  OutlinedBorder _inner(
    BuildContext context,
    OutlinedBorder outline,
    EdgeInsetsGeometry spacing,
  ) {
    final pad = spacing.resolve(Directionality.of(context));
    final least = [
      pad.left,
      pad.top,
      pad.right,
      pad.bottom,
    ].reduce((a, b) => a < b ? a : b);
    return RetroDesktopShapes.inset(
      outline,
      outline.side.strokeInset +
          (bevel ? RetroDesktopTheme.of(context).strokes.hairline : 0) +
          least,
      textDirection: Directionality.of(context),
    );
  }

  // The face's shadow, its default ring and its focus ring all take the
  // resolved outline, concentric: the default ring outside the face, the
  // focus ring outside that (or, in Chisel, dotted inside the face). Hover
  // draws nothing unless a component theme gives the hovered state an overlay.
  Widget _decorate(
    BuildContext context,
    OutlinedBorder outline,
    Color? overlay,
    Color fill,
    Color ink,
    Widget face,
  ) {
    final theme = RetroDesktopTheme.of(context);
    final plain = outline.copyWith(side: BorderSide.none);
    final claim = RetroDesktopHighlightClaim.maybeOf(context);
    final owns = claim?.claim(context, states) ?? false;
    // The PC drew no soft shadows: Chisel's raised parts stand on their bevel.
    if (shadows != null && shadows!.isNotEmpty && !theme.chisel) {
      face = DecoratedBox(
        decoration: ShapeDecoration(shape: plain, shadows: shadows),
        child: face,
      );
    }
    final ring = defaultRing ? retroDesktopDefaultRingExtent(theme) : 0.0;
    if (ring > 0) {
      face = RetroDesktopPixelPaint(
        foreground: true,
        painter: _DefaultRingPainter(
          plain,
          ring,
          theme.chisel ? 0 : 1,
          theme.colors.dark ? theme.colors.control : theme.colors.outline,
          Directionality.of(context),
        ),
        child: face,
      );
      // In the box: the ring's outer edge is the box's.
      if (ringInBox) {
        face = Padding(padding: EdgeInsets.all(ring), child: face);
      }
    }
    if (!owns) return face;
    return RetroDesktopHighlight(
      shape: plain,
      focused: states.contains(WidgetState.focused),
      inside: ringInside,
      beyond: ringInBox ? 0 : ring,
      // Chisel's dots, and a ring inside a face of its own colour, take the
      // label's colour so they show.
      insideColor: theme.focus.dotted || fill == theme.focus.color ? ink : null,
      child: face,
    );
  }
}

/// The default button's ring, [extent] outside its face: [gap] clear, then the
/// ring, concentric with the face (its radius the face's plus the distance).
/// On the device's grid like the face, so both its sides are as crisp.
class _DefaultRingPainter extends RetroDesktopPixelPainter {
  const _DefaultRingPainter(
    this.shape,
    this.extent,
    this.gap,
    this.color,
    this.direction,
  );
  final OutlinedBorder shape;
  final double extent, gap;
  final Color color;
  final TextDirection direction;
  @override
  void paint(RetroDesktopPixelGrid px, Size size) {
    final rect = px.snap(Offset.zero & size);
    final clear = px.extent(gap);
    RetroDesktopShapes.outset(shape, clear, textDirection: direction)
        .copyWith(
          side: BorderSide(
            color: color,
            width: px.extent(extent) - clear,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        )
        .paint(px.canvas, rect.inflate(clear), textDirection: direction);
  }

  @override
  bool shouldRepaint(_DefaultRingPainter old) =>
      shape != old.shape ||
      extent != old.extent ||
      gap != old.gap ||
      color != old.color ||
      direction != old.direction;
}

// Toggling a render property keeps fields/focus alive while releasing a cached
// face after its animation. A moving settled face then repaints on the new grid.
class _MotionPaintBoundary extends SingleChildRenderObjectWidget {
  const _MotionPaintBoundary({required this.active, required super.child});
  final bool active;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMotionPaintBoundary(active);
  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMotionPaintBoundary renderObject,
  ) {
    renderObject.active = active;
  }
}

class _RenderMotionPaintBoundary extends RenderProxyBox {
  _RenderMotionPaintBoundary(this._active);
  bool _active;
  set active(bool value) {
    if (_active == value) return;
    _active = value;
    markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  @override
  bool get isRepaintBoundary => _active;
}

class _OutlineTween extends Tween<OutlinedBorder> {
  _OutlineTween({required super.begin, required super.end});
  @override
  OutlinedBorder lerp(double t) => OutlinedBorder.lerp(begin, end, t)!;
}

OutlinedBorder _pixelOutline(OutlinedBorder outline, RetroDesktopPixelGrid px) {
  final side = outline.side.copyWith(width: px.extent(outline.side.width));
  return outline is RetroDesktopBorder
      ? outline.copyWith(side: side, cut: px.extent(outline.cut))
      : outline.copyWith(side: side);
}

class _SurfacePainter extends RetroDesktopPixelPainter {
  const _SurfacePainter(this.decoration, this.direction);
  final ShapeDecoration decoration;
  final TextDirection direction;
  @override
  void paint(RetroDesktopPixelGrid px, Size size) {
    final rect = px.snap(Offset.zero & size);
    final outline = _pixelOutline(decoration.shape as OutlinedBorder, px);
    final paint = Paint()..color = decoration.color ?? const Color(0xFFFFFFFF);
    if (decoration.gradient != null) {
      paint.shader = decoration.gradient!.createShader(
        rect,
        textDirection: direction,
      );
    }
    px.canvas.drawPath(
      outline.getOuterPath(rect, textDirection: direction),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SurfacePainter old) =>
      decoration != old.decoration || direction != old.direction;
}

/// Both the outer rim and the inset bevel follow the supplied outline at the
/// current size. Platinum: the outline's own rim, then a one-step bevel.
/// Chisel ([chisel] set): two steps, the rim's width then the bevel's, each
/// light above and left and dark below and right; a coloured rim
/// ([keepSide]) stands in for the outer step.
class _BevelPainter extends RetroDesktopPixelPainter {
  const _BevelPainter(
    this.shape,
    this.width,
    this.light,
    this.shade,
    this.direction,
    this.dashed, {
    this.openBottom = false,
    this.openDepth = 0,
    this.chisel,
    this.keepSide = true,
  });
  final double openDepth;
  final OutlinedBorder shape;
  final double width;
  final Color light, shade;
  final TextDirection direction;
  final bool dashed, openBottom, keepSide;
  final ({
    Color outerLight,
    Color outerShade,
    Color innerLight,
    Color innerShade,
  })?
  chisel;

  // One step of a bevel: the band between [outer] and [inner], light where it
  // faces up and left, shade where it faces down and right.
  void _step(
    Canvas canvas,
    Path outer,
    Path inner,
    double width,
    Color light,
    Color shade,
  ) {
    // Keep the hole explicit. CanvasKit's path-operation result can carry a
    // different winding rule; restoring the input rule fills that hole and
    // paints the foreground bevel over the entire child on the web.
    final band = Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(outer, Offset.zero)
      ..addPath(inner, Offset.zero);
    canvas.save();
    canvas.clipPath(band);
    canvas.drawPath(
      band,
      Paint()
        ..color = shade
        ..isAntiAlias = false,
    );
    canvas.drawPath(
      // This difference has no hole, so it keeps the input winding rule.
      // Preserve its exact edge coverage at fractional layout positions.
      Path.combine(
        PathOperation.difference,
        outer,
        outer.shift(Offset(width, width)),
      ),
      Paint()
        ..color = light
        ..isAntiAlias = false,
    );
    canvas.restore();
  }

  @override
  void paint(RetroDesktopPixelGrid px, Size size) {
    final canvas = px.canvas;
    final rect = px.snap(Offset.zero & size);
    final shape = _pixelOutline(this.shape, px);
    final width = px.extent(this.width);
    if (rect.isEmpty) return;
    if (openBottom) {
      canvas.save();
      final outer = rect.inflate(shape.side.strokeOutset);
      final inset = shape.side.strokeInset;
      final notch = Rect.fromLTRB(
        rect.left + inset,
        (rect.bottom - inset - width).clamp(rect.top, rect.bottom),
        rect.right - inset,
        outer.bottom,
      );
      // Explicit contours preserve the CanvasKit path-hole repair.
      canvas.clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(outer)
          ..addRect(notch),
        doAntiAlias: false,
      );
    }
    // Below the panel's rule the open tab's sides stop: its outline at the
    // rule, its bevel one row lower, where it meets the panel's own (they had
    // run on past both, a dark stub at one corner, a broken light at the other).
    void stopAt(double above) {
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(
          rect.left - size.width,
          rect.top - size.height,
          rect.right + size.width,
          rect.bottom - above,
        ),
      );
    }

    final stopping = openBottom && openDepth > 0;
    try {
      final edge = chisel;
      if (stopping) stopAt(openDepth);
      if (dashed && shape.side.style != BorderStyle.none) {
        final line = Paint()
          ..color = shape.side.color
          ..strokeWidth = shape.side.width
          ..style = PaintingStyle.stroke
          ..isAntiAlias = false;
        final path = shape.getOuterPath(
          rect.deflate(shape.side.width / 2),
          textDirection: direction,
        );
        for (final contour in path.computeMetrics()) {
          for (var from = 2.0; from < contour.length; from += 4) {
            canvas.drawPath(
              contour.extractPath(from, (from + 2).clamp(0, contour.length)),
              line,
            );
          }
        }
      } else if (edge != null && !keepSide && shape.side.width > 0) {
        _step(
          canvas,
          shape.getOuterPath(rect, textDirection: direction),
          shape.getInnerPath(rect, textDirection: direction),
          shape.side.strokeInset,
          edge.outerLight,
          edge.outerShade,
        );
      } else {
        shape.paint(canvas, rect, textDirection: direction);
      }
      if (stopping) canvas.restore();
      if (width <= 0) return;
      if (stopping) stopAt(openDepth > width ? openDepth - width : 0);
      _step(
        canvas,
        shape.getInnerPath(rect, textDirection: direction),
        shape
            .copyWith(side: BorderSide(width: shape.side.strokeInset + width))
            .getInnerPath(rect, textDirection: direction),
        width,
        edge?.innerLight ?? light,
        edge?.innerShade ?? shade,
      );
      if (stopping) canvas.restore();
    } finally {
      if (openBottom) canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BevelPainter old) =>
      shape != old.shape ||
      width != old.width ||
      light != old.light ||
      shade != old.shade ||
      direction != old.direction ||
      dashed != old.dashed ||
      openBottom != old.openBottom ||
      openDepth != old.openDepth ||
      chisel != old.chisel ||
      keepSide != old.keepSide;
}

/// Chisel's drop button at the end of a field with a list behind it (the
/// select's, the combo box's): a bevelled grey square holding a down arrow,
/// pushed in while [down].
class RetroDesktopArrowButtonPainter extends RetroDesktopPixelPainter {
  /// Creates a [RetroDesktopArrowButtonPainter].
  const RetroDesktopArrowButtonPainter(
    this.c,
    this.down,
    this.outer,
    this.inner,
  );

  /// The theme's colours.
  final RetroDesktopColors c;

  /// Whether the button is held.
  final bool down;

  /// The bevel's outer and inner strokes.
  final double outer, inner;
  @override
  void paint(RetroDesktopPixelGrid px, Size size) {
    final rect = px.snap(Offset.zero & size);
    if (rect.isEmpty) return;
    px.canvas.drawRect(rect, Paint()..color = c.platinum);
    retroDesktopPaintChiselRect(
      px.canvas,
      rect,
      retroDesktopChiselEdge(c, pressed: down),
      outer: px.extent(outer),
      inner: px.extent(inner),
    );
    final shift = down ? 1.0 : 0.0;
    final w = 7.0, h = 4.0;
    final x = (rect.center.dx - w / 2).roundToDouble() + shift;
    final y = (rect.center.dy - h / 2).roundToDouble() + shift;
    px.canvas.drawPath(
      Path()..addPolygon([
        Offset(x, y),
        Offset(x + w, y),
        Offset(x + w / 2, y + h),
      ], true),
      Paint()..color = c.text,
    );
  }

  @override
  bool shouldRepaint(RetroDesktopArrowButtonPainter old) =>
      c != old.c ||
      down != old.down ||
      outer != old.outer ||
      inner != old.inner;
}
