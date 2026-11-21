// An open menu (a menu, a split button's, a menubar's) has one current row:
// the keys' row, which the pointer moves as it moves onto a row, so the
// pointer's row and the keys' never read as two. While the pointer moved it
// last, the row has the pointer's mark (its words, or a chosen row's bar,
// in the accent), lighter than the keys' cursor; the first key brings the
// cursor. Opened by the pointer it lights no row until the pointer moves
// onto one or a key is pressed (the first Down shows the first row); opened
// by the keys it lights the first.
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: TermTheme(
    data: TermThemeData.dark(),
    child: Align(
      alignment: Alignment.topLeft,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

// A desk: a pointer and keys, rows one line tall.
final _desk = TargetPlatformVariant.only(TargetPlatform.macOS);

// The rows that show as current: the keys' cursor drawn on them.
List<String> _lit() => [
  for (final e in find.byType(TermMenuRow).evaluate())
    if (find
        .descendant(
          of: find.byElementPredicate((x) => identical(x, e)),
          matching: find.byWidgetPredicate(
            (w) =>
                w is CustomPaint &&
                w.painter is TermCursorPainter &&
                (w.painter! as TermCursorPainter).amount > 0.5,
          ),
        )
        .evaluate()
        .isNotEmpty)
      (e.widget as TermMenuRow).label,
];

// The rows the pointer marks: no cursor, their words or their bar in the
// accent.
List<String> _pointed(WidgetTester tester) {
  final accent = TermThemeData.dark().accent;
  return [
    for (final e in find.byType(TermMenuRow).evaluate())
      if (!_lit().contains((e.widget as TermMenuRow).label) &&
          tester
              .widgetList(
                find.descendant(
                  of: find.byElementPredicate((x) => identical(x, e)),
                  matching: find.byWidgetPredicate(
                    (w) =>
                        (w is Text && w.style?.color == accent) ||
                        (w is ColoredBox && w.color == accent),
                  ),
                ),
              )
              .isNotEmpty)
        (e.widget as TermMenuRow).label,
  ];
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await _settle(tester);
}

Future<TestGesture> _mouse(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  return mouse;
}

Future<void> _click(WidgetTester tester, TestGesture mouse, Finder f) async {
  final at = tester.getCenter(f);
  await mouse.moveTo(at);
  await mouse.down(at);
  await mouse.up();
  await _settle(tester);
}

Finder _row(String label) => find.byWidgetPredicate(
  (w) => w is TermMenuRow && w.label.startsWith(label),
);

// The three menus, each with what opens it and its rows' words.
final _menus = <({String name, Widget menu, Finder opener, List<String> rows})>[
  (
    name: 'a menu',
    menu: TermMenu(
      anchorBuilder: (context, anchor) =>
          TermButton(label: 'more', onPressed: anchor.toggle),
      items: [
        for (final n in const ['rerun', 'copy link', 'delete logs'])
          TermMenuItem(label: n, onPressed: () {}),
      ],
    ),
    opener: find.text('more'),
    rows: const ['rerun', 'copy link', 'delete logs'],
  ),
  (
    name: "a split button's menu",
    menu: const TermSplitButton(
      label: 'deploy',
      onPressed: _noop,
      menuLabel: 'deploy to',
      actions: [
        RawSplitAction(label: 'staging', onPressed: _noop),
        RawSplitAction(label: 'production', onPressed: _noop),
        RawSplitAction(label: 'preview', onPressed: _noop),
      ],
    ),
    opener: find.text('▾'),
    rows: const ['staging', 'production', 'preview'],
  ),
  (
    name: "a menubar's menu",
    menu: TermMenuBar(
      menus: [
        RawMenuEntry(
          label: 'view',
          children: [
            RawMenuEntry(label: 'timestamps', onPressed: () {}),
            RawMenuEntry(label: 'wrap lines', checked: true, onPressed: () {}),
            RawMenuEntry(label: 'follow', onPressed: () {}),
          ],
        ),
      ],
    ),
    opener: find.text('view'),
    rows: const ['timestamps', 'wrap lines', 'follow'],
  ),
];

void _noop() {}

void main() {
  for (final m in _menus) {
    group(m.name, () {
      testWidgets('opened by the pointer: no row lit', (tester) async {
        await tester.pumpWidget(_host(m.menu));
        final mouse = await _mouse(tester);
        await _click(tester, mouse, m.opener);
        expect(find.byType(TermMenuRow), findsNWidgets(m.rows.length));
        expect(_lit(), isEmpty);
      }, variant: _desk);

      testWidgets('the pointer moves the one current row; the keys move it '
          'on from there', (tester) async {
        await tester.pumpWidget(_host(m.menu));
        final mouse = await _mouse(tester);
        await _click(tester, mouse, m.opener);
        await mouse.moveTo(tester.getCenter(_row(m.rows[1])));
        await _settle(tester);
        expect(_lit(), isEmpty);
        expect(_pointed(tester), [m.rows[1]]);
        // The pointer stays on the second row: one row current, the keys'.
        await _key(tester, LogicalKeyboardKey.arrowDown);
        expect(_lit(), [m.rows[2]]);
        expect(_pointed(tester), isEmpty);
        await mouse.moveTo(tester.getCenter(_row(m.rows[0])));
        await _settle(tester);
        expect(_lit(), isEmpty);
        expect(_pointed(tester), [m.rows[0]]);
      }, variant: _desk);

      testWidgets('opened by a finger, a pointer moving onto a row shows it', (
        tester,
      ) async {
        await tester.pumpWidget(_host(m.menu));
        await tester.tap(m.opener);
        await _settle(tester);
        expect(_lit(), isEmpty);
        final mouse = await _mouse(tester);
        await mouse.moveTo(tester.getCenter(_row(m.rows[2])));
        await _settle(tester);
        expect(_lit(), isEmpty);
        expect(_pointed(tester), [m.rows[2]]);
      }, variant: _desk);

      testWidgets('opened by the pointer, the first Down shows the first; Up '
          'goes round to the last', (tester) async {
        await tester.pumpWidget(_host(m.menu));
        final mouse = await _mouse(tester);
        await _click(tester, mouse, m.opener);
        await _key(tester, LogicalKeyboardKey.arrowDown);
        expect(_lit(), [m.rows[0]]);
        await _key(tester, LogicalKeyboardKey.arrowDown);
        expect(_lit(), [m.rows[1]]);
        await _key(tester, LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        await _click(tester, mouse, m.opener);
        await _key(tester, LogicalKeyboardKey.arrowUp);
        expect(_lit(), [m.rows.last]);
      }, variant: _desk);

      testWidgets('opened by the pointer, Return chooses nothing unseen; '
          'Down then shows the first', (tester) async {
        await tester.pumpWidget(_host(m.menu));
        final mouse = await _mouse(tester);
        await _click(tester, mouse, m.opener);
        await _key(tester, LogicalKeyboardKey.enter);
        expect(find.byType(TermMenuRow), findsNWidgets(m.rows.length));
        expect(_lit(), isEmpty);
        await _key(tester, LogicalKeyboardKey.arrowDown);
        expect(_lit(), [m.rows[0]]);
      }, variant: _desk);

      testWidgets('opened by the keys: the first lit', (tester) async {
        await tester.pumpWidget(_host(m.menu));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        if (m.name == "a split button's menu") {
          // Its main half first, then the arrow's.
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
        }
        await _key(
          tester,
          m.name == "a menubar's menu"
              ? LogicalKeyboardKey.arrowDown
              : LogicalKeyboardKey.enter,
        );
        expect(find.byType(TermMenuRow), findsNWidgets(m.rows.length));
        expect(_lit(), [m.rows[0]]);
      }, variant: _desk);
    });
  }
}
