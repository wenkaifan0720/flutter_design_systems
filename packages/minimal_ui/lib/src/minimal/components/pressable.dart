import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../theme.dart';

/// Minimal's press feedback for a surface the kit does not already cover
/// — screens rarely need it, because [MinimalButton], [MinimalIconButton] and
/// the rows carry it already.
///
/// The feedback is the instrument's own: no scale, no bounce — the surface
/// takes a faint wash of the ink while pressed, dims when disabled, and
/// draws the [MinimalThemeData.ring] (`t.focusWidth`, 2 px) outside
/// its edge, past 2 px of the ground it stands on, when the keyboard
/// focuses it. A hovering pointer changes
/// nothing: [style]'s `overlay` is the hook for an app that wants a hover
/// wash. Enter and Space activate it like a tap. [shape] (or [radius])
/// outlines the wash and the ring; it defaults to the theme's
/// `shapes.small`.
///
/// [builder] builds the child for the control's states (pressed, hovered,
/// focused, disabled, selected), for a part whose face resolves a
/// `MinimalStyle` for them.
///
/// DISABLED IS SOMETHING A CALLER SAYS, NOT SOMETHING WE INFER. A pressable
/// with no [onPressed] that is not declared disabled is not a control at all:
/// it renders its bare child and lets taps through. A component that owns a
/// control API passes `enabled: onPressed != null`.
///
/// Also the kit's touch-target guarantee: taps within a
/// [MinimalLayout.minHitTarget] square centred on the control land, however
/// small it paints — a 32 px bar button still LOOKS 32 px. The margin lives
/// in hit testing alone, so it reaches only as far as the boxes around the
/// control: a parent that hugs a small control (a 28 px strip, a bare
/// `Row` of pills) stands it in a [MinimalHitTarget] to hand the margin on.
///
/// [toggled] and [checked] put a switch's or a checkbox's state on the
/// control's own node. `focusable: false` is a part of a larger focus stop
/// (a segment of a track, a tab of a strip): still a tap and a screen
/// reader's button, never a keyboard stop, and it announces no focus.
/// `focusInside: true` draws the ring inside the edge, for a full-bleed
/// surface (a row, a table header) that has no outside to draw on, or one a
/// parent clips; a square-cornered surface (`radius: 0`) takes it by default.
/// A [focusNode] lets a form move focus to the control itself (the first
/// agreement still to tick).
///
/// ```dart
/// MinimalPressable(onPressed: open, shape: t.shapes.medium, child: tile)
/// ```
class MinimalPressable extends StatefulWidget {
  /// Makes [child] pressable.
  const MinimalPressable({
    super.key,
    this.child,
    this.builder,
    this.onPressed,
    this.enabled = true,
    this.behavior = HitTestBehavior.opaque,
    this.radius,
    this.shape,
    this.style,
    this.semanticLabel,
    this.selected,
    this.toggled,
    this.checked,
    this.link = false,
    this.focusable = true,
    this.focusInside,
    this.focusNode,
    this.autofocus = false,
    this.face,
    this.ink,
    this.outset,
  }) : assert(
         (child == null) != (builder == null),
         'a pressable takes a child or a builder, one of them',
       );

  /// What the control shows, whatever its state.
  final Widget? child;

  /// What the control shows for its states, in place of [child].
  final Widget Function(BuildContext context, Set<WidgetState> states)? builder;

  /// Its press; null disables it.
  final VoidCallback? onPressed;

  /// Whether this is a control that is currently UNAVAILABLE. False dims the
  /// child and swallows taps; true with no [onPressed] is not a control at all
  /// and renders as its bare child.
  final bool enabled;

  /// How it takes hits on its empty parts.
  final HitTestBehavior behavior;

  /// The corner radius of the press wash and the focus ring; null takes
  /// [shape], else the theme's `shapes.small`.
  final double? radius;

  /// The outline of the press wash and the focus ring, any
  /// [OutlinedBorder]; wins over [radius].
  final OutlinedBorder? shape;

  /// The part's style, of which this reads two slots for the control's
  /// states: `overlay` (the wash; the look's is the ink at 8% while
  /// pressed, nothing hovered) and `shape` (wins over [shape]).
  final MinimalStyle? style;

  /// What a screen reader announces, for a control whose child says nothing
  /// in words (an icon). A child with text announces that text.
  final String? semanticLabel;

  /// Whether this control is the current one of a set (a tab, a segment),
  /// announced on the control's own node; null for a control that is not
  /// one of a set.
  final bool? selected;

  /// The on/off state of a switch, announced on the control's own node;
  /// null for a control that is not a switch.
  final bool? toggled;

