// A radio, a checkbox and a switch read as Flutter's do: checkables, not
// buttons, and so does a switch row. A KeycapRadioGroup is one Tab stop: Tab reaches it at its choice
// (its first open option when none is chosen), the next Tab leaves it, and
// the arrows choose the next or the previous, wrap, pass over an option
// that is off and run the other way right to left. A one-choice segmented
// button and a one-at-a-time toggle group are radio groups of their keys,
// and a radio keeps the focus node its caller gives it.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:ui' show CheckedState, SemanticsFlags, Tristate;

import 'package:material_ui/material_ui.dart'
    show Checkbox, Material, Radio, RadioGroup, Switch, SwitchListTile;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

import '../example/lib/kit_gallery/kit.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 1400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    kitApp(
      brightness: Brightness.light,
      home: Material(
        child: Directionality(
          textDirection: direction,
          child: Align(alignment: Alignment.topCenter, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SemanticsFlags _flags(WidgetTester tester, String label) => tester
    .getSemantics(find.bySemanticsLabel(label))
    .getSemanticsData()
    .flagsCollection;

// A focusable before the group, the group under [group], and one after.
Widget _between(FocusNode before, Widget group) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    KeycapButton(
      focusNode: before,
      onPressed: () {},
      child: const Text('Before'),
    ),
    SizedBox(key: const ValueKey('group'), width: 358, child: group),
    KeycapButton(onPressed: () {}, child: const Text('After')),
  ],
);

Future<void> _check(WidgetTester tester, FocusNode before) async =>
    (await const DesignRadioGroupCheck(look: 'Keycap').check(
      tester.element(find.byKey(const ValueKey('group'))),
      before: before,
      sendKeyEvent: tester.sendKeyEvent,
      pump: tester.pump,
    )).verify();

void main() {
  testWidgets("a radio, a checkbox and a switch read as Flutter's do", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _show(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioGroup<String>(
            groupValue: 'a',
            onChanged: (_) {},
            child: Semantics(
              label: 'Flutter radio',
              child: const Radio(value: 'a'),
            ),
          ),
          Semantics(
            label: 'Flutter checkbox',
            child: Checkbox(value: true, onChanged: (_) {}),
          ),
          Semantics(
            label: 'Flutter switch',
            child: Switch(value: true, onChanged: (_) {}),
          ),
          SizedBox(
            width: 358,
            child: SwitchListTile(
              title: const Text('Flutter switch row'),
              value: true,
              onChanged: (_) {},
            ),
          ),
          KeycapRadio<String>(
            value: 'a',
            groupValue: 'a',
            onChanged: (_) {},
            semanticLabel: 'Keycap radio',
          ),
          KeycapCheckbox(
            value: true,
            onChanged: (_) {},
            semanticLabel: 'Keycap checkbox',
          ),
          KeycapSwitch(
            value: true,
            onChanged: (_) {},
            semanticLabel: 'Keycap switch',
          ),
          SizedBox(
            width: 358,
            child: KeycapSwitchListTile(
              title: 'Keycap switch row',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    );
    for (final (keycap, flutter) in [
      ('Keycap radio', 'Flutter radio'),
      ('Keycap checkbox', 'Flutter checkbox'),
      ('Keycap switch', 'Flutter switch'),
      ('Keycap switch row', 'Flutter switch row'),
    ]) {
      final ours = _flags(tester, keycap);
      final theirs = _flags(tester, flutter);
      expect(ours.isButton, isFalse, reason: '$keycap: button');
      expect(
        ours.isInMutuallyExclusiveGroup,
        theirs.isInMutuallyExclusiveGroup,
        reason: '$keycap: group',
      );
      expect(ours.isChecked, theirs.isChecked, reason: '$keycap: checked');
      expect(ours.isToggled, theirs.isToggled, reason: '$keycap: toggled');
    }
    semantics.dispose();
  });

  // The shared keyboard check: options A to D with B turned off, chosen C,
  // nothing, and the turned-off B, in both reading directions.
  for (final direction in TextDirection.values) {
    for (final initial in <String?>['C', null, 'B']) {
      final named = 'chosen ${initial ?? 'nothing'}, ${direction.name}';
      testWidgets('a radio group passes the shared check, $named', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        final before = FocusNode(debugLabel: 'before');
        addTearDown(before.dispose);
        var chosen = initial;
        await _show(
          tester,
          StatefulBuilder(
            builder: (context, setState) => _between(
              before,
              KeycapRadioGroup<String>(
                options: const ['A', 'B', 'C', 'D'],
                groupValue: chosen,
                isEnabled: (v) => v != 'B',
                labelOf: (v) => v,
                semanticLabel: 'Letters',
                onChanged: (v) => setState(() => chosen = v),
              ),
            ),
          ),
          direction: direction,
        );
        if (initial == 'B') {
          // A turned-off choice still says it is the checked one.
          expect(_flags(tester, 'B').isChecked, CheckedState.isTrue);
          expect(_flags(tester, 'B').isEnabled, Tristate.isFalse);
        }
        await _check(tester, before);
        semantics.dispose();
      });

      testWidgets('a one-at-a-time toggle group passes the shared check, '
          '$named', (tester) async {
        final semantics = tester.ensureSemantics();
        final before = FocusNode(debugLabel: 'before');
        addTearDown(before.dispose);
        var down = initial;
        await _show(
          tester,
          StatefulBuilder(
            builder: (context, setState) => _between(
              before,
              KeycapToggleGroup<String>(
                options: [
                  for (final v in const ['A', 'B', 'C', 'D'])
                    KeycapToggleOption(value: v, label: v, enabled: v != 'B'),
                ],
                selected: {?down},
                multiSelectionEnabled: false,
                semanticLabel: 'Letters',
                onSelectionChanged: (s) =>
                    setState(() => down = s.isEmpty ? null : s.first),
              ),
            ),
          ),
          direction: direction,
        );
        await _check(tester, before);
        semantics.dispose();
      });
    }

    for (final initial in <String?>['week', null]) {
      testWidgets('a one-choice segmented button passes the shared check, '
          'chosen ${initial ?? 'nothing'}, ${direction.name}', (tester) async {
        final semantics = tester.ensureSemantics();
        final before = FocusNode(debugLabel: 'before');
        addTearDown(before.dispose);
        var chosen = initial;
        await _show(
          tester,
          StatefulBuilder(
            builder: (context, setState) => _between(
              before,
              KeycapSegmentedButton<String>(
                segments: const [
                  KeycapSegment(value: 'day', label: 'Day'),
                  KeycapSegment(value: 'week', label: 'Week'),
                  KeycapSegment(value: 'month', label: 'Month'),
                ],
                selected: {?chosen},
                emptySelectionAllowed: initial == null,
                semanticLabel: 'Period',
                onSelectionChanged: (s) =>
                    setState(() => chosen = s.isEmpty ? null : s.first),
              ),
            ),
          ),
          direction: direction,
        );
        await _check(tester, before);
        semantics.dispose();
      });
    }
  }

  testWidgets('a tap on the words chooses, and a second Tab leaves', (
    tester,
  ) async {
    final before = FocusNode(debugLabel: 'before');
    addTearDown(before.dispose);
    var chosen = 'A4';
    await _show(
      tester,
      StatefulBuilder(
        builder: (context, setState) => _between(
          before,
          KeycapRadioGroup<String>(
            options: const ['A4', 'Letter', 'Legal'],
            groupValue: chosen,
            labelOf: (v) => v,
            onChanged: (v) => setState(() => chosen = v),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Letter'));
    await tester.pumpAndSettle();
    expect(chosen, 'Letter');
    // Pressing the chosen one again changes nothing.
    await tester.tap(find.text('Letter'));
    await tester.pumpAndSettle();
    expect(chosen, 'Letter');
  });

  testWidgets('the key that is down lets up when the row may be empty', (
    tester,
  ) async {
    Set<String> down = {'bold'};
    await _show(
      tester,
      StatefulBuilder(
        builder: (context, setState) => KeycapToggleGroup<String>(
          options: const [
            KeycapToggleOption(value: 'bold', label: 'Bold'),
            KeycapToggleOption(value: 'italic', label: 'Italic'),
          ],
          selected: down,
          multiSelectionEnabled: false,
          onSelectionChanged: (s) => setState(() => down = s),
        ),
      ),
    );
    await tester.tap(find.text('Italic'));
    await tester.pumpAndSettle();
    expect(down, {'italic'});
    await tester.tap(find.text('Italic'));
    await tester.pumpAndSettle();
    expect(down, isEmpty);
  });

  testWidgets('a radio keeps the focus node its caller gives it', (
    tester,
  ) async {
    final first = FocusNode(debugLabel: 'first');
    final second = FocusNode(debugLabel: 'second');
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    var told = 0;
    first.addListener(() => told++);
    Widget radio(FocusNode node) => KeycapRadio<String>(
      value: 'md',
      groupValue: 'md',
      semanticLabel: 'Markdown',
      focusNode: node,
      onChanged: (_) {},
    );

    await _show(tester, radio(first));
    first.requestFocus();
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, same(first));
    expect(told, greaterThan(0), reason: 'the caller hears the focus');

    // A rebuild with the same node keeps the focus where it is.
    await _show(tester, radio(first));
    expect(FocusManager.instance.primaryFocus, same(first));

    // A second node replaces the first, which lets go of the radio.
    await _show(tester, radio(second));
    second.requestFocus();
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, same(second));
    expect(first.hasFocus, isFalse);
    // Tab leaves the lone radio and comes back to it through its node.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, same(second));

    // Gone, the radio leaves both nodes whole for the caller to reuse.
    await _show(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Focus(focusNode: first, child: const Text('First')),
          Focus(focusNode: second, child: const Text('Second')),
        ],
      ),
    );
    for (final node in [first, second]) {
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, same(node));
    }
  });
}
