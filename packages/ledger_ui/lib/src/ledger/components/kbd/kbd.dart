/// A keyboard key, as Ledger prints one.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/cap_center.dart';
import '../../theme.dart';

/// The keys of a shortcut, each printed as a ledger prints a mark: its
/// name in the mono capitals on the light paper, ringed in the rule, with
/// the heavier ink rule of the key's edge at its foot, 4 apart (⌘ K, Shift
/// Enter). It is read, never pressed: a screen reader hears the keys
/// joined, or [semanticLabel] (Command K) when the marks are symbols.
///
/// ```dart
/// LedgerKbd(const ['⌘', 'K'], semanticLabel: 'Command K')
/// ```
///
/// ```dart
/// LedgerKbd.shortcut(const SingleActivator(LogicalKeyboardKey.keyK, meta: true))
/// ```
class LedgerKbd extends StatelessWidget {
  /// The [keys] of a shortcut, in the order they are held.
  const LedgerKbd(this.keys, {this.semanticLabel, super.key}) : shortcut = null;

  /// The keys of [shortcut] as the platform prints them, in ui_core's
  /// [designShortcutKeys]: ⌘ K on macOS and iOS, Ctrl K elsewhere, the
  /// named keys in the reader's words; a screen reader hears them spelled
  /// out ("Command+K", [designShortcutLabel]).
  const LedgerKbd.shortcut(
    MenuSerializableShortcut this.shortcut, {
    this.semanticLabel,
    super.key,
  }) : keys = const [];

  /// Each key's mark; none with a [shortcut].
  final List<String> keys;

  /// The shortcut whose keys it prints, in place of [keys].
  final MenuSerializableShortcut? shortcut;

  /// What a screen reader hears; null: the keys joined by spaces.
  final String? semanticLabel;

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
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = t.meta.medium.sized(_words).line(_line).tracked(_track);
    final shortcut = this.shortcut;
    final marks = shortcut == null
        ? keys
        : designShortcutKeys(context, shortcut);
    return Semantics(
      label:
          semanticLabel ??
          (shortcut == null
              ? keys.join(' ')
              : designShortcutLabel(context, shortcut, appleSymbols: false)),
      child: ExcludeSemantics(
        child: Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final k in marks)
              // The key's edge: the ink showing under its ringed face.
              DecoratedBox(
                decoration: BoxDecoration(
                  color: t.textSecondary,
                  borderRadius: BorderRadius.circular(t.smallRadius),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: _edge - _rule),
                  constraints: const BoxConstraints(
                    minWidth: _least,
                    minHeight: _least - _edge + _rule,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: _pad),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(t.smallRadius),
                    border: Border.all(color: t.border, width: _rule),
                  ),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: ledgerCapCenter(
                      words,
                      Text(
                        k.toUpperCase(),
                        softWrap: false,
                        style: words.colored(t.textPrimary),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // A key 22 square at least, 6 at its ends, its words 500 11/16 tracked
  // .04 in the mono; its edge a 2 rule; keys 4 apart.
  static const double _least = 22;
  static const double _pad = LedgerSpacing.s6;
  static const double _words = 11;
  static const double _line = 16;
  static const double _track = .04;
  static const double _edge = 2;
  static const double _rule = 1;
  static const double _gap = LedgerSpacing.s4;
}
