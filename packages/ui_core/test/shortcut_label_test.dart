// A shortcut's keys as a menu row shows them: Flutter's own labels (⌃ ⌥ ⇧ ⌘
// on Apple, Material's words elsewhere), in the reader's language.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

late BuildContext _context;

Future<void> _pump(WidgetTester tester, {Locale locale = const Locale('en')}) =>
    tester.pumpWidget(
      Localizations(
        locale: locale,
        delegates: const [
          DesignLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Builder(
          builder: (context) {
            _context = context;
            return const SizedBox();
          },
        ),
      ),
    );

const _everyModifier = SingleActivator(
  LogicalKeyboardKey.keyK,
  control: true,
  alt: true,
  shift: true,
  meta: true,
);

List<String> _keys(
  MenuSerializableShortcut shortcut,
  TargetPlatform platform, {
  bool appleSymbols = true,
}) => designShortcutKeys(
  _context,
  shortcut,
  platform: platform,
  appleSymbols: appleSymbols,
);

String _label(
  MenuSerializableShortcut shortcut,
  TargetPlatform platform, {
  bool appleSymbols = true,
}) => designShortcutLabel(
  _context,
  shortcut,
  platform: platform,
  appleSymbols: appleSymbols,
);

void main() {
  testWidgets('on macOS and iOS, Apple\'s symbols in Apple\'s order, '
      'spaced as Flutter spaces them', (tester) async {
    await _pump(tester);
    for (final apple in [TargetPlatform.macOS, TargetPlatform.iOS]) {
      expect(_keys(_everyModifier, apple), ['⌃', '⌥', '⇧', '⌘', 'K']);
      expect(
        _label(
          const SingleActivator(
            LogicalKeyboardKey.keyN,
            shift: true,
            meta: true,
          ),
          apple,
        ),
        '⇧ ⌘ N',
      );
      expect(
        _label(
          const SingleActivator(LogicalKeyboardKey.enter, meta: true),
          apple,
        ),
        '⌘ ↵',
      );
    }
  });

  testWidgets('with Apple\'s symbols off, words: Material\'s (Ctrl, Shift, '
      'Command), ui_core\'s Option and Enter, joined with +', (tester) async {
    await _pump(tester);
    expect(_keys(_everyModifier, TargetPlatform.macOS, appleSymbols: false), [
      'Ctrl',
      'Option',
      'Shift',
      'Command',
      'K',
    ]);
    expect(
      _label(
        const SingleActivator(LogicalKeyboardKey.enter, meta: true),
        TargetPlatform.iOS,
        appleSymbols: false,
      ),
      'Command+Enter',
    );
  });

  testWidgets('elsewhere, the words in Flutter\'s order; the Windows key on '
      'Windows, Meta on the rest; Apple\'s symbols mean nothing there', (
    tester,
  ) async {
    await _pump(tester);
    expect(_keys(_everyModifier, TargetPlatform.windows), [
      'Alt',
      'Ctrl',
      'Win',
      'Shift',
      'K',
    ]);
    for (final other in [
      TargetPlatform.linux,
      TargetPlatform.android,
      TargetPlatform.fuchsia,
    ]) {
      expect(_keys(_everyModifier, other), [
        'Alt',
        'Ctrl',
        'Meta',
        'Shift',
        'K',
      ]);
    }
    expect(
      _label(
        const SingleActivator(
          LogicalKeyboardKey.keyS,
          control: true,
          shift: true,
        ),
        TargetPlatform.windows,
        appleSymbols: false,
      ),
      'Ctrl+Shift+S',
    );
    expect(
      _label(
        const SingleActivator(LogicalKeyboardKey.enter, control: true),
        TargetPlatform.linux,
      ),
      'Ctrl+↵',
    );
  });

  testWidgets('the key: arrows as arrows, named keys in words, a letter or '
      'digit in capitals, any other by its label', (tester) async {
    await _pump(tester);
    String key(LogicalKeyboardKey k) =>
        _keys(SingleActivator(k), TargetPlatform.windows).single;
    expect(
      [
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown,
      ].map(key),
      ['←', '→', '↑', '↓'],
    );
    expect(
      [
        LogicalKeyboardKey.tab,
        LogicalKeyboardKey.escape,
        LogicalKeyboardKey.space,
        LogicalKeyboardKey.delete,
        LogicalKeyboardKey.backspace,
        LogicalKeyboardKey.home,
        LogicalKeyboardKey.end,
        LogicalKeyboardKey.pageUp,
        LogicalKeyboardKey.pageDown,
        LogicalKeyboardKey.insert,
      ].map(key),
      [
        'Tab',
        'Esc',
        'Space',
        'Del',
        'Backspace',
        'Home',
        'End',
        'PgUp',
        'PgDown',
        'Insert',
      ],
    );
    expect(key(LogicalKeyboardKey.keyA), 'A');
    expect(key(LogicalKeyboardKey.digit1), '1');
    expect(key(LogicalKeyboardKey.comma), ',');
    expect(key(LogicalKeyboardKey.f5), 'F5');
  });

  testWidgets('a character activator: its character, and no Shift', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      _keys(const CharacterActivator('?', meta: true), TargetPlatform.macOS),
      ['⌘', '?'],
    );
    expect(
      _label(
        const CharacterActivator('+', control: true, alt: true),
        TargetPlatform.windows,
      ),
      'Alt+Ctrl++',
    );
  });

  testWidgets('in the reader\'s language: Material\'s words, and '
      'ui_core\'s', (tester) async {
    await _pump(tester, locale: const Locale('de'));
    expect(
      _label(
        const SingleActivator(
          LogicalKeyboardKey.delete,
          control: true,
          shift: true,
        ),
        TargetPlatform.windows,
      ),
      'Strg+Umschalttaste+Entf',
    );
    expect(_keys(_everyModifier, TargetPlatform.macOS, appleSymbols: false), [
      'Strg',
      'Wahltaste',
      'Umschalttaste',
      'Befehl',
      'K',
    ]);
  });

  testWidgets('with no platform given, the one Flutter targets', (
    tester,
  ) async {
    await _pump(tester);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      expect(
        designShortcutLabel(
          _context,
          const SingleActivator(LogicalKeyboardKey.keyC, meta: true),
        ),
        '⌘ C',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
