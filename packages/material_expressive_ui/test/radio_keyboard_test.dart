/// A radio group from the keyboard, as Flutter's `RadioGroup` is: one Tab
/// stop (the choice, or the first enabled option while there is none) that
/// the next Tab leaves, and arrows that choose the next or the previous
/// option, skipping disabled ones and wrapping at the ends, Left and Right
/// swapped in a right-to-left layout. Expressive's group kept Tab inside and
/// moved focus without choosing (the 11-18 API audit's radio probe).
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
