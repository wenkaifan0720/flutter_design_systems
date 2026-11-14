import 'package:flutter/widgets.dart';

import 'dim.dart';

/// The face's opacity under a finger, as `FrostedPressable` draws its own.
const double _pressedOpacity = 0.7;

/// Where a press on a control with no `FrostedPressable` of its own (a check
/// or a switch, whose node says more than a button's can) is felt: everything
/// inside it, as wide as the control's touch target, while its
/// [FrostedPressedFace] draws the press on the face alone. Plumbing of the
/// components; pages never place one.
class FrostedPressArea extends StatefulWidget {
  /// Creates a [FrostedPressArea].
  const FrostedPressArea({
    required this.enabled,
    required this.child,
    super.key,
  });

  /// Whether a press shows.
  final bool enabled;

  /// The control.
  final Widget child;

  /// Whether a finger is down on the [FrostedPressArea] above [context], for
  /// a face that draws its press past the fade (an empty check fills).
  static bool isDown(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_PressScope>()
          ?.notifier
          ?.value ??
      false;

  @override
  State<FrostedPressArea> createState() => _FrostedPressAreaState();
}

class _FrostedPressAreaState extends State<FrostedPressArea> {
  final ValueNotifier<bool> _down = ValueNotifier<bool>(false);

  @override
  void didUpdateWidget(FrostedPressArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _down.value = false;
  }

  @override
  void dispose() {
    _down.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) {
      if (widget.enabled) _down.value = true;
    },
    onPointerUp: (_) => _down.value = false,
    onPointerCancel: (_) => _down.value = false,
    child: _PressScope(notifier: _down, child: widget.child),
  );
}

class _PressScope extends InheritedNotifier<ValueNotifier<bool>> {
  const _PressScope({required super.notifier, required super.child});
}

/// The face a [FrostedPressArea] above it presses: it eases to the pressed
/// opacity and back.
class FrostedPressedFace extends StatelessWidget {
  /// Creates a [FrostedPressedFace].
  const FrostedPressedFace({required this.child, super.key});

  /// The face as drawn.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_PressScope>();
    final down = scope?.notifier?.value ?? false;
    return FrostedFade(opacity: down ? _pressedOpacity : 1, child: child);
  }
}
