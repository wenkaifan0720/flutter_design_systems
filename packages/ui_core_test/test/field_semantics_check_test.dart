// DesignFieldSemanticsCheck: each control inside a field takes a tap
// through the semantics tree, and the field's label is read once.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

Widget _layout(BuildContext context, RawInputDecoratorDetails parts) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [?parts.label, parts.control],
);

Widget _part(String label) => RawButton(
  onPressed: () {},
  semanticLabel: label,
  excludeSemantics: true,
  builder: (context, states, _) => plainFace(label),
);

Widget _field(String label, Widget child, {bool? merge}) => harness(
  Center(
    child: RawInputDecorator(
      labelText: label,
      mergeSemantics: merge,
      builder: _layout,
      child: child,
    ),
  ),
);

// A stepper as a look builds one on ui_core's: its buttons take a pointer's
// press, its node steps, and its entry stands in a node of its own.
Widget _stepper() => RawNumberField(
  value: 45,
  semanticLabel: 'Estimate',
  onChanged: (_) {},
  fieldBuilder: (context, d) => SizedBox(
    width: 80,
    height: 44,
    child: Semantics(
      container: true,
      textField: true,
      onTap: d.focusNode.requestFocus,
      child: EditableText(
        controller: d.controller,
        focusNode: d.focusNode,
        style: const TextStyle(fontSize: 16),
        cursorColor: const Color(0xFF000000),
        backgroundCursorColor: const Color(0xFF808080),
      ),
    ),
  ),
  // The stepper's node says the number it steps, as a look's does.
  layoutBuilder: (context, field, decrement, increment) => Semantics(
    value: '45',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [decrement, field, increment],
    ),
  ),
  buttonBuilder: (context, d) => SizedBox(
    width: 44,
    height: 44,
    child: Center(child: Text(d.isIncrement ? '+' : '-')),
  ),
);

List<String> _problems(WidgetTester tester) =>
    const DesignFieldSemanticsCheck(look: 'Test')
        .check(tester.element(find.byType(RawInputDecorator)))
        .problems;

void main() {
  testWidgets('a group made one node: a tap reaches one of its controls', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final group = Row(
      mainAxisSize: MainAxisSize.min,
      children: [_part('Low'), _part('Medium'), _part('High')],
    );
    await tester.pumpWidget(_field('Priority', group, merge: true));
    expect(_problems(tester), [
      'a field "Priority": a button "Low", a button "Medium" and a button '
          '"High" are one node, so a tap through the semantics tree reaches '
          'one of them',
    ]);
    await tester.pumpWidget(_field('Priority', group));
    expect(_problems(tester), isEmpty);
    semantics.dispose();
  });

  testWidgets('a stepper named as its field, made one node: its label is read '
      'twice and its buttons are one node', (tester) async {
    final semantics = tester.ensureSemantics();
    final stepper = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _part('Decrease'),
        Semantics(label: 'Guests', value: '4', child: plainFace('4')),
        _part('Increase'),
      ],
    );
    await tester.pumpWidget(_field('Guests', stepper, merge: true));
    expect(_problems(tester), [
      'a field "Guests": a button "Decrease" and a button "Increase" are one '
          'node, so a tap through the semantics tree reaches one of them',
      'a field "Guests": its label is read 2 times',
    ]);
    await tester.pumpWidget(_field('Guests', stepper));
    expect(_problems(tester), isEmpty);
    semantics.dispose();
  });

  testWidgets("a stepper whose entry's tap is merged over its buttons", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_field('Estimate', _stepper(), merge: true));
    expect(_problems(tester), [
      'a field "Estimate": a tap through the semantics tree on its stepper\'s '
          'button on the left lands on "Estimate", not on the button',
      'a field "Estimate": a tap through the semantics tree on its stepper\'s '
          'button on the right lands on "Estimate", not on the button',
      'a field "Estimate": its label is read 2 times',
    ]);
    await tester.pumpWidget(_field('Estimate', _stepper()));
    expect(_problems(tester), isEmpty);
    semantics.dispose();
  });

  testWidgets('a group that names itself under a field that names it too', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final group = Semantics(
      container: true,
      label: 'Size',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_part('S'), _part('M'), _part('L')],
      ),
    );
    await tester.pumpWidget(_field('Size', group, merge: false));
    expect(_problems(tester), ['a field "Size": its label is read 2 times']);
    await tester.pumpWidget(_field('Size', group));
    expect(_problems(tester), isEmpty);
    semantics.dispose();
  });

  testWidgets("a date's and a time's segments: each segment takes its own "
      'tap', (tester) async {
    final semantics = tester.ensureSemantics();
    Widget segment(BuildContext context, RawDateSegmentDetails d) =>
        SizedBox(width: 40, height: 44, child: Center(child: Text(d.text)));
    await tester.pumpWidget(
      _field(
        'Due',
        RawDateField(
          value: DateTime(2026, 11, 16),
          semanticLabel: 'Due',
          onChanged: (_) {},
          segmentBuilder: segment,
        ),
      ),
    );
    expect(_problems(tester), isEmpty);
    await tester.pumpWidget(
      _field(
        'Starts',
        RawTimeField(
          value: const RawTimeOfDay(hour: 9, minute: 30),
          semanticLabel: 'Starts',
          onChanged: (_) {},
          segmentBuilder: segment,
        ),
      ),
    );
    expect(_problems(tester), isEmpty);
    semantics.dispose();
  });

  testWidgets('one control merged with its label passes', (tester) async {
    final semantics = tester.ensureSemantics();
    final toggle = Semantics(
      toggled: false,
      onTap: () {},
      child: plainFace('switch'),
    );
    for (final merge in [null, true]) {
      await tester.pumpWidget(_field('Wi-Fi', toggle, merge: merge));
      expect(_problems(tester), isEmpty, reason: 'mergeSemantics: $merge');
    }
    semantics.dispose();
  });

  testWidgets("a text entry beside a button named as the field (a search "
      "field's Search): the button's name is its own, not a reading", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final text = TextEditingController();
    final focus = FocusNode();
    addTearDown(text.dispose);
    addTearDown(focus.dispose);
    final search = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        plainField(controller: text, focusNode: focus, width: 160),
        _part('Search'),
      ],
    );
    await tester.pumpWidget(_field('Search', search));
    expect(_problems(tester), isEmpty);
    semantics.dispose();
  });
}
