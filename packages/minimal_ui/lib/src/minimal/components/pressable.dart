import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../component_themes.dart';
import '../internal/kit_paint.dart';
import '../internal/menu_keys.dart';
import '../internal/styled.dart';
import '../internal/tap_band.dart';
import '../theme.dart';

/// Adds keyboard, pointer and screen reader support to a custom control.
///
/// Enter, Space and a tap invoke [onPressed]. A pressed control takes a
/// light wash. Keyboard focus draws a 2 px outline using the theme’s accent.
/// [shape] or [radius] determines both outlines. Supply [face] and [ink] for
/// a colored surface so feedback can preserve its label contrast.
///
/// Use [builder] to resolve the child's appearance for each [WidgetState].
/// Set [enabled] to false for an unavailable control. With [enabled] true
/// and [onPressed] null, the child handles its own interactions.
///
/// The hit target is at least 44 px for touch and 24 px for a pointer.
/// [tapAlignment] places the painted control inside it. A larger control
/// can provide a shared target for its parts with [tapTarget] false.
///
/// [toggled] and [checked] announce the value on the control's own node,
/// which then reads as a switch, a checkbox or a radio, not as a button.
/// Use [focusable] false for a part of a composite focus stop, such as a
/// tab. [focusInside] places the outline within clipped surfaces. Supply
/// [focusNode] to move focus programmatically.
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
    this.inMutuallyExclusiveGroup = false,
    this.link = false,
    this.focusable = true,
    this.focusInside,
    this.focusNode,
    this.autofocus = false,
    this.face,
    this.ink,
    this.outset,
    this.tapTarget = true,
    this.tapAlignment,
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

  /// Whether the control can receive input. A disabled control is dimmed
  /// and announces its unavailable state to screen readers.
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
  /// or an on/off button that is on, announced on the control's own node;
  /// null for a control that is neither. It stays a button.
  final bool? selected;

  /// The on/off state of a switch, announced on the control's own node;
  /// null for a control that is not a switch.
  final bool? toggled;

  /// The checked state of a checkbox-like control, announced on the
  /// control's own node; null for a control that is not one.
  final bool? checked;

  /// Whether [checked] is one choice of a set where one is chosen (a radio),
  /// announced on the control's own node: a screen reader says a radio
  /// button, not a checkbox.
  final bool inMutuallyExclusiveGroup;

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

  /// {@macro minimal.autofocus}
  final bool autofocus;

  /// The fill the press wash lands on (a filled button's), and [ink] its
  /// words' ink: the wash deepens a light or mid face and lifts a dark one
  /// ([minimalPressInk]). Null reads the page's ground and ink.
  final Color? face;

  /// The ink of the [face]'s words.
  final Color? ink;

  /// Whether the control is laid out at least the tap-target floor
  /// ([DesignTapTarget]); false for a part whose larger control lays the
  /// target out round it.
  final bool tapTarget;

  /// Where the face stands in its tap target, the target growing away from
  /// the edges it names (mirrored right to left):
  /// [AlignmentDirectional.centerStart] keeps a face on its start keyline.
  /// Null: the part's own placement under a [MinimalTapAlignment], else
  /// centred.
  final AlignmentGeometry? tapAlignment;

  /// How far the press wash and the keyboard ring reach past the child's
  /// box on each side, [shape] drawn on the grown box; the child's layout
  /// and hit area stay its own. A flush form row's words line up with the
  /// form's other labels at rest, and its feedback still stands clear of
  /// them. Null keeps the feedback on the box.
  final EdgeInsetsGeometry? outset;

  @override
  State<MinimalPressable> createState() => _MinimalPressableState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<
          Widget Function(BuildContext context, Set<WidgetState> states)
        >.has('builder', builder),
      )
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(
        EnumProperty<HitTestBehavior>(
          'behavior',
          behavior,
          defaultValue: HitTestBehavior.opaque,
        ),
      )
      ..add(DoubleProperty('radius', radius, defaultValue: null))
      ..add(
        DiagnosticsProperty<OutlinedBorder>('shape', shape, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<MinimalStyle>('style', style, defaultValue: null),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('selected', selected, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('toggled', toggled, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('checked', checked, defaultValue: null))
      ..add(
        FlagProperty(
          'inMutuallyExclusiveGroup',
          value: inMutuallyExclusiveGroup,
          ifTrue: 'inMutuallyExclusiveGroup',
        ),
      )
      ..add(FlagProperty('link', value: link, ifTrue: 'link'))
      ..add(
        FlagProperty(
          'focusable',
          value: focusable,
          ifFalse: 'focusable: false',
        ),
      )
      ..add(
        DiagnosticsProperty<bool>(
          'focusInside',
          focusInside,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(ColorProperty('face', face, defaultValue: null))
      ..add(ColorProperty('ink', ink, defaultValue: null))
      ..add(
        FlagProperty(
          'tapTarget',
          value: tapTarget,
          ifFalse: 'tapTarget: false',
        ),
      )
      ..add(
        DiagnosticsProperty<AlignmentGeometry>(
          'tapAlignment',
          tapAlignment,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'outset',
          outset,
          defaultValue: null,
        ),
      );
  }
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
    // The ring, unless the row it presses paints the keyboard's place (an
    // open menu's item, on the muted fill).
    final ringed = _focus && enabled && !MinimalPaintsFocus.of(context);
    // The look's wash: the ink at 8% while pressed. Hover leaves the face
    // as it is; an app's overlay may say otherwise.
    final wash =
        widget.style?.overlay?.resolve(states) ??
        minimalPressInk(
          t,
          face: widget.face,
          faceInk: widget.ink,
        ).withValues(alpha: enabled && _down ? 0.08 : 0.0);
    // The tap target is the outermost layer: laid out at the floor, so the
    // area a tap reaches is the box a screen reader outlines (the node
    // below spans it).
    final control = Semantics(
      container: true,
      // A switch, a checkbox or a radio is that control alone, as Flutter's
      // are; the rest are buttons, or links.
      button:
          !widget.link &&
              widget.checked == null &&
              widget.toggled == null &&
              !widget.inMutuallyExclusiveGroup
          ? true
          : null,
      link: widget.link,
      enabled: enabled,
      selected: widget.selected,
      toggled: widget.toggled,
      checked: widget.checked,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup ? true : null,
      label: widget.semanticLabel,
      child: _interactionScope(
        FocusableActionDetector(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          enabled: enabled,
          includeFocusSemantics: widget.focusable,
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onShowFocusHighlight: (v) => setState(() => _focus = v),
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onPressed?.call();
                return null;
              },
            ),
            // In a browser Enter is a button's press alone
            // (ButtonActivateIntent), as on the web: a button, a toggle
            // button or a link takes it; a checkbox or a radio keeps to
            // Space.
            if (widget.checked == null)
              ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
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
              opacity: enabled
                  ? 1
                  : minimalDisabledOpacity(
                      ink: widget.ink,
                      face: widget.face,
                      ground: minimalGround(context),
                    ),
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
                        side: ringed
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
                        ring: ringed ? t.ring : null,
                        ground: minimalGround(context),
                        width: t.focusWidth,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
    if (!widget.tapTarget) return control;
    return minimalInlineNode(
      context,
      DesignTapTarget(
        alignment:
            widget.tapAlignment ??
            MinimalTapAlignment.maybeOf(context) ??
            AlignmentDirectional.center,
        // The target's own node says whether the control is enabled, not
        // only the node it merges: Flutter's contrast guideline reads a
        // node's own flags, and would hold a disabled control's dimmed words
        // to the contrast of live ones.
        child: Semantics(enabled: enabled, child: control),
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

  Widget _interactionScope(Widget child) => MouseRegion(
    // A pointer can hover even when touch was the last input. Keyboard
    // highlight mode only controls the focus outline.
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: widget.focusable ? child : ExcludeFocus(child: child),
  );
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
@Deprecated(
  'Not needed: since 0.2.0 each Minimal control lays its own tap target out '
  '(ui_core\'s DesignTapTarget), whatever its parent. Remove the wrapper.',
)
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('line', line, defaultValue: null))
      ..add(DoubleProperty('inset', inset, defaultValue: 4));
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
