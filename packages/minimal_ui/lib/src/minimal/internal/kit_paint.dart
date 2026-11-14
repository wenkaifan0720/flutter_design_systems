// What Minimal paints for ui_core's builders: the states a behaviour hands
// over, turned into the look's wash, ring, highlight and panel on a part's
// own outline. Not exported: the parts call it, pages never do.
import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show DiagnosticPropertiesBuilder, DiagnosticsProperty, DoubleProperty;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../component_themes.dart';
import '../shapes.dart';
import '../theme.dart';
import 'styled.dart';

/// The states a ui_core builder hands over, read the way Minimal paints
/// them: pressed and focused count only while the part is enabled. This file
/// applies it by name (`MinimalKitStates(states).down`), so a copy of the file
/// in an app, beside the package's own, reads its own copy unambiguously.
extension MinimalKitStates on Set<WidgetState> {
  /// A finger or a button is down on it.
  bool get down =>
      contains(WidgetState.pressed) && !contains(WidgetState.disabled);

  /// The keyboard is on it (ui_core sets focused for the keyboard only).
  bool get ring =>
      contains(WidgetState.focused) && !contains(WidgetState.disabled);

  /// It is chosen, on, or its menu is open.
  bool get chosen => contains(WidgetState.selected);

  /// It cannot be used.
  bool get off => contains(WidgetState.disabled);

  /// It is wrong.
  bool get wrong => contains(WidgetState.error);
}

/// The ink a press washes a [face] with, at 8%: of the page's ink and the
/// face's own [faceInk], the darker on a light or mid face and the lighter
/// on a dark one, so a press always deepens or lifts the face it lands on
/// (the dark appearance's pale accent deepens; a black solid button lifts).
/// No [face] reads the page's ground.
Color minimalPressInk(MinimalThemeData t, {Color? face, Color? faceInk}) {
  final page = t.foreground;
  final own = faceInk ?? page;
  final pageDarker = page.computeLuminance() <= own.computeLuminance();
  final dark = pageDarker ? page : own;
  final light = pageDarker ? own : page;
  return (face ?? t.background).computeLuminance() > 0.05 ? dark : light;
}

/// The press wash and the keyboard ring over a part's face on [shape]: the
/// ink at 8% while pressed ([minimalPressInk]), the focus ring while the
/// keyboard is on it: [minimalRingFrame]'s, outside the edge past a gap of
/// [ground] (the page's background when null), or inside the edge with
/// [inside]. A hovering pointer changes nothing. Always a decoration, so a
/// container that wears it never re-parents its child as the states change.
///
/// A ring inside a filled [face] it would vanish into (under 3:1 against
/// it) takes the face's own [faceInk].
Decoration minimalStateLayer(
  MinimalThemeData t,
  OutlinedBorder shape,
  Set<WidgetState> states, {
  bool inside = false,
  Color? overlay,
  Color? face,
  Color? faceInk,
  Color? ground,
}) {
  final wash =
      overlay ??
      (MinimalKitStates(states).down
          ? minimalPressInk(
              t,
              face: face,
              faceInk: faceInk,
            ).withValues(alpha: 0.08)
          : null);
  if (MinimalKitStates(states).ring && !inside) {
    return minimalRingFrame(
      shape,
      wash: wash,
      ring: t.ring,
      ground: ground ?? t.background,
      width: t.focusWidth,
    );
  }
  return minimalFrame(
    shape,
    fill: wash,
    side: MinimalKitStates(states).ring
        ? BorderSide(
            color: face != null && faceInk != null
                ? (_contrast(t.ring, face) < 3 ? faceInk : t.ring)
                : t.ring,
            width: t.focusWidth,
            strokeAlign: BorderSide.strokeAlignInside,
          )
        : BorderSide.none,
  );
}

/// The ground left between a part's edge and its focus ring.
const double _focusGap = 2;

