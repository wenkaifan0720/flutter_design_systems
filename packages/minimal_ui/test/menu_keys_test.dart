// A Minimal menu's keys are a menu button's, on every control that opens
// one: the select, the property, the property pill and the kit's menu button
// the apps' bars carry. Opened from a key (Enter, Space, Down) the menu
// starts on the chosen item, or the first enabled one when none is chosen;
// opened by the pointer it starts on none, and still takes the arrows at
// once. The arrows walk the enabled items round, Home and End go to the
// ends, a letter to the next item it starts, Enter takes the item and
// closes, Escape closes, and either hands the keys back to the control. The
// item with the keys is the one a screen reader hears focused, and the one
// on the muted fill: the pointer moves it too, so there is only ever one. The
// keyboard's item also wears the accent ring, inside its edge.
import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

const _labels = ['Every day', 'Weekdays', 'Weekends', 'Monthly', 'Custom…'];

// Not offered: the keys pass it by.
const _off = 'Weekends';

/// One kind of control that opens a menu: [build] draws it for the current
/// value, [trigger] finds it to tap, and [says] is how its announcement
/// starts.
typedef _Kind = ({
  String name,
  Widget Function(String? value, ValueChanged<String> onChanged) build,
  Finder Function() trigger,
  String says,
});

List<MinimalMenuItem> _items(String? value, ValueChanged<String> onChanged) => [
  for (final label in _labels)
    MinimalMenuItem(
      label,
      selected: label == value,
      onPressed: label == _off ? null : () => onChanged(label),
    ),
];

final List<_Kind> _kinds = [
  (
    name: 'select',
    build: (value, onChanged) => MinimalSelect<String>(
      labelText: 'Repeats',
      value: value,
      options: [
        for (final label in _labels)
          MinimalSelectOption(label, label, enabled: label != _off),
      ],
      onChanged: onChanged,
    ),
    trigger: () => find.text('Repeats').first,
    says: 'Repeats',
  ),
  (
    name: 'property pill',
    build: (value, onChanged) => MinimalPropertyPill(
      icon: Icons.repeat,
      label: value ?? 'Repeats',
      name: 'Repeats',
      hasValue: value != null,
      items: _items(value, onChanged),
    ),
    trigger: () => find.bySemanticsLabel(RegExp('^Repeats')).first,
    says: 'Repeats',
  ),
  (
    name: 'property',
    build: (value, onChanged) => MinimalProperty(
      icon: Icons.repeat,
      label: 'Repeats',
      value: value,
      items: _items(value, onChanged),
    ),
    trigger: () => find.bySemanticsLabel(RegExp('^Repeats')).first,
    says: 'Repeats',
  ),
  (
    name: "an app bar's menu button",
    build: (value, onChanged) => MinimalMenu.button(
      Icons.filter_list,
      text: value ?? 'Any',
      label: 'Filter',
      items: _items(value, onChanged),
    ),
    trigger: () => find.bySemanticsLabel(RegExp('^Filter')).first,
    says: 'Filter',
  ),
];

/// The keys as a browser maps them: Enter is a button's press alone
/// ([ButtonActivateIntent]), not every control's ([ActivateIntent]).
final Map<ShortcutActivator, Intent> _webShortcuts = {
  ...WidgetsApp.defaultShortcuts,
  const SingleActivator(LogicalKeyboardKey.enter): const ButtonActivateIntent(),
  const SingleActivator(LogicalKeyboardKey.numpadEnter):
      const ButtonActivateIntent(),
};

