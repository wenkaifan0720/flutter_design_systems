// An open list's marks, by day and by night. The chosen option is seen
// at a glance in Ledger's own material: its row on the menu's paper, its words semibold, the green tick at its end. A
// pointer marks an option by underlining its words in the ink, as a frameless act's words are; the keyboard by the
// accountant's double rule under them. Both run under the words alone, inside their own row: no wash a second choice
// could be mistaken for, and no rule across the list a break between options could. In the lists a field opens (the
// select, the combobox; a tag field's suggestions leave the chosen out and wear the same row) and in the menu, at 390
// and 1440, by day and by night.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

Widget _host(Widget child, Brightness brightness) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => LedgerHost(brightness: brightness, child: page!),
  home: Builder(
    builder: (context) => SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: LedgerLayout.gutter(context),
        vertical: 24,
      ),
      child: child,
    ),
  ),
);

/// The option worded [words] in the open list (the field's own face may say the chosen one's words too: the list is
/// built after it).
Finder _option(String words) => find.text(words).last;

/// The fill under the option worded [words], between its words and the list's paper: null for none.
Color? _ground(WidgetTester t, String words) {
  final paper = LedgerTheme.of(t.element(_option(words))).surface;
  Color? found;
  t.element(_option(words)).visitAncestorElements((e) {
    final w = e.widget;
    final fill = switch (w) {
      ColoredBox(:final color) => color,
      DecoratedBox(decoration: BoxDecoration(:final color?)) => color,
      _ => null,
    };
    if (fill == null || fill.a == 0) return true;
    if (fill == paper) return false;
    found = fill;
    return false;
  });
  return found;
}

/// How the option worded [words] is set: its weight and the rule under it.
({FontWeight? weight, TextDecoration? rule, TextDecorationStyle? style}) _words(
  WidgetTester t,
  String words,
) {
  final s = t.widget<Text>(_option(words)).style!;
  return (weight: s.fontWeight, rule: s.decoration, style: s.decorationStyle);
}

/// A list to open: its name, the widget, how a person opens it, the chosen option and another.
typedef _List = (
  String,
  Widget,
  Future<void> Function(WidgetTester),
  String,
  String,
);

final List<_List> _lists = [
  (
    'a select',
    LedgerSelect<String>(
      labelText: 'Currency',
      value: 'USD',
      items: const [
        LedgerSelectItem(value: 'USD', label: 'US dollar'),
        LedgerSelectItem(value: 'EUR', label: 'Euro'),
        LedgerSelectItem(value: 'GBP', label: 'Pound sterling'),
      ],
      onChanged: (_) {},
    ),
    // Its face: from 600 a select stands at a short entry's measure at the start of its slot.
    (t) => t.tap(
      find
          .descendant(
            of: find.byType(LedgerSelect<String>),
            matching: find.byType(LedgerPressable),
          )
          .first,
    ),
    'US dollar',
    'Euro',
  ),
  (
    'a combobox',
    LedgerCombobox<String>(
      labelText: 'Payee',
      value: 'Cedar Books',
      options: const ['Corner Market', 'Cedar Books', 'Blue Fern Café'],
      onSelected: (_) {},
    ),
    (t) async {
      final entry = find.byType(EditableText).first;
      await t.tap(entry);
      await t.pump();
      await t.enterText(entry, 'C');
    },
    // ui_core opens the list on the field's value, the keyboard's place (Enter takes it), so the chosen one wears
    // the double rule from the start; the last stands for the others.
    'Cedar Books',
    'Blue Fern Café',
  ),
  (
    'a menu',
    const LedgerMenu(
      head: 'Spent by month',
      items: [
        LedgerMenuItem('September 2026', amount: 2310.40, onTap: _none),
        LedgerMenuItem(
          'October 2026',
          amount: 2486.12,
          selected: true,
          onTap: _none,
        ),
        LedgerMenuItem('November 2026', amount: 412.08, onTap: _none),
      ],
    ),
    (t) async {},
    'October 2026',
    'November 2026',
  ),
];