/// A part's press [wash] and keyboard [ring] on [shape], as one foreground
/// decoration: the wash over the face; with a ring, [_focusGap] (2 px) of
/// [ground] outside the edge, opaque, and the ring at [width] outside that,
/// concentric with the face. The gap is what lets a ring read on a face
/// filled in its own ink (an accent button's accent ring), and on an
/// outlined or quiet face it is only a clean margin. With no ring the
/// shape's own side, if it has one, paints as [minimalFrame] would. It
/// animates between states (the ring and the gap fade in together).
Decoration minimalRingFrame(
  OutlinedBorder shape, {
  Color? wash,
  Color? ring,
  Color? ground,
  double width = 2,
}) => _RingFrame(
  shape: shape,
  wash: wash,
  ring: ring,
  ground: ground,
  width: width,
);

/// The ground under the parts at [context]: the fill of the card, dialog,
/// sheet, panel, toast or banner they stand in ([MinimalGroundFill]), made
/// opaque over the ground around it; else the page's background. What a
/// focus ring's gap paints.
Color minimalGround(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<_GroundMark>()?.fill ??
    context.minimalTheme.background;

/// Publishes [fill] as the ground the parts in [child] stand on (see
/// [minimalGround]). A translucent fill is laid over the ground around it.
class MinimalGroundFill extends StatelessWidget {
  /// Stands [child] on [fill].
  const MinimalGroundFill({super.key, required this.fill, required this.child});

  /// The surface's fill; null publishes nothing.
  final Color? fill;

  /// What stands on it.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final own = fill;
    if (own == null || own.a == 0) return child;
    return _GroundMark(
      fill: own.a == 1 ? own : Color.alphaBlend(own, minimalGround(context)),
      child: child,
    );
  }
}

class _GroundMark extends InheritedWidget {
  const _GroundMark({required this.fill, required super.child});

  final Color fill;

  @override
  bool updateShouldNotify(_GroundMark old) => old.fill != fill;
}

class _RingFrame extends Decoration {
  const _RingFrame({
    required this.shape,
    required this.wash,
    required this.ring,
    required this.ground,
    required this.width,
  });

  final OutlinedBorder shape;
  final Color? wash;
  final Color? ring;
  final Color? ground;
  final double width;

  @override
  Path getClipPath(Rect rect, TextDirection textDirection) =>
      shape.getOuterPath(rect, textDirection: textDirection);

  @override
  bool hitTest(Size size, Offset position, {TextDirection? textDirection}) =>
      shape
          .getOuterPath(Offset.zero & size, textDirection: textDirection)
          .contains(position);

  @override
  Decoration? lerpFrom(Decoration? a, double t) =>
      a is _RingFrame && a.shape == shape ? _lerp(a, this, t) : null;

  @override
  Decoration? lerpTo(Decoration? b, double t) =>
      b is _RingFrame && b.shape == shape ? _lerp(this, b, t) : null;

  static _RingFrame _lerp(_RingFrame a, _RingFrame b, double t) => _RingFrame(
    shape: b.shape,
    wash: Color.lerp(a.wash, b.wash, t),
    ring: Color.lerp(a.ring, b.ring, t),
    // The gap fades with the ring it belongs to.
    ground: Color.lerp(
      a.ring == null ? null : a.ground,
      b.ring == null ? null : b.ground,
      t,
    ),
    width: b.ring == null ? a.width : b.width,
  );

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _RingFramePainter(this, onChanged);

  @override
  bool operator ==(Object other) =>
      other is _RingFrame &&
      other.shape == shape &&
      other.wash == wash &&
      other.ring == ring &&
      other.ground == ground &&
      other.width == width;

  @override
  int get hashCode => Object.hash(shape, wash, ring, ground, width);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<OutlinedBorder>('shape', shape))
      ..add(ColorProperty('wash', wash, defaultValue: null))
      ..add(ColorProperty('ring', ring, defaultValue: null))
      ..add(ColorProperty('ground', ground, defaultValue: null))
      ..add(DoubleProperty('width', width));
  }
}

