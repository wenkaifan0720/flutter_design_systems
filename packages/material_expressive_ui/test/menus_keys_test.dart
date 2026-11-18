/// The keys in an open list, a select's, a combobox's or a menu's: opened
/// from a key, it starts on the chosen option (else the first); the arrows
/// move at once and wrap, also right after a pointer opened it; Home and End
/// go to the ends; a typed letter jumps; Enter chooses and closes; Escape
/// closes and gives the focus back to the field. And one lit row: the
/// pointer moving over a row lights it, the keys go on from it, and no frame
/// lights two; a menu the pointer opened lights none until something moves.
library;

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/state_face.dart';

final ExpressiveThemeData bloom = ExpressiveThemeData.preset(
  'bloom',
  Brightness.light,
);

/// Expressive's host round a page holding [child] at its start.
Widget host(Widget child, {ExpressiveThemeData? theme}) => MaterialApp(
  builder: (context, app) => ExpressiveHost(
    light: theme ?? bloom,
    brightness: Brightness.light,
    child: app!,
  ),
  home: Padding(
    padding: const EdgeInsets.all(24),
    child: Align(alignment: AlignmentDirectional.topStart, child: child),
  ),
);

const List<ExpressiveSelectOption<String>> sizes = [
  ExpressiveSelectOption('s', 'Small'),
  ExpressiveSelectOption('m', 'Medium'),
  ExpressiveSelectOption('l', 'Large'),
  ExpressiveSelectOption('xl', 'Extra large'),
];

Finder get menu => find.byType(ExpressiveMenuSurface);

/// The words of the menu item with the keyboard's focus: the text drawn
/// inside the focused node's box. Null when the focus is on no item (on
/// the field, or on the list itself).
String? focused() {
  final node = FocusManager.instance.primaryFocus;
  final context = node?.context;
  if (node == null ||
      context == null ||
      node.skipTraversal ||
      context.findAncestorWidgetOfExactType<ExpressiveMenuSurface>() == null) {
    return null;
  }
  for (final element in find.byType(Text).evaluate()) {
    final words = (element.widget as Text).data;
    final box = element.renderObject;
    if (words == null || box is! RenderBox || !box.attached) continue;
    if (node.rect.contains(box.localToGlobal(box.size.center(Offset.zero)))) {
      return words;
    }
  }
  return null;
}

/// A select of [sizes] holding its value, its field's focus [node].
Widget select(FocusNode node, {String? initial, List<String>? chosen}) {
  var value = initial;
  return SizedBox(
    width: 300,
    child: StatefulBuilder(
      builder: (context, update) => ExpressiveSelect<String>(
        options: sizes,
        value: value,
        label: 'Size',
        focusNode: node,
        onChanged: (v) {
          chosen?.add(v);
          update(() => value = v);
        },
      ),
    ),
  );
}

Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

/// The states [words]'s row was last drawn in: those of the face nearest
/// round its text.
Set<WidgetState> statesOf(String words) => find
    .ancestor(of: find.text(words), matching: find.byType(ExpressiveStateFace))
    .evaluate()
    .map((e) => (e.widget as ExpressiveStateFace).states)
    .first;

/// Whether [words]'s row carries ui_core's highlight (the keys' place).
bool lit(String words) => statesOf(words).contains(WidgetState.focused);

/// The words the keys' highlight is on, among [rows] shown.
String? litOne(List<String> rows) {
  final on = [
    for (final row in rows)
      if (find.text(row).evaluate().isNotEmpty && lit(row)) row,
  ];
  return on.length == 1 ? on.single : null;
}

/// Focus drawn as the keyboard's, as after a key press.
void keyboard() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

