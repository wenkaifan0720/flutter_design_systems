// What reads current in a field's open list (a select's) and its open
// calendar (a date field's). Opened by the pointer: nothing but the chosen
// row's bar or day until a key (with nothing chosen, no row at all; the
// first Down then shows the first, Return chooses nothing unseen; with one
// chosen, the first key moves from it at once). Opened by the keys: the
// keys' row or day at once, the chosen one (else the first), and a
// calendar's keys on its day, never on the month's arrow. A press focuses
// the field, so Escape, however it opened, gives the focus back to it. Its
// rows stand a cell inside the frame each side, as a menu's do.
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(width: 420, child: child),
      ),
    ),
  ),
);

// A desk: a pointer and keys, rows one line tall.
final _desk = TargetPlatformVariant.only(TargetPlatform.macOS);

const _names = ['alpha', 'bravo', 'charlie'];

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await _settle(tester);
}

Future<void> _click(WidgetTester tester, Finder f) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  final at = tester.getCenter(f);
  await mouse.moveTo(at);
  await mouse.down(at);
  await mouse.up();
  // Off the list, so no row is under the pointer.
  await mouse.moveTo(const Offset(2, 2));
  await _settle(tester);
}

// The select's rows that show the keys' block.
List<String> _lit() => [
  for (final e in find.byType(TermListTile).evaluate())
    if (find
        .descendant(
          of: find.byElementPredicate((x) => identical(x, e)),
          matching: find.byWidgetPredicate(
            (w) => w is TermStateSprings && w.focused,
          ),
        )
        .evaluate()
        .isNotEmpty)
      ((e.widget as TermListTile).title as Text).data!,
];

String? _chosenRow() {
  for (final e in find.byType(TermListTile).evaluate()) {
    final tile = e.widget as TermListTile;
    if (tile.selected) return (tile.title as Text).data;
  }
  return null;
}

// The days wrapped in the keys' brackets (the month's arrows wear theirs
// as their face, lit or not: whether one has the focus is [_arrowFocused]).
List<String> _bracketed() => [
  for (final e
      in find
          .byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is TermBracketPainter,
          )
          .evaluate())
    if (e.findAncestorWidgetOfExactType<TermIconButton>() == null)
      for (final t
          in find
              .descendant(
                of: find.byElementPredicate((x) => identical(x, e)),
                matching: find.byType(Text),
              )
              .evaluate())
        (t.widget as Text).data!.trim(),
];

bool _arrowFocused() {
  final context = FocusManager.instance.primaryFocus?.context;
  return context != null &&
      context.findAncestorWidgetOfExactType<TermIconButton>() != null;
}

void main() {
  group('a select', () {
    late String? chosen;

    Future<void> pump(WidgetTester tester, {String? value}) async {
      chosen = value;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => TermSelect<String>(
              labelText: 'environment',
              hintText: 'choose one',
              value: chosen,
              items: [
                for (final n in _names) TermSelectItem(value: n, label: n),
              ],
              onChanged: (v) => setState(() => chosen = v),
            ),
          ),
        ),
      );
    }

    testWidgets('none chosen, opened by the pointer: no row lit until a key; '
        'the first Down shows the first, the next moves', (tester) async {
      await pump(tester);
      await _click(tester, find.byType(TermSelect<String>));
      expect(find.byType(TermListTile), findsNWidgets(3));
      expect(_lit(), isEmpty);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(), ['alpha']);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(), ['bravo']);
    }, variant: _desk);

    testWidgets('none chosen, opened by the pointer: Return shows the first '
        'and chooses nothing', (tester) async {
      await pump(tester);
      await _click(tester, find.byType(TermSelect<String>));
      await _key(tester, LogicalKeyboardKey.enter);
      expect(find.byType(TermListTile), findsNWidgets(3));
      expect(_lit(), ['alpha']);
      expect(chosen, isNull);
    }, variant: _desk);

    testWidgets('one chosen, opened by the pointer: its bar alone; the first '
        'Down moves from it at once', (tester) async {
      await pump(tester, value: 'bravo');
      await _click(tester, find.byType(TermSelect<String>));
      expect(_chosenRow(), 'bravo');
      expect(_lit(), isEmpty);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(), ['charlie']);
    }, variant: _desk);

    testWidgets('opened by the pointer, Escape gives the focus to the field: '
        'Return opens it again', (tester) async {
      await pump(tester);
      await _click(tester, find.byType(TermSelect<String>));
      await _key(tester, LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(TermListTile), findsNothing);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(find.byType(TermListTile), findsNWidgets(3));
      expect(_lit(), ['alpha']);
    }, variant: _desk);

    testWidgets('opened by the keys: the first lit at once, or the chosen', (
      tester,
    ) async {
      await pump(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.enter);
      expect(_lit(), ['alpha']);
      await _key(tester, LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await pump(tester, value: 'charlie');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.enter);
      expect(_lit(), ['charlie']);
    }, variant: _desk);

    testWidgets("its rows a cell inside the frame each side: the words a "
        "cell in from the field's", (tester) async {
      await pump(tester, value: 'alpha');
      await _click(tester, find.byType(TermSelect<String>));
      const grid = TermGrid();
      final cw = grid.cellWidth;
      final list = find.byType(TermPane).last;
      final row = find.byType(TermListTile).first;
      // The frame's cell, then the cell inside it.
      expect(
        tester.getTopLeft(row).dx - tester.getTopLeft(list).dx,
        closeTo(2 * cw, .01),
      );
      expect(
        tester.getTopRight(list).dx - tester.getTopRight(row).dx,
        closeTo(2 * cw, .01),
      );
      final field = find.descendant(
        of: find.byType(TermSelect<String>),
        matching: find.text('alpha'),
      );
      final inList = find.descendant(of: list, matching: find.text('alpha'));
      expect(
        tester.getTopLeft(inList).dx - tester.getTopLeft(field.first).dx,
        closeTo(cw, .01),
      );
    }, variant: _desk);
  });

  group('a date field', () {
    Future<void> pump(WidgetTester tester) => tester.pumpWidget(
      _host(
        TermDatePicker(
          labelText: 'release on',
          value: DateTime(2026, 11, 14),
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          currentDate: DateTime(2026, 11, 15),
          onChanged: (_) {},
        ),
      ),
    );

    testWidgets('opened by the pointer: the chosen day alone reads current, '
        'the month arrows unlit; a key shows the keys where it moves', (
      tester,
    ) async {
      await pump(tester);
      await _click(tester, find.byType(TermDatePicker));
      expect(find.text('14'), findsOneWidget);
      expect(_arrowFocused(), isFalse, reason: 'the focus on the days');
      expect(_bracketed(), isEmpty);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_bracketed(), ['15']);
    }, variant: _desk);

    testWidgets('opened by the pointer, Escape gives the focus to the field: '
        'Return opens it again, the keys on the chosen day', (tester) async {
      await pump(tester);
      await _click(tester, find.byType(TermDatePicker));
      await _key(tester, LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('14'), findsNothing);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(_bracketed(), ['14']);
    }, variant: _desk);

    testWidgets('opened by the keys: the keys on the chosen day, each time', (
      tester,
    ) async {
      await pump(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.enter);
      expect(_arrowFocused(), isFalse);
      expect(_bracketed(), ['14']);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_bracketed(), ['13']);
      // Closed and opened again: the keys back on the chosen day, not where
      // they were left.
      await _key(tester, LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await _key(tester, LogicalKeyboardKey.enter);
      expect(_bracketed(), ['14']);
    }, variant: _desk);
  });
}
