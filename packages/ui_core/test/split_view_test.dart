import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _a = ValueKey('a');
const _b = ValueKey('b');
Set<WidgetState> _divider = {};

// The bare reference painter: two grey panes and a dark line.
Widget _split({
  Axis axis = Axis.horizontal,
  TextDirection direction = TextDirection.ltr,
  ValueChanged<double>? onChanged,
}) => harness(
  _view(axis: axis, onChanged: onChanged),
  textDirection: direction,
);

Widget _view({Axis axis = Axis.horizontal, ValueChanged<double>? onChanged}) =>
    Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 401,
        height: 401,
        child: DesignSplitView(
          axis: axis,
          minFirst: 100,
          minSecond: 50,
          step: 0.1,
          onChanged: onChanged,
          first: const ColoredBox(key: _a, color: Color(0xFFEEEEEE)),
          second: const ColoredBox(key: _b, color: Color(0xFFDDDDDD)),
          dividerBuilder: (context, states, axis) {
            _divider = states;
            return const ColoredBox(color: Color(0xFF000000));
          },
        ),
      ),
    );

WidgetTester tester(ContractProbe p) => p.tester;

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

void main() {
  behaviourContract(
    'DesignSplitView',
    build: (c) => _view(),
    node: () => find.bySemanticsLabel('Resize'),
    semantics: isSemantics(
      label: 'Resize',
      isSlider: true,
      isFocusable: true,
      hasEnabledState: true,
      isEnabled: true,
      hasIncreaseAction: true,
      hasDecreaseAction: true,
    ),
    noDisabledState:
        'a divider always resizes; a split that may not is two panes',
    keyboard: (p) async {
      await p.tabInto();
      final before = p.data.value;
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(tester(p).getSize(find.byKey(_a)).width, greaterThan(200));
      expect(p.data.value, isNot(before), reason: 'the reader hears it');
      await p.key(LogicalKeyboardKey.home);
      expect(tester(p).getSize(find.byKey(_a)).width, closeTo(100, 0.01));
      await p.key(LogicalKeyboardKey.end);
      expect(tester(p).getSize(find.byKey(_b)).width, closeTo(50, 0.01));
      await p.key(LogicalKeyboardKey.enter);
      expect(tester(p).getSize(find.byKey(_a)).width, closeTo(100, 0.01));
      await p.key(LogicalKeyboardKey.enter);
      expect(tester(p).getSize(find.byKey(_b)).width, closeTo(50, 0.01));
    },
    rtl: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(
        tester(p).getSize(find.byKey(_a)).width,
        greaterThan(200),
        reason: 'the first pane is on the right: left grows it',
      );
    },
    motion: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowRight);
    },
  );

  testWidgets('a drag on the divider resizes, within each pane\'s least '
      'size', (tester) async {
    await tester.pumpWidget(_split());
    expect(tester.getSize(find.byKey(_a)).width, 200);
    expect(tester.getRect(find.byKey(_b)).left, 201);
    final gesture = await tester.startGesture(const Offset(200.5, 200));
    await gesture.moveBy(const Offset(30, 0));
    await gesture.moveBy(const Offset(50, 0));
    await tester.pump();
    expect(_divider, contains(WidgetState.pressed));
    await gesture.moveBy(const Offset(400, 0));
    await gesture.up();
    await tester.pump();
    expect(tester.getSize(find.byKey(_b)).width, 50, reason: 'its least');
    expect(_divider, isNot(contains(WidgetState.pressed)));
  });

  testWidgets('the divider is a tab stop: arrows move it, Enter collapses '
      'the first pane to its least and brings it back', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    final seen = <double>[];
    await tester.pumpWidget(_split(axis: Axis.vertical, onChanged: seen.add));
    await _press(tester, LogicalKeyboardKey.tab);
    expect(_divider, contains(WidgetState.focused));
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(tester.getSize(find.byKey(_a)).height, closeTo(240, 0.01));
    await _press(tester, LogicalKeyboardKey.enter);
    expect(tester.getSize(find.byKey(_a)).height, closeTo(100, 0.01));
    await _press(tester, LogicalKeyboardKey.enter);
    expect(tester.getSize(find.byKey(_a)).height, closeTo(240, 0.01));
    expect(seen, hasLength(3));
  });

  testWidgets('right to left: the first pane is on the right and a drag '
      'left grows it; a screen reader hears a slider', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_split(direction: TextDirection.rtl));
    expect(tester.getRect(find.byKey(_a)).right, 401);
    final gesture = await tester.startGesture(const Offset(200.5, 200));
    await gesture.moveBy(const Offset(-30, 0));
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.up();
    await tester.pump();
    expect(tester.getSize(find.byKey(_a)).width, greaterThan(200));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Resize')),
      isSemantics(isSlider: true, hasIncreaseAction: true),
    );
    semantics.dispose();
  });
}