  /// The checked state of a checkbox-like control, announced on the
  /// control's own node; null for a control that is not one.
  final bool? checked;

  /// Announce a link rather than a button: words that go somewhere
  /// ([MinimalLink]), on the control's own node.
  final bool link;

  /// Whether the control is a keyboard focus stop of its own. False for a
  /// part of a larger stop — a segment of a track, a tab of a strip — which
  /// then announces no focus either.
  final bool focusable;

  /// Draw the focus ring inside the edge rather than outside it: a
  /// full-bleed or clipped surface's register. Null draws it inside for a
  /// surface given `radius: 0` (a full-bleed row) and outside otherwise.
  final bool? focusInside;

  /// The control's focus node, for a caller that moves focus to it; null
  /// keeps one of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  /// The fill the press wash lands on (a filled button's), and [ink] its
  /// words' ink: the wash deepens a light or mid face and lifts a dark one
  /// ([minimalPressInk]). Null reads the page's ground and ink.
  final Color? face;

  /// The ink of the [face]'s words.
  final Color? ink;

  /// How far the press wash and the keyboard ring reach past the child's
  /// box on each side, [shape] drawn on the grown box; the child's layout
  /// and hit area stay its own. A flush form row's words line up with the
  /// form's other labels at rest, and its feedback still stands clear of
  /// them. Null keeps the feedback on the box.
  final EdgeInsetsGeometry? outset;

  @override
  State<MinimalPressable> createState() => _MinimalPressableState();
}

class _MinimalPressableState extends State<MinimalPressable> {
  bool _down = false;
  bool _hover = false;
  bool _focus = false;

  void _setDown(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    // Nothing wired and nothing disabled: not a control, so no wash, no
    // focus stop and no tap target.
    final enabled = widget.enabled && widget.onPressed != null;
    final states = minimalStates(
      enabled: enabled,
      pressed: enabled && _down,
      hovered: enabled && _hover,
      focused: enabled && _focus,
      selected:
          (widget.selected ?? false) ||
          (widget.toggled ?? false) ||
          (widget.checked ?? false),
    );
    final child = widget.child ?? widget.builder!(context, states);
    if (widget.enabled && widget.onPressed == null) return child;
    final t = context.minimalTheme;
    final shape =
        widget.style?.shape?.resolve(states) ??
        widget.shape ??
        (widget.radius == null
            ? t.shapes.small
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.radius!),
              ));
    final inside = widget.focusInside ?? widget.radius == 0;
    // The look's wash: the ink at 8% while pressed. Hover leaves the face
    // as it is; an app's overlay may say otherwise.
    final wash =
        widget.style?.overlay?.resolve(states) ??
        minimalPressInk(
          t,
          face: widget.face,
          faceInk: widget.ink,
        ).withValues(alpha: enabled && _down ? 0.08 : 0.0);
    // The inflated hit region is the outermost layer: a render box only
    // hit-tests a child the point falls inside, so anything wrapped around
    // it would cut the margin off again.
    // It is also the control's node for a screen reader (the Semantics below
    // folds into it), as big as the region a tap lands in.
    return _PressTarget(
      inset: _nudge,
      child: Semantics(
        button: !widget.link,
        link: widget.link,
        enabled: enabled,
        selected: widget.selected,
        toggled: widget.toggled,
        checked: widget.checked,
        label: widget.semanticLabel,
        child: _focusScope(
          FocusableActionDetector(
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            enabled: enabled,
            includeFocusSemantics: widget.focusable,
            mouseCursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onShowFocusHighlight: (v) => setState(() => _focus = v),
            onShowHoverHighlight: (v) => setState(() => _hover = v),
            actions: <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  widget.onPressed?.call();
                  return null;
                },
              ),
            },
            child: GestureDetector(
              behavior: widget.behavior,
              onTap: enabled ? widget.onPressed : null,
              onTapDown: enabled ? (_) => _setDown(true) : null,
              onTapUp: enabled ? (_) => _setDown(false) : null,
              onTapCancel: enabled ? () => _setDown(false) : null,
              child: AnimatedOpacity(
                opacity: enabled ? 1 : 0.45,
                duration: context.minimalStill
                    ? Duration.zero
                    : MinimalMotion.fast,
                child: _reach(
                  context,
                  child,
                  // Outside the edge the ring stands past a gap of the
                  // ground, so it reads on a face filled in its own ink.
                  inside
                      ? minimalFrame(
                          shape,
                          fill: wash,
                          side: _focus && enabled
                              ? BorderSide(
                                  color: t.ring,
                                  width: t.focusWidth,
                                  strokeAlign: BorderSide.strokeAlignInside,
                                )
                              : BorderSide.none,
                        )
                      : minimalRingFrame(
                          shape,
                          wash: wash,
                          ring: _focus && enabled ? t.ring : null,
                          ground: minimalGround(context),
                          width: t.focusWidth,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// [child] wearing [feedback] (the wash and the ring): over its own box,
  /// or with [MinimalPressable.outset] over that box grown by the outset,
  /// the child laid out as it would be without it.
  Widget _reach(BuildContext context, Widget child, Decoration feedback) {
    final outset = widget.outset?.resolve(Directionality.of(context));
    if (outset == null || outset == EdgeInsets.zero) {
      return AnimatedContainer(
        duration: context.minimalStill ? Duration.zero : MinimalMotion.fast,
        curve: MinimalMotion.out,
        foregroundDecoration: feedback,
        child: child,
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned(
          left: -outset.left,
          top: -outset.top,
          right: -outset.right,
          bottom: -outset.bottom,
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: context.minimalStill
                  ? Duration.zero
                  : MinimalMotion.fast,
              curve: MinimalMotion.out,
              foregroundDecoration: feedback,
            ),
          ),
        ),
      ],
    );
  }

  /// How far inside the edge a tap in the inflated margin lands: a hair, so
  /// the child's own gesture detector takes it.
  static const double _nudge = 0.1;

  /// A part of a larger focus stop is kept out of keyboard traversal.
  Widget _focusScope(Widget child) =>
      widget.focusable ? child : ExcludeFocus(child: child);
}

/// Hands the [MinimalLayout.minHitTarget] margin on through a parent that
/// hugs small controls — a 28 px strip of pills, a bare `Row` holding a
/// switch, a 20 px content line inside a padded row. A render box rejects
/// every point outside its own size before any child sees it, so a control's
/// own inflated target ([MinimalPressable]) is cut off wherever an ancestor is
/// smaller than 44 px; wrapping that ancestor here restores it.
///
/// It pads the HIT-TEST region only, never layout or paint. [line] is the
/// height of one line of controls (a pill row's 28 px); null takes the
/// wrapped box's own height. A point within the margin that brings a line up
/// to 44 is forwarded [inset] inside the box's nearest edge, past its border
/// and padding, where one of its controls takes it. Only the margin a line
/// needs is added: a box already 44 px tall gains nothing.
///
/// ```dart
/// MinimalHitTarget(line: 28, child: Row(children: pills))
/// ```
class MinimalHitTarget extends SingleChildRenderObjectWidget {
  /// Pads [child]'s hit area to 44 px.
  const MinimalHitTarget({super.key, this.line, this.inset = 4, super.child});

  /// The height of one line of controls; null takes the box's own height.
  final double? line;

  /// How far inside the box's nearest edge a margin point is forwarded.
  final double inset;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHitTarget(line, inset);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderHitTarget)
      ..line = line
      ..inset = inset;
  }
}

