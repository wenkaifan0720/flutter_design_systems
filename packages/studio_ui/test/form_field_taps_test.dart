// Controls in a StudioFormField take a tap, each its own: a segmented
// choice's keys, chips in a wrap, a stepper's keys, a switch and a checkbox, by
// the pointer and through their semantics (a screen reader's double tap, a
// browser's click with semantics on). A group's controls merged into the
// field's one node gave every tap to the first of them (the user, 11-18:
// Stint's Priority and Labels took no tap, in Neumorphism's look and
// Appliance's).
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

class _Form extends StatefulWidget {
  const _Form({required this.log});

  final List<String> log;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  var _priority = 'low';
  final _labels = <String>{};
  var _estimate = 45;
  var _reminder = false;
  var _done = false;

  void _say(String what) => widget.log.add(what);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioFormField(
        label: 'Priority',
        child: StudioSegmentedButton<String>(
          semanticLabel: 'Priority',
          segments: const [
            StudioSegment(value: 'low', label: 'Low'),
            StudioSegment(value: 'normal', label: 'Normal'),
            StudioSegment(value: 'high', label: 'High'),
          ],
          value: _priority,
          onChanged: (v) {
            _say('priority $v');
            setState(() => _priority = v);
          },
        ),
      ),
      StudioFormField(
        label: 'Labels',
        child: Wrap(
          spacing: 8,
          children: [
            for (final l in ['Planning', 'Review', 'Fieldwork'])
              StudioChip(
                label: l,
                selected: _labels.contains(l),
                onSelected: (_) {
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
      StudioFormField(
        label: 'Estimate (minutes)',
        child: StudioStepper(
          value: _estimate,
          min: 5,
          max: 480,
          step: 15,
          semanticLabel: 'Estimate',
          onChanged: (v) {
            _say('estimate $v');
            setState(() => _estimate = v);
          },
        ),
      ),
      StudioFormField(
        label: 'Reminder',
        helper: 'A nudge before it is due',
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: StudioSwitch(
            value: _reminder,
            onChanged: (v) {
              _say('reminder $v');
              setState(() => _reminder = v);
            },
          ),
        ),
      ),
      StudioFormField(
        label: 'Done',
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: StudioCheckbox(
            value: _done,
            onChanged: (v) {
              _say('done $v');
              setState(() => _done = v);
            },
          ),
        ),
      ),
    ],
  );
}

Future<List<String>> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(520, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final log = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          StudioHost(brightness: Brightness.light, child: app!),
      home: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: 440, child: _Form(log: log)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return log;
}

const _taken = [
  'priority high',
  'label Review',
  'estimate 60',
  'reminder true',
  'done true',
];

void main() {
  setUpAll(studioLoadFonts);

  // The stepper is one adjustable node: its keys answer the pointer, and a
  // screen reader raises it by its increase action.
  Finder increase() => find
      .descendant(
        of: find.byType(StudioStepper),
        matching: find.byType(StudioIconButton),
      )
      .last;

  testWidgets('each control in a field takes the pointer\'s tap', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final log = await _pump(tester);
    for (final target in [
      find.text('High'),
      find.text('Review'),
      increase(),
      find.byType(StudioSwitch),
      find.byType(StudioCheckbox),
    ]) {
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
    expect(log, _taken);
    semantics.dispose();
  });

  testWidgets('each control in a field takes a tap through the node the '
      'platform sees for it, and a group is named by its field', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final log = await _pump(tester);
    for (final (control, name, action) in [
      (find.text('High'), 'High', SemanticsAction.tap),
      (find.text('Review'), 'Review', SemanticsAction.tap),
      (find.byType(StudioStepper), 'Estimate', SemanticsAction.increase),
      (find.byType(StudioSwitch), 'Reminder', SemanticsAction.tap),
      (find.byType(StudioCheckbox), 'Done', SemanticsAction.tap),
    ]) {
      final own = tester.getSemantics(control);
      expect(own.label, startsWith(name), reason: '$name has its own node');
      own.owner!.performAction(own.id, action);
      await tester.pumpAndSettle();
    }
    expect(log, _taken);
    expect(
      tester.getSemantics(find.text('High')).label,
      isNot(contains('Low')),
      reason: 'one key, not the group',
    );
    // The field names its group: one node above the keys says
    // 'Priority', once.
    expect(find.bySemanticsLabel(RegExp('^Priority')), findsWidgets);
    semantics.dispose();
  });
}
