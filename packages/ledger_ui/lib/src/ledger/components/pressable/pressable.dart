import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../internal/field_frame.dart';
import '../../theme.dart';

/// What a [LedgerPressable] is to assistive technology.
enum LedgerPressRole {
  /// A button: it acts.
  button,

  /// A link: it goes somewhere.
  link,
}

/// The one press machine every Ledger control rides, on ui_core's
/// [RawButton]: the tap, the pointer's click cursor, keyboard focus
/// with Enter and Space, and the semantics of the control it makes (a
/// button or a link, enabled or not, selected, checked or toggled). Ledger
/// says each state in its rules and its ink, never in light or depth: a
/// press leaves the face where it is and deepens its marks a shade toward
/// the ink, like a stamp pressed harder, and the bare paper of its box (its
/// corners [radius] round) takes the same ink under them, so a face drawn
/// in the ink itself still shows it ([LedgerImpression]); keyboard
/// focus rules the accountant's double rule in the ink under the face
/// ([LedgerFocusRing]), only while the keyboard moved focus; a hover or a
/// press inks a row's dot leader in ([LedgerPressStates] carries them to
/// the face). Each change moves in Ledger's one motion ([LedgerEase],
/// [LedgerFace]): the impression fades in and out, the rule is drawn in as
/// a pen draws it, and a change mid-way turns from where it is. Plumbing of
/// the components; a page places one only to make a row or card it
/// composed by hand one tap target.
///
/// A null [onTap] makes it inert: the child is drawn as it is, the node is
/// announced as disabled, and nothing answers a tap or a key. [semanticLabel] is the
/// spoken name and replaces what the child says when [excludeChild] is true.
class LedgerPressable extends StatelessWidget {
  /// A control of [child] that calls [onTap].
  const LedgerPressable({
    required this.onTap,
    required this.child,
    this.semanticLabel,
    this.value,
    this.hint,
    this.role = LedgerPressRole.button,
    this.selected,
    this.toggled,
    this.checked,
    this.mixed = false,
    this.inMutuallyExclusiveGroup = false,
    this.expanded,
    this.isError = false,
    this.radius = 0,
    this.ringInsets = EdgeInsets.zero,
    this.rulesFocus = true,
    this.excludeChild = true,
    this.pressedOpacity = 1,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
    super.key,
  }) : assert(radius >= 0),
       assert(pressedOpacity >= 0 && pressedOpacity <= 1);

  /// What a press does; null makes the control inert.
  final VoidCallback? onTap;

  /// What a long press does, when anything.
  final VoidCallback? onLongPress;

  /// The control's face.
  final Widget child;

  /// The spoken name; null leaves the child's own semantics.
  final String? semanticLabel;

  /// The spoken value after the name (the month a switch shows).
  final String? value;

  /// The spoken hint after the value (what a press does, when the name
  /// does not say it).
  final String? hint;

  /// What the control is to assistive technology.
  final LedgerPressRole role;

  /// Set for one option of a set (a tab, a chip): chosen or not.
  final bool? selected;

  /// Set for an on/off control (a switch, a heart): on or off.
  final bool? toggled;

  /// Set for a checkbox or a radio: ticked or not.
  final bool? checked;

  /// A checkbox partly ticked.
  final bool mixed;

  /// One of a set where only one is chosen: a radio.
  final bool inMutuallyExclusiveGroup;

  /// Set for a disclosure (a select's menu): open or not.
  final bool? expanded;

  /// What it holds is wrong: the node says so.
  final bool isError;

  /// The face's corner radius: the focus rule keeps to the straight run of
  /// its foot, and a press's wash of the paper rounds its corners by it.
  final double radius;

  /// How far inside the child's box the face stands.
  final EdgeInsetsGeometry ringInsets;

  /// Whether keyboard focus rules the double rule under the face. False
  /// where the face writes focus in its own words instead (an option in an
  /// open list doubles the rule under its words, on its own row, where a
  /// rule across the list would read as a break between options); such a
  /// face reads focus from [LedgerPressStates].
  final bool rulesFocus;

