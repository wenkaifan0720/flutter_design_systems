import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../components/pressable/pressable.dart' show Fluent2FocusRing;

/// Keyboard reach for a control: it takes focus, answers [keys], and draws
/// Fluent's focus indicator while the keyboard, not a pointer, holds focus:
/// a 2 stroke of `strokeFocus2` on the control's own edge and a 1 stroke of
/// `strokeFocus1` inside it. Plumbing of the components; pages never place
/// one.
class Fluent2KeyFocus extends StatefulWidget {
  /// Gives [child] keyboard focus, [keys] and Fluent's focus indicator.
  const Fluent2KeyFocus({
    required this.enabled,
    required this.keys,
    required this.radius,
    required this.child,
    this.ringInsets = EdgeInsets.zero,
    this.focusNode,
    this.autofocus = false,
    this.onFocus,
    super.key,
  });

  /// Whether the control takes focus and keys at all.
  final bool enabled;

  /// What each key does.
  final Map<LogicalKeyboardKey, VoidCallback> keys;

  /// The ringed object's corner radius.
  final double radius;

  /// How far inside [child]'s box the ringed object stands.
  final EdgeInsets ringInsets;

  /// The caller's focus node; null keeps one of the widget's own.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first builds.
  final bool autofocus;

  /// Told when the keyboard's focus arrives (true) or leaves (false).
  final ValueChanged<bool>? onFocus;

  /// The control's face.
  final Widget child;

  @override
  State<Fluent2KeyFocus> createState() => _Fluent2KeyFocusState();
}

class _Fluent2KeyFocusState extends State<Fluent2KeyFocus> {
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
    final at = widget.ringInsets;
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      // The control announces itself; focus adds no node of its own.
      includeSemantics: false,
      canRequestFocus: widget.enabled,
      skipTraversal: !widget.enabled,
      onFocusChange: (focused) {
        setState(() => _focused = focused);
        widget.onFocus?.call(focused && _keyboard);
      },
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        final action = widget.keys[event.logicalKey];
        if (!widget.enabled || action == null) return KeyEventResult.ignored;
        action();
        return KeyEventResult.handled;
      },
      child: Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_focused && _keyboard)
            Positioned(
              left: at.left,
              top: at.top,
              right: at.right,
              bottom: at.bottom,
              child: IgnorePointer(
                child: Fluent2FocusRing(radius: widget.radius),
              ),
            ),
        ],
      ),
    );
  }
}
