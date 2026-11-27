// Controls in a RetroDesktopFormField take a tap, each its own: a segmented button's segments, chips in a wrap, radios,
// a row of boxes, a switch and a box, by the pointer and through their semantics (a screen reader's double tap, a
// browser's click with semantics on). A group's controls merged into the field's one node gave every tap to the first
// of them (a form's priority segments and its label chips took no tap).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

class _Form extends StatefulWidget {
  const _Form({required this.log});

  final List<String> log;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  var _priority = 'low';
  final _labels = <String>{};
  var _size = 'small';
  final _days = <String>{};
  var _reminder = false;
  var _done = false;
  var _estimate = 30;

  void _say(String what) => widget.log.add(what);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      RetroDesktopFormField(
        labelText: 'Priority',
        child: RetroDesktopSegmentedButton<String>(
          label: 'Priority',
          showLabel: false,
          segments: const [
            RetroDesktopButtonSegment('low', 'Low'),
            RetroDesktopButtonSegment('normal', 'Normal'),
            RetroDesktopButtonSegment('high', 'High'),
          ],
          value: _priority,
          onChanged: (v) {
            _say('priority $v');
            setState(() => _priority = v);
          },
        ),
      ),
      RetroDesktopFormField(
        labelText: 'Labels',
        child: Wrap(
          spacing: 8,
          children: [
            for (final l in ['Planning', 'Review', 'Fieldwork'])
              RetroDesktopChip(
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
      RetroDesktopFormField(
        labelText: 'Size',
        child: RetroDesktopRadioGroup<String>(
          labelText: 'Size',
          showLabel: false,
          value: _size,
          options: const [
            RetroDesktopRadio('small', 'Small'),
            RetroDesktopRadio('large', 'Large'),
          ],
          onChanged: (v) {
            _say('size $v');
            setState(() => _size = v);
          },
        ),
      ),
      RetroDesktopFormField(
        labelText: 'Days',
        child: Padding(
          padding: EdgeInsets.zero,
          child: Row(
            spacing: 12,
            children: [
              for (final d in ['Mon', 'Tue'])
                RetroDesktopCheckbox(
                  semanticLabel: d,
                  value: _days.contains(d),
                  onChanged: (_) {
                    _say('day $d');
                    setState(
                      () => _days.contains(d) ? _days.remove(d) : _days.add(d),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      RetroDesktopFormField(
        labelText: 'Reminder',
        helperText: 'A nudge before it is due',
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: RetroDesktopSwitch(
            semanticLabel: 'Reminder',
            value: _reminder,
            onChanged: (v) {
              _say('reminder $v');
              setState(() => _reminder = v);
            },
          ),
        ),
      ),
      RetroDesktopFormField(
        labelText: 'Estimate',
        child: RetroDesktopNumberField(
          labelText: 'Estimate',
          value: _estimate,
          min: 5,
          max: 480,
          step: 5,
          onChanged: (v) {
            _say('estimate $v');
            setState(() => _estimate = v);
          },
        ),
      ),
      const RetroDesktopFormField(
        labelText: 'Password',
        child: RetroDesktopPasswordField(),
      ),
      RetroDesktopFormField(
        labelText: 'Done',
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: RetroDesktopCheckbox(
            semanticLabel: 'Done',
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
  tester.view.physicalSize = const Size(520, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final log = <String>[];
  await tester.pumpWidget(
    retroDesktopApp(
      Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: 440, child: _Form(log: log)),
      ),
      width: 520,
    ),
  );
  await tester.pumpAndSettle();
  return log;
}

// A box by its name; its label is spoken, not drawn.
Finder _box(String name) => find.byWidgetPredicate(
  (w) => w is RetroDesktopCheckbox && w.semanticLabel == name,
);

const _taken = [
  'priority high',
  'label Review',
  'size large',
  'day Tue',
  'reminder true',
  'done true',
];

void main() {
  setUpAll(loadRetroDesktopFonts);

  testWidgets('each control in a form field takes the pointer\'s tap', (
    tester,
  ) async {
    final log = await _pump(tester);
    for (final target in [
      find.text('High'),
      find.text('Review'),
      find.text('Large'),
      _box('Tue'),
      find.byType(RetroDesktopSwitch),
      _box('Done'),
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
    for (final (control, name) in [
      (find.text('High'), 'High'),
      (find.text('Review'), 'Review'),
      (find.text('Large'), 'Large'),
      // A box draws no words: the node that carries its name. Merged into the field's, Tue had none of its own.
      (find.bySemanticsLabel(RegExp(r'^Tue\b')).first, 'Tue'),
      (find.byType(RetroDesktopSwitch), 'Reminder'),
      (find.bySemanticsLabel(RegExp(r'^Done\b')).first, 'Done'),
    ]) {
      final own = tester.getSemantics(control);
      expect(
        own.getSemanticsData().label,
        contains(name),
        reason: '$name has its own node',
      );
      own.owner!.performAction(own.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
    }
    expect(log, _taken);
    for (final (one, other) in [
      ('High', 'Low'),
      ('Review', 'Planning'),
      ('Large', 'Small'),
    ]) {
      expect(
        tester.getSemantics(find.text(one)).getSemanticsData().label,
        isNot(contains(other)),
        reason: '$one is one control, not its group',
      );
    }
    semantics.dispose();
  });

  testWidgets('a number field in a form field keeps its step buttons from '
      'the node that takes a tap', (tester) async {
    final semantics = tester.ensureSemantics();
    final log = await _pump(tester);
    final plus = find.descendant(
      of: find.byType(RetroDesktopNumberField),
      matching: find.byIcon(RetroDesktopGlyphs.plus),
    );
    await tester.tap(plus);
    await tester.pumpAndSettle();
    expect(log, ['estimate 35'], reason: 'the pointer steps it');
    // A screen reader's double tap, or a browser's click with semantics on, at the + button: merged into the
    // field's one node, the button stood under the entry's tap, which took it in the button's place.
    tester.binding.renderViews.first.owner!.semanticsOwner!.performActionAt(
      tester.getCenter(plus),
      SemanticsAction.tap,
    );
    await tester.pumpAndSettle();
    final entry = tester
        .state<EditableTextState>(
          find.descendant(
            of: find.byType(RetroDesktopNumberField),
            matching: find.byType(EditableText),
          ),
        )
        .widget
        .focusNode;
    expect(
      entry.hasFocus,
      isFalse,
      reason: 'no node under the + button takes its tap for the entry',
    );
    semantics.dispose();
  });

  testWidgets('a password\'s Show button in a form field takes a tap '
      'through its own node', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    final show = tester.getSemantics(find.bySemanticsLabel('Show password'));
    expect(show.label, 'Show password', reason: 'not merged with the entry');
    show.owner!.performAction(show.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Hide password'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a field named as its control reads the name once', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    // Every node a screen reader stops at, with each line of its label.
    final lines = <String>[];
    void visit(SemanticsNode n) {
      if (!n.isMergedIntoParent) {
        lines.addAll(
          n.getSemanticsData().label.split('\n').map((l) => l.trim()),
        );
      }
      n.visitChildren((c) {
        visit(c);
        return true;
      });
    }

    visit(
      tester
          .binding
          .renderViews
          .first
          .owner!
          .semanticsOwner!
          .rootSemanticsNode!,
    );
    for (final name in ['Priority', 'Size', 'Estimate']) {
      expect(
        lines.where((l) => l == name || l.startsWith('$name,')).length,
        1,
        reason: '$name is said by its control, and not again by its field',
      );
    }
    semantics.dispose();
  });

  testWidgets('a single control takes the field\'s name and help as its own', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    // The switch's node, merged with the field's: what a screen reader hears for it.
    final reminder = tester
        .getSemantics(find.byType(RetroDesktopSwitch))
        .getSemanticsData();
    expect(reminder.label, 'Reminder', reason: 'its name, once');
    expect(reminder.hint, contains('A nudge before it is due'));
    expect(reminder.hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
  });
}
