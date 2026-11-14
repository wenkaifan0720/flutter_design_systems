import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../internal/hit_slop.dart';
import '../../theme.dart';

/// What a [Fluent2Pressable] is to assistive technology.
enum Fluent2PressRole {
  /// It does something.
  button,

  /// It goes somewhere.
  link,
}

/// The step of Fluent's colour aliases a face is drawn in: at rest, under
/// the pointer, pressed, or disabled, as Fluent's `Hover`, `Pressed` and
/// `Disabled` aliases step. Read from a press's states with
/// [Fluent2PressStates.press].
enum Fluent2Press {
  /// Neither under the pointer nor pressed.
  rest,

  /// Under the pointer.
  hover,

  /// Under a press.
  pressed,

  /// Taking no presses.
  disabled;

  /// The colour of [rest], [hover] or [pressed] by this state; [disabled]
  /// when given, else [rest].
  Color pick(Color rest, Color hover, Color pressed, [Color? disabled]) =>
      switch (this) {
        Fluent2Press.rest => rest,
        Fluent2Press.hover => hover,
        Fluent2Press.pressed => pressed,
        Fluent2Press.disabled => disabled ?? rest,
      };
}

/// A press's states read by name, for a face that draws its own:
/// `states.hovered`, `states.pressed`, and [press] for Fluent's colour step.
extension Fluent2PressStates on Set<WidgetState> {
  /// Under the pointer.
  bool get hovered => contains(WidgetState.hovered);

  /// Holding the keyboard's focus (only while the keyboard moved it).
  bool get focused => contains(WidgetState.focused);

  /// Under a press.
  bool get pressed => contains(WidgetState.pressed);

  /// Taking presses: not disabled.
  bool get enabled => !contains(WidgetState.disabled);

  /// Chosen, ticked, or on.
  bool get selected => contains(WidgetState.selected);

  /// Holding something wrong.
  bool get error => contains(WidgetState.error);

  /// The step of Fluent's colour aliases these states draw: disabled first,
  /// then pressed, then hover, else rest.
  Fluent2Press get press => contains(WidgetState.disabled)
      ? Fluent2Press.disabled
      : pressed
      ? Fluent2Press.pressed
      : hovered
      ? Fluent2Press.hover
      : Fluent2Press.rest;
}

/// Makes a face a Fluent 2 control. Every control in this library stands on
/// it; place one yourself only to make a row or a tile you composed one tap
/// target.
///
/// It stands on the design kit's `DesignPressable`: a tap and a long press,
/// Enter and Space through the app's shortcuts, the pointer's hover and
/// click cursor, keyboard focus, and one semantics node with the control's
/// role and state ([role], [selected], [toggled], [checked], [mixed],
/// [inGroup], [expanded]). [builder] gets the press's `Set<WidgetState>`;
/// [Fluent2PressStates.press] turns it into Fluent's rest, hover, pressed
/// and disabled colour step. While the keyboard holds focus it draws
/// Fluent's focus indicator over the face: a 2 stroke of `strokeFocus2` on
/// the face's edge and a 1 stroke of `strokeFocus1` inside it, [radius]
/// round, [ringInsets] in from the box.
///
/// A null [onPressed] (and no [onLongPress]) makes it disabled: the face is
/// drawn disabled, the node is announced as disabled, and nothing answers a
/// tap or a key. [label] is the spoken name; it replaces what the face says
/// when [excludeChild] is true.
///
/// ```dart
/// Fluent2Pressable(onPressed: open, label: 'Open file', builder: (context, states) => ColoredBox(color: states.press.pick(rest, hover, pressed), child: row))
/// ```
class Fluent2Pressable extends StatelessWidget {
  /// A control drawn by [builder], or [child] in every state.
  const Fluent2Pressable({
    super.key,
    required this.onPressed,
    this.child,
    this.builder,
    this.label,
    this.value,
    this.hint,
    this.role = Fluent2PressRole.button,
    this.selected,
    this.toggled,
    this.checked,
    this.mixed = false,
    this.inGroup = false,
    this.expanded,
    this.isError = false,
    this.radius = 4,
    this.shape,
    this.ringInsets = EdgeInsets.zero,
    this.ring = true,
    this.excludeChild = true,
    this.semantics = true,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
    this.keys,
    this.mouseCursor,
    this.statesController,
    this.padded = true,
    this.faceAlignment = AlignmentDirectional.center,
  }) : assert(
         (child == null) != (builder == null),
         'a pressable draws a child or a builder, one of the two',
       );

  /// What a press does; null (with no [onLongPress]) makes it disabled.
  final VoidCallback? onPressed;

  /// The face, drawn the same in every state.
  final Widget? child;

  /// The face, drawn for the press's states.
  final Widget Function(BuildContext context, Set<WidgetState> states)? builder;

  /// The spoken name; null leaves the face's own words.
  final String? label;

  /// The spoken value after the name.
  final String? value;

  /// The spoken hint after the value.
  final String? hint;

  /// A button (the default) or a link.
  final Fluent2PressRole role;

  /// Set for one option of a set (a tab, a chip): chosen or not.
  final bool? selected;

  /// Set for an on/off control (a switch, a toggle button): on or off.
  final bool? toggled;

  /// Set for a checkbox or a radio: ticked or not.
  final bool? checked;

  /// A checkbox partly ticked.
  final bool mixed;

  /// One of a set where only one is chosen: a radio.
  final bool inGroup;

  /// Set for a disclosure: open or not.
  final bool? expanded;

  /// What it holds is wrong: the face gets [WidgetState.error].
  final bool isError;

