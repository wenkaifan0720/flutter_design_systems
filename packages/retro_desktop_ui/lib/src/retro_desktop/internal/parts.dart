// Pieces several parts share: a raised panel, a lit row, a held segment, a bare editor and a sunken box. Not part
// of the public API (the barrel does not export internal/).
import 'dart:math' as math;

import 'package:flutter/gestures.dart'
    show GestureBinding, PointerDownEvent, PointerEvent, PointerHoverEvent;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyDownEvent, KeyEvent;

import '../component_themes.dart';
import '../editing.dart';
import '../layout.dart' show RetroDesktopReach;
import '../pixels.dart';
import '../shapes.dart';
import '../theme.dart';
import 'caps.dart';
import 'face.dart';
import '../tokens.dart';

/// Whether the last input was a key (else the pointer's press or move): a menu lights its focused row only for the
/// keyboard, as the period's menus lit the row the keys moved to; opened by the pointer, the focus a menu puts on its
/// first row stays unlit (lit, it read as chosen), and the row under the pointer is the lit one.
abstract final class RetroDesktopLastInput {
  static bool _listening = false;
  static bool _byKey = false;

  /// Whether the last input was a key.
  static bool get byKey {
    listen();
    return _byKey;
  }

  /// Starts following the input; calling it again is harmless.
  static void listen() {
    // The keyboard's handler goes in again each time, taken out first so it is never in twice: a test binding clears
    // the keyboard's handlers after each test, and a flag alone left every test after the first unheard.
    HardwareKeyboard.instance
      ..removeHandler(_onKey)
      ..addHandler(_onKey);
    if (_listening) return;
    _listening = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  static bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent) _byKey = true;
    return false;
  }

  static void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent || event is PointerHoverEvent) {
      _byKey = false;
    }
  }
}

/// Whether a menu's row stands lit: the keyboard's row once a key was the last input, else the row under the
/// pointer. The look draws the two alike, in the highlight's bar, so a menu has one current row, as the period's had:
/// with the pointer resting on one row and the keys on another, the keys' row alone. Opened by a click a menu lights
/// none until the pointer or the keys move (the focus ui_core puts on its first row is the keys' place, unlit).
bool retroDesktopMenuRowLit(Set<WidgetState> states, {required bool enabled}) =>
    enabled &&
    (RetroDesktopLastInput.byKey
        ? states.contains(WidgetState.focused)
        : states.contains(WidgetState.hovered));

/// A raised panel: a popup's, a menu's, a sheet's. The machine's grey, the
/// family's outline and the hard shadow every raised thing casts.
Widget retroDesktopPanel(
  BuildContext context, {
  required Widget child,
  EdgeInsetsGeometry padding = const EdgeInsets.all(RetroDesktopSpacing.s4),
  RetroDesktopStyle? style,
  RetroDesktopStyle? component,
}) {
  final t = RetroDesktopTheme.of(context);
  return retroDesktopFace(
    shadows: [
      BoxShadow(
        color: t.colors.shade.withValues(
          alpha: t.colors.brightness == Brightness.dark ? .95 : .8,
        ),
        offset: const Offset(2, 2),
      ),
    ],
    states: const {},
    component: (component ?? t.menuTheme).over(
      RetroDesktopStyle(fill: WidgetStatePropertyAll(t.colors.platinum)),
    ),
    style: style,
    padding: padding,
    scale: RetroDesktopFaceScale.surface,
    child: child,
  );
}

/// The outline of a row inside a panel or a well: concentric with the panel,
/// never squarer than a control.
OutlinedBorder retroDesktopItemShape(RetroDesktopThemeData t) =>
    RetroDesktopShapes.atLeast(
      RetroDesktopShapes.inset(
        t.shapes.medium,
        t.strokes.regular + t.strokes.hairline + 4 * t.density.horizontal,
      ),
      t.shapes.small,
    );

