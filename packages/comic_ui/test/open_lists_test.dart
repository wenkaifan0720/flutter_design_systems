// An open list's chosen option reads at a glance in Comic's own material, and its active row can't be taken for it.
// Chosen is printed as Comic prints every chosen thing: the caption's flat yellow, its words in the caption's ink, and
// a check (so it reads without its colour too). The active row, the pointer's or the keyboard's (the one Enter takes),
// wears the pointer's light Ben-Day shade on the card: dots, never the chosen fill and never a line, so it reads
// neither as a second choice nor as a divider. Held for a select's list, a menu with a choice and a combobox. A tag
// input's list holds only the options not yet taken (the taken ones are its tags), so it has no chosen row; its active
// row is the same dots.
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/src/comic/raised.dart'
    show ComicMenuRowFace, ComicRaisedFrame;

import 'support.dart';

typedef _Row = ({
  Set<WidgetState> shade,
  bool ring,
  Color? fill,
  Color? ink,
  bool check,
});

/// The row [words] stand in: its highlight's states, its fill, its words' ink, and whether it carries the check.
_Row _row(WidgetTester tester, Finder words) {
  final highlight = find
      .ancestor(of: words, matching: find.byType(ComicHighlight))
      .first;
  final fill = tester
      .widgetList<DecoratedBox>(
        find.ancestor(of: words, matching: find.byType(DecoratedBox)),
      )
      .map((b) => b.decoration)
      .whereType<ShapeDecoration>()
      .map((d) => d.color)
      .firstWhere((c) => c != null, orElse: () => null);
  final h = tester.widget<ComicHighlight>(highlight);
  return (
    shade: h.states,
    ring: h.ring,
    fill: fill,
    ink: tester.widget<Text>(words).style?.color,
    check: find
        .descendant(of: highlight, matching: find.byIcon(ComicGlyphs.check))
        .evaluate()
        .isNotEmpty,
  );
}

void _chosen(_Row row, ComicColors c, {bool lit = false}) {
  expect(
    row.fill,
    c.caption,
    reason: 'the chosen row is not the caption yellow',
  );
  expect(row.ink, c.onCaption);
  expect(row.check, isTrue, reason: 'the chosen row has no check');
  expect(row.ring, isFalse);
  expect(row.shade.contains(WidgetState.hovered), lit);
}

void _other(_Row row, ComicColors c, {required bool lit}) {
  expect(row.fill, c.card, reason: 'a row not chosen is filled as if it were');
  expect(row.check, isFalse);
  expect(row.ring, isFalse, reason: 'the active row is outlined, a line');
  expect(
    row.shade.contains(WidgetState.hovered),
    lit,
    reason: lit ? 'the active row wears no shade' : 'a resting row is shaded',
  );
}

const _delivery = [
  ComicSelectOption('standard', 'Standard delivery'),
  ComicSelectOption('express', 'Express delivery'),
  ComicSelectOption('collect', 'Collect in store'),
  ComicSelectOption('courier', 'Courier'),
];

/// A select over [_delivery] holding [value], its field's focus node, and the values it was handed.
Future<({FocusNode field, List<String> chosen})> _select(
  WidgetTester tester, {
  String? value = 'express',
}) async {
  final field = FocusNode(debugLabel: 'the field');
  addTearDown(field.dispose);
  final chosen = <String>[];
  await tester.pumpWidget(
    comicApp(
      Center(
        child: SizedBox(
          width: 320,
          child: ComicSelect<String>(
            label: 'Delivery',
            value: value,
            focusNode: field,
            onChanged: chosen.add,
            options: _delivery,
          ),
        ),
      ),
    ),
  );
  return (field: field, chosen: chosen);
}