  /// The corner radius of the focus ring.
  final double radius;

  /// The focus ring's outline for the press's states, when the face is a
  /// styled shape; null (or null for the states) rounds it [radius].
  final WidgetStateProperty<OutlinedBorder?>? shape;

  /// How far inside the box the ringed face stands.
  final EdgeInsetsGeometry ringInsets;

  /// False when the face draws its own focus ring from `states.focused`.
  final bool ring;

  /// Whether the face's own semantics are replaced by [label].
  final bool excludeChild;

  /// False when the control around it says what it is: the press then adds
  /// no words, role or state of its own.
  final bool semantics;

  /// Its focus node, when the caller moves focus itself.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  /// What a long press does (a row's context menu on a phone).
  final VoidCallback? onLongPress;

  /// More keys while it holds focus, beside Enter and Space (arrows on a
  /// radio group).
  final Map<LogicalKeyboardKey, VoidCallback>? keys;

  /// The pointer over it. Null: a click where it presses.
  final MouseCursor? mouseCursor;

  /// The states, when the caller watches or drives them.
  final WidgetStatesController? statesController;

  /// Whether, where a touch reaches it ([Fluent2Layout.padded]), the press
  /// stands at least 48 square as Material's padded tap target does: the
  /// face keeps its size, centred, the room round it takes the touch, and
  /// the press's semantics node is the whole target. False where the
  /// control around it holds the target.
  final bool padded;

  /// Where the face stands in its padded target: centred, or, for two
  /// presses joined as one control (a tag and its dismiss), each against
  /// the other so no gap opens between them.
  final AlignmentGeometry faceAlignment;

  bool get _live => onPressed != null || onLongPress != null;

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final action = keys?[event.logicalKey];
    if (!_live || action == null) return KeyEventResult.ignored;
    action();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final on = (selected ?? false) || (checked ?? false) || (toggled ?? false);
    final drawn = builder;
    final face = child;
    return DesignPressable(
      onPressed: onPressed,
      onLongPress: onLongPress,
      selected: on,
      isError: isError,
      statesController: statesController,
      focusNode: focusNode,
      autofocus: autofocus,
      mouseCursor: mouseCursor,
      onKeyEvent: keys == null || keys!.isEmpty ? null : _key,
      semanticLabel: semantics ? label : null,
      semanticValue: semantics ? value : null,
      semanticHint: semantics ? hint : null,
      button: semantics && role == Fluent2PressRole.button,
      link: semantics && role == Fluent2PressRole.link,
      semanticSelected: semantics ? selected : null,
      checked: semantics ? checked : null,
      mixed: semantics && mixed,
      toggled: semantics ? toggled : null,
      expanded: semantics ? expanded : null,
      inMutuallyExclusiveGroup: semantics && inGroup,
      excludeSemantics: !semantics || (excludeChild && label != null),
      // Fluent's controls answer a press with their own face, not a click.
      enableFeedback: false,
      builder: (context, states, _) {
        final shown = drawn != null ? drawn(context, states) : face!;
        final ringAt = ringInsets.resolve(Directionality.maybeOf(context));
        final ringed = !ring || !states.focused
            ? shown
            : Stack(
                fit: StackFit.passthrough,
                clipBehavior: Clip.none,
                children: [
                  shown,
                  Positioned.fromRelativeRect(
                    rect: RelativeRect.fromLTRB(
                      ringAt.left,
                      ringAt.top,
                      ringAt.right,
                      ringAt.bottom,
                    ),
                    child: IgnorePointer(
                      child: Fluent2FocusRing(
                        radius: radius,
                        shape: shape?.resolve(states),
                      ),
                    ),
                  ),
                ],
              );
        if (!padded || !Fluent2Layout.padded(context)) return ringed;
        return Fluent2TapTarget(
          minSize: const Size.square(Fluent2Layout.touchHitTarget),
          alignment: faceAlignment,
          child: ringed,
        );
      },
    );
  }
}

/// Fluent's focus indicator, filling its box: a 2 stroke of `strokeFocus2`
/// on the edge and a 1 stroke of `strokeFocus1` inside it, [radius] round
/// (or along [shape]). The two tones stand apart on any fill, so the ring reads on a
/// brand or a selected face as on the page. A [Fluent2Pressable] draws it
/// while the keyboard holds focus; a control that draws its own ring (one
/// that takes text) places it the same way.
///
/// ```dart
/// Positioned.fill(child: Fluent2FocusRing(radius: 4))
/// ```
class Fluent2FocusRing extends StatelessWidget {
  /// A focus ring [radius] round, or along [shape].
  const Fluent2FocusRing({super.key, this.radius = 4, this.shape});

  /// The ringed face's corner radius.
  final double radius;

  /// The ringed face's outline, when it is a styled shape; it wins over
  /// [radius].
  final OutlinedBorder? shape;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final outer = Fluent2ChromeMetrics.focusOuter;
    final drawn = shape;
    if (drawn != null) {
      return DecoratedBox(
        decoration: ShapeDecoration(
          shape: drawn.copyWith(
            side: BorderSide(color: c.strokeFocus2, width: outer),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(outer),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: drawn.copyWith(
                side: BorderSide(
                  color: c.strokeFocus1,
                  width: Fluent2ChromeMetrics.focusInner,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.strokeFocus2, width: outer),
      ),
      child: Padding(
        padding: EdgeInsets.all(outer),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              (radius - outer).clamp(0, double.infinity),
            ),
            border: Border.all(
              color: c.strokeFocus1,
              width: Fluent2ChromeMetrics.focusInner,
            ),
          ),
        ),
      ),
    );
  }
}
