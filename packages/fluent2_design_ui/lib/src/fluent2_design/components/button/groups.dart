// A shortcut written out, as Fluent's menus and tooltips write one.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../theme.dart';

/// The keys of a shortcut written out, as Fluent's menus and tooltips write
/// one: the [keys] joined by "+" ("Ctrl+K") in caption1 and the third ink,
/// with no caps round them. Read as the keys joined by "plus".
/// [Fluent2Kbd.shortcut] takes the keys from an app's shortcut instead.
///
/// ```dart
/// Fluent2Kbd(const ['Ctrl', 'K'])
/// ```
class Fluent2Kbd extends StatelessWidget {
  /// The shortcut of [keys], in press order.
  const Fluent2Kbd(this.keys, {super.key}) : shortcut = null;

  /// The keys of [shortcut] (a `SingleActivator` or a `CharacterActivator`)
  /// as ui_core's `designShortcutLabel` writes them: in the platform's order
  /// and the reader's words, "Ctrl+Shift+N", or Apple's symbols on macOS and
  /// iOS ("⇧ ⌘ N"). A screen reader hears the keys in words.
  ///
  /// ```dart
  /// Fluent2Kbd.shortcut(const SingleActivator(LogicalKeyboardKey.keyK, control: true))
  /// ```
  const Fluent2Kbd.shortcut(MenuSerializableShortcut this.shortcut, {super.key})
    : keys = const [];

  /// Each key's name; empty when [shortcut] names them.
  final List<String> keys;

  /// The shortcut whose keys it writes, in place of [keys].
  final MenuSerializableShortcut? shortcut;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final shortcut = this.shortcut;
    return Semantics(
      label: shortcut == null
          ? keys.join(' plus ')
          : designShortcutLabel(context, shortcut, appleSymbols: false),
      excludeSemantics: true,
      child: Text(
        shortcut == null
            ? keys.join('+')
            : designShortcutLabel(context, shortcut),
        maxLines: 1,
        style: t.caption1.c(t.colors.neutralForeground3),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('keys', keys))
      ..add(
        DiagnosticsProperty<MenuSerializableShortcut>(
          'shortcut',
          shortcut,
          defaultValue: null,
        ),
      );
  }
}