/// A row of a menu, a list of options or a palette: lit in the highlight when
/// [lit] (the keyboard's row, or the row a menu bar has open), its words in
/// the highlight's ink; quieter when disabled. Hover changes nothing.
Widget retroDesktopLitRow(
  BuildContext context, {
  required Widget child,
  required bool lit,
  bool enabled = true,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  ),
  OutlinedBorder? shape,
}) {
  final t = RetroDesktopTheme.of(context);
  final c = t.colors;
  final ink = lit ? c.onHighlight : (enabled ? c.text : c.textTertiary);
  return DecoratedBox(
    decoration: ShapeDecoration(
      shape: shape ?? retroDesktopItemShape(t),
      color: lit ? c.highlight : null,
    ),
    child: DefaultTextStyle.merge(
      style: t.textTheme.body.copyWith(color: ink),
      child: IconTheme.merge(
        data: IconThemeData(color: ink, size: 16),
        // Under a finger a row reaches as far as a button does.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: RetroDesktopReach.least(context),
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            heightFactor: 1,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    ),
  );
}

/// A segment's ground while it is held or chosen: Platinum's darker grey, or
/// Chisel's sunken face over its held grey. Null draws nothing extra. Its words
/// sink a pixel with the face unless [sink] is false (a list's chosen row,
/// whose words stay on the list's one line).
///
/// Platinum's well is a rectangle [bleed] taller than [child] above and below;
/// given an [outline] (a frame's, square where the well meets no corner of it)
/// it fills that outline's inner path instead, over [child] grown by [reach]:
/// concentric with the frame, its corners the frame's less the outline's width,
/// its turned-in bevel following them.
Widget retroDesktopHeldGround(
  RetroDesktopThemeData t, {
  required bool held,
  required Widget child,
  double bleed = 0,
  OutlinedBorder? outline,
  EdgeInsets reach = EdgeInsets.zero,
  bool sink = true,
}) {
  final c = t.colors;
  if (!held) return child;
  final words = sink ? _Sink(child: child) : child;
  if (!t.chisel) {
    // On whole device pixels, as the frame round it is drawn: a ground at a
    // fractional edge would leave a pale row against the frame's bevel.
    // Pressed in is in shadow, by night too: the night's lighter grey sat within a face's own top-to-bottom shading,
    // so a held toggle read as not held. And its bevel turns in (the light from the top start now falls on its bottom
    // and end inner edges, the shade on its top and start): a darker ground alone read as a tint, the chosen toggle
    // the same as a held one beside a raised one. [bleed] carries it over the frame's own bevel above and below, so
    // the well meets the outline: inside that bevel the frame's light ran over the well's shade (light, then dark, at
    // its top).
    return RetroDesktopPixelPaint(
      foreground: true,
      painter: _TurnedInPainter(
        shade: c.bevelDarker,
        light: c.bevelLight,
        bleed: bleed,
        outline: outline,
        reach: reach,
      ),
      child: RetroDesktopPixelPaint(
        painter: _GroundPainter(
          c.brightness == Brightness.dark ? c.bevelDark : c.platinumDark,
          bleed: bleed,
          outline: outline,
          reach: reach,
        ),
        // The words sink a pixel with the face; the segment keeps its size.
        child: words,
      ),
    );
  }
  // The bevel on the grid the ground and the frame round it stand on: off it,
  // at a fractional height, a device pixel of ground showed between the
  // frame's rim and the bevel.
  return RetroDesktopPixelPaint(
    foreground: true,
    painter: _SunkenBevelPainter(c),
    child: RetroDesktopPixelPaint(
      painter: _GroundPainter(retroDesktopChiselHeldBox(c)),
      // The words sink a pixel; the segment keeps its size.
      child: words,
    ),
  );
}

/// A menu's row that takes the keyboard's focus as the pointer moves over it, so the keys go on from the row the
/// pointer lit (beside [retroDesktopMenuRowLit]). Only a move does: a row that comes to stand under a resting pointer (a
/// menu opened from the keys) leaves the keys where they are. Built inside the row's own [Focus]; it draws nothing.
class RetroDesktopPointerFocus extends StatelessWidget {
  /// [child], a row that takes the focus under a moving pointer while [enabled].
  const RetroDesktopPointerFocus({
    super.key,
    required this.enabled,
    required this.child,
  });

  /// Whether the row can take the focus.
  final bool enabled;

  /// The row.
  final Widget child;

  @override
  Widget build(BuildContext context) => MouseRegion(
    opaque: false,
    onHover: enabled
        ? (_) {
            final node = Focus.maybeOf(context, createDependency: false);
            if (node != null && node.canRequestFocus && !node.hasFocus) {
              node.requestFocus();
            }
          }
        : null,
    child: child,
  );
}

class _GroundPainter extends RetroDesktopPixelPainter {
  const _GroundPainter(
    this.color, {
    this.bleed = 0,
    this.outline,
    this.reach = EdgeInsets.zero,
  });
  final Color color;
  final double bleed;
  final OutlinedBorder? outline;
  final EdgeInsets reach;
  @override
  void paint(RetroDesktopPixelGrid px, Size size) {
    final well = _wellOutline(px, outline);
    if (well == null) {
      px.fill(Rect.fromLTRB(0, -bleed, size.width, size.height + bleed), color);
      return;
    }
    px.canvas.drawPath(
      well.getOuterPath(px.snap(reach.inflateRect(Offset.zero & size))),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_GroundPainter old) =>
      old.color != color ||
      old.bleed != bleed ||
      old.outline != outline ||
      old.reach != reach;
}

/// The well's own outline inside a frame's [outline]: its inner path, the
/// outline's width taken on whole device pixels as the frame draws it.
OutlinedBorder? _wellOutline(
  RetroDesktopPixelGrid px,
  OutlinedBorder? outline,
) => outline == null
    ? null
    : RetroDesktopShapes.inset(outline, px.extent(outline.side.width));

/// Platinum's turned-in bevel inside a held or chosen segment: one pixel of [shade] along the top and the start, one of
/// [light] along the bottom and the end, on whole device pixels. The light stands at the top start: the top right right
/// to left.
class _TurnedInPainter extends RetroDesktopPixelPainter {
  const _TurnedInPainter({
    required this.shade,
    required this.light,
    this.bleed = 0,
    this.outline,
    this.reach = EdgeInsets.zero,
  });
  final Color shade, light;
  final double bleed;
  final OutlinedBorder? outline;
  final EdgeInsets reach;
  @override
  void paint(RetroDesktopPixelGrid px, Size size) {
    final h = px.hair, w = px.hairX;
    final well = _wellOutline(px, outline);
    if (well != null) {
      // Concentric in a frame's corner: the band one pixel in, the shade along
      // its top and its start (round the corner between them), the light the
      // rest.
      final r = px.snap(reach.inflateRect(Offset.zero & size));
      retroDesktopBevelStep(
        px.canvas,
        well.getOuterPath(r),
        RetroDesktopShapes.inset(well, h).getOuterPath(
          Rect.fromLTRB(r.left + w, r.top + h, r.right - w, r.bottom - h),
        ),
        px.fall(w, h),
        shade,
        light,
      );
      return;
    }
    // Turned in: the shade along the top and the start, the light along the
    // bottom and the end.
    px.bevel(
      Rect.fromLTRB(0, -bleed, size.width, size.height + bleed),
      shade,
      light,
    );
  }

  @override
  bool shouldRepaint(_TurnedInPainter old) =>
      old.shade != shade ||
      old.light != light ||
      old.bleed != bleed ||
      old.outline != outline ||
      old.reach != reach;
}

class _SunkenBevelPainter extends RetroDesktopPixelPainter {
  const _SunkenBevelPainter(this.colors);
  final RetroDesktopColors colors;
  @override
  void paint(RetroDesktopPixelGrid px, Size size) =>
      retroDesktopPaintChiselRect(
        px.canvas,
        px.snap(Offset.zero & size),
        retroDesktopChiselEdge(colors, sunken: true),
        outer: px.hair,
        inner: px.hair,
        litFromRight: px.litFromRight,
      );
  @override
  bool shouldRepaint(_SunkenBevelPainter old) => old.colors != colors;
}

/// Chisel's two-step sunken bevel, painted over a box; right to left
/// ([textDirection]) its mirror.
class RetroDesktopSunkenPainter extends CustomPainter {
  /// Paints the sunken bevel in [colors].
  const RetroDesktopSunkenPainter(
    this.colors, {
    this.textDirection = TextDirection.ltr,
  });

  /// The theme's colours.
  final RetroDesktopColors colors;

  /// Which side is the start: right to left, the bevel is mirrored.
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) => retroDesktopPaintChiselRect(
    canvas,
    Offset.zero & size,
    retroDesktopChiselEdge(colors, sunken: true),
    litFromRight: textDirection == TextDirection.rtl,
  );

  @override
  bool shouldRepaint(RetroDesktopSunkenPainter old) =>
      old.colors != colors || old.textDirection != textDirection;
}

/// The white box a field sinks into, its states drawn the way a text field
/// draws them; [child] is what stands in it.
Widget retroDesktopSunkenBox(
  BuildContext context, {
  required Set<WidgetState> states,
  required Widget child,
  EdgeInsetsGeometry padding = const EdgeInsetsDirectional.fromSTEB(
    RetroDesktopSpacing.s8,
    0,
    RetroDesktopSpacing.s6,
    0,
  ),
  RetroDesktopStyle? style,
}) {
  final t = RetroDesktopTheme.of(context);
  return retroDesktopFace(
    states: states,
    component: t.textFieldTheme.over(
      RetroDesktopStyle(fill: WidgetStatePropertyAll(t.colors.paper)),
    ),
    style: style,
    sunken: true,
    padding: padding,
    child: child,
  );
}

/// A bare editor in the look's type and caret, for parts that draw their own
/// box round it (an input group, a combobox, a tag input, a palette).
///
/// Enter: a part whose field gives the focus up on Enter passes [onSubmitted]; a
/// part whose field keeps it (a combobox, a tag input) passes
/// [onEditingComplete] alone. Never both: Flutter restarts the text input of a
/// field told of a submit that still has the focus, and in a browser the
/// restarted input takes no typing.
Widget retroDesktopBareEditor(
  BuildContext context, {
  required TextEditingController controller,
  required FocusNode focusNode,
  String? hint,
  bool enabled = true,
  bool autofocus = false,
  bool obscure = false,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onSubmitted,
  VoidCallback? onEditingComplete,
  TextInputType? keyboardType,
  String? semanticLabel,
  String? semanticHint,
  bool? expanded,
}) {
  final t = RetroDesktopTheme.of(context);
  final c = t.colors;
  // The text field's type and height: what is typed and hinted is set as the
  // words around it are, and under a pointer the line stands 6 clear above and
  // below (a button's height), under a finger in the whole reach.
  final style = t.textTheme.body.copyWith(color: c.text);
  final line =
      MediaQuery.textScalerOf(context).scale(style.fontSize ?? 14) *
      (style.height ?? 1.3);
  final least = RetroDesktopReach.padsAcross(context)
      ? math.max(line + 12, RetroDesktopReach.least(context))
      : line + 12;
  // The decorator's minimum height alone grows the box under the line, so the
  // line takes the slack as padding above and below, the text field's way.
  final pad = math.max(0.0, (least - line) / 2);
  return Material(
    type: MaterialType.transparency,
    // Its node, named, is the unmoved box's, so a clip around it never trims
    // its reach.
    child: MergeSemantics(
      child: Semantics(
        label: semanticLabel,
        // The field's error, else its help, read on the text field itself.
        hint: semanticHint,
        // Whether a list it searches shows under it.
        expanded: expanded,
        // Its capitals on the box's middle, typed or hinted.
        child: RetroDesktopCaps(
          style: style,
          TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            autofocus: autofocus,
            obscureText: obscure,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            onEditingComplete: onEditingComplete,
            keyboardType: keyboardType,
            style: style,
            selectionControls: RetroDesktopTextSelectionControls.of(
              Theme.of(context).platform,
            ),
            contextMenuBuilder: RetroDesktopTextContextMenu.editable,
            cursorColor: c.text,
            cursorWidth: t.strokes.regular == 0 ? 1 : t.strokes.regular,
            cursorRadius: Radius.zero,
            cursorOpacityAnimates: false,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              constraints: BoxConstraints(minHeight: least),
              contentPadding: EdgeInsets.symmetric(vertical: pad),
              hintText: hint,
              hintStyle: style.copyWith(color: c.textTertiary),
              hintMaxLines: 1,
            ),
          ),
        ),
      ),
    ),
  );
}

