// A radio group is one stop for Tab, as Flutter's RadioGroup and a browser's radios are: Tab and Shift+Tab come to the
// chosen answer and leave the group, and the arrow keys move the choice. A second Tab stayed inside the group, walking
// its answers one by one. The fixture is the API audit's: the group between two buttons, real key events.
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _group = ValueKey('group');

void main() {
  late FocusNode before, after;
  late String? chosen;

  Future<void> pump(
    WidgetTester tester, {
    String? start = 'A',
    Set<String> disabled = const {},
    TextDirection direction = TextDirection.ltr,
  }) async {
    before = FocusNode();
    after = FocusNode();
    addTearDown(before.dispose);
    addTearDown(after.dispose);
    chosen = start;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: SizedBox(
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
                    CivicTheme(
                      data: CivicThemeData.light(),
                      child: CivicRadioGroup<String>(
                        key: _group,
                        labelText: 'Which one?',
                        groupValue: chosen,
                        onChanged: (value) => setState(() => chosen = value),
                        children: [
                          for (final value in ['A', 'B', 'C'])
                            CivicRadio<String>(
                              value: value,
                              labelText: value,
                              enabled: !disabled.contains(value),
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
    );
    await tester.pumpAndSettle();
  }

  /// Where the focus is: 'before', 'after', the answer it is on, or 'elsewhere'.
  String place() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == before) return 'before';
    if (focus == after) return 'after';
    String? answer;
    focus?.context?.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is CivicRadio<String>) answer = widget.value;
      return answer == null && widget.key != _group;
    });
    return answer ?? 'elsewhere';
  }

  Future<void> press(
    WidgetTester tester,
    LogicalKeyboardKey key, {
    bool shift = false,
  }) async {
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
  }

  testWidgets('Tab comes to the chosen answer and leaves the group', (
    tester,
  ) async {
    await pump(tester, start: 'B');
    before.requestFocus();
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.tab);
    expect(place(), 'B');
    await press(tester, LogicalKeyboardKey.tab);
    expect(place(), 'after');
    await press(tester, LogicalKeyboardKey.tab, shift: true);
    expect(place(), 'B');
    await press(tester, LogicalKeyboardKey.tab, shift: true);
    expect(place(), 'before');
    expect(chosen, 'B', reason: 'Tab chooses nothing');
  });

  testWidgets('with no answer chosen, Tab comes to the first and leaves', (
    tester,
  ) async {
    await pump(tester, start: null);
    before.requestFocus();
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.tab);
    expect(place(), 'A');
    await press(tester, LogicalKeyboardKey.tab);
    expect(place(), 'after');
    expect(chosen, isNull);
  });

  testWidgets('the arrow keys move the choice, and the focus with it', (
    tester,
  ) async {
    await pump(tester);
    before.requestFocus();
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.tab);
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect((chosen, place()), ('B', 'B'));
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect((chosen, place()), ('C', 'C'));
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect((chosen, place()), ('A', 'A'), reason: 'it wraps round');
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect((chosen, place()), ('C', 'C'));
    await press(tester, LogicalKeyboardKey.arrowLeft);
    expect((chosen, place()), ('B', 'B'));
    // After the arrows, Tab still leaves from the answer they chose.
    await press(tester, LogicalKeyboardKey.tab);
    expect(place(), 'after');
  });

  testWidgets('right to left, Left moves on and Right moves back', (
    tester,
  ) async {
    await pump(tester, direction: TextDirection.rtl);
    before.requestFocus();
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.tab);
    await press(tester, LogicalKeyboardKey.arrowLeft);
    expect((chosen, place()), ('B', 'B'));
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect((chosen, place()), ('A', 'A'));
    await press(tester, LogicalKeyboardKey.tab);
    expect(place(), 'after');
  });

  testWidgets('the arrow keys pass over an answer that cannot be chosen', (
    tester,
  ) async {
    await pump(tester, disabled: {'B'});
    before.requestFocus();
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.tab);
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect((chosen, place()), ('C', 'C'));
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect((chosen, place()), ('A', 'A'));
  });
}
