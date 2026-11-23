import 'package:flutter/foundation.dart';

import 'dart:math' as math;

import 'package:flutter/rendering.dart' show RenderCustomPaint;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'layout.dart';
import 'behavior.dart';
import 'pixels.dart';
import 'theme.dart';
import 'shapes.dart';

/// Shared keyboard, pointer and accessibility behavior with Retro Desktop's focus outline.
/// A null callback disables the control; [busy] keeps focus while work completes.
///
/// ```dart
/// RetroDesktopPressable(label: 'Open', onPressed: open, child: tile)
/// ```
class RetroDesktopPressable extends StatelessWidget {
  /// Gives a face interaction and a padded touch target.
  const RetroDesktopPressable({
    super.key,
    this.child,
    this.builder,
    this.onPressed,
    this.onLongPress,
    this.label,
    this.value,
    this.hint,
    this.selected,
    this.checked,
    this.toggled,
    this.expanded,
    this.button = true,
    this.link = false,
    this.inGroup = false,
    this.isError = false,
    this.mixed = false,
    this.busy = false,
    this.focusNode,
    this.statesController,
    this.autofocus = false,
    this.alignment = Alignment.center,
    this.focusShape,
    this.ringInside = false,
    this.cursor,
    this.inside = false,
  }) : assert(child != null || builder != null);

  /// A face with no state-dependent drawing.
  final Widget? child;

  /// Draws the face for hovered, focused, pressed, disabled, selected and error states.
  final Widget Function(BuildContext, Set<WidgetState>)? builder;

  /// Tap, Enter, Space and semantic activation.
  final VoidCallback? onPressed;

  /// Long-press action.
  final VoidCallback? onLongPress;

  /// Accessible name, current value and hint.
  final String? label, value, hint;

  /// Accessible selection, check, toggle and expansion states.
  final bool? selected, checked, toggled, expanded;

  /// Whether this is a button.
  final bool button;

  /// Whether this is a link.
  final bool link;

  /// Whether this is a mutually exclusive option.
  final bool inGroup;

  /// Whether the control contains invalid input.
  final bool isError;

  /// Whether a tri-state checkbox is indeterminate.
  final bool mixed;

  /// Keeps the existing focus and face while ignoring activation.
  final bool busy;

  /// Optional externally managed focus.
  final FocusNode? focusNode;

  /// Optional externally managed interaction states.
  final WidgetStatesController? statesController;

  /// Requests focus when mounted.
  final bool autofocus;

  /// Where the face stands in its padded target.
  final AlignmentGeometry alignment;

  /// The outline of the focus feedback when no face inside draws its own;
  /// defaults to the control step.
  final OutlinedBorder? focusShape;

  /// Rings focus inside [focusShape]: for parts that join their neighbours
  /// (rows, menu items, calendar cells), where a ring outside would cross them.
  final bool ringInside;

  /// The pointer over an enabled part; defaults to the click cursor. A
  /// disabled or busy part always shows the basic one.
  final MouseCursor? cursor;

