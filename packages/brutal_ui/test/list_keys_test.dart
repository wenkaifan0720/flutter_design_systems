// The keyboard in an open list, as a native select and menu have it: opened
// from a key (Enter, Space, Down) the keyboard is on the chosen item, or the
// first when none is; the arrows move at once, round from the end; Home and
// End go to the ends; a typed letter goes to the next item starting with it;
// Enter chooses and closes; Escape closes; the keyboard comes back to the
// field. Opened by a press, the arrows work at once too.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  home: BrutalTheme(
    data: BrutalThemeData.light(),
    child: Builder(
      builder: (context) => ColoredBox(
        color: BrutalTheme.of(context).colors.paper,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    ),
  ),
);

// The words of the row the keyboard is on.
String? _keyboardOn() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context is! Element) return null;
  String? words;
  void visit(Element e) {
    if (words != null) return;
    final w = e.widget;
    if (w is Text && w.data != null) {
      words = w.data;
      return;
    }
    e.visitChildren(visit);
  }

  context.visitChildren(visit);
  return words;
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

Future<void> _letter(WidgetTester tester, String letter) async {
  await tester.sendKeyEvent(
    LogicalKeyboardKey.findKeyByKeyId(letter.codeUnitAt(0))!,
    character: letter,
  );
  await tester.pumpAndSettle();
}

const _cities = [
  BrutalSelectItem(value: 'north', label: 'North quarter'),
  BrutalSelectItem(value: 'harbour', label: 'Harbour'),
  BrutalSelectItem(value: 'old', label: 'Old town'),
  BrutalSelectItem(value: 'river', label: 'Riverside'),
  BrutalSelectItem(value: 'rail', label: 'Rail yards'),
];

