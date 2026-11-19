// A radio reads as Flutter's does: a checkable in a mutually exclusive
// group, not a button (and a checkbox as Flutter's Checkbox, a checkable,
// not a button). An ApplianceRadioGroup is one Tab stop: Tab reaches it at its
// choice and the next Tab leaves it; the arrows choose the next or the
// previous and wrap, mirrored right to left in a row; a screen reader hears
// each row as a radio named by its words, in a form field too.
import 'dart:ui' show CheckedState, SemanticsFlags, Tristate;

import 'package:material_ui/material_ui.dart'
    show Checkbox, MaterialApp, Radio, RadioGroup, Scaffold;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appliance_ui/appliance_ui.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 1200);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: Scaffold(
        body: Directionality(
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

const _group = ValueKey('group');

void main() {
  testWidgets('a radio and a checkbox read as Flutter\'s do, not as buttons', (
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
          ApplianceRadio<String>(
            value: 'a',
            groupValue: 'a',
            onChanged: (_) {},
            semanticLabel: 'Appliance radio',
          ),
          ApplianceCheckbox(
            value: true,
            onChanged: (_) {},
            semanticLabel: 'Appliance checkbox',
          ),
        ],
      ),
    );
    final radio = _flags(tester, 'Flutter radio');
    final checkbox = _flags(tester, 'Flutter checkbox');
    for (final (label, flutter) in [
      ('Appliance radio', radio),
      ('Appliance checkbox', checkbox),
    ]) {
      final appliance = _flags(tester, label);
      expect(appliance.isButton, flutter.isButton, reason: '$label: button');
      expect(appliance.isButton, isFalse, reason: '$label: button');
      expect(
        appliance.isInMutuallyExclusiveGroup,
        flutter.isInMutuallyExclusiveGroup,
        reason: '$label: group',
      );
      expect(appliance.isChecked, flutter.isChecked, reason: '$label: checked');
    }
    semantics.dispose();
  });

  testWidgets('in a form field, each radio keeps its own node and tap', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var chosen = 'MP3';
    await _show(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 360,
          child: ApplianceField(
            labelText: 'Format',
            child: ApplianceRadioGroup<String>(
              options: const ['MP3', 'AAC', 'WAV'],
              value: chosen,
              labelOf: (f) => f,
              onChanged: (f) => setState(() => chosen = f),
            ),
          ),
        ),
      ),
    );
    // Merged into the field, the radios would be one node, "Format" and
    // all three words, which a screen reader could not choose by.
    for (final f in ['MP3', 'AAC', 'WAV']) {
      // The node a reader reaches: the radio's own, not the field's.
      expect(tester.getSemantics(find.bySemanticsLabel(f)).label, f);
      expect(_flags(tester, f).isInMutuallyExclusiveGroup, isTrue, reason: f);
    }
    tester.semantics.tap(find.semantics.byLabel('AAC'));
    await tester.pumpAndSettle();
    expect(chosen, 'AAC');
    semantics.dispose();
  });

  for (final (axis, direction, next, previous) in [
    (
      Axis.vertical,
      TextDirection.ltr,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowUp,
    ),
    (
      Axis.vertical,
      TextDirection.rtl,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowUp,
    ),
    (
      Axis.horizontal,
      TextDirection.ltr,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowLeft,
    ),
    (
      Axis.horizontal,
      TextDirection.rtl,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
    ),
  ]) {
    testWidgets('a ${axis.name} group, ${direction.name}: one Tab stop, and '
        '${next.keyLabel} chooses the next', (tester) async {
      final semantics = tester.ensureSemantics();
      final before = FocusNode(debugLabel: 'before');
      final after = FocusNode(debugLabel: 'after');
      addTearDown(before.dispose);
      addTearDown(after.dispose);
      var chosen = 'MP3';
      await _show(
        tester,
        StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApplianceButton('Before', focusNode: before, onPressed: () {}),
              SizedBox(
                key: _group,
                width: 360,
                child: ApplianceRadioGroup<String>(
                  options: const ['MP3', 'AAC', 'WAV'],
                  value: chosen,
                  labelOf: (f) => f,
                  direction: axis,
                  semanticLabel: 'Format',
                  onChanged: (f) => setState(() => chosen = f),
                ),
              ),
              ApplianceButton('After', focusNode: after, onPressed: () {}),
            ],
          ),
        ),
        direction: direction,
      );

      String place() {
        final focus = FocusManager.instance.primaryFocus;
        if (focus == before) return 'before';
        if (focus == after) return 'after';
        var inGroup = false;
        focus?.context?.visitAncestorElements((element) {
          inGroup = element.widget.key == _group;
          return !inGroup;
        });
        return inGroup ? 'group' : 'elsewhere';
      }

      Future<void> press(LogicalKeyboardKey key) async {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
      }

      // Each row a radio named by its words, not a button.
      for (final f in ['MP3', 'AAC', 'WAV']) {
        final flags = _flags(tester, f);
        expect(flags.isInMutuallyExclusiveGroup, isTrue, reason: f);
        expect(flags.isButton, isFalse, reason: f);
      }
      expect(_flags(tester, 'MP3').isChecked, CheckedState.isTrue);

      // Tab reaches the group at its choice, and the next Tab leaves it.
      before.requestFocus();
      await tester.pumpAndSettle();
      await press(LogicalKeyboardKey.tab);
      expect(place(), 'group');
      expect(_flags(tester, 'MP3').isFocused, Tristate.isTrue);
      await press(LogicalKeyboardKey.tab);
      expect(place(), 'after');

      // The arrows choose, the focus staying in the group, and wrap.
      before.requestFocus();
      await tester.pumpAndSettle();
      await press(LogicalKeyboardKey.tab);
      await press(next);
      expect((chosen, place()), ('AAC', 'group'));
      await press(next);
      await press(next);
      expect(chosen, 'MP3', reason: 'the arrows wrap');
      await press(previous);
      expect(chosen, 'WAV');
      // Back into the group from after it, Tab lands on the choice.
      await press(LogicalKeyboardKey.tab);
      expect(place(), 'after');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await press(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      expect(place(), 'group');
      await press(LogicalKeyboardKey.space);
      expect(chosen, 'WAV');
      semantics.dispose();
    });
  }
}
