// Clay's single choices answer the keyboard as Flutter's RadioGroup does
// (ui_core_test's DesignRadioGroupCheck): one Tab stop, on the choice or on
// the first that can be chosen; arrows that choose as they move, round the
// ends and past a choice turned off, Left onward right to left; and each
// radio says it is one, checked or not, and not a button. Each group is
// checked with C chosen, with none, and with B (turned off) chosen, left to
// right and right to left. Sibling radios grouped at their owner keep the
// nodes their caller gave them.
import 'dart:ui' show CheckedState;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:clay_ui/clay_ui.dart';

const _options = ['A', 'B', 'C', 'D'];

/// One of [_options] chosen, [value]; [choose] holds a new choice.
typedef _Choice = Widget Function(String? value, ValueChanged<String> choose);

/// The radios that say they are checked (each once: not the node merged
/// into its radio's).
int _checked() => find.semantics
    .byPredicate((node) {
      if (node.isMergedIntoParent) return false;
      final f = node.getSemanticsData().flagsCollection;
      return f.isInMutuallyExclusiveGroup && f.isChecked == CheckedState.isTrue;
    })
    .evaluate()
    .length;

/// [choice] between a key before it and a key after it, its choice held as
/// an app holds it, then checked from the key before.
Future<void> _check(
  WidgetTester tester,
  _Choice choice, {
  required String? start,
  required TextDirection direction,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final before = FocusNode();
  addTearDown(before.dispose);
  var value = start;
  await tester.pumpWidget(
    ClayPreview(
      child: Directionality(
        textDirection: direction,
        child: ClayScreen(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClayButton('Before', focusNode: before, onPressed: () {}),
              StatefulBuilder(
                builder: (context, setState) => KeyedSubtree(
                  key: const ValueKey('radios'),
                  child: choice(value, (v) => setState(() => value = v)),
                ),
              ),
              ClayButton('After', onPressed: () {}),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  (await const DesignRadioGroupCheck(look: 'Clay').check(
    tester.element(find.byKey(const ValueKey('radios'))),
    before: before,
    sendKeyEvent: tester.sendKeyEvent,
    pump: tester.pump,
  )).verify();
  // After the arrows have moved, one radio is checked, never two.
  await tester.pumpAndSettle();
  expect(_checked(), 1);
}

void main() {
  final groups = <String, _Choice>{
    'ClayRadioGroup': (value, choose) => ClayRadioGroup<String>(
      options: _options,
      value: value,
      labelOf: (o) => o,
      isEnabled: (o) => o != 'B',
      onChanged: choose,
      semanticLabel: 'Letters',
    ),
    'ClayRadioGroup in a row': (value, choose) => ClayRadioGroup<String>(
      options: _options,
      value: value,
      labelOf: (o) => o,
      isEnabled: (o) => o != 'B',
      onChanged: choose,
      direction: Axis.horizontal,
      semanticLabel: 'Letters',
    ),
    'ClayToggleGroup, one at a time': (value, choose) =>
        ClayToggleGroup<String>(
          toggles: [
            for (final o in _options)
              ClayToggle(value: o, label: o, enabled: o != 'B'),
          ],
          selected: {?value},
          onSelectionChanged: (next) {
            if (next.isNotEmpty) choose(next.first);
          },
          multiSelectionEnabled: false,
          emptySelectionAllowed: false,
          semanticLabel: 'Letters',
        ),
  };
  for (final MapEntry(key: name, value: group) in groups.entries) {
    for (final direction in TextDirection.values) {
      for (final start in const ['C', null, 'B']) {
        testWidgets('$name, ${direction.name}, ${start ?? 'none'} chosen', (
          tester,
        ) async {
          await _check(tester, group, start: start, direction: direction);
        });
      }
    }
  }

  // A segmented button always holds a choice, and turns off whole.
  for (final direction in TextDirection.values) {
    testWidgets('ClaySegmentedButton, ${direction.name}, C chosen', (
      tester,
    ) async {
      await _check(
        tester,
        (value, choose) => ClaySegmentedButton<String>(
          segments: [for (final o in _options) ClaySegment(value: o, label: o)],
          selected: value ?? 'A',
          onChanged: choose,
          semanticLabel: 'Letters',
        ),
        start: 'C',
        direction: direction,
      );
    });
  }

  // Sibling radios grouped where their choice is held, each on the node its
  // caller gave it.
  for (final direction in TextDirection.values) {
    for (final start in const ['C', null, 'B']) {
      testWidgets('ClayRadio siblings, ${direction.name}, '
          '${start ?? 'none'} chosen, on their callers\' nodes', (
        tester,
      ) async {
        final nodes = {for (final o in _options) o: FocusNode(debugLabel: o)};
        for (final node in nodes.values) {
          addTearDown(node.dispose);
        }
        await _check(
          tester,
          (value, choose) => DesignRadioGroup<String>(
            options: _options,
            value: value,
            isEnabled: (o) => o != 'B',
            focusNodeFor: (o) => nodes[o],
            onChanged: choose,
            direction: Axis.horizontal,
            itemBuilder: (context, o, node, select) => ClayRadio<String>(
              key: ValueKey('radio $o'),
              value: o,
              groupValue: value,
              focusNode: node,
              semanticLabel: o,
              onChanged: select == null ? null : (_) => select(),
            ),
          ),
          start: start,
          direction: direction,
        );
        // The radio took the caller's own node, and focus through it.
        final a = nodes['A']!;
        expect(
          tester
              .widget<ClayRadio<String>>(find.byKey(const ValueKey('radio A')))
              .focusNode,
          same(a),
        );
        a.requestFocus();
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, same(a));
        // An arrow moves on to the caller's own node for the next choice,
        // past B, turned off.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, same(nodes['C']));
      });
    }
  }
}