void _none() {}

void main() {
  for (final (name, list, open, chosen, other) in _lists) {
    for (final size in const [Size(390, 844), Size(1440, 900)]) {
      for (final brightness in Brightness.values) {
        final at =
            '${size.width.round()}, ${brightness == Brightness.dark ? 'by night' : 'by day'}';

        testWidgets(
          '$name at $at: the chosen option on the menu\'s paper; a pointer and the keyboard mark only the '
          'words of their own option',
          (t) async {
            t.view.physicalSize = size;
            t.view.devicePixelRatio = 1;
            addTearDown(t.view.reset);
            await t.pumpWidget(_host(list, brightness));
            await t.pumpAndSettle();
            await open(t);
            await t.pumpAndSettle();
            final theme = LedgerTheme.of(t.element(_option(chosen)));

            // At rest: the chosen one on the menu's paper, semibold; another on the list's own paper, plain, unruled.
            expect(
              _ground(t, chosen),
              theme.menuSelected,
              reason: 'the chosen row stands on the menu\'s paper',
            );
            expect(_words(t, chosen).weight, FontWeight.w600);
            expect(_ground(t, other), isNull);
            expect(_words(t, other).weight, isNot(FontWeight.w600));
            expect(_words(t, other).rule, isNull);

            // Under a pointer: the other's words take the ink underline, its row no fill; the chosen one is unchanged
            // (a combobox's is the keyboard's place too, its double rule apart from the pointer's single one).
            final atRest = _words(t, chosen);
            final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
            await mouse.addPointer(location: Offset.zero);
            await mouse.moveTo(t.getCenter(_option(other)));
            await t.pumpAndSettle();
            expect(
              _words(t, other).rule,
              TextDecoration.underline,
              reason: 'a pointer underlines the words',
            );
            expect(_words(t, other).style, TextDecorationStyle.solid);
            expect(
              _ground(t, other),
              isNull,
              reason: 'no wash a second choice could be taken for',
            );
            expect(_ground(t, chosen), theme.menuSelected);
            expect(_words(t, chosen), atRest);
            await mouse.moveTo(Offset.zero);
            await t.pumpAndSettle();
            expect(_words(t, other).rule, isNull);
            // The mouse goes: in a widget test, focus a key moves shows on no pressable while a mouse is
            // connected (FocusableActionDetector reports no highlight; a button's ring stays off too).
            await mouse.removePointer();
            await t.pumpAndSettle();

            // The keyboard on an option: the double rule under its words, and no rule across the list. Focus shows
            // only once the keyboard moves it (a select puts it on its chosen option as it opens, unmarked under
            // a touch or a pointer): the arrow keys in a select's or a combobox's list, Tab into a menu.
            await t.sendKeyEvent(
              name == 'a menu'
                  ? LogicalKeyboardKey.tab
                  : LogicalKeyboardKey.arrowDown,
            );
            await t.pumpAndSettle();
            final ruled = [
              for (final w in t.widgetList<Text>(find.byType(Text)))
                if (w.style?.decorationStyle == TextDecorationStyle.double &&
                    w.style?.decoration != null)
                  w.data,
            ];
            expect(
              ruled,
              hasLength(1),
              reason: 'the keyboard marks one option\'s words: $ruled',
            );
            expect(
              _ground(t, ruled.single!),
              ruled.single == chosen ? theme.menuSelected : isNull,
            );
            // The option's press target leaves the focus rule under its face to its words: no rule runs under the
            // row, across the list's rules.
            final rulers = [
              for (final w in t.widgetList<LedgerPressable>(
                find.ancestor(
                  of: _option(ruled.single!),
                  matching: find.byType(LedgerPressable),
                ),
              ))
                if (w.rulesFocus) w,
            ];
            expect(rulers, isEmpty, reason: 'no focus rule across the list');
          },
        );
      }
    }
  }
}
