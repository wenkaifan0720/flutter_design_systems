// The keys of Fluent 2's combobox and multi-select lists (ui_core's RawCombobox and RawTagInput under Fluent's
// faces): a combobox opened with its chosen value's own words lists every option, the chosen one marked, until the
// words are edited; Down or Up on a closed list opens it without moving, on the chosen option, else the first in use;
// the arrows go round the list, past an option out of use, which neither the keyboard nor a press takes; Escape
// closes it, the focus staying on the field. A multi-select's list starts on its first option in use, each time it
// opens. A choice is made the way a keyboard's Enter reaches a field, as the text input's done action.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/src/fluent2_design/components/input/field_core.dart'
    show Fluent2OptionFace;

const _options = [
  Fluent2Option('equipment', 'Equipment'),
  Fluent2Option('access', 'Access'),
  Fluent2Option('archive', 'Archive', enabled: false),
  Fluent2Option('room', 'Room booking'),
];

Iterable<Fluent2OptionFace> _faces(WidgetTester t) =>
    t.widgetList<Fluent2OptionFace>(find.byType(Fluent2OptionFace));

/// The words of the options the list shows.
List<String> _shown(WidgetTester t) => [for (final f in _faces(t)) f.label];

/// The words of the option the keyboard's highlight is on, or null.
String? _lit(WidgetTester t) {
  final lit = [
    for (final f in _faces(t))
      if (f.highlighted) f.label,
  ];
  expect(lit.length, lessThanOrEqualTo(1), reason: 'one highlight at most');
  return lit.isEmpty ? null : lit.single;
}

Future<void> _key(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyEvent(key);
  await t.pumpAndSettle();
}

/// Chooses the active option as a keyboard's Enter does in a text field.
Future<void> _done(WidgetTester t) async {
  await t.testTextInput.receiveAction(TextInputAction.done);
  await t.pumpAndSettle();
}

