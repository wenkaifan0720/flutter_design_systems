// Controls, moulded from the plaster. Off is raised, in ink. Latched is pressed in AND carries the pigment AND says so: an
// icon or an LED, heavier words. The shadow is the third cue and never the only one, so a control still reads with every
// shadow gone (`NeumorphicFlatScope`). A control that isn't an object takes the control scale: 8 to 12, no pills.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';

import 'glyphs.dart';
import 'chrome_metrics.dart';

import 'frames.dart';
import 'component_themes.dart';
import 'styled.dart';
import 'shapes.dart';
import 'knobs.dart';
import 'editing.dart';
import 'localizations.dart';
import 'internal/cell_bank.dart';
import 'internal/error_line.dart';
import 'internal/geometry.dart';
import 'internal/reach.dart';
import 'internal/text_entry.dart';
import 'layout.dart';
import 'ornaments.dart';
import 'theme.dart';
import 'internal/cap_label.dart';
import 'tell.dart' show NeumorphicCircularProgressIndicator;
import 'internal/out_of_use.dart';

/// Makes a face a control: the design kit's pressable under it, so Tab reaches it, Enter and Space press it, and one
/// semantics node names it. Keyboard focus lifts the face off the wall and warms its lit side with the pigment; a
/// pointer's focus changes nothing.
///
/// The pointer changes nothing on the face: a moulded surface answers a press with its relief, not a hover with a
/// tint. Over an enabled control the pointer becomes [SystemMouseCursors.click] (or [mouseCursor]), over a disabled
/// one [SystemMouseCursors.basic]. [WidgetState.hovered] still reaches every style and builder, so an app can draw a
/// hover of its own through a style's `overlay`.
///
/// A press sinks the face a pixel and presses its exact outline in (a groove's paired inset), unless [pressRelief] is
/// false because the face draws its own depression. [onDown] hears the press go in and come out, for a face that
/// sinks. [radius] and [round] say which outline the lift follows.
///
/// ```dart
/// NeumorphicTap(onPressed: open, label: 'Open', child: tile)
/// ```
class NeumorphicTap extends StatefulWidget {
  /// Creates a [NeumorphicTap].
  const NeumorphicTap({
    super.key,
    required this.child,
    this.onPressed,
    this.label,
    this.semanticValue,
    this.semanticHint,
    this.enabled,
    this.selected,
    this.expanded,
    this.checked,
    this.toggled,
    this.mixed = false,
    this.inMutuallyExclusiveGroup = false,
    this.onDown,
    this.onStatesChanged,
    this.radius = NeumorphicRadii.control,
    this.round = false,
    this.focusInset = 0,
    this.focusSize,
    this.faceOutset = EdgeInsets.zero,
    this.focusNode,
    this.focusReach = 1,
    this.autofocus = false,
    this.button = true,
    this.onKeyEvent,
    this.style,
    this.themeStyle,
    this.shape,
    this.showFocus = true,
    this.pressRelief = true,
    this.mouseCursor,
  });

  /// The content placed inside this component.
  final Widget child;

  /// Whether keyboard focus lifts the face. False when the face lifts the part that moves itself (the slider's thumb),
  /// or shows focus its own way.
  final bool showFocus;

  /// Whether a press draws the groove's paired inset over the face's outline. False for a face that already goes in
  /// (a moulded button, a pressed cell), so the depth is never drawn twice.
  final bool pressRelief;

  /// The pointer over the enabled control; [SystemMouseCursors.click] when null. A disabled control always shows
  /// [SystemMouseCursors.basic].
  final MouseCursor? mouseCursor;

  /// The control's own state-resolved wash and outline.
  final NeumorphicStyle? style;

  /// The component theme below [style].
  final NeumorphicStyle? themeStyle;

  /// The role's shape when neither style overrides it.
  final OutlinedBorder? shape;

  /// Called when the item is activated.
  final VoidCallback? onPressed;

  /// An accessible name replacing the descendant semantics when supplied.
  final String? label;

  /// The current value announced by accessibility services.
  final String? semanticValue;

  /// An additional description of the result of activation.
  final String? semanticHint;

  /// Overrides whether the pressable is enabled; null follows its callback.
  final bool? enabled;

  /// Whether this item is selected.
  final bool? selected;

  /// The expanded state announced for a disclosure control.
  final bool? expanded;

  /// The checked state announced for a checkbox.
  final bool? checked;

  /// The on/off state announced for a switch.
  final bool? toggled;

  /// Whether to announce a mixed checkbox state.
  final bool mixed;

  /// Whether this is one choice in a mutually exclusive group.
  final bool inMutuallyExclusiveGroup;

  /// Reports when the press enters or leaves its down state.
  final ValueChanged<bool>? onDown;

  /// Reports the full pressable state set when an interaction changes it.
  final ValueChanged<Set<WidgetState>>? onStatesChanged;

  /// The corner the focus lift and the press follow.
  final double radius;

  /// A circle: the lift and the press are round.
  final bool round;

  /// The inset of the focus outline from the target bounds.
  final double focusInset;

  /// Optional dimensions of the focus outline within the target.
  final Size? focusSize;

  /// How far the face runs past the target, side by side, for a part whose face is wider than what it lays out: a
  /// grouped list's row is a band of its card, a breath inside its rim, so its lift and its press are the row's whole
  /// outline and not its words'. The lift, the press and an app's wash follow it; the target stays the child.
  final EdgeInsetsGeometry faceOutset;

  /// An optional externally owned focus node.
  final FocusNode? focusNode;

  /// How far keyboard focus lifts the face: 1 for a part on the wall, less for a small one among others (a cell in its
  /// bank, an item in a menu).
  final double focusReach;

  /// Whether to request focus when first attached.
  final bool autofocus;

  /// Whether to expose the button semantic role.
  final bool button;

  /// An optional keyboard handler for keys not handled by activation.
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;
  @override
  State<NeumorphicTap> createState() => _NeumorphicTapState();
}

class _NeumorphicTapState extends State<NeumorphicTap> {
  bool _pressed = false;

  void _states(Set<WidgetState> states) {
    widget.onStatesChanged?.call(states);
    final now = states.contains(WidgetState.pressed);
    if (now == _pressed) return;
    _pressed = now;
    widget.onDown?.call(now);
  }

  @override
  Widget build(BuildContext context) {
    return DesignPressable(
      onPressed: widget.onPressed,
      semanticLabel: widget.label,
      semanticValue: widget.semanticValue,
      semanticHint: widget.semanticHint,
      enabled: widget.enabled,
      excludeSemantics: widget.label != null,
      semanticSelected: widget.selected,
      expanded: widget.expanded,
      checked: widget.checked,
      toggled: widget.toggled,
      mixed: widget.mixed,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup,
      selected: widget.selected ?? false,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      button: widget.button,
      onKeyEvent: widget.onKeyEvent,
      enableFeedback: false,
      mouseCursor: WidgetStateMouseCursor.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? SystemMouseCursors.basic
            : widget.mouseCursor ?? SystemMouseCursors.click,
      ),
      onStatesChanged: widget.onDown == null && widget.onStatesChanged == null
          ? null
          : _states,
      builder: (context, states, child) => NeumorphicTapFace(
        states: states,
        style: widget.style,
        themeStyle: widget.themeStyle,
        shape: widget.shape,
        radius: widget.radius,
        round: widget.round,
        focusInset: widget.focusInset,
        focusSize: widget.focusSize,
        faceOutset: widget.faceOutset,
        focusReach: widget.focusReach,
        showFocus: widget.showFocus,
        pressRelief: widget.pressRelief,
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// The face a [NeumorphicTap] paints for its [states], for a part whose pressable is not a [NeumorphicTap]: a ui_core
/// behaviour's item (a toggle group's cell, a menu bar's item, a calendar's day) gets its states from ui_core and wears
/// the look's own relief, focus lift and press through this. Hidden from the barrel.
///
/// ```dart
/// NeumorphicTapFace(states: states, shape: cell.border, child: label)
/// ```
class NeumorphicTapFace extends StatelessWidget {
  /// The face of a control in [states].
  const NeumorphicTapFace({
    super.key,
    required this.states,
    this.child,
    this.style,
    this.themeStyle,
    this.shape,
    this.radius = NeumorphicRadii.control,
    this.round = false,
    this.focusInset = 0,
    this.focusSize,
    this.faceOutset = EdgeInsets.zero,
    this.focusReach = 1,
    this.showFocus = true,
    this.pressRelief = true,
  });

  /// The control's states: pressed sinks it, keyboard focus lifts it.
  final Set<WidgetState> states;

  /// What the face shows.
  final Widget? child;

  /// See [NeumorphicTap.style].
  final NeumorphicStyle? style;

  /// See [NeumorphicTap.themeStyle].
  final NeumorphicStyle? themeStyle;

  /// See [NeumorphicTap.shape].
  final OutlinedBorder? shape;

  /// See [NeumorphicTap.radius].
  final double radius;

  /// See [NeumorphicTap.round].
  final bool round;

  /// See [NeumorphicTap.focusInset].
  final double focusInset;

  /// See [NeumorphicTap.focusSize].
  final Size? focusSize;

  /// See [NeumorphicTap.faceOutset].
  final EdgeInsetsGeometry faceOutset;

  /// See [NeumorphicTap.focusReach].
  final double focusReach;

  /// See [NeumorphicTap.showFocus].
  final bool showFocus;

  /// See [NeumorphicTap.pressRelief].
  final bool pressRelief;

  @override
  Widget build(BuildContext context) {
    final faceOutset = this.faceOutset.resolve(Directionality.of(context));
    final theme = NeumorphicTheme.of(context);
    final motion = NeumorphicMotion.of(context);
    final look = NeumorphicStyleOf([style, themeStyle], states);
    return AnimatedNeumorphicShape(
      shape:
          look.shape ??
          shape ??
          (round ? theme.shapes.circle() : theme.shapes.corner(radius)),
      builder: (context, border) {
        final faceSize = focusSize == null
            ? null
            : Size(
                math.max(focusSize!.width, look.minimumSize?.width ?? 0),
                math.max(focusSize!.height, look.minimumSize?.height ?? 0),
              );
        Widget sunk(Widget? content) => TweenAnimationBuilder<double>(
          tween: Tween(end: states.contains(WidgetState.pressed) ? 1 : 0),
          duration: motion.press,
          curve: motion.enter,
          child: content,
          builder: (context, sink, child) =>
              Transform.translate(offset: Offset(0, sink), child: child),
        );
        // A face that runs past the child is its holder's (a grouped list's band of its card): it stays where the
        // card is when pressed, and only the words go in.
        final held = faceOutset != EdgeInsets.zero;
        // Keyboard focus lifts the face: never a line, and never sunk, since pressed in means on. The wrapper stays
        // in the tree: inserting it only on focus remounts stateful faces and resets their value animations.
        Widget face = TweenAnimationBuilder<double>(
          tween: Tween(
            end: showFocus && states.contains(WidgetState.focused) ? 1 : 0,
          ),
          duration: motion.state,
          curve: motion.enter,
          child: held ? sunk(child) : child,
          builder: (context, lift, child) => CustomPaint(
            foregroundPainter: lift == 0
                ? null
                : _FocusLift(
                    theme.colors,
                    theme.elevation,
                    lift,
                    focusReach,
                    radius,
                    round,
                    focusInset,
                    faceSize,
                    border,
                    faceOutset,
                  ),
            child: child,
          ),
        );
        // No wash by default, hovered or pressed: an app's own `overlay` style is the only tint, drawn in the
        // face's exact outline for the states it resolves.
        // The wrapper stays in the tree either way, so a face never remounts when the wash comes and goes.
        final overlay = look.overlay?.resolve(states);
        face = CustomPaint(
          foregroundPainter: overlay == null || overlay.a == 0
              ? null
              : _Overlay(
                  overlay,
                  radius,
                  round,
                  focusInset,
                  faceSize,
                  border,
                  faceOutset,
                ),
          child: face,
        );
        // Always in the tree, like the lift's and the wash's wrappers: a part that turns its relief off when it is
        // chosen (a pressed-in cell) keeps its face mounted, and its own motion with it.
        face = TweenAnimationBuilder<double>(
          tween: Tween(
            end: pressRelief && states.contains(WidgetState.pressed) ? 1 : 0,
          ),
          duration: motion.press,
          curve: motion.enter,
          child: face,
          builder: (context, depth, child) => CustomPaint(
            foregroundPainter: depth == 0 || NeumorphicFlatScope.of(context)
                ? null
                : _PressRelief(
                    theme.colors,
                    theme.elevation,
                    depth,
                    radius,
                    round,
                    focusInset,
                    faceSize,
                    border,
                    faceOutset,
                  ),
            child: child,
          ),
        );
        if (!held) face = sunk(face);
        face = RepaintBoundary(child: face);
        return NeumorphicStatesScope(
          states: states,
          child: _TapTarget(
            minSize: Size.square(NeumorphicChromeMetrics.targetSize),
            child: face,
          ),
        );
      },
    );
  }
}

/// Keyboard focus on the face: it lifts off the wall, its lit side warmed by the pigment ([neumorphicPaintFocusLift]).
class _FocusLift extends CustomPainter {
  const _FocusLift(
    this.c,
    this.elevation,
    this.amount,
    this.reach,
    this.radius,
    this.round,
    this.inset,
    this.faceSize,
    this.border,
    this.outset,
  );
  final NeumorphicColors c;
  final NeumorphicElevation elevation;
  final double amount, reach;
  final Size? faceSize;
  final OutlinedBorder? border;
  final double radius, inset;
  final bool round;
  final EdgeInsets outset;
  @override
  void paint(Canvas canvas, Size size) {
    final face = _faceBox(size, inset, faceSize, outset);
    neumorphicPaintFocusLift(
      canvas,
      border?.getOuterPath(face) ??
          (Path()..addRRect(
            RRect.fromRectAndRadius(
              face,
              Radius.circular(round ? face.shortestSide / 2 : radius),
            ),
          )),
      c,
      amount: amount,
      reach: reach,
      elevation: elevation,
    );
  }

  @override
  bool shouldRepaint(_FocusLift o) =>
      o.c != c ||
      o.elevation != elevation ||
      o.amount != amount ||
      o.reach != reach ||
      o.radius != radius ||
      o.round != round ||
      o.inset != inset ||
      o.faceSize != faceSize ||
      o.border != border ||
      o.outset != outset;
}

/// The face's box in a target of [size]: the target moved in by [inset] and out by [outset], or [faceSize] centred.
Rect _faceBox(Size size, double inset, Size? faceSize, EdgeInsets outset) =>
    faceSize == null
    ? outset.inflateRect((Offset.zero & size).deflate(inset))
    : Rect.fromCenter(
        center: size.center(Offset.zero),
        width: faceSize.width,
        height: faceSize.height,
      );

/// The face's outline for a highlight or a pressed inset: the part's own border, else its fallback radius.
Path _faceOutline(
  Size size,
  double radius,
  bool round,
  double inset,
  Size? faceSize,
  OutlinedBorder? border,
  EdgeInsets outset,
) {
  final box = _faceBox(size, inset, faceSize, outset);
  return border?.getOuterPath(box) ??
      (Path()..addRRect(
        RRect.fromRectAndRadius(
          box,
          Radius.circular(round ? box.shortestSide / 2 : radius),
        ),
      ));
}

/// An app's own state wash, in the face's exact outline. The look draws none.
class _Overlay extends CustomPainter {
  const _Overlay(
    this.color,
    this.radius,
    this.round,
    this.inset,
    this.faceSize,
    this.border,
    this.outset,
  );
  final Color color;
  final double radius, inset;
  final bool round;
  final Size? faceSize;
  final OutlinedBorder? border;
  final EdgeInsets outset;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    _faceOutline(size, radius, round, inset, faceSize, border, outset),
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_Overlay old) =>
      old.color != color ||
      old.radius != radius ||
      old.round != round ||
      old.inset != inset ||
      old.faceSize != faceSize ||
      old.border != border ||
      old.outset != outset;
}

/// A press in the look's own idiom: the groove's paired inset, light above and dark below, inside the face's exact
/// outline and faded in by [depth]. No tint.
class _PressRelief extends CustomPainter {
  const _PressRelief(
    this.c,
    this.elevation,
    this.depth,
    this.radius,
    this.round,
    this.inset,
    this.faceSize,
    this.border,
    this.outset,
  );
  final NeumorphicColors c;
  final NeumorphicElevation elevation;
  final double depth, radius, inset;
  final bool round;
  final Size? faceSize;
  final OutlinedBorder? border;
  final EdgeInsets outset;
  @override
  void paint(Canvas canvas, Size size) {
    if (elevation.depth == 0) return;
    final shape = _faceOutline(
      size,
      radius,
      round,
      inset,
      faceSize,
      border,
      outset,
    );
    final box = shape.getBounds();
    Paint blurred(Color color) => Paint()
      ..isAntiAlias = true
      ..color = color.withValues(alpha: color.a * depth * elevation.strength)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.5 * elevation.depth);
    Path outside(Offset by) => Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(box.inflate(24))
      ..addPath(shape, by * elevation.depth);
    canvas.save();
    canvas.clipPath(shape);
    canvas.drawPath(outside(const Offset(-3, -3)), blurred(c.highlight));
    canvas.drawPath(outside(const Offset(3, 3)), blurred(c.shadowInset));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PressRelief old) =>
      old.c != c ||
      old.elevation != elevation ||
      old.depth != depth ||
      old.radius != radius ||
      old.round != round ||
      old.inset != inset ||
      old.faceSize != faceSize ||
      old.border != border ||
      old.outset != outset;
}

/// A raised part that goes in under a finger.
class _Moulded extends StatefulWidget {
  const _Moulded({
    required this.builder,
    this.style,
    this.themeStyle,
    this.shape,
    this.onPressed,
    this.label,
    this.selected,
    this.busy = false,
    this.showBusy = true,
    this.focusNode,
    this.autofocus = false,
    this.radius = NeumorphicRadii.control,
    this.padding = EdgeInsets.zero,
  });
  final Widget Function(BuildContext, NeumorphicStyleOf) builder;
  final NeumorphicStyle? style, themeStyle;
  final OutlinedBorder? shape;
  final VoidCallback? onPressed;
  final String? label;
  final bool? selected;
  final bool busy, showBusy;
  final FocusNode? focusNode;
  final double radius;
  final EdgeInsets padding;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  State<_Moulded> createState() => _MouldedState();
}

class _MouldedState extends State<_Moulded> {
  bool _down = false;
  @override
  void didUpdateWidget(_Moulded old) {
    super.didUpdateWidget(old);
    if (widget.busy || widget.onPressed == null) _down = false;
  }

