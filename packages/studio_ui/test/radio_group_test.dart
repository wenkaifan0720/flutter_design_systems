// A radio reads as Flutter's does: a checkable in a mutually exclusive
// group, not a button (and a checkbox as Flutter's Checkbox, a checkable,
// not a button). A StudioRadioGroup is one Tab stop: Tab reaches it at its
// choice and the next Tab leaves it; the arrows choose the next or the
// previous and wrap, mirrored right to left in a row; a screen reader hears
// each row as a radio named by its words, in a form field too. A bank of
// latching keys is a radio group of its keys, a radio keeps the focus node
// its caller gives it, a press anywhere in a radio's box chooses it, and a
// selectable table row reads as a checkbox, checked when selected, not as a
// button.
import 'dart:ui' show CheckedState, SemanticsFlags, Tristate;

import 'package:material_ui/material_ui.dart'
    show Checkbox, MaterialApp, Radio, RadioGroup, Scaffold;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

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
          StudioHost(brightness: Brightness.light, child: app!),
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

/// Presses each of [radios] (a group's RawRadios, saying [values] in turn)
/// at its start, its middle, its end, its top and its bottom, each time from
/// another choice, and expects the press to choose it. RawRadio's own
/// detector takes a press only where the face paints; a radio takes it
/// anywhere in its box, as the published radios did, the gap between its key
/// and its words too.
Future<void> _pressEverywhere<V>(
  WidgetTester tester,
  Finder radios,
  ValueNotifier<V> choice,
  List<V> values,
) async {
  expect(radios, findsNWidgets(values.length));
  for (final (i, value) in values.indexed) {
    final box = tester.getRect(radios.at(i));
    for (final at in [
      box.centerLeft + const Offset(2, 0),
      box.center,
      box.centerRight - const Offset(2, 0),
      box.topCenter + const Offset(0, 2),
      box.bottomCenter - const Offset(0, 2),
    ]) {
      choice.value = values[(i + 1) % values.length];
      await tester.pumpAndSettle();
      await tester.tapAt(at);
      await tester.pumpAndSettle();
      expect(choice.value, value, reason: '$value pressed at $at in $box');
    }
  }
}

Finder _radiosOf(Finder group) => find.descendant(
  of: group,
  matching: find.byWidgetPredicate((w) => w is RawRadio),
);