void main() {
  group('a select', () {
    for (final key in [
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.arrowDown,
    ]) {
      testWidgets('opened by ${key.keyLabel}, starts on the chosen option, '
          'else the first', (tester) async {
        final node = FocusNode();
        addTearDown(node.dispose);
        await tester.pumpWidget(host(select(node, initial: 'l')));
        node.requestFocus();
        await tester.pumpAndSettle();
        await press(tester, key);
        expect(menu, findsOneWidget);
        expect(focused(), 'Large');

        await press(tester, LogicalKeyboardKey.escape);
        await tester.pumpWidget(host(select(node)));
        node.requestFocus();
        await tester.pumpAndSettle();
        await press(tester, key);
        expect(focused(), 'Small');
      });
    }

    testWidgets('the arrows move at once and wrap; Home and End go to the '
        'ends; a typed letter jumps', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(host(select(node, initial: 'xl')));
      node.requestFocus();
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.enter);
      expect(focused(), 'Extra large');
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(focused(), 'Small');
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(focused(), 'Extra large');
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(focused(), 'Large');
      await press(tester, LogicalKeyboardKey.home);
      expect(focused(), 'Small');
      await press(tester, LogicalKeyboardKey.end);
      expect(focused(), 'Extra large');
      await press(tester, LogicalKeyboardKey.keyM);
      expect(focused(), 'Medium');
      await press(tester, LogicalKeyboardKey.keyL);
      expect(focused(), 'Large');
    });

    testWidgets('Enter chooses and closes, the focus back on the field', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final chosen = <String>[];
      await tester.pumpWidget(host(select(node, initial: 's', chosen: chosen)));
      node.requestFocus();
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.enter);
      expect(chosen, ['m']);
      expect(menu, findsNothing);
      expect(node.hasPrimaryFocus, isTrue);
    });

    testWidgets('Escape closes, the focus back on the field', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(host(select(node, initial: 'm')));
      node.requestFocus();
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.enter);
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.escape);
      expect(menu, findsNothing);
      expect(node.hasPrimaryFocus, isTrue);
    });

    testWidgets('opened by a pointer, the arrows work at once: from the '
        'chosen option, else from the ends', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(host(select(node, initial: 'm')));
      await tester.tap(find.byType(ExpressiveTextField));
      await tester.pumpAndSettle();
      expect(menu, findsOneWidget);
      // Nothing ringed yet: the pointer opened it.
      expect(focused(), isNull);
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(focused(), 'Large');

      await press(tester, LogicalKeyboardKey.escape);
      await tester.pumpWidget(host(select(node)));
      await tester.tap(find.byType(ExpressiveTextField));
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(focused(), 'Extra large');
    });
  });

  testWidgets('a combobox holding a choice opens from Down on it; Escape on '
      'an option closes, the focus back on the field', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    final text = TextEditingController(text: 'Large');
    addTearDown(text.dispose);
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 300,
          child: ExpressiveCombobox<String>(
            options: sizes,
            label: 'Size',
            controller: text,
            focusNode: node,
          ),
        ),
      ),
    );
    node.requestFocus();
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(menu, findsOneWidget);
    expect(focused(), 'Large');
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(focused(), 'Extra large');
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(focused(), 'Small');
    await press(tester, LogicalKeyboardKey.escape);
    expect(menu, findsNothing);
    expect(node.hasPrimaryFocus, isTrue);
  });

  testWidgets('a menu opened from its button by a key starts on its first '
      'item; the keys walk it', (tester) async {
    await tester.pumpWidget(
      host(
        ExpressiveMenu(
          label: 'More',
          entries: [
            ExpressiveMenuItem('Rename', onPressed: () {}),
            ExpressiveMenuItem('Archive', onPressed: () {}),
            ExpressiveMenuItem('Delete', onPressed: () {}),
          ],
          child: const SizedBox(width: 48, height: 48),
        ),
      ),
    );
    await press(tester, LogicalKeyboardKey.tab);
    await press(tester, LogicalKeyboardKey.enter);
    expect(menu, findsOneWidget);
    expect(focused(), 'Rename');
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(focused(), 'Delete');
    await press(tester, LogicalKeyboardKey.keyA);
    expect(focused(), 'Archive');
  });

  group('a long select', () {
    final towns = <ExpressiveSelectOption<int>>[
      for (var i = 1; i <= 30; i++) ExpressiveSelectOption(i, 'Town $i'),
    ];

    Widget long(FocusNode node, int value) => SizedBox(
      width: 300,
      child: ExpressiveSelect<int>(
        options: towns,
        value: value,
        label: 'Town',
        focusNode: node,
        menuMaxHeight: 240,
        onChanged: (_) {},
      ),
    );

    /// Whether [words]'s row shows in the open list: a row the list has
    /// scrolled out of its viewport takes no hit.
    bool shown(WidgetTester tester, String words) => find
        .descendant(of: menu, matching: find.text(words))
        .hitTestable()
        .evaluate()
        .isNotEmpty;

    testWidgets('opened by a pointer, it shows its value near the end', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(host(long(node, 27)));
      await tester.tap(find.byType(ExpressiveTextField));
      await tester.pumpAndSettle();
      expect(shown(tester, 'Town 27'), isTrue);
      expect(shown(tester, 'Town 1'), isFalse);
    });

    testWidgets('the keys keep the focused row in view', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(host(long(node, 27)));
      node.requestFocus();
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.enter);
      expect(focused(), 'Town 27');
      expect(shown(tester, 'Town 27'), isTrue);
      await press(tester, LogicalKeyboardKey.home);
      expect(focused(), 'Town 1');
      expect(shown(tester, 'Town 1'), isTrue);
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(focused(), 'Town 30');
      expect(shown(tester, 'Town 30'), isTrue, reason: 'round the end');
      for (var i = 0; i < 3; i++) {
        await press(tester, LogicalKeyboardKey.arrowDown);
      }
      expect(focused(), 'Town 3');
      expect(shown(tester, 'Town 3'), isTrue);
      for (var i = 0; i < 9; i++) {
        await press(tester, LogicalKeyboardKey.arrowDown);
      }
      expect(focused(), 'Town 12');
      expect(shown(tester, 'Town 12'), isTrue);
    });
  });

  group("a multi-select (ui_core's tag input)", () {
    const colours = [
      ExpressiveSelectOption('red', 'Red'),
      ExpressiveSelectOption('green', 'Green'),
      ExpressiveSelectOption('blue', 'Blue', enabled: false),
      ExpressiveSelectOption('black', 'Black'),
    ];
    const rows = ['Red', 'Green', 'Blue', 'Black'];

    Widget multi(List<String> values, ValueChanged<List<String>> changed) =>
        SizedBox(
          width: 320,
          child: StatefulBuilder(
            builder: (context, update) => ExpressiveMultiSelect<String>(
              label: 'Colours',
              options: colours,
              values: values,
              onChanged: (next) {
                changed(next);
                update(() => values = next);
              },
            ),
          ),
        );

    List<String> listed() => [
      for (final row in rows)
        if (find
            .descendant(
              of: find.byType(ExpressivePopoverSurface),
              matching: find.text(row),
            )
            .evaluate()
            .isNotEmpty)
          row,
    ];

    testWidgets('it offers every option, a disabled one dimmed; the keys go '
        'round the ends and pass over it; on a closed list Down only opens '
        'it', (tester) async {
      keyboard();
      var chosen = <String>[];
      await tester.pumpWidget(host(multi(const [], (v) => chosen = v)));
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(listed(), rows);
      expect(statesOf('Blue'), contains(WidgetState.disabled));
      expect(litOne(rows), 'Red', reason: 'it opens on the first');
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(litOne(rows), 'Black', reason: 'Up at the first goes round');
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(litOne(rows), 'Green', reason: 'past the disabled Blue');
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(litOne(rows), 'Red', reason: 'Down at the last goes round');
      await press(tester, LogicalKeyboardKey.escape);
      expect(listed(), isEmpty);
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(listed(), rows);
      expect(litOne(rows), 'Red', reason: 'Down only opens it');
      await press(tester, LogicalKeyboardKey.arrowDown);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(chosen, ['green']);
    });

    testWidgets('a disabled option is never taken; typed words filter', (
      tester,
    ) async {
      keyboard();
      var chosen = <String>[];
      await tester.pumpWidget(host(multi(const [], (v) => chosen = v)));
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Blue'));
      await tester.pumpAndSettle();
      expect(chosen, isEmpty);
      await tester.enterText(find.byType(EditableText), 'bl');
      await tester.pumpAndSettle();
      expect(listed(), ['Blue', 'Black']);
      expect(litOne(rows), 'Black');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(chosen, ['black']);
    });

    testWidgets('with a search: a spinner row while it runs, its finds as '
        'options, and a failure says so with a Try again the keys reach', (
      tester,
    ) async {
      keyboard();
      var runs = 0;
      var chosen = <String>[];
      final pending = <Completer<Iterable<ExpressiveSelectOption<String>>>>[];
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 320,
            child: StatefulBuilder(
              builder: (context, update) => ExpressiveMultiSelect<String>(
                label: 'Colours',
                options: const [],
                values: chosen,
                debounceDuration: const Duration(milliseconds: 300),
                search: (query) {
                  runs++;
                  final c =
                      Completer<Iterable<ExpressiveSelectOption<String>>>();
                  pending.add(c);
                  return c.future;
                },
                onChanged: (next) => update(() => chosen = next),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'bl');
      await tester.pump();
      expect(find.text('Loading'), findsOneWidget, reason: 'while it rests');
      expect(find.byType(ExpressiveCircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(runs, 1, reason: 'one search per pause');

      pending.removeLast().completeError(StateError('offline'));
      await tester.pump();
      await tester.pump();
      expect(find.text("Couldn't load results"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(lit('Try again'), isTrue, reason: 'Down reaches it');
      // The spinner turns while the search runs: pumped, not settled.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 300));
      expect(runs, 2, reason: 'Enter on it searches again');

      pending.removeLast().complete(const [
        ExpressiveSelectOption('blue', 'Blue'),
        ExpressiveSelectOption('black', 'Black'),
      ]);
      await tester.pump();
      await tester.pump();
      expect(runs, 2, reason: 'no search after the retry');
      expect(find.byType(ExpressiveCircularProgressIndicator), findsNothing);
      await tester.pumpAndSettle();
      expect(listed(), ['Blue', 'Black']);
      await tester.tap(find.text('Black'));
      await tester.pump();
      expect(chosen, ['black']);
      // Choosing clears the words, which searches again: answered, settled.
      await tester.pump(const Duration(milliseconds: 300));
      for (final search in pending) {
        search.complete(const []);
      }
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(ExpressiveChip),
          matching: find.text('Black'),
        ),
        findsOneWidget,
        reason: 'the chip takes the found option\'s label',
      );
    });
  });

  testWidgets("a menu bar's menu: a typed letter goes to the next item it "
      'starts', (tester) async {
    keyboard();
    await tester.pumpWidget(
      host(
        ExpressiveMenuBar(
          menus: [
            ExpressiveMenuBarEntry(
              'File',
              children: [
                ExpressiveMenuBarEntry('New', onPressed: () {}),
                ExpressiveMenuBarEntry('Open', onPressed: () {}),
                ExpressiveMenuBarEntry('Save', onPressed: () {}),
                ExpressiveMenuBarEntry('Share', onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    );
    await press(tester, LogicalKeyboardKey.tab);
    expect(lit('File'), isTrue);
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(lit('New'), isTrue);
    await press(tester, LogicalKeyboardKey.keyS);
    expect(lit('Save'), isTrue);
    // Letters typed in a run (700 ms) spell the start; after a pause the
    // same letter steps on.
    Future<void> pause() => tester.pump(const Duration(seconds: 1));
    await pause();
    await press(tester, LogicalKeyboardKey.keyS);
    expect(lit('Share'), isTrue, reason: 'the same letter steps on');
    await pause();
    await press(tester, LogicalKeyboardKey.keyO);
    expect(lit('Open'), isTrue);
    await press(tester, LogicalKeyboardKey.keyP);
    expect(lit('Open'), isTrue, reason: '"op" still fits it');
  });
  group('one lit row', () {
    const rows = ['Rename', 'Duplicate', 'Delete'];

    /// How [words]'s row is lit: 'plate' (the pointer's hover layer), 'ring'
    /// (the keys' focus indicator), or null.
    String? light(String words) {
      final pressable = find.ancestor(
        of: find.text(words),
        matching: find.byType(ExpressivePressable),
      );
      if (pressable.evaluate().isNotEmpty) {
        final p = pressable.evaluate().first.widget as ExpressivePressable;
        if (p.focusRing) return 'ring';
        return p.color.a > 0 ? 'plate' : null;
      }
      final states = statesOf(words);
      if (states.contains(WidgetState.focused)) return 'ring';
      if (states.contains(WidgetState.hovered)) return 'plate';
      return null;
    }

    /// The lit rows among [shown], each with its light.
    Map<String, String> lights(List<String> shown) => {
      for (final row in shown)
        if (find.text(row).evaluate().isNotEmpty && light(row) != null)
          row: light(row)!,
    };

    Widget overflow() => ExpressiveMenu(
      label: 'More',
      entries: [
        for (final row in rows) ExpressiveMenuItem(row, onPressed: () {}),
      ],
      child: const SizedBox(width: 48, height: 48),
    );

    Future<TestGesture> mouse(WidgetTester tester, Offset at) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: at);
      addTearDown(gesture.removePointer);
      return gesture;
    }

    Future<void> click(TestGesture mouse, Offset at) async {
      await mouse.moveTo(at);
      await mouse.down(at);
      await mouse.up();
    }

    testWidgets('a menu the pointer opened lights none; the pointer moving '
        'lights its row, the keys go on from it', (tester) async {
      await tester.pumpWidget(host(overflow()));
      final anchor = tester.getCenter(find.bySemanticsLabel('More'));
      final pointer = await mouse(tester, anchor);
      await click(pointer, anchor);
      await tester.pumpAndSettle();
      expect(lights(rows), isEmpty);

      await pointer.moveTo(tester.getCenter(find.text('Duplicate')));
      await tester.pumpAndSettle();
      expect(lights(rows), {'Duplicate': 'plate'});
      expect(focused(), 'Duplicate', reason: 'the keys go on from it');

      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(lights(rows), {
        'Delete': 'ring',
      }, reason: 'the pointer resting on Duplicate lights it no more');

      await pointer.moveTo(tester.getCenter(find.text('Rename')));
      await tester.pumpAndSettle();
      expect(lights(rows), {'Rename': 'plate'});
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(lights(rows), {'Delete': 'ring'}, reason: 'Up from the first');
    });

    testWidgets("an open menu's rows tell a screen reader their boxes as "
        'drawn, not as the open animation began', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(overflow()));
      await tester.tap(find.bySemanticsLabel('More'));
      await tester.pumpAndSettle();
      for (final row in rows) {
        final node = tester.getSemantics(find.text(row));
        // In the view's physical pixels, through every node's transform.
        var box = node.rect;
        for (SemanticsNode? n = node; n != null; n = n.parent) {
          final transform = n.transform;
          if (transform != null) {
            box = MatrixUtils.transformRect(transform, box);
          }
        }
        final dpr = tester.view.devicePixelRatio;
        box = Rect.fromLTRB(
          box.left / dpr,
          box.top / dpr,
          box.right / dpr,
          box.bottom / dpr,
        );
        final drawn = tester.getRect(
          find
              .ancestor(
                of: find.text(row),
                matching: find.byType(ExpressivePressable),
              )
              .first,
        );
        expect(box.center.dx, moreOrLessEquals(drawn.center.dx, epsilon: 1));
        expect(box.center.dy, moreOrLessEquals(drawn.center.dy, epsilon: 1));
        expect(box.height, moreOrLessEquals(drawn.height, epsilon: 1));
      }
      semantics.dispose();
    });

    Widget split() => ExpressiveSplitButton(
      'Send',
      onPressed: () {},
      menuLabel: 'Send options',
      menu: (context, close) => ExpressiveMenuSurface(
        groups: [
          ExpressiveMenuGroup([
            for (final row in rows) ExpressiveMenuItem(row, onPressed: close),
          ]),
        ],
      ),
    );

    testWidgets("a split button's menu a key opened: its first row lit, the "
        'arrows walk it, Escape gives the chevron the focus back', (
      tester,
    ) async {
      await tester.pumpWidget(host(split()));
      await press(tester, LogicalKeyboardKey.tab);
      await press(tester, LogicalKeyboardKey.tab);
      await press(tester, LogicalKeyboardKey.enter);
      expect(lights(rows), {'Rename': 'ring'});
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(lights(rows), {'Duplicate': 'ring'});
      await press(tester, LogicalKeyboardKey.arrowUp);
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(lights(rows), {'Delete': 'ring'}, reason: 'Up goes round');
      await press(tester, LogicalKeyboardKey.home);
      expect(lights(rows), {'Rename': 'ring'});
      await press(tester, LogicalKeyboardKey.escape);
      expect(find.text('Rename'), findsNothing);
      await press(tester, LogicalKeyboardKey.enter);
      expect(lights(rows), {'Rename': 'ring'}, reason: 'the chevron again');
    });

    testWidgets("a split button's menu the pointer opened lights none; the "
        "keys go on from the pointer's row", (tester) async {
      await tester.pumpWidget(host(split()));
      final chevron = tester.getCenter(find.bySemanticsLabel('Send options'));
      final pointer = await mouse(tester, chevron);
      await click(pointer, chevron);
      await tester.pumpAndSettle();
      expect(lights(rows), isEmpty);
      await pointer.moveTo(tester.getCenter(find.text('Duplicate')));
      await tester.pumpAndSettle();
      expect(lights(rows), {'Duplicate': 'plate'});
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(lights(rows), {'Delete': 'ring'});
      await pointer.moveTo(tester.getCenter(find.text('Rename')));
      await tester.pumpAndSettle();
      expect(lights(rows), {'Rename': 'plate'});
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(lights(rows), {'Duplicate': 'ring'});
    });

    testWidgets('a menu showExpressiveMenu opened from a button the pointer '
        'pressed: Escape gives the button the focus, Enter opens it again', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ExpressiveFilledButton(
              'Add',
              onPressed: () => showExpressiveMenu(
                context,
                entries: [
                  for (final row in rows)
                    ExpressiveMenuItem(row, onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      );
      final button = tester.getCenter(find.text('Add'));
      final pointer = await mouse(tester, button);
      await click(pointer, button);
      await tester.pumpAndSettle();
      expect(lights(rows), isEmpty);
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(lights(rows), {'Rename': 'ring'});
      await press(tester, LogicalKeyboardKey.escape);
      expect(find.text('Rename'), findsNothing);
      await press(tester, LogicalKeyboardKey.enter);
      expect(lights(rows), {'Rename': 'ring'}, reason: 'the button again');
    });

    const items = ['Booking', 'List', 'Guide'];

    /// The lit items of an open FAB menu, each with its light: the keys'
    /// ring, or the pointer's fill (the colour the others do not share).
    Map<String, String> fabLights(WidgetTester tester) {
      final faces = {
        for (final item in items)
          item: tester.widget<ExpressivePressable>(
            find
                .ancestor(
                  of: find.text(item),
                  matching: find.byType(ExpressivePressable),
                )
                .first,
          ),
      };
      final colours = [for (final face in faces.values) face.color];
      final rest = colours.firstWhere(
        (c) => colours.where((d) => d == c).length > 1,
      );
      return {
        for (final MapEntry(key: item, value: face) in faces.entries)
          if (face.focusRing)
            item: 'ring'
          else if (face.color != rest)
            item: 'plate',
      };
    }

    testWidgets("a FAB menu lights one item: the pointer's, the keys going "
        'on from it; Escape gives the toggle the focus back', (tester) async {
      keyboard();
      final changes = <bool>[];
      await tester.pumpWidget(
        host(
          ExpressiveHeroMoment(
            child: ExpressiveFabMenu(
              icon: ExpressiveSymbols.add,
              semanticLabel: 'Add',
              onExpandedChanged: changes.add,
              items: [
                for (final item in items)
                  ExpressiveFabMenuItem(
                    icon: ExpressiveSymbols.edit,
                    label: item,
                    onPressed: (_) {},
                  ),
              ],
            ),
          ),
        ),
      );
      await press(tester, LogicalKeyboardKey.tab);
      await press(tester, LogicalKeyboardKey.enter);
      expect(changes, [true]);
      expect(fabLights(tester), isEmpty, reason: 'the toggle holds the keys');
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(fabLights(tester), {'Booking': 'ring'});

      final pointer = await mouse(tester, Offset.zero);
      await pointer.moveTo(tester.getCenter(find.text('Guide')));
      await tester.pumpAndSettle();
      expect(fabLights(tester), {
        'Guide': 'plate',
      }, reason: 'the pointer moves the lit item, and the focus with it');

      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(fabLights(tester), {
        'List': 'ring',
      }, reason: 'on from Guide; the pointer resting there lights it no more');

      await press(tester, LogicalKeyboardKey.escape);
      expect(changes, [true, false]);
      await press(tester, LogicalKeyboardKey.enter);
      expect(changes, [true, false, true], reason: 'the toggle had the focus');
    });

    testWidgets('a menu a key opened lights its first row', (tester) async {
      await tester.pumpWidget(host(overflow()));
      await press(tester, LogicalKeyboardKey.tab);
      await press(tester, LogicalKeyboardKey.enter);
      expect(lights(rows), {'Rename': 'ring'});
    });

    testWidgets('a menu laid out under a resting pointer lights nothing '
        'until it moves, and takes no focus', (tester) async {
      Widget surface() => ExpressiveMenuSurface(
        groups: [
          ExpressiveMenuGroup([
            for (final row in rows) ExpressiveMenuItem(row, onPressed: () {}),
          ]),
        ],
      );
      await tester.pumpWidget(host(surface()));
      final at = tester.getCenter(find.text('Duplicate'));
      await tester.pumpWidget(host(const SizedBox()));
      final pointer = await mouse(tester, at);
      await tester.pumpWidget(host(surface()));
      await tester.pumpAndSettle();
      expect(lights(rows), isEmpty);
      await pointer.moveTo(at + const Offset(2, 0));
      await tester.pumpAndSettle();
      expect(lights(rows), {'Duplicate': 'plate'});
      expect(focused(), isNull, reason: 'a page keeps its focus');

      // With the keys in it, the pointer takes them along.
      await press(tester, LogicalKeyboardKey.tab);
      expect(lights(rows), {'Rename': 'ring'});
      await pointer.moveTo(tester.getCenter(find.text('Delete')));
      await tester.pumpAndSettle();
      expect(lights(rows), {'Delete': 'plate'});
      expect(focused(), 'Delete');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await press(tester, LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(lights(rows), {'Duplicate': 'ring'});
    });

    Widget bar() => ExpressiveMenuBar(
      menus: [
        ExpressiveMenuBarEntry(
          'File',
          children: [
            ExpressiveMenuBarEntry('New', onPressed: () {}),
            ExpressiveMenuBarEntry('Open', onPressed: () {}),
            const ExpressiveMenuBarEntry.divider(),
            ExpressiveMenuBarEntry('Close', onPressed: () {}),
          ],
        ),
      ],
    );
    const file = ['New', 'Open', 'Close'];

    testWidgets("a menu bar's menu the pointer opened lights none; Down "
        'lights the first, the pointer its own row', (tester) async {
      await tester.pumpWidget(host(bar()));
      final title = tester.getCenter(find.text('File'));
      final pointer = await mouse(tester, title);
      await click(pointer, title);
      await tester.pumpAndSettle();
      expect(lights(file), isEmpty);

      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(lights(file), {'New': 'ring'});

      await pointer.moveTo(tester.getCenter(find.text('Close')));
      await tester.pumpAndSettle();
      expect(lights(file), {'Close': 'plate'});

      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(lights(file), {'New': 'ring'}, reason: 'on from Close, round');
    });

    testWidgets("a menu bar's menu the pointer opened: Up lights the last", (
      tester,
    ) async {
      await tester.pumpWidget(host(bar()));
      final title = tester.getCenter(find.text('File'));
      final pointer = await mouse(tester, title);
      await click(pointer, title);
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(lights(file), {'Close': 'ring'});
    });

    testWidgets("a menu's rows stand 4dp clear of its container on every "
        'side, at the densest density too', (tester) async {
      final compact = bloom.copyWith(density: ExpressiveDensity.compact);
      await tester.pumpWidget(host(bar(), theme: compact));
      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();
      final panel = tester.getRect(
        find.ancestor(
          of: find.text('New'),
          matching: find.byType(ExpressivePopoverSurface),
        ),
      );
      Rect face(String words) => tester.getRect(
        find
            .ancestor(
              of: find.text(words),
              matching: find.byType(ExpressiveStateFace),
            )
            .first,
      );
      expect(face('New').top - panel.top, 4);
      expect(panel.bottom - face('Close').bottom, 4);
      expect(face('New').left - panel.left, 4);
      expect(panel.right - face('New').right, 4);

      await press(tester, LogicalKeyboardKey.escape);
      await tester.pumpWidget(host(overflow(), theme: compact));
      await tester.tap(find.bySemanticsLabel('More'));
      await tester.pumpAndSettle();
      // The group's container: the largest surface round its first item.
      final group = find
          .ancestor(
            of: find.text('Rename'),
            matching: find.byType(ExpressiveSurface),
          )
          .evaluate()
          .map((e) {
            final box = e.renderObject! as RenderBox;
            return box.localToGlobal(Offset.zero) & box.size;
          })
          .reduce((a, b) => a.height >= b.height ? a : b);
      Rect item(String words) => tester.getRect(
        find
            .ancestor(
              of: find.text(words),
              matching: find.byType(ExpressivePressable),
            )
            .first,
      );
      expect(item('Rename').top - group.top, 4);
      expect(group.bottom - item('Delete').bottom, 4);
      expect(item('Rename').left - group.left, 4);
      expect(group.right - item('Rename').right, 4);
    });
  });
}