/// The kind's control on a page, holding its value; [chosen] logs each
/// choice. [web]: with a browser's keys.
Widget _page(
  _Kind kind,
  String? initial,
  List<String> chosen, {
  bool web = false,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  shortcuts: web ? _webShortcuts : null,
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    // At the top, as a form's first row: the menu opens below it, with room.
    body: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 320,
            child: StatefulBuilder(
              builder: (context, setState) => kind.build(
                chosen.isEmpty ? initial : chosen.last,
                (v) => setState(() => chosen.add(v)),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);

/// The labels of the nodes a screen reader hears as focused.
List<String> _focused() => [
  for (final node
      in find.semantics
          .byPredicate(
            (node) => node.flagsCollection.isFocused == Tristate.isTrue,
          )
          .evaluate())
    node.label,
];

/// The open menu's items on the muted fill.
List<String> _filled(WidgetTester tester, MinimalThemeData t) => [
  for (final label in _labels)
    if (_fill(tester, label) == t.muted) label,
];

Color? _fill(WidgetTester tester, String label) {
  final row = find.ancestor(
    of: find.text(label).last,
    matching: find.byWidgetPredicate(
      (w) => w is Container && w.decoration != null,
    ),
  );
  return switch (tester.widget<Container>(row.first).decoration) {
    BoxDecoration(:final color) => color,
    ShapeDecoration(:final color) => color,
    _ => null,
  };
}

/// The item with the keys: focused for a screen reader, and the one item
/// on the muted fill.
void _expectPlace(
  WidgetTester tester,
  MinimalThemeData t,
  String label,
  String why,
) {
  expect(_focused(), [label], reason: '$why: focused');
  expect(_filled(tester, t), [label], reason: '$why: filled');
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

// Never chosen, so never on the control: on screen only while the menu is.
bool _open() => find.text(_off).evaluate().isNotEmpty;

/// The control the menu opened from has the keys: the one node a screen
/// reader hears focused.
void _expectControlFocused(_Kind kind, String why) =>
    expect(_focused(), [startsWith(kind.says)], reason: why);

void main() {
  final t = MinimalThemeData.preset('standard', Brightness.light);

  for (final kind in _kinds) {
    group(kind.name, () {
      testWidgets('opened by Enter, it starts on the chosen item and walks '
          'the enabled ones round', (tester) async {
        final handle = tester.ensureSemantics();
        final chosen = <String>[];
        await tester.pumpWidget(_page(kind, 'Weekdays', chosen));
        await _key(tester, LogicalKeyboardKey.tab);
        _expectControlFocused(kind, 'Tab gives the control the keys');
        await _key(tester, LogicalKeyboardKey.enter);
        expect(_open(), isTrue);
        _expectPlace(tester, t, 'Weekdays', 'opened on the chosen item');

        // Down passes the item that is not offered by.
        await _key(tester, LogicalKeyboardKey.arrowDown);
        _expectPlace(tester, t, 'Monthly', 'down');
        await _key(tester, LogicalKeyboardKey.arrowDown);
        _expectPlace(tester, t, 'Custom…', 'down');
        await _key(tester, LogicalKeyboardKey.arrowDown);
        _expectPlace(tester, t, 'Every day', 'down, round the end');
        await _key(tester, LogicalKeyboardKey.arrowUp);
        _expectPlace(tester, t, 'Custom…', 'up, round the start');
        await _key(tester, LogicalKeyboardKey.home);
        _expectPlace(tester, t, 'Every day', 'Home');
        await _key(tester, LogicalKeyboardKey.end);
        _expectPlace(tester, t, 'Custom…', 'End');
        // A letter: the next item it starts, never one not offered.
        await _key(tester, LogicalKeyboardKey.keyW);
        _expectPlace(tester, t, 'Weekdays', 'w');
        await _key(tester, LogicalKeyboardKey.keyW);
        _expectPlace(tester, t, 'Weekdays', 'w again: Weekends is not offered');
        await _key(tester, LogicalKeyboardKey.keyM);
        _expectPlace(tester, t, 'Monthly', 'm');

        // Enter takes it and closes; the keys go back to the control.
        await _key(tester, LogicalKeyboardKey.enter);
        expect(_open(), isFalse);
        expect(chosen, ['Monthly']);
        _expectControlFocused(kind, 'the control has the keys again');
        handle.dispose();
      });

      testWidgets('Space and Down open it too; Escape closes it and gives '
          'the control the keys', (tester) async {
        final handle = tester.ensureSemantics();
        final chosen = <String>[];
        await tester.pumpWidget(_page(kind, 'Monthly', chosen));
        await _key(tester, LogicalKeyboardKey.tab);
        for (final key in [
          LogicalKeyboardKey.space,
          LogicalKeyboardKey.arrowDown,
        ]) {
          await _key(tester, key);
          expect(_open(), isTrue, reason: '$key opens it');
          _expectPlace(tester, t, 'Monthly', '$key: on the chosen item');
          await _key(tester, LogicalKeyboardKey.escape);
          expect(_open(), isFalse, reason: 'Escape closes it');
          expect(chosen, isEmpty);
          _expectControlFocused(
            kind,
            'after Escape the control has the keys again',
          );
        }
        handle.dispose();
      });

      testWidgets('in a browser, where Enter is a press only a button '
          'takes, Enter opens it on the chosen item and takes an item', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        final chosen = <String>[];
        await tester.pumpWidget(_page(kind, 'Weekdays', chosen, web: true));
        await _key(tester, LogicalKeyboardKey.tab);
        await _key(tester, LogicalKeyboardKey.enter);
        expect(_open(), isTrue, reason: 'Enter opens it');
        _expectPlace(tester, t, 'Weekdays', 'opened on the chosen item');
        await _key(tester, LogicalKeyboardKey.arrowDown);
        await _key(tester, LogicalKeyboardKey.enter);
        expect(_open(), isFalse, reason: 'Enter takes the item');
        expect(chosen, ['Monthly']);
        _expectControlFocused(kind, 'the control has the keys again');
        handle.dispose();
      });

      testWidgets('with nothing chosen, a key opens it on the first enabled '
          'item', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_page(kind, null, <String>[]));
        await _key(tester, LogicalKeyboardKey.tab);
        await _key(tester, LogicalKeyboardKey.enter);
        _expectPlace(tester, t, 'Every day', 'the first item');
        await _key(tester, LogicalKeyboardKey.arrowUp);
        _expectPlace(tester, t, 'Custom…', 'up, round the start');
        handle.dispose();
      });

      testWidgets('opened by the pointer, it starts on none and takes the '
          'arrows at once; the pointer moves the one place', (tester) async {
        final handle = tester.ensureSemantics();
        final chosen = <String>[];
        await tester.pumpWidget(_page(kind, 'Weekdays', chosen));
        await tester.tap(kind.trigger());
        await tester.pumpAndSettle();
        expect(_open(), isTrue);
        expect(_focused(), isEmpty, reason: 'nothing changes at rest');
        expect(_filled(tester, t), isEmpty, reason: 'nothing changes at rest');

        await _key(tester, LogicalKeyboardKey.arrowDown);
        _expectPlace(tester, t, 'Weekdays', 'the first arrow');
        await _key(tester, LogicalKeyboardKey.arrowDown);
        _expectPlace(tester, t, 'Monthly', 'down');

        // The pointer takes the place to its item, and the keys go on from
        // there; one item is ever on the fill.
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(tester.getCenter(find.text('Every day').last));
        await tester.pumpAndSettle();
        _expectPlace(tester, t, 'Every day', 'under the pointer');
        await _key(tester, LogicalKeyboardKey.arrowDown);
        _expectPlace(tester, t, 'Weekdays', 'down from the pointer');
        // The pointer moving again takes the place back; on the item not
        // offered, or off the items, there is none.
        await mouse.moveTo(tester.getCenter(find.text('Custom…').last));
        await tester.pumpAndSettle();
        _expectPlace(tester, t, 'Custom…', 'the pointer again');
        await mouse.moveTo(tester.getCenter(find.text(_off).last));
        await tester.pumpAndSettle();
        expect(_focused(), isEmpty, reason: 'on the item not offered');
        expect(_filled(tester, t), isEmpty, reason: 'on the item not offered');
        await mouse.moveTo(const Offset(790, 590));
        await tester.pumpAndSettle();
        expect(_filled(tester, t), isEmpty, reason: 'the pointer gone');

        await _key(tester, LogicalKeyboardKey.end);
        await _key(tester, LogicalKeyboardKey.enter);
        expect(chosen, ['Custom…']);
        expect(_open(), isFalse);
        handle.dispose();
      });
    });
  }

  testWidgets('a menu of actions with none chosen starts on its first '
      'enabled item, its ring inside its edge', (tester) async {
    final handle = tester.ensureSemantics();
    final ran = <String>[];
    await tester.pumpWidget(
      _page(
        (
          name: 'actions',
          build: (value, onChanged) => MinimalMenu.button(
            Icons.more_horiz,
            label: 'Actions',
            items: [
              const MinimalMenuItem('Rename'),
              MinimalMenuItem('Duplicate', onPressed: () => ran.add('dup')),
              MinimalMenuItem(
                'Delete',
                isDestructiveAction: true,
                startsGroup: true,
                onPressed: () => ran.add('delete'),
              ),
            ],
          ),
          trigger: () => find.bySemanticsLabel(RegExp('^Actions')).first,
          says: 'Actions',
        ),
        null,
        <String>[],
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(_focused(), ['Duplicate']);
    expect(
      tester.getSemantics(find.text('Duplicate')).flagsCollection.isSelected,
      isNot(Tristate.isTrue),
      reason: 'a place is not a choice',
    );
    // The row's fill is the keyboard's place, and the accent ring stands
    // inside its edge, so it fits between the items above and below.
    final item = find.ancestor(
      of: find.text('Duplicate'),
      matching: find.byType(MinimalPressable),
    );
    // A paint's colour comes back in single precision: compare it as 8-bit
    // ARGB.
    bool noRing(Symbol method, List<dynamic> args) =>
        !args.any((a) => a is Paint && a.color.toARGB32() == t.ring.toARGB32());
    final bounds = Offset.zero & tester.getSize(item.first);
    var rings = 0;
    bool inside(Symbol method, List<dynamic> args) {
      if (noRing(method, args)) return true;
      rings++;
      final outer = args.first;
      return method == #drawDRRect &&
          outer is RRect &&
          outer.outerRect == bounds;
    }

    expect(tester.renderObject(item.first), paints..everything(inside));
    expect(rings, 1, reason: 'one ring round the keyboard\'s place');
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), ['Delete']);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(ran, ['delete']);
    // Back on the control, the keyboard's ring is the control's own.
    expect(
      tester.renderObject(
        find
            .ancestor(
              of: find.byIcon(Icons.more_horiz),
              matching: find.byType(MinimalPressable),
            )
            .first,
      ),
      isNot(paints..everything(noRing)),
    );
    handle.dispose();
  });
}
