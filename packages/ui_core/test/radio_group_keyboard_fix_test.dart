// The cases of Flutter's two RadioGroup fixes, each with a
// RadioGroupKeyboardFix inserted inside the RadioGroup (see `fixed`) and
// nothing else changed: flutter/flutter#197073's (the Tab stop, "Radio group
// Tab stop" and the RadioListTile case) and the right-to-left branch
// 4b0bb03252's ("Radio group arrow keys" and the Radio case). Once a fix is in
// a Flutter stable that ui_core's floor covers, its shim goes and these pass
// as they are.
//
// Flutter's helpers come with them: TestRadio and TestRadioGroup (its
// radio_tester.dart and radio_group_tester.dart), a bare app for
// TestWidgetsApp, and a plain focusable for TestTextField, which the cases use
// only as a place for focus before and after the group. The right-to-left
// branch's two Cupertino cases test CupertinoSegmentedControl and
// CupertinoSlidingSegmentedControl, which build their RadioGroup inside, out
// of a look's reach: they have no counterpart here.
import 'package:material_ui/material_ui.dart'
    show MaterialApp, Material, Radio, RadioListTile, TextButton;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

/// [child] with the fix, as a look's group holds its radios.
Widget fixed<T>(Widget child) => RadioGroupKeyboardFix<T>(child: child);

class TestRadioGroup<T> extends StatefulWidget {
  const TestRadioGroup({super.key, required this.child});

  final Widget child;

  @override
  State<StatefulWidget> createState() => TestRadioGroupState<T>();
}

class TestRadioGroupState<T> extends State<TestRadioGroup<T>> {
  T? groupValue;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
      onChanged: (T? newValue) {
        setState(() {
          groupValue = newValue;
        });
      },
      groupValue: groupValue,
      child: fixed<T>(widget.child),
    );
  }
}

class TestRadio<T> extends StatefulWidget {
  const TestRadio({
    super.key,
    required this.value,
    this.focusNode,
    this.enabled = true,
  });

  final T value;

  final FocusNode? focusNode;

  final bool enabled;

  @override
  State<TestRadio<T>> createState() => TestRadioState<T>();
}