void main() {
  setUpAll(studioLoadFonts);

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
          StudioRadio<String>(
            value: 'a',
            groupValue: 'a',
            onChanged: (_) {},
            semanticLabel: 'Studio radio',
          ),
          StudioCheckbox(
            value: true,
            onChanged: (_) {},
            semanticLabel: 'Studio checkbox',
          ),
          SizedBox(
            width: 300,
            child: StudioCheckRow(
              label: 'Studio check row',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    );
    final radio = _flags(tester, 'Flutter radio');
    final checkbox = _flags(tester, 'Flutter checkbox');
    for (final (label, flutter) in [
      ('Studio radio', radio),
      ('Studio checkbox', checkbox),
      ('Studio check row', checkbox),
    ]) {
      final studio = _flags(tester, label);
      expect(studio.isButton, flutter.isButton, reason: '$label: button');
      expect(studio.isButton, isFalse, reason: '$label: button');
      expect(
        studio.isInMutuallyExclusiveGroup,
        flutter.isInMutuallyExclusiveGroup,
        reason: '$label: group',
      );
      expect(studio.isChecked, flutter.isChecked, reason: '$label: checked');
    }
    semantics.dispose();
  });

  for (final axis in Axis.values) {
    testWidgets('a press anywhere in a radio\'s box chooses it, ${axis.name}', (
      tester,
    ) async {
      final format = ValueNotifier('MP3');
      final rate = ValueNotifier(1.0);
      addTearDown(format.dispose);
      addTearDown(rate.dispose);
      await _show(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 360,
              child: ValueListenableBuilder(
                valueListenable: format,
                builder: (context, value, _) => StudioRadioGroup<String>(
                  options: const ['MP3', 'AAC', 'WAV'],
                  value: value,
                  labelOf: (f) => f,
                  direction: axis,
                  onChanged: (f) => format.value = f,
                ),
              ),
            ),
            SizedBox(
              width: 360,
              child: ValueListenableBuilder(
                valueListenable: rate,
                builder: (context, value, _) => StudioSegmentedButton<double>(
                  segments: const [
                    StudioSegment(value: 1.0, label: '1×'),
                    StudioSegment(value: 1.5, label: '1.5×'),
                    StudioSegment(value: 2.0, label: '2×'),
                  ],
                  value: value,
                  onChanged: (r) => rate.value = r,
                ),
              ),
            ),
          ],
        ),
      );
      await _pressEverywhere(
        tester,
        _radiosOf(find.byType(StudioRadioGroup<String>)),
        format,
        const ['MP3', 'AAC', 'WAV'],
      );
      await _pressEverywhere(
        tester,
        _radiosOf(find.byType(StudioSegmentedButton<double>)),
        rate,
        const [1.0, 1.5, 2.0],
      );
    });
  }

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
          child: StudioFormField(
            label: 'Format',
            child: StudioRadioGroup<String>(
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
              StudioButton('Before', focusNode: before, onPressed: () {}),
              SizedBox(
                key: _group,
                width: 360,
                child: StudioRadioGroup<String>(
                  options: const ['MP3', 'AAC', 'WAV'],
                  value: chosen,
                  labelOf: (f) => f,
                  direction: axis,
                  semanticLabel: 'Format',
                  onChanged: (f) => setState(() => chosen = f),
                ),
              ),
              StudioButton('After', focusNode: after, onPressed: () {}),
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

  // The shared keyboard check: options A to D with B turned off, chosen C,
  // nothing, A, and the turned-off B, down a column and along a row, in both
  // reading directions.
  for (final axis in Axis.values) {
    for (final direction in TextDirection.values) {
      for (final initial in <String?>['C', null, 'A', 'B']) {
        testWidgets('the shared radio group check, ${axis.name}, '
            '${direction.name}, chosen ${initial ?? 'nothing'}', (
          tester,
        ) async {
          final semantics = tester.ensureSemantics();
          final before = FocusNode(debugLabel: 'before');
          addTearDown(before.dispose);
          var chosen = initial;
          await _show(
            tester,
            StatefulBuilder(
              builder: (context, setState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StudioButton('Before', focusNode: before, onPressed: () {}),
                  SizedBox(
                    key: const ValueKey('radios'),
                    width: 310,
                    child: StudioRadioGroup<String>(
                      options: const ['A', 'B', 'C', 'D'],
                      value: chosen,
                      isEnabled: (v) => v != 'B',
                      labelOf: (v) => v,
                      direction: axis,
                      semanticLabel: 'Letters',
                      onChanged: (v) => setState(() => chosen = v),
                    ),
                  ),
                  StudioButton('After', onPressed: () {}),
                ],
              ),
            ),
            direction: direction,
          );
          if (initial == 'B') {
            // A turned-off choice still says it is the checked one.
            expect(_flags(tester, 'B').isChecked, CheckedState.isTrue);
            expect(_flags(tester, 'B').isEnabled, Tristate.isFalse);
          }
          (await const DesignRadioGroupCheck(look: 'Studio').check(
            tester.element(find.byKey(const ValueKey('radios'))),
            before: before,
            sendKeyEvent: tester.sendKeyEvent,
            pump: tester.pump,
          )).verify();
          semantics.dispose();
        });
      }
    }
  }

  testWidgets('Home and End choose the first and the last open choice', (
    tester,
  ) async {
    final before = FocusNode(debugLabel: 'before');
    addTearDown(before.dispose);
    var chosen = 'B';
    await _show(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StudioButton('Before', focusNode: before, onPressed: () {}),
            SizedBox(
              key: _group,
              width: 360,
              child: StudioRadioGroup<String>(
                options: const ['A', 'B', 'C', 'D'],
                value: chosen,
                isEnabled: (v) => v != 'A',
                labelOf: (v) => v,
                onChanged: (v) => setState(() => chosen = v),
              ),
            ),
          ],
        ),
      ),
    );
    String focused() {
      final semantics = tester.ensureSemantics();
      final on = [
        for (final v in ['A', 'B', 'C', 'D'])
          if (_flags(tester, v).isFocused == Tristate.isTrue) v,
      ];
      semantics.dispose();
      return on.single;
    }

    before.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect((chosen, focused()), ('D', 'D'));
    // A is turned off, so Home stops at B.
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect((chosen, focused()), ('B', 'B'));
  });

  for (final direction in TextDirection.values) {
    testWidgets('a key bank is a radio group of its keys, '
        '${direction.name}', (tester) async {
      final semantics = tester.ensureSemantics();
      final before = FocusNode(debugLabel: 'before');
      final after = FocusNode(debugLabel: 'after');
      addTearDown(before.dispose);
      addTearDown(after.dispose);
      var chosen = 'trailer';
      const words = {'full': 'Full', 'trailer': 'Trailer', 'bonus': 'Bonus'};
      await _show(
        tester,
        StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StudioButton('Before', focusNode: before, onPressed: () {}),
              SizedBox(
                key: const ValueKey('segments'),
                width: 360,
                child: StudioSegmentedButton<String>(
                  segments: const [
                    StudioSegment(value: 'full', label: 'Full'),
                    StudioSegment(value: 'trailer', label: 'Trailer'),
                    StudioSegment(value: 'bonus', label: 'Bonus'),
                  ],
                  value: chosen,
                  semanticLabel: 'Episode type',
                  onChanged: (v) => setState(() => chosen = v),
                ),
              ),
              StudioButton('After', focusNode: after, onPressed: () {}),
            ],
          ),
        ),
        direction: direction,
      );

      List<String> checked() => [
        for (final w in words.values)
          if (_flags(tester, w).isChecked == CheckedState.isTrue) w,
      ];

      // Each segment a radio named by its words, the chosen one checked.
      for (final w in words.values) {
        final flags = _flags(tester, w);
        expect(flags.isInMutuallyExclusiveGroup, isTrue, reason: w);
        expect(flags.isButton, isFalse, reason: w);
      }
      expect(checked(), ['Trailer']);

      Future<void> press(LogicalKeyboardKey key) async {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
      }

      // One Tab stop, at the choice.
      before.requestFocus();
      await tester.pumpAndSettle();
      await press(LogicalKeyboardKey.tab);
      expect(_flags(tester, 'Trailer').isFocused, Tristate.isTrue);
      await press(LogicalKeyboardKey.tab);
      expect(FocusManager.instance.primaryFocus, same(after));

      // The arrow the row reads by chooses the next segment, and wraps.
      final next = direction == TextDirection.ltr
          ? LogicalKeyboardKey.arrowRight
          : LogicalKeyboardKey.arrowLeft;
      before.requestFocus();
      await tester.pumpAndSettle();
      await press(LogicalKeyboardKey.tab);
      await press(next);
      expect(chosen, 'bonus');
      expect(checked(), ['Bonus']);
      expect(_flags(tester, 'Bonus').isFocused, Tristate.isTrue);
      await press(LogicalKeyboardKey.arrowDown);
      expect(chosen, 'full', reason: 'Down wraps');
      expect(checked(), ['Full'], reason: 'Down wraps');
      await press(LogicalKeyboardKey.arrowUp);
      expect(chosen, 'bonus');
      await press(LogicalKeyboardKey.home);
      expect(chosen, 'full', reason: 'Home');
      expect(checked(), ['Full'], reason: 'Home');
      await press(LogicalKeyboardKey.end);
      expect(chosen, 'bonus', reason: 'End');
      expect(checked(), ['Bonus'], reason: 'End');
      semantics.dispose();
    });
  }

  testWidgets('the shared radio group check on the playback rates', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final before = FocusNode(debugLabel: 'before');
    addTearDown(before.dispose);
    var chosen = 1.0;
    await _show(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StudioButton('Before', focusNode: before, onPressed: () {}),
            SizedBox(
              key: const ValueKey('segments'),
              width: 360,
              child: StudioSegmentedButton<double>(
                semanticLabel: 'Speed',
                segments: const [
                  StudioSegment(value: 1.0, label: '1×'),
                  StudioSegment(value: 1.25, label: '1.25×'),
                  StudioSegment(value: 1.5, label: '1.5×'),
                  StudioSegment(value: 2.0, label: '2×'),
                ],
                value: chosen,
                onChanged: (v) => setState(() => chosen = v),
              ),
            ),
            StudioButton('After', onPressed: () {}),
          ],
        ),
      ),
    );
    (await const DesignRadioGroupCheck(look: 'Studio').check(
      tester.element(find.byKey(const ValueKey('segments'))),
      before: before,
      sendKeyEvent: tester.sendKeyEvent,
      pump: tester.pump,
    )).verify();
    semantics.dispose();
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
    Widget radio(FocusNode node) => StudioRadio<String>(
      value: 'metric',
      groupValue: 'metric',
      semanticLabel: 'Metric',
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

  testWidgets('a selectable table row reads as a checked checkbox, not a '
      'button', (tester) async {
    final semantics = tester.ensureSemantics();
    final before = FocusNode(debugLabel: 'before');
    addTearDown(before.dispose);
    final table = StudioTableController<(String, String, int)>(
      rows: const [
        ('Pilot', 'One', 1204),
        ('The long table', 'One', 864),
        ('Field notes', 'Two', 702),
        ('Night shift', 'Two', 655),
      ],
      rowKey: (r) => r.$1,
      columns: [
        StudioDataColumn(id: 'name', label: 'Episode', sortKey: (r) => r.$1),
        StudioDataColumn(id: 'kind', label: 'Season', sortKey: (r) => r.$2),
        StudioDataColumn(
          id: 'figure',
          label: 'Plays',
          numeric: true,
          sortKey: (r) => r.$3,
        ),
      ],
    );
    addTearDown(table.dispose);
    await _show(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StudioButton('Before', focusNode: before, onPressed: () {}),
          SizedBox(
            width: 380,
            child: StudioDataTable<(String, String, int)>(
              controller: table,
              cell: (r, column) => switch (column) {
                'name' => r.$1,
                'kind' => r.$2,
                _ => '${r.$3}',
              },
            ),
          ),
        ],
      ),
    );
    const items = ['Pilot', 'The long table', 'Field notes', 'Night shift'];
    SemanticsNode row(String item) {
      final nodes = find.semantics
          .byPredicate(
            (node) =>
                node.label.split('\n').contains(item) &&
                node.getSemanticsData().flagsCollection.isChecked !=
                    CheckedState.none,
          )
          .evaluate()
          .toList();
      expect(nodes, hasLength(1), reason: item);
      return nodes.single;
    }

    void expectChecked(Set<String> chosen) {
      for (final item in items) {
        final flags = row(item).getSemanticsData().flagsCollection;
        expect(flags.isButton, isFalse, reason: '$item: button');
        expect(
          flags.isChecked,
          chosen.contains(item) ? CheckedState.isTrue : CheckedState.isFalse,
          reason: '$item: checked',
        );
      }
    }

    expectChecked({});
    await tester.tap(find.text('The long table'));
    await tester.pumpAndSettle();
    final toggled = {'The long table'};
    expectChecked(toggled);
    // Tab past the page box and the sorting headings to the rows' one stop,
    // then Space toggles the focused row and the arrows walk the rows.
    String? focused() => [
      for (final item in items)
        if (row(item).getSemanticsData().flagsCollection.isFocused ==
            Tristate.isTrue)
          item,
    ].singleOrNull;
    before.requestFocus();
    await tester.pump();
    for (var i = 0; i < 8 && focused() == null; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    final first = focused();
    expect(first, isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    if (!toggled.remove(first)) toggled.add(first!);
    expectChecked(toggled);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    final next = focused();
    expect(items.indexOf(next!), items.indexOf(first!) + 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    if (!toggled.remove(next)) toggled.add(next);
    expectChecked(toggled);
    semantics.dispose();
  });
}
