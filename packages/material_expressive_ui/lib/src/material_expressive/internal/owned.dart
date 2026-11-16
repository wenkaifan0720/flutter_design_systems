/// A notifier made for one subtree and disposed with it. Internal: what a
/// dialog or a specimen makes for itself (a time picker's controller, a
/// scroll area's controller) rather than takes from its caller.
library;

import 'package:flutter/widgets.dart';

/// Makes a [T] with [create] when first built, hands it to [builder] on
/// every build, and disposes it when the subtree goes.
class Owned<T extends ChangeNotifier> extends StatefulWidget {
  /// Owns what [create] makes for [builder].
  const Owned({required this.create, required this.builder, super.key});

  /// Makes the notifier, once.
  final T Function() create;

  /// The subtree, given the notifier.
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<Owned<T>> createState() => _OwnedState<T>();
}

class _OwnedState<T extends ChangeNotifier> extends State<Owned<T>> {
  late final T _value = widget.create();

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}