class TestRadioState<T> extends State<TestRadio<T>> {
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawRadio<T>(
      value: widget.value,
      mouseCursor: WidgetStateProperty.all<MouseCursor>(
        SystemMouseCursors.click,
      ),
      toggleable: false,
      focusNode: _effectiveFocusNode,
      autofocus: false,
      groupRegistry: widget.enabled ? RadioGroup.maybeOf<T>(context) : null,
      enabled: widget.enabled,
      builder: (BuildContext context, ToggleableStateMixin state) {
        return SizedBox(
          width: 18,
          height: 18,
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state.value ?? false
                    ? const Color(0xFF000000)
                    : const Color(0x00000000),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TestWidgetsApp extends StatelessWidget {
  const TestWidgetsApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) => WidgetsApp(
    color: const Color(0xFF000000),
    debugShowCheckedModeBanner: false,
    pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
        PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        ),
    home: home,
  );
}

class TestTextField extends StatelessWidget {
  const TestTextField({super.key, required this.focusNode});

  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: focusNode,
    child: const SizedBox(width: 100, height: 20),
  );
}

void main() {
  // flutter/flutter#197073, test/material/radio_list_tile_test.dart.
  testWidgets(
    'RadioGroup keeps one Tab stop when the selected RadioListTile is disabled',
    (WidgetTester tester) async {
      final before = FocusNode();
      addTearDown(before.dispose);
      final tileA = FocusNode();
      addTearDown(tileA.dispose);
      final after = FocusNode();
      addTearDown(after.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                TextButton(
                  focusNode: before,
                  onPressed: () {},
                  child: const Text('Before'),
                ),
                RadioGroup<String>(
                  groupValue: 'B',
                  onChanged: (String? value) =>
                      fail('Tab traversal changed the selection to $value'),
                  child: fixed<String>(
                    Column(
                      children: <Widget>[
                        RadioListTile<String>(
                          value: 'A',
                          focusNode: tileA,
                          title: const Text('A'),
                        ),
                        const RadioListTile<String>(
                          value: 'B',
                          enabled: false,
                          title: Text('B'),
                        ),
                        const RadioListTile<String>(
                          value: 'C',
                          title: Text('C'),
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
      );

      // The selected tile is disabled and can't take focus, so focus moves to
      // the first enabled tile instead of skipping the group.
      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(tileA.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(after.hasPrimaryFocus, isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(tileA.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();
      expect(before.hasPrimaryFocus, isTrue);
    },
  );

  // flutter/flutter#197073, test/widgets/radio_group_test.dart.
  group('Radio group Tab stop', () {
    // Builds radios 0, 1 and 2 in a radio group whose value is 1, between two
    // text fields. Checks that Tab and Shift+Tab stop once in the group, on the
    // radio with the value [expected], and that moving focus doesn't change the
    // selection.
    Future<void> expectSingleTabStop(
      WidgetTester tester, {
      required int expected,
      bool excludeSelected = false,
      int? nested,
      int? inSkippedScope,
    }) async {
      final before = FocusNode();
      addTearDown(before.dispose);
      final after = FocusNode();
      addTearDown(after.dispose);
      final radios = <FocusNode>[FocusNode(), FocusNode(), FocusNode()];
      for (final radio in radios) {
        addTearDown(radio.dispose);
      }

      Widget buildRadio(int value) {
        Widget radio = TestRadio<int>(value: value, focusNode: radios[value]);
        if (value == 1 && excludeSelected) {
          radio = ExcludeFocus(child: radio);
        }
        if (value == nested) {
          radio = FocusTraversalGroup(child: radio);
        }
        if (value == inSkippedScope) {
          radio = FocusScope(skipTraversal: true, child: radio);
        }
        return radio;
      }

      await tester.pumpWidget(
        TestWidgetsApp(
          home: Column(
            children: <Widget>[
              TestTextField(focusNode: before),
              RadioGroup<int>(
                groupValue: 1,
                onChanged: (int? value) =>
                    fail('Tab traversal changed the selection to $value'),
                child: fixed<int>(
                  Column(
                    children: <Widget>[
                      for (var i = 0; i < 3; i++) buildRadio(i),
                    ],
                  ),
                ),
              ),
              TestTextField(focusNode: after),
            ],
          ),
        ),
      );

      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(radios[expected].hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(after.hasPrimaryFocus, isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(radios[expected].hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();
      expect(before.hasPrimaryFocus, isTrue);
    }

    testWidgets(
      'falls back to the first radio when the selected radio cannot take focus',
      (WidgetTester tester) async {
        await expectSingleTabStop(tester, excludeSelected: true, expected: 0);
      },
    );

    testWidgets(
      'stays on the selected radio inside a nested FocusTraversalGroup',
      (WidgetTester tester) async {
        await expectSingleTabStop(tester, nested: 1, expected: 1);
      },
    );

    testWidgets(
      'is the radio in a nested FocusTraversalGroup before the selected radio',
      (WidgetTester tester) async {
        await expectSingleTabStop(
          tester,
          excludeSelected: true,
          nested: 0,
          expected: 0,
        );
      },
    );

    testWidgets(
      'is the radio in a nested FocusTraversalGroup after the selected radio',
      (WidgetTester tester) async {
        await expectSingleTabStop(
          tester,
          excludeSelected: true,
          nested: 2,
          expected: 2,
        );
      },
    );

    testWidgets('skips a radio in a FocusScope that traversal skips', (
      WidgetTester tester,
    ) async {
      await expectSingleTabStop(
        tester,
        excludeSelected: true,
        inSkippedScope: 0,
        expected: 2,
      );
    });

    testWidgets(
      'stays on the selected radio when traversal starts inside a skipped FocusScope',
      (WidgetTester tester) async {
        final inside = FocusNode();
        addTearDown(inside.dispose);
        final radios = <FocusNode>[FocusNode(), FocusNode()];
        for (final radio in radios) {
          addTearDown(radio.dispose);
        }

        await tester.pumpWidget(
          TestWidgetsApp(
            home: RadioGroup<int>(
              groupValue: 1,
              onChanged: (int? value) =>
                  fail('Tab traversal changed the selection to $value'),
              child: fixed<int>(
                FocusScope(
                  skipTraversal: true,
                  child: Column(
                    children: <Widget>[
                      TestRadio<int>(value: 0, focusNode: radios[0]),
                      TestRadio<int>(value: 1, focusNode: radios[1]),
                      TestTextField(focusNode: inside),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        inside.requestFocus();
        await tester.pump();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pump();
        expect(radios[1].hasPrimaryFocus, isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(inside.hasPrimaryFocus, isTrue);
      },
    );
  });

  group('Radio group arrow keys', () {
    // Branch 4b0bb03252, test/material/radio_test.dart.
    for (final (LogicalKeyboardKey key, int expected)
        in <(LogicalKeyboardKey, int)>[
          (LogicalKeyboardKey.arrowRight, 0),
          (LogicalKeyboardKey.arrowLeft, 2),
        ]) {
      testWidgets(
        'RTL ${key.keyLabel} selects the adjacent radio from a disabled radio with focus',
        (WidgetTester tester) async {
          final nodes = <FocusNode>[FocusNode(), FocusNode(), FocusNode()];
          for (final node in nodes) {
            addTearDown(node.dispose);
          }
          int? value = 1;
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(
                  navigationMode: NavigationMode.directional,
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Material(
                    child: StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) =>
                          RadioGroup<int>(
                            groupValue: value,
                            onChanged: (int? next) => setState(() {
                              value = next;
                            }),
                            child: fixed<int>(
                              Row(
                                children: <Widget>[
                                  for (var i = 0; i < nodes.length; i++)
                                    Radio<int>(
                                      value: i,
                                      focusNode: nodes[i],
                                      enabled: i != 1,
                                    ),
                                ],
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(nodes[1].hasPrimaryFocus, isTrue);
          expect(value, 1);
          await tester.sendKeyEvent(key);
          await tester.pump();
          expect(nodes[expected].hasPrimaryFocus, isTrue);
          expect(value, expected);
        },
      );
    }

    // Branch 4b0bb03252, test/widgets/radio_group_test.dart.
    for (final (
          String layout,
          TextDirection groupDirection,
          TextDirection radioDirection,
          Axis axis,
          int right,
          int left,
        )
        in <(String, TextDirection, TextDirection, Axis, int, int)>[
          (
            'an RTL row',
            TextDirection.rtl,
            TextDirection.rtl,
            Axis.horizontal,
            0,
            2,
          ),
          (
            'an RTL row in an LTR group',
            TextDirection.ltr,
            TextDirection.rtl,
            Axis.horizontal,
            0,
            2,
          ),
          (
            'an LTR row in an RTL group',
            TextDirection.rtl,
            TextDirection.ltr,
            Axis.horizontal,
            2,
            0,
          ),
          (
            'an RTL column',
            TextDirection.rtl,
            TextDirection.rtl,
            Axis.vertical,
            0,
            2,
          ),
        ]) {
      testWidgets(
        'Radio group left and right arrow keys follow the text direction of $layout',
        (WidgetTester tester) async {
          final nodes = <FocusNode>[FocusNode(), FocusNode(), FocusNode()];
          for (final node in nodes) {
            addTearDown(node.dispose);
          }
          Widget buildGroup(TextDirection radioDirection) {
            return TestWidgetsApp(
              home: Directionality(
                textDirection: groupDirection,
                child: TestRadioGroup<int>(
                  child: Directionality(
                    textDirection: radioDirection,
                    child: Flex(
                      direction: axis,
                      children: <Widget>[
                        for (var i = 0; i < 3; i++)
                          TestRadio<int>(value: i, focusNode: nodes[i]),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          // Focus the middle radio in the other text direction, then switch, to
          // check that the arrow keys read the direction when they are pressed.
          await tester.pumpWidget(
            buildGroup(
              radioDirection == TextDirection.rtl
                  ? TextDirection.ltr
                  : TextDirection.rtl,
            ),
          );
          nodes[1].requestFocus();
          await tester.pump();
          await tester.pumpWidget(buildGroup(radioDirection));
          expect(nodes[1].hasPrimaryFocus, isTrue);

          final TestRadioGroupState<int> state = tester
              .state<TestRadioGroupState<int>>(
                find.byType(TestRadioGroup<int>),
              );
          Future<void> press(LogicalKeyboardKey key, int expected) async {
            await tester.sendKeyEvent(key);
            await tester.pump();
            expect(state.groupValue, expected);
            expect(nodes[expected].hasPrimaryFocus, isTrue);
          }

          await press(LogicalKeyboardKey.arrowRight, right);
          await press(LogicalKeyboardKey.arrowLeft, 1);
          await press(LogicalKeyboardKey.arrowLeft, left);
          // Both keys wrap around.
          await press(LogicalKeyboardKey.arrowLeft, right);
          await press(LogicalKeyboardKey.arrowRight, left);
          // Down selects the next radio and Up the previous one, in either direction.
          nodes[1].requestFocus();
          await tester.pump();
          await press(LogicalKeyboardKey.arrowDown, 2);
          await press(LogicalKeyboardKey.arrowUp, 1);
        },
      );
    }

    testWidgets(
      'Radio group left and right arrow keys keep their mapping when text directions differ',
      (WidgetTester tester) async {
        final nodes = <FocusNode>[FocusNode(), FocusNode(), FocusNode()];
        for (final node in nodes) {
          addTearDown(node.dispose);
        }
        int? selected;
        // A right-to-left row whose first two radios are each in left-to-right
        // text, shown as 2, 1, 0 from left to right. Starts from radio 2, on the
        // left, focused and selected.
        Future<void> pressFromRadio2(
          LogicalKeyboardKey key,
          int expected,
        ) async {
          selected = null;
          await tester.pumpWidget(
            TestWidgetsApp(
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: RadioGroup<int>(
                  groupValue: 2,
                  onChanged: (int? value) => selected = value,
                  child: fixed<int>(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (var i = 0; i < 2; i++)
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: TestRadio<int>(
                              value: i,
                              focusNode: nodes[i],
                            ),
                          ),
                        TestRadio<int>(value: 2, focusNode: nodes[2]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          nodes[2].requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(key);
          await tester.pump();
          expect(selected, expected);
          expect(nodes[expected].hasPrimaryFocus, isTrue);
        }

        // Right selects the adjacent radio 1, and Left wraps around to radio 0.
        await pressFromRadio2(LogicalKeyboardKey.arrowRight, 1);
        await pressFromRadio2(LogicalKeyboardKey.arrowLeft, 0);
      },
    );
  });
}
