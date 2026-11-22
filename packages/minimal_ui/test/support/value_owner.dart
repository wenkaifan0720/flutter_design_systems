import 'package:material_ui/material_ui.dart';

/// A parent that owns a value, as a page does, for controls that report
/// changes rather than keep them.
class ValueOwner<T> extends StatefulWidget {
  const ValueOwner({super.key, required this.initial, required this.builder});

  /// The value it starts with.
  final T initial;

  /// Builds the control from the value and the setter that changes it.
  final Widget Function(T value, ValueChanged<T> set) builder;

  @override
  State<ValueOwner<T>> createState() => _ValueOwnerState<T>();
}

class _ValueOwnerState<T> extends State<ValueOwner<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (v) => setState(() => _value = v));
}
