import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

Widget _app(Widget child) => MaterialApp(home: Center(child: child));

void main() {
  late Set<WidgetState> seen;
  Widget face(BuildContext _, Set<WidgetState> states, Widget? _) {
    seen = states;
    return const SizedBox(width: 20, height: 20);
  }

  setUp(() => seen = {});

  var presses = 0;
  behaviourContract(
    'DesignPressable',
    build: (c) => Center(
      child: DesignPressable(
        onPressed: c.enabled ? () => presses++ : null,
        isError: c.error,
        semanticLabel: 'Save',
        minimumSize: const Size(44, 44),
        excludeSemantics: true,
        builder: (_, _, _) => plainFace('Save'),
      ),
    ),
    node: () => find.bySemanticsLabel('Save'),
    semantics: isSemantics(
      label: 'Save',
      isButton: true,
      isFocusable: true,
      hasEnabledState: true,
      isEnabled: true,
      hasTapAction: true,
      validationResult: SemanticsValidationResult.none,
    ),
    disabled: isSemantics(
      isButton: true,
      hasEnabledState: true,
      isEnabled: false,
      isFocusable: false,
      hasTapAction: false,
    ),
    error: isSemantics(validationResult: SemanticsValidationResult.invalid),
    keyboard: (p) async {
      presses = 0;
      await p.tabInto();
      await p.key(LogicalKeyboardKey.enter);
      await p.key(LogicalKeyboardKey.space);
      expect(presses, 2, reason: 'Enter and Space press it');
    },
  );

  testWidgets('a tap, Enter and Space press it; a press reaches the face', (
    tester,
  ) async {
    var n = 0;
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      _app(
        DesignPressable(
          onPressed: () => n++,
          focusNode: node,
          minimumSize: const Size(44, 44),
          builder: face,
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(DesignPressable)),
    );
    await tester.pump();
    expect(seen, contains(WidgetState.pressed));
    await gesture.up();
    await tester.pump();
    expect(seen, isNot(contains(WidgetState.pressed)));
    expect(n, 1);
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(n, 3);
    expect(tester.getSize(find.byType(DesignPressable)), const Size(44, 44));
  });

  testWidgets('hover and a keyboard focus reach the face; a tap\'s does not', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      _app(DesignPressable(onPressed: () {}, focusNode: node, builder: face)),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(DesignPressable)));
    await tester.pump();
    expect(seen, contains(WidgetState.hovered));
    await mouse.moveTo(Offset.zero);
    await tester.pump();
    expect(seen, isNot(contains(WidgetState.hovered)));

    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTouch;
    node.requestFocus();
    await tester.pump();
    expect(node.hasPrimaryFocus, isTrue);
    expect(seen, isNot(contains(WidgetState.focused)));
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    await tester.pump();
    expect(seen, contains(WidgetState.focused));
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  testWidgets('disabled: no focus, no press, and the face is told', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      _app(DesignPressable(focusNode: node, builder: face)),
    );
    expect(seen, contains(WidgetState.disabled));
    node.requestFocus();
    await tester.pump();
    expect(node.hasPrimaryFocus, isFalse);
    final h = tester.ensureSemantics();
    final data = tester
        .getSemantics(find.byType(DesignPressable))
        .getSemanticsData();
    expect(data.flagsCollection.isEnabled, Tristate.isFalse);
    h.dispose();
  });

  testWidgets('waiting: keeps its focus and its tap, takes no press', (
    tester,
  ) async {
    final h = tester.ensureSemantics();
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      _app(DesignPressable(enabled: true, focusNode: node, builder: face)),
    );
    expect(seen, isNot(contains(WidgetState.disabled)));
    final data = tester
        .getSemantics(find.byType(DesignPressable))
        .getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    h.dispose();
    node.requestFocus();
    await tester.pump();
    expect(node.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.tap(find.byType(DesignPressable));
    await tester.pump();
    expect(seen, isNot(contains(WidgetState.pressed)));
  });

  testWidgets('selected and error reach the face and follow the widget', (
    tester,
  ) async {
    Widget build(bool on) => _app(
      DesignPressable(
        onPressed: () {},
        selected: on,
        isError: on,
        builder: face,
      ),
    );
    await tester.pumpWidget(build(true));
    expect(seen, containsAll([WidgetState.selected, WidgetState.error]));
    await tester.pumpWidget(build(false));
    expect(seen, isNot(contains(WidgetState.selected)));
    expect(seen, isNot(contains(WidgetState.error)));
  });

  testWidgets('one semantics node, named, with its role and state', (
    tester,
  ) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        DesignPressable(
          onPressed: () {},
          semanticLabel: 'Save',
          toggled: true,
          builder: (_, _, _) => const Text('Ignored when named'),
          excludeSemantics: true,
        ),
      ),
    );
    final data = tester
        .getSemantics(find.byType(DesignPressable))
        .getSemanticsData();
    expect(data.label, 'Save');
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isToggled, Tristate.isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(find.bySemanticsLabel('Ignored when named'), findsNothing);
    h.dispose();
  });

  testWidgets('a tab is read as a tab, chosen or not, not a button', (
    tester,
  ) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        Semantics(
          role: SemanticsRole.tabBar,
          explicitChildNodes: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (label, on) in [('Spending', true), ('Income', false)])
                DesignPressable(
                  onPressed: () {},
                  tab: true,
                  selected: on,
                  semanticLabel: label,
                  excludeSemantics: true,
                  builder: (_, _, _) => const SizedBox(width: 60, height: 40),
                ),
            ],
          ),
        ),
      ),
    );
    for (final (label, on) in [('Spending', true), ('Income', false)]) {
      final data = tester
          .getSemantics(find.bySemanticsLabel(label))
          .getSemanticsData();
      expect(data.role, SemanticsRole.tab);
      expect(data.flagsCollection.isButton, isFalse);
      expect(
        data.flagsCollection.isSelected,
        on ? Tristate.isTrue : Tristate.isFalse,
      );
      expect(data.hasAction(SemanticsAction.tap), isTrue);
    }
    h.dispose();
  });

  testWidgets('more shortcuts and actions ride along', (tester) async {
    var next = 0;
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      _app(
        DesignPressable(
          onPressed: () {},
          focusNode: node,
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.arrowRight): NextFocusIntent(),
          },
          actions: {
            NextFocusIntent: CallbackAction<NextFocusIntent>(
              onInvoke: (_) => next++,
            ),
          },
          builder: face,
        ),
      ),
    );
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(next, 1);
  });
}
