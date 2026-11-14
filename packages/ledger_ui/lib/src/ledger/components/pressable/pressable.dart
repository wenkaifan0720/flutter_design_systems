import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
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
/// [DesignPressable]: the tap, the pointer's click cursor, keyboard focus
/// with Enter and Space, and the semantics of the control it makes (a
/// button or a link, enabled or not, selected, checked or toggled). Ledger
/// says each state in its rules and its ink, never in a wash: a press sinks
/// the face [LedgerChromeMetrics.pressSink] into the paper, like a stamp;
/// keyboard focus rules the accountant's double rule in the ink under the
/// face ([LedgerFocusRing]), only while the keyboard moved focus; a hover
/// or a press inks a row's dot leader in ([LedgerPressStates] carries them
/// to the face). Each change moves in Ledger's one motion ([LedgerEase],
/// [LedgerFace]): the face sinks and rises, the rule is drawn in as a pen
/// draws it, and a change mid-way turns from where it is. Plumbing of the components; a page places one only to make
/// a row or card it composed by hand one tap target.
///
/// A null [onTap] makes it inert: the child is drawn as it is, the node is
/// announced as disabled, and nothing answers a tap or a key. [label] is the
/// spoken name and replaces what the child says when [excludeChild] is true.
class LedgerPressable extends StatelessWidget {
  /// A control of [child] that calls [onTap].
  const LedgerPressable({
    required this.onTap,
    required this.child,
    this.label,
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
    this.excludeChild = true,
    this.pressedOpacity = 1,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
    super.key,
  });

  /// What a press does; null makes the control inert.
  final VoidCallback? onTap;

  /// What a long press does, when anything.
  final VoidCallback? onLongPress;

  /// The control's face.
  final Widget child;

  /// The spoken name; null leaves the child's own semantics.
  final String? label;

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
  /// its foot.
  final double radius;

  /// How far inside the child's box the face stands.
  final EdgeInsetsGeometry ringInsets;

  /// Whether the child's own semantics are replaced by [label].
  final bool excludeChild;

  /// The face's opacity while a finger is down; 1, the default, sinks it
  /// into the paper instead.
  final double pressedOpacity;

  /// The caller's focus node, which the caller disposes; null keeps one of
  /// the pressable's own.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return DesignPressable(
      onPressed: onTap,
      onLongPress: onLongPress,
      focusNode: focusNode,
      autofocus: autofocus,
      selected: selected ?? toggled ?? checked ?? false,
      isError: isError,
      semanticLabel: label,
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
      excludeSemantics: excludeChild && label != null,
      child: child,
      builder: (context, states, child) {
        // One tree in every state, so a press or a focus never rebuilds
        // the face from scratch.
        final pressed = states.contains(WidgetState.pressed);
        final face = LedgerPressStates(states: states, child: child!);
        return LedgerFocusRing(
          radius: radius,
          insets: ringInsets,
          color: t.textPrimary,
          shown:
              states.contains(WidgetState.focused) &&
              !LedgerFieldRuled.rules(context, focusNode),
          child: pressedOpacity < 1
              ? LedgerEase(
                  value: pressed ? pressedOpacity : 1,
                  builder: (context, o, face) =>
                      Opacity(opacity: o, child: face),
                  child: face,
                )
              : LedgerEase(
                  value: pressed ? LedgerChromeMetrics.pressSink : 0,
                  builder: (context, y, face) =>
                      Transform.translate(offset: Offset(0, y), child: face),
                  child: face,
                ),
        );
      },
    );
  }
}

/// The states of the nearest [LedgerPressable] above (hovered, pressed,
/// focused, selected), for a face that answers them in its own ink: a
/// row's dot leader inks in, a filled button's shadow goes while pressed.
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
  });

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
