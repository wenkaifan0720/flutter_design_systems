import 'dart:ui' show CheckedState;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);
  testWidgets(
    'checkbox removes unchecked ink while preserving mixed and error marks',
    (tester) async {
      bool? value = false;
      var error = false;
      late StateSetter update;
      await tester.pumpWidget(
        neumorphicApp(
          Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return NeumorphicCheckbox(
                  value: value,
                  error: error,
                  tristate: true,
                  label: 'Terms',
                  onChanged: (_) {},
                );
              },
            ),
          ),
        ),
      );
      final initialSize = tester.getSize(find.byType(NeumorphicCheckbox));
      expect(find.byType(Icon), findsNothing);
      for (final next in [true, null, false]) {
        update(() => value = next);
        await tester.pumpAndSettle();
        expect(tester.getSize(find.byType(NeumorphicCheckbox)), initialSize);
        expect(
          find.byIcon(NeumorphicGlyphs.check),
          next == true ? findsOneWidget : findsNothing,
        );
        expect(
          find.byIcon(NeumorphicGlyphs.minus),
          next == null ? findsOneWidget : findsNothing,
        );
      }
      update(() => error = true);
      await tester.pumpAndSettle();
      // The box keeps showing its value; the error is its edge and the message under it.
      expect(find.byType(Icon), findsNothing);
      expect(tester.getSize(find.byType(NeumorphicCheckbox)), initialSize);
    },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets('search clear reports once and keeps the field focused', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'A room');
    final node = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(node.dispose);
    final changes = <String>[];
    await tester.pumpWidget(
      neumorphicApp(
        Center(
          child: NeumorphicSearchField(
            hint: 'Search',
            controller: controller,
            focusNode: node,
            onChanged: changes.add,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(NeumorphicRoundButton));
    await tester.pump();
    expect(controller.text, '');
    expect(changes, ['']);
    expect(node.hasFocus, isTrue);
    expect(find.byType(NeumorphicRoundButton), findsNothing);
    await tester.enterText(find.byType(EditableText), 'New');
    await tester.pump();
    expect(find.byType(NeumorphicRoundButton), findsOneWidget);
  });
  testWidgets(
    'controller changes remove old listeners without disposing caller controllers',
    (tester) async {
      final old = TextEditingController(text: 'Old'),
          next = TextEditingController(text: 'New');
      addTearDown(old.dispose);
      addTearDown(next.dispose);
      for (final code in [false, true]) {
        Widget make(TextEditingController controller) => neumorphicApp(
          Center(
            child: code
                ? NeumorphicInputOtp(controller: controller, label: 'Code')
                : NeumorphicSearchField(controller: controller, hint: 'Search'),
          ),
        );
        await tester.pumpWidget(make(old));
        await tester.pumpWidget(make(next));
        old.text = 'Unused';
        next.text = '123';
        await tester.pump();
        expect(
          tester.widget<EditableText>(find.byType(EditableText)).controller,
          same(next),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        old.text = 'Still owned';
        next.text = 'Still owned';
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'code is one editable value, filters pasted digits and completes once',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final completed = <String>[];
      await tester.pumpWidget(
        neumorphicApp(
          Center(
            child: NeumorphicInputOtp(
              controller: controller,
              length: 6,
              onCompleted: completed.add,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '1a234567');
      await tester.pump();
      expect(controller.text, '123456');
      expect(completed, ['123456']);
      expect(find.byType(EditableText), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).autofillHints,
        [AutofillHints.oneTimeCode],
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'checkbox mixed state is spoken, and the tristate cycle is reversible',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        bool? value = false;
        await tester.pumpWidget(
          neumorphicApp(
            Center(
              child: StatefulBuilder(
                builder: (context, setState) => NeumorphicCheckbox(
                  label: 'Agree',
                  value: value,
                  tristate: true,
                  onChanged: (v) => setState(() => value = v),
                ),
              ),
            ),
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        for (final expected in [true, null, false]) {
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
          expect(value, expected);
          final data = tester
              .getSemantics(find.byType(NeumorphicCheckbox))
              .getSemanticsData();
          expect(data.label, 'Agree');
          expect(
            data.flagsCollection.isChecked,
            expected == null
                ? CheckedState.mixed
                : expected
                ? CheckedState.isTrue
                : CheckedState.isFalse,
          );
        }
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets('a null check is valid without cycling through mixed', (
    tester,
  ) async {
    bool? selected;
    await tester.pumpWidget(
      neumorphicApp(
        Center(
          child: NeumorphicCheckbox(
            label: 'Some',
            value: null,
            onChanged: (v) => selected = v,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(NeumorphicCheckbox));
    await tester.pump();
    expect(selected, isTrue);
  });
  for (final segmented in [false, true]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        '${segmented ? 'segments' : 'radios'} skip disabled, follow RTL and keep one Tab stop',
        (tester) async {
          var value = 'a';
          var after = 0;
          await tester.pumpWidget(
            neumorphicApp(
              Center(
                child: StatefulBuilder(
                  builder: (context, setState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (segmented)
                        NeumorphicSegmentedButton<String>(
                          label: 'Period',
                          value: value,
                          segments: const [
                            NeumorphicButtonSegment('a', 'First'),
                            NeumorphicButtonSegment(
                              'b',
                              'Unavailable',
                              enabled: false,
                            ),
                            NeumorphicButtonSegment('c', 'Last'),
                          ],
                          onChanged: (v) => setState(() => value = v),
                        )
                      else
                        NeumorphicRadioGroup<String>(
                          label: 'Space',
                          value: value,
                          options: const [
                            NeumorphicRadio('a', 'First'),
                            NeumorphicRadio('b', 'Unavailable', enabled: false),
                            NeumorphicRadio('c', 'Last'),
                          ],
                          onChanged: (v) => setState(() => value = v),
                        ),
                      NeumorphicButton('After', onPressed: () => after++),
                    ],
                  ),
                ),
              ),
              direction: direction,
            ),
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          await tester.sendKeyEvent(
            direction == TextDirection.rtl
                ? LogicalKeyboardKey.arrowLeft
                : LogicalKeyboardKey.arrowRight,
          );
          await tester.pump();
          expect(value, 'c');
          await tester.sendKeyEvent(LogicalKeyboardKey.home);
          await tester.pump();
          expect(value, 'a');
          await tester.sendKeyEvent(LogicalKeyboardKey.end);
          await tester.pump();
          expect(value, 'c');
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(after, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'select commits a typed value and Escape preserves the prior value',
    (tester) async {
      var value = 1;
      await tester.pumpWidget(
        neumorphicApp(
          Center(
            child: StatefulBuilder(
              builder: (context, setState) => NeumorphicSelect<int>(
                label: 'Room',
                value: value,
                options: const [
                  NeumorphicMenuItem(1, 'One'),
                  NeumorphicMenuItem(2, 'Two'),
                ],
                onChanged: (v) => setState(() => value = v),
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(value, 2);
      expect(find.byType(NeumorphicMenu<int>), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(value, 2);
    },
  );
  testWidgets('check row has one label and one check role', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        neumorphicApp(
          Center(
            child: NeumorphicCheckRow(
              label: 'Remember',
              note: 'On this device',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      final data = tester
          .getSemantics(find.byType(NeumorphicTap))
          .getSemanticsData();
      expect(data.label, 'Remember, On this device');
      expect(data.flagsCollection.isChecked, CheckedState.isTrue);
      expect(data.flagsCollection.isButton, isFalse);
    } finally {
      semantics.dispose();
    }
  });
  check(
    'search with long label',
    () => const NeumorphicSearchField(label: longLine, hint: long),
  );
  check(
    'code with twelve cells',
    () =>
        const NeumorphicInputOtp(length: 12, label: longLine, error: longLine),
  );
  check(
    'select with long value',
    () => NeumorphicSelect<String>(
      label: longLine,
      value: 'a',
      options: const [NeumorphicMenuItem('a', longLine)],
      error: longLine,
      onChanged: (_) {},
    ),
  );
  check(
    'check row with long note',
    () => NeumorphicCheckRow(
      label: longLine,
      note: longLine,
      value: true,
      onChanged: (_) {},
    ),
  );
  check(
    'radio with long labels',
    () => NeumorphicRadioGroup<int>(
      label: 'Space',
      options: const [NeumorphicRadio(1, longLine, note: longLine)],
      onChanged: (_) {},
    ),
  );
  check(
    'segment with long label',
    () => NeumorphicSegmentedButton<int>(
      label: 'Period',
      segments: const [NeumorphicButtonSegment(1, longLine)],
      onChanged: (_) {},
    ),
  );
}