void main() {
  group('BrutalSelect', () {
    late FocusNode box;
    late List<String> chosen;

    Future<void> pumpSelect(WidgetTester tester, {String? value}) async {
      box = FocusNode(debugLabel: 'City box');
      addTearDown(box.dispose);
      chosen = [];
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 320,
            child: BrutalSelect<String>(
              label: 'City',
              value: value,
              hint: 'Pick a city',
              items: _cities,
              focusNode: box,
              onChanged: chosen.add,
            ),
          ),
        ),
      );
    }

    bool isOpen() => find.text('Riverside').evaluate().isNotEmpty;

    for (final opener in [
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowUp,
    ]) {
      testWidgets('${opener.keyLabel} opens it on the chosen item', (
        tester,
      ) async {
        await pumpSelect(tester, value: 'old');
        box.requestFocus();
        await tester.pumpAndSettle();
        await _key(tester, opener);
        expect(isOpen(), isTrue);
        expect(_keyboardOn(), 'Old town');
      });
    }

    testWidgets('with none chosen, a key opens it on the first item', (
      tester,
    ) async {
      await pumpSelect(tester);
      box.requestFocus();
      await tester.pumpAndSettle();
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_keyboardOn(), 'North quarter');
    });

    testWidgets('the arrows move at once, round from the end; Home and End', (
      tester,
    ) async {
      await pumpSelect(tester, value: 'river');
      box.requestFocus();
      await tester.pumpAndSettle();
      await _key(tester, LogicalKeyboardKey.enter);
      expect(_keyboardOn(), 'Riverside');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_keyboardOn(), 'Rail yards');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_keyboardOn(), 'North quarter');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_keyboardOn(), 'Rail yards');
      await _key(tester, LogicalKeyboardKey.home);
      expect(_keyboardOn(), 'North quarter');
      await _key(tester, LogicalKeyboardKey.end);
      expect(_keyboardOn(), 'Rail yards');
    });

    testWidgets('a typed letter goes to the next item starting with it', (
      tester,
    ) async {
      await pumpSelect(tester, value: 'north');
      box.requestFocus();
      await tester.pumpAndSettle();
      await _key(tester, LogicalKeyboardKey.enter);
      await _letter(tester, 'r');
      expect(_keyboardOn(), 'Riverside');
      await _letter(tester, 'r');
      expect(_keyboardOn(), 'Rail yards');
      await _letter(tester, 'r');
      expect(_keyboardOn(), 'Riverside');
      await _letter(tester, 'h');
      expect(_keyboardOn(), 'Harbour');
      expect(isOpen(), isTrue);
    });

    testWidgets('Enter chooses and closes; the keyboard is back on the box', (
      tester,
    ) async {
      await pumpSelect(tester, value: 'north');
      box.requestFocus();
      await tester.pumpAndSettle();
      await _key(tester, LogicalKeyboardKey.enter);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(chosen, ['harbour']);
      expect(isOpen(), isFalse);
      expect(box.hasPrimaryFocus, isTrue);
    });

    testWidgets('Escape closes; the keyboard is back on the box', (
      tester,
    ) async {
      await pumpSelect(tester, value: 'north');
      box.requestFocus();
      await tester.pumpAndSettle();
      await _key(tester, LogicalKeyboardKey.space);
      await _key(tester, LogicalKeyboardKey.escape);
      expect(chosen, isEmpty);
      expect(isOpen(), isFalse);
      expect(box.hasPrimaryFocus, isTrue);
    });

    testWidgets('opened by a press, the arrows move at once and Escape '
        'brings the keyboard to the box', (tester) async {
      await pumpSelect(tester, value: 'harbour');
      await tester.tap(find.text('Harbour'));
      await tester.pumpAndSettle();
      expect(isOpen(), isTrue);
      expect(_keyboardOn(), 'Harbour');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_keyboardOn(), 'Old town');
      await _key(tester, LogicalKeyboardKey.escape);
      expect(isOpen(), isFalse);
      expect(box.hasPrimaryFocus, isTrue);
    });

    testWidgets('a long list opens on the chosen row in view, and the row the '
        'keyboard is on stays in view: round past the end, End, Home', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 520);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 320,
            child: BrutalSelect<String>(
              label: 'Hall',
              value: 'Hall 22',
              items: [
                for (var i = 1; i <= 24; i++)
                  BrutalSelectItem(value: 'Hall $i', label: 'Hall $i'),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('Hall 22'));
      await tester.pumpAndSettle();
      final list = tester.getRect(find.byType(SingleChildScrollView).last);
      void inView(String row) {
        expect(_keyboardOn(), row);
        final at = tester.getRect(find.text(row).last);
        expect(
          at.top >= list.top - 0.5 && at.bottom <= list.bottom + 0.5,
          isTrue,
          reason: '$row at $at, the list at $list',
        );
      }

      inView('Hall 22');
      for (var i = 0; i < 3; i++) {
        await _key(tester, LogicalKeyboardKey.arrowDown);
      }
      inView('Hall 1');
      await _key(tester, LogicalKeyboardKey.end);
      inView('Hall 24');
      await _key(tester, LogicalKeyboardKey.home);
      inView('Hall 1');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      inView('Hall 24');
    });
  });

  group('BrutalMenu', () {
    late FocusNode trigger;
    late List<String> ran;

    Future<void> pumpMenu(WidgetTester tester) async {
      trigger = FocusNode(debugLabel: 'More');
      addTearDown(trigger.dispose);
      ran = [];
      await tester.pumpWidget(
        _app(
          BrutalMenu(
            items: [
              BrutalMenuItem(label: 'Share', onPressed: () => ran.add('Share')),
              BrutalMenuItem(label: 'Save', onPressed: () => ran.add('Save')),
              BrutalMenuItem(
                label: 'Duplicate',
                onPressed: () => ran.add('Duplicate'),
              ),
              BrutalMenuItem(
                label: 'Delete',
                onPressed: () => ran.add('Delete'),
                isDestructiveAction: true,
              ),
            ],
            builder: (context, toggle, open) =>
                BrutalButton('More', onPressed: toggle, focusNode: trigger),
          ),
        ),
      );
      trigger.requestFocus();
      await tester.pumpAndSettle();
    }

    bool isOpen() => find.text('Duplicate').evaluate().isNotEmpty;

    for (final opener in [
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.arrowDown,
    ]) {
      testWidgets('${opener.keyLabel} opens it on the first item', (
        tester,
      ) async {
        await pumpMenu(tester);
        await _key(tester, opener);
        expect(isOpen(), isTrue);
        expect(_keyboardOn(), 'Share');
      });
    }

    testWidgets('the arrows, Home, End and a typed letter', (tester) async {
      await pumpMenu(tester);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_keyboardOn(), 'Delete');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_keyboardOn(), 'Share');
      await _key(tester, LogicalKeyboardKey.end);
      expect(_keyboardOn(), 'Delete');
      await _key(tester, LogicalKeyboardKey.home);
      expect(_keyboardOn(), 'Share');
      await _letter(tester, 's');
      expect(_keyboardOn(), 'Save');
      await _letter(tester, 'd');
      expect(_keyboardOn(), 'Duplicate');
      await _letter(tester, 'd');
      expect(_keyboardOn(), 'Delete');
    });

    testWidgets('Enter runs one and closes; Escape closes; the keyboard is '
        'back on the trigger', (tester) async {
      await pumpMenu(tester);
      await _key(tester, LogicalKeyboardKey.enter);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(ran, ['Save']);
      expect(isOpen(), isFalse);
      expect(trigger.hasPrimaryFocus, isTrue);
      await _key(tester, LogicalKeyboardKey.enter);
      await _key(tester, LogicalKeyboardKey.escape);
      expect(isOpen(), isFalse);
      expect(trigger.hasPrimaryFocus, isTrue);
      expect(ran, ['Save']);
    });

    testWidgets('opened by a press, the arrows answer at once: the first '
        'Down lights the first row, the next moves on', (tester) async {
      await pumpMenu(tester);
      trigger.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      // No row lit (test/menus_test.dart), the keyboard waiting on the first.
      expect(_keyboardOn(), 'Share');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_keyboardOn(), 'Share');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_keyboardOn(), 'Save');
    });
  });

  // The suggesting fields keep the keyboard in their entry, as a combobox
  // does; the row it is on is the one drawn focused (a line inside it). Their
  // keys are ui_core's (0.2.0): Up and Down wrap and pass a disabled option
  // by, Down on a closed list only opens it, the list opens on the value and
  // shows every option until the words are edited, Enter takes the row.
  String? lineOn(WidgetTester tester) => tester
      .widgetList<BrutalMenuRow>(find.byType(BrutalMenuRow))
      .where((r) => r.states.contains(WidgetState.focused))
      .map((r) => r.label)
      .firstOrNull;

  List<String> rows(WidgetTester tester) => [
    for (final r in tester.widgetList<BrutalMenuRow>(
      find.byType(BrutalMenuRow),
    ))
      r.label,
  ];

  FocusNode entryOf(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText).first).focusNode;

  // Into the entry from the keyboard, the list open (Down opens a closed one).
  Future<void> keyIn(WidgetTester tester) async {
    entryOf(tester).requestFocus();
    await tester.pumpAndSettle();
    if (rows(tester).isEmpty) await _key(tester, LogicalKeyboardKey.arrowDown);
  }

  Future<void> take(WidgetTester tester) async {
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  group('BrutalTagInput', () {
    late List<List<String>> changed;

    Future<void> pumpTags(
      WidgetTester tester, {
      bool Function(String)? isOptionEnabled,
    }) async {
      changed = [];
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 320,
            child: BrutalTagInput<String>(
              label: 'Kinds of night',
              hint: 'Add a kind',
              values: const ['Film', 'Talks'],
              options: const ['Film', 'Music', 'Talks', 'Art', 'Late'],
              labelOf: (k) => k,
              isOptionEnabled: isOptionEnabled,
              onChanged: changed.add,
            ),
          ),
        ),
      );
    }

    testWidgets('the keyboard on the first suggestion; the arrows wrap; Enter '
        'takes one and stays; Escape closes', (tester) async {
      await pumpTags(tester);
      await keyIn(tester);
      expect(lineOn(tester), 'Music');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(lineOn(tester), 'Art');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(lineOn(tester), 'Late');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(lineOn(tester), 'Music');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(lineOn(tester), 'Late');
      await take(tester);
      expect(changed, [
        ['Film', 'Talks', 'Late'],
      ]);
      // Still in the entry, for the next tag.
      expect(entryOf(tester).hasPrimaryFocus, isTrue);
      await tester.enterText(find.byType(EditableText), 'a');
      await tester.pumpAndSettle();
      await _key(tester, LogicalKeyboardKey.escape);
      expect(find.byType(BrutalMenuRow), findsNothing);
      expect(entryOf(tester).hasPrimaryFocus, isTrue);
    });

    testWidgets('Down on the closed list opens it without moving', (
      tester,
    ) async {
      await pumpTags(tester);
      await keyIn(tester);
      await _key(tester, LogicalKeyboardKey.escape);
      expect(rows(tester), isEmpty);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(lineOn(tester), 'Music');
    });

    testWidgets('a disabled suggestion stands grey and the keys pass it by', (
      tester,
    ) async {
      await pumpTags(tester, isOptionEnabled: (k) => k != 'Art');
      await keyIn(tester);
      final art = tester
          .widgetList<BrutalMenuRow>(find.byType(BrutalMenuRow))
          .firstWhere((r) => r.label == 'Art');
      expect(art.states, contains(WidgetState.disabled));
      expect(lineOn(tester), 'Music');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(lineOn(tester), 'Late');
    });

    testWidgets('opened by a press, the arrows move at once', (tester) async {
      await pumpTags(tester);
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      if (rows(tester).isEmpty) {
        await _key(tester, LogicalKeyboardKey.arrowDown);
      }
      expect(lineOn(tester), 'Music');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(lineOn(tester), 'Art');
    });
  });

  group('BrutalCombobox', () {
    late List<String> chosen;

    Future<void> pumpVenues(
      WidgetTester tester, {
      bool Function(String)? isOptionEnabled,
    }) async {
      chosen = [];
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 320,
            child: BrutalCombobox<String>(
              label: 'Venue',
              options: const ['Hall 4', 'Gallery Nine', 'The Yard', 'Pier'],
              value: 'Gallery Nine',
              labelOf: (v) => v,
              isOptionEnabled: isOptionEnabled,
              onSelected: chosen.add,
            ),
          ),
        ),
      );
    }

    testWidgets('opened, every venue, the keyboard on the chosen one; the '
        'arrows wrap; Enter chooses', (tester) async {
      await pumpVenues(tester);
      await keyIn(tester);
      expect(rows(tester), ['Hall 4', 'Gallery Nine', 'The Yard', 'Pier']);
      expect(lineOn(tester), 'Gallery Nine');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(lineOn(tester), 'Pier');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(lineOn(tester), 'Hall 4');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(lineOn(tester), 'Pier');
      await take(tester);
      expect(chosen, ['Pier']);
    });

    testWidgets('Down on the closed list opens it on the chosen venue; Escape '
        'closes and leaves the keyboard in the entry', (tester) async {
      await pumpVenues(tester);
      await keyIn(tester);
      await _key(tester, LogicalKeyboardKey.escape);
      expect(rows(tester), isEmpty);
      expect(entryOf(tester).hasPrimaryFocus, isTrue);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(lineOn(tester), 'Gallery Nine');
    });

    testWidgets('edited words narrow the list', (tester) async {
      await pumpVenues(tester);
      await keyIn(tester);
      await tester.enterText(find.byType(EditableText), 'pi');
      await tester.pumpAndSettle();
      expect(rows(tester), ['Pier']);
      expect(lineOn(tester), 'Pier');
    });

    testWidgets('a disabled venue stands grey and the keys pass it by', (
      tester,
    ) async {
      await pumpVenues(tester, isOptionEnabled: (v) => v != 'The Yard');
      await keyIn(tester);
      final yard = tester
          .widgetList<BrutalMenuRow>(find.byType(BrutalMenuRow))
          .firstWhere((r) => r.label == 'The Yard');
      expect(yard.states, contains(WidgetState.disabled));
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(lineOn(tester), 'Pier');
    });
  });

  group('BrutalMenuBar', () {
    testWidgets(
      'a typed letter goes to the next item starting with it; a quick run spells',
      (tester) async {
        await tester.pumpWidget(
          _app(
            BrutalMenuBar(
              menus: [
                BrutalMenuBarMenu('Ticket', [
                  BrutalMenuItem(label: 'Print', onPressed: () {}),
                  BrutalMenuItem(label: 'Pause', onPressed: () {}),
                  BrutalMenuItem(label: 'Share', onPressed: () {}),
                  BrutalMenuItem(label: 'Save', onPressed: () {}),
                ]),
              ],
            ),
          ),
        );
        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is Text && w.data?.toLowerCase() == 'ticket',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Share'), findsOneWidget);
        await _letter(tester, 's');
        expect(_keyboardOn(), 'Share');
        // A second letter long after the first starts a new run.
        await tester.pump(const Duration(seconds: 1));
        await _letter(tester, 's');
        expect(_keyboardOn(), 'Save');
        // Letters typed close together spell the start: p goes round to Print,
        // pa on to Pause.
        await tester.pump(const Duration(seconds: 1));
        await _letter(tester, 'p');
        expect(_keyboardOn(), 'Print');
        await _letter(tester, 'a');
        expect(_keyboardOn(), 'Pause');
        await tester.pump(const Duration(seconds: 1));
      },
    );
  });
}