Future<void> _stage(WidgetTester t, Widget body) async {
  t.view.physicalSize = const Size(1440, 900);
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

/// A combobox of [_options] holding [value]; [chosen] hears each choice.
Future<FocusNode> _combobox(
  WidgetTester t, {
  String? value,
  ValueChanged<String>? chosen,
}) async {
  final field = FocusNode(debugLabel: 'combobox');
  addTearDown(field.dispose);
  var v = value;
  await _stage(
    t,
    StatefulBuilder(
      builder: (context, set) => Fluent2Combobox<String>(
        semanticLabel: 'Type',
        value: v,
        options: _options,
        focusNode: field,
        onChanged: (x) {
          chosen?.call(x);
          set(() => v = x);
        },
      ),
    ),
  );
  return field;
}

/// Puts the focus on [field] and closes the list that opens with it.
Future<void> _focusClosed(WidgetTester t, FocusNode field) async {
  field.requestFocus();
  await t.pumpAndSettle();
  if (_faces(t).isNotEmpty) await _key(t, LogicalKeyboardKey.escape);
  expect(_faces(t), isEmpty, reason: 'the list is closed');
  expect(field.hasFocus, isTrue);
}

void main() {
  testWidgets('a combobox with a chosen value opens onto every option, '
      'the chosen one marked and active, ringed only once a key is used', (
    t,
  ) async {
    await _combobox(t, value: 'access');
    await t.tap(find.byIcon(Fluent2Icons.chevronDown));
    await t.pumpAndSettle();
    expect(_shown(t), ['Equipment', 'Access', 'Archive', 'Room booking']);
    expect(
      [
        for (final f in _faces(t))
          if (f.selected) f.label,
      ],
      ['Access'],
    );
    expect(
      [
        for (final f in _faces(t))
          if (f.states.contains(WidgetState.focused)) f.label,
      ],
      ['Access'],
      reason: 'the active option, the one Enter takes',
    );
    expect(_lit(t), isNull, reason: 'opened by a pointer: no ring');
    expect(
      [
        for (final f in _faces(t))
          if (f.states.contains(WidgetState.disabled)) f.label,
      ],
      ['Archive'],
      reason: 'drawn out of use',
    );
    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_lit(t), 'Room booking', reason: 'a key shows the ring');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets("a combobox's closed list: Down opens it on the chosen option "
      'without moving; the arrows wrap past an option out of use', (t) async {
    final picks = <String>[];
    final field = await _combobox(t, value: 'access', chosen: picks.add);
    await _focusClosed(t, field);
    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_shown(t), hasLength(4), reason: 'every option');
    expect(_lit(t), 'Access', reason: 'opened on the chosen option');
    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_lit(t), 'Room booking', reason: 'past Archive, out of use');
    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_lit(t), 'Equipment', reason: 'Down wraps to the first');
    await _key(t, LogicalKeyboardKey.arrowUp);
    expect(_lit(t), 'Room booking', reason: 'Up wraps to the last');
    await _key(t, LogicalKeyboardKey.arrowUp);
    expect(_lit(t), 'Access', reason: 'past Archive, out of use');
    await _key(t, LogicalKeyboardKey.arrowDown);
    await _done(t);
    expect(picks, ['room']);
    expect(_faces(t), isEmpty, reason: 'it closes');
    expect(find.text('Room booking'), findsOneWidget, reason: 'its words');
    expect(field.hasFocus, isTrue);

    await _key(t, LogicalKeyboardKey.arrowUp);
    expect(_shown(t), hasLength(4), reason: 'every option again');
    expect(_lit(t), 'Room booking', reason: 'Up opens it on the new choice');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets("a combobox's list with nothing chosen opens on the first "
      'option; Escape closes it, the focus on the field', (t) async {
    final field = await _combobox(t);
    await _focusClosed(t, field);
    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_lit(t), 'Equipment');
    await _key(t, LogicalKeyboardKey.escape);
    expect(_faces(t), isEmpty, reason: 'it closes');
    expect(field.hasFocus, isTrue, reason: 'still on the field');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('an option out of use is not taken, by a press or the keys', (
    t,
  ) async {
    final picks = <String>[];
    final field = await _combobox(t, value: 'access', chosen: picks.add);
    await t.tap(find.byIcon(Fluent2Icons.chevronDown));
    await t.pumpAndSettle();
    await t.tap(find.text('Archive'), warnIfMissed: false);
    await t.pumpAndSettle();
    expect(picks, isEmpty);
    await t.enterText(find.byType(EditableText), 'arch');
    await t.pumpAndSettle();
    expect(_shown(t), ['Archive']);
    expect(_lit(t), isNull, reason: 'the highlight passes it over');
    await _done(t);
    expect(picks, isEmpty);
    expect(field.hasFocus, isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('edited words filter a combobox; Home and End stay with them', (
    t,
  ) async {
    final field = await _combobox(t, value: 'access');
    field.requestFocus();
    await t.pumpAndSettle();
    await t.enterText(find.byType(EditableText), 'ro');
    await t.pumpAndSettle();
    expect(_shown(t), ['Room booking']);
    await _key(t, LogicalKeyboardKey.home);
    final text = t.widget<EditableText>(find.byType(EditableText)).controller;
    expect((text.selection.isCollapsed, text.selection.baseOffset), (true, 0));
    await _key(t, LogicalKeyboardKey.end);
    expect((text.selection.isCollapsed, text.selection.baseOffset), (true, 2));
    expect(_shown(t), ['Room booking'], reason: 'the list stays filtered');
    // Windows', where Home and End move the caret (a Mac's scroll).
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets("a multi-select's list: its first option in use first, round "
      'the list past one out of use, the same when it opens again', (t) async {
    final field = FocusNode(debugLabel: 'multi-select');
    addTearDown(field.dispose);
    var chosen = <String>[];
    await _stage(
      t,
      StatefulBuilder(
        builder: (context, set) => Fluent2MultiSelect<String>(
          semanticLabel: 'Types',
          options: const [
            Fluent2Option('archive', 'Archive', enabled: false),
            ..._options,
          ],
          selected: chosen,
          focusNode: field,
          onChanged: (v) => set(() => chosen = v),
        ),
      ),
    );
    field.requestFocus();
    await t.pumpAndSettle();
    if (_faces(t).isEmpty) await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_lit(t), 'Equipment', reason: 'the first in use');
    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_lit(t), 'Access');
    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_lit(t), 'Room booking', reason: 'past Archive, out of use');
    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_lit(t), 'Equipment', reason: 'Down wraps past Archive');
    await _key(t, LogicalKeyboardKey.arrowUp);
    await _done(t);
    expect(chosen, ['room']);
    if (_faces(t).isEmpty) await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_lit(t), 'Equipment', reason: 'again from the first in use');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets("a comma naming a multi-select's option out of use adds "
      'nothing', (t) async {
    var chosen = <String>[];
    await _stage(
      t,
      StatefulBuilder(
        builder: (context, set) => Fluent2MultiSelect<String>(
          semanticLabel: 'Types',
          options: _options,
          selected: chosen,
          onChanged: (v) => set(() => chosen = v),
        ),
      ),
    );
    await t.enterText(find.byType(EditableText), 'Archive,');
    await t.pumpAndSettle();
    expect(chosen, isEmpty);
    await t.enterText(find.byType(EditableText), 'Access,');
    await t.pumpAndSettle();
    expect(chosen, ['access']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