  @override
  Widget build(BuildContext context) => NeumorphicTap(
    autofocus: widget.autofocus,
    style: widget.style,
    themeStyle: widget.themeStyle,
    shape: widget.shape,
    onPressed: widget.busy ? null : widget.onPressed,
    label: widget.label,
    selected: widget.selected,
    focusNode: widget.focusNode,
    enabled: widget.busy ? widget.onPressed != null : null,
    semanticValue: widget.busy && widget.showBusy
        ? NeumorphicLocalizations.of(context).loading
        : null,
    radius: widget.radius,
    pressRelief: false,
    onDown: widget.onPressed == null || widget.busy
        ? null
        : (v) => setState(() => _down = v),
    // A busy key stays pressed in while it works, and rises when its work is done (law 7): raised and blank it read
    // as an empty key still waiting for a press.
    child: TweenAnimationBuilder<double>(
      tween: Tween(end: _down || (widget.busy && widget.showBusy) ? 1 : 0),
      duration: NeumorphicMotion.of(context).press,
      curve: NeumorphicMotion.of(context).enter,
      child: Builder(
        builder: (context) => widget.builder.call(
          context,
          NeumorphicStyleOf([
            widget.style,
            widget.themeStyle,
          ], NeumorphicStatesScope.of(context)),
        ),
      ),
      builder: (context, depression, child) => RepaintBoundary(
        child: NeumorphicSurface(
          cast: widget.selected == true
              ? NeumorphicSurfaceLevel.groove
              : NeumorphicSurfaceLevel.part,
          style: widget.style,
          themeStyle: widget.themeStyle,
          shape: widget.shape,
          depression: widget.selected == true ? 0 : depression,
          outlined: true,
          radius: widget.radius,
          padding: widget.padding,
          child: child,
        ),
      ),
    ),
  );
}

class _ActPainter extends CustomPainter {
  _ActPainter(
    this.c,
    this.flat,
    this.radius,
    this.down, {
    this.border,
    this.fill,
    this.side,
    this.elevation = const NeumorphicElevation(),
  });
  final OutlinedBorder? border;
  final Color? fill;
  final BorderSide? side;
  final NeumorphicElevation elevation;
  final NeumorphicColors c;
  final bool flat;
  final double radius;

  /// How far the act has gone in, 0 to 1: raised, flush at a half, pressed.
  final double down;
  @override
  void paint(Canvas canvas, Size s) {
    final box = Offset.zero & s;
    final shape =
        border?.getOuterPath(box) ??
        (Path()
          ..addRRect(RRect.fromRectAndRadius(box, Radius.circular(radius))));
    // One depth, as every part's: the raised pair shrinks to nothing by the middle of a press, then the pigment face
    // takes its pressed pair. A release runs back from wherever it is.
    final up = math.max(0.0, 1 - 2 * down);
    final pressed = math.max(0.0, 2 * down - 1);
    final face = cssLinear(box, 145, [fill ?? c.pigment, fill ?? c.pigmentDk]);
    neumorphicPaintRaised(
      canvas,
      shape,
      c,
      light: (const Offset(-4, -4), 10),
      dark: (const Offset(5, 5), 12),
      face: face,
      elevation: elevation.copyWith(
        depth: elevation.depth * up,
        strength: elevation.strength * up,
      ),
      flat: flat || up == 0,
      rim: false,
    );
    if (!flat && pressed > 0) {
      neumorphicPaintPressed(
        canvas,
        shape,
        c,
        light: (const Offset(-3, -3), 7),
        dark: (const Offset(3, 3), 7),
        lightColor: c.pigmentHi.withValues(alpha: .6),
        darkColor: c.pigmentDk,
        face: face,
        elevation: elevation.copyWith(
          depth: elevation.depth * pressed,
          strength: elevation.strength * pressed,
        ),
      );
    }
    if (side != null) {
      (border ?? NeumorphicRoundedBorder(radius: radius))
          .copyWith(side: side)
          .paint(canvas, box);
    }
    if (flat) return;
    canvas.save();
    canvas.clipPath(shape);
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(box.inflate(4))
        ..addPath(shape, const Offset(1, 1)),
      neumorphicFillPaint(c.pigmentHi.withValues(alpha: .55 * up)),
    );
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(box.inflate(4))
        ..addPath(shape, const Offset(-1, -1)),
      neumorphicFillPaint(c.pigmentDk.withValues(alpha: c.pigmentDk.a * up)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ActPainter o) =>
      o.c != c ||
      o.flat != flat ||
      o.radius != radius ||
      o.down != down ||
      o.border != border ||
      o.fill != fill ||
      o.side != side ||
      o.elevation != elevation;
}

/// The three button faces; their padded touch targets remain at least 48 pixels.
/// The visual size of a button, independent of its minimum hit target.
enum NeumorphicButtonSize {
  /// The smallest face and spacing.
  small,

  /// The standard face and spacing.
  medium,

  /// The largest face and spacing.
  large,
}

// One control height per density (a field's, a select's, a bank's, a split button's): a button beside them shows
// the same top and bottom (design6 P, "the button doesnt have the same height here?").
double _buttonHeight(NeumorphicButtonSize size) => switch (size) {
  NeumorphicButtonSize.small => 36,
  NeumorphicButtonSize.medium => 48,
  NeumorphicButtonSize.large => 56,
};

/// A filled key's side room by its size, so the sizes read as a scale: with one room for all, 'Large' stood narrower
/// than 'Medium'.
EdgeInsets _buttonSides(NeumorphicButtonSize size) => EdgeInsets.symmetric(
  horizontal: switch (size) {
    NeumorphicButtonSize.small => 14,
    NeumorphicButtonSize.medium => 20,
    NeumorphicButtonSize.large => 28,
  },
);

/// While busy, a key with a glyph turns the ring in the glyph's place and keeps its words: held in with its words
/// hidden too, a key with a ring alone read as an empty field. The ring's box is the glyph's, so the key keeps its
/// width.
Widget _glyphOrRing(Widget glyph, double size, bool busy, Color ink) => !busy
    ? glyph
    : SizedBox.square(
        dimension: size,
        child: Center(
          child: NeumorphicCircularProgressIndicator(
            size: math.min(20, size),
            color: ink,
          ),
        ),
      );

/// While busy, a key of words alone keeps its width with the ring in their place (a glyph's key uses [_glyphOrRing]).
Widget _busyContent(Widget child, bool busy, Color ink) => !busy
    ? child
    : Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0, child: child),
          Positioned.fill(
            child: Center(
              child: NeumorphicCircularProgressIndicator(size: 20, color: ink),
            ),
          ),
        ],
      );

// The act's face: NeumorphicButton.filled, and NeumorphicRoundButton.filled when [round] (a cap with its icon alone).
class _ActButton extends StatefulWidget {
  const _ActButton(
    this.label, {
    this.icon,
    this.leading,
    this.onPressed,
    this.wide = false,
    this.round = false,
    this.busy = false,
    this.showBusy = true,
    this.focusNode,
    this.autofocus = false,
    this.alignment = AlignmentDirectional.centerStart,
    this.size = NeumorphicButtonSize.medium,
    this.style,
  });

  /// State-resolved visual overrides before the component theme.
  final NeumorphicStyle? style;

  /// The text identifying this item or control.
  final String label;

  /// Placement of a hugging face inside a wider slot.
  final AlignmentGeometry alignment;

  /// The glyph displayed with the content.
  final IconData? icon;

  /// Custom leading content; takes precedence over [icon].
  final Widget? leading;

  /// Called when the item is activated.
  final VoidCallback? onPressed;

  /// Whether the button fills the available width.
  final bool wide;

  /// Whether to use the rounder version of the raised face.
  final bool round;

  /// Whether an operation is in progress and activation is blocked.
  final bool busy;

  /// Whether progress is visible while [busy]; false preserves the resting face.
  /// Activation is blocked throughout [busy], including before progress appears.
  final bool showBusy;

  /// The control's focus, retained while busy.
  final FocusNode? focusNode;

  /// The button height, spacing and type scale.
  final NeumorphicButtonSize size;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  State<_ActButton> createState() => _ActButtonState();
}

class _ActButtonState extends State<_ActButton> {
  Set<WidgetState> _states = const {};

  @override
  Widget build(BuildContext context) => widget.wide
      ? neumorphicWideRoom(widget.alignment, LayoutBuilder(builder: _build))
      : LayoutBuilder(builder: _build);

  Widget _build(BuildContext context, BoxConstraints box) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final disabled = !widget.busy && widget.onPressed == null;
    final states = {..._states}..remove(WidgetState.disabled);
    if (disabled) states.add(WidgetState.disabled);
    if (widget.busy || disabled) states.remove(WidgetState.pressed);
    final themeStyle = NeumorphicStyle.cascade([
      t.filledButtonTheme,
      t.buttonTheme,
    ]);
    final look = NeumorphicStyleOf([widget.style, themeStyle], states);
    final height = math.max(
      t.density.height(_buttonHeight(widget.size)),
      look.minimumSize?.height ?? 0,
    );
    final ink = look.foreground ?? c.onPigment;
    final words =
        (widget.size == NeumorphicButtonSize.small
                ? t.textTheme.caption.copyWith(fontWeight: FontWeight.w700)
                : t.textTheme.title)
            .merge(look.textStyle)
            .copyWith(color: ink);
    final glyph = neumorphicGlyphBeside(context, look.iconSize ?? 20);
    var shape =
        look.shape ??
        (!widget.round &&
                widget.size == NeumorphicButtonSize.small &&
                !widget.wide
            ? t.shapes.capsule
            : null);
    if (!widget.round && look.shape == null) {
      shape = neumorphicInlineRoleShape(
        context,
        shape: shape,
        text: widget.label,
        textStyle: words,
        width: box.hasBoundedWidth ? box.maxWidth : double.infinity,
        padding:
            look.padding(Directionality.of(context)) ??
            t.density.padding(_buttonSides(widget.size)),
        beside: widget.leading != null || widget.icon != null ? glyph + 8 : 0,
      );
    }
    final diameter = math.max(height, look.minimumSize?.width ?? 0);
    if (widget.round && shape is NeumorphicBorder) {
      shape = shape.fit(Size.square(diameter));
    }
    final onPressed = widget.busy ? null : widget.onPressed;
    Widget tap(Widget face, {bool round = false}) => NeumorphicTap(
      autofocus: widget.autofocus,
      // The face draws its own depression.
      pressRelief: false,
      style: widget.style,
      themeStyle: themeStyle,
      shape: shape,
      onPressed: onPressed,
      label: widget.label,
      focusNode: widget.focusNode,
      enabled: widget.busy ? widget.onPressed != null : null,
      semanticValue: widget.busy && widget.showBusy
          ? NeumorphicLocalizations.of(context).loading
          : null,
      round: round,
      focusInset: round ? (_targetSize(diameter) - diameter) / 2 : 0,
      onStatesChanged: (states) => setState(() => _states = Set.of(states)),
      child: NeumorphicOutOfUse(off: disabled, child: face),
    );
    // The act's face is its box (its relief paints outside it): marked as one item for ui_core's checks, which read
    // a raised pigment face's highlight and shadow into its edges.
    Widget paint(Widget child, {required EdgeInsets padding}) =>
        AnimatedNeumorphicShape(
          shape: shape,
          builder: (context, border) => DesignKeylineFace(
            child: TweenAnimationBuilder<double>(
              // Held in while busy, as a moulded key is.
              tween: Tween(
                end:
                    states.contains(WidgetState.pressed) ||
                        (widget.busy && widget.showBusy)
                    ? 1
                    : 0,
              ),
              duration: NeumorphicMotion.of(context).press,
              curve: NeumorphicMotion.of(context).enter,
              builder: (context, down, child) => CustomPaint(
                painter: _ActPainter(
                  c,
                  NeumorphicFlatScope.of(context),
                  widget.round ? diameter / 2 : NeumorphicRadii.control,
                  down,
                  border: border,
                  fill: look.fill,
                  // High contrast prints the act's fine outline too, as it does every part's.
                  side:
                      look.side ??
                      (look.edge != null || t.highContrast
                          ? BorderSide(
                              color: look.edge ?? c.edge,
                              width: neumorphicEdgeWidth,
                            )
                          : null),
                  elevation: t.elevation,
                ),
                child: child,
              ),
              child: Padding(
                padding:
                    padding +
                    (border?.dimensions.resolve(Directionality.of(context)) ??
                        EdgeInsets.zero),
                child: child,
              ),
            ),
          ),
        );
    if (widget.round) {
      return _onEdge(
        diameter,
        neumorphicOwnSize(
          width: _targetSize(diameter),
          height: _targetSize(diameter),
          child: tap(
            Center(
              child: SizedBox.square(
                dimension: diameter,
                child: paint(
                  _busyContent(
                    Center(
                      child:
                          widget.leading ??
                          Icon(
                            widget.icon ?? NeumorphicGlyphs.plus,
                            size: look.iconSize ?? 22,
                            color: ink,
                          ),
                    ),
                    widget.busy && widget.showBusy,
                    ink,
                  ),
                  padding:
                      look.padding(Directionality.of(context)) ??
                      EdgeInsets.zero,
                ),
              ),
            ),
            round: true,
          ),
        ),
      );
    }
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leading != null || widget.icon != null) ...[
          _glyphOrRing(
            widget.leading ?? Icon(widget.icon, size: glyph, color: ink),
            glyph,
            widget.busy && widget.showBusy,
            ink,
          ),
          const SizedBox(width: 8),
        ],
        // As wide as its longest line, so glyph and words stay one centred group: a label wrapped at twice the text
        // took the whole width, and its arrow stood stranded at the key's start while the lines centred.
        Flexible(
          child: neumorphicLabel(
            Text(
              widget.label,
              style: words,
              textAlign: TextAlign.center,
              textWidthBasis: TextWidthBasis.longestLine,
            ),
          ),
        ),
      ],
    );
    // A pill's cut-in counts towards the face's height, not on top of it.
    final cut =
        shape?.dimensions.resolve(Directionality.of(context)) ??
        EdgeInsets.zero;
    final button = tap(
      paint(
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(0.0, height - cut.vertical),
            minWidth: look.minimumSize?.width ?? 0,
          ),
          child: Padding(
            // The minimum face height already gives a one-line label room.
            // Wrapped or enlarged words need the same breathing space.
            padding: look.padding(Directionality.of(context)) == null
                ? neumorphicClearOfCut(
                    const EdgeInsets.symmetric(vertical: 4),
                    cut,
                  )
                : EdgeInsets.zero,
            child: _busyContent(
              Center(widthFactor: 1, heightFactor: 1, child: row),
              widget.busy &&
                  widget.showBusy &&
                  widget.leading == null &&
                  widget.icon == null,
              ink,
            ),
          ),
        ),
        padding:
            look.padding(Directionality.of(context)) ??
            t.density.padding(_buttonSides(widget.size)),
      ),
    );
    if (widget.wide) {
      return LayoutBuilder(
        builder: (context, box) => ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: box.hasBoundedWidth ? box.maxWidth : 0,
          ),
          child: button,
        ),
      );
    }
    return Align(
      alignment: widget.alignment,
      widthFactor: 1,
      heightFactor: 1,
      child: button,
    );
  }
}

// The ordinary button's face: NeumorphicButton.
class _LineButton extends StatelessWidget {
  const _LineButton(
    this.label, {
    this.icon,
    this.leading,
    this.onPressed,
    this.wide = false,
    this.busy = false,
    this.showBusy = true,
    this.focusNode,
    this.alignment = AlignmentDirectional.centerStart,
    this.size = NeumorphicButtonSize.medium,
    this.style,
  });