  /// Whether the part stands inside another's face (a field's eye or clear
  /// button): on a desk its reach is only pressed, so the face keeps its height.
  final bool inside;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null || onLongPress != null;
    return RawButton(
      // The pointer says "this presses"; the face doesn't change under it.
      mouseCursor: enabled && !busy
          ? cursor ?? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onPressed: busy ? null : onPressed,
      onLongPress: busy ? null : onLongPress,
      enabled: enabled,
      selected: selected ?? checked ?? toggled ?? false,
      isError: isError,
      focusNode: focusNode,
      statesController: statesController,
      autofocus: autofocus,
      button: button,
      link: link,
      excludeSemantics: label != null,
      semanticLabel: label,
      semanticValue: value,
      semanticHint: hint,
      semanticSelected: selected,
      checked: checked,
      mixed: mixed,
      toggled: toggled,
      expanded: expanded,
      inMutuallyExclusiveGroup: inGroup,
      builder: (context, states, _) => retroDesktopPressChrome(
        context,
        states,
        alignment: alignment,
        inside: inside,
        ringInside: ringInside,
        focusShape: focusShape,
        child: builder?.call(context, states) ?? child!,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<Widget Function(BuildContext, Set<WidgetState>)>.has(
          'builder',
          builder,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(ObjectFlagProperty<VoidCallback>.has('onLongPress', onLongPress))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('value', value, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('selected', selected, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('checked', checked, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('toggled', toggled, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('expanded', expanded, defaultValue: null))
      ..add(FlagProperty('button', value: button, ifFalse: 'button: false'))
      ..add(FlagProperty('link', value: link, ifTrue: 'link'))
      ..add(FlagProperty('inGroup', value: inGroup, ifTrue: 'inGroup'))
      ..add(FlagProperty('isError', value: isError, ifTrue: 'isError'))
      ..add(FlagProperty('mixed', value: mixed, ifTrue: 'mixed'))
      ..add(FlagProperty('busy', value: busy, ifTrue: 'busy'))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<WidgetStatesController>(
          'statesController',
          statesController,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<AlignmentGeometry>(
          'alignment',
          alignment,
          defaultValue: Alignment.center,
        ),
      )
      ..add(
        DiagnosticsProperty<OutlinedBorder>(
          'focusShape',
          focusShape,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('ringInside', value: ringInside, ifTrue: 'ringInside'))
      ..add(
        DiagnosticsProperty<MouseCursor>('cursor', cursor, defaultValue: null),
      )
      ..add(FlagProperty('inside', value: inside, ifTrue: 'inside'));
  }
}

/// What a [RetroDesktopPressable] stands round its face, for a press ui_core builds (a tab of its RawTabBar): the
/// reach a finger needs, the focus ring a face under it claims (else round [child] in [focusShape]), and the dimming
/// while [states] is disabled. Not exported: the look's own.
Widget retroDesktopPressChrome(
  BuildContext context,
  Set<WidgetState> states, {
  required Widget child,
  AlignmentGeometry alignment = Alignment.center,
  bool inside = false,
  bool ringInside = false,
  OutlinedBorder? focusShape,
}) {
  final claim = RetroDesktopHighlightClaim._(states);
  return RetroDesktopReach(
    alignment: alignment,
    inside: inside,
    child: _ClaimedHighlight(
      claim: claim,
      inside: ringInside,
      shape: focusShape ?? RetroDesktopTheme.of(context).shapes.small,
      child: _HighlightScope(
        claim: claim,
        child: AnimatedOpacity(
          duration: RetroDesktopMotion.of(context).state,
          curve: RetroDesktopMotion.of(context).standard,
          opacity: states.contains(WidgetState.disabled) ? .5 : 1,
          child: child,
        ),
      ),
    ),
  );
}

/// Which part under a [RetroDesktopPressable] draws its focus feedback.
/// The first face whose states include the press's states claims it, so the
/// feedback takes that face's exact outline; with no claim, the press draws it
/// around its own box in its focus shape.
class RetroDesktopHighlightClaim {
  RetroDesktopHighlightClaim._(this.states);

  /// The press's current interaction states.
  final Set<WidgetState> states;
  Object? _owner;

  /// Whether a face has claimed the feedback.
  bool get claimed => _owner != null;

  /// The nearest press's claim above [context], if any.
  static RetroDesktopHighlightClaim? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_HighlightScope>()?.claim;

  /// Claims the feedback for [owner], a face drawn for [faceStates]; returns
  /// whether [owner] draws it. A face whose states lack the press's (a static
  /// mark in a pressable row) never claims.
  bool claim(Object owner, Set<WidgetState> faceStates) {
    if (_owner == owner) return true;
    if (_owner != null || !faceStates.containsAll(states)) return false;
    _owner = owner;
    return true;
  }
}

class _HighlightScope extends InheritedWidget {
  const _HighlightScope({required this.claim, required super.child});
  final RetroDesktopHighlightClaim claim;
  @override
  bool updateShouldNotify(_HighlightScope old) => old.claim != claim;
}

class _ClaimedHighlight extends StatelessWidget {
  const _ClaimedHighlight({
    required this.claim,
    required this.shape,
    required this.child,
    this.inside = false,
  });
  final bool inside;
  final RetroDesktopHighlightClaim claim;
  final OutlinedBorder shape;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return _HighlightPaint(
      foregroundPainter: _HighlightPainter(
        shape: shape.copyWith(side: BorderSide.none),
        hover: null,
        ring: claim.states.contains(WidgetState.focused) ? t.focus : null,
        direction: Directionality.of(context),
        skip: claim,
        inside: inside,
        // No face here to stand inside: a link's or a label's words.
        bare: true,
      ),
      child: child,
    );
  }
}

/// The look's interaction feedback around one outline: while [focused], the
/// theme's focus ring, concentric with [shape] (its radius the shape's plus
/// the gap outside, or minus it inside for Chisel's dotted rectangle).
/// Hover draws nothing unless [hoverColor] is given: desktops of the period
/// showed no hover, and the pointer's cursor already says what presses.
/// Faces draw it from their own resolved outline; a custom part can draw it
/// the same way.
///
/// ```dart
/// RetroDesktopHighlight(shape: RetroDesktopTheme.of(context).shapes.small, focused: true, child: face)
/// ```
class RetroDesktopHighlight extends StatelessWidget {
  /// Creates a [RetroDesktopHighlight].
  const RetroDesktopHighlight({
    super.key,
    required this.shape,
    this.hovered = false,
    this.focused = false,
    this.hoverColor,
    this.inside = false,
    this.beyond = 0,
    this.insideColor,
    this.child,
  });

  /// The colour of a ring drawn inside the face in place of the theme's,
  /// where the theme's would not show: the face's label colour for Chisel's
  /// dots (on any fill, as the PC's inverted dots did) and for a ring inside a
  /// face filled with the ring's own colour (a chosen cell). A ring outside
  /// the face keeps the theme's colour.
  final Color? insideColor;

  /// How far outside [shape] the part draws a ring of its own (a default
  /// button's): an outside focus ring stands that much further out.
  final double beyond;

  /// Draws the ring inside the outline, its gap in; for rows flush in a group,
  /// where a ring outside would cross the next row.
  final bool inside;

  /// The part's outline; the tint fills it and the ring follows it outside.
  final OutlinedBorder shape;

  /// Whether a pointer is over the part.
  final bool hovered;

  /// Whether the part has keyboard focus.
  final bool focused;

  /// A tint filling [shape] while [hovered]; none unless given.
  final Color? hoverColor;

  /// The part the feedback is drawn over.
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return _HighlightPaint(
      foregroundPainter: _HighlightPainter(
        shape: shape.copyWith(side: BorderSide.none),
        hover: hovered ? hoverColor : null,
        ring: focused ? t.focus : null,
        direction: Directionality.of(context),
        inside: inside,
        beyond: beyond,
        insideColor: insideColor,
      ),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('insideColor', insideColor, defaultValue: null))
      ..add(DoubleProperty('beyond', beyond, defaultValue: 0))
      ..add(FlagProperty('inside', value: inside, ifTrue: 'inside'))
      ..add(DiagnosticsProperty<OutlinedBorder>('shape', shape))
      ..add(FlagProperty('hovered', value: hovered, ifTrue: 'hovered'))
      ..add(FlagProperty('focused', value: focused, ifTrue: 'focused'))
      ..add(ColorProperty('hoverColor', hoverColor, defaultValue: null));
  }
}

// A custom paint, as checkers reading faces expect, whose render object hands
// its painter the device's grid: a face a fractional width wide (a button sized
// by its words) left the ring's far side on a half pixel, a 3 px smear.
class _HighlightPaint extends CustomPaint {
  const _HighlightPaint({
    required _HighlightPainter super.foregroundPainter,
    super.child,
  });
  @override
  RenderCustomPaint createRenderObject(BuildContext context) =>
      _RenderHighlightPaint(foregroundPainter);
}

class _RenderHighlightPaint extends RenderCustomPaint {
  _RenderHighlightPaint(CustomPainter? painter)
    : super(foregroundPainter: painter);
  @override
  void paint(PaintingContext context, Offset offset) {
    if (foregroundPainter case final _HighlightPainter p) p._box = this;
    super.paint(context, offset);
  }
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter({
    required this.shape,
    required this.hover,
    required this.ring,
    required this.direction,
    this.skip,
    this.inside = false,
    this.beyond = 0,
    this.insideColor,
    this.bare = false,
  });
  final bool inside, bare;
  final double beyond;
  final Color? insideColor;
  final OutlinedBorder shape;
  final Color? hover;
  final RetroDesktopFocusRing? ring;
  final TextDirection direction;
  final RetroDesktopHighlightClaim? skip;
  // The box painting this, set as it paints: its device grid (none when the
  // painter is replayed on a bare canvas).
  RenderBox? _box;
  @override
  void paint(Canvas canvas, Size size) {
    if (skip?.claimed ?? false) return;
    final box = _box;
    final px = box == null || !box.attached
        ? RetroDesktopPixelGrid.plain(canvas)
        : retroDesktopGridUnder(box, canvas);
    final rect = px.snap(Offset.zero & size);
    if (hover != null) {
      canvas.drawPath(
        shape.getOuterPath(rect, textDirection: direction),
        Paint()..color = hover!,
      );
    }
    var ring = this.ring;
    if (ring != null && ring.width > 0) {
      // Chisel's dotted rectangle stands inside the face; a face too small to
      // hold it (a checkbox, a grip) and a part with no face at all (a link's
      // words) take it just outside instead.
      var within = inside || ring.inside;
      var gap = ring.gap;
      if (ring.inside &&
          !inside &&
          (bare || size.shortestSide - 2 * (gap + ring.width) < 10)) {
        within = false;
        gap = 1;
      }
      if (within && insideColor != null) {
        ring = ring.copyWith(color: insideColor);
      }
      final d = within ? -gap : gap + beyond;
      final outline = RetroDesktopShapes.outset(
        shape,
        d,
        textDirection: direction,
      );
      final at = rect.inflate(d);
      if (ring.dotted) {
        _dotted(canvas, outline, at, ring, within);
      } else {
        outline
            .copyWith(
              side: BorderSide(
                color: ring.color,
                width: ring.width,
                strokeAlign: within
                    ? BorderSide.strokeAlignInside
                    : BorderSide.strokeAlignOutside,
              ),
            )
            .paint(canvas, at, textDirection: direction);
      }
    }
  }

  // One pixel on, one off, along the ring's centre line.
  void _dotted(
    Canvas canvas,
    OutlinedBorder outline,
    Rect at,
    RetroDesktopFocusRing ring,
    bool within,
  ) {
    final w = ring.width;
    final centre = within ? at.deflate(w / 2) : at.inflate(w / 2);
    if (centre.isEmpty) return;
    final path = outline.getOuterPath(centre, textDirection: direction);
    final paint = Paint()
      ..color = ring.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..isAntiAlias = false;
    for (final contour in path.computeMetrics()) {
      for (var from = 0.0; from < contour.length; from += 2 * w) {
        canvas.drawPath(
          contour.extractPath(from, math.min(from + w, contour.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HighlightPainter old) =>
      shape != old.shape ||
      hover != old.hover ||
      ring != old.ring ||
      direction != old.direction ||
      inside != old.inside ||
      beyond != old.beyond ||
      insideColor != old.insideColor ||
      bare != old.bare ||
      skip != old.skip;
}
