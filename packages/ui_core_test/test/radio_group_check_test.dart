// DesignRadioGroupCheck and DesignCheckableCheck: a group of radios is one
// tab stop whose arrows choose, and each checkbox, radio and switch says
// what it is, as Flutter's do.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:ui_core/ui_core.dart';

const _choices = ['A', 'B', 'C'];

// Flutter's own group, the reference.
Widget _flutter(String? chosen, ValueChanged<String?> choose, {String? off}) =>
    RadioGroup<String>(
      groupValue: chosen,
      onChanged: choose,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in _choices)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(value: c, enabled: c != off),
                Text(c),
              ],
            ),
        ],
      ),
    );

// A group of pressables, each a tab stop that says it is a button, whose
// arrows do nothing: the audit's look radios.
Widget _pressables(String? chosen, ValueChanged<String?> choose) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    for (final c in _choices)
      DesignPressable(
        onPressed: () => choose(c),
        builder: (context, states, _) => Semantics(
          inMutuallyExclusiveGroup: true,
          checked: c == chosen,
          child: SizedBox(
            width: 120,
            height: 44,
            child: Center(child: Text(c)),
          ),
        ),
      ),
  ],
);

Future<DesignAlignmentReport> _check(
  WidgetTester tester,
  Widget Function(String? chosen, ValueChanged<String?> choose) group, {
  String? chosen = 'B',
  TextDirection direction = TextDirection.ltr,
}) async {
  final before = FocusNode();
  addTearDown(before.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Material(
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  focusNode: before,
                  onPressed: () {},
                  child: const Text('Before'),
                ),
                KeyedSubtree(
                  key: const ValueKey('group'),
                  child: group(chosen, (c) => setState(() => chosen = c)),
                ),
                TextButton(onPressed: () {}, child: const Text('After')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  return const DesignRadioGroupCheck(look: 'Test').check(
    tester.element(find.byKey(const ValueKey('group'))),
    before: before,
    sendKeyEvent: tester.sendKeyEvent,
    pump: tester.pump,
  );
}

void main() {
  testWidgets("Flutter's RadioGroup passes, chosen or not, a radio turned "
      'off passed over', (tester) async {
    final semantics = tester.ensureSemantics();
    expect((await _check(tester, _flutter)).problems, isEmpty);
    expect((await _check(tester, _flutter, chosen: null)).problems, isEmpty);
    expect(
      (await _check(
        tester,
        (chosen, choose) => _flutter(chosen, choose, off: 'C'),
      )).problems,
      isEmpty,
    );
    semantics.dispose();
  });

  testWidgets('a group of pressables: three tab stops, arrows that choose '
      'nothing, and buttons beside their state', (tester) async {
    final semantics = tester.ensureSemantics();
    final report = await _check(tester, _pressables);
    expect(report.problems, [
      'a radio "A": says it is a button beside its checked state, as '
          "Flutter's Radio does not",
      'a radio "B": says it is a button beside its checked state, as '
          "Flutter's Radio does not",
      'a radio "C": says it is a button beside its checked state, as '
          "Flutter's Radio does not",
      'Tab from before the group lands on "A", not on the chosen "B"',
      'a second Tab stays in the group, on "B"',
      'Up from "A" moves outside the group, not to "C"',
      'Right from "A" moves on "A", not to "B"',
      'Left from "A" moves on "A", not to "C"',
    ]);
    semantics.dispose();
  });

  testWidgets('right to left, Left moves on and Right back', (tester) async {
    final semantics = tester.ensureSemantics();
    Widget row(String? chosen, ValueChanged<String?> choose) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in _choices)
          Semantics(
            container: true,
            inMutuallyExclusiveGroup: true,
            checked: c == chosen,
            label: c,
            child: const SizedBox(width: 60, height: 44),
          ),
      ],
    );
    final report = await _check(tester, row, direction: TextDirection.rtl);
    // Nothing takes the focus: the check says so where Tab lands.
    expect(
      report.problems.first,
      'Tab from before the group lands outside the group, not on the chosen '
      '"B"',
    );
    semantics.dispose();
  });

  testWidgets('DesignCheckableCheck: a checkbox, a switch and a radio that say '
      'they are buttons; one that says no state', (tester) async {
    final semantics = tester.ensureSemantics();
    Widget node(String label, {bool? checked, bool? toggled, bool? group}) =>
        Semantics(
          container: true,
          button: true,
          label: label,
          checked: checked,
          toggled: toggled,
          inMutuallyExclusiveGroup: group,
          child: const SizedBox(width: 60, height: 44),
        );
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            key: const ValueKey('screen'),
            mainAxisSize: MainAxisSize.min,
            children: [
              node('Remember me', checked: true),
              node('Wi-Fi', toggled: false),
              node('Express', checked: false, group: true),
              Semantics(
                container: true,
                inMutuallyExclusiveGroup: true,
                label: 'Standard',
                child: const SizedBox(width: 60, height: 44),
              ),
              Checkbox(value: true, onChanged: (_) {}),
              Switch(value: true, onChanged: (_) {}),
            ],
          ),
        ),
      ),
    );
    expect(
      const DesignCheckableCheck(look: 'Test')
          .check(tester.element(find.byKey(const ValueKey('screen'))))
          .problems,
      [
        'a checkbox "Remember me": says it is a button beside its checked '
            "state, as Flutter's Checkbox does not",
        'a switch "Wi-Fi": says it is a button beside its toggled state, as '
            "Flutter's Switch does not",
        'a radio "Express": says it is a button beside its checked state, '
            "as Flutter's Radio does not",
        'a radio "Standard": says no checked state',
      ],
    );
    semantics.dispose();
  });
}
