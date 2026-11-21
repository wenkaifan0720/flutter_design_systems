// ui_core's own list keys (0.2.0), as Minimal's lists carry them: the
// combobox (RawCombobox), the multi-select (RawTagInput) and the menu
// bar (RawMenuBar). The row the keys are on is the one on the muted fill
// ("lit"). Up and Down go round the ends; Down or Up on a closed list only
// opens it, on the chosen option (else the first); the list shows every
// option until the words are edited; done takes the lit option; a menu bar's
// menu goes to the next item a typed letter starts. Minimal's combobox and
// multi-select take no disabled options, so none is passed over here. The
// pointer moves the one lit row (ui_core's highlightFollowsPointer, on in
// Minimal: the pointer's row and the keys' are painted alike), and the keys
// go on from where it left it. A menu bar's menu keeps Minimal's one place:
// opened by the pointer it lights none (the first arrow lands on the first
// row), and the pointer moves the place.
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

const _fruit = ['Apple', 'Apricot', 'Banana', 'Blueberry', 'Cherry'];
const _colours = ['Red', 'Green', 'Blue', 'Black'];

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [SizedBox(width: 320, child: child)],
      ),
    ),
  ),
);

/// A list row's words (a Text, never the field's own EditableText).
Finder _row(String label) =>
    find.byWidgetPredicate((w) => w is Text && w.data == label);

/// Of [all], the options the open list shows, in order.
List<String> _listed(List<String> all) => [
  for (final o in all)
    if (_row(o).evaluate().isNotEmpty) o,
];

Color? _fill(WidgetTester tester, String label) {
  final box = find.ancestor(
    of: _row(label).last,
    matching: find.byWidgetPredicate(
      (w) => w is Container && w.decoration != null,
    ),
  );
  return switch (tester.widget<Container>(box.first).decoration) {
    BoxDecoration(:final color) => color,
    ShapeDecoration(:final color) => color,
    _ => null,
  };
}

