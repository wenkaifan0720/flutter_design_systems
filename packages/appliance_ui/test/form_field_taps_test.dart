// Controls in an ApplianceField take a tap, each its own: a selector's
// positions, chips in a wrap, a stepper's keys, a switch, a checkbox and a
// time picker's keys, by the pointer and through their semantics (a screen
// reader's double tap, a browser's click with semantics on). A group's
// controls merged into the field's one node gave every tap to the first of
// them (the user, 11-18: Stint's Priority and Labels took no tap).
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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
  var _time = const ApplianceTime(9, 30);

  void _say(String what) => widget.log.add(what);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ApplianceField(
        labelText: 'Priority',
        child: ApplianceSegmentedButton<String>(
          semanticLabel: 'Priority',
          segments: const [
            ApplianceSegment(value: 'low', label: 'Low'),
            ApplianceSegment(value: 'normal', label: 'Normal'),
            ApplianceSegment(value: 'high', label: 'High'),
          ],
          value: _priority,
          onChanged: (v) {
            _say('priority $v');
            setState(() => _priority = v);
          },
        ),
      ),
      ApplianceField(
        labelText: 'Labels',
        child: Wrap(
          spacing: 8,
          children: [
            for (final l in ['Planning', 'Review', 'Fieldwork'])
              ApplianceChip(
                l,
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
      ApplianceField(
        labelText: 'Estimate (minutes)',
        child: ApplianceStepper(
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
      ApplianceField(
        labelText: 'Reminder',
        helperText: 'A nudge before it is due',
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: ApplianceSwitch(
            value: _reminder,
            onChanged: (v) {
              _say('reminder $v');
              setState(() => _reminder = v);
            },
          ),
        ),
      ),
      ApplianceField(
        labelText: 'Done',
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: ApplianceCheckbox(
            value: _done,
            onChanged: (v) {
              _say('done $v');
              setState(() => _done = v ?? false);
            },
          ),
        ),
      ),
      ApplianceField(
        labelText: 'Remind at',
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: ApplianceTimePicker(
            value: _time,
            twentyFourHour: false,
            onChanged: (t) {
              _say('time ${t.hour}:${t.minute}');
              setState(() => _time = t);
            },
          ),
        ),
      ),
    ],
  );
}

Future<List<String>> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(520, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final log = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
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
  'time 21:30',
];

void main() {
  setUpAll(applianceLoadFonts);

  Finder increase() => find.bySemanticsLabel(RegExp('^Increase'));

  testWidgets('each control in a field takes the pointer\'s tap', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final log = await _pump(tester);
    for (final target in [
      find.text('High'),
      find.text('Review'),
      increase(),
      find.byType(ApplianceSwitch),
      find.byType(ApplianceCheckbox),
      find.text('PM'),
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
    for (final (control, name) in [
      (find.text('High'), 'High'),
      (find.text('Review'), 'Review'),
      (increase(), 'Increase'),
      (find.byType(ApplianceSwitch), 'Reminder'),
      (find.byType(ApplianceCheckbox), 'Done'),
      (find.text('PM'), 'PM'),
    ]) {
      final own = tester.getSemantics(control);
      expect(own.label, startsWith(name), reason: '$name has its own node');
      own.owner!.performAction(own.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
    }
    expect(log, _taken);
    expect(
      tester.getSemantics(find.text('High')).label,
      isNot(contains('Low')),
      reason: 'one position, not the group',
    );
    // The field names its group: one node above the positions says
    // 'Priority', once.
    expect(find.bySemanticsLabel(RegExp('^Priority')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('^Remind at')), findsWidgets);
    semantics.dispose();
  });
}
