// A shortcut written out, as Fluent's menus and tooltips write one.
import 'package:flutter/widgets.dart';

import '../../theme.dart';

/// The keys of a shortcut written out, as Fluent's menus and tooltips write
/// one: the [keys] joined by "+" ("Ctrl+K") in caption1 and the third ink,
/// with no caps round them. Read as the keys joined by "plus".
///
/// ```dart
/// Fluent2Kbd(const ['Ctrl', 'K'])
/// ```
class Fluent2Kbd extends StatelessWidget {
  /// The shortcut of [keys], in press order.
  const Fluent2Kbd(this.keys, {super.key});

  /// Each key's name.
  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Semantics(
      label: keys.join(' plus '),
      excludeSemantics: true,
      child: Text(
        keys.join('+'),
        maxLines: 1,
        style: t.caption1.c(t.colors.neutralForeground3),
      ),
    );
  }
}
