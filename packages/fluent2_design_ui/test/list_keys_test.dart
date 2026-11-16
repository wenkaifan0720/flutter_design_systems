// The keys of Fluent 2's open lists: a select's popover (a desktop's) and its sheet (a phone's), a menu a control
// opens. (A combobox's and a tag picker's lists take ui_core's keys, DesignCombobox's and DesignTagInput's.) Opened
// from a key (Enter, Space or Down) the focus goes to the chosen option, else the first in use; Down and Up move at
// once and wrap round, past an option out of use; Home and End go to the ends; a typed letter goes to the next option
// it starts; Enter chooses and closes; Escape closes; either way the focus is back on the field. A list a pointer
// opened takes the arrows at once too.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

const _options = [
  Fluent2Option('equipment', 'Equipment'),
  Fluent2Option('access', 'Access'),
  Fluent2Option('archive', 'Archive', enabled: false),
  Fluent2Option('room', 'Room booking'),
];

/// The words of the option or item the focus is on.
String? _focused() => FocusManager.instance.primaryFocus?.context
    ?.findAncestorWidgetOfExactType<Fluent2Pressable>()
    ?.label;

Future<void> _stage(WidgetTester t, Widget body, {double width = 1440}) async {
  t.view.physicalSize = Size(width, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) =>
          Fluent2Host(brightness: Brightness.light, child: navigator!),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 320, child: body),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> _key(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyEvent(key);
  await t.pumpAndSettle();
}

/// Types [letter] after a pause, so it starts a new search.
Future<void> _type(WidgetTester t, LogicalKeyboardKey letter) async {
  await t.pump(const Duration(seconds: 2));
  await _key(t, letter);
}

class _Select extends StatefulWidget {
  const _Select({required this.field, this.value});

  final FocusNode field;
  final String? value;

  @override
  State<_Select> createState() => _SelectState();
}

class _SelectState extends State<_Select> {
  late String? _value = widget.value;

  @override
  Widget build(BuildContext context) => Fluent2Select<String>(
    label: 'Type',
    value: _value,
    options: _options,
    focusNode: widget.field,
    onChanged: (v) => setState(() => _value = v),
  );
}

/// Walks the list from 'Access' (focused): wrap, Home, End, letters.
Future<void> _walk(WidgetTester t) async {
  expect(_focused(), 'Access');
  await _key(t, LogicalKeyboardKey.arrowDown);
  expect(_focused(), 'Room booking', reason: 'past Archive, out of use');
  await _key(t, LogicalKeyboardKey.arrowDown);
  expect(_focused(), 'Equipment', reason: 'Down wraps to the first');
  await _key(t, LogicalKeyboardKey.arrowUp);
  expect(_focused(), 'Room booking', reason: 'Up wraps to the last');
  await _key(t, LogicalKeyboardKey.home);
  expect(_focused(), 'Equipment');
  await _key(t, LogicalKeyboardKey.end);
  expect(_focused(), 'Room booking');
  await _type(t, LogicalKeyboardKey.keyA);
  expect(_focused(), 'Access', reason: 'a typed letter jumps');
  await _type(t, LogicalKeyboardKey.keyE);
  expect(_focused(), 'Equipment');
}

void main() {
  for (final (how, key) in [
    ('Enter', LogicalKeyboardKey.enter),
    ('Space', LogicalKeyboardKey.space),
    ('Down', LogicalKeyboardKey.arrowDown),
  ]) {
    testWidgets("a select's list opened by $how: the chosen option first, "
        'round the list, Enter chooses', (t) async {
      final field = FocusNode(debugLabel: 'field');
      addTearDown(field.dispose);
      await _stage(t, _Select(field: field, value: 'access'));
      field.requestFocus();
      await t.pumpAndSettle();
      await _key(t, key);
      expect(find.text('Room booking'), findsOneWidget, reason: 'it opens');
      await _walk(t);
      await _key(t, LogicalKeyboardKey.enter);
      expect(find.text('Room booking'), findsNothing, reason: 'it closes');
      expect(find.text('Equipment'), findsOneWidget, reason: 'chosen');
      expect(field.hasPrimaryFocus, isTrue, reason: 'back on the field');
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  }

  testWidgets("a select's list with nothing chosen: the first option first; "
      'Escape closes, the focus back on the field', (t) async {
    final field = FocusNode(debugLabel: 'field');
    addTearDown(field.dispose);
    await _stage(t, _Select(field: field));
    field.requestFocus();
    await t.pumpAndSettle();
    await _key(t, LogicalKeyboardKey.enter);
    expect(_focused(), 'Equipment');
    await _key(t, LogicalKeyboardKey.escape);
    expect(find.text('Room booking'), findsNothing);
    expect(field.hasPrimaryFocus, isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets("a select's list a pointer opened takes the arrows at once", (
    t,
  ) async {
    final field = FocusNode(debugLabel: 'field');
    addTearDown(field.dispose);
    await _stage(t, _Select(field: field, value: 'access'));
    await t.tap(find.text('Access'));
    await t.pumpAndSettle();
    await _walk(t);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets("a select's sheet on a phone takes the same keys", (t) async {
    final field = FocusNode(debugLabel: 'field');
    addTearDown(field.dispose);
    await _stage(t, _Select(field: field, value: 'access'), width: 390);
    field.requestFocus();
    await t.pumpAndSettle();
    await _key(t, LogicalKeyboardKey.enter);
    expect(find.text('Room booking'), findsOneWidget, reason: 'it opens');
    await _walk(t);
    await _key(t, LogicalKeyboardKey.enter);
    expect(find.text('Room booking'), findsNothing, reason: 'it closes');
    expect(find.text('Equipment'), findsOneWidget, reason: 'chosen');
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('a menu a control opens: its checked item first, round it, '
      'Escape back to the control', (t) async {
    final button = FocusNode(debugLabel: 'button');
    addTearDown(button.dispose);
    String? picked;
    await _stage(
      t,
      Builder(
        builder: (anchor) => Fluent2Button(
          'Sort',
          focusNode: button,
          onPressed: () async {
            picked = await Fluent2Menu.show<String>(
              anchor,
              items: const [
                Fluent2MenuItem('equipment', 'Equipment', checked: false),
                Fluent2MenuItem('access', 'Access', checked: true),
                Fluent2MenuItem(
                  'archive',
                  'Archive',
                  checked: false,
                  enabled: false,
                ),
                Fluent2MenuItem('room', 'Room booking', checked: false),
              ],
            );
          },
        ),
      ),
    );
    button.requestFocus();
    await t.pumpAndSettle();
    await _key(t, LogicalKeyboardKey.enter);
    await _walk(t);
    await _key(t, LogicalKeyboardKey.escape);
    expect(find.text('Room booking'), findsNothing, reason: 'it closes');
    expect(button.hasPrimaryFocus, isTrue, reason: 'back on the control');
    expect(picked, isNull);

    await _key(t, LogicalKeyboardKey.space);
    expect(_focused(), 'Access');
    await _key(t, LogicalKeyboardKey.arrowDown);
    await _key(t, LogicalKeyboardKey.enter);
    expect(picked, 'room');
    expect(button.hasPrimaryFocus, isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
