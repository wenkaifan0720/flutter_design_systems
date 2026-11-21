import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart' show IconButton, MaterialApp;
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
    'RawButton',
    build: (c) => Center(
      child: RawButton(
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
        RawButton(
          onPressed: () => n++,
          focusNode: node,
          minimumSize: const Size(44, 44),
          builder: face,
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(RawButton)),
    );
    await tester.pump();
    expect(seen, contains(WidgetState.pressed));
    await gesture.up();
    await tester.pump();
    expect(n, 1);
    // The press stays its least time, then goes.
    expect(seen, contains(WidgetState.pressed));
    await tester.pump(RawButton.minimumPressDuration);
    expect(seen, isNot(contains(WidgetState.pressed)));
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(n, 3);
    expect(tester.getSize(find.byType(RawButton)), const Size(44, 44));
  });

  testWidgets('hover and a keyboard focus reach the face; a tap\'s does not', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      _app(RawButton(onPressed: () {}, focusNode: node, builder: face)),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(RawButton)));
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
    await tester.pumpWidget(_app(RawButton(focusNode: node, builder: face)));
    expect(seen, contains(WidgetState.disabled));
    node.requestFocus();
    await tester.pump();
    expect(node.hasPrimaryFocus, isFalse);
    final h = tester.ensureSemantics();
    final data = tester.getSemantics(find.byType(RawButton)).getSemanticsData();
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
      _app(RawButton(enabled: true, focusNode: node, builder: face)),
    );
    expect(seen, isNot(contains(WidgetState.disabled)));
    final data = tester.getSemantics(find.byType(RawButton)).getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    h.dispose();
    node.requestFocus();
    await tester.pump();
    expect(node.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.tap(find.byType(RawButton));
    await tester.pump();
    expect(seen, isNot(contains(WidgetState.pressed)));
  });

  testWidgets('selected and error reach the face and follow the widget', (
    tester,
  ) async {
    Widget build(bool on) => _app(
      RawButton(onPressed: () {}, selected: on, isError: on, builder: face),
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
        RawButton(
          onPressed: () {},
          semanticLabel: 'Save',
          toggled: true,
          builder: (_, _, _) => const Text('Ignored when named'),
          excludeSemantics: true,
        ),
      ),
    );
    final data = tester.getSemantics(find.byType(RawButton)).getSemanticsData();
    expect(data.label, 'Save');
    expect(data.flagsCollection.isButton, isFalse);
    expect(data.flagsCollection.isToggled, Tristate.isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(find.bySemanticsLabel('Ignored when named'), findsNothing);
    h.dispose();
  });

  testWidgets('a toggle button stays a button, selected, as '
      'IconButton(isSelected:) does; a switch is not a button', (tester) async {
    final semantics = tester.ensureSemantics();
    SemanticsData read(Finder f) => tester.getSemantics(f).getSemanticsData();
    for (final on in [true, false]) {
      await tester.pumpWidget(
        _app(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                isSelected: on,
                onPressed: () {},
                icon: const Text('B'),
              ),
              RawButton(
                semanticSelected: on,
                onPressed: () {},
                builder: (_, _, _) => const Text('Bold'),
              ),
              RawButton(
                toggled: on,
                onPressed: () {},
                builder: (_, _, _) => const Text('Sounds'),
              ),
            ],
          ),
        ),
      );
      final material = read(find.byType(IconButton)).flagsCollection;
      final toggle = read(find.byType(RawButton).at(0)).flagsCollection;
      expect(material.isButton, isTrue);
      expect(toggle.isButton, material.isButton);
      expect(toggle.isSelected, material.isSelected);
      expect(toggle.isToggled, material.isToggled);
      expect(toggle.isChecked, material.isChecked);
      expect(toggle.isSelected, on ? Tristate.isTrue : Tristate.isFalse);
      final aSwitch = read(find.byType(RawButton).at(1)).flagsCollection;
      expect(aSwitch.isButton, isFalse);
      expect(aSwitch.isToggled, on ? Tristate.isTrue : Tristate.isFalse);
    }
    semantics.dispose();
  });

  testWidgets('checked, mixed, toggled and radio states keep their roles', (
    tester,
  ) async {
    for (final checked in [false, true]) {
      for (final control in [
        RawButton(checked: checked, builder: face),
        RawButton(checked: false, mixed: true, builder: face),
        RawButton(toggled: checked, builder: face),
        RawButton(inMutuallyExclusiveGroup: true, builder: face),
        RawButton(
          checked: checked,
          inMutuallyExclusiveGroup: true,
          onPressed: () {},
          builder: face,
        ),
      ]) {
        await tester.pumpWidget(_app(control));
        final data = tester
            .getSemantics(find.byType(RawButton))
            .getSemanticsData();
        expect(data.flagsCollection.isButton, isFalse);
        expect(
          data.flagsCollection.isChecked,
          control.mixed
              ? CheckedState.mixed
              : switch (control.checked) {
                  true => CheckedState.isTrue,
                  false => CheckedState.isFalse,
                  null => CheckedState.none,
                },
        );
        expect(data.flagsCollection.isToggled, switch (control.toggled) {
          true => Tristate.isTrue,
          false => Tristate.isFalse,
          null => Tristate.none,
        });
        expect(
          data.flagsCollection.isInMutuallyExclusiveGroup,
          control.inMutuallyExclusiveGroup,
        );
        expect(data.hasAction(SemanticsAction.tap), control.onPressed != null);
      }
    }
  });

  testWidgets('explicit names and values are read once while a changed '
      'subtitle stays in the button name', (tester) async {
    final semantics = tester.ensureSemantics();
    Future<void> show(String subtitle) => tester.pumpWidget(
      _app(
        RawButton(
          semanticLabel: 'Paper size',
          semanticValue: 'A4',
          onPressed: () {},
          builder: (_, _, _) => Column(
            children: [
              const Text('Paper size'),
              const Text('A4'),
              Text(subtitle),
            ],
          ),
        ),
      ),
    );
    for (final subtitle in ['Unread', 'Read']) {
      await show(subtitle);
      final data = tester
          .getSemantics(find.byType(RawButton))
          .getSemanticsData();
      expect(data.label.split('\n'), ['Paper size', subtitle]);
      expect(data.value, 'A4');
      expect(data.hasAction(SemanticsAction.tap), isTrue);
    }
    semantics.dispose();
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
                RawButton(
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
        RawButton(
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
                RawButton(onPressed: () => taps++, builder: recording),
                const SizedBox(height: 600),
              ],
            ),
          ),
        ),
      );
      frames.clear();
      await quickTap(tester, find.byType(RawButton));
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
          RawButton(
            onPressed: () => taps++,
            onLongPress: () {},
            builder: recording,
          ),
        ),
      );
      frames.clear();
      await quickTap(tester, find.byType(RawButton));
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
        _app(RawButton(onLongPress: () => longs++, builder: recording)),
      );
      final finger = await tester.startGesture(
        tester.getCenter(find.byType(RawButton)),
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
                RawButton(onPressed: () => taps++, builder: recording),
                const SizedBox(height: 600),
              ],
            ),
          ),
        ),
      );
      final finger = await tester.startGesture(
        tester.getCenter(find.byType(RawButton)),
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

    testWidgets('in a list, a mouse press shows at once and a finger waits '
        'kPressTimeout, as InkWell: a mouse does not drag the list', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 300,
            child: ListView(
              children: [
                RawButton(onPressed: () {}, builder: recording),
                const SizedBox(height: 600),
              ],
            ),
          ),
        ),
      );
      final at = tester.getCenter(find.byType(RawButton));
      for (final kind in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
        frames.clear();
        final pointer = await tester.startGesture(at, kind: kind);
        await tester.pump(const Duration(milliseconds: 20));
        // No frame since the clear: nothing changed, so not pressed.
        expect(
          frames.isNotEmpty && frames.last.contains(WidgetState.pressed),
          kind == PointerDeviceKind.mouse,
          reason: '$kind, 20 ms after it went down',
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(frames.last, contains(WidgetState.pressed), reason: '$kind');
        await pointer.up();
        await tester.pump(const Duration(milliseconds: 200));
        expect(frames.last, isNot(contains(WidgetState.pressed)));
      }
    });

    testWidgets("a list that drags with a mouse (its ScrollBehavior's "
        'dragDevices) makes a mouse press wait too', (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 300,
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(
                dragDevices: PointerDeviceKind.values.toSet(),
              ),
              child: ListView(
                children: [
                  RawButton(onPressed: () {}, builder: recording),
                  const SizedBox(height: 600),
                ],
              ),
            ),
          ),
        ),
      );
      frames.clear();
      final mouse = await tester.startGesture(
        tester.getCenter(find.byType(RawButton)),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 20));
      expect(pressedIn(frames), isFalse);
      await tester.pump(const Duration(milliseconds: 100));
      expect(frames.last, contains(WidgetState.pressed));
      await mouse.up();
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('a fling in a list never shows a press', (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 300,
            child: ListView(
              children: [
                RawButton(onPressed: () {}, builder: recording),
                const SizedBox(height: 600),
              ],
            ),
          ),
        ),
      );
      frames.clear();
      await tester.fling(find.byType(RawButton), const Offset(0, -200), 1000);
      await tester.pump(const Duration(milliseconds: 200));
      expect(pressedIn(frames), isFalse);
    });
  });

  testWidgets('turned off, it takes no tap and no long press, and says no '
      'long press', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    var longPresses = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RawButton(
            enabled: false,
            semanticLabel: 'Commit',
            excludeSemantics: true,
            onPressed: () => taps++,
            onLongPress: () => longPresses++,
            builder: (_, states, _) {
              expect(states, contains(WidgetState.disabled));
              return const SizedBox.square(dimension: 64);
            },
          ),
        ),
      ),
    );
    final node = tester
        .getSemantics(find.bySemanticsLabel('Commit'))
        .getSemanticsData();
    await tester.tap(find.byType(RawButton));
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(RawButton));
    await tester.pumpAndSettle();
    expect([taps, longPresses], [0, 0]);
    expect(node.hasAction(SemanticsAction.tap), isFalse);
    expect(node.hasAction(SemanticsAction.longPress), isFalse);
    semantics.dispose();
  });

  testWidgets("a state the widget brings (selected) is told to the "
      "controller's listeners and onStatesChanged", (tester) async {
    final controller = WidgetStatesController();
    addTearDown(controller.dispose);
    var heard = 0;
    final told = <Set<WidgetState>>[];
    var face = false;
    controller.addListener(() => heard++);
    Widget app(bool selected) => MaterialApp(
      home: Center(
        child: RawButton(
          onPressed: () {},
          selected: selected,
          statesController: controller,
          onStatesChanged: told.add,
          builder: (_, states, _) {
            face = states.contains(WidgetState.selected);
            return const SizedBox.square(dimension: 64);
          },
        ),
      ),
    );
    await tester.pumpWidget(app(false));
    await tester.pumpAndSettle();
    heard = 0;
    told.clear();
    await tester.pumpWidget(app(true));
    await tester.pumpAndSettle();
    expect(face, isTrue);
    expect(controller.value, contains(WidgetState.selected));
    expect(heard, greaterThan(0));
    expect(told.last, contains(WidgetState.selected));
    heard = 0;
    await tester.pumpWidget(app(true));
    await tester.pumpAndSettle();
    expect(heard, 0, reason: 'nothing changed');
  });
}
