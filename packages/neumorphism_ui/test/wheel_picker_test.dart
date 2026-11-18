// The wheel picker on ui_core's DesignWheelPicker: one tab stop that the keys turn (Up and Down, Page keys, Home and
// End, typed letters), a tap on a row, a screen reader's steps, and the look's own: a press on the wheel gives it the
// keys, and the well deepens round its lens with keyboard focus.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// A wheel that keeps the day it is given, and the days it reported.
class _Turned extends StatefulWidget {
  const _Turned({required this.log, this.enabled = true});

  final List<String> log;
  final bool enabled;

  @override
  State<_Turned> createState() => _TurnedState();
}

class _TurnedState extends State<_Turned> {
  String _day = 'Wed';

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: NeumorphicWheelPicker<String>(
      label: 'Day',
      items: _days,
      value: _day,
      width: 200,
      onChanged: widget.enabled
          ? (day) {
              widget.log.add(day);
              setState(() => _day = day);
            }
          : null,
    ),
  );
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadNeumorphicFonts);

  testWidgets('one tab stop: the keys turn it', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(neumorphicApp(_Turned(log: log)));
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.arrowUp);
    await _key(tester, LogicalKeyboardKey.arrowUp);
    await _key(tester, LogicalKeyboardKey.end);
    await _key(tester, LogicalKeyboardKey.home);
    await _key(tester, LogicalKeyboardKey.keyF);
    expect(log, ['Thu', 'Wed', 'Tue', 'Sun', 'Mon', 'Fri']);
  });

  testWidgets('a tap on a row turns it there', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(neumorphicApp(_Turned(log: log)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thu'));
    await tester.pumpAndSettle();
    expect(log, ['Thu']);
  });

  testWidgets('a press on the wheel gives it the keys', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(neumorphicApp(_Turned(log: log)));
    final press = await tester.startGesture(tester.getCenter(find.text('Wed')));
    await press.up();
    await tester.pumpAndSettle();
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(log, ['Thu']);
  });

  testWidgets('keyboard focus deepens the well', (tester) async {
    await tester.pumpWidget(neumorphicApp(const _Turned(log: [])));
    Set<WidgetState>? wellStates() => tester
        .widgetList<NeumorphicSurface>(find.byType(NeumorphicSurface))
        .firstWhere((s) => s.cast == NeumorphicSurfaceLevel.well)
        .states;
    expect(wellStates(), isNot(contains(WidgetState.focused)));
    await _key(tester, LogicalKeyboardKey.tab);
    expect(wellStates(), contains(WidgetState.focused));
  });

  testWidgets('a screen reader hears one adjustable and steps it', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final log = <String>[];
    await tester.pumpWidget(neumorphicApp(_Turned(log: log)));
    expect(
      find.semantics.byLabel('Day'),
      isSemantics(
        label: 'Day',
        value: 'Wed',
        increasedValue: 'Thu',
        decreasedValue: 'Tue',
        isEnabled: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    tester.semantics.increase(find.semantics.byLabel('Day'));
    await tester.pumpAndSettle();
    expect(log, ['Thu']);
    semantics.dispose();
  });

  testWidgets('out of use: no stop, no turn', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(neumorphicApp(_Turned(log: log, enabled: false)));
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await tester.drag(find.text('Wed'), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(log, isEmpty);
  });

  testWidgets('no items: the empty well, out of use', (tester) async {
    await tester.pumpWidget(
      neumorphicApp(
        NeumorphicWheelPicker<String>(
          label: 'Day',
          items: const [],
          value: '',
          onChanged: (_) {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
