import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
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
    expect(n, 1);
    // The press stays its least time, then goes.
    expect(seen, contains(WidgetState.pressed));
    await tester.pump(DesignPressable.minimumPressDuration);
    expect(seen, isNot(contains(WidgetState.pressed)));
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

  group('a quick tap shows its press', () {
    // Every frame's states, as the face was built for them.
    late List<Set<WidgetState>> frames;
    Widget recording(BuildContext _, Set<WidgetState> states, Widget? _) {
      frames.add({...states});
      return const SizedBox(width: 200, height: 48);
    }

    bool pressedIn(List<Set<WidgetState>> built) =>
        built.any((s) => s.contains(WidgetState.pressed));

    setUp(() => frames = []);

    // A tap 40 ms long: shorter than kPressTimeout (100 ms), as a finger's
    // quick tap is.
    Future<void> quickTap(WidgetTester tester, Finder target) async {
      final finger = await tester.startGesture(tester.getCenter(target));
      await tester.pump(const Duration(milliseconds: 40));
      await finger.up();
      await tester.pump();
    }

    testWidgets('in a list: the press is drawn, then let go', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 300,
            child: ListView(
              children: [
                DesignPressable(onPressed: () => taps++, builder: recording),
                const SizedBox(height: 600),
              ],
            ),
          ),
        ),
      );
      frames.clear();
      await quickTap(tester, find.byType(DesignPressable));
      expect(taps, 1);
      expect(
        pressedIn(frames),
        isTrue,
        reason: 'a 40 ms tap in a list builds a pressed face',
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(frames.last, isNot(contains(WidgetState.pressed)));
    });

    testWidgets('with onLongPress: the press is drawn, then let go', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          DesignPressable(
            onPressed: () => taps++,
            onLongPress: () {},
            builder: recording,
          ),
        ),
      );
      frames.clear();
      await quickTap(tester, find.byType(DesignPressable));
      expect(taps, 1);
      expect(
        pressedIn(frames),
        isTrue,
        reason: 'a 40 ms tap on a long-pressable builds a pressed face',
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(frames.last, isNot(contains(WidgetState.pressed)));
    });

    testWidgets('a long press stays pressed until the finger lifts', (
      tester,
    ) async {
      var longs = 0;
      await tester.pumpWidget(
        _app(DesignPressable(onLongPress: () => longs++, builder: recording)),
      );
      final finger = await tester.startGesture(
        tester.getCenter(find.byType(DesignPressable)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(frames.last, contains(WidgetState.pressed));
      await tester.pump(const Duration(milliseconds: 600));
      expect(longs, 1);
      expect(frames.last, contains(WidgetState.pressed));
      await finger.up();
      await tester.pump(const Duration(milliseconds: 200));
      expect(frames.last, isNot(contains(WidgetState.pressed)));
    });

    testWidgets('a drag that scrolls the list leaves no press behind', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 300,
            child: ListView(
              children: [
                DesignPressable(onPressed: () => taps++, builder: recording),
                const SizedBox(height: 600),
              ],
            ),
          ),
        ),
      );
      final finger = await tester.startGesture(
        tester.getCenter(find.byType(DesignPressable)),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        frames.last,
        contains(WidgetState.pressed),
        reason: 'a finger held still in a list presses after kPressTimeout',
      );
      await finger.moveBy(const Offset(0, -60));
      await tester.pump();
      expect(frames.last, isNot(contains(WidgetState.pressed)));
      frames.clear();
      await finger.up();
      await tester.pump(const Duration(milliseconds: 200));
      expect(taps, 0);
      expect(pressedIn(frames), isFalse);
    });

    testWidgets('a fling in a list never shows a press', (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 300,
            child: ListView(
              children: [
                DesignPressable(onPressed: () {}, builder: recording),
                const SizedBox(height: 600),
              ],
            ),
          ),
        ),
      );
      frames.clear();
      await tester.fling(
        find.byType(DesignPressable),
        const Offset(0, -200),
        1000,
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(pressedIn(frames), isFalse);
    });
  });
}