/// [child] hung [start] over its box's start edge: its box begins [start] in
/// from the child's, which paints and is hit over the edge. A part with no
/// surface at rest (a quiet button) keeps its words on its column's edge, and
/// the face it shows held or focused stands out past it by its padding.
Widget retroDesktopOutdent({required double start, required Widget child}) =>
    start <= 0 ? child : _Outdent(start: start, child: child);

class _Outdent extends SingleChildRenderObjectWidget {
  const _Outdent({required this.start, super.child});
  final double start;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOutdent(start, Directionality.of(context));
  @override
  void updateRenderObject(BuildContext context, _RenderOutdent render) => render
    ..start = start
    ..textDirection = Directionality.of(context);
}

class _RenderOutdent extends RenderShiftedBox {
  _RenderOutdent(this._start, this._textDirection) : super(null);
  double _start;
  set start(double v) {
    if (v == _start) return;
    _start = v;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsLayout();
  }

  double _less(double w) => math.max(0, w - _start);
  @override
  double computeMinIntrinsicWidth(double height) =>
      _less(child?.getMinIntrinsicWidth(height) ?? 0);
  @override
  double computeMaxIntrinsicWidth(double height) =>
      _less(child?.getMaxIntrinsicWidth(height) ?? 0);
  @override
  double computeMinIntrinsicHeight(double width) =>
      child?.getMinIntrinsicHeight(width + _start) ?? 0;
  @override
  double computeMaxIntrinsicHeight(double width) =>
      child?.getMaxIntrinsicHeight(width + _start) ?? 0;
  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      child?.getDistanceToActualBaseline(baseline);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final c = child;
    if (c == null) return constraints.smallest;
    final s = c.getDryLayout(_wider(constraints));
    return constraints.constrain(Size(_less(s.width), s.height));
  }

  BoxConstraints _wider(BoxConstraints c) => BoxConstraints(
    minWidth: c.minWidth + _start,
    maxWidth: c.maxWidth + _start,
    minHeight: c.minHeight,
    maxHeight: c.maxHeight,
  );

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    c.layout(_wider(constraints), parentUsesSize: true);
    size = constraints.constrain(Size(_less(c.size.width), c.size.height));
    (c.parentData! as BoxParentData).offset = Offset(
      _textDirection == TextDirection.rtl ? 0 : -_start,
      0,
    );
  }

  // A screen reader outlines the box, which is what a tap reaches: past the edge the column's own bounds stop a tap
  // (hit testing reaches a child only inside its parent), so the face hung over it is drawn, not reached.
  @override
  Rect? describeSemanticsClip(RenderObject? child) => Offset.zero & size;

  // The child is hit where it is painted, as far as the parent lets a press reach.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final c = child;
    if (c == null) return false;
    final offset = (c.parentData! as BoxParentData).offset;
    final hit = result.addWithPaintOffset(
      offset: offset,
      position: position,
      hitTest: (result, p) => c.hitTest(result, position: p),
    );
    if (hit) result.add(BoxHitTestEntry(this, position));
    return hit;
  }
}

// Held words sink a pixel away from the light: down and toward the end.
class _Sink extends StatelessWidget {
  const _Sink({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: retroDesktopFall(
      Directionality.maybeOf(context) ?? TextDirection.ltr,
      1,
      1,
    ),
    child: child,
  );
}