  /// State-resolved visual overrides before the component theme.
  final NeumorphicStyle? style;

  /// The text identifying this item or control.
  final String label;

  /// Placement of a hugging face inside a wider slot.
  final AlignmentGeometry alignment;

  /// The glyph displayed with the content.
  final IconData? icon;

  /// Custom leading content; takes precedence over [icon].
  final Widget? leading;

  /// Called when the item is activated.
  final VoidCallback? onPressed;

  /// Whether the button fills the available width.
  final bool wide;

  /// Whether an operation is in progress and activation is blocked.
  final bool busy;

  /// Whether progress is visible while [busy]; false preserves the resting face.
  /// Activation is blocked throughout [busy], including before progress appears.
  final bool showBusy;

  /// The control's focus, retained while busy.
  final FocusNode? focusNode;

  /// The button height, spacing and type scale.
  final NeumorphicButtonSize size;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final height = t.density.height(_buttonHeight(size));
    final themeStyle = NeumorphicStyle.cascade([t.buttonTheme]);
    final shape = size == NeumorphicButtonSize.small && !wide
        ? t.shapes.capsule
        : null;
    // Large text keeps a margin of face above and below its words: at 4 px, twice-size words filled the face edge to
    // edge.
    final grown = (MediaQuery.textScalerOf(context).scale(16) / 16 - 1).clamp(
      0.0,
      1.5,
    );
    final inset = EdgeInsets.symmetric(horizontal: 16, vertical: 4 + 6 * grown);
    final body = LayoutBuilder(
      builder: (context, box) {
        final limit = box.hasBoundedWidth
            ? box.maxWidth
            : (t.desk ? 280.0 : 168.0);
        final look = NeumorphicStyleOf(
          [style, themeStyle],
          {if (onPressed == null && !busy) WidgetState.disabled},
        );
        final role = neumorphicInlineRoleShape(
          context,
          shape: shape,
          text: label,
          textStyle:
              (size == NeumorphicButtonSize.small
                      ? t.textTheme.caption
                      : t.textTheme.title)
                  .merge(look.textStyle),
          width: limit,
          padding:
              look.padding(Directionality.of(context)) ??
              t.density.padding(inset),
          beside: leading != null || icon != null
              ? neumorphicGlyphBeside(context, look.iconSize ?? 18) + 8
              : 0,
        );
        // A pill's cut-in counts towards the face's height, not on top of it.
        final cut =
            role?.dimensions.resolve(Directionality.of(context)) ??
            EdgeInsets.zero;
        final facePadding = neumorphicClearOfCut(t.density.padding(inset), cut);
        final button = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: limit, minHeight: height),
          // Out of use the whole face lies flat, flush with the ground, its words quiet.
          child: NeumorphicOutOfUse(
            off: onPressed == null && !busy,
            child: _Moulded(
              style: style,
              themeStyle: themeStyle,
              shape: role,
              onPressed: onPressed,
              label: label,
              busy: busy,
              showBusy: showBusy,
              focusNode: focusNode,
              padding: facePadding,
              builder: (context, look) => ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(
                    0.0,
                    height - facePadding.vertical - cut.vertical,
                  ),
                ),
                child: Center(
                  widthFactor: wide && box.hasBoundedWidth ? null : 1,
                  heightFactor: 1,
                  child: _busyContent(
                    NeumorphicFitRow(
                      fill: leading == null && icon == null ? 0 : 1,
                      gap: 8,
                      shrink: true,
                      children: [
                        if (leading != null || icon != null)
                          _glyphOrRing(
                            leading ??
                                Icon(
                                  icon,
                                  size: look.iconSize ?? 18,
                                  color: look.foreground ?? t.colors.ink,
                                ),
                            look.iconSize ?? 18,
                            busy && showBusy,
                            look.foreground ?? t.colors.ink,
                          ),
                        neumorphicLabel(
                          Text(
                            label,
                            style:
                                (size == NeumorphicButtonSize.small
                                        ? t.textTheme.caption
                                        : t.textTheme.title)
                                    .merge(look.textStyle)
                                    .copyWith(color: look.foreground),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    busy && showBusy && leading == null && icon == null,
                    look.foreground ?? t.colors.ink,
                  ),
                ),
              ),
            ),
          ),
        );
        if (wide) return button;
        return Align(
          alignment: alignment,
          widthFactor: 1,
          heightFactor: 1,
          child: button,
        );
      },
    );
    return wide ? neumorphicWideRoom(alignment, body) : body;
  }
}

// The frameless button's face: NeumorphicButton.text.
class _QuietButton extends StatelessWidget {
  const _QuietButton(
    this.label, {
    this.icon,
    this.leading,
    this.onPressed,
    this.size = NeumorphicButtonSize.medium,
    this.wide = false,
    this.busy = false,
    this.showBusy = true,
    this.focusNode,
    this.alignment = AlignmentDirectional.centerStart,
    this.style,
  });

  /// State-resolved visual overrides before the component theme.
  final NeumorphicStyle? style;

  /// The text identifying this item or control.
  final String label;

  /// Placement of a hugging face inside a wider slot.
  final AlignmentGeometry alignment;

  /// The glyph displayed with the content.
  final IconData? icon;

  /// Custom leading content; takes precedence over [icon].
  final Widget? leading;

  /// Called when the item is activated.
  final VoidCallback? onPressed;

  /// Whether progress is visible while [busy]; false preserves the resting face.
  /// Activation is blocked throughout [busy], including before progress appears.
  final bool showBusy;

  /// The control's focus, retained while busy.
  final FocusNode? focusNode;

  /// The button height, spacing and type scale.
  final NeumorphicButtonSize size;

  /// Whether the button fills the available width.
  final bool wide;

  /// Whether an operation is in progress and activation is blocked.
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final themeStyle = NeumorphicStyle.cascade([
      t.textButtonTheme,
      t.buttonTheme,
    ]);
    final shape = size == NeumorphicButtonSize.small && !wide
        ? t.shapes.capsule
        : null;
    final button = NeumorphicTap(
      style: style,
      themeStyle: themeStyle,
      shape: shape,
      label: label,
      focusNode: focusNode,
      onPressed: busy ? null : onPressed,
      enabled: busy ? onPressed != null : null,
      semanticValue: busy && showBusy
          ? NeumorphicLocalizations.of(context).loading
          : null,
      child: Builder(
        builder: (context) {
          final look = NeumorphicStyleOf([
            style,
            themeStyle,
          ], NeumorphicStatesScope.of(context));
          // Its words are in the pigment's ink, the look's mark of what is live (law 5): in the plain ink, with no face, a
          // live text button read as the out-of-use one beside it.
          final ink = look.foreground ?? t.colors.pigmentInk;
          final outline = look.shape ?? shape;
          return ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(
                t.density.height(_buttonHeight(size)) +
                    (outline?.dimensions
                            .resolve(Directionality.of(context))
                            .vertical ??
                        0),
                look.minimumSize?.height ?? 0,
              ),
              minWidth: look.minimumSize?.width ?? 0,
            ),
            child: Padding(
              padding:
                  (look.padding(Directionality.of(context)) ??
                      t.density.padding(
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      )) +
                  (outline?.dimensions.resolve(Directionality.of(context)) ??
                      EdgeInsets.zero),
              child: _busyContent(
                NeumorphicOutOfUse(
                  off: onPressed == null && !busy,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (leading != null || icon != null) ...[
                        _glyphOrRing(
                          leading ??
                              Icon(
                                icon,
                                size: neumorphicGlyphBeside(
                                  context,
                                  look.iconSize ?? 18,
                                ),
                                color: ink,
                              ),
                          neumorphicGlyphBeside(context, look.iconSize ?? 18),
                          busy && showBusy,
                          ink,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: neumorphicLabel(
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style:
                                (size == NeumorphicButtonSize.small
                                        ? t.textTheme.caption
                                        : t.textTheme.title)
                                    .merge(look.textStyle)
                                    .copyWith(color: ink),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                busy && showBusy && leading == null && icon == null,
                ink,
              ),
            ),
          );
        },
      ),
    );
    return wide
        ? neumorphicWideRoom(
            alignment,
            LayoutBuilder(
              builder: (context, box) => ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: box.hasBoundedWidth ? box.maxWidth : 0,
                ),
                child: button,
              ),
            ),
          )
        : Align(
            alignment: alignment,
            widthFactor: 1,
            heightFactor: 1,
            child: button,
          );
  }
}

enum _ButtonForm { ordinary, filled, text }

/// A button with its words: the plain moulded button, in ink, any number of them. Height 48, radius 12. It hugs its
/// words, and [wide] makes it take the width it's given; in a bare Row it leaves its neighbours their words.
/// [NeumorphicButton.filled] is the page's one act; [NeumorphicButton.text] has no raised face; [isDestructiveAction]
/// on any of them puts a warning mark beside explicit words such as Delete.
///
/// ```dart
/// NeumorphicButton('Open', icon: NeumorphicGlyphs.arrowRight, onPressed: () {})
/// ```
class NeumorphicButton extends StatelessWidget {
  /// The plain moulded button, in ink.
  const NeumorphicButton(
    this.label, {
    super.key,
    this.autofocus = false,
    this.icon,
    this.leading,
    this.onPressed,
    this.wide = false,
    this.busy = false,
    this.showBusy = true,
    this.focusNode,
    this.alignment = AlignmentDirectional.centerStart,
    this.size = NeumorphicButtonSize.medium,
    this.isDestructiveAction = false,
    this.style,
  }) : _form = _ButtonForm.ordinary;

  /// THE act: the one pigment-filled button on a screen. [NeumorphicRoundButton.filled] is the act as a round cap
  /// with its icon alone.
  ///
  /// ```dart
  /// NeumorphicButton.filled('Turn off', icon: NeumorphicGlyphs.power, onPressed: () {})
  /// ```
  const NeumorphicButton.filled(
    this.label, {
    super.key,
    this.autofocus = false,
    this.icon,
    this.leading,
    this.onPressed,
    this.wide = false,
    this.busy = false,
    this.showBusy = true,
    this.focusNode,
    this.alignment = AlignmentDirectional.centerStart,
    this.size = NeumorphicButtonSize.medium,
    this.isDestructiveAction = false,
    this.style,
  }) : _form = _ButtonForm.filled;

  /// A quiet text button, in the pigment's ink with no raised face, for an action that does not need one.
  ///
  /// ```dart
  /// NeumorphicButton.text('Skip for now', onPressed: skip)
  /// ```
  const NeumorphicButton.text(
    this.label, {
    super.key,
    this.autofocus = false,
    this.icon,
    this.leading,
    this.onPressed,
    this.wide = false,
    this.busy = false,
    this.showBusy = true,
    this.focusNode,
    this.alignment = AlignmentDirectional.centerStart,
    this.size = NeumorphicButtonSize.medium,
    this.isDestructiveAction = false,
    this.style,
  }) : _form = _ButtonForm.text;

  /// The button's words.
  final String label;

  /// The glyph beside the words.
  final IconData? icon;

  /// Custom leading content; takes precedence over [icon].
  final Widget? leading;

  /// Called when the button is pressed; null draws it out of use.
  final VoidCallback? onPressed;

  /// Whether the button fills the available width.
  final bool wide;

  /// Whether an operation is in progress; activation is blocked throughout.
  final bool busy;

  /// Whether progress is visible while [busy]; false keeps the resting face.
  final bool showBusy;

  /// The button's focus, kept while busy.
  final FocusNode? focusNode;

  /// Where a hugging face stands inside a wider slot.
  final AlignmentGeometry alignment;

  /// The button's height, spacing and type scale.
  final NeumorphicButtonSize size;

  /// Whether the action destroys something: a warning mark stands beside its words when no [icon] is given, and the
  /// mark reads without colour.
  final bool isDestructiveAction;

  /// State-resolved visual overrides before the button's component theme.
  final NeumorphicStyle? style;

  final _ButtonForm _form;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final mark =
        icon ?? (isDestructiveAction ? NeumorphicGlyphs.triangleAlert : null);
    return switch (_form) {
      _ButtonForm.ordinary => _LineButton(
        label,
        icon: mark,
        leading: leading,
        onPressed: onPressed,
        wide: wide,
        busy: busy,
        showBusy: showBusy,
        focusNode: focusNode,
        alignment: alignment,
        size: size,
        style: style,
      ),
      _ButtonForm.filled => _ActButton(
        autofocus: autofocus,
        label,
        icon: mark,
        leading: leading,
        onPressed: onPressed,
        wide: wide,
        busy: busy,
        showBusy: showBusy,
        focusNode: focusNode,
        alignment: alignment,
        size: size,
        style: style,
      ),
      _ButtonForm.text => _QuietButton(
        label,
        icon: mark,
        leading: leading,
        onPressed: onPressed,
        wide: wide,
        busy: busy,
        showBusy: showBusy,
        focusNode: focusNode,
        alignment: alignment,
        size: size,
        style: style,
      ),
    };
  }
}

/// Words that go somewhere: ink with a printed underline, so the underline stays when shadows wash out.
///
/// ```dart
/// NeumorphicLink('Details', onPressed: () {})
/// ```
class NeumorphicLink extends StatelessWidget {
  /// Creates a [NeumorphicLink].
  const NeumorphicLink(
    this.label, {
    super.key,
    this.autofocus = false,
    this.onPressed,
    this.focusNode,
    this.alignment = AlignmentDirectional.centerStart,
    this.busy = false,
    this.showBusy = true,
    this.leading,
    this.style,
  });

  /// State-resolved content, padding and optional face styling, before the
  /// quiet-button and general button themes. The default remains an underlined
  /// link; fill, side, edge or shape can give it an explicit face.
  final NeumorphicStyle? style;

  /// The text identifying this item or control.
  final String label;

  /// Placement of a hugging face inside a wider slot.
  final AlignmentGeometry alignment;

  /// Whether an operation is in progress and activation is blocked.
  final bool busy;

  /// Whether the busy state displays its progress indicator.
  final bool showBusy;

  /// Optional content before the main text.
  final Widget? leading;

  /// The link's keyboard focus.
  final FocusNode? focusNode;

  /// Called when the item is activated.
  final VoidCallback? onPressed;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final themeStyle = NeumorphicStyle.cascade([
      t.textButtonTheme,
      t.buttonTheme,
    ]);
    // Bare words have no face to sink: the press shows in the underline, keyboard focus lifts the words' small
    // corner off the wall, and a dead link lies flat as a dead button does. A style that gives the link a face gets a
    // button's press and lift back.
    final idle = NeumorphicStyleOf([style, themeStyle], <WidgetState>{});
    final faced =
        idle.fill != null ||
        idle.side != null ||
        idle.edge != null ||
        idle.shape != null;
    final disabled = onPressed == null && !busy;
    return Align(
      alignment: alignment,
      widthFactor: 1,
      heightFactor: 1,
      child: NeumorphicTap(
        autofocus: autofocus,
        style: style,
        themeStyle: themeStyle,
        shape: faced ? null : t.shapes.corner(4),
        pressRelief: faced,
        onPressed: busy ? null : onPressed,
        enabled: busy ? onPressed != null : null,
        semanticValue: busy && showBusy
            ? NeumorphicLocalizations.of(context).loading
            : null,
        label: label,
        focusNode: focusNode,
        child: LayoutBuilder(
          builder: (context, box) {
            final states = NeumorphicStatesScope.of(context);
            final look = NeumorphicStyleOf([style, themeStyle], states);
            // A link is live: its words in the pigment's ink (law 5), its underline quiet until pressed.
            final ink = look.foreground ?? t.colors.pigmentInk;
            final words = t.textTheme.caption
                .copyWith(
                  color: t.colors.pigmentInk,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor:
                      !faced && states.contains(WidgetState.pressed)
                      ? ink
                      : t.colors.quiet,
                )
                .merge(look.textStyle)
                .copyWith(color: ink);
            final padding =
                look.padding(Directionality.of(context)) ?? EdgeInsets.zero;
            final border =
                look.shape ??
                neumorphicInlineRoleShape(
                  context,
                  shape: null,
                  text: label,
                  textStyle: words,
                  width: box.maxWidth,
                  padding: padding,
                  beside: leading == null ? 0 : (look.iconSize ?? 18) + 6,
                ) ??
                const NeumorphicRoundedBorder(radius: NeumorphicRadii.control);
            final hasFace =
                look.fill != null ||
                look.side != null ||
                look.edge != null ||
                look.shape != null;
            return AnimatedNeumorphicShape(
              shape: border,
              builder: (context, animated) {
                final frame = animated ?? border;
                final inset = hasFace
                    ? frame.dimensions.resolve(Directionality.of(context))
                    : EdgeInsets.zero;
                Widget content = Padding(
                  padding: padding + inset,
                  child: _busyContent(
                    NeumorphicOutOfUse(
                      off: disabled,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (leading != null) ...[
                            IconTheme.merge(
                              data: IconThemeData(
                                color: ink,
                                size: look.iconSize,
                              ),
                              child: leading!,
                            ),
                            const SizedBox(width: 6),
                          ],
                          // As wide as its longest line: a label that wraps took the whole width, and its glyph stood
                          // stranded at the key's start while the lines centred.
                          Flexible(
                            child: Text(
                              label,
                              style: words,
                              textWidthBasis: TextWidthBasis.longestLine,
                            ),
                          ),
                        ],
                      ),
                    ),
                    busy && showBusy,
                    ink,
                  ),
                );
                if (look.minimumSize != null) {
                  content = ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: look.minimumSize!.width,
                      minHeight: look.minimumSize!.height,
                    ),
                    child: content,
                  );
                }
                if (hasFace) {
                  content = DecoratedBox(
                    decoration: ShapeDecoration(
                      color: look.fill,
                      shape: frame.copyWith(
                        side:
                            look.side ??
                            (look.edge == null
                                ? BorderSide.none
                                : BorderSide(
                                    color: look.edge!,
                                    width: neumorphicEdgeWidth,
                                  )),
                      ),
                    ),
                    child: content,
                  );
                }
                return content;
              },
            );
          },
        ),
      ),
    );
  }
}