/// The one row of the open list the keys or the pointer are on.
String _lit(WidgetTester tester) => _delivery
    .map((o) => o.label)
    .singleWhere(
      (words) => _row(
        tester,
        find.descendant(
          of: find.byType(ComicMenu<String>),
          matching: find.text(words),
        ),
      ).shade.contains(WidgetState.hovered),
    );

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String letters) async {
  for (final letter in letters.split('')) {
    await tester.sendKeyEvent(
      LogicalKeyboardKey(
        LogicalKeyboardKey.keyA.keyId + letter.codeUnitAt(0) - 0x61,
      ),
      character: letter,
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// The open list's rows in order (a combobox's, a tag input's or a menu's) and the one lit: the keys' or the pointer's.
/// Two lit rows would read as two current options, so there is never more than one.
({List<String> rows, String? lit}) _open(WidgetTester tester) {
  final rows = tester
      .widgetList<ComicMenuRowFace>(find.byType(ComicMenuRowFace))
      .map((f) => f.label)
      .toList();
  final lit = [
    for (final words in rows)
      if (_row(
        tester,
        find.descendant(
          of: find.byType(ComicMenuRowFace),
          matching: find.text(words),
        ),
      ).shade.contains(WidgetState.hovered))
        words,
  ];
  expect(lit.length, lessThanOrEqualTo(1), reason: 'rows lit at once: $lit');
  return (rows: rows, lit: lit.firstOrNull);
}

/// The open list shows [rows], in order, with [lit] lit (null: none).
void _shows(WidgetTester tester, List<String> rows, String? lit) {
  final open = _open(tester);
  expect(open.rows, rows);
  expect(open.lit, lit);
}

/// The face of the row [words] stand in.
ComicMenuRowFace _face(WidgetTester tester, String words) =>
    tester.widget<ComicMenuRowFace>(
      find.ancestor(
        of: find.text(words),
        matching: find.byType(ComicMenuRowFace),
      ),
    );

/// Whether the field kept its text input through a done action: Flutter restarts the input of a field told of a submit
/// that keeps its focus, and in a browser the restarted input takes no typing (the field looks focused, the words stay).
void _keptItsInput(WidgetTester tester) => expect(
  tester.testTextInput.log.map((call) => call.method),
  isNot(
    anyOf(contains('TextInput.clearClient'), contains('TextInput.setClient')),
  ),
  reason: "the field's text input was restarted",
);

bool _hasFocus(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;

void main() {
  setUpAll(loadComicFonts);

  for (final dark in [false, true]) {
    testWidgets("a select's list prints its value yellow and checked, the pointer's and the keys' row in dots "
        '(${dark ? 'night' : 'day'})', (tester) async {
      await tester.pumpWidget(
        comicApp(
          dark: dark,
          Center(
            child: SizedBox(
              width: 320,
              child: ComicSelect<String>(
                label: 'Delivery',
                value: 'standard',
                onChanged: (_) {},
                options: const [
                  ComicSelectOption('standard', 'Standard delivery'),
                  ComicSelectOption('express', 'Express'),
                  ComicSelectOption('collect', 'Collect in store'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Standard delivery'));
      await tester.pumpAndSettle();
      final c = ComicTheme.of(tester.element(find.text('Express'))).colors;
      Finder item(String words) => find.descendant(
        of: find.byType(ComicMenu<String>),
        matching: find.text(words),
      );
      // Opened by the pointer, no row is lit yet: the chosen one is yellow and checked, none in dots.
      _chosen(_row(tester, item('Standard delivery')), c);
      _other(_row(tester, item('Express')), c, lit: false);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(item('Express')));
      await tester.pumpAndSettle();
      _chosen(_row(tester, item('Standard delivery')), c);
      _other(_row(tester, item('Express')), c, lit: true);
      _other(_row(tester, item('Collect in store')), c, lit: false);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      _chosen(_row(tester, item('Standard delivery')), c);
      _other(_row(tester, item('Express')), c, lit: false);
      _other(_row(tester, item('Collect in store')), c, lit: true);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      // On the chosen row the keys' dots print in the caption's ink, over its yellow.
      _chosen(_row(tester, item('Standard delivery')), c, lit: true);
      _other(_row(tester, item('Express')), c, lit: false);
    });

    testWidgets("a combobox's list prints the option taken yellow and checked, the highlight in dots "
        '(${dark ? 'night' : 'day'})', (tester) async {
      await tester.pumpWidget(
        comicApp(
          dark: dark,
          const Center(
            child: SizedBox(
              width: 320,
              child: ComicCombobox<String>(
                label: 'Port',
                options: ['Porto', 'Porto Santo', 'Lisbon'],
              ),
            ),
          ),
        ),
      );
      Finder item(String words) => find.descendant(
        of: find.byType(ComicMenuRowFace),
        matching: find.text(words),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'Port');
      await tester.pumpAndSettle();
      await tester.tap(item('Porto'));
      await tester.pumpAndSettle();
      // Back in the list on its words: the one taken is chosen, the keys' highlight starts on it. (The same words
      // again would change nothing and open nothing: away first.)
      await tester.enterText(find.byType(EditableText), 'Port');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Porto');
      await tester.pumpAndSettle();
      final c = ComicTheme.of(tester.element(item('Porto'))).colors;
      _chosen(_row(tester, item('Porto')), c, lit: true);
      _other(_row(tester, item('Porto Santo')), c, lit: false);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      _chosen(_row(tester, item('Porto')), c);
      _other(_row(tester, item('Porto Santo')), c, lit: true);
      // Typed away from its words, nothing in the list is the field's value.
      await tester.enterText(find.byType(EditableText), 'Port');
      await tester.pumpAndSettle();
      expect(_row(tester, item('Porto')).check, isFalse);
    });
  }

  testWidgets(
    'Enter in a combobox takes the highlighted option, and the field keeps the focus and its text input',
    (tester) async {
      final taken = <String>[];
      await tester.pumpWidget(
        comicApp(
          Center(
            child: SizedBox(
              width: 320,
              child: ComicCombobox<String>(
                label: 'Port',
                options: const ['Porto', 'Porto Santo', 'Lisbon'],
                onSelected: taken.add,
              ),
            ),
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'Port');
      await tester.pumpAndSettle();
      tester.testTextInput.log.clear();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(taken, ['Porto']);
      expect(find.byType(ComicMenuRowFace), findsNothing);
      _keptItsInput(tester);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
    },
  );

  testWidgets('a select tells a screen reader whether its list is open', (
    tester,
  ) async {
    await tester.pumpWidget(
      comicApp(
        Center(
          child: SizedBox(
            width: 320,
            child: ComicSelect<String>(
              label: 'Delivery',
              value: 'standard',
              onChanged: (_) {},
              options: const [
                ComicSelectOption('standard', 'Standard delivery'),
                ComicSelectOption('express', 'Express'),
              ],
            ),
          ),
        ),
      ),
    );
    List<bool> expanded() => tester
        .widgetList<Semantics>(
          find.descendant(
            of: find.byType(ComicSelectField),
            matching: find.byType(Semantics),
          ),
        )
        .map((s) => s.properties.expanded)
        .whereType<bool>()
        .toList();
    expect(expanded(), [false]);
    await tester.tap(find.byType(ComicSelectField));
    await tester.pumpAndSettle();
    expect(expanded(), [true]);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(expanded(), [false]);
  });

  for (final key in [
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.arrowDown,
  ]) {
    testWidgets(
      'a select opened by ${key.keyLabel} starts on the chosen option, or the first; Escape gives the field back',
      (tester) async {
        for (final value in ['express', null]) {
          final select = await _select(tester, value: value);
          select.field.requestFocus();
          await tester.pump();
          await _press(tester, key);
          expect(find.byType(ComicMenu<String>), findsOneWidget);
          expect(
            _lit(tester),
            value == null ? 'Standard delivery' : 'Express delivery',
          );
          expect(select.field.hasFocus, isFalse);
          await _press(tester, LogicalKeyboardKey.escape);
          expect(find.byType(ComicMenu<String>), findsNothing);
          expect(select.field.hasPrimaryFocus, isTrue);
          expect(select.chosen, isEmpty);
        }
      },
    );
  }

  testWidgets(
    "a select's list: the arrows wrap, Home and End go to the ends, a typed letter jumps, Enter chooses",
    (tester) async {
      final select = await _select(tester);
      select.field.requestFocus();
      await tester.pump();
      await _press(tester, LogicalKeyboardKey.enter);
      expect(_lit(tester), 'Express delivery');
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester), 'Collect in store');
      await _press(tester, LogicalKeyboardKey.arrowDown);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester), 'Standard delivery', reason: 'Down did not wrap');
      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(_lit(tester), 'Courier', reason: 'Up did not wrap');
      await _press(tester, LogicalKeyboardKey.home);
      expect(_lit(tester), 'Standard delivery');
      await _press(tester, LogicalKeyboardKey.end);
      expect(_lit(tester), 'Courier');
      // One letter steps through the options it starts, a run spells a start.
      await _type(tester, 'e');
      expect(_lit(tester), 'Express delivery');
      await tester.pump(const Duration(seconds: 1));
      await _type(tester, 'c');
      expect(_lit(tester), 'Collect in store');
      await tester.pump(const Duration(seconds: 1));
      await _type(tester, 'c');
      expect(_lit(tester), 'Courier');
      await tester.pump(const Duration(seconds: 1));
      await _type(tester, 'col');
      expect(_lit(tester), 'Collect in store');
      await tester.pump(const Duration(seconds: 1));
      await _type(tester, 'cou');
      expect(_lit(tester), 'Courier');
      await tester.pump(const Duration(seconds: 1));
      await _press(tester, LogicalKeyboardKey.arrowUp);
      await _press(tester, LogicalKeyboardKey.enter);
      expect(select.chosen, ['collect']);
      expect(find.byType(ComicMenu<String>), findsNothing);
      expect(select.field.hasPrimaryFocus, isTrue);
    },
  );

  testWidgets('after the pointer opens a select, the first arrow lights the chosen row and the next moves on, and Escape gives '
      'the field the focus', (tester) async {
    final select = await _select(tester);
    await tester.tap(find.byType(ComicSelectField));
    await tester.pumpAndSettle();
    // Opened by the pointer, no row is lit (the chosen one is yellow and checked, not in dots).
    expect(
      () => _lit(tester),
      throwsStateError,
      reason: 'a list the pointer opened lit a row',
    );
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_lit(tester), 'Express delivery');
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_lit(tester), 'Collect in store');
    await _press(tester, LogicalKeyboardKey.escape);
    expect(find.byType(ComicMenu<String>), findsNothing);
    expect(select.field.hasPrimaryFocus, isTrue);
    // A pick by the pointer gives it back too.
    await tester.tap(find.byType(ComicSelectField));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(ComicMenu<String>),
        matching: find.text('Courier'),
      ),
    );
    await tester.pumpAndSettle();
    expect(select.chosen, ['courier']);
    expect(select.field.hasPrimaryFocus, isTrue);
  });

  testWidgets(
    "a combobox's keys: Down opens on the first option without moving, every option until edited, the arrows wrap "
    'and pass over one that cannot be taken, and a list opened again starts on the option taken',
    (tester) async {
      final taken = <String>[];
      await tester.pumpWidget(
        comicApp(
          Center(
            child: SizedBox(
              width: 320,
              child: ComicCombobox<String>(
                label: 'City',
                options: const ['Paris', 'Porto', 'Prague', 'Lisbon'],
                isOptionEnabled: (city) => city != 'Prague',
                onSelected: taken.add,
              ),
            ),
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.pumpAndSettle();
      // The field offers every option as it takes the focus; Escape closes the list and leaves the words alone.
      _shows(tester, ['Paris', 'Porto', 'Prague', 'Lisbon'], 'Paris');
      await _press(tester, LogicalKeyboardKey.escape);
      expect(find.byType(ComicMenuRowFace), findsNothing);
      expect(_hasFocus(tester), isTrue);
      // Closed, Down only opens the list: on its first option, not the second.
      await _press(tester, LogicalKeyboardKey.arrowDown);
      _shows(tester, ['Paris', 'Porto', 'Prague', 'Lisbon'], 'Paris');
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_open(tester).lit, 'Porto');
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(
        _open(tester).lit,
        'Lisbon',
        reason: 'the keys stopped on an option that cannot be taken',
      );
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_open(tester).lit, 'Paris', reason: 'Down did not wrap');
      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(_open(tester).lit, 'Lisbon', reason: 'Up did not wrap');
      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(_open(tester).lit, 'Porto');
      // The option that cannot be taken prints in the secondary ink, unlit, and a press passes it by.
      final c = ComicTheme.of(tester.element(find.text('Prague'))).colors;
      expect(_face(tester, 'Prague').states, contains(WidgetState.disabled));
      expect(
        tester.widget<Text>(find.text('Prague')).style?.color,
        c.textSecondary,
      );
      await tester.tap(find.text('Prague'));
      await tester.pumpAndSettle();
      expect(taken, isEmpty);
      // Enter takes the lit option; the field keeps the focus.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(taken, ['Porto']);
      expect(find.byType(ComicMenuRowFace), findsNothing);
      expect(_hasFocus(tester), isTrue);
      // Typed on after a take, the list opens on the matches; back on the taken words, every option, the taken lit.
      await tester.enterText(find.byType(EditableText), 'Port');
      await tester.pumpAndSettle();
      _shows(tester, ['Porto'], 'Porto');
      await tester.enterText(find.byType(EditableText), 'Porto');
      await tester.pumpAndSettle();
      _shows(tester, ['Paris', 'Porto', 'Prague', 'Lisbon'], 'Porto');
      await _press(tester, LogicalKeyboardKey.escape);
      expect(find.byType(ComicMenuRowFace), findsNothing);
      // Opened again on its words: every option, the highlight on the one taken, printed chosen.
      await _press(tester, LogicalKeyboardKey.arrowDown);
      _shows(tester, ['Paris', 'Porto', 'Prague', 'Lisbon'], 'Porto');
      expect(_face(tester, 'Porto').checked, isTrue);
      expect(_face(tester, 'Paris').checked, isFalse);
      // Edited, the matches, the highlight on the first that can be taken.
      await tester.enterText(find.byType(EditableText), 'pr');
      await tester.pumpAndSettle();
      _shows(tester, ['Prague'], null);
      await tester.enterText(find.byType(EditableText), 'p');
      await tester.pumpAndSettle();
      _shows(tester, ['Paris', 'Porto', 'Prague'], 'Paris');
      expect(_face(tester, 'Porto').checked, isFalse);
    },
  );

  testWidgets("a combobox's and a tag input's list keep one highlight: the pointer moves it, the keys go on from it, and it "
      'stays when the pointer leaves', (tester) async {
    for (final multi in [false, true]) {
      await tester.pumpWidget(
        comicApp(
          Center(
            child: SizedBox(
              width: 320,
              child: multi
                  ? ComicMultiSelect<String>(
                      label: 'Genres',
                      values: const ['Noir'],
                      options: const ['Noir', 'Western', 'Horror', 'Romance'],
                      onChanged: (_) {},
                    )
                  : const ComicCombobox<String>(
                      label: 'City',
                      options: ['Paris', 'Porto', 'Prague', 'Lisbon'],
                    ),
            ),
          ),
        ),
      );
      final rows = multi
          ? ['Western', 'Horror', 'Romance']
          : ['Paris', 'Porto', 'Prague', 'Lisbon'];
      await tester.showKeyboard(find.byType(EditableText));
      await tester.pumpAndSettle();
      _shows(tester, rows, rows.first);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text(rows.last)));
      await tester.pumpAndSettle();
      // One place: the pointer's row is the one lit, the keys' gone from the first.
      _shows(tester, rows, rows.last);
      await _press(tester, LogicalKeyboardKey.arrowUp);
      _shows(tester, rows, rows[rows.length - 2]);
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      _shows(tester, rows, rows[rows.length - 2]);
      await mouse.removePointer();
    }
  });

  testWidgets(
    'a long list opens on its value near the end, in view, and the keys keep the lit row in view',
    (tester) async {
      const cities = [
        'Amsterdam',
        'Athens',
        'Barcelona',
        'Berlin',
        'Bologna',
        'Lisbon',
        'London',
        'Lyon', //
        'Madrid',
        'Marseille',
        'Milan',
        'Paris',
        'Porto',
        'Prague',
        'Rome',
        'Vienna',
      ];
      await tester.pumpWidget(
        comicApp(
          const Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 320,
              child: ComicCombobox<String>(label: 'City', options: cities),
            ),
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'Rome');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await _press(tester, LogicalKeyboardKey.arrowDown);
      final list = tester.getRect(find.byType(ComicRaisedFrame));
      bool inView(String city) {
        final row = find.descendant(
          of: find.byType(ComicMenuRowFace),
          matching: find.text(city),
        );
        if (row.evaluate().isEmpty) return false;
        final r = tester.getRect(row);
        return r.top >= list.top && r.bottom <= list.bottom;
      }

      expect(find.byType(ComicMenuRowFace), findsWidgets);
      expect(
        inView('Amsterdam') && inView('Vienna'),
        isFalse,
        reason: 'the list is not long enough to scroll',
      );
      expect(_open(tester).lit, 'Rome');
      expect(
        inView('Rome'),
        isTrue,
        reason: 'the chosen row opened out of view',
      );
      expect(_face(tester, 'Rome').checked, isTrue);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_open(tester).lit, 'Vienna');
      expect(inView('Vienna'), isTrue);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_open(tester).lit, 'Amsterdam', reason: 'Down did not wrap');
      expect(
        inView('Amsterdam'),
        isTrue,
        reason: 'the lit row went out of view',
      );
    },
  );

  testWidgets(
    "a tag input's keys: Down opens on the first suggestion, the arrows wrap and pass over one that cannot be taken, "
    'Enter adds the lit one, and the list opened again starts on its first',
    (tester) async {
      var genres = <String>['Noir'];
      await tester.pumpWidget(
        comicApp(
          Center(
            child: SizedBox(
              width: 320,
              child: StatefulBuilder(
                builder: (context, setState) => ComicMultiSelect<String>(
                  label: 'Genres',
                  values: genres,
                  options: const [
                    'Noir',
                    'Western',
                    'Horror',
                    'Romance',
                    'Satire',
                  ],
                  isOptionEnabled: (genre) => genre != 'Horror',
                  onChanged: (next) => setState(() => genres = next),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.pumpAndSettle();
      // It suggests as it takes the focus; Escape closes the list.
      _shows(tester, ['Western', 'Horror', 'Romance', 'Satire'], 'Western');
      await _press(tester, LogicalKeyboardKey.escape);
      expect(find.byType(ComicMenuRowFace), findsNothing);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      _shows(tester, ['Western', 'Horror', 'Romance', 'Satire'], 'Western');
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(
        _open(tester).lit,
        'Romance',
        reason: 'the keys stopped on a suggestion that cannot be taken',
      );
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_open(tester).lit, 'Satire');
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_open(tester).lit, 'Western', reason: 'Down did not wrap');
      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(_open(tester).lit, 'Satire', reason: 'Up did not wrap');
      expect(_face(tester, 'Horror').states, contains(WidgetState.disabled));
      tester.testTextInput.log.clear();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(genres, ['Noir', 'Satire']);
      expect(_hasFocus(tester), isTrue);
      _keptItsInput(tester);
      // Still open after the pick, its highlight back on the first suggestion; closed, Down opens it there again.
      _shows(tester, ['Western', 'Horror', 'Romance'], 'Western');
      await _press(tester, LogicalKeyboardKey.escape);
      expect(find.byType(ComicMenuRowFace), findsNothing);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      _shows(tester, ['Western', 'Horror', 'Romance'], 'Western');
    },
  );

  testWidgets(
    "a menu bar's menu: Down opens it on its first command, the arrows wrap and pass over one that is off, a typed "
    'letter jumps (a run spells a start), and Enter runs the lit command',
    (tester) async {
      final ran = <String>[];
      DesignMenuEntry command(String label, {bool on = true}) =>
          DesignMenuEntry(
            label: label,
            onPressed: on ? () => ran.add(label) : null,
          );
      await tester.pumpWidget(
        comicApp(
          ComicMenuBar(
            menus: [
              DesignMenuEntry(
                label: 'File',
                children: [
                  command('New'),
                  command('Open'),
                  command('Print', on: false),
                  command('Save'),
                  command('Save as'),
                  command('Close'),
                ],
              ),
              DesignMenuEntry(label: 'View', children: [command('Zoom')]),
            ],
          ),
        ),
      );
      await tester.pump();
      await _press(tester, LogicalKeyboardKey.tab);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_open(tester).lit, 'New');
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_open(tester).lit, 'Open');
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(
        _open(tester).lit,
        'Save',
        reason: 'the keys stopped on a command that is off',
      );
      await _press(tester, LogicalKeyboardKey.end);
      expect(_open(tester).lit, 'Close');
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_open(tester).lit, 'New', reason: 'Down did not wrap');
      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(_open(tester).lit, 'Close', reason: 'Up did not wrap');
      // One letter steps through the commands it starts; a run spells a start.
      await _type(tester, 's');
      expect(_open(tester).lit, 'Save');
      await tester.pump(const Duration(seconds: 1));
      await _type(tester, 's');
      expect(_open(tester).lit, 'Save as');
      await tester.pump(const Duration(seconds: 1));
      await _type(tester, 'op');
      expect(_open(tester).lit, 'Open');
      await tester.pump(const Duration(seconds: 1));
      await _type(tester, 'p');
      expect(
        _open(tester).lit,
        'Open',
        reason: 'a letter landed on a command that is off',
      );
      await tester.pump(const Duration(seconds: 1));
      await _press(tester, LogicalKeyboardKey.enter);
      expect(ran, ['Open']);
      expect(find.text('Save as'), findsNothing);
    },
  );

  testWidgets(
    'every open menu has one current row: opened by the pointer it lights none until the pointer or a key moves '
    '(a key lights the first and takes nothing), opened by the keys its first; the pointer and the keys move one row',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final taken = <String>[];
      final ran = <String>[];
      DesignMenuEntry command(String label) =>
          DesignMenuEntry(label: label, onPressed: () => ran.add(label));
      Finder words(String w) => find.byWidgetPredicate(
        (x) => x is Text && x.data?.toLowerCase() == w.toLowerCase(),
      );
      await tester.pumpWidget(
        comicApp(
          ComicColumn(
            gap: 16,
            children: [
              ComicMenuBar(
                menus: [
                  DesignMenuEntry(
                    label: 'File',
                    children: [
                      command('New'),
                      command('Open'),
                      command('Close'),
                    ],
                  ),
                ],
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: ComicMenuAnchor<String>(
                  items: const [
                    ComicMenuItem('save', 'Save'),
                    ComicMenuItem('share', 'Share'),
                    ComicMenuItem('print', 'Print', enabled: false),
                    ComicMenuItem('delete', 'Delete'),
                  ],
                  onSelected: taken.add,
                  builder: (context, open) => ComicButton(
                    'More',
                    key: const ValueKey('more'),
                    onPressed: open,
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: ComicSplitButton(
                  'Keep',
                  onPressed: () {},
                  menuLabel: 'Other ways to keep',
                  actions: [
                    ComicSplitAction(
                      'Keep a copy',
                      onPressed: () => ran.add('copy'),
                    ),
                    ComicSplitAction(
                      'Keep as print',
                      onPressed: () => ran.add('print'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      // A raised menu of Comic's own (an overflow menu, a select's list): its rows' shade.
      String? menuLit() {
        final lit = [
          for (final w in ['Save', 'Share', 'Print', 'Delete'])
            if (_row(
              tester,
              find.descendant(
                of: find.byType(ComicMenu<String>),
                matching: find.text(w),
              ),
            ).shade.contains(WidgetState.hovered))
              w,
        ];
        expect(
          lit.length,
          lessThanOrEqualTo(1),
          reason: 'rows lit at once: $lit',
        );
        return lit.firstOrNull;
      }

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      Future<void> click(Finder target) async {
        await mouse.moveTo(tester.getCenter(target));
        await tester.pump();
        await mouse.down(tester.getCenter(target));
        await mouse.up();
        await tester.pumpAndSettle();
      }

      // The overflow menu, opened by the pointer: no row lit. Enter lights the first and takes nothing.
      await click(find.byKey(const ValueKey('more')));
      expect(menuLit(), isNull, reason: 'a menu the pointer opened lit a row');
      await _press(tester, LogicalKeyboardKey.enter);
      expect(taken, isEmpty, reason: 'Enter took a row nobody lit');
      expect(menuLit(), 'Save');
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(menuLit(), 'Share');
      // The pointer moves the one lit row; the keys go on from it, past the row that is off.
      await mouse.moveTo(
        tester.getCenter(
          find.descendant(
            of: find.byType(ComicMenu<String>),
            matching: find.text('Save'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(menuLit(), 'Save');
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(menuLit(), 'Share');
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(
        menuLit(),
        'Delete',
        reason: 'the keys stopped on a row that is off',
      );
      await _press(tester, LogicalKeyboardKey.escape);
      expect(find.byType(ComicMenu<String>), findsNothing);
      // Opened by the pointer, Down lights the first row, not the second.
      await click(find.byKey(const ValueKey('more')));
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(menuLit(), 'Save', reason: 'Down passed over the first row');
      await _press(tester, LogicalKeyboardKey.escape);
      // Opened by the keys (the anchor has the focus back): the first row lit.
      await mouse.moveTo(Offset.zero);
      await _press(tester, LogicalKeyboardKey.enter);
      expect(menuLit(), 'Save', reason: 'a menu the keys opened lit no row');
      await _press(tester, LogicalKeyboardKey.escape);

      // The menu bar's menu, opened by the pointer: no row lit; Down lights its first.
      await click(words('File'));
      expect(_open(tester).rows, ['New', 'Open', 'Close']);
      expect(
        _open(tester).lit,
        isNull,
        reason: "a menu bar's menu the pointer opened lit a row",
      );
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(
        _open(tester).lit,
        'New',
        reason: 'Down passed over the first command',
      );
      await mouse.moveTo(tester.getCenter(words('Close')));
      await tester.pumpAndSettle();
      expect(_open(tester).lit, 'Close');
      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(_open(tester).lit, 'Open');
      await _press(tester, LogicalKeyboardKey.escape);
      expect(find.byType(ComicMenuRowFace), findsNothing);

      // The split button's menu, opened by the pointer: no row lit; Down lights its first.
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      await click(find.bySemanticsLabel('Other ways to keep'));
      expect(_open(tester).rows, ['Keep a copy', 'Keep as print']);
      expect(
        _open(tester).lit,
        isNull,
        reason: "a split button's menu the pointer opened lit a row",
      );
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(
        _open(tester).lit,
        'Keep a copy',
        reason: 'Down passed over the first action',
      );
      await _press(tester, LogicalKeyboardKey.escape);
      expect(ran, isEmpty);

      // A browser shows no focus highlight after the pointer alone: the row the pointer moved over is still the one lit.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      await click(words('File'));
      expect(_open(tester).lit, isNull);
      await mouse.moveTo(tester.getCenter(words('Open')));
      await tester.pumpAndSettle();
      expect(
        _open(tester).lit,
        'Open',
        reason: 'the row under the pointer was not lit',
      );
      await mouse.moveTo(tester.getCenter(words('Close')));
      await tester.pumpAndSettle();
      expect(_open(tester).lit, 'Close');
      await _press(tester, LogicalKeyboardKey.escape);
      // Inside the test: the handle is checked as the body ends, before the teardowns run.
      semantics.dispose();
    },
  );

  testWidgets(
    "a menu row face: chosen is the caption's yellow and a check; the keys' and the pointer's row is dots on the card",
    (tester) async {
      Widget face(Set<WidgetState> states, {bool checked = false}) =>
          ComicMenuRowFace(states: states, label: 'Row', checked: checked);
      for (final (states, checked) in [
        (<WidgetState>{}, false),
        ({WidgetState.focused}, false),
        ({WidgetState.hovered}, false),
        ({WidgetState.pressed}, false),
        (<WidgetState>{}, true),
        ({WidgetState.focused}, true),
      ]) {
        await tester.pumpWidget(comicApp(face(states, checked: checked)));
        final c = ComicTheme.of(tester.element(find.text('Row'))).colors;
        final row = _row(tester, find.text('Row'));
        final lit = states.isNotEmpty;
        if (checked) {
          _chosen(row, c, lit: lit);
        } else {
          _other(row, c, lit: lit);
        }
        expect(
          row.shade.contains(WidgetState.pressed),
          states.contains(WidgetState.pressed),
        );
      }
    },
  );
}