  /// Whether the child's own semantics are replaced by [semanticLabel].
  final bool excludeChild;

  /// The face's opacity while a finger is down; 1, the default, deepens its
  /// ink instead ([LedgerImpression]).
  final double pressedOpacity;

  /// The caller's focus node, which the caller disposes; null keeps one of
  /// the pressable's own.
  final FocusNode? focusNode;

  /// {@macro ledger.autofocus}
  final bool autofocus;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap))
      ..add(ObjectFlagProperty<VoidCallback>.has('onLongPress', onLongPress))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(StringProperty('value', value, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(EnumProperty<LedgerPressRole>('role', role))
      ..add(DiagnosticsProperty<bool>('selected', selected, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('toggled', toggled, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('checked', checked, defaultValue: null))
      ..add(FlagProperty('mixed', value: mixed, ifTrue: 'mixed'))
      ..add(
        FlagProperty(
          'inMutuallyExclusiveGroup',
          value: inMutuallyExclusiveGroup,
          ifTrue: 'inMutuallyExclusiveGroup',
        ),
      )
      ..add(DiagnosticsProperty<bool>('expanded', expanded, defaultValue: null))
      ..add(FlagProperty('isError', value: isError, ifTrue: 'isError'))
      ..add(DoubleProperty('radius', radius))
      ..add(DiagnosticsProperty<EdgeInsetsGeometry>('ringInsets', ringInsets))
      ..add(
        FlagProperty(
          'rulesFocus',
          value: rulesFocus,
          ifFalse: 'face writes focus',
        ),
      )
      ..add(
        FlagProperty(
          'excludeChild',
          value: excludeChild,
          ifTrue: 'excludeChild',
        ),
      )
      ..add(DoubleProperty('pressedOpacity', pressedOpacity))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return RawButton(
      onPressed: onTap,
      onLongPress: onLongPress,
      focusNode: focusNode,
      autofocus: autofocus,
      selected: selected ?? toggled ?? checked ?? false,
      isError: isError,
      semanticLabel: semanticLabel,
      semanticValue: value,
      semanticHint: hint,
      button: role == LedgerPressRole.button,
      link: role == LedgerPressRole.link,
      semanticSelected: selected,
      toggled: toggled,
      checked: checked,
      mixed: mixed,
      inMutuallyExclusiveGroup: inMutuallyExclusiveGroup,
      expanded: expanded,
      excludeSemantics: excludeChild && semanticLabel != null,
      child: child,
      builder: (context, states, child) => _dress(
        context,
        t,
        states,
        child!,
        radius: radius,
        ringInsets: ringInsets,
        rulesFocus: rulesFocus,
        pressedOpacity: pressedOpacity,
        focusNode: focusNode,
      ),
    );
  }
}

// A pressable's dress in [states]: the impression (or [pressedOpacity]) of a
// press, the double rule of the keyboard's focus, and the states for the
// face under it ([LedgerPressStates]).
Widget _dress(
  BuildContext context,
  LedgerThemeData t,
  Set<WidgetState> states,
  Widget child, {
  required double radius,
  required EdgeInsetsGeometry ringInsets,
  required bool rulesFocus,
  required double pressedOpacity,
  required FocusNode? focusNode,
}) {
  // One tree in every state, so a press or a focus never rebuilds the face
  // from scratch.
  final pressed = states.contains(WidgetState.pressed);
  final face = LedgerPressStates(states: states, child: child);
  return LedgerFocusRing(
    radius: radius,
    insets: ringInsets,
    color: t.textPrimary,
    shown:
        rulesFocus &&
        states.contains(WidgetState.focused) &&
        !LedgerFieldRuled.rules(context, focusNode),
    child: pressedOpacity < 1
        ? LedgerEase(
            value: pressed ? pressedOpacity : 1,
            builder: (context, o, face) => Opacity(opacity: o, child: face),
            child: face,
          )
        : LedgerEase(
            value: pressed ? LedgerImpression.pressed : 0,
            builder: (context, depth, face) => LedgerImpression(
              ink: t.textPrimary,
              depth: depth,
              wash: radius,
              child: face,
            ),
            child: face,
          ),
  );
}

/// A radio in a [LedgerPressable]'s dress: Flutter's RawRadio, of the
/// RadioGroup above it or of [registry], which takes the tap, the focus and
/// the keys and says it is checked and one of a group; Ledger draws the
/// press, the focus and the states over [child] as a pressable does. [semanticLabel]
/// names it in place of what [child] says. Plumbing of the radios; not
/// exported.
class LedgerRadioPress<T> extends StatefulWidget {
  /// A radio for [value] over [child].
  const LedgerRadioPress({
    required this.value,
    required this.enabled,
    required this.child,
    this.registry,
    this.toggleable = false,
    this.semanticLabel,
    this.radius = 0,
    this.ringInsets = EdgeInsets.zero,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// What choosing it sets.
  final T value;

  /// Whether it can be chosen.
  final bool enabled;

  /// What it draws.
  final Widget child;

  /// Its group; null: the RadioGroup above it.
  final RadioGroupRegistry<T>? registry;

  /// Whether a press on the chosen one clears the choice.
  final bool toggleable;

  /// Its spoken name, in place of what [child] says.
  final String? semanticLabel;

  /// As [LedgerPressable.radius].
  final double radius;

  /// As [LedgerPressable.ringInsets].
  final EdgeInsetsGeometry ringInsets;

  /// Its focus; never disposed when given.
  final FocusNode? focusNode;

  /// {@macro ledger.autofocus}
  final bool autofocus;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(
        DiagnosticsProperty<RadioGroupRegistry<T>>(
          'registry',
          registry,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('toggleable', value: toggleable, ifTrue: 'toggleable'))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(DoubleProperty('radius', radius))
      ..add(DiagnosticsProperty<EdgeInsetsGeometry>('ringInsets', ringInsets))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }

  @override
  State<LedgerRadioPress<T>> createState() => _LedgerRadioPressState<T>();
}

class _LedgerRadioPressState<T> extends State<LedgerRadioPress<T>> {
  FocusNode? _own;

  FocusNode get _node =>
      widget.focusNode ?? (_own ??= FocusNode(debugLabel: 'LedgerRadio'));

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final node = _node;
    final label = widget.semanticLabel;
    return MergeSemantics(
      child: RawRadio<T>(
        value: widget.value,
        mouseCursor: WidgetStateMouseCursor.clickable,
        toggleable: widget.toggleable,
        focusNode: node,
        autofocus: widget.autofocus,
        groupRegistry: widget.registry ?? RadioGroup.maybeOf<T>(context),
        enabled: widget.enabled,
        builder: (context, radio) {
          // All of its box takes a press, its gaps too: RawRadio's detector
          // finds only what the face paints.
          final face = Listener(
            behavior: HitTestBehavior.opaque,
            child: _dress(
              context,
              t,
              // The radio's states, and pressed while a press is down on it.
              {
                ...radio.states,
                if (radio.downPosition != null) WidgetState.pressed,
              },
              widget.child,
              radius: widget.radius,
              ringInsets: widget.ringInsets,
              rulesFocus: true,
              pressedOpacity: 1,
              focusNode: node,
            ),
          );
          return label == null
              ? face
              : Semantics(
                  label: label,
                  child: ExcludeSemantics(child: face),
                );
        },
      ),
    );
  }
}

/// The states of the nearest [LedgerPressable] above (hovered, pressed,
/// focused, selected), for a face that answers them in its own ink: a
/// row's dot leader inks in, a frameless button's words take the underline.
/// Plumbing of the controls; pages never place one.
class LedgerPressStates extends InheritedWidget {
  /// [states] for the faces under [child].
  const LedgerPressStates({
    required this.states,
    required super.child,
    super.key,
  });

  /// What the pressable is now.
  final Set<WidgetState> states;

  /// The states of the pressable above [context]; empty under none.
  static Set<WidgetState> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LedgerPressStates>()?.states ??
      const {};

  /// Whether the pressable above [context] is hovered or pressed.
  static bool isHot(BuildContext context) {
    final states = of(context);
    return states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.pressed);
  }

  @override
  bool updateShouldNotify(LedgerPressStates oldWidget) =>
      !setEquals(oldWidget.states, states);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<Object?>('states', states));
  }
}

