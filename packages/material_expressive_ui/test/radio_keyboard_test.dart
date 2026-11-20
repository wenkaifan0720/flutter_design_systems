/// Radio group Tab entry, arrow selection, wrapping, disabled options and
/// right-to-left reading order.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart' show DesignRadioGroupCheck;
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

const _group = ValueKey('group');

class _Harness {
  _Harness(this.tester);

  final WidgetTester tester;
  final before = FocusNode(debugLabel: 'before');
  final after = FocusNode(debugLabel: 'after');
  String? chosen;

  Future<void> pump({
    String? value,
    Set<String> disabled = const {},
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    chosen = value;
    addTearDown(before.dispose);
    addTearDown(after.dispose);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, app) => ExpressiveHost(
          light: _theme,
          brightness: Brightness.light,
          child: Directionality(textDirection: textDirection, child: app!),
        ),
        home: Material(
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  focusNode: before,
                  onPressed: () {},
                  child: const Text('Before'),
                ),
                KeyedSubtree(
                  key: _group,
                  child: ExpressiveRadioGroup<String>(
                    value: chosen,
                    onChanged: (v) => setState(() => chosen = v),
                    options: [
                      for (final v in const ['A', 'B', 'C'])
                        ExpressiveRadioOption<String>(
                          value: v,
                          label: v,
                          enabled: !disabled.contains(v),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  focusNode: after,
                  onPressed: () {},
                  child: const Text('After'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Where focus is: before, after, or the option of the group it is on.
  String place() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == before) return 'before';
    if (focus == after) return 'after';
    String? row;
    focus?.context?.visitAncestorElements((e) {
      final widget = e.widget;
      if (widget is ExpressiveRadioRow) row = widget.label;
      return row == null;
    });
    return row ?? 'elsewhere';
  }

  Future<void> key(LogicalKeyboardKey key, {bool shift = false}) async {
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(key);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pumpAndSettle();
  }

  /// Tab from the button before the group.
  Future<void> enter() async {
    before.requestFocus();
    await tester.pumpAndSettle();
    await key(LogicalKeyboardKey.tab);
  }
}

enum _Choices { rows, segments, toggles }

Widget _choices(_Choices kind, String? value, ValueChanged<String> changed) {
  const options = [
    ExpressiveButtonSegment('A', 'A'),
    ExpressiveButtonSegment('B', 'B', enabled: false),
    ExpressiveButtonSegment('C', 'C'),
    ExpressiveButtonSegment('D', 'D'),
  ];
  return switch (kind) {
    _Choices.rows => ExpressiveRadioGroup<String>(
      options: [
        for (final option in options)
          ExpressiveRadioOption(
            value: option.value,
            label: option.label,
            enabled: option.enabled,
          ),
      ],
      value: value,
      onChanged: changed,
    ),
    _Choices.segments => ExpressiveSegmentedButton<String>(
      segments: options,
      value: value,
      onChanged: changed,
      expand: false,
    ),
    _Choices.toggles => ExpressiveToggleGroup<String>(
      segments: options,
      value: value,
      onChanged: changed,
    ),
  };
}

void main() {
  for (final kind in _Choices.values) {
    for (final direction in TextDirection.values) {
      for (final initial in <String?>['C', null, 'B']) {
        testWidgets(
          '${kind.name} keyboard in ${direction.name}, checked $initial',
          (tester) async {
            final before = FocusNode();
            final after = FocusNode();
            addTearDown(before.dispose);
            addTearDown(after.dispose);
            var value = initial;
            await tester.pumpWidget(
              MaterialApp(
                home: ExpressiveHost(
                  light: _theme,
                  brightness: Brightness.light,
                  child: Directionality(
                    textDirection: direction,
                    child: Material(
                      child: StatefulBuilder(
                        builder: (context, setState) => Column(
                          children: [
                            TextButton(
                              focusNode: before,
                              onPressed: () {},
                              child: const Text('Before'),
                            ),
                            KeyedSubtree(
                              key: _group,
                              child: _choices(
                                kind,
                                value,
                                (next) => setState(() => value = next),
                              ),
                            ),
                            TextButton(
                              focusNode: after,
                              onPressed: () {},
                              child: const Text('After'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            void expectRadio(String option) {
              final node = tester.getSemantics(find.bySemanticsLabel(option));
              expect(
                node,
                isSemantics(
                  label: option,
                  hasCheckedState: true,
                  isChecked: option == value,
                  isInMutuallyExclusiveGroup: true,
                  isButton: false,
                  isEnabled: option != 'B',
                ),
              );
            }

            const options = ['A', 'B', 'C', 'D'];
            for (final option in options) {
              expectRadio(option);
            }
            final result =
                await const DesignRadioGroupCheck(look: 'Material Expressive')
                    .check(
                      tester.element(find.byKey(_group)),
                      before: before,
                      sendKeyEvent: tester.sendKeyEvent,
                      pump: tester.pump,
                    );
            result.verify();
            expect(value, isNotNull);
            for (final option in options) {
              expectRadio(option);
            }
          },
        );
      }
    }
  }

  testWidgets(
    'switch rows and independent checkable segments expose their state',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExpressiveHost(
            light: _theme,
            brightness: Brightness.light,
            child: Material(
              child: Column(
                children: [
                  ExpressiveSwitchRow(
                    label: 'Background sync',
                    value: true,
                    onChanged: (_) {},
                  ),
                  ExpressiveMultiChoiceSegmentedButton<String>(
                    segments: const [
                      ExpressiveButtonSegment('B', 'Bold'),
                      ExpressiveButtonSegment('I', 'Italic'),
                    ],
                    value: const {'B'},
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final name in ['Background sync', 'Bold', 'Italic']) {
        final node = tester.getSemantics(find.bySemanticsLabel(name));
        expect(
          node,
          isSemantics(
            label: name,
            hasToggledState: true,
            isToggled: name != 'Italic',
            isButton: false,
            hasTapAction: true,
          ),
        );
      }
    },
  );
  for (final row in [false, true]) {
    final name = row ? 'ExpressiveRadioRow' : 'ExpressiveRadio';
    testWidgets('$name keeps the focus node supplied by its caller', (
      tester,
    ) async {
      final original = FocusNode();
      final replacement = FocusNode();
      final before = FocusNode();
      final after = FocusNode();
      for (final node in [original, replacement, before, after]) {
        addTearDown(node.dispose);
      }
      var originalChanges = 0;
      var replacementChanges = 0;
      original.addListener(() => originalChanges++);
      replacement.addListener(() => replacementChanges++);
      var selected = 'B';

      Future<void> mount(FocusNode node, {bool includeB = true}) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ExpressiveHost(
              light: _theme,
              brightness: Brightness.light,
              child: Material(
                child: StatefulBuilder(
                  builder: (context, update) => Column(
                    children: [
                      TextButton(
                        focusNode: before,
                        onPressed: () {},
                        child: const Text('Before'),
                      ),
                      DesignRadioGroup<String>(
                        options: ['A', if (includeB) 'B'],
                        value: includeB ? selected : 'A',
                        onChanged: (v) => update(() => selected = v),
                        focusNodeFor: (v) => v == 'B' ? node : null,
                        itemBuilder: (context, value, focus, select) => row
                            ? ExpressiveRadioRow(
                                label: value,
                                selected: selected == value,
                                focusNode: focus,
                                onPressed: select,
                              )
                            : ExpressiveRadio(
                                semanticLabel: value,
                                selected: selected == value,
                                focusNode: focus,
                                onPressed: select,
                              ),
                      ),
                      TextButton(
                        focusNode: after,
                        onPressed: () {},
                        child: const Text('After'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> enter(FocusNode node) async {
        before.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, same(node));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, same(after));
      }

      await mount(original);
      await enter(original);
      await mount(original);
      original.requestFocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(original));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(selected, 'A');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(selected, 'B');
      expect(FocusManager.instance.primaryFocus, same(original));
      await mount(replacement);
      await enter(replacement);
      replacement.requestFocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(replacement));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(selected, 'A');
      await mount(replacement, includeB: false);
      expect(replacement.parent, isNull);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Focus(focusNode: original, child: const SizedBox()),
              Focus(focusNode: replacement, child: const SizedBox()),
            ],
          ),
        ),
      );
      final previousOriginalChanges = originalChanges;
      final previousReplacementChanges = replacementChanges;
      for (final node in [original, replacement]) {
        node.requestFocus();
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, same(node));
      }
      expect(originalChanges, greaterThan(previousOriginalChanges));
      expect(replacementChanges, greaterThan(previousReplacementChanges));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('one Tab stop on the choice, and Down chooses the next', (
    tester,
  ) async {
    final h = _Harness(tester);
    await h.pump(value: 'A');
    await h.enter();
    expect(h.place(), 'A');
    await h.key(LogicalKeyboardKey.tab);
    expect(h.place(), 'after', reason: 'the next Tab leaves the group');

    await h.enter();
    await h.key(LogicalKeyboardKey.arrowDown);
    expect((h.chosen, h.place()), ('B', 'B'));
    await h.key(LogicalKeyboardKey.tab);
    expect(h.place(), 'after');
    await h.key(LogicalKeyboardKey.tab, shift: true);
    expect(h.place(), 'B', reason: 'Shift+Tab comes back to the choice');
    await h.key(LogicalKeyboardKey.tab, shift: true);
    expect(h.place(), 'before');
  });

  testWidgets('the arrows wrap at the ends and pass a disabled option', (
    tester,
  ) async {
    final h = _Harness(tester);
    await h.pump(value: 'A', disabled: {'B'});
    await h.enter();
    await h.key(LogicalKeyboardKey.arrowUp);
    expect((h.chosen, h.place()), ('C', 'C'), reason: 'Up from the first');
    await h.key(LogicalKeyboardKey.arrowDown);
    expect((h.chosen, h.place()), ('A', 'A'), reason: 'Down from the last');
    await h.key(LogicalKeyboardKey.arrowDown);
    expect((h.chosen, h.place()), ('C', 'C'), reason: 'B is disabled');
  });

  testWidgets('with nothing chosen, Tab lands on the first enabled option', (
    tester,
  ) async {
    final h = _Harness(tester);
    await h.pump(disabled: {'A'});
    await h.enter();
    expect((h.chosen, h.place()), (null, 'B'));
    await h.key(LogicalKeyboardKey.tab);
    expect(h.place(), 'after');
    await h.enter();
    await h.key(LogicalKeyboardKey.arrowDown);
    expect((h.chosen, h.place()), ('C', 'C'));
  });

  for (final textDirection in TextDirection.values) {
    testWidgets('Right and Left follow ${textDirection.name}', (tester) async {
      final rtl = textDirection == TextDirection.rtl;
      final h = _Harness(tester);
      await h.pump(value: 'A', textDirection: textDirection);
      await h.enter();
      await h.key(
        rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight,
      );
      expect((h.chosen, h.place()), ('B', 'B'), reason: 'the next');
      await h.key(
        rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft,
      );
      expect((h.chosen, h.place()), ('A', 'A'), reason: 'the previous');
    });
  }

  testWidgets('Space chooses the focused option', (tester) async {
    final h = _Harness(tester);
    await h.pump();
    await h.enter();
    expect(h.place(), 'A');
    await h.key(LogicalKeyboardKey.space);
    expect(h.chosen, 'A');
  });

  testWidgets('Enter, Space and a tap on the checked option report it', (
    tester,
  ) async {
    final reported = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) => ExpressiveHost(
          light: _theme,
          brightness: Brightness.light,
          child: app!,
        ),
        home: Material(
          child: ExpressiveRadioGroup<String>(
            value: 'B',
            onChanged: reported.add,
            options: const [
              ExpressiveRadioOption(value: 'A', label: 'A'),
              ExpressiveRadioOption(value: 'B', label: 'B'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final key in [
      LogicalKeyboardKey.tab,
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.space,
    ]) {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    expect(reported, ['B', 'B', 'B']);
  });

  testWidgets('a disabled group is no Tab stop', (tester) async {
    final h = _Harness(tester);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) => ExpressiveHost(
          light: _theme,
          brightness: Brightness.light,
          child: app!,
        ),
        home: Material(
          child: Column(
            children: [
              TextButton(
                focusNode: h.before,
                onPressed: () {},
                child: const Text('Before'),
              ),
              const KeyedSubtree(
                key: _group,
                child: ExpressiveRadioGroup<String>(
                  value: 'A',
                  options: [
                    ExpressiveRadioOption(value: 'A', label: 'A'),
                    ExpressiveRadioOption(value: 'B', label: 'B'),
                    ExpressiveRadioOption(value: 'C', label: 'C'),
                  ],
                ),
              ),
              TextButton(
                focusNode: h.after,
                onPressed: () {},
                child: const Text('After'),
              ),
            ],
          ),
        ),
      ),
    );
    addTearDown(h.before.dispose);
    addTearDown(h.after.dispose);
    await h.enter();
    expect(h.place(), 'after');
  });
}