/// Of [all], the one option on the muted fill; null when none is, or more.
String? _lit(WidgetTester tester, MinimalThemeData t, List<String> all) {
  final lit = [
    for (final o in _listed(all))
      if (_fill(tester, o) == t.muted) o,
  ];
  return lit.length == 1 ? lit.single : null;
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  final t = MinimalThemeData.preset('standard', Brightness.light);

  group('combobox', () {
    testWidgets('a press lists every option on the chosen one; the keys go '
        'round the ends; Down or Up on a closed list only opens it; edited '
        'words filter', (tester) async {
      var value = 'Banana';
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => MinimalCombobox<String>(
              label: 'Fruit',
              options: _fruit,
              value: value,
              onSelected: (o) => setState(() => value = o),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(_listed(_fruit), _fruit, reason: 'a press lists every option');
      expect(_lit(tester, t, _fruit), 'Banana', reason: 'on the chosen one');

      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester, t, _fruit), 'Blueberry');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester, t, _fruit), 'Cherry');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester, t, _fruit), 'Apple', reason: 'round the end');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_lit(tester, t, _fruit), 'Cherry', reason: 'round the start');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(value, 'Cherry', reason: 'done takes the lit one');
      expect(_listed(_fruit), isEmpty, reason: 'and closes the list');

      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_listed(_fruit), _fruit, reason: 'Down reopens every option');
      expect(_lit(tester, t, _fruit), 'Cherry', reason: 'and only opens it');
      await _key(tester, LogicalKeyboardKey.escape);
      expect(_listed(_fruit), isEmpty);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_lit(tester, t, _fruit), 'Cherry', reason: 'Up only opens it');

      await tester.enterText(find.byType(EditableText), 'ap');
      await tester.pumpAndSettle();
      expect(_listed(_fruit), ['Apple', 'Apricot'], reason: 'edited words');
      expect(_lit(tester, t, _fruit), 'Apple');
    });

    testWidgets('the pointer moves the one lit row, and the keys go on from '
        'it', (tester) async {
      await tester.pumpWidget(
        _host(
          MinimalCombobox<String>(
            label: 'Fruit',
            options: _fruit,
            value: 'Banana',
            onSelected: (_) {},
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(_lit(tester, t, _fruit), 'Banana');
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(_row('Apricot').last));
      await tester.pumpAndSettle();
      expect(_lit(tester, t, _fruit), 'Apricot', reason: 'one place, moved');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester, t, _fruit), 'Banana', reason: 'on from the pointer');
      await mouse.moveTo(tester.getCenter(_row('Cherry').last));
      await tester.pumpAndSettle();
      expect(_lit(tester, t, _fruit), 'Cherry');
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(_lit(tester, t, _fruit), 'Cherry', reason: 'it stays on leaving');
    });

    testWidgets('a long list opens with its value in view, and the keys keep '
        'the lit row in view', (tester) async {
      final many = [for (var i = 1; i <= 24; i++) 'Zone $i'];
      await tester.pumpWidget(
        _host(
          MinimalCombobox<String>(
            label: 'Time zone',
            options: many,
            value: 'Zone 21',
            onSelected: (_) {},
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      bool seen(String o) => _row(o).hitTestable().evaluate().isNotEmpty;
      expect(seen('Zone 21'), isTrue, reason: 'opens on its value, in view');
      expect(seen('Zone 1'), isFalse, reason: 'scrolled to it');
      expect(_lit(tester, t, many), 'Zone 21');
      for (var i = 0; i < 4; i++) {
        await _key(tester, LogicalKeyboardKey.arrowDown);
      }
      expect(_lit(tester, t, many), 'Zone 1', reason: 'round the end');
      expect(seen('Zone 1'), isTrue, reason: 'the lit row is in view');
    });

    testWidgets('empty, Down opens every option on the first', (tester) async {
      await tester.pumpWidget(
        _host(
          MinimalCombobox<String>(
            label: 'Fruit',
            options: _fruit,
            onSelected: (_) {},
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      await _key(tester, LogicalKeyboardKey.escape);
      expect(_listed(_fruit), isEmpty);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_listed(_fruit), _fruit);
      expect(_lit(tester, t, _fruit), 'Apple');
    });
  });

  testWidgets('multi-select: the suggestions go round the ends, Down on a '
      'closed list only opens it, and done takes the lit one', (tester) async {
    var values = <String>[];
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => MinimalMultiSelect<String>(
            label: 'Colours',
            values: values,
            options: _colours,
            onChanged: (v) => setState(() => values = v),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(_listed(_colours), _colours);
    expect(_lit(tester, t, _colours), 'Red');
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(_lit(tester, t, _colours), 'Black', reason: 'round the start');
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_lit(tester, t, _colours), 'Red', reason: 'round the end');
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_lit(tester, t, _colours), 'Green');
    await _key(tester, LogicalKeyboardKey.escape);
    expect(_listed(_colours), isEmpty);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_listed(_colours), _colours);
    expect(
      _lit(tester, t, _colours),
      'Red',
      reason: 'only opens, at the first',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(values, ['Red']);
  });

  testWidgets("menu bar: in a menu, a typed letter goes to the next item it "
      'starts', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    const items = ['New', 'Open', 'Save', 'Quit'];
    await tester.pumpWidget(
      _host(
        MinimalMenuBar(
          menus: [
            MinimalMenuEntry(
              'File',
              children: [
                for (final label in items)
                  MinimalMenuEntry(label, onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_lit(tester, t, items), 'New');
    Future<void> pause() => tester.pump(const Duration(seconds: 1));
    await _key(tester, LogicalKeyboardKey.keyQ);
    expect(_lit(tester, t, items), 'Quit');
    await pause();
    await _key(tester, LogicalKeyboardKey.keyN);
    expect(_lit(tester, t, items), 'New', reason: 'round past the end');
    await pause();
    await _key(tester, LogicalKeyboardKey.keyS);
    expect(_lit(tester, t, items), 'Save');
    await pause();
    await _key(tester, LogicalKeyboardKey.keyZ);
    expect(_lit(tester, t, items), 'Save', reason: 'no item: it stays');
  });

  group('menu bar', () {
    const items = ['New', 'Open', 'Save', 'Quit'];
    Widget bar() => _host(
      MinimalMenuBar(
        menus: [
          MinimalMenuEntry(
            'File',
            children: [
              for (final label in items)
                MinimalMenuEntry(label, onPressed: () {}),
            ],
          ),
        ],
      ),
    );
    // The keyboard's highlights on throughout: a row with the keys shows
    // whatever opened the menu.
    setUp(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional,
    );
    tearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );

    testWidgets('opened by the pointer a menu lights no row, and the first '
        'Down lands on the first', (tester) async {
      await tester.pumpWidget(bar());
      await tester.tap(find.text('File'), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(_listed(items), items);
      expect([
        for (final o in items)
          if (_fill(tester, o) == t.muted) o,
      ], isEmpty);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester, t, items), 'New');
      await _key(tester, LogicalKeyboardKey.escape);
      await tester.tap(find.text('File'), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_lit(tester, t, items), 'Quit', reason: 'Up: the last');
    });

    testWidgets('the pointer moves the one lit row; the keys go on from it; '
        'off the rows none is lit', (tester) async {
      await tester.pumpWidget(bar());
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester, t, items), 'New', reason: 'a key opened it');
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(_row('Save').last));
      await tester.pumpAndSettle();
      expect(_lit(tester, t, items), 'Save', reason: 'the pointer moved it');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester, t, items), 'Quit', reason: 'on from the pointer');
      await mouse.moveTo(tester.getCenter(_row('Open').last));
      await tester.pumpAndSettle();
      expect(_lit(tester, t, items), 'Open');
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(
        [
          for (final o in items)
            if (_fill(tester, o) == t.muted) o,
        ],
        isEmpty,
        reason: 'the pointer gone off the rows',
      );
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester, t, items), 'New', reason: 'then Down: the first');
    });
  });
}
