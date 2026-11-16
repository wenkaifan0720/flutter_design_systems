// The keys in an open list. A list opened from a key (Return, Space, Down)
// puts the focus on the chosen option, or the first when none is; the arrows
// move at once and wrap, Home and End go to the ends, a typed letter jumps
// to the next option it starts, Return chooses and closes, and Escape
// closes and gives the focus back to the field. The arrows work as well
// right after a press opened it (a menu a press opened lights no row, so
// its first Down shows the first: menus_test). A combobox's and a tag input's list takes
// ui_core's own keys: a press lists every option until the words are
// edited, the keys on the chosen one (else the first that can be taken);
// Down or Up on a closed list only opens it; a disabled option is passed
// over and never taken; done takes the one the keys are on.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: TermTheme(
    data: TermThemeData.dark(),
    child: Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(width: 360, child: child),
      ),
    ),
  ),
);

const _names = ['alpha', 'bravo', 'charlie', 'delta', 'echo', 'dune'];

// A desk's keyboard and pointer: a row is one line, so a list of eight
// lines shows all six names (a finger's rows are two lines).
final _desk = TargetPlatformVariant.only(TargetPlatform.macOS);

// The words of the row the focus is on: a select's tile or a menu's row.
String? _focused(WidgetTester tester) {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return null;
  final tile = context.findAncestorWidgetOfExactType<TermListTile>();
  if (tile != null) return (tile.title as Text).data;
  final row = find.descendant(
    of: find.byElementPredicate((e) => identical(e, context)),
    matching: find.byType(TermMenuRow),
  );
  if (row.evaluate().isNotEmpty) {
    return tester.widget<TermMenuRow>(row.first).label;
  }
  return '<${context.widget.runtimeType}>';
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

// A letter typed, as a keyboard sends it (its character with it).
Future<void> _letter(WidgetTester tester, String letter) async {
  await tester.sendKeyEvent(
    LogicalKeyboardKey(letter.codeUnitAt(0)),
    character: letter,
  );
  await tester.pump();
}

bool _open(WidgetTester tester) => find.byType(TermPane).evaluate().isNotEmpty;

// A combobox's or a tag input's open list: its rows' words, in order, and
// the one row the keys are on (ui_core marks it focused; the keyboard's
// focus itself stays in the words).
List<String> _rows() => [
  for (final e in find.byType(TermMenuRow).evaluate())
    (e.widget as TermMenuRow).label,
];

String? _keysOn() {
  final on = [
    for (final e in find.byType(TermMenuRow).evaluate())
      if ((e.widget as TermMenuRow).states.contains(WidgetState.focused))
        (e.widget as TermMenuRow).label,
  ];
  return on.length == 1 ? on.single : null;
}

Set<WidgetState> _statesOf(String label) => find
    .byType(TermMenuRow)
    .evaluate()
    .map((e) => e.widget as TermMenuRow)
    .firstWhere((r) => r.label == label)
    .states;

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

// Return in the words, as a keyboard's done reaches a text field.
Future<void> _done(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  // A long list on a phone (rows two lines, the list taller than the room
  // under the field): the chosen row, near the end, shows as it opens, and
  // the keys' row stays in view past the end and round.
  testWidgets("a long select's list shows the chosen row and the keys' row", (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 640);
    addTearDown(tester.view.reset);
    final names = [
      for (var i = 0; i < 24; i++) 'place ${String.fromCharCode(0x61 + i)}',
    ];
    await tester.pumpWidget(
      _host(
        TermSelect<String>(
          labelText: 'region',
          value: names[21],
          items: [for (final n in names) TermSelectItem(value: n, label: n)],
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.text(names[21]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final list = find.byType(TermPane).last;
    bool shown(String name) {
      final frame = tester.getRect(list);
      final row = tester.getRect(
        find.descendant(of: list, matching: find.text(name)),
      );
      return row.top >= frame.top - .5 && row.bottom <= frame.bottom + .5;
    }

    expect(_focused(tester), names[21]);
    expect(shown(names[21]), isTrue, reason: 'the chosen row as it opens');
    for (var i = 0; i < 3; i++) {
      await _key(tester, LogicalKeyboardKey.arrowDown);
    }
    expect(_focused(tester), names[0]);
    expect(shown(names[0]), isTrue, reason: 'round to the first');
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(_focused(tester), names[23]);
    expect(shown(names[23]), isTrue, reason: 'back to the last');
    await _letter(tester, 'p');
    expect(shown(_focused(tester)!), isTrue, reason: "a letter's jump");
  });

  group('a select', () {
    late String? chosen;
    late FocusNode field;

    Future<void> pump(WidgetTester tester, {String? value = 'charlie'}) async {
      chosen = value;
      field = FocusNode();
      addTearDown(field.dispose);
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => TermSelect<String>(
              labelText: 'name',
              focusNode: field,
              value: chosen,
              items: [
                for (final n in _names) TermSelectItem(value: n, label: n),
              ],
              onChanged: (v) => setState(() => chosen = v),
            ),
          ),
        ),
      );
      field.requestFocus();
      await tester.pump();
    }

    for (final opener in [
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.arrowDown,
    ]) {
      testWidgets('opened by ${opener.keyLabel}: the focus on the chosen', (
        tester,
      ) async {
        await pump(tester);
        await _key(tester, opener);
        expect(_open(tester), isTrue);
        expect(_focused(tester), 'charlie');
      });
    }

    testWidgets('with none chosen, the focus on the first', (tester) async {
      await pump(tester, value: null);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(_focused(tester), 'alpha');
    });

    testWidgets('the arrows move at once and wrap; Home and End', (
      tester,
    ) async {
      await pump(tester);
      await _key(tester, LogicalKeyboardKey.enter);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focused(tester), 'delta');
      await _key(tester, LogicalKeyboardKey.end);
      expect(_focused(tester), 'dune');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focused(tester), 'alpha');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_focused(tester), 'dune');
      await _key(tester, LogicalKeyboardKey.home);
      expect(_focused(tester), 'alpha');
    });

    testWidgets('a typed letter jumps; again, to the next it starts', (
      tester,
    ) async {
      await pump(tester);
      await _key(tester, LogicalKeyboardKey.enter);
      await _letter(tester, 'd');
      expect(_focused(tester), 'delta');
      await tester.pump(const Duration(seconds: 1));
      await _letter(tester, 'd');
      expect(_focused(tester), 'dune');
      await tester.pump(const Duration(seconds: 1));
      await _letter(tester, 'b');
      expect(_focused(tester), 'bravo');
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Return chooses and closes; the focus back on the field', (
      tester,
    ) async {
      await pump(tester);
      await _key(tester, LogicalKeyboardKey.enter);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      await _key(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(chosen, 'bravo');
      expect(_open(tester), isFalse);
      expect(field.hasPrimaryFocus, isTrue);
    });

    testWidgets('Escape closes; the focus back on the field', (tester) async {
      await pump(tester);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(chosen, 'charlie');
      expect(_open(tester), isFalse);
      expect(field.hasPrimaryFocus, isTrue);
    });

    testWidgets('opened by a press, the arrows move at once', (tester) async {
      await pump(tester);
      await tester.tap(find.byType(TermSelect<String>));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_open(tester), isTrue);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focused(tester), 'delta');
    });
  });

  group('a menu', () {
    late List<String> pressed;
    late FocusNode button;

    Future<void> pump(WidgetTester tester) async {
      pressed = [];
      button = FocusNode();
      addTearDown(button.dispose);
      await tester.pumpWidget(
        _host(
          TermMenu(
            anchorBuilder: (context, anchor) => TermButton(
              focusNode: button,
              onPressed: anchor.toggle,
              label: 'more',
            ),
            items: [
              for (final n in _names)
                TermMenuItem(label: n, onPressed: () => pressed.add(n)),
            ],
          ),
        ),
      );
      button.requestFocus();
      await tester.pump();
    }

    testWidgets('opened by a key: the first; arrows wrap; Home, End', (
      tester,
    ) async {
      await pump(tester);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(_open(tester), isTrue);
      expect(_focused(tester), 'alpha');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_focused(tester), 'dune');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focused(tester), 'alpha');
      await _key(tester, LogicalKeyboardKey.end);
      expect(_focused(tester), 'dune');
      await _key(tester, LogicalKeyboardKey.home);
      expect(_focused(tester), 'alpha');
    });

    testWidgets('a typed letter jumps; Return picks and closes', (
      tester,
    ) async {
      await pump(tester);
      await _key(tester, LogicalKeyboardKey.enter);
      await _letter(tester, 'e');
      expect(_focused(tester), 'echo');
      await _key(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(pressed, ['echo']);
      expect(_open(tester), isFalse);
      expect(button.hasPrimaryFocus, isTrue);
    });

    testWidgets('Escape closes; the focus back on the button', (tester) async {
      await pump(tester);
      await _key(tester, LogicalKeyboardKey.enter);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_open(tester), isFalse);
      expect(button.hasPrimaryFocus, isTrue);
    });

    testWidgets('opened by a press, the first Down shows the first, the '
        'next moves', (tester) async {
      await pump(tester);
      await tester.tap(find.byType(TermButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focused(tester), 'alpha');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focused(tester), 'bravo');
    });
  });

  group('a menubar menu with a choice', () {
    testWidgets('opened by a key: the first; arrows wrap; a letter; Escape', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          TermMenuBar(
            menus: [
              DesignMenuEntry(
                label: 'view',
                children: [
                  DesignMenuEntry(label: 'timestamps', onPressed: () {}),
                  DesignMenuEntry(
                    label: 'wrap lines',
                    checked: true,
                    onPressed: () {},
                  ),
                  DesignMenuEntry(label: 'follow', onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_open(tester), isTrue);
      final first = _focused(tester);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      final last = _focused(tester);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(
        [first, last, _focused(tester)],
        ['timestamps', 'follow', 'timestamps'],
      );
      await _letter(tester, 'f');
      expect(_focused(tester), 'follow');
      await tester.pump(const Duration(seconds: 1));
      await _key(tester, LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_open(tester), isFalse);
    });
  });

  group('a combobox', () {
    late String? chosen;

    Future<void> pump(
      WidgetTester tester, {
      String? value = 'charlie',
      bool Function(String)? isOptionEnabled,
    }) async {
      chosen = value;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => TermCombobox<String>(
              labelText: 'name',
              options: _names,
              value: chosen,
              isOptionEnabled: isOptionEnabled,
              onSelected: (v) => setState(() => chosen = v),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
    }

    testWidgets('a press lists every option, the keys on the chosen; the '
        'arrows wrap; done takes it', (tester) async {
      await pump(tester);
      expect(_rows(), _names);
      expect(_keysOn(), 'charlie');
      expect(_statesOf('charlie'), contains(WidgetState.selected));
      for (final next in ['delta', 'echo', 'dune', 'alpha']) {
        await _press(tester, LogicalKeyboardKey.arrowDown);
        expect(_keysOn(), next);
      }
      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(_keysOn(), 'dune', reason: 'Up at the first goes round');
      await _done(tester);
      expect(chosen, 'dune');
      expect(_rows(), isEmpty, reason: 'taking one closes the list');
    }, variant: _desk);

    testWidgets('Down or Up on a closed list only opens it, on the chosen', (
      tester,
    ) async {
      await pump(tester);
      await _press(tester, LogicalKeyboardKey.escape);
      expect(_rows(), isEmpty);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_rows(), _names, reason: 'every option, not the value filtered');
      expect(_keysOn(), 'charlie', reason: 'and only opens it');
      await _press(tester, LogicalKeyboardKey.escape);
      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(_keysOn(), 'charlie');
    }, variant: _desk);

    testWidgets('every option until the words are edited', (tester) async {
      await pump(tester);
      expect(_rows(), _names);
      await tester.enterText(find.byType(EditableText), 'd');
      await tester.pumpAndSettle();
      expect(_rows(), ['delta', 'dune']);
      expect(_keysOn(), 'delta');
    }, variant: _desk);

    testWidgets('a disabled option is dim, passed over and never taken', (
      tester,
    ) async {
      await pump(
        tester,
        isOptionEnabled: (o) => o != 'charlie' && o != 'delta',
      );
      expect(_rows(), _names);
      expect(_keysOn(), 'alpha', reason: 'the chosen one cannot be taken');
      expect(_statesOf('delta'), contains(WidgetState.disabled));
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_keysOn(), 'bravo');
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_keysOn(), 'echo', reason: 'past charlie and delta');
      await tester.tap(find.text('delta'));
      await tester.pumpAndSettle();
      expect(chosen, 'charlie', reason: 'a tap takes no disabled option');
      await _done(tester);
      expect(chosen, 'echo');
    }, variant: _desk);
  });

  group('a tag input', () {
    late List<String> tags;

    Future<void> pump(
      WidgetTester tester, {
      bool Function(String)? isOptionEnabled,
    }) async {
      tags = [];
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => TermTagInput<String>(
              labelText: 'names',
              values: tags,
              options: _names,
              isOptionEnabled: isOptionEnabled,
              onChanged: (v) => setState(() => tags = v),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
    }

    testWidgets('a press lists every option, the keys on the first; the '
        'arrows wrap; done makes a tag', (tester) async {
      await pump(tester);
      expect(_rows(), _names);
      expect(_keysOn(), 'alpha');
      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(_keysOn(), 'dune', reason: 'Up at the first goes round');
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_keysOn(), 'alpha', reason: 'Down at the last goes round');
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_keysOn(), 'bravo');
      await _done(tester);
      expect(tags, ['bravo']);
    }, variant: _desk);

    testWidgets('typed words filter; a disabled option is passed over', (
      tester,
    ) async {
      await pump(tester, isOptionEnabled: (o) => o != 'bravo');
      expect(_keysOn(), 'alpha');
      expect(_statesOf('bravo'), contains(WidgetState.disabled));
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_keysOn(), 'charlie', reason: 'past bravo');
      await tester.enterText(find.byType(EditableText), 'd');
      await tester.pumpAndSettle();
      expect(_rows(), ['delta', 'dune']);
      await _done(tester);
      expect(tags, ['delta']);
    }, variant: _desk);
  });
}
