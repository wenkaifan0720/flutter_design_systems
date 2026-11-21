/// A keyboard shortcut's keys as a menu row shows them, in the platform's
/// order and the reader's words: Flutter's own labels (Material's
/// `MenuItemButton`), for a look that paints its own row.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'localizations.dart';

/// The keys of [shortcut] (a [SingleActivator] or a [CharacterActivator]),
/// one string a key, modifiers first, as Flutter's `MenuItemButton` labels
/// them:
///
/// - On macOS and iOS, with [appleSymbols] (the default): ⌃ ⌥ ⇧ ⌘, in
///   Apple's order (⌘ last). Without: the same order in words, Material's
///   where it has one (Ctrl, Shift, Command) and ui_core's where it has
///   none (Option), for a look whose font draws none of ⌃ ⌥ ⇧ ⌘ and ↵.
/// - Elsewhere: Alt, Ctrl, the Windows key (Win, on Windows) or Meta, and
///   Shift, in Flutter's order, in the reader's words.
///
/// Then the key: an arrow as ← → ↑ ↓; Enter as ↵ (as a word, with Apple's
/// symbols off); a letter or a digit in capitals; Tab, Esc, Space, Delete,
/// Backspace, Home, End, Page Up and Down, and Insert in the reader's words
/// ([RawWidgetsLocalizations]); any other key by its key label. A
/// [CharacterActivator]'s character as it is, with no Shift (the character
/// says it).
///
/// [platform] is [defaultTargetPlatform] when null. The words come from
/// [RawWidgetsLocalizations.of] at [context].
///
/// ```dart
/// designShortcutKeys(context, const SingleActivator(LogicalKeyboardKey.keyN, meta: true, shift: true))
/// ```
List<String> designShortcutKeys(
  BuildContext context,
  MenuSerializableShortcut shortcut, {
  TargetPlatform? platform,
  bool appleSymbols = true,
}) {
  final words = RawWidgetsLocalizations.of(context);
  final on = platform ?? defaultTargetPlatform;
  final apple = on == TargetPlatform.macOS || on == TargetPlatform.iOS;
  final symbols = apple && appleSymbols;
  final keys = shortcut.serializeForMenu();
  final character = keys.character;
  final shift = character == null && (keys.shift ?? false);
  final control = keys.control ?? false;
  final alt = keys.alt ?? false;
  final meta = keys.meta ?? false;
  return [
    if (apple) ...[
      if (control) symbols ? '⌃' : words.keyboardKeyControl,
      if (alt) symbols ? '⌥' : words.keyboardKeyOption,
      if (shift) symbols ? '⇧' : words.keyboardKeyShift,
      if (meta) symbols ? '⌘' : words.keyboardKeyMetaMacOs,
    ] else ...[
      if (alt) words.keyboardKeyAlt,
      if (control) words.keyboardKeyControl,
      if (meta)
        on == TargetPlatform.windows
            ? words.keyboardKeyMetaWindows
            : words.keyboardKeyMeta,
      if (shift) words.keyboardKeyShift,
    ],
    if (character != null)
      character
    else if (keys.trigger case final trigger?)
      _keyLabel(trigger, words, enterSymbol: !apple || symbols),
  ];
}

/// [designShortcutKeys] joined as a menu row shows them: "⌃ ⇧ N" with
/// Apple's symbols (Flutter's spacing), "Shift+Command+N" in words on
/// macOS and iOS, "Ctrl+Shift+N" elsewhere.
///
/// ```dart
/// designShortcutLabel(context, const SingleActivator(LogicalKeyboardKey.keyS, control: true))
/// ```
String designShortcutLabel(
  BuildContext context,
  MenuSerializableShortcut shortcut, {
  TargetPlatform? platform,
  bool appleSymbols = true,
}) {
  final on = platform ?? defaultTargetPlatform;
  final symbols =
      appleSymbols && (on == TargetPlatform.macOS || on == TargetPlatform.iOS);
  return designShortcutKeys(
    context,
    shortcut,
    platform: on,
    appleSymbols: appleSymbols,
  ).join(symbols ? ' ' : '+');
}

String _keyLabel(
  LogicalKeyboardKey key,
  RawWidgetsLocalizations words, {
  required bool enterSymbol,
}) {
  if (key == LogicalKeyboardKey.arrowLeft) return '←';
  if (key == LogicalKeyboardKey.arrowRight) return '→';
  if (key == LogicalKeyboardKey.arrowUp) return '↑';
  if (key == LogicalKeyboardKey.arrowDown) return '↓';
  if (key == LogicalKeyboardKey.enter) {
    return enterSymbol ? '↵' : words.keyboardKeyEnter;
  }
  final named = switch (key) {
    LogicalKeyboardKey.tab => words.keyboardKeyTab,
    LogicalKeyboardKey.escape => words.keyboardKeyEscape,
    LogicalKeyboardKey.space => words.keyboardKeySpace,
    LogicalKeyboardKey.delete => words.keyboardKeyDelete,
    LogicalKeyboardKey.backspace => words.keyboardKeyBackspace,
    LogicalKeyboardKey.home => words.keyboardKeyHome,
    LogicalKeyboardKey.end => words.keyboardKeyEnd,
    LogicalKeyboardKey.pageUp => words.keyboardKeyPageUp,
    LogicalKeyboardKey.pageDown => words.keyboardKeyPageDown,
    LogicalKeyboardKey.insert => words.keyboardKeyInsert,
    _ => null,
  };
  if (named != null) return named;
  // A key that types a character (a letter, a digit, a mark): the
  // character, in capitals.
  if (key.keyId & LogicalKeyboardKey.planeMask == 0) {
    return String.fromCharCode(key.keyId & LogicalKeyboardKey.valueMask)
        .toUpperCase();
  }
  return key.keyLabel;
}