class _RingFramePainter extends BoxPainter {
  _RingFramePainter(this._frame, super.onChanged);

  final _RingFrame _frame;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final direction = configuration.textDirection;
    final shape = _frame.shape;
    final wash = _frame.wash;
    if (wash != null && wash.a > 0) {
      final paint = Paint()..color = wash;
      if (shape is RoundedRectangleBorder) {
        // As BoxDecoration fills it, pixel for pixel.
        canvas.drawRRect(
          shape.borderRadius.resolve(direction).toRRect(rect),
          paint,
        );
      } else if (shape.preferPaintInterior) {
        shape.paintInterior(canvas, rect, paint, textDirection: direction);
      } else {
        canvas.drawPath(
          shape.getOuterPath(rect, textDirection: direction),
          paint,
        );
      }
    }
    final ring = _frame.ring;
    if (ring == null || ring.a == 0) {
      if (shape.side != BorderSide.none) {
        shape.paint(canvas, rect, textDirection: direction);
      }
      return;
    }
    final ground = _frame.ground;
    if (ground != null && ground.a > 0) {
      shape
          .copyWith(
            side: BorderSide(
              color: ground,
              width: _focusGap,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          )
          .paint(canvas, rect, textDirection: direction);
    }
    // A stroke aligned past "outside" stands off the edge: its inner side at
    // the gap, its outer at gap + width, corners grown to stay concentric.
    final width = _frame.width;
    shape
        .copyWith(
          side: BorderSide(
            color: ring,
            width: width,
            strokeAlign: 1 + 2 * _focusGap / width,
          ),
        )
        .paint(canvas, rect, textDirection: direction);
  }
}

/// WCAG's contrast of [a] on [b], from 1 to 21.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// A floating panel (a popover, a menu, a list of options): the surface on
/// `shapes.medium` with its hairline rim and the menu's shadow, clipped to
/// the outline. [style]'s fill, edge or side and shape win.
class MinimalKitPanel extends StatelessWidget {
  /// A floating panel around [child].
  const MinimalKitPanel({
    super.key,
    required this.child,
    this.style,
    this.padding = EdgeInsets.zero,
    this.width,
    this.maxHeight,
  });

  /// The panel's content.
  final Widget child;

  /// Its style, over `components.menu`.
  final MinimalStyle? style;

  /// Space inside its rim.
  final EdgeInsetsGeometry padding;

  /// Its width; null sizes it to its content.
  final double? width;

  /// The tallest it grows before its content scrolls.
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final so = MinimalStyleOf([style, t.components.menu], const {});
    final shape = so.shape ?? t.shapes.medium;
    Widget panel = DecoratedBox(
      decoration: minimalFrame(
        shape,
        fill: so.fill ?? t.card,
        side: so.rim(t.border, t.rim),
        shadows: t.shadowMd,
      ),
      child: minimalClip(
        shape,
        child: Padding(
          padding: so.padding ?? padding,
          child: DefaultTextStyle(
            style: t.bodySmall.c(t.foreground),
            child: MinimalGroundFill(fill: so.fill ?? t.card, child: child),
          ),
        ),
      ),
    );
    if (width != null || maxHeight != null) {
      panel = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: width ?? 0,
          maxWidth: width ?? double.infinity,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: panel,
      );
    }
    return panel;
  }
}