/// A round moulded key: a stepper's, a transport's, a way back. An object, so it stays round. [selected] latches it: pressed, with
/// the pigment in its glyph and a wash under it.
///
/// ```dart
/// NeumorphicRoundButton(NeumorphicGlyphs.plus, size: 52, label: 'Up', onPressed: () {})
/// ```
class NeumorphicRoundButton extends StatelessWidget {
  /// Creates a [NeumorphicRoundButton].
  const NeumorphicRoundButton(
    this.icon, {
    this.badge,
    this.badgeLabel,
    super.key,
    this.focusNode,
    this.autofocus = false,
    this.size = 44,
    this.iconSize,
    this.label,
    this.selected = false,
    this.onPressed,
    this.style,
  }) : _filled = false;

  /// The act as a round key: the pigment-filled cap with [icon] alone, for a phone's top or a row with no room for the
  /// word; [label] is read out, never drawn. [size] is the face's diameter: 36, 48 or 56.
  ///
  /// ```dart
  /// NeumorphicRoundButton.filled(NeumorphicGlyphs.power, label: 'Turn off', onPressed: () {})
  /// ```
  const NeumorphicRoundButton.filled(
    this.icon, {
    super.key,
    this.focusNode,
    this.autofocus = false,
    required String this.label,
    this.size = 48,
    this.onPressed,
    this.style,
  }) : badge = null,
       badgeLabel = null,
       iconSize = null,
       selected = false,
       _filled = true;

  final bool _filled;

  /// State-resolved visual overrides before the component theme.
  final NeumorphicStyle? style;

  /// The glyph displayed with the content.
  final IconData icon;

  /// The face diameter in logical pixels; the hit target may be larger.
  final double size;

  /// The glyph size in logical pixels; null uses the component default.
  final double? iconSize;

  /// The accessible name of the icon action.
  final String? label;

  /// Whether to emphasize the active state with the pigment colour.
  final bool selected;

  /// Called when the item is activated.
  final VoidCallback? onPressed;

  /// A small count at its shoulder, on the pigment: something is waiting.
  final String? badge;

