// Screen-reader activation and pointer taps must reach each control in a
// field with several independent actions.
import 'dart:convert';

import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart' show DesignFieldSemanticsCheck;

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : brutalRegisteredFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

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
    spacing: BrutalSpacing.large,
    children: [
      BrutalFormField(
        labelText: 'Priority',
        child: BrutalSegmentedButton<String>(
          segments: const [
            BrutalSegment(value: 'low', label: 'Low'),
            BrutalSegment(value: 'normal', label: 'Normal'),
            BrutalSegment(value: 'high', label: 'High'),
          ],
          value: _priority,
          onChanged: (v) {
            _say('priority $v');
            setState(() => _priority = v);
          },
        ),
      ),
      BrutalFormField(
        labelText: 'Labels',
        child: Wrap(
          spacing: BrutalSpacing.small,
          runSpacing: BrutalSpacing.small,
          children: [
            for (final l in ['Planning', 'Review', 'Fieldwork'])
              BrutalChip(
                label: l,
                selected: _labels.contains(l),
                onSelected: (on) {
                  _say('label $l');
                  setState(() => on ? _labels.add(l) : _labels.remove(l));
                },
              ),
          ],
        ),
      ),
      BrutalFormField(
        labelText: 'Estimate',
        helperText: 'In minutes',
        child: BrutalStepper(
          value: _estimate,
          min: 5,
          max: 480,
          semanticLabel: 'Estimate',
          onChanged: (v) {
            _say('estimate $v');
            setState(() => _estimate = v);
          },
        ),
      ),
      BrutalFormField(
        labelText: 'Reminder',
        helperText: 'A nudge before it is due',
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: BrutalSwitch(
            value: _reminder,
            onChanged: (v) {
              _say('reminder $v');
              setState(() => _reminder = v);
            },
          ),
        ),
      ),
      BrutalFormField(
        labelText: 'Done',
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: BrutalCheckbox(
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

Future<List<String>> _pump(WidgetTester t) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final log = <String>[];
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) =>
          BrutalHost(brightness: Brightness.light, child: page!),
      home: Align(
        alignment: AlignmentDirectional.topStart,
        child: Padding(
          padding: const EdgeInsets.all(BrutalSpacing.large),
          child: SizedBox(width: 342, child: _Form(log: log)),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  return log;
}

const _taken = [
  'priority high',
  'label Review',
  'estimate 46',
  'reminder true',
  'done true',
];

void main() {
  setUpAll(_loadFonts);

  testWidgets('each control in a form field takes the pointer\'s tap', (
    t,
  ) async {
    final log = await _pump(t);
    final plus = find.descendant(
      of: find.byType(BrutalStepper),
      matching: find.byType(Icon),
    );
    for (final target in [
      find.text('High'),
      find.text('Review'),
      plus.last,
      find.byType(BrutalSwitch),
      find.byType(BrutalCheckbox),
    ]) {
      await t.tap(target);
      await t.pumpAndSettle();
    }
    expect(log, _taken);
  });

  testWidgets('each control in a form field takes a tap through the node '
      'the platform sees for it, and the group is named by the field', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    final log = await _pump(t);
    SemanticsNode node(Finder control) => t.getSemantics(control);
    // A group keeps its controls' nodes; a single control takes the field's
    // name as its own.
    for (final (control, name) in [
      (find.text('High'), 'High'),
      (find.text('Review'), 'Review'),
    ]) {
      final own = node(control);
      expect(
        own.getSemanticsData().label,
        startsWith(name),
        reason: '$name has its own node',
      );
      own.owner!.performAction(own.id, SemanticsAction.tap);
      await t.pumpAndSettle();
    }
    // The stepper is one adjustable number, named once.
    final estimate = node(find.bySemanticsLabel(RegExp('^Estimate')));
    expect(
      estimate.getSemanticsData().hasAction(SemanticsAction.increase),
      isTrue,
    );
    expect(
      RegExp('Estimate').allMatches(estimate.label).length,
      1,
      reason: estimate.label,
    );
    estimate.owner!.performAction(estimate.id, SemanticsAction.increase);
    await t.pumpAndSettle();
    for (final (control, name) in [
      (find.byType(BrutalSwitch), 'Reminder'),
      (find.byType(BrutalCheckbox), 'Done'),
    ]) {
      final own = node(control);
      expect(
        own.getSemanticsData().label,
        startsWith(name),
        reason: '$name is named by its field',
      );
      own.owner!.performAction(own.id, SemanticsAction.tap);
      await t.pumpAndSettle();
    }
    expect(log, _taken);
    expect(
      node(find.text('High')).getSemanticsData().label,
      isNot(contains('Low')),
      reason: 'one cell, not the group',
    );
    const DesignFieldSemanticsCheck(look: 'Brutal')
        .check(t.element(find.byType(_Form)))
        .verify();
    semantics.dispose();
  });

  testWidgets('the field passes its merge through to ui_core\'s field, '
      'which decides by the child when it is left unset', (t) async {
    Widget field({bool? merge}) => BrutalFormField(
      labelText: 'Priority',
      mergeSemantics: merge,
      child: const SizedBox(width: 10, height: 10),
    );
    for (final merge in const [null, true, false]) {
      await t.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, page) =>
              BrutalHost(brightness: Brightness.light, child: page!),
          home: Center(child: field(merge: merge)),
        ),
      );
      expect(
        t
            .widget<RawInputDecorator>(find.byType(RawInputDecorator))
            .mergeSemantics,
        merge,
      );
    }
    expect(const BrutalFormField(child: SizedBox()).mergeSemantics, isNull);
  });
}