/// A surface arriving from its anchor: it fades in and slides 4 px from the
/// side it opens on, on the overlay's spring; still under Reduce Motion
/// (the spring is then critically damped and the slide nothing).
Widget minimalKitPresence(
  BuildContext context,
  DesignOverlayInfo info,
  Widget child,
) {
  final still = context.minimalStill;
  final rtl = Directionality.of(context) == TextDirection.rtl;
  return AnimatedBuilder(
    animation: info.animation,
    child: child,
    builder: (context, child) {
      final p = info.animation.value;
      final double shift = still ? 0.0 : (1.0 - math.min<double>(p, 1.0)) * 4.0;
      final offset = switch (info.side) {
        DesignOverlaySide.below => Offset(0, -shift),
        DesignOverlaySide.above => Offset(0, shift),
        DesignOverlaySide.start => Offset(rtl ? -shift : shift, 0),
        DesignOverlaySide.end => Offset(rtl ? shift : -shift, 0),
      };
      return Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform.translate(offset: offset, child: child),
      );
    },
  );
}

/// The outline of a row inside a panel: the panel's own, moved in by the
/// panel's 4 px padding so the two stay concentric.
OutlinedBorder minimalKitRowShape(MinimalThemeData t, [MinimalStyle? style]) {
  final so = MinimalStyleOf([style, t.components.menu], const {});
  return MinimalShapes.inset(so.shape ?? t.shapes.medium, MinimalSpacing.s4);
}

/// One 32 px row of an open list or menu (an option, a menu item, an
/// action). The active row (the keyboard's, or the pointer's: an open list
/// follows the pointer) takes the selection fill; a chosen value its check;
/// a destructive action the destructive ink.
class MinimalKitRow extends StatelessWidget {
  /// A row of a list a ui_core behaviour drives.
  const MinimalKitRow({
    super.key,
    required this.states,
    required this.label,
    this.icon,
    this.leading,
    this.trailing,
    this.checked = false,
    this.destructive = false,
    this.start = MinimalSpacing.s8,
    this.style,
  });

  /// The row's states from its behaviour: focused (the active row), selected,
  /// disabled.
  final Set<WidgetState> states;

  /// What the row says.
  final String label;

  /// A glyph before the label.
  final IconData? icon;

  /// A widget before the label, in place of [icon].
  final Widget? leading;

  /// A widget after the label: a shortcut, a count, a chevron.
  final Widget? trailing;

  /// Whether it shows a check.
  final bool checked;

  /// Whether it is destructive, in the destructive ink.
  final bool destructive;

  /// The air before its glyph or words: 8, or what a select's list sets so
  /// an option's words start where the field's value does.
  final double start;

  /// Its style, over `components.menu`.
  final MinimalStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final shape = minimalKitRowShape(t, style);
    final active =
        !MinimalKitStates(states).off &&
        (states.contains(WidgetState.focused) ||
            states.contains(WidgetState.hovered));
    final ink = MinimalKitStates(states).off
        ? t.textTertiary
        : destructive
        ? t.destructiveInk
        : t.foreground;
    final glyph = icon;
    final lead = leading;
    final end = trailing;
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: EdgeInsetsDirectional.only(
        start: start,
        end: MinimalSpacing.s8,
        top: MinimalSpacing.s4,
        bottom: MinimalSpacing.s4,
      ),
      decoration: minimalFrame(shape, fill: active ? t.selection : null),
      foregroundDecoration: minimalFrame(
        shape,
        fill: MinimalKitStates(states).down
            ? t.foreground.withValues(alpha: 0.08)
            : null,
      ),
      child: Row(
        children: [
          if (glyph != null) ...[
            MinimalIcon(
              glyph,
              size: MinimalIconSize.i16,
              color: destructive ? t.destructiveInk : t.mutedForeground,
            ),
            const MinimalGap(MinimalSpacing.s8),
          ] else if (lead != null) ...[
            lead,
            const MinimalGap(MinimalSpacing.s8),
          ],
          Expanded(
            child: Text(
              label,
              style: t.bodySmall.c(ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (end != null) ...[const MinimalGap(MinimalSpacing.s8), end],
          if (checked) ...[
            const MinimalGap(MinimalSpacing.s8),
            MinimalIcon(
              LucideIcons.check,
              size: MinimalIconSize.i16,
              color: t.primaryInk,
            ),
          ],
        ],
      ),
    );
  }
}