class _RenderHitTarget extends RenderProxyBox {
  _RenderHitTarget(this.line, this.inset);

  double? line;
  double inset;

  static const double _min = MinimalLayout.minHitTarget;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (size.contains(position)) {
      return super.hitTest(result, position: position);
    }
    final dx = ((_min - size.width) / 2).clamp(0.0, double.infinity);
    final dy = ((_min - (line ?? size.height)) / 2).clamp(0.0, double.infinity);
    if (position.dx < -dx ||
        position.dy < -dy ||
        position.dx > size.width + dx ||
        position.dy > size.height + dy) {
      return false;
    }
    double into(double v, double extent) {
      final edge = inset < extent / 2 ? inset : extent / 2;
      return v.clamp(edge, extent - edge);
    }

    return super.hitTest(
      result,
      position: Offset(
        into(position.dx, size.width),
        into(position.dy, size.height),
      ),
    );
  }
}

/// A pressable's own [MinimalHitTarget], which is also its semantics node:
/// the node's rect is the [MinimalLayout.minHitTarget] square a tap lands in,
/// so touch exploration finds a 32 px button wherever a finger would press it.
class _PressTarget extends MinimalHitTarget {
  const _PressTarget({super.inset, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPressTarget(line, inset);
}

class _RenderPressTarget extends _RenderHitTarget {
  _RenderPressTarget(super.line, super.inset);

  @override
  Rect get semanticBounds => Rect.fromCenter(
    center: size.center(Offset.zero),
    width: size.width < _RenderHitTarget._min
        ? _RenderHitTarget._min
        : size.width,
    height: size.height < _RenderHitTarget._min
        ? _RenderHitTarget._min
        : size.height,
  );

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
  }
}
