import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import 'dim.dart';
import '../components/pressable/pressable.dart';

/// Keyboard reach for an adjustable control (the switch, the sliders, the
/// stepper, the segmented strip): it takes focus, answers [keys], and shows
/// the [FrostedFocusRing] while the keyboard, not a pointer, holds focus.
/// Plumbing of the controls; pages never place one.
class FrostedKeyFocus extends StatefulWidget {
  /// Creates a [FrostedKeyFocus].
  const FrostedKeyFocus({
    required this.enabled,
    required this.keys,
    required this.radius,
    required this.child,
    this.ringInsets = EdgeInsets.zero,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Whether the control takes focus and keys at all.
  final bool enabled;

  /// What each key does.
  final Map<LogicalKeyboardKey, VoidCallback> keys;

  /// The ringed object's corner radius; the ring runs
  /// [FrostedChromeMetrics.focusRingGap] outside it.
  final double radius;

  /// How far inside [child]'s box the ringed object stands.
  final EdgeInsets ringInsets;

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
      child: Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          widget.child,
          // The light fades in and out, always standing over the child.
          Positioned.fill(
            child: IgnorePointer(
              child: FrostedFade(
                opacity: _focused && _keyboard ? 1 : 0,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: FrostedFocusRing.layers(
                    context,
                    radius: widget.radius,
                    insets: at,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
