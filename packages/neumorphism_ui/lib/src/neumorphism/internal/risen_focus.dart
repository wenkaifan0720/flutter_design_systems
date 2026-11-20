// Keyboard focus is said once, by the part that has it.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Whether the pressable around [child] is showing keyboard focus by rising off the wall (a list row, a card, a key).
///
/// The hollows inside such a part (an icon's well in a row, a card's picture window, a box's socket) keep their depth
/// while it rises: the part's rise already says where focus is, and a second change inside it would read as the
/// hollow taking focus of its own. A hollow that is itself the focused control (a field's well, a radio's socket)
/// stands under a pressable that does not rise, and deepens.
class NeumorphicRisenFocus extends InheritedWidget {
  /// Marks whether [child]'s pressable is risen for keyboard focus.
  const NeumorphicRisenFocus({
    super.key,
    required this.risen,
    required super.child,
  });

  /// Whether the pressable is risen for keyboard focus.
  final bool risen;

  /// Whether the nearest pressable around [context] is risen for keyboard focus; false outside one.
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<NeumorphicRisenFocus>()
          ?.risen ??
      false;

  @override
  bool updateShouldNotify(NeumorphicRisenFocus oldWidget) =>
      oldWidget.risen != risen;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('risen', risen));
  }
}
