import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart' show RawFocusShown;

import '../components/pressable/pressable.dart';

/// Keyboard reach for an adjustable control (the switch, the sliders, the
/// stepper, the segmented strip): it takes focus, answers [keys], and clears
/// its frost ([FrostedFocusRing]) while it holds the focus and the focus shows:
/// after a key, not after a press of a pointer ([RawFocusShown]).
/// Plumbing of the controls; pages never place one.
class FrostedKeyFocus extends StatefulWidget {
  /// Creates a [FrostedKeyFocus].
  const FrostedKeyFocus({
    required this.enabled,
    required this.keys,
    required this.radius,
    required this.child,
    this.ringInsets = EdgeInsets.zero,
    this.ringInside = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Whether the control takes focus and keys at all.
  final bool enabled;

  /// What each key does.
  final Map<LogicalKeyboardKey, VoidCallback> keys;

  /// The cleared object's corner radius.
  final double radius;

  /// How far inside [child]'s box the cleared object stands.
  final EdgeInsets ringInsets;

  /// Whether only what is behind the object clears, not the faces it holds
  /// (a nav bar's tab).
  final bool ringInside;

  /// The caller's focus node; null keeps one of the widget's own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when first shown.
  final bool autofocus;

  /// The part.
  final Widget child;

  @override
  State<FrostedKeyFocus> createState() => _FrostedKeyFocusState();
}

class _FrostedKeyFocusState extends State<FrostedKeyFocus> {
  bool _hovered = false;
  late final RawFocusShown _focus;

  @override
  void initState() {
    super.initState();
    _focus = RawFocusShown((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
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
      onFocusChange: _focus.focused,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        final action = widget.keys[event.logicalKey];
        if (!widget.enabled || action == null) return KeyEventResult.ignored;
        action();
        return KeyEventResult.handled;
      },
      // The frost clears while the keyboard holds it, a little under a
      // resting pointer, easing in and out.
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: FrostedFocusRing(
          shown: _focus.value,
          hovered: _hovered && widget.enabled,
          radius: widget.radius,
          insets: at,
          inside: widget.ringInside,
          child: widget.child,
        ),
      ),
    );
  }
}
