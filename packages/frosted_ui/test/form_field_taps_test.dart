// Controls in a FrostedFormField take a tap, each its own: a segmented button's segments, chips in a wrap, a switch
// and a checkbox, by the pointer and through the node the platform has for each (a screen reader's double tap, a
// browser's click with semantics on). A group merged into the field's one node would give every tap to its first
// control.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

class _Form extends StatefulWidget {
  const _Form({required this.log});

  final List<String> log;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  var _priority = 'low';
  final _labels = <String>{};
  var _reminder = false;
  var _done = false;

  void _say(String what) => widget.log.add(what);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 16,
    children: [
      FrostedFormField(
        labelText: 'Priority',
        child: FrostedSegmentedButton<String>(
          label: 'Priority',
          segments: const [
            FrostedButtonSegment('low', 'Low'),
            FrostedButtonSegment('normal', 'Normal'),
            FrostedButtonSegment('high', 'High'),
          ],
          value: _priority,
          onChanged: (v) {
            _say('priority $v');
            setState(() => _priority = v);
          },
        ),
      ),
      FrostedFormField(
        labelText: 'Labels',
        child: Wrap(
          spacing: 8,
          children: [
            for (final l in ['Planning', 'Review', 'Fieldwork'])
              FrostedChip(
                l,
                selected: _labels.contains(l),
                onPressed: () {
                  _say('label $l');
                  setState(
                    () => _labels.contains(l)
                        ? _labels.remove(l)
                        : _labels.add(l),
                  );
                },
              ),
          ],
        ),
      ),
      FrostedFormField(
        labelText: 'Reminder',
        helperText: 'A nudge before it is due',
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: FrostedSwitch(
            label: 'Reminder',
            value: _reminder,
            onChanged: (v) {
              _say('reminder $v');
              setState(() => _reminder = v);
            },
          ),
        ),
      ),
      FrostedFormField(
        labelText: 'Done',
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: FrostedCheckbox(
            label: 'Done',
            value: _done,
            onChanged: (v) {
              _say('done $v');
              setState(() => _done = v ?? false);
            },
          ),
        ),
      ),
    ],
  );
}

Future<List<String>> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(520, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final log = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => FrostedHost(child: page!),
      home: Material(
        type: MaterialType.transparency,
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: 440, child: _Form(log: log)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return log;
}

const _taken = ['priority high', 'label Review', 'reminder true', 'done true'];

void main() {
  testWidgets('each control in a form field takes the pointer\'s tap', (
    tester,
  ) async {
    final log = await _pump(tester);
    for (final target in [
      find.text('High'),
      find.text('Review'),
      find.byType(FrostedSwitch),
      find.byType(FrostedCheckbox),
    ]) {
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
    expect(log, _taken);
  });

  testWidgets('each control in a form field takes a tap through the node '
      'the platform sees for it', (tester) async {
    final semantics = tester.ensureSemantics();
    final log = await _pump(tester);
    // The node a screen reader, or a browser with semantics on, has for a control: its own, not merged into another.
    SemanticsNode node(Finder control) => tester.getSemantics(control);
    for (final (control, name) in [
      (find.text('High'), 'High'),
      (find.text('Review'), 'Review'),
      (find.byType(FrostedSwitch), 'Reminder'),
      (find.byType(FrostedCheckbox), 'Done'),
    ]) {
      final own = node(control);
      expect(own.label, contains(name), reason: '$name has its own node');
      own.owner!.performAction(own.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
    }
    expect(log, _taken);
    expect(
      node(find.text('High')).label,
      isNot(contains('Low')),
      reason: 'one segment, not the group',
    );
    semantics.dispose();
  });

  testWidgets('a group is named once: by its own node when it says the '
      "field's words, by the field when it does not", (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    // The nodes that say [words] on a line of their own.
    FinderBase<SemanticsNode> saying(String words) =>
        find.semantics.byPredicate(
          (n) => n.label
              .split('\n')
              .any((line) => line.trim().toLowerCase() == words),
        );
    // The segmented button names itself Priority, as its field does.
    expect(saying('priority'), findsOne);
    // A wrap of chips names nothing: the field names it.
    expect(saying('labels'), findsOne);
    semantics.dispose();
  });
}
