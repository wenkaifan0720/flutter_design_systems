/// Keys, written as a terminal writes them: `^K` for Control-K, `⏎` for
/// Return, beside the action they work.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../style.dart';
import '../theme.dart';

/// [activator]'s keys as a terminal writes them: `^` for Control, `M-` for
/// Alt (Meta, as Emacs and readline say), `⌘` for Command, `⇧` for Shift,
/// then the key (`⏎` Return, `esc`, `tab`, `␣` Space, arrows as `↑↓←→`).
///
/// ```dart
/// termKeyLabel(const SingleActivator(LogicalKeyboardKey.keyK, control: true)); // ^K
/// ```
String termKeyLabel(SingleActivator activator) {
  final buffer = StringBuffer();
  if (activator.meta) buffer.write('⌘');
  if (activator.control) buffer.write('^');
  if (activator.alt) buffer.write('M-');
  if (activator.shift) buffer.write('⇧');
  buffer.write(_keyName(activator.trigger));
  return buffer.toString();
}

String _keyName(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter) {
    return '⏎';
  }
  if (key == LogicalKeyboardKey.escape) return 'esc';
  if (key == LogicalKeyboardKey.tab) return 'tab';
  if (key == LogicalKeyboardKey.space) return '␣';
  if (key == LogicalKeyboardKey.backspace) return '⌫';
  if (key == LogicalKeyboardKey.delete) return 'del';
  if (key == LogicalKeyboardKey.arrowUp) return '↑';
  if (key == LogicalKeyboardKey.arrowDown) return '↓';
  if (key == LogicalKeyboardKey.arrowLeft) return '←';
  if (key == LogicalKeyboardKey.arrowRight) return '→';
  final label = key.keyLabel;
  return label.length == 1 ? label.toUpperCase() : label.toLowerCase();
}

/// Whether keys are shown here: where a keyboard and a pointer reach the
/// app ([DesignInput.pointer], from [DesignTapTargets]). Under touch there
/// are no keys to press, so the look leaves them out: a [TermKey] draws
/// nothing, a button's keys and a menu row's step aside, a status line's
/// keys go, and so do the keys in the bottom line of a palette, a dialog, a
/// sheet and a toast. A pane's footer is the app's own words: give keys
/// there only where this is true.
bool termKeysShown(BuildContext context) =>
    DesignTapTargets.of(context).inputOn() == DesignInput.pointer;

/// A key or a chord shown beside an action: [keys] in the dim ink, its
/// letters in the words' face, read to a screen reader as "shortcut" and
/// the keys. Under touch it draws nothing ([termKeysShown]).
///
/// ```dart
/// const TermKey('^K');
/// ```
class TermKey extends StatelessWidget {
  /// The key written [keys].
  const TermKey(this.keys, {super.key, this.style});

  /// [activator]'s keys, written as [termKeyLabel] writes them.
  TermKey.of(SingleActivator activator, {super.key, this.style})
    : keys = termKeyLabel(activator);

  /// Overrides, over the theme's [TermThemeData.keyStyle]: `foreground`
  /// (the keys' words) and `textStyle` (their weight).
  final TermStyle? style;

  /// The keys, as written: `^K`, `⏎`, `g h`.
  final String keys;

  @override
  Widget build(BuildContext context) {
    if (!termKeysShown(context)) return const SizedBox.shrink();
    final theme = TermTheme.of(context);
    final own = TermStyleOf([style, theme.keyStyle], const {});
    return Semantics(
      label: keys,
      excludeSemantics: true,
      // A chord reads left to right in every language: `^S`, never `S^`.
      child: Text(
        keys,
        maxLines: 1,
        softWrap: false,
        textDirection: TextDirection.ltr,
        style: theme.dimStyle
            .merge(own.textStyle)
            .copyWith(color: own.foreground),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('keys', keys));
  }
}
