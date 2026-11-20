// A radio group from the keyboard, as Flutter's RadioGroup is: one Tab stop
// (the choice, or the first option while there is none) that the next Tab
// leaves, and arrows that choose the next or the previous option, skipping
// disabled ones and wrapping at the ends, Left and Right swapped in a
// right-to-left layout. Minimal's group once kept Tab inside and moved
// focus without choosing. Each radio, checkbox and switch reads as that
// control and never as a button, and radios that draw their own rows group
// in ui_core's DesignRadioGroup on their callers' own focus nodes.
import 'dart:ui' show CheckedState, SemanticsFlags, Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

const _group = ValueKey('group');

class _Harness {
  _Harness(this.tester);

  final WidgetTester tester;
  final before = FocusNode();
  final after = FocusNode();
  String? chosen;

  Future<void> pump({
    String? value,
    Set<String> disabled = const {},
    Axis direction = Axis.vertical,
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    chosen = value;
    addTearDown(before.dispose);
    addTearDown(after.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: textDirection,
          child: MinimalTheme(
            data: MinimalThemeData.standard(),
            child: Material(
              child: SizedBox(
                width: 420,
                child: StatefulBuilder(
                  builder: (context, setState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        focusNode: before,
                        onPressed: () {},
                        child: const Text('Before'),
                      ),
                      SizedBox(
                        key: _group,
                        child: MinimalRadioGroup<String>(
                          value: chosen,
                          direction: direction,
                          onChanged: (v) => setState(() => chosen = v),
                          options: [
                            for (final v in const ['A', 'B', 'C'])
                              MinimalRadioOption<String>(
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
    final at = focus?.context;
    if (at == null) return 'elsewhere';
    for (final v in const ['A', 'B', 'C']) {
      final words = find
          .descendant(of: find.byKey(_group), matching: find.text(v))
          .evaluate()
          .single;
      var inside = false;
      words.visitAncestorElements((e) {
        inside = e == at;
        return !inside;
      });
      if (inside) return v;
    }
    return 'elsewhere';
  }

  Future<void> key(LogicalKeyboardKey key, {bool shift = false}) async {
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(key);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pumpAndSettle();
  }

  Future<void> enter() async {
    before.requestFocus();
    await tester.pumpAndSettle();
    await key(LogicalKeyboardKey.tab);
  }
}

void main() {
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

  testWidgets('with nothing chosen, Tab lands on the first option', (
    tester,
  ) async {
    final h = _Harness(tester);
    await h.pump();
    await h.enter();
    expect((h.chosen, h.place()), (null, 'A'));
    await h.key(LogicalKeyboardKey.tab);
    expect(h.place(), 'after');
    await h.enter();
    await h.key(LogicalKeyboardKey.arrowDown);
    expect((h.chosen, h.place()), ('B', 'B'));
  });

  for (final textDirection in TextDirection.values) {
    testWidgets('a row\'s Left and Right follow ${textDirection.name}', (
      tester,
    ) async {
      final rtl = textDirection == TextDirection.rtl;
      final h = _Harness(tester);
      await h.pump(
        value: 'A',
        direction: Axis.horizontal,
        textDirection: textDirection,
      );
      await h.enter();
      await h.key(
        rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight,
      );
      expect((h.chosen, h.place()), ('B', 'B'), reason: 'the next');
      await h.key(
        rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft,
      );
      expect((h.chosen, h.place()), ('A', 'A'), reason: 'the previous');
      // The next option stands on the reading side.
      final a = tester.getCenter(find.text('A')).dx;
      final b = tester.getCenter(find.text('B')).dx;
      expect(rtl ? b < a : b > a, isTrue);
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
  // A, B, C and D with B turned off, chosen C, nothing or B, in each
  // direction: ui_core_test's check of the one Tab stop and the arrows, and
  // after a move one radio checked, each a radio and none a button.
  for (final textDirection in TextDirection.values) {
    for (final initial in <String?>['C', null, 'B']) {
      testWidgets('the shared radio group check, ${textDirection.name}, '
          'chosen ${initial ?? 'none'}', (tester) async {
        final semantics = tester.ensureSemantics();
        final before = FocusNode();
        addTearDown(before.dispose);
        var chosen = initial;
        await tester.pumpWidget(
          _app(
            textDirection,
            StatefulBuilder(
              builder: (context, setState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Focus(focusNode: before, child: const Text('Before')),
                  MinimalRadioGroup<String>(
                    key: _group,
                    label: 'Plan',
                    value: chosen,
                    onChanged: (v) => setState(() => chosen = v),
                    options: [
                      for (final v in const ['A', 'B', 'C', 'D'])
                        MinimalRadioOption<String>(
                          value: v,
                          label: v,
                          enabled: v != 'B',
                        ),
                    ],
                  ),
                  const Focus(child: Text('After')),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        (await const DesignRadioGroupCheck(look: 'Minimal').check(
          tester.element(find.byKey(_group)),
          before: before,
          sendKeyEvent: tester.sendKeyEvent,
          pump: tester.pump,
        )).verify();
        before.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(chosen, isNotNull);
        for (final v in const ['A', 'B', 'C', 'D']) {
          final flags = tester
              .getSemantics(find.bySemanticsLabel(v))
              .getSemanticsData()
              .flagsCollection;
          expect(
            flags.isChecked,
            v == chosen ? CheckedState.isTrue : CheckedState.isFalse,
            reason: v,
          );
          expect(flags.isInMutuallyExclusiveGroup, isTrue, reason: v);
          expect(flags.isButton, isFalse, reason: v);
        }
        semantics.dispose();
      });
    }
  }

  testWidgets('a checkbox, a switch, a radio, a choice row and a status '
      'control read as themselves, a button as a button', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        TextDirection.ltr,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MinimalCheckbox(value: true, label: 'Box', onChanged: (_) {}),
            const MinimalCheckbox(
              value: false,
              label: 'Box off',
              onChanged: null,
            ),
            MinimalSwitch(value: true, label: 'Switch', onChanged: (_) {}),
            const MinimalSwitch(value: false, label: 'Switch off'),
            MinimalRadio(selected: true, label: 'Radio', onPressed: () {}),
            MinimalChoiceRow(title: 'Row', selected: false, onPressed: () {}),
            MinimalStatusIcon(
              MinimalTaskStatus.done,
              semanticLabel: 'Status',
              onPressed: () {},
            ),
            MinimalButton('Save', onPressed: () {}),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    SemanticsFlags flagsOf(String name) => tester
        .getSemantics(find.bySemanticsLabel(name))
        .getSemanticsData()
        .flagsCollection;
    expect(flagsOf('Box').isChecked, CheckedState.isTrue);
    expect(flagsOf('Box off').isChecked, CheckedState.isFalse);
    expect(flagsOf('Switch').isToggled, Tristate.isTrue);
    expect(flagsOf('Switch off').isToggled, Tristate.isFalse);
    expect(flagsOf('Radio').isChecked, CheckedState.isTrue);
    expect(flagsOf('Radio').isInMutuallyExclusiveGroup, isTrue);
    expect(flagsOf('Row').isChecked, CheckedState.isFalse);
    expect(flagsOf('Row').isInMutuallyExclusiveGroup, isTrue);
    expect(flagsOf('Status').isChecked, CheckedState.isTrue);
    for (final name in const [
      'Box',
      'Box off',
      'Switch',
      'Switch off',
      'Radio',
      'Row',
      'Status',
    ]) {
      expect(flagsOf(name).isButton, isFalse, reason: name);
    }
    expect(flagsOf('Save').isButton, isTrue);
    semantics.dispose();
  });

  testWidgets('radios that draw their own rows keep their callers\' nodes in '
      'a DesignRadioGroup', (tester) async {
    final before = FocusNode();
    final after = FocusNode();
    final nodes = {
      for (final v in const ['A', 'B', 'C', 'D']) v: FocusNode(debugLabel: v),
    };
    final second = FocusNode(debugLabel: 'C, second');
    for (final node in [before, after, second, ...nodes.values]) {
      addTearDown(node.dispose);
    }
    var options = const ['A', 'B', 'C', 'D'];
    String? chosen = 'A';
    var nodeOfC = nodes['C']!;
    var grouped = true;
    late StateSetter rebuild;
    await tester.pumpWidget(
      _app(
        TextDirection.ltr,
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Focus(focusNode: before, child: const Text('Before')),
                if (grouped)
                  DesignRadioGroup<String>(
                    key: _group,
                    options: options,
                    value: chosen,
                    onChanged: (v) => setState(() => chosen = v),
                    isEnabled: (v) => v != 'B',
                    focusNodeFor: (v) => v == 'C' ? nodeOfC : nodes[v],
                    itemBuilder: (context, v, node, select) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MinimalRadio(
                          selected: v == chosen,
                          label: v,
                          enabled: select != null,
                          onPressed: select,
                          focusNode: node,
                        ),
                        Text(v),
                      ],
                    ),
                  )
                else
                  // A focusable of its own: B's radio, turned off, had set
                  // its node to take no focus.
                  for (final node in [second, ...nodes.values])
                    Focus(
                      focusNode: node,
                      canRequestFocus: true,
                      child: Text('${node.debugLabel}'),
                    ),
                Focus(focusNode: after, child: const Text('After')),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> key(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    FocusNode? focus() => FocusManager.instance.primaryFocus;

    (await const DesignRadioGroupCheck(look: 'Minimal').check(
      tester.element(find.byKey(_group)),
      before: before,
      sendKeyEvent: tester.sendKeyEvent,
      pump: tester.pump,
    )).verify();

    // The caller focuses a radio through its own node, which a rebuild keeps.
    chosen = 'A';
    rebuild(() {});
    await tester.pumpAndSettle();
    nodes['A']!.requestFocus();
    await tester.pumpAndSettle();
    expect(focus(), same(nodes['A']));
    rebuild(() {});
    await tester.pumpAndSettle();
    expect(focus(), same(nodes['A']));
    await key(LogicalKeyboardKey.arrowDown);
    expect(chosen, 'C');
    expect(focus(), same(nodeOfC));

    // A second node for C takes its place: focus, the arrows and the one
    // Tab stop run on it.
    nodeOfC = second;
    rebuild(() {});
    await tester.pumpAndSettle();
    second.requestFocus();
    await tester.pumpAndSettle();
    expect(focus(), same(second));
    await key(LogicalKeyboardKey.arrowDown);
    expect(chosen, 'D');
    expect(focus(), same(nodes['D']));
    await key(LogicalKeyboardKey.arrowUp);
    expect(chosen, 'C');
    expect(focus(), same(second));
    before.requestFocus();
    await tester.pumpAndSettle();
    await key(LogicalKeyboardKey.tab);
    expect(focus(), same(second));
    await key(LogicalKeyboardKey.tab);
    expect(focus(), same(after));

    // Without D, then without the group, every node is still the caller's:
    // each takes the focus again on a focusable of its own.
    options = const ['A', 'B', 'C'];
    rebuild(() {});
    await tester.pumpAndSettle();
    expect(find.text('D'), findsNothing);
    rebuild(() => grouped = false);
    await tester.pumpAndSettle();
    for (final node in [second, ...nodes.values]) {
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(focus(), same(node), reason: node.debugLabel);
    }
  });
}

/// [child] in Minimal's light theme, read in [textDirection].
Widget _app(TextDirection textDirection, Widget child) => MaterialApp(
  home: Directionality(
    textDirection: textDirection,
    child: MinimalTheme(
      data: MinimalThemeData.standard(),
      child: Material(child: SizedBox(width: 420, child: child)),
    ),
  ),
);