/// The focus mark a Ledger control wears: the accountant's double rule,
/// two lines of [LedgerChromeMetrics.focusRing] in [color],
/// [LedgerChromeMetrics.focusGap] apart and twice that under the face
/// standing [insets] inside [child]'s box, clear of the face's drop. It is
/// centred under the face and as long as the face less one corner of
/// [radius], never shorter than three quarters of the face. It is drawn in
/// from the reading start as a pen draws it, in [LedgerMotion.base], and
/// drawn back out when focus leaves. Painted over the child, it takes no
/// room and no taps.
/// Plumbing of the controls; pages never place one.
class LedgerFocusRing extends StatelessWidget {
  /// The double rule under [child].
  const LedgerFocusRing({
    required this.radius,
    required this.color,
    required this.child,
    this.insets = EdgeInsets.zero,
    this.shown = true,
    super.key,
  }) : assert(radius >= 0);

  /// The corner radius of the face it rules under.
  final double radius;

  /// The rule's ink.
  final Color color;

  /// How far the face stands inside the child's box.
  final EdgeInsetsGeometry insets;

  /// The control the rule stands under.
  final Widget child;

  /// Whether the rule is drawn: the control keeps one tree either way.
  final bool shown;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('radius', radius))
      ..add(ColorProperty('color', color))
      ..add(DiagnosticsProperty<EdgeInsetsGeometry>('insets', insets))
      ..add(FlagProperty('shown', value: shown, ifTrue: 'shown'));
  }

  @override
  Widget build(BuildContext context) {
    const gap = LedgerChromeMetrics.focusGap;
    const line = LedgerChromeMetrics.focusRing;
    const under = 2 * gap;
    final direction = Directionality.of(context);
    final rtl = direction == TextDirection.rtl;
    final at = insets.resolve(direction);
    return LedgerEase(
      value: shown ? 1 : 0,
      duration: LedgerMotion.base,
      builder: (context, drawn, child) => Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          child!,
          if (drawn > 0)
            Positioned(
              left: at.left,
              right: at.right,
              bottom: at.bottom - under - (2 * line + gap),
              height: 2 * line + gap,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _DoubleRule(color, radius, drawn, rtl: rtl),
                ),
              ),
            ),
        ],
      ),
      child: child,
    );
  }
}

/// Two rules of [LedgerChromeMetrics.focusRing], centred under a face of
/// corner [radius], [drawn] of the way along from the reading start.
class _DoubleRule extends CustomPainter {
  const _DoubleRule(this.color, this.radius, this.drawn, {required this.rtl});

  final Color color;
  final double radius;
  final double drawn;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    const line = LedgerChromeMetrics.focusRing;
    final run = size.width - math.min(radius, size.width / 4);
    final start = (size.width - run) / 2;
    final ink = run * drawn.clamp(0.0, 1.0);
    final left = rtl ? start + run - ink : start;
    final paint = Paint()..color = color;
    canvas
      ..drawRect(Rect.fromLTWH(left, 0, ink, line), paint)
      ..drawRect(Rect.fromLTWH(left, size.height - line, ink, line), paint);
  }

  @override
  bool shouldRepaint(_DoubleRule old) =>
      old.color != color ||
      old.radius != radius ||
      old.drawn != drawn ||
      old.rtl != rtl;
}
