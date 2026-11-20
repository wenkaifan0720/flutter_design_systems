// Tab enters and leaves a group of answers. Arrow keys move the choice.
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

const _group = ValueKey('group');

void main() {
  late FocusNode before, after;
  late String? chosen;

  Future<void> pump(
    WidgetTester tester, {
    String? start = 'A',
    Set<String> disabled = const {},
    TextDirection direction = TextDirection.ltr,
    List<String> options = const ['A', 'B', 'C'],
    Widget Function(StateSetter)? buildChoice,
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
                      child: KeyedSubtree(
                        key: _group,
                        child:
                            buildChoice?.call(setState) ??
                            CivicRadioGroup<String>(
                              labelText: 'Which one?',
                              groupValue: chosen,
                              onChanged: (value) =>
                                  setState(() => chosen = value),
                              children: [
                                for (final value in options)
                                  CivicRadio<String>(
                                    value: value,
                                    labelText: value,
                                    enabled: !disabled.contains(value),
                                  ),
                              ],
                            ),
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

  Future<void> verifyGroup(WidgetTester tester) async {
    final report = await const DesignRadioGroupCheck(look: 'Civic').check(
      tester.element(find.byKey(_group)),
      before: before,
      sendKeyEvent: tester.sendKeyEvent,
      pump: tester.pump,
    );
    report.verify();
  }

  for (final direction in TextDirection.values) {
    const answers = ['A', 'B', 'C', 'D'];
    for (final initial in <String?>['C', null, 'B']) {
      for (final segmented in [false, true]) {
        final name = segmented ? 'segments' : 'radios';
        testWidgets('$name in ${direction.name} with initial answer $initial', (
          tester,
        ) async {
          await pump(
            tester,
            start: initial,
            options: answers,
            disabled: {'B'},
            direction: direction,
            buildChoice: segmented
                ? (setState) => CivicSegmentedControl<String>(
                    labelText: 'Period',
                    value: chosen,
                    segments: [
                      for (final answer in answers)
                        CivicSegment(
                          value: answer,
                          label: answer,
                          enabled: answer != 'B',
                        ),
                    ],
                    onChanged: (next) => setState(() => chosen = next),
                  )
                : null,
          );
          await verifyGroup(tester);
        });
      }
    }

    testWidgets('yes or no answers in ${direction.name}', (tester) async {
      await pump(
        tester,
        options: ['Yes', 'No'],
        start: null,
        direction: direction,
      );
      await verifyGroup(tester);
    });

    for (final initial in [const Color(0xFF0F4C81), const Color(0xFF123456)]) {
      testWidgets(
        'named swatches in ${direction.name} with initial colour $initial',
        (tester) async {
          final controller = DesignColorController(initial);
          addTearDown(controller.dispose);
          await pump(
            tester,
            direction: direction,
            buildChoice: (_) => CivicColorPicker(
              labelText: 'Badge colour',
              controller: controller,
              showCustom: false,
              swatches: const [
                CivicColorSwatch(Color(0xFF0F4C81), 'Harbour blue'),
                CivicColorSwatch(Color(0xFF0B6136), 'Park green'),
                CivicColorSwatch(Color(0xFF8A1C1C), 'Brick red'),
              ],
            ),
          );
          await verifyGroup(tester);
        },
      );
    }
  }

  testWidgets('a divider and helper stay between their answers', (
    tester,
  ) async {
    await pump(
      tester,
      buildChoice: (setState) => CivicRadioGroup<String>(
        labelText: 'Vehicle',
        groupValue: chosen,
        onChanged: (next) => setState(() => chosen = next),
        children: const [
          CivicRadio(value: 'A', labelText: 'Car'),
          CivicRadioDivider(label: 'or'),
          Text('Another way to travel'),
          CivicRadio(value: 'B', labelText: 'Motorcycle'),
        ],
      ),
    );
    final positions = [
      for (final label in ['Car', 'or', 'Another way to travel', 'Motorcycle'])
        tester.getCenter(find.text(label)).dy,
    ];
    expect(positions, orderedEquals([...positions]..sort()));
    await verifyGroup(tester);
  });

  testWidgets('caller focus nodes follow their answer and can be reused', (
    tester,
  ) async {
    final first = FocusNode();
    final replacement = FocusNode();
    final afterGroup = FocusNode();
    addTearDown(first.dispose);
    addTearDown(replacement.dispose);
    addTearDown(afterGroup.dispose);

    var notifications = 0;
    first.addListener(() => notifications++);
    replacement.addListener(() => notifications++);
    var activeNode = first;
    var answers = ['A', 'B'];
    var value = 'B';
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CivicTheme(
            data: CivicThemeData.light(),
            child: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return Column(
                  children: [
                    CivicRadioGroup<String>(
                      labelText: 'Answer',
                      groupValue: value,
                      onChanged: (next) => setState(() => value = next!),
                      children: [
                        for (final answer in answers)
                          CivicRadio<String>(
                            key: ValueKey(answer),
                            value: answer,
                            labelText: answer,
                            focusNode: answer == 'B' ? activeNode : null,
                          ),
                      ],
                    ),
                    TextButton(
                      focusNode: afterGroup,
                      onPressed: () {},
                      child: const Text('Continue'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    Future<void> focus(FocusNode node) async {
      final previous = notifications;
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, same(node));
      expect(notifications, greaterThan(previous));
    }

    await focus(first);
    rebuild(() => answers = ['B', 'A']);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, same(first));
    rebuild(() => activeNode = replacement);
    await tester.pumpAndSettle();
    afterGroup.requestFocus();
    await tester.pumpAndSettle();
    await focus(replacement);
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(value, 'A');
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(value, 'B');
    expect(FocusManager.instance.primaryFocus, same(replacement));
    await press(tester, LogicalKeyboardKey.tab);
    expect(FocusManager.instance.primaryFocus, same(afterGroup));
    rebuild(() => answers = ['A']);
    await tester.pumpAndSettle();
    expect(replacement.parent, isNull);
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            Focus(focusNode: first, child: const SizedBox()),
            Focus(focusNode: replacement, child: const SizedBox()),
          ],
        ),
      ),
    );
    await focus(first);
    await focus(replacement);
  });

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

  testWidgets('Enter and Space press an answer, the chosen one too', (
    tester,
  ) async {
    final presses = <String?>[];
    await pump(
      tester,
      buildChoice: (setState) => CivicRadioGroup<String>(
        labelText: 'Which one?',
        groupValue: chosen,
        onChanged: (value) => setState(() {
          presses.add(value);
          chosen = value;
        }),
        children: [
          for (final value in ['A', 'B', 'C'])
            CivicRadio<String>(value: value, labelText: value),
        ],
      ),
    );
    before.requestFocus();
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.tab);
    expect(place(), 'A');
    await press(tester, LogicalKeyboardKey.enter);
    await press(tester, LogicalKeyboardKey.space);
    expect(presses, ['A', 'A'], reason: 'the chosen answer, pressed twice');
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(presses, ['A', 'A', 'B']);
    await press(tester, LogicalKeyboardKey.space);
    expect(presses, ['A', 'A', 'B', 'B']);
    expect((chosen, place()), ('B', 'B'));
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