  /// Spoken value for the decorative badge.
  final String? badgeLabel;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    if (_filled) {
      return _ActButton(
        focusNode: focusNode,
        autofocus: autofocus,
        label ?? '',
        icon: icon,
        round: true,
        size: size >= 52
            ? NeumorphicButtonSize.large
            : size <= 40
            ? NeumorphicButtonSize.small
            : NeumorphicButtonSize.medium,
        onPressed: onPressed,
        style: style,
      );
    }
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final rest = NeumorphicStyleOf(
      [style, t.iconButtonTheme],
      {
        if (selected) WidgetState.selected,
        if (onPressed == null) WidgetState.disabled,
      },
    );
    double faceMinimum(NeumorphicStyleOf look) => math.max(
      t.density.height(size),
      math.max(
        (look.iconSize ??
                iconSize ??
                (t.density.height(size) * .46).clamp(18, 28)) *
            math.sqrt2,
        math.max(look.minimumSize?.width ?? 0, look.minimumSize?.height ?? 0),
      ),
    );
    // The tap is the button's own size wherever it stands: a row that hands it its whole width still gets the lift
    // round the face, not round the room. The merge keeps the button's one spoken node at its own root.
    // The face on the box's edge, its target's margins past it (outside the tap, which keeps its whole target and its
    // spoken node).
    return _onEdge(
      faceMinimum(rest),
      MergeSemantics(
        child: Align(
          alignment: AlignmentDirectional.topStart,
          widthFactor: 1,
          heightFactor: 1,
          child: NeumorphicTap(
            focusNode: focusNode,
            autofocus: autofocus,
            // The face draws its own depression.
            pressRelief: false,
            style: style,
            themeStyle: t.iconButtonTheme,
            shape: t.shapes.circle(),
            onPressed: onPressed,
            label: label,
            semanticValue: badgeLabel ?? badge,
            focusSize: Size.square(faceMinimum(rest)),
            selected: selected ? true : null,
            round: true,
            child: Builder(
              builder: (context) {
                final states = {
                  ...NeumorphicStatesScope.of(context),
                  if (selected) WidgetState.selected,
                };
                final look = NeumorphicStyleOf([
                  style,
                  t.iconButtonTheme,
                ], states);
                final faceSize = faceMinimum(look);
                var shape = look.shape ?? t.shapes.circle();
                if (shape is NeumorphicBorder) {
                  shape = shape.fit(Size.square(faceSize));
                }
                final glyph = Center(
                  child: Icon(
                    icon,
                    size:
                        look.iconSize ??
                        iconSize ??
                        (faceSize * .46).clamp(18, 28).toDouble(),
                    color:
                        look.foreground ?? (selected ? c.pigmentInkLit : c.ink),
                  ),
                );
                // Out of use it reads as the buttons do: flat, flush with the ground, its ink quiet.
                final body = NeumorphicOutOfUse(
                  off: onPressed == null,
                  child: SizedBox.square(
                    dimension: faceSize,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        end: !selected && states.contains(WidgetState.pressed)
                            ? 1
                            : 0,
                      ),
                      duration: NeumorphicMotion.of(context).press,
                      curve: NeumorphicMotion.of(context).enter,
                      builder: (context, depression, child) =>
                          NeumorphicSurface(
                            cast: selected
                                ? NeumorphicSurfaceLevel.groove
                                : NeumorphicSurfaceLevel.part,
                            style: style,
                            themeStyle: t.iconButtonTheme,
                            shape: shape,
                            states: states,
                            outlined: true,
                            round: true,
                            live: selected,
                            depression: depression,
                            child: child,
                          ),
                      child: glyph,
                    ),
                  ),
                );
                return neumorphicOwnSize(
                  width: _targetSize(faceSize),
                  height: _targetSize(faceSize),
                  child: badge == null
                      ? Center(child: body)
                      : Stack(
                          clipBehavior: Clip.none,
                          fit: StackFit.expand,
                          children: [
                            // The count is a bead of the plaster with its figure in the ink, as NeumorphicBadge's:
                            // pigment is never a body of its own (law 5). It is cast in one piece with its key (law 4):
                            // its shadow lies under the key, so it never falls on the key's face, and its face comes
                            // over the key's. Large text grows it only so far, so it never swallows the key it counts
                            // for.
                            PositionedDirectional(
                              top: -4,
                              end: -6,
                              child: MediaQuery.withClampedTextScaling(
                                maxScaleFactor: 1.4,
                                child: CustomPaint(
                                  painter: _KeyBeadPainter(
                                    under: true,
                                    t.shapes.capsule,
                                    c,
                                    t.elevation,
                                    NeumorphicFlatScope.of(context),
                                  ),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      child: Center(
                                        widthFactor: 1,
                                        heightFactor: 1,
                                        child: ExcludeSemantics(
                                          child: Opacity(
                                            opacity: 0,
                                            child: neumorphicLabel(
                                              Text(
                                                badge!,
                                                style: t.textTheme.micro
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      height: 18 / 12,
                                                      color: c.ink,
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
                            Center(child: body),
                            // Its face over the key's, its figure in the ink.
                            PositionedDirectional(
                              top: -4,
                              end: -6,
                              child: MediaQuery.withClampedTextScaling(
                                maxScaleFactor: 1.4,
                                child: CustomPaint(
                                  painter: _KeyBeadPainter(
                                    under: false,
                                    t.shapes.capsule,
                                    c,
                                    t.elevation,
                                    NeumorphicFlatScope.of(context),
                                  ),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      child: Center(
                                        widthFactor: 1,
                                        heightFactor: 1,
                                        child: ExcludeSemantics(
                                          child: neumorphicLabel(
                                            Text(
                                              badge!,
                                              style: t.textTheme.micro.copyWith(
                                                fontWeight: FontWeight.w700,
                                                height: 18 / 12,
                                                color: c.ink,
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
                          ],
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// A key's count: a small bead cast in one piece with its key. [under] it casts and fills (under the key, so its
/// shadow never falls on the key's face); over it only lays its face.
class _KeyBeadPainter extends CustomPainter {
  const _KeyBeadPainter(
    this.border,
    this.c,
    this.elevation,
    this.flat, {
    required this.under,
  });
  final bool under;
  final ShapeBorder border;
  final NeumorphicColors c;
  final NeumorphicElevation elevation;
  final bool flat;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final face = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c.faceStart, c.faceEnd],
    ).createShader(box);
    final path = border.getOuterPath(box);
    if (!under) {
      canvas.drawPath(path, Paint()..shader = face);
      return;
    }
    neumorphicPaintRaised(
      canvas,
      path,
      c,
      light: (const Offset(-1.5, -1.5), 3),
      dark: (const Offset(1.5, 1.5), 4),
      face: face,
      flat: flat,
      elevation: elevation,
    );
  }

  @override
  bool shouldRepaint(_KeyBeadPainter old) =>
      old.under != under ||
      old.border != border ||
      old.c != c ||
      old.elevation != elevation ||
      old.flat != flat;
}

/// A labelled icon on a round moulded button.
///
/// ```dart
/// NeumorphicIconButton(NeumorphicGlyphs.plus, label: 'Add', onPressed: add)
/// ```
class NeumorphicIconButton extends StatelessWidget {
  /// Creates a [NeumorphicIconButton].
  const NeumorphicIconButton(
    this.icon, {
    super.key,
    this.focusNode,
    this.autofocus = false,
    required this.label,
    this.onPressed,
    this.size = 44,
    this.iconSize,
    this.badge,
    this.badgeLabel,
    this.selected = false,
    this.style,
  });

  /// State-resolved visual overrides before the component theme.
  final NeumorphicStyle? style;

  /// The glyph displayed with the content.
  final IconData icon;

  /// The accessible name of the icon action.
  final String label;

  /// Called when the item is activated.
  final VoidCallback? onPressed;

  /// The face diameter in logical pixels; the hit target may be larger.
  final double size;

  /// The glyph size in logical pixels; null uses the component default.
  final double? iconSize;

  /// Optional short text displayed over the icon.
  final String? badge;

  /// Spoken value for the decorative badge.
  final String? badgeLabel;

  /// Whether this item is selected.
  final bool selected;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) => NeumorphicRoundButton(
    focusNode: focusNode,
    autofocus: autofocus,
    icon,
    style: style,
    label: label,
    onPressed: onPressed,
    size: size,
    iconSize: iconSize,
    badge: badge,
    badgeLabel: badgeLabel,
    selected: selected,
  );
}

/// A short raised chip: a fact, a filter, a quick reply. Height 36, radius 10. [selected]: pressed, in heavier ink, its icon in
/// the pigment, or an LED when it has none.
///
/// ```dart
/// NeumorphicChip('All secure', icon: NeumorphicGlyphs.shieldCheck, live: true)
/// ```
class NeumorphicChip extends StatelessWidget {
  /// Creates a [NeumorphicChip].
  const NeumorphicChip(
    this.label, {
    super.key,
    this.focusNode,
    this.autofocus = false,
    this.icon,
    this.leading,
    this.trailingIcon,
    this.onPressed,
    this.onDeleted,
    this.deleteLabel,
    this.enabled = true,
    this.selected = false,
    this.live = false,
    this.dense = false,
    this.style,
  });

  /// The text identifying this item or control.
  final String label;

  /// The glyph displayed with the content.
  final IconData? icon;

  /// An optional glyph after the label.
  final IconData? trailingIcon;

  /// Optional content before the main text.
  final Widget? leading;

  /// Called when the item is activated.
  final VoidCallback? onPressed;

  /// Called by the separate delete target when deletion is offered.
  final VoidCallback? onDeleted;

  /// The accessible label of the delete target; null uses localizations.
  final String? deleteLabel;

  /// Whether the control accepts user interaction.
  final bool enabled;

  /// Whether this item is selected.
  final bool selected;

  /// Whether to emphasize the active state with the pigment colour.
  final bool live;

  /// Whether to use the compact chip face.
  final bool dense;

  /// State-resolved face, words, outline and spacing, before the chip theme.
  final NeumorphicStyle? style;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _build);
  Widget _build(BuildContext context, BoxConstraints box) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;

    final pad = EdgeInsetsDirectional.fromSTEB(
      leading != null || icon != null || selected ? 12 : (dense ? 12 : 14),
      0,
      trailingIcon != null ? 10 : (dense ? 12 : 14),
      0,
    ).resolve(Directionality.of(context));
    final padding = t.density.padding(pad);
    final rest = NeumorphicStyleOf(
      [style, t.chipTheme],
      {if (selected) WidgetState.selected, if (!enabled) WidgetState.disabled},
    );
    final shape = neumorphicInlineRoleShape(
      context,
      shape: t.shapes.capsule,
      text: label,
      textStyle: t.textTheme.caption
          .copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w600)
          .merge(rest.textStyle),
      width: box.hasBoundedWidth ? box.maxWidth : double.infinity,
      padding: rest.padding(Directionality.of(context)) ?? padding,
      beside:
          (leading != null || icon != null || selected
              ? (rest.iconSize ?? 18) + 8
              : 0) +
          (trailingIcon != null ? (rest.iconSize ?? 18) + 8 : 0) +
          (onDeleted != null ? 48 : 0),
    );
    final states = <WidgetState>{
      if (selected) WidgetState.selected,
      if (!enabled || (onPressed == null && onDeleted == null))
        WidgetState.disabled,
    };
    Widget content(BuildContext context, NeumorphicStyleOf look) {
      final pigment = selected || live;
      final words = t.textTheme.caption
          .copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: pigment ? c.ink : c.inkSecondary,
          )
          .merge(look.textStyle)
          .copyWith(color: look.foreground);
      final mark =
          leading ??
          (icon != null
              ? Icon(
                  icon,
                  size: look.iconSize ?? 18,
                  color:
                      look.foreground ?? (pigment ? c.pigment : c.inkSecondary),
                )
              : selected
              ? const NeumorphicLed()
              : null);
      return ConstrainedBox(
        constraints: BoxConstraints(
          // A pill's cut-in counts towards the chip's height, not on top of it.
          minHeight: math.max(
            0.0,
            t.density.height(dense ? 32 : 36) -
                (shape?.dimensions.resolve(Directionality.of(context)) ??
                        EdgeInsets.zero)
                    .vertical,
          ),
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: NeumorphicFitRow(
            fill: mark != null ? 1 : 0,
            gap: 8,
            shrink: true,
            children: [
              ?mark,
              neumorphicLabel(
                Text(label, style: dense ? words.tabular : words),
              ),
              if (trailingIcon != null)
                Icon(
                  trailingIcon,
                  size: look.iconSize ?? 18,
                  color: look.foreground ?? c.inkSecondary,
                ),
            ],
          ),
        ),
      );
    }

    Widget inner(BuildContext context) => content(
      context,
      NeumorphicStyleOf(
        [style, t.chipTheme],
        {...NeumorphicStatesScope.of(context), ...states},
      ),
    );
    Widget face;
    if (onDeleted != null) {
      // One row, one height: a removable chip's face is as tall as any chip's. Its two keys (the chip's own press and
      // the cross) keep the platform's target in the reach round the face, as a plain chip's does, not by growing it.
      final dims =
          shape?.dimensions.resolve(Directionality.of(context)) ??
          EdgeInsets.zero;
      // The words as laid out beside the cross: in a narrow room they may wrap, and the band then grows to hold them.
      final words = TextPainter(
        text: TextSpan(
          text: label,
          style: t.textTheme.caption
              .copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              )
              .merge(rest.textStyle),
        ),
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.of(context),
      );
      words.layout(
        maxWidth: math.max(
          0.0,
          (box.hasBoundedWidth ? box.maxWidth : double.infinity) -
              48 -
              padding.horizontal -
              dims.horizontal -
              (leading != null || icon != null || selected
                  ? (rest.iconSize ?? 18) + 8
                  : 0) -
              (trailingIcon != null ? (rest.iconSize ?? 18) + 8 : 0),
        ),
      );
      final band = math.max(
        words.height,
        MediaQuery.textScalerOf(context).scale(
          math.max(0.0, t.density.height(dense ? 32 : 36) - dims.vertical),
        ),
      );
      words.dispose();
      face = Semantics(
        container: true,
        button: onPressed != null,
        enabled: enabled,
        selected: selected,
        label: label,
        onTap: enabled ? onPressed : null,
        child: NeumorphicReach(
          height: NeumorphicChromeMetrics.targetSize,
          child: NeumorphicSurface(
            cast: selected
                ? NeumorphicSurfaceLevel.groove
                : NeumorphicSurfaceLevel.part,
            style: style,
            themeStyle: t.chipTheme,
            shape: shape,
            states: states,
            outlined: true,
            radius: NeumorphicRadii.chip,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: band),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ExcludeSemantics(
                      child: NeumorphicTap(
                        focusNode: focusNode,
                        autofocus: autofocus,
                        onPressed: enabled ? onPressed : null,
                        style: style,
                        themeStyle: t.chipTheme,
                        shape: shape,
                        label: label,
                        selected: selected,
                        radius: NeumorphicRadii.chip,
                        child: Padding(
                          padding: padding,
                          child: Builder(builder: inner),
                        ),
                      ),
                    ),
                  ),
                  // The cross is the chip's own face at its end, sinking where it is pressed as the words' part does: a
                  // raised key on the raised chip stood one bump on another (law 4). Its target is the platform's,
                  // reaching past the band up and down.
                  NeumorphicTallTarget(
                    height: NeumorphicChromeMetrics.targetSize,
                    child: NeumorphicTap(
                      onPressed: enabled ? onDeleted : null,
                      label:
                          deleteLabel ??
                          '${NeumorphicLocalizations.of(context).delete} $label',
                      style: style,
                      themeStyle: t.chipTheme,
                      shape: shape,
                      radius: NeumorphicRadii.chip,
                      child: SizedBox(
                        width: 48,
                        height: band,
                        child: Icon(
                          NeumorphicGlyphs.close,
                          size: 16,
                          color: enabled ? c.inkSecondary : c.inkTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      face = _Moulded(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: enabled ? onPressed : null,
        label: label,
        selected: selected,
        style: style,
        themeStyle: t.chipTheme,
        shape: shape,
        radius: NeumorphicRadii.chip,
        padding: padding,
        builder: (context, look) =>
            content(context, look.at({...look.states, ...states})),
      );
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: NeumorphicOutOfUse(off: !enabled, child: face),
    );
  }
}

/// One of a bank's push buttons.
class NeumorphicLatch {
  /// Creates a [NeumorphicLatch].
  const NeumorphicLatch(this.label, {this.icon, String? value})
    : value = value ?? label;

  /// The text identifying this item or control.
  final String label;

  /// The stable value returned when this option is selected.
  final String value;

  /// The glyph displayed with the content.
  final IconData? icon;
}

/// A bank of latching push buttons: one is in. Pressed AND pigment AND heavier words: its icon in the pigment, or an LED when it
/// has none, so the latched one reads with no shadow at all. The bank's radius is 12, its caps' 8.
///
/// ```dart
/// NeumorphicLatchGroup(options: const [NeumorphicLatch('Day'), NeumorphicLatch('Week')], value: 'Day', onChanged: (v) {})
/// ```
class NeumorphicLatchGroup extends StatelessWidget {
  /// Creates a [NeumorphicLatchGroup].
  const NeumorphicLatchGroup({
    super.key,
    required this.options,
    this.value,
    this.onChanged,
    this.style,
  });

  /// The available latch options, in display order.
  final List<NeumorphicLatch> options;

  /// The value of the selected option, or null for no selection.
  final String? value;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<String>? onChanged;

  /// State-resolved caps and words, before the segmented-button theme.
  final NeumorphicStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context), c = t.colors;
    if (options.isEmpty) return const SizedBox.shrink();
    final bank = NeumorphicStyleOf([style, t.segmentedButtonTheme], const {});
    final padding =
        bank.padding(Directionality.of(context)) ??
        t.density.padding(const EdgeInsets.symmetric(horizontal: 6));
    final words = t.textTheme.caption
        .copyWith(fontWeight: FontWeight.w700)
        .merge(bank.textStyle);
    var need = 48.0;
    for (final o in options) {
      need = math.max(
        need,
        _wholeWidth(o.label, words, MediaQuery.textScalerOf(context)) +
            (o.icon != null ? (bank.iconSize ?? 18) + 7 : 30) +
            padding.horizontal,
      );
    }
    final chosen = options.indexWhere((o) => o.value == value);
    Widget cap(NeumorphicLatch o) {
      final on = o.value == value;
      return Builder(
        builder: (context) {
          final cell = NeumorphicCellScope.of(context);
          return NeumorphicTap(
            onPressed: onChanged == null ? null : () => onChanged!(o.value),
            style: style,
            themeStyle: t.segmentedButtonTheme,
            shape: cell.border,
            focusReach: .5,
            pressRelief: !on,
            label: o.label,
            selected: on,
            child: NeumorphicCellFace(
              child: Builder(
                builder: (context) {
                  final states = {
                    ...NeumorphicStatesScope.of(context),
                    if (on) WidgetState.selected,
                    if (onChanged == null) WidgetState.disabled,
                  };
                  final look = NeumorphicStyleOf([
                    style,
                    t.segmentedButtonTheme,
                  ], states);
                  // One weight in both states: a chosen label never reflows or moves.
                  final label = t.textTheme.caption
                      .copyWith(
                        fontWeight: FontWeight.w700,
                        color: on ? c.ink : c.inkSecondary,
                      )
                      .merge(look.textStyle)
                      .copyWith(color: look.foreground);
                  final mark = o.icon != null
                      ? Icon(
                          o.icon,
                          size: look.iconSize ?? 18,
                          color:
                              look.foreground ??
                              (on ? c.pigmentInkLit : c.inkSecondary),
                        )
                      // A latch with no icon carries the pigment as an LED: latched reads with no shadow visible. Off has
                      // no LED, but keeps its room, so the label stands still when its latch is chosen.
                      : on
                      ? const NeumorphicLed()
                      : const SizedBox.square(dimension: 8);
                  Widget face = Padding(
                    padding: padding,
                    child: Center(
                      child: NeumorphicFitRow(
                        fill: 1,
                        gap: 7,
                        shrink: true,
                        children: [
                          mark,
                          neumorphicLabel(Text(o.label, style: label)),
                          // The LED's room again after the words, so they stand on the cell's middle: with its room
                          // on one side only, Off and On sat 7 px past their centres beside a centred Auto.
                          if (o.icon == null)
                            const SizedBox.square(dimension: 8),
                        ],
                      ),
                    ),
                  );
                  if (look.fill != null) {
                    face = DecoratedBox(
                      decoration: ShapeDecoration(
                        color: look.fill,
                        shape: cell.border,
                      ),
                      child: face,
                    );
                  }
                  return face;
                },
              ),
            ),
          );
        },
      );
    }

    return NeumorphicCellBank(
      selected: chosen,
      minCellWidth: need,
      side: bank.side,
      edge: bank.edge,
      naturalWidth: 390,
      // The tallest label at the cell's width: a label that wraps makes its row taller.
      contentHeight: (cellWidth) {
        var tallest = 0.0;
        for (final o in options) {
          final painter =
              TextPainter(
                text: TextSpan(text: o.label, style: words),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(
                maxWidth: math.max(
                  0,
                  cellWidth -
                      padding.horizontal -
                      (o.icon != null ? (bank.iconSize ?? 18) : 8) -
                      7,
                ),
              );
          tallest = math.max(tallest, painter.height);
          painter.dispose();
        }
        return tallest + padding.vertical;
      },
      group: (bank) => NeumorphicOutOfUse(
        // Out of use (no onChanged) it reads as every control does: the bank flat, flush with the ground, its ink quiet.
        off: onChanged == null,
        child: bank,
      ),
      children: [for (final o in options) cap(o)],
    );
  }
}

/// A field's shell: a pressed groove with a 12-pixel radius.
/// The theme's high-contrast setting adds an explicit boundary.
///
/// ```dart
/// NeumorphicFieldBox(child: Text('A custom input'))
/// ```
class NeumorphicFieldBox extends StatelessWidget {
  /// Creates a [NeumorphicFieldBox].
  const NeumorphicFieldBox({
    super.key,
    required this.child,
    this.minHeight = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.style,
    this.states = const {},
    this.multiline = false,
    this.shape,
  });

  /// The content placed inside this component.
  final Widget child;

  /// The requested minimum height, before the platform target floor.
  final double minHeight;

  /// Space between the face and its content, before any shape inset.
  final EdgeInsetsGeometry padding;

  /// State-resolved shell slots, before textFieldTheme.
  final NeumorphicStyle? style;

  /// Editing states in addition to a containing pressable's states.
  final Set<WidgetState> states;

  /// Tall inputs use the surface role, so stadiums cannot cut into paragraphs.
  final bool multiline;

  /// A specific role, such as a code cell's square mark.
  final OutlinedBorder? shape;
  @override
  Widget build(BuildContext context) {
    final padding = this.padding.resolve(Directionality.of(context));
    final t = NeumorphicTheme.of(context);
    return NeumorphicSurface(
      cast: NeumorphicSurfaceLevel.groove,
      outlined: true,
      boundary: true,
      style: style,
      themeStyle: t.textFieldTheme,
      states: states,
      shape: shape,
      padding: t.density.padding(padding),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // The density's control height, as a button's beside it: no floor of its own.
          minHeight: t.density.height(minHeight),
        ),
        // Several lines start at the top; the first stands where one line does.
        child: Align(
          alignment: multiline
              ? AlignmentDirectional.topStart
              : Alignment.center,
          heightFactor: 1,
          child: child,
        ),
      ),
    );
  }
}

/// A text input in Neumorphism's field: the look's groove around a bare editable, one line centred in it whatever the
/// platform, density or an app's input theme.
/// [lines] > 1 makes a note box; [trailing] holds a send button or a unit.
///
/// ```dart
/// NeumorphicTextField(hint: 'A name', trailing: const Icon(NeumorphicGlyphs.search, size: 18))
/// ```
class NeumorphicTextField extends StatefulWidget {
  /// Creates a [NeumorphicTextField].
  const NeumorphicTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.leading,
    this.trailing,
    this.lines = 1,
    this.counter,
    this.minHeight,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLength,
    this.decorate,
    this.failureLine,
    this.revealLabels,
    this.nameOnly = false,
    this.style,
  }) : assert(lines > 0),
       assert(!obscureText || lines == 1);

  /// Visual shell and editable text slots, before textFieldTheme.
  final NeumorphicStyle? style;

  /// An optional externally owned text controller.
  final TextEditingController? controller;

  /// The initial text when no controller is supplied.
  final String? initialValue;

  /// The text identifying this item or control.
  final String? label;

  /// Placeholder text shown when the input is empty.
  final String? hint;

  /// Supporting text beneath the input.
  final String? helper;

  /// An error message displayed beneath the input.
  final String? error;

  /// Optional text describing the input count or limit.
  final String? counter;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the current text.
  final ValueChanged<String>? onSubmitted;

  /// Called when the user finishes editing.
  final VoidCallback? onEditingComplete;

  /// Optional content before the main text.
  final Widget? leading;

  /// Optional content after the editable text.
  final Widget? trailing;

  /// The number of visible input lines; values above one use the multiline role.
  final int lines;

  /// The maximum number of input characters, when specified.
  final int? maxLength;

  /// The requested minimum height, before the platform target floor.
  final double? minHeight;

  /// The keyboard layout requested from the platform.
  final TextInputType? keyboardType;

  /// The action shown on the platform keyboard.
  final TextInputAction? textInputAction;

  /// Autofill purposes supplied to the platform text input.
  final Iterable<String>? autofillHints;

  /// Formatters applied to user edits in order.
  final List<TextInputFormatter>? inputFormatters;

  /// An optional externally owned focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first attached.
  final bool autofocus;

  /// Whether the control accepts user interaction.
  final bool enabled;

  /// Whether text can be selected but not edited.
  final bool readOnly;

  /// Whether to obscure the entered text.
  final bool obscureText;

  /// Wraps only the editable, allowing a form to own its name and hints.
  /// When supplied, the visible label and placeholder do not add spoken names.
  final Widget Function(Widget editable)? decorate;

  /// Wraps the drawn failure when a form owns its announcement.
  final Widget Function(Widget failure)? failureLine;

  /// Caller-provided words for the password's show and hide actions.
  final (String show, String hide)? revealLabels;

  /// Uses [label] only as the input's name; no label is drawn above it.
  final bool nameOnly;
  @override
  State<NeumorphicTextField> createState() => _NeumorphicTextFieldState();
}

class _NeumorphicTextFieldState extends State<NeumorphicTextField> {
  bool _focused = false, _hovered = false;
  TextEditingController? _ownText;
  FocusNode? _ownFocus;

  TextEditingController get _text =>
      widget.controller ??
      (_ownText ??= TextEditingController(text: widget.initialValue));
  FocusNode get _focus =>
      widget.focusNode ??
      (_ownFocus ??= FocusNode(debugLabel: 'NeumorphicTextField'));

  @override
  void dispose() {
    _ownText?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.obscureText) return _field(context, null);
    // A password's show and hide is ui_core's (DesignPasswordReveal): the eye's state, its words and the field's
    // obscuring; the look draws the eye.
    final words = NeumorphicLocalizations.of(context);
    return DesignPasswordReveal(
      showLabel: widget.revealLabels?.$1 ?? words.showPassword,
      hideLabel: widget.revealLabels?.$2 ?? words.hidePassword,
      builder: _field,
    );
  }

  Widget _field(BuildContext context, DesignPasswordDetails? reveal) {
    final t = NeumorphicTheme.of(context);
    final states = <WidgetState>{
      if (_focused) WidgetState.focused,
      if (_hovered && widget.enabled) WidgetState.hovered,
      if (!widget.enabled) WidgetState.disabled,
      if (widget.error != null) WidgetState.error,
    };
    final look = NeumorphicStyleOf([widget.style, t.textFieldTheme], states);
    final shape = look.shape;
    final text = neumorphicEntryStyle(
      t.textTheme.body.merge(look.textStyle).copyWith(color: look.foreground),
    );
    final hintStyle = text.copyWith(
      color: look.foreground ?? t.colors.inkTertiary,
    );
    final multi = widget.lines > 1;
    // The box's control height: one line is centred in it, and the first of several stands where that line does. Large
    // text keeps 8 px of well above and below its line: at twice the size a 48 well held its words edge to edge.
    final control = math.max(
      t.density.height(multi ? 48 : widget.minHeight ?? 48),
      neumorphicLineHeight(context, text) + 16,
    );
    // A number, a phone number, an address or a link is written left to right in any page, as the platforms enter
    // them: set in a right-to-left page's direction, '07700 900 412' read '412 900 07700'. It keeps the page's side.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // By index, so a number with options (a decimal point, a sign) counts as a number.
    final leftToRight =
        rtl &&
        const [
          TextInputType.number,
          TextInputType.phone,
          TextInputType.datetime,
          TextInputType.emailAddress,
          TextInputType.url,
        ].any((kind) => kind.index == widget.keyboardType?.index);
    // The editable is bare (design6 I3): the box is the look's, the tap reach and the spoken node are the seat's.
    final editable = Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: _text,
        focusNode: _focus,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        obscureText: reveal?.obscured ?? false,
        autocorrect: !widget.obscureText,
        enableSuggestions: !widget.obscureText,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onEditingComplete: widget.onEditingComplete,
        style: text,
        keyboardType: widget.keyboardType,
        textDirection: leftToRight ? TextDirection.ltr : null,
        textAlign: leftToRight ? TextAlign.right : TextAlign.start,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        inputFormatters: [
          ...?widget.inputFormatters,
          if (widget.maxLength != null)
            LengthLimitingTextInputFormatter(widget.maxLength),
        ],
        minLines: widget.lines,
        maxLines: widget.lines,
        cursorColor: t.colors.ink,
        cursorWidth: 1.5,
        selectionControls: NeumorphicTextSelectionControls.of(
          Theme.of(context).platform,
        ),
        contextMenuBuilder: NeumorphicTextContextMenu.editable,
        decoration: _bareDecoration(
          hint: widget.decorate == null ? widget.hint : null,
          hintWidget: widget.decorate != null && widget.hint != null
              ? ExcludeSemantics(child: Text(widget.hint!, style: hintStyle))
              : null,
          hintStyle: hintStyle,
          // A box of several lines lets its hint take them: cut to one, the notes' hint ended in an ellipsis in an
          // empty three-line box at large text.
          hintLines: widget.lines,
        ),
      ),
    );
    final input = NeumorphicEntrySeat(
      height: control,
      line: neumorphicLineHeight(context, text),
      lines: widget.lines,
      focusNode: _focus,
      enabled: widget.enabled,
      label: widget.decorate == null ? widget.label : null,
      maxLength: widget.maxLength,
      // One line's node is its reach round the whole box (below).
      node: multi,
      // One line stands on the seat's middle by its capitals (ui_core's DesignCapCenter): caret, hint and taps move
      // with it. Several lines start at the top, where they are laid out.
      child: multi
          ? (widget.decorate?.call(editable) ?? editable)
          : neumorphicLabel(widget.decorate?.call(editable) ?? editable),
    );
    // Beside several lines, a glyph or a key stands on the first line's band. Beside one, a key's own 48 target
    // overhangs a groove the density draws smaller instead of growing it; the field's reach takes a press there to it.
    Widget band(Widget part) => multi
        ? SizedBox(
            height: control,
            child: Center(widthFactor: 1, child: part),
          )
        : SizedBox(
            height: control,
            child: OverflowBox(
              fit: OverflowBoxFit.deferToChild,
              minHeight: 0,
              maxHeight: double.infinity,
              child: part,
            ),
          );
    // The eye key stands in the groove's end with as much floor round it as above and below it: a 32 key in a 40
    // groove sat 4 from its top and bottom and jammed into the end, and at 8 round it in a 48 groove its light still
    // ran into the groove's curved end. At 12 its relief stays on the groove's floor.
    final keySize = (control - 24).clamp(24.0, 28.0);
    final keyFloor = (control - keySize) / 2;
    final trailing = reveal != null
        ? NeumorphicRoundButton(
            reveal.obscured ? NeumorphicGlyphs.eye : NeumorphicGlyphs.eyeOff,
            label: reveal.toggleLabel,
            size: keySize,
            onPressed: widget.enabled ? reveal.toggle : null,
          )
        : widget.trailing;
    final field = NeumorphicFieldBox(
      style: widget.style,
      states: states,
      multiline: multi,
      shape: shape,
      minHeight: widget.minHeight ?? (multi ? 92 : 48),
      // The key's end floor is the floor above and below it after the density's step, which the box takes off its
      // padding: given as is, a compact groove set the key 5 from its end against 8 above it, jammed into the end.
      // A send key at the end of one line stands as the eye key does, as far from the end as from the top and bottom:
      // at 14 it stood 10 from the end against 6 above and below.
      padding: EdgeInsetsDirectional.only(
        start: 14,
        end: reveal != null && !multi
            ? math.max(keyFloor, 8) - math.min(0.0, t.density.paddingDelta)
            : widget.trailing is NeumorphicSendButton && !multi
            ? (control - t.density.height(34)) / 2 -
                  math.min(0.0, t.density.paddingDelta)
            : 14,
      ),
      child: Row(
        crossAxisAlignment: multi
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (widget.leading != null) ...[
            band(widget.leading!),
            const SizedBox(width: 10),
          ],
          Expanded(child: input),
          if (trailing != null) ...[const SizedBox(width: 10), band(trailing)],
        ],
      ),
    );
    final drawn = NeumorphicOutOfUse(off: !widget.enabled, child: field);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null && !widget.nameOnly) ...[
          ExcludeSemantics(
            child: Text(
              widget.label!,
              // A field being typed in names itself in the pigment's ink: its deeper well alone was barely deeper
              // by night, and the caret blinks, so focus had no steady 3:1 mark but the edge.
              style: t.textTheme.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: _focused ? t.colors.pigmentInk : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        MouseRegion(
          // The text cursor over the whole field, its padding included; the face itself doesn't change.
          cursor: widget.enabled
              ? SystemMouseCursors.text
              : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            includeSemantics: false,
            onFocusChange: (v) => setState(() => _focused = v),
            // One line keeps a control's 48 target round its face, as a button does: the groove takes the density's
            // height in it, so a field and a button share a box in any row. The target is the field's one node, and
            // a press in it off the groove reaches the line.
            child: multi
                ? drawn
                : Semantics(
                    container: true,
                    label: widget.decorate == null ? widget.label : null,
                    maxValueLength: widget.maxLength,
                    child: NeumorphicReach(
                      height: NeumorphicChromeMetrics.targetSize,
                      child: drawn,
                    ),
                  ),
          ),
        ),
        if (widget.error != null || widget.helper != null) ...[
          const SizedBox(height: 8),
          if (widget.error != null)
            (widget.failureLine ?? (child) => child)(
              NeumorphicErrorLine(
                live: widget.failureLine == null,
                child: Text(widget.error!),
              ),
            )
          else
            ExcludeSemantics(
              excluding: widget.decorate != null,
              child: Text(widget.helper!, style: t.textTheme.caption),
            ),
        ],
        if (widget.counter != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(widget.counter!, style: t.textTheme.micro),
          ),
        ],
      ],
    );
  }
}

/// The small act at the end of an ask field: a round pigment key. It is an act, so a screen with one has no other.
///
/// ```dart
/// NeumorphicSendButton(onPressed: () {})
/// ```
class NeumorphicSendButton extends StatelessWidget {
  /// Creates a [NeumorphicSendButton].
  const NeumorphicSendButton({
    super.key,
    this.focusNode,
    this.autofocus = false,
    this.onPressed,
    this.style,
  });

  /// Called when the item is activated.
  final VoidCallback? onPressed;

  /// The small act face before the icon-button theme.
  final NeumorphicStyle? style;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final rest = NeumorphicStyleOf(
      [style, t.iconButtonTheme],
      {if (onPressed == null) WidgetState.disabled},
    );
    final diameter = math.max(
      t.density.height(34),
      math.max(rest.minimumSize?.width ?? 0, rest.minimumSize?.height ?? 0),
    );
    var shape = rest.shape;
    if (shape is NeumorphicBorder) shape = shape.fit(Size.square(diameter));
    return _onEdge(
      diameter,
      neumorphicOwnSize(
        width: _targetSize(diameter),
        height: _targetSize(diameter),
        child: NeumorphicTap(
          focusNode: focusNode,
          autofocus: autofocus,
          // The face draws its own depression.
          pressRelief: false,
          onPressed: onPressed,
          label: NeumorphicLocalizations.of(context).send,
          style: style,
          themeStyle: t.iconButtonTheme,
          shape: shape,
          round: true,
          focusSize: Size.square(diameter),
          child: Builder(
            builder: (context) {
              final states = NeumorphicStatesScope.of(context);
              final look = NeumorphicStyleOf([
                style,
                t.iconButtonTheme,
              ], states);
              var border = look.shape ?? shape;
              if (border is NeumorphicBorder) {
                border = border.fit(Size.square(diameter));
              }
              return Center(
                child: SizedBox.square(
                  dimension: diameter,
                  child: AnimatedNeumorphicShape(
                    shape: border,
                    builder: (context, border) => TweenAnimationBuilder<double>(
                      tween: Tween(
                        end: states.contains(WidgetState.pressed) ? 1 : 0,
                      ),
                      duration: NeumorphicMotion.of(context).press,
                      curve: NeumorphicMotion.of(context).enter,
                      builder: (context, down, child) => CustomPaint(
                        painter: _ActPainter(
                          t.colors,
                          NeumorphicFlatScope.of(context),
                          diameter / 2,
                          down,
                          border: border,
                          fill: look.fill,
                          side:
                              look.side ??
                              (look.edge == null
                                  ? null
                                  : BorderSide(
                                      color: look.edge!,
                                      width: neumorphicEdgeWidth,
                                    )),
                          elevation: t.elevation,
                        ),
                        child: child,
                      ),
                      child: Padding(
                        padding:
                            (look.padding(Directionality.of(context)) ??
                                EdgeInsets.zero) +
                            (border?.dimensions.resolve(
                                  Directionality.of(context),
                                ) ??
                                EdgeInsets.zero),
                        child: Center(
                          child: Icon(
                            NeumorphicGlyphs.sendHorizontal,
                            size: look.iconSize ?? 17,
                            color: look.foreground ?? t.colors.onPigment,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A read-only picker row: a value, a small note and a chevron.
///
/// ```dart
/// NeumorphicSelectField(value: 'Every day', onPressed: () {})
/// ```
class NeumorphicSelectField extends StatelessWidget {
  /// Creates a [NeumorphicSelectField].
  const NeumorphicSelectField({
    super.key,
    this.focusNode,
    this.autofocus = false,
    required this.value,
    this.note,
    this.onPressed,
    this.style,
  });

  /// Visual slots before the text-field component theme.
  final NeumorphicStyle? style;

  /// The currently displayed selection.
  final String value;

  /// Supporting text displayed with the primary content.
  final String? note;

  /// Called when the item is activated.
  final VoidCallback? onPressed;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    // From a medium window up, a picker is a control, not a band: at most a control's most in a wider column.
    return LayoutBuilder(
      builder: (context, box) {
        final row = _row(context);
        if (!box.hasBoundedWidth) return row;
        return Align(
          alignment: AlignmentDirectional.centerStart,
          heightFactor: 1,
          child: SizedBox(
            width: neumorphicControlWidth(
              context,
              box.maxWidth,
              neumorphicWideControlMax,
            ),
            child: row,
          ),
        );
      },
    );
  }

  Widget _row(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return NeumorphicTap(
      focusNode: focusNode,
      autofocus: autofocus,
      style: style,
      themeStyle: t.textFieldTheme,
      onPressed: onPressed,
      label: value,
      child: Builder(
        builder: (context) {
          final look = NeumorphicStyleOf([
            style,
            t.textFieldTheme,
          ], NeumorphicStatesScope.of(context));
          return NeumorphicOutOfUse(
            // Disabled reads as the other fields do.
            off: onPressed == null,
            child: NeumorphicFieldBox(
              style: style,
              child: NeumorphicFitRow(
                fill: 0,
                gap: 10,
                fillShare: .3,
                children: [
                  neumorphicLabel(
                    Text(
                      value,
                      style: t.textTheme.body
                          .merge(look.textStyle)
                          .copyWith(color: look.foreground),
                    ),
                  ),
                  if (note != null)
                    neumorphicLabel(
                      Text(
                        note!,
                        style: t.textTheme.caption
                            .merge(look.textStyle)
                            .copyWith(color: look.foreground),
                      ),
                    ),
                  Icon(
                    NeumorphicGlyphs.chevronDown,
                    size: look.iconSize ?? 18,
                    color: look.foreground ?? t.colors.inkSecondary,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The shared box of every option: raised in ink; selected, pressed with an LED in its corner, so it reads with no shadow.
///
/// ```dart
/// NeumorphicChoiceBox(selected: true, onPressed: () {}, child: Text('Morning'))
/// ```
class NeumorphicChoiceBox extends StatelessWidget {
  /// Creates a [NeumorphicChoiceBox].
  const NeumorphicChoiceBox({
    super.key,
    this.focusNode,
    this.autofocus = false,
    required this.child,
    this.selected = false,
    this.padding = const EdgeInsets.all(12),
    this.onPressed,
    this.label,
    this.hint,
    this.many = false,
    this.inGroup = false,
    this.style,
  });

  /// Face, outline and padding before the option component theme.
  final NeumorphicStyle? style;

  /// The content placed inside this component.
  final Widget child;

  /// Whether this item is selected.
  final bool selected;

  /// Space between the face and its content, before any shape inset.
  final EdgeInsetsGeometry padding;

  /// Called when the item is activated.
  final VoidCallback? onPressed;

  /// The text identifying this item or control.
  final String? label;

  /// An accessible description of what selecting this option does.
  final String? hint;

  /// Announce a checked choice when multiple choices are allowed.
  final bool many;

  /// Announce membership of a mutually exclusive group.
  final bool inGroup;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final padding = this.padding.resolve(Directionality.of(context));
    final t = NeumorphicTheme.of(context);
    return NeumorphicTap(
      focusNode: focusNode,
      autofocus: autofocus,
      style: style,
      themeStyle: t.optionTheme,
      onPressed: onPressed,
      label: label,
      selected: many ? null : selected,
      checked: many ? selected : null,
      inMutuallyExclusiveGroup: inGroup,
      button: !many,
      semanticHint: hint,
      // The box takes the room it is given (a grid's cell), so the chosen LED stands in its own corner, not the cell's.
      // Out of use it reads as the buttons do: flat, flush with the ground, its ink quiet.
      child: NeumorphicOutOfUse(
        off: onPressed == null,
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.passthrough,
          children: [
            NeumorphicSurface(
              style: style,
              themeStyle: t.optionTheme,
              states: {
                if (selected) WidgetState.selected,
                if (onPressed == null) WidgetState.disabled,
              },
              cast: selected
                  ? NeumorphicSurfaceLevel.groove
                  : NeumorphicSurfaceLevel.part,
              outlined: true,
              radius: NeumorphicRadii.control,
              padding: padding,
              child: child,
            ),
            // Chosen carries the pigment as an LED, so it reads with no shadow visible. It is concentric with the corner,
            // its centre on the curve's centre (a control's 12), so it sits as far from the curve as from both edges:
            // at 11 in it stood off the curve's middle, and read as jammed towards the corner.
            if (selected)
              const PositionedDirectional(
                top: NeumorphicRadii.control - 4,
                end: NeumorphicRadii.control - 4,
                child: NeumorphicLed(),
              ),
          ],
        ),
      ),
    );
  }
}

/// One option of a [NeumorphicChoices].
class NeumorphicChoice {
  /// Creates a [NeumorphicChoice].
  const NeumorphicChoice(this.label, {this.note, String? value})
    : value = value ?? label;

  /// The text identifying this item or control.
  final String label;

  /// The stable value returned when this choice is selected.
  final String value;

  /// Supporting text displayed with the primary content.
  final String? note;
}

double _wholeWidth(String text, TextStyle style, TextScaler textScaler) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textScaler: textScaler,
    textDirection: TextDirection.ltr,
  )..layout();
  final w = tp.width;
  tp.dispose();
  return w;
}

/// One choice from a few, as tiles: a filter, a grade, a size, a kind. Give it the words: it puts as many on a row as hold
/// their longest word, and the rest on the next rows, so no tile crushes. Never write this as a `Row` of `Expanded` boxes.
///
/// ```dart
/// NeumorphicChoices(options: const [NeumorphicChoice('All'), NeumorphicChoice('Some', note: 'A small note')], value: 'All', onChanged: (v) {})
/// ```
class NeumorphicChoices extends StatelessWidget {
  /// Creates a [NeumorphicChoices].
  const NeumorphicChoices({
    super.key,
    required this.options,
    this.value,
    this.onChanged,
    this.style,
  });

  /// Per-option state styling.
  final NeumorphicStyle? style;

  /// The available choices, in display order.
  final List<NeumorphicChoice> options;

  /// The value of the value option; none, if null.
  final String? value;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final words = t.textTheme.caption.copyWith(fontWeight: FontWeight.w700);
    final notes = options.any((o) => o.note != null);
    return LayoutBuilder(
      builder: (context, box) {
        const pad = 12.0, gap = 10.0;
        var need = notes ? 104.0 : 56.0;
        for (final o in options) {
          // A short label stays on one line; a long one may wrap, between its words.
          final holds = o.label.length <= 16
              ? _wholeWidth(o.label, words, MediaQuery.textScalerOf(context))
              : neumorphicWidestWord(
                  o.label,
                  words,
                  textScaler: MediaQuery.textScalerOf(context),
                );
          need = math.max(need, holds + 2 * pad + 18);
        }
        final w = box.hasBoundedWidth ? box.maxWidth : 390.0;
        // From 600 up a tile keeps to its words and note (at most 240), the row starting on the column's edge; below,
        // the tiles share the column.
        final wide = MediaQuery.sizeOf(context).width >= 600;
        if (wide) {
          for (final o in options) {
            if (o.note == null) continue;
            need = math.max(
              need,
              _wholeWidth(
                    o.note!,
                    t.textTheme.micro,
                    MediaQuery.textScalerOf(context),
                  ) +
                  2 * pad +
                  18,
            );
          }
          need = need.clamp(140.0, 240.0);
        }
        var columns = math.max(
          1,
          math.min(options.length, ((w + gap) / (need + gap)).floor()),
        );
        // One left alone on its row reads worse than a row one shorter.
        if (columns > 1 && options.length % columns == 1) columns -= 1;
        final grid = NeumorphicGridOf(
          columns: columns,
          gap: gap,
          runGap: gap,
          children: [
            for (final o in options)
              NeumorphicChoiceBox(
                style: style,
                selected: o.value == value,
                padding: const EdgeInsets.symmetric(
                  horizontal: pad,
                  vertical: 10,
                ),
                label: o.label,
                onPressed: onChanged == null ? null : () => onChanged!(o.value),
                child: Builder(
                  builder: (context) {
                    final look = NeumorphicStyleOf(
                      [style, t.optionTheme],
                      {
                        ...NeumorphicStatesScope.of(context),
                        if (o.value == value) WidgetState.selected,
                        if (onChanged == null) WidgetState.disabled,
                      },
                    );
                    return SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: notes
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            o.label,
                            style:
                                (o.value == value
                                        ? words
                                        : words.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ))
                                    .merge(look.textStyle)
                                    .copyWith(color: look.foreground),
                            textAlign: notes
                                ? TextAlign.start
                                : TextAlign.center,
                          ),
                          if (o.note != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              o.note!,
                              style: t.textTheme.micro
                                  .merge(look.textStyle)
                                  .copyWith(color: look.foreground),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
        if (!wide) return grid;
        return Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          child: SizedBox(
            width: math.min(w, columns * need + (columns - 1) * gap),
            child: grid,
          ),
        );
      },
    );
  }
}

/// A count you change: two round keys and a figure between them, the figure in the title's tabular figures so it
/// stands on the baseline of the labels and fields beside it.
///
/// ```dart
/// NeumorphicNumberField(value: '2', unit: 'people', onDecrease: () {}, onIncrease: () {})
/// ```
class NeumorphicNumberField extends StatelessWidget {
  /// Creates a [NeumorphicNumberField].
  const NeumorphicNumberField({
    super.key,
    required this.value,
    this.unit,
    this.note,
    this.onDecrease,
    this.onIncrease,
    this.style,
  });

  /// Key faces and the central value, before the stepper component theme.
  final NeumorphicStyle? style;

  /// The formatted value between the decrease and increase keys.
  final String value;

  /// A unit displayed alongside the value.
  final String? unit;

  /// Supporting text displayed with the primary content.
  final String? note;

  /// Called when the decrease key is activated; null disables that key.
  final VoidCallback? onDecrease;

  /// Called when the increase key is activated; null disables that key.
  final VoidCallback? onIncrease;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final layers = NeumorphicStyle.cascade([style, t.stepperTheme]);
    final look = NeumorphicStyleOf([layers], const {});
    final scaler = MediaQuery.textScalerOf(context);
    // As wide as its keys and its widest word: at a floor of 200 a one-figure count stood 160 px between keys that no
    // longer read as one stepper.
    final width = math.max(
      144.0,
      120 +
          math.max(
            neumorphicWidestWord(
              value,
              t.textTheme.title.tabular,
              textScaler: scaler,
            ),
            neumorphicWidestWord(
              unit ?? '',
              t.textTheme.micro,
              textScaler: scaler,
            ),
          ),
    );
    return NeumorphicColumn(
      gap: 6,
      children: [
        // The keys' faces stand on the row's ends, their targets past them: a press there still reaches them.
        NeumorphicSideReach(
          slop: (NeumorphicChromeMetrics.targetSize - t.density.height(44)) / 2,
          child: SizedBox(
            width: width.toDouble(),
            child: Row(
              children: [
                NeumorphicRoundButton(
                  NeumorphicGlyphs.minus,
                  style: layers,
                  label: NeumorphicLocalizations.of(context).less,
                  onPressed: onDecrease,
                ),
                Expanded(
                  // With both keys out of use the field is: its figure goes quiet with them. One key out (at a bound) is not.
                  child: NeumorphicOutOfUse(
                    off: onDecrease == null && onIncrease == null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value,
                          textAlign: TextAlign.center,
                          style: t.textTheme.title.tabular
                              .merge(look.textStyle)
                              .copyWith(color: look.foreground),
                        ),
                        if (unit != null)
                          Text(
                            unit!,
                            textAlign: TextAlign.center,
                            style: t.textTheme.micro,
                          ),
                      ],
                    ),
                  ),
                ),
                NeumorphicRoundButton(
                  NeumorphicGlyphs.plus,
                  style: layers,
                  label: NeumorphicLocalizations.of(context).more,
                  onPressed: onIncrease,
                ),
              ],
            ),
          ),
        ),
        if (note != null) Text(note!, style: t.textTheme.caption),
      ],
    );
  }
}

class _SwitchPainter extends CustomPainter {
  _SwitchPainter(
    this.on,
    this.c,
    this.flat,
    this.size,
    this.position, {
    this.border,
    this.knobBorder,
    this.fill,
    this.foreground,
    this.side,
    this.elevation = const NeumorphicElevation(),
    this.rule = 1,
  });
  final double position, rule;
  final bool on, flat;
  final NeumorphicColors c;
  final Size size;
  final OutlinedBorder? border, knobBorder;
  final Color? fill, foreground;
  final BorderSide? side;
  final NeumorphicElevation elevation;
  @override
  void paint(Canvas canvas, Size s) {
    final slot = Rect.fromCenter(
      center: s.center(Offset.zero),
      width: size.width,
      height: size.height,
    );
    final outline = border ?? NeumorphicRoundedBorder(radius: size.height / 2);
    final shape = outline.getOuterPath(slot);
    neumorphicPaintPressed(
      canvas,
      shape,
      c,
      light: (const Offset(-2, -2), 4),
      dark: (const Offset(2, 2), 4),
      lightColor: on ? c.pigmentHi.withValues(alpha: .35) : null,
      darkColor: on
          ? c.pigmentDk.withValues(alpha: .7)
          : c.shadowInset.withValues(alpha: c.dark ? .9 : .55),
      face: fill != null
          ? cssLinear(slot, 145, [fill!, fill!])
          : on
          ? cssLinear(slot, 145, [c.pigmentDk, c.pigment])
          : null,
      flat: flat,
      elevation: elevation,
    );
    // No rim of its own is BorderSide.none, not null: read as null, so a flat off track still prints its outline (taking
    // none for a rim left the knob alone on the wall, a ring that read as a radio).
    if (side != null && side!.style != BorderStyle.none) {
      outline.copyWith(side: side!).paint(canvas, slot);
    } else if (flat && !on) {
      // Flat, an off track has no groove left: its outline is printed in the quiet ink, so the knob still has a
      // track to sit in (alone it read as a lone ring, not a switch).
      outline
          .copyWith(
            side: BorderSide(color: c.quiet, width: rule),
          )
          .paint(canvas, slot);
    }
    final knob = Rect.fromCircle(
      center: Offset(
        slot.left + size.height / 2 + (slot.width - size.height) * position,
        slot.center.dy,
      ),
      radius: size.height * .375,
    );
    final knobShape = knobBorder?.getOuterPath(knob) ?? (Path()..addOval(knob));
    neumorphicPaintRaised(
      canvas,
      knobShape,
      c,
      light: (const Offset(-1, -1), 2),
      dark: (const Offset(2, 2), 5),
      lightColor: c.highlightSoft,
      face: cssLinear(knob, 145, [
        foreground ?? c.domeLight,
        foreground ?? c.domeMid,
      ]),
      flat: flat,
      elevation: elevation,
    );
    if (flat && !on) {
      (knobBorder ?? const NeumorphicCircleBorder())
          .copyWith(
            side: BorderSide(color: c.quiet, width: rule),
          )
          .paint(canvas, knob);
    }
    // The thumb's printed mark says the state without colour or shadow: a bar for on, a ring for off. The bar is the
    // pigment by night too: the thumb is plaster, and the dark ink that stands on the pigment vanished on it.
    if (on) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: knob.center, width: 2, height: 10),
          const Radius.circular(1),
        ),
        neumorphicFillPaint(c.pigment),
      );
    } else {
      canvas.drawCircle(
        knob.center,
        4,
        neumorphicStrokePaint(c.inkTertiary, rule * 2),
      );
    }
  }

  @override
  bool shouldRepaint(_SwitchPainter o) =>
      o.on != on ||
      o.c != c ||
      o.flat != flat ||
      o.position != position ||
      o.size != size ||
      o.border != border ||
      o.knobBorder != knobBorder ||
      o.fill != fill ||
      o.foreground != foreground ||
      o.side != side ||
      o.elevation != elevation ||
      o.rule != rule;
}

/// The slotted switch: a 56 by 32 face inside a padded activation target.
/// The pigment slot, the sliding thumb and the thumb's printed mark (a bar on, a ring off) indicate its value; with no
/// [onChanged] it is disabled and lies flat.
///
/// ```dart
/// NeumorphicSwitch(value: true, onChanged: (v) {})
/// ```
class NeumorphicSwitch extends StatelessWidget {
  /// Creates a [NeumorphicSwitch].
  const NeumorphicSwitch({
    super.key,
    this.autofocus = false,
    required this.value,
    this.onChanged,
    this.focusNode,
    this.style,
    this.label,
  });

  /// Whether the switch is on.
  final bool value;

  /// An optional externally owned focus node.
  final FocusNode? focusNode;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<bool>? onChanged;

  /// The setting announced with its on/off value. Supply this for a standalone
  /// switch; [NeumorphicSwitchRow] owns the label for its decorative switch.
  final String? label;

  /// Track fill, knob ink, rim and shape before the switch theme.
  final NeumorphicStyle? style;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final initial = NeumorphicStyleOf(
      [style, t.switchTheme],
      {
        if (value) WidgetState.selected,
        if (onChanged == null) WidgetState.disabled,
      },
    );
    final size = Size(
      math.max(56, initial.minimumSize?.width ?? 0),
      math.max(32, initial.minimumSize?.height ?? 0),
    );
    final mirror = Directionality.of(context) == TextDirection.rtl;
    final motion = NeumorphicMotion.of(context);
    return neumorphicOwnSize(
      width: size.width,
      height: _targetSize(math.max(44, size.height)),
      child: NeumorphicTap(
        autofocus: autofocus,
        label: label,
        toggled: value,
        focusNode: focusNode,
        button: false,
        style: style,
        themeStyle: t.switchTheme,
        shape: t.shapes.capsule,
        onPressed: onChanged == null ? null : () => onChanged!(!value),
        radius: 16,
        focusSize: size,
        child: Builder(
          builder: (context) {
            final states = {
              ...NeumorphicStatesScope.of(context),
              if (value) WidgetState.selected,
            };
            final look = NeumorphicStyleOf([style, t.switchTheme], states);
            // The track is the switch's face, whichever end its thumb stands at: marked for ui_core's checks, which
            // would read an off switch's ground-coloured track by its thumb alone.
            final paint = DesignKeylineFace(
              child: RepaintBoundary(
                child: AnimatedNeumorphicShape(
                  shape: look.shape ?? t.shapes.capsule,
                  builder: (context, border) => TweenAnimationBuilder<double>(
                    tween: Tween(end: value ? 1 : 0),
                    duration: motion.state,
                    curve: motion.standard,
                    builder: (context, position, _) => CustomPaint(
                      painter: _SwitchPainter(
                        value,
                        t.colors,
                        NeumorphicFlatScope.of(context),
                        size,
                        position,
                        border: border,
                        // The thumb is the track moved in by its inset: round in a capsule, square in a square track,
                        // concentric either way.
                        knobBorder: NeumorphicShapes.inset(
                          border ??
                              NeumorphicRoundedBorder(radius: size.height / 2),
                          size.height * .125,
                        ),
                        fill: look.fill,
                        foreground: look.foreground,
                        side:
                            look.side ??
                            (look.edge != null || t.highContrast
                                ? BorderSide(
                                    color: look.edge ?? t.colors.edge,
                                    width: neumorphicEdgeWidth,
                                  )
                                : BorderSide.none),
                        elevation: t.elevation,
                        rule: neumorphicRuleWidth,
                      ),
                    ),
                  ),
                ),
              ),
            );
            // Disabled reads as the other controls do: flat, flush with the ground, its ink quiet.
            return NeumorphicOutOfUse(
              off: onChanged == null,
              child: mirror ? Transform.flip(flipX: true, child: paint) : paint,
            );
          },
        ),
      ),
    );
  }
}

/// A line of words and its switch: a setting. The words say on or off; the switch doesn't have to say it alone.
///
/// ```dart
/// NeumorphicSwitchRow(label: 'Reminders', note: 'On, at 09:00', value: true, onChanged: (v) {})
/// ```
class NeumorphicSwitchRow extends StatelessWidget {
  /// Creates a [NeumorphicSwitchRow].
  const NeumorphicSwitchRow({
    super.key,
    this.autofocus = false,
    required this.label,
    this.note,
    required this.value,
    this.onChanged,
    this.focusNode,
    this.leading,
    this.style,
  });

  /// Switch face and setting words before the switch theme.
  final NeumorphicStyle? style;

  /// The text identifying this item or control.
  final String label;

  /// Supporting text displayed with the primary content.
  final String? note;

  /// Whether the switch is on.
  final bool value;

  /// Focus for the whole switch row.
  final FocusNode? focusNode;

  /// A decorative mark inside the row's single activation target.
  final Widget? leading;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<bool>? onChanged;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return NeumorphicTap(
      autofocus: autofocus,
      style: style,
      themeStyle: t.switchTheme,
      label: label,
      semanticHint: note,
      toggled: value,
      button: false,
      // A row that holds a control passes its press to the control: the row stays flat and the control moves.
      pressRelief: false,
      focusNode: focusNode,
      onPressed: onChanged == null ? null : () => onChanged!(!value),
      child: Builder(
        builder: (context) {
          final look = NeumorphicStyleOf(
            [style, t.switchTheme],
            {
              ...NeumorphicStatesScope.of(context),
              if (value) WidgetState.selected,
            },
          );
          return NeumorphicFitRow(
            fill: leading == null ? 0 : 1,
            gap: 14,
            children: [
              if (leading != null) ExcludeSemantics(child: leading!),
              // A disabled setting's words fade with its switch.
              NeumorphicOutOfUse(
                off: onChanged == null,
                child: NeumorphicColumn(
                  children: [
                    Text(
                      label,
                      style: t.textTheme.title
                          .merge(look.textStyle)
                          .copyWith(color: look.foreground),
                    ),
                    if (note != null)
                      Text(
                        note!,
                        style: t.textTheme.caption
                            .merge(look.textStyle)
                            .copyWith(
                              color: look.foreground ?? t.colors.inkTertiary,
                            ),
                      ),
                  ],
                ),
              ),
              ExcludeFocus(
                child: ExcludeSemantics(
                  child: IgnorePointer(
                    child: NeumorphicSwitch(
                      value: value,
                      style: style,
                      onChanged: onChanged == null ? null : (_) {},
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SliderPainter extends CustomPainter {
  _SliderPainter(
    this.at,
    this.c,
    this.flat,
    this.h,
    this.thumb,
    this.rtl, {
    this.border,
    this.knobBorder,
    this.fill,
    this.foreground,
    this.side,
    this.elevation = const NeumorphicElevation(),
  });
  final OutlinedBorder? border, knobBorder;
  final Color? fill, foreground;
  final BorderSide? side;
  final NeumorphicElevation elevation;
  final double at, h, thumb;
  final NeumorphicColors c;
  final bool flat, rtl;
  @override
  void paint(Canvas canvas, Size s) {
    final y = s.height / 2;
    final track = Rect.fromLTWH(0, y - h / 2, s.width, h);
    final r = Radius.circular(h / 2);
    // By night a groove this narrow is mostly its shadow, which the dark wall swallows: its floor takes a shade of the
    // quiet ink, so the reach past the thumb still shows.
    final floor = Color.lerp(c.ground, c.inkTertiary, .22)!;
    final groove =
        border?.getOuterPath(track) ??
        (Path()..addRRect(RRect.fromRectAndRadius(track, r)));
    neumorphicPaintPressed(
      canvas,
      groove,
      c,
      light: (const Offset(-3, -3), 7),
      dark: (const Offset(3, 3), 7),
      face: c.dark ? cssLinear(track, 90, [floor, floor]) : null,
      flat: flat,
      elevation: elevation,
    );
    (border ?? NeumorphicRoundedBorder(radius: h / 2))
        .copyWith(side: side ?? BorderSide.none)
        .paint(canvas, track);
    final x = rtl ? s.width * (1 - at) : s.width * at;
    if (at > 0) {
      final filled = rtl
          ? Rect.fromLTRB(x, track.top, track.right, track.bottom)
          : Rect.fromLTRB(track.left, track.top, x, track.bottom);
      // The fill is the groove's floor where it reaches, under the groove's own shade in the pigment's tones: laid
      // over the groove, it stood fuller than the groove beside it, whose upper edge is shade (by night the dark
      // wall swallows it). Its end lies under the thumb.
      canvas.save();
      canvas.clipRect(filled);
      neumorphicPaintPressed(
        canvas,
        groove,
        c,
        light: (const Offset(-3, -3), 7),
        dark: (const Offset(3, 3), 7),
        tone: fill ?? c.pigment,
        face: cssLinear(filled, rtl ? 270 : 90, [
          fill ?? c.pigmentHi,
          fill ?? c.pigment,
        ]),
        flat: flat,
        elevation: elevation,
      );
      canvas.restore();
    }
    final knob = knobRect(s, at, thumb, rtl);
    neumorphicPaintRaised(
      canvas,
      knobBorder?.getOuterPath(knob) ?? (Path()..addOval(knob)),
      c,
      light: (const Offset(-2, -2), 5),
      dark: (const Offset(3, 3), 7),
      lightColor: c.highlightSoft,
      face: cssLinear(knob, 145, [
        foreground ?? c.domeLight,
        foreground ?? c.domeMid,
      ]),
      flat: flat,
      elevation: elevation,
    );
    // An explicit or high-contrast edge rims the thumb as it does the track, and stays visible without shadows.
    if (flat || (side != null && side!.style != BorderStyle.none)) {
      (knobBorder ?? const NeumorphicCircleBorder())
          .copyWith(side: side ?? BorderSide.none)
          .paint(canvas, knob);
    }
    // The filled track and thumb position already express the value.
  }

  /// Where the thumb stands in a slider of size [s] at [at].
  static Rect knobRect(Size s, double at, double thumb, bool rtl) {
    final x = rtl ? s.width * (1 - at) : s.width * at;
    final clamped = x.clamp(thumb / 2, s.width - thumb / 2).toDouble();
    return Rect.fromCircle(
      center: Offset(clamped, s.height / 2),
      radius: thumb / 2,
    );
  }

  @override
  bool shouldRepaint(_SliderPainter o) =>
      o.at != at ||
      o.c != c ||
      o.flat != flat ||
      o.h != h ||
      o.thumb != thumb ||
      o.rtl != rtl ||
      o.border != border ||
      o.knobBorder != knobBorder ||
      o.fill != fill ||
      o.foreground != foreground ||
      o.side != side ||
      o.elevation != elevation;
}

/// The slider's keyboard focus: its thumb, the part that moves, lifts ([neumorphicPaintFocusLift]), not the whole row.
class _ThumbLift extends CustomPainter {
  _ThumbLift(
    this.c,
    this.elevation,
    this.border,
    this.at,
    this.thumb,
    this.rtl,
  );
  final NeumorphicColors c;
  final NeumorphicElevation elevation;
  final OutlinedBorder border;
  final double at, thumb;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) => neumorphicPaintFocusLift(
    canvas,
    border.getOuterPath(_SliderPainter.knobRect(size, at, thumb, rtl)),
    c,
    reach: .6,
    elevation: elevation,
  );

  @override
  bool shouldRepaint(_ThumbLift o) =>
      o.c != c ||
      o.elevation != elevation ||
      o.border != border ||
      o.at != at ||
      o.thumb != thumb ||
      o.rtl != rtl;
}

/// A level you drag: a groove, a pigment fill, a raised round thumb. At zero the fill goes and the thumb's point turns ink.
///
/// ```dart
/// NeumorphicSlider(label: 'Level', value: .3, onChanged: (v) {})
/// ```
class NeumorphicSlider extends StatefulWidget {
  /// Creates a [NeumorphicSlider].
  const NeumorphicSlider({
    super.key,
    this.focusNode,
    this.autofocus = false,
    required this.value,
    required this.label,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChanged,
    this.onChangeEnd,
    this.valueLabel,
    this.style,
  }) : assert(max >= min),
       assert(divisions == null || divisions > 0);

  /// A level between [min] and [max].
  /// Active track fill, knob, outline and target size before the slider theme.
  final NeumorphicStyle? style;

  /// The current value, within the inclusive min/max range.
  final double value;

  /// The lower bound of the value range.
  final double min;

  /// The upper bound of the value range.
  final double max;

  /// The number of discrete intervals, or null for continuous movement.
  final int? divisions;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<double>? onChanged;

  /// The committed level after a pointer gesture or keyboard change.
  final ValueChanged<double>? onChangeEnd;

  /// A screen reader's name for this level.
  final String label;

  /// Formats the current and adjacent accessibility values.
  final String Function(double value)? valueLabel;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  State<NeumorphicSlider> createState() => _NeumorphicSliderState();
}

class _NeumorphicSliderState extends State<NeumorphicSlider> {
  bool _dragging = false;
  double? _last;
  double get _span => widget.max - widget.min;
  bool get _enabled => widget.onChanged != null && _span > 0;
  double get _step => _span / (widget.divisions ?? 20);
  double _snap(double value) {
    final at = value.clamp(widget.min, widget.max);
    if (widget.divisions == null || _span == 0) return at;
    return widget.min +
        ((at - widget.min) / _span * widget.divisions!).round() /
            widget.divisions! *
            _span;
  }

  void _drag(bool active) {
    if (_dragging != active) setState(() => _dragging = active);
  }

  void _change(double value, {bool commit = false}) {
    if (!_enabled) return;
    final next = _snap(value);
    _last = next;
    widget.onChanged!(next);
    if (commit) widget.onChangeEnd?.call(next);
  }

  void _finish() {
    _drag(false);
    if (_enabled) widget.onChangeEnd?.call(_last ?? widget.value);
    _last = null;
  }

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final enabled = _enabled;
    final words = NeumorphicLocalizations.of(context);
    String spoken(double value) =>
        widget.valueLabel?.call(_snap(value)) ??
        (widget.min == 0 && widget.max == 1
            ? words.formatPercent(_snap(value))
            : words.formatNumber(_snap(value)));
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.hasBoundedWidth ? box.maxWidth : 200.0;
        void pick(double dx) {
          if (width <= 0) return;
          final at = (dx / width).clamp(0.0, 1.0);
          _change(widget.min + (rtl ? 1 - at : at) * _span);
        }

        return SizedBox(
          width: width,
          child: MergeSemantics(
            child: Semantics(
              slider: true,
              label: widget.label,
              value: spoken(widget.value),
              increasedValue: enabled ? spoken(widget.value + _step) : null,
              decreasedValue: enabled ? spoken(widget.value - _step) : null,
              onIncrease: enabled
                  ? () => _change(widget.value + _step, commit: true)
                  : null,
              onDecrease: enabled
                  ? () => _change(widget.value - _step, commit: true)
                  : null,
              child: NeumorphicTap(
                focusNode: widget.focusNode,
                autofocus: widget.autofocus,
                style: widget.style,
                themeStyle: t.sliderTheme,
                // Its focus is the thumb's, lifted by the face below; the thumb drags, so the pointer is grab, and
                // grabbing while held.
                shape: t.shapes.capsule,
                showFocus: false,
                button: false,
                pressRelief: false,
                mouseCursor: _dragging
                    ? SystemMouseCursors.grabbing
                    : SystemMouseCursors.grab,
                onPressed: enabled ? () {} : null,
                onKeyEvent: (node, event) {
                  if (!enabled ||
                      (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
                    return KeyEventResult.ignored;
                  }
                  final key = event.logicalKey;
                  final direction = key == LogicalKeyboardKey.arrowUp
                      ? 1.0
                      : key == LogicalKeyboardKey.arrowDown
                      ? -1.0
                      : key == LogicalKeyboardKey.arrowRight
                      ? (rtl ? -1.0 : 1.0)
                      : key == LogicalKeyboardKey.arrowLeft
                      ? (rtl ? 1.0 : -1.0)
                      : 0.0;
                  if (key == LogicalKeyboardKey.home ||
                      key == LogicalKeyboardKey.end) {
                    _change(
                      key == LogicalKeyboardKey.home ? widget.min : widget.max,
                      commit: true,
                    );
                    return KeyEventResult.handled;
                  }
                  if (direction == 0) return KeyEventResult.ignored;
                  _change(widget.value + direction * _step, commit: true);
                  return KeyEventResult.handled;
                },
                child: GestureDetector(
                  excludeFromSemantics: true,
                  behavior: HitTestBehavior.opaque,
                  onTapDown: enabled
                      ? (d) {
                          _drag(true);
                          pick(d.localPosition.dx);
                        }
                      : null,
                  onTapUp: enabled ? (_) => _finish() : null,
                  onTapCancel: enabled ? () => _drag(false) : null,
                  onHorizontalDragStart: enabled ? (_) => _drag(true) : null,
                  onHorizontalDragUpdate: enabled
                      ? (d) => pick(d.localPosition.dx)
                      : null,
                  onHorizontalDragEnd: enabled ? (_) => _finish() : null,
                  onHorizontalDragCancel: enabled ? () => _drag(false) : null,
                  child: RepaintBoundary(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        end: _span == 0
                            ? 0
                            : (_snap(widget.value) - widget.min) / _span,
                      ),
                      duration: _dragging
                          ? Duration.zero
                          : NeumorphicMotion.of(context).state,
                      curve: NeumorphicMotion.of(context).standard,
                      builder: (context, at, child) {
                        final states = {
                          ...NeumorphicStatesScope.of(context),
                          if (_dragging) WidgetState.dragged,
                        };
                        final look = NeumorphicStyleOf([
                          widget.style,
                          t.sliderTheme,
                        ], states);
                        // Disabled reads as the other controls do: flat, flush with the ground, its ink quiet.
                        return NeumorphicOutOfUse(
                          off: !enabled,
                          child: AnimatedNeumorphicShape(
                            shape: look.shape ?? t.shapes.capsule,
                            builder: (context, border) => CustomPaint(
                              painter: _SliderPainter(
                                at,
                                c,
                                NeumorphicFlatScope.of(context),
                                12,
                                26,
                                rtl,
                                border: border,
                                knobBorder: t.shapes.circle(26),
                                fill: look.fill,
                                foreground: look.foreground,
                                side: neumorphicRim(t, look, c.edge, 1.5),
                                elevation: t.elevation,
                              ),
                              foregroundPainter:
                                  states.contains(WidgetState.focused)
                                  ? _ThumbLift(
                                      c,
                                      t.elevation,
                                      t.shapes.circle(26),
                                      at,
                                      26,
                                      rtl,
                                    )
                                  : null,
                              child: SizedBox(
                                height: math.max(
                                  48,
                                  look.minimumSize?.height ?? 0,
                                ),
                                width: double.infinity,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// How far along a thing is: a thin groove, a pigment fill, a thumb. Two times stand under it. For a level you set, use the slider.
///
/// ```dart
/// NeumorphicProgress(value: .21, start: '0:25:12', end: '1:58:00')
/// ```
class NeumorphicProgress extends StatelessWidget {
  /// Creates a [NeumorphicProgress].
  const NeumorphicProgress({
    super.key,
    required this.value,
    this.start,
    this.end,
  });

  /// The fraction complete, from zero to one.
  final double value;

  /// Optional text at the start of the progress track.
  final String? start;

  /// Optional text at the end of the progress track.
  final String? end;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return NeumorphicColumn(
      gap: 6,
      children: [
        CustomPaint(
          painter: _SliderPainter(
            value.clamp(0, 1).toDouble(),
            t.colors,
            NeumorphicFlatScope.of(context),
            8,
            26,
            rtl,
            border: t.shapes.capsule,
            knobBorder: t.shapes.circle(26),
            elevation: t.elevation,
          ),
          child: const SizedBox(height: 8, width: double.infinity),
        ),
        if (start != null || end != null)
          NeumorphicSplit(
            start: Text(start ?? '', style: t.textTheme.micro.tabular),
            end: Text(end ?? '', style: t.textTheme.micro.tabular),
          ),
      ],
    );
  }
}

/// A round check: open it's raised, done it's pressed with an ink tick. High contrast adds a printed ring.
///
/// ```dart
/// NeumorphicRoundCheckbox(value: true, onChanged: (v) {})
/// ```
class NeumorphicRoundCheckbox extends StatelessWidget {
  /// Creates a [NeumorphicRoundCheckbox].
  const NeumorphicRoundCheckbox({
    super.key,
    this.focusNode,
    this.autofocus = false,
    this.value = false,
    this.onChanged,
    this.style,
  });

  /// Mark face and ink before the checkbox component theme.
  final NeumorphicStyle? style;

  /// Whether the check is selected.
  final bool value;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<bool>? onChanged;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final flat = NeumorphicFlatScope.of(context);
    return _onEdge(
      28,
      neumorphicOwnSize(
        width: _targetSize(28),
        height: _targetSize(28),
        child: NeumorphicTap(
          focusNode: focusNode,
          autofocus: autofocus,
          style: style,
          themeStyle: t.checkboxTheme,
          shape: t.shapes.circle(28),
          checked: value,
          button: false,
          onPressed: onChanged == null ? null : () => onChanged!(!value),
          round: true,
          focusInset: (_targetSize(28) - 28) / 2,
          child: Builder(
            builder: (context) {
              final states = {
                ...NeumorphicStatesScope.of(context),
                if (value) WidgetState.selected,
              };
              final look = NeumorphicStyleOf([style, t.checkboxTheme], states);
              var border = look.shape ?? t.shapes.circle(28);
              if (border is NeumorphicBorder) {
                border = border.fit(const Size.square(28));
              }
              final shapeBorder = border;
              // A face of the ground's colour shows only by its shading: marked as the check's face for ui_core's
              // checks, which would place its edge by the shading's first dark pixel.
              return Center(
                child: DesignKeylineFace(
                  child: SizedBox.square(
                    dimension: 28,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        neumorphicPaint(
                          28,
                          28,
                          (
                            c,
                            value,
                            flat,
                            shapeBorder,
                            look.fill,
                            look.foreground,
                            look.edge,
                            look.side,
                            t.elevation,
                          ),
                          (canvas, s) {
                            final shape = shapeBorder.getOuterPath(
                              Offset.zero & s,
                            );
                            final mid = s.center(Offset.zero);
                            if (value) {
                              neumorphicPaintPressed(
                                canvas,
                                shape,
                                c,
                                light: (const Offset(-2, -2), 5),
                                dark: (const Offset(2, 2), 5),
                                flat: flat,
                                elevation: t.elevation,
                                face: look.fill == null
                                    ? null
                                    : cssLinear(Offset.zero & s, 145, [
                                        look.fill!,
                                        look.fill!,
                                      ]),
                              );
                            } else {
                              neumorphicPaintRaised(
                                canvas,
                                shape,
                                c,
                                light: (const Offset(-2, -2), 5),
                                dark: (const Offset(3, 3), 6),
                                flat: flat,
                                elevation: t.elevation,
                                face: look.fill == null
                                    ? null
                                    : cssLinear(Offset.zero & s, 145, [
                                        look.fill!,
                                        look.fill!,
                                      ]),
                              );
                              canvas.drawCircle(
                                mid,
                                7,
                                neumorphicStrokePaint(
                                  look.foreground ?? c.inkTertiary,
                                  2,
                                ),
                              );
                            }
                            // The check's own edge, printed: open or value, it reads with no shadow. At rest it is the
                            // 3:1 boundary a person finds the control by.
                            shapeBorder
                                .copyWith(
                                  side:
                                      look.side ??
                                      (look.edge != null || t.highContrast
                                          ? BorderSide(
                                              color: look.edge ?? c.edge,
                                              width: neumorphicEdgeWidth,
                                            )
                                          : BorderSide.none),
                                )
                                .paint(canvas, Offset.zero & s);
                          },
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(end: value ? 1 : 0),
                          duration: NeumorphicMotion.of(context).state,
                          builder: (context, opacity, _) => opacity == 0
                              ? const SizedBox.shrink()
                              : Opacity(
                                  opacity: opacity,
                                  child: Center(
                                    child: Icon(
                                      NeumorphicGlyphs.check,
                                      size: look.iconSize ?? 16,
                                      color: look.foreground ?? c.inkSecondary,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TapTarget extends SingleChildRenderObjectWidget {
  const _TapTarget({required this.minSize, required super.child});

  final Size minSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTapTarget(minSize);

  @override
  void updateRenderObject(BuildContext context, _RenderTapTarget target) =>
      target.minSize = minSize;
}

class _RenderTapTarget extends RenderShiftedBox {
  _RenderTapTarget(this._minSize) : super(null);

  Size get minSize => _minSize;
  Size _minSize;
  set minSize(Size value) {
    if (_minSize == value) return;
    _minSize = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(child?.getMinIntrinsicWidth(height) ?? 0, minSize.width);

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(child?.getMinIntrinsicHeight(width) ?? 0, minSize.height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(child?.getMaxIntrinsicWidth(height) ?? 0, minSize.width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(child?.getMaxIntrinsicHeight(width) ?? 0, minSize.height);

  Size _sized(BoxConstraints constraints, Size face) => constraints.constrain(
    Size(
      math.max(face.width, minSize.width),
      math.max(face.height, minSize.height),
    ),
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return Size.zero;
    return _sized(constraints, child.getDryLayout(constraints));
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final child = this.child;
    if (child == null) return null;
    final at = child.getDryBaseline(constraints, baseline);
    if (at == null) return null;
    final face = child.getDryLayout(constraints);
    return at +
        Alignment.center
            .alongOffset(_sized(constraints, face) - face as Offset)
            .dy;
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = Size.zero;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = _sized(constraints, child.size);
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(
      size - child.size as Offset,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    final child = this.child;
    if (child == null || !size.contains(position)) return false;
    final centre = child.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(centre),
      position: centre,
      hitTest: (result, position) => child.hitTest(result, position: centre),
    );
  }
}

/// [child], a face [face] wide centred in its target, with its first drawn pixel on the box's edge: the target's side
/// margins reach past the box, hit-tested and spoken, never laid out (NeumorphicFaceEdge).
Widget _onEdge(double face, Widget child) {
  final slop = (_targetSize(face) - face) / 2;
  return slop <= 0 ? child : NeumorphicFaceEdge(slop: slop, child: child);
}

double _targetSize(double face) =>
    math.max(NeumorphicChromeMetrics.targetSize, face);

/// A collapsed decoration with every field that could size or draw it set here, so no theme default reaches it: no
/// padding, no borders, no fill, standard density and no constraints (an unset one takes the theme's). It carries
/// the hint only, [hint] or a [hintWidget]; icons, buttons, counters, help and error are the look's own widgets
/// beside or under the box.
InputDecoration _bareDecoration({
  String? hint,
  Widget? hintWidget,
  TextStyle? hintStyle,
  int hintLines = 1,
}) => InputDecoration(
  isCollapsed: true,
  isDense: false,
  contentPadding: EdgeInsets.zero,
  hintText: hintWidget == null ? hint : null,
  hint: hintWidget,
  hintStyle: hintStyle,
  hintMaxLines: hintLines,
  filled: false,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  focusedErrorBorder: InputBorder.none,
  visualDensity: VisualDensity.standard,
  constraints: const BoxConstraints(),
);
