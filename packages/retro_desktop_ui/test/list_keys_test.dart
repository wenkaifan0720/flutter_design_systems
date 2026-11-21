// ui_core 0.2.0's list keys, through the look's own wrappers: a combobox's list opens on every option with the chosen
// one lit, its arrows go round, Down on a closed list only opens it, edited words filter, the pointer moves the one lit
// row (highlightFollowsPointer), a long list opens on its choice and keeps the lit row in view; a menu bar's menu goes to
// the item a typed letter starts. A row is lit when it stands on the look's highlight bar. The look's combobox takes no
// disabled options, so ui_core's disabled-option keys are its own tests' alone.
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

const _countries = ['Austria', 'Belgium', 'Chile', 'Denmark'];

Widget _host(Widget child) => MaterialApp(
  builder: (context, child) =>
      RetroDesktopTheme(data: RetroDesktopThemeData.classic(), child: child!),
  home: Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(width: 320, child: child),
    ),
  ),
);

// The row's words on the look's highlight bar.
bool _lit(WidgetTester tester, String words) {
  final row = find.byWidgetPredicate((w) => w is Text && w.data == words);
  if (row.evaluate().isEmpty) return false;
  final highlight = RetroDesktopTheme.of(tester.element(row.first))
      .colors
      .highlight;
  return find
      .ancestor(
        of: row,
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is ShapeDecoration &&
              (w.decoration as ShapeDecoration).color == highlight,
        ),
      )
      .evaluate()
      .isNotEmpty;
}

// The options the open list shows, in order (the field's own words are an editor's, not a Text).
List<String> _listed() => [
  for (final o in _countries)
    if (find
        .byWidgetPredicate((w) => w is Text && w.data == o)
        .evaluate()
        .isNotEmpty)
      o,
];

// The one option lit among those shown.
String? _litOne(WidgetTester tester) {
  final lit = _listed().where((o) => _lit(tester, o)).toList();
  return lit.length == 1 ? lit.single : null;
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a combobox opens on every option, the chosen one lit; the '
      'arrows go round; Down on a closed list only opens it; edited words '
      'filter', (tester) async {
    String? value = 'Belgium';
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => RetroDesktopCombobox<String>(
            label: 'Country',
            options: _countries,
            value: value,
            onSelected: (o) => setState(() => value = o),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(_listed(), _countries, reason: 'a press lists every option');
    expect(_litOne(tester), 'Belgium', reason: 'the chosen one lit');

    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_litOne(tester), 'Chile');
    expect(
      find.byIcon(RetroDesktopGlyphs.check),
      findsOneWidget,
      reason: 'the choice keeps its check while another row is lit',
    );
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_litOne(tester), 'Denmark');
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_litOne(tester), 'Austria', reason: 'Down at the last goes round');
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(_litOne(tester), 'Denmark', reason: 'Up at the first goes round');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(value, 'Denmark');
    expect(_listed(), isEmpty, reason: 'taking one closes the list');

    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_listed(), _countries, reason: 'Down reopens it on every option');
    expect(_litOne(tester), 'Denmark', reason: 'and only opens it');
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(_litOne(tester), 'Chile');
    await _key(tester, LogicalKeyboardKey.escape);
    expect(_listed(), isEmpty);
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(_litOne(tester), 'Denmark', reason: 'Up only opens it too');

    await tester.enterText(find.byType(EditableText), 'ch');
    await tester.pumpAndSettle();
    expect(_listed(), ['Chile'], reason: 'edited words filter');
    expect(_litOne(tester), 'Chile');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(value, 'Chile');
  });

  // highlightFollowsPointer: one lit row, as in the period's pop-up menus and the look's select, never two that read
  // as two current options.
  testWidgets('in a combobox the pointer moves the one lit row, and the keys '
      'go on from it', (tester) async {
    await tester.pumpWidget(
      _host(
        RetroDesktopCombobox<String>(
          label: 'Country',
          options: _countries,
          value: 'Belgium',
          onSelected: (_) {},
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(_litOne(tester), 'Belgium');

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('Denmark')));
    await tester.pumpAndSettle();
    expect(_litOne(tester), 'Denmark', reason: 'the pointer lights its row');
    expect(_listed().where((o) => _lit(tester, o)), [
      'Denmark',
    ], reason: 'and only its row');
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(_litOne(tester), 'Chile', reason: 'the keys go on from it');

    await mouse.moveTo(const Offset(600, 500));
    await tester.pumpAndSettle();
    expect(_litOne(tester), 'Chile', reason: 'leaving the list keeps it');
  });

  testWidgets('a long combobox list opens with its choice in view, and the '
      'keys keep the lit row in view', (tester) async {
    final many = [for (var i = 1; i <= 40; i++) 'Folder $i'];
    await tester.pumpWidget(
      _host(
        RetroDesktopCombobox<String>(
          label: 'Folder',
          options: many,
          value: 'Folder 37',
          onSelected: (_) {},
        ),
      ),
    );
    // A row of the list in view (the field's own words are an editor's, not a Text).
    Finder row(String words) => find
        .byWidgetPredicate((w) => w is Text && w.data == words)
        .hitTestable();
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(row('Folder 37'), findsOneWidget, reason: 'the choice is in view');
    expect(row('Folder 1'), findsNothing);
    expect(_lit(tester, 'Folder 37'), isTrue);

    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_lit(tester, 'Folder 1'), isTrue, reason: 'round from the last');
    expect(row('Folder 1'), findsOneWidget, reason: 'the lit row in view');
  });

  testWidgets('in an empty combobox, Down opens every option at the first', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        RetroDesktopCombobox<String>(
          label: 'Country',
          options: _countries,
          onSelected: (_) {},
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    await _key(tester, LogicalKeyboardKey.escape);
    expect(_listed(), isEmpty);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_listed(), _countries);
    expect(_litOne(tester), 'Austria');
  });

  testWidgets('in a menu bar\'s menu, a typed letter goes to the next item it '
      'starts; letters typed in a run spell the start', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.pumpWidget(
      _host(
        RetroDesktopMenuBar(
          menus: [
            RawMenuEntry(
              label: 'File',
              children: [
                for (final label in [
                  'New',
                  'Open',
                  'Open recent',
                  'Print',
                  'Close',
                  'Quit',
                ])
                  RawMenuEntry(label: label, onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_lit(tester, 'New'), isTrue);
    Future<void> pause() => tester.pump(const Duration(seconds: 1));
    await _key(tester, LogicalKeyboardKey.keyQ);
    expect(_lit(tester, 'Quit'), isTrue);
    await pause();
    await _key(tester, LogicalKeyboardKey.keyN);
    expect(_lit(tester, 'New'), isTrue, reason: 'round past the end');
    await pause();
    await _key(tester, LogicalKeyboardKey.keyO);
    expect(_lit(tester, 'Open'), isTrue);
    await _key(tester, LogicalKeyboardKey.keyP);
    expect(_lit(tester, 'Open'), isTrue, reason: '"op" still fits it');
    await pause();
    await _key(tester, LogicalKeyboardKey.keyO);
    expect(
      _lit(tester, 'Open recent'),
      isTrue,
      reason: 'the next item O starts',
    );
    expect(_lit(tester, 'Open'), isFalse, reason: 'one row lit');
    await pause();
    await _key(tester, LogicalKeyboardKey.keyZ);
    expect(_lit(tester, 'Open recent'), isTrue, reason: 'no item: it stays');
    expect(find.text('Print'), findsOneWidget, reason: 'the menu stays open');
  });
}
