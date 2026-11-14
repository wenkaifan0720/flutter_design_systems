// What Flutter's own controls do and a look must: Tab reaches a control, Enter and Space press it, keyboard focus lifts the face
// when the keyboard moved the focus, a disabled control takes nothing, and a hover reaches the face's states.
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void _test(String description, WidgetTesterCallback body) =>
    testWidgets(description, body, variant: TargetPlatformVariant.all());

void main() {
  setUpAll(loadNeumorphicFonts);

  _test('slider ranges snap pointer, keyboard and spoken values', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var value = 10.0;
      final commits = <double>[];
      await tester.pumpWidget(
        neumorphicApp(
          StatefulBuilder(
            builder: (context, setState) => Center(
              child: SizedBox(
                width: 300,
                child: NeumorphicSlider(
                  label: 'Temperature',
                  value: value,
                  min: -10,
                  max: 30,
                  divisions: 8,
                  onChanged: (v) => setState(() => value = v),
                  onChangeEnd: commits.add,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(value, 15);
      expect(commits, [15]);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Temperature')).value,
        '15',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(value, 30);
      final box = tester.getRect(find.byType(NeumorphicSlider));
      await tester.tapAt(box.topLeft + Offset(box.width * .3, 24));
      await tester.pumpAndSettle();
      expect(value, 0);
      expect(commits.last, 0);
      await tester.pumpWidget(
        neumorphicApp(
          NeumorphicSlider(
            label: 'Fixed',
            value: 10,
            min: 10,
            max: 10,
            onChanged: (_) => fail('fixed range is disabled'),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  _test('a slider commits keyboard and pointer changes and respects RTL', (
    tester,
  ) async {
    var value = .5;
    final commits = <double>[];
    await tester.pumpWidget(
      neumorphicApp(
        StatefulBuilder(
          builder: (context, setState) => Center(
            child: SizedBox(
              width: 300,
              child: NeumorphicSlider(
                label: 'Volume',
                value: value,
                onChanged: (next) => setState(() => value = next),
                onChangeEnd: commits.add,
              ),
            ),
          ),
        ),
        direction: TextDirection.rtl,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, closeTo(.45, .001));
    expect(commits, [value]);
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(value, 0);
    commits.clear();
    await tester.drag(find.byType(NeumorphicSlider), const Offset(-90, 0));
    await tester.pumpAndSettle();
    expect(value, greaterThan(.5));
    expect(commits, [value]);
  });

  _test('a switch and a check report their own roles and values', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      for (final value in [false, true]) {
        await tester.pumpWidget(
          neumorphicApp(
            Center(
              child: NeumorphicSwitch(value: value, onChanged: (_) {}),
            ),
          ),
        );
        var data = tester
            .getSemantics(find.byType(DesignPressable))
            .getSemanticsData();
        expect(
          data.flagsCollection.isToggled,
          value ? ui.Tristate.isTrue : ui.Tristate.isFalse,
        );
        expect(data.flagsCollection.isButton, isFalse);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        await tester.pumpWidget(
          neumorphicApp(
            Center(
              child: NeumorphicRoundCheckbox(value: value, onChanged: (_) {}),
            ),
          ),
        );
        data = tester
            .getSemantics(find.byType(DesignPressable))
            .getSemanticsData();
        expect(
          data.flagsCollection.isChecked,
          value ? ui.CheckedState.isTrue : ui.CheckedState.isFalse,
        );
        expect(data.flagsCollection.isButton, isFalse);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
      }
    } finally {
      semantics.dispose();
    }
  });

  _test('a check releases its faded-out glyph and still animates changes', (
    tester,
  ) async {
    var value = false;
    late StateSetter update;
    await tester.pumpWidget(
      neumorphicApp(
        Center(
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return NeumorphicRoundCheckbox(value: value, onChanged: (_) {});
            },
          ),
        ),
      ),
    );
    final glyph = find.byIcon(NeumorphicGlyphs.check);
    expect(glyph, findsNothing);
    update(() => value = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(glyph, findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    update(() => value = false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(glyph, findsOneWidget);
    await tester.pumpAndSettle();
    expect(glyph, findsNothing);
  });

  _test(
    'primary cap keeps one 48 target around its fixed face on every platform',
    (tester) async {
      await tester.pumpWidget(
        neumorphicApp(
          Center(
            child: NeumorphicRoundButton.filled(
              NeumorphicGlyphs.plus,
              label: 'Add',
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(DesignPressable)), Size.square(48));
    },
  );

  _test('a tap in the padded margin reaches the face', (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      neumorphicApp(
        Center(
          child: NeumorphicRoundButton(
            Icons.add,
            label: 'Add',
            onPressed: () => presses++,
          ),
        ),
      ),
    );
    final box = tester.getRect(find.byType(DesignPressable));
    expect(box.size, Size.square(48));
    await tester.tapAt(box.centerLeft + const Offset(1, 0));
    await tester.pumpAndSettle();
    expect(presses, 1);
  });

  _test('small faces keep a 48 target on every platform', (tester) async {
    var presses = 0;
    for (final part in <Widget>[
      NeumorphicRoundButton(
        Icons.add,
        label: 'Add',
        size: 28,
        onPressed: () => presses++,
      ),
      NeumorphicRoundCheckbox(onChanged: (_) => presses++),
      NeumorphicLink('Go', onPressed: () => presses++),
      NeumorphicNumberField(
        value: '2',
        onDecrease: () => presses++,
        onIncrease: () => presses++,
      ),
    ]) {
      // A page's margin round the part: a target reaches past its face's box (the number field's keys stand on its
      // edges, their targets 2 px past them), and a field takes the column's width, so without one it meets the
      // screen's edge.
      await tester.pumpWidget(
        neumorphicApp(
          Center(
            child: Padding(padding: const EdgeInsets.all(24), child: part),
          ),
        ),
      );
      final target = find.byType(DesignPressable).first;
      final box = tester.getRect(target);
      expect(box.width, greaterThanOrEqualTo(48));
      expect(box.height, greaterThanOrEqualTo(48));
      final before = presses;
      await tester.tapAt(box.centerLeft + const Offset(1, 0));
      await tester.pumpAndSettle();
      expect(presses, before + 1);
    }
  });

  _test('reduced motion makes the press a cut', (tester) async {
    await tester.pumpWidget(
      neumorphicApp(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Center(child: NeumorphicButton('Save', onPressed: () {})),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Save')),
    );
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    await gesture.up();
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  final parts = <(String, Widget Function(VoidCallback?))>[
    ('act button', (go) => NeumorphicButton.filled('Book', onPressed: go)),
    ('line button', (go) => NeumorphicButton('Book', onPressed: go)),
    ('text link', (go) => NeumorphicLink('Book', onPressed: go)),
    (
      'round button',
      (go) => NeumorphicRoundButton(Icons.add, label: 'Add', onPressed: go),
    ),
    ('chip', (go) => NeumorphicChip('Book', onPressed: go)),
  ];

  for (final (name, make) in parts) {
    group(name, () {
      _test('mouse hover and a touch press reach the same face', (
        tester,
      ) async {
        var pressed = 0;
        await tester.pumpWidget(
          neumorphicApp(Center(child: make(() => pressed++))),
        );
        final target = find.byType(DesignPressable).first;
        final mouse = await tester.createGesture(
          kind: ui.PointerDeviceKind.mouse,
        );
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(tester.getCenter(target));
        await tester.pumpAndSettle();
        expect(
          tester.state<DesignPressableState>(target).states,
          contains(WidgetState.hovered),
        );
        await mouse.removePointer();
        await tester.pumpAndSettle();
        expect(
          tester.state<DesignPressableState>(target).states,
          isNot(contains(WidgetState.hovered)),
        );
        final touch = await tester.startGesture(
          tester.getCenter(target),
          kind: ui.PointerDeviceKind.touch,
        );
        await tester.pump();
        expect(
          tester.state<DesignPressableState>(target).states,
          contains(WidgetState.pressed),
        );
        await touch.up();
        await tester.pumpAndSettle();
        expect(pressed, 1);
      });
      _test('Tab reaches it, Enter and Space press it', (tester) async {
        var pressed = 0;
        await tester.pumpWidget(
          neumorphicApp(Center(child: make(() => pressed++))),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(pressed, 1, reason: 'Enter');
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(pressed, 2, reason: 'Space');
      });

      _test('keyboard focus lifts the face, and nothing before', (
        tester,
      ) async {
        await tester.pumpWidget(neumorphicApp(Center(child: make(() {}))));
        final lifts = find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.foregroundPainter.runtimeType.toString() == '_FocusLift',
        );
        expect(lifts, findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        // One frame starts the lift's clock, the next finds it risen.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(lifts, findsOneWidget);
      });

      _test('disabled takes no press and no focus', (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(neumorphicApp(Center(child: make(null))));
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(tester.takeException(), isNull);
          final data = tester
              .getSemantics(find.byType(DesignPressable).first)
              .getSemanticsData();
          expect(data.hasAction(SemanticsAction.tap), isFalse);
        } finally {
          semantics.dispose();
        }
      });

      _test('it is one button in the semantics tree', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(neumorphicApp(Center(child: make(() {}))));
          final data = tester
              .getSemantics(find.byType(DesignPressable).first)
              .getSemanticsData();
          expect(data.flagsCollection.isButton, isTrue);
          expect(data.label, name == 'round button' ? 'Add' : 'Book');
          expect(data.hasAction(SemanticsAction.tap), isTrue);
          expect(data.flagsCollection.isFocused, isNot(ui.Tristate.none));
          // Flutter's Focus intentionally omits the iOS semantics focus action
          // (flutter/flutter#150030); keyboard focus remains tested above.
          expect(
            data.hasAction(SemanticsAction.focus),
            defaultTargetPlatform != TargetPlatform.iOS,
          );
        } finally {
          handle.dispose();
        }
      });
    });
  }
}
