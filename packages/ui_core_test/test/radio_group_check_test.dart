// DesignRadioGroupCheck and DesignCheckableCheck: a group of radios is one
// tab stop whose arrows choose, and each checkbox, radio and switch says
// what it is, as Flutter's do.
import 'dart:async' show unawaited;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
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
      RawButton(
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

// A one-choice toggle group (a segmented control): a radio group, every
// arrow choosing (the 0.3.5 queue's fault: it answered its own axis alone).
Widget _segments(
  String? chosen,
  ValueChanged<String?> choose, {
  String? off,
  Axis direction = Axis.horizontal,
}) => RawSegmentedButton<String>(
  options: _choices,
  selected: {?chosen},
  direction: direction,
  emptySelectionAllowed: true,
  isEnabled: (c) => c != off,
  onSelectionChanged: (next) => choose(next.isEmpty ? null : next.first),
  itemBuilder: (context, value, states) =>
      SizedBox(width: 60, height: 44, child: Center(child: Text(value))),
);

// A page and a modal route over it, each a one-choice group at the same
// spot behind a control (the Lobo pilot's schedule chips under its
// new-class sheet): the page's group, behind the route's barrier, is out
// of the semantics tree.
Future<(DesignAlignmentReport, DesignAlignmentReport)> _covered(
  WidgetTester tester,
  double scale,
) async {
  final backBefore = FocusNode();
  final frontBefore = FocusNode();
  addTearDown(backBefore.dispose);
  addTearDown(frontBefore.dispose);
  final navigator = GlobalKey<NavigatorState>();
  Widget layer(
    FocusNode before,
    Key key,
    List<String> options,
    String initial,
  ) {
    var chosen = initial;
    return Material(
      type: MaterialType.transparency,
      child: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 200),
            TextButton(
              focusNode: before,
              onPressed: () {},
              child: const Text('Before'),
            ),
            KeyedSubtree(
              key: key,
              child: RawSegmentedButton<String>(
                options: options,
                selected: {chosen},
                onSelectionChanged: (next) =>
                    setState(() => chosen = next.single),
                itemBuilder: (context, value, states) =>
                    SizedBox(width: 90, height: 44, child: Text(value)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: layer(backBefore, const ValueKey('back'), const [
        'All',
        'Strength',
        'Conditioning',
        'Mobility',
      ], 'All'),
    ),
  );
  unawaited(
    navigator.currentState!.push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: const Color(0x80000000),
        pageBuilder: (context, _, _) => layer(
          frontBefore,
          const ValueKey('front'),
          const ['Strength', 'Conditioning', 'Mobility', 'Boxing'],
          'Strength',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // The page's group is behind the barrier: its words are read nowhere.
  bool read(String label) {
    var found = false;
    bool visit(SemanticsNode node) {
      if (node.getSemanticsData().label == label) found = true;
      node.visitChildren(visit);
      return true;
    }

    visit(
      tester
          .renderObject(find.byType(MaterialApp))
          .owner!
          .semanticsOwner!
          .rootSemanticsNode!,
    );
    return found;
  }

  expect(read('All'), isFalse);
  expect(read('Boxing'), isTrue);
  Future<DesignAlignmentReport> check(String key, FocusNode before) =>
      const DesignRadioGroupCheck(look: 'Test').check(
        tester.element(find.byKey(ValueKey(key))),
        before: before,
        sendKeyEvent: tester.sendKeyEvent,
        pump: tester.pump,
      );
  final back = await check('back', backBefore);
  final front = await check('front', frontBefore);
  navigator.currentState!.pop();
  await tester.pumpAndSettle();
  return (back, front);
}

void main() {
  testWidgets('a group behind a modal route is not read from the group over '
      'it, and the group over it passes', (tester) async {
    final semantics = tester.ensureSemantics();
    for (final scale in [1.0, 2.0]) {
      final (back, front) = await _covered(tester, scale);
      expect(back.problems, isEmpty, reason: '${scale}x');
      expect(front.problems, isEmpty, reason: '${scale}x');
    }
    semantics.dispose();
  });

  testWidgets('a one-choice RawSegmentedButton passes as a radio group, '
      'either way it runs and reads', (tester) async {
    final semantics = tester.ensureSemantics();
    for (final direction in TextDirection.values) {
      for (final axis in Axis.values) {
        Widget group(String? chosen, ValueChanged<String?> choose) =>
            _segments(chosen, choose, direction: axis);
        expect(
          (await _check(tester, group, direction: direction)).problems,
          isEmpty,
          reason: '${direction.name} ${axis.name}',
        );
        expect(
          (await _check(
            tester,
            group,
            chosen: null,
            direction: direction,
          )).problems,
          isEmpty,
        );
        expect(
          (await _check(
            tester,
            (chosen, choose) =>
                _segments(chosen, choose, off: 'C', direction: axis),
            direction: direction,
          )).problems,
          isEmpty,
        );
      }
    }
    semantics.dispose();
  });

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
