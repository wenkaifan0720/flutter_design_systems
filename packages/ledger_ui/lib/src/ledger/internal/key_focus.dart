import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../components/pressable/pressable.dart';
import '../theme.dart';

/// Keyboard reach for an adjustable control (the switch, the sliders, the
/// stepper, the segmented strip): it takes focus, answers [keys], and rules
/// the double rule in the ink under it ([LedgerFocusRing]) while the
/// keyboard, not a pointer, holds focus.
/// Plumbing of the controls; pages never place one.
class LedgerKeyFocus extends StatefulWidget {
  /// Keyboard reach for [child].
  const LedgerKeyFocus({
    required this.enabled,
    required this.keys,
    required this.radius,
    required this.child,
    this.ringInsets = EdgeInsets.zero,
    this.focusNode,
    super.key,
  });

  /// Whether the control takes focus and keys at all.
  final bool enabled;

  /// What each key does.
  final Map<LogicalKeyboardKey, VoidCallback> keys;

  /// The ruled object's corner radius; the rule keeps to its foot's
  /// straight run.
  final double radius;

  /// How far inside [child]'s box the ruled object stands.
  final EdgeInsetsGeometry ringInsets;

  /// The caller's focus node; null keeps one of the widget's own.
  final FocusNode? focusNode;

  /// The control.
  final Widget child;

  @override
  State<LedgerKeyFocus> createState() => _LedgerKeyFocusState();
}

class _LedgerKeyFocusState extends State<LedgerKeyFocus> {
  bool _focused = false;
  bool _keyboard = _isKeyboard(FocusManager.instance.highlightMode);

  static bool _isKeyboard(FocusHighlightMode mode) =>
      mode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onMode);
    super.dispose();
  }

  void _onMode(FocusHighlightMode mode) {
    final keyboard = _isKeyboard(mode);
    if (keyboard != _keyboard) setState(() => _keyboard = keyboard);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return Focus(
      focusNode: widget.focusNode,
      // The control announces itself; focus adds no node of its own.
      includeSemantics: false,
      canRequestFocus: widget.enabled,
      skipTraversal: !widget.enabled,
      onFocusChange: (focused) => setState(() => _focused = focused),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        final action = widget.keys[event.logicalKey];
        if (!widget.enabled || action == null) return KeyEventResult.ignored;
        action();
        return KeyEventResult.handled;
      },
      child: LedgerFocusRing(
        radius: widget.radius,
        insets: widget.ringInsets,
        color: t.textPrimary,
        shown: _focused && _keyboard,
        child: widget.child,
      ),
    );
  }
}
