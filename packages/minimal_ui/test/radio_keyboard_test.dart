// A radio group from the keyboard, as Flutter's RadioGroup is: one Tab stop
// (the choice, or the first option while there is none) that the next Tab
// leaves, and arrows that choose the next or the previous option, skipping
// disabled ones and wrapping at the ends, Left and Right swapped in a
// right-to-left layout. Minimal's group kept Tab inside and moved focus
// without choosing (the 11-18 API audit's radio probe).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
