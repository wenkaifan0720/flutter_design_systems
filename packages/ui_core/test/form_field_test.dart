import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

late RawInputDecoratorDetails _parts;

// The bare reference painter: label over the control over help or error.
Widget _layout(BuildContext context, RawInputDecoratorDetails parts) {
  _parts = parts;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [?parts.label, parts.control, ?(parts.error ?? parts.helper)],
  );
}

void main() {
  final contractNode = FocusNode();
  final contractText = TextEditingController();
  tearDownAll(() {
    contractNode.dispose();
    contractText.dispose();
  });
  behaviourContract(
    'RawInputDecorator',
    build: (c) => Center(
      child: SizedBox(
        width: 240,
        child: RawInputDecorator(
          labelText: 'Email',
          helperText: 'Work address',
          errorText: c.error ? 'Enter an email' : null,
          required: true,
          enabled: c.enabled,
          focusNode: contractNode,
          builder: _layout,
          child: plainField(controller: contractText, focusNode: contractNode),
        ),
      ),
    ),
    node: () => find.byType(EditableText),
    // The control's one node carries the name, the help and the validity.
    semantics: isSemantics(
      label: 'Email, required',
      hint: 'Work address',
      isTextField: true,
      validationResult: SemanticsValidationResult.none,
    ),
    noDisabledState:
        'RawInputDecorator names a control the look builds; the control carries '
        'its own disabled state',
    error: isSemantics(
      hint: 'Enter an email. Work address',
      validationResult: SemanticsValidationResult.invalid,
    ),
    errorWords: 'Enter an email',
    keyboard: (p) async {
      await p.tabInto();
      expect(_parts.focused, isTrue, reason: 'the parts know focus is in');
    },
  );

  testWidgets('the control carries the name, the hint and the validity; the '
      'visible words are not read twice', (tester) async {
    final semantics = tester.ensureSemantics();
    final node = FocusNode();
    final text = TextEditingController();
    addTearDown(node.dispose);
    addTearDown(text.dispose);
    await tester.pumpWidget(
      harness(
        Center(
          child: RawInputDecorator(
            labelText: 'Email',
            helperText: 'We never share it',
            errorText: 'Enter a valid email',
            required: true,
            focusNode: node,
            builder: _layout,
            child: plainField(controller: text, focusNode: node),
          ),
        ),
      ),
    );
    final data = tester
        .getSemantics(find.byType(EditableText))
        .getSemanticsData();
    expect(data.label, 'Email, required');
    expect(data.hint, 'Enter a valid email. We never share it');
    expect(data.validationResult, SemanticsValidationResult.invalid);
    expect(data.flagsCollection.isTextField, isTrue);
    expect(find.bySemanticsLabel('Enter a valid email'), findsNothing);
    semantics.dispose();
  });

  testWidgets('a tap on the label focuses the control; focus inside lights '
      'the field', (tester) async {
    final node = FocusNode();
    final text = TextEditingController();
    addTearDown(node.dispose);
    addTearDown(text.dispose);
    await tester.pumpWidget(
      harness(
        Center(
          child: RawInputDecorator(
            labelText: 'Name',
            focusNode: node,
            builder: _layout,
            child: plainField(controller: text, focusNode: node),
          ),
        ),
      ),
    );
    expect(_parts.focused, isFalse);
    await tester.tap(find.text('Name'));
    await tester.pump();
    expect(node.hasPrimaryFocus, isTrue);
    expect(_parts.focused, isTrue);
  });

  testWidgets('a group: the label names the group, each control keeps its '
      'own node', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(
        Center(
          child: RawInputDecorator(
            labelText: 'Size',
            mergeSemantics: false,
            builder: _layout,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final size in ['S', 'M'])
                  RawButton(
                    onPressed: () {},
                    semanticLabel: size,
                    excludeSemantics: true,
                    builder: (context, states, _) => plainFace(size),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Size'), findsOneWidget);
    expect(find.bySemanticsLabel('S'), findsOneWidget);
    expect(find.bySemanticsLabel('M'), findsOneWidget);
    semantics.dispose();
  });

  group('by default, the field reads what its child brings', () {
    SemanticsOwner owner() =>
        RendererBinding.instance.renderViews.first.owner!.semanticsOwner!;

    // A tap through the semantics tree where the platform's lands: on the
    // deepest node under [at] that takes a tap (a screen reader's, or a
    // click on the web with semantics on).
    Future<void> tapThrough(WidgetTester tester, Offset at) async {
      // The root node's space is the view's, in physical pixels.
      owner().performActionAt(
        at * tester.view.devicePixelRatio,
        SemanticsAction.tap,
      );
      await tester.pump();
    }

    int heard(String words) {
      var count = 0;
      void visit(SemanticsNode n) {
        count += words.allMatches(n.label).length;
        n.visitChildren((c) {
          visit(c);
          return true;
        });
      }

      visit(owner().rootSemanticsNode!);
      return count;
    }

    Widget part(String label, VoidCallback onPressed) => RawButton(
      onPressed: onPressed,
      semanticLabel: label,
      excludeSemantics: true,
      builder: (context, states, _) => plainFace(label, key: ValueKey(label)),
    );

    testWidgets('a group of controls: each keeps its node, and a tap through '
        'the semantics tree picks the one under it', (tester) async {
      final semantics = tester.ensureSemantics();
      String? picked;
      await tester.pumpWidget(
        harness(
          Center(
            child: RawInputDecorator(
              labelText: 'Priority',
              builder: _layout,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final p in ['Low', 'Medium', 'High'])
                    part(p, () => picked = p),
                ],
              ),
            ),
          ),
        ),
      );
      for (final p in ['High', 'Low', 'Medium']) {
        await tapThrough(tester, tester.getCenter(find.byKey(ValueKey(p))));
        expect(picked, p, reason: 'a tap on $p through the semantics tree');
      }
      expect(heard('Priority'), 1);
      semantics.dispose();
    });

    testWidgets("a stepper named as its field: its buttons step, and the "
        'label is read once', (tester) async {
      final semantics = tester.ensureSemantics();
      var value = 45;
      await tester.pumpWidget(
        harness(
          Center(
            child: StatefulBuilder(
              builder: (context, setState) => RawInputDecorator(
                labelText: 'Estimate',
                builder: _layout,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    part('Decrease', () => setState(() => value -= 5)),
                    Semantics(
                      label: 'Estimate',
                      value: '$value',
                      child: plainFace('$value'),
                    ),
                    part('Increase', () => setState(() => value += 5)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tapThrough(
        tester,
        tester.getCenter(find.byKey(const ValueKey('Increase'))),
      );
      expect(value, 50);
      await tapThrough(
        tester,
        tester.getCenter(find.byKey(const ValueKey('Decrease'))),
      );
      expect(value, 45);
      expect(heard('Estimate'), 1);
      semantics.dispose();
    });

    testWidgets('a required field whose control says its label: required, '
        'first in its hint, unless the control says that too', (tester) async {
      final semantics = tester.ensureSemantics();
      // The field's own node.
      final fieldNode = find.byWidgetPredicate(
        (w) => '${w.runtimeType}' == '_FieldSemantics',
      );
      Future<SemanticsData> field(String said, {Widget? group}) async {
        await tester.pumpWidget(
          harness(
            Center(
              child: RawInputDecorator(
                labelText: 'Estimate',
                helperText: 'In minutes',
                required: true,
                builder: _layout,
                child:
                    group ??
                    Semantics(
                      label: said,
                      value: '45',
                      onIncrease: () {},
                      increasedValue: '50',
                      child: plainFace('45'),
                    ),
              ),
            ),
          ),
        );
        return tester.getSemantics(fieldNode).getSemanticsData();
      }

      final stepper = await field('Estimate');
      expect(stepper.label, isNot(contains('required')));
      expect(stepper.hint, 'required, In minutes');
      expect(heard('Estimate'), 1);
      final whole = await field('Estimate, required');
      expect(whole.label, contains('Estimate, required'));
      expect(whole.hint, 'In minutes', reason: 'the control says it');
      await field(
        '',
        group: Semantics(
          container: true,
          label: 'Estimate',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [part('15', () {}), part('30', () {})],
          ),
        ),
      );
      final node = tester.getSemantics(fieldNode).getSemanticsData();
      expect(node.hint, 'required, In minutes', reason: 'a group');
      expect(heard('Estimate'), 1);
      // A control that does not say the label: the field's name says it all.
      final plain = await field('Minutes');
      expect(plain.label, contains('Estimate, required'));
      expect(plain.label, contains('Minutes'));
      expect(plain.hint, 'In minutes');
      semantics.dispose();
    });

    testWidgets("a number field: a tap through the semantics tree on its "
        "buttons does not land on its entry, and its name is read once", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      FocusNode? entry;
      await tester.pumpWidget(
        harness(
          Center(
            child: RawInputDecorator(
              labelText: 'Estimate',
              builder: _layout,
              child: RawNumberField(
                value: 45,
                semanticLabel: 'Estimate',
                onChanged: (_) {},
                fieldBuilder: (context, d) => SizedBox(
                  width: 80,
                  height: 44,
                  // As a look's text field does, the entry stands in a
                  // node of its own under the stepper's.
                  child: Semantics(
                    container: true,
                    textField: true,
                    onTap: (entry = d.focusNode).requestFocus,
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
                layoutBuilder: (context, field, decrement, increment) =>
                    Semantics(
                      value: '45',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [decrement, field, increment],
                      ),
                    ),
                buttonBuilder: (context, d) => SizedBox(
                  key: ValueKey(d.isIncrement ? '+' : '-'),
                  width: 44,
                  height: 44,
                  child: Center(child: Text(d.isIncrement ? '+' : '-')),
                ),
              ),
            ),
          ),
        ),
      );
      await tapThrough(
        tester,
        tester.getCenter(find.byKey(const ValueKey('+'))),
      );
      expect(entry!.hasFocus, isFalse);
      expect(heard('Estimate'), 1);
      // Its node spans the field but its buttons, so no tap node lies over
      // a button.
      final rect = globalRect(
        tester.getSemantics(find.byType(RawNumberField)),
        tester.view.devicePixelRatio,
      );
      final whole = tester.getRect(find.byType(RawNumberField));
      for (final (a, b) in [
        (rect.left, tester.getRect(find.byKey(const ValueKey('-'))).right),
        (rect.top, whole.top),
        (rect.right, tester.getRect(find.byKey(const ValueKey('+'))).left),
        (rect.bottom, whole.bottom),
      ]) {
        expect(a, closeTo(b, .01));
      }
      semantics.dispose();
    });

    testWidgets("a number field carries its field's name, help and error on "
        'its own node, and the field says them on none', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        harness(
          Center(
            child: RawInputDecorator(
              labelText: 'Estimate',
              helperText: 'In minutes',
              errorText: 'Too long',
              required: true,
              builder: _layout,
              child: RawNumberField(
                value: 45,
                semanticLabel: 'Minutes',
                onChanged: (_) {},
                fieldBuilder: (context, d) => plainField(
                  controller: d.controller,
                  focusNode: d.focusNode,
                  width: 80,
                ),
                buttonBuilder: (context, d) => SizedBox.square(
                  dimension: 44,
                  child: Center(child: Text(d.isIncrement ? '+' : '-')),
                ),
              ),
            ),
          ),
        ),
      );
      final data = tester
          .getSemantics(find.byType(RawNumberField))
          .getSemanticsData();
      expect(data.label, 'Estimate, required');
      expect(data.hint, 'Too long. In minutes');
      expect(data.validationResult, SemanticsValidationResult.invalid);
      expect(data.hasAction(SemanticsAction.increase), isTrue);
      expect(heard('Estimate'), 1);
      var hinted = 0;
      void visit(SemanticsNode n) {
        if (n.hint.contains('Too long')) hinted++;
        n.visitChildren((c) {
          visit(c);
          return true;
        });
      }

      visit(owner().rootSemanticsNode!);
      expect(hinted, 1);
      semantics.dispose();
    });

    testWidgets('a text entry beside a button: the entry takes the field '
        "name and help, and the button keeps its node and its name", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final text = TextEditingController();
      final focus = FocusNode();
      addTearDown(text.dispose);
      addTearDown(focus.dispose);
      var searched = 0;
      await tester.pumpWidget(
        harness(
          Center(
            child: RawInputDecorator(
              labelText: 'Search',
              helperText: 'Titles and authors',
              required: true,
              focusNode: focus,
              builder: _layout,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // As a look's text field does, the entry takes a tap on
                  // the field's node rather than a node of its own.
                  Semantics(
                    onTap: focus.requestFocus,
                    child: plainField(
                      controller: text,
                      focusNode: focus,
                      width: 160,
                    ),
                  ),
                  part('Search', () => searched++),
                ],
              ),
            ),
          ),
        ),
      );
      final entry = textFieldNode().getSemanticsData();
      expect(entry.label, 'Search, required');
      expect(entry.hint, 'Titles and authors');
      await tapThrough(
        tester,
        tester.getCenter(find.byKey(const ValueKey('Search'))),
      );
      expect(searched, 1);
      expect(focus.hasFocus, isFalse);
      await tapThrough(tester, tester.getCenter(find.byType(EditableText)));
      expect(focus.hasFocus, isTrue);
      semantics.dispose();
    });

    testWidgets('a group that names itself on its own node: the label is '
        'read once, and each control keeps its node', (tester) async {
      final semantics = tester.ensureSemantics();
      String? picked;
      await tester.pumpWidget(
        harness(
          Center(
            child: RawInputDecorator(
              labelText: 'Size',
              builder: _layout,
              child: Semantics(
                container: true,
                label: 'Size',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final p in ['S', 'M', 'L']) part(p, () => picked = p),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(heard('Size'), 1);
      await tapThrough(
        tester,
        tester.getCenter(find.byKey(const ValueKey('M'))),
      );
      expect(picked, 'M');
      semantics.dispose();
    });

    testWidgets('one control that is not a text field (a switch) takes the '
        'label as its name, and a tap through it toggles it', (tester) async {
      final semantics = tester.ensureSemantics();
      var on = false;
      await tester.pumpWidget(
        harness(
          Center(
            child: StatefulBuilder(
              builder: (context, setState) => RawInputDecorator(
                labelText: 'Wi-Fi',
                builder: _layout,
                child: Semantics(
                  toggled: on,
                  onTap: () => setState(() => on = !on),
                  child: plainFace('switch', key: const ValueKey('switch')),
                ),
              ),
            ),
          ),
        ),
      );
      final data = tester
          .getSemantics(find.byKey(const ValueKey('switch')))
          .getSemanticsData();
      expect(data.label, contains('Wi-Fi'));
      await tapThrough(
        tester,
        tester.getCenter(find.byKey(const ValueKey('switch'))),
      );
      expect(on, isTrue);
      semantics.dispose();
    });

    testWidgets('mergeSemantics true still makes one node of a group', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        harness(
          Center(
            child: RawInputDecorator(
              labelText: 'Priority',
              mergeSemantics: true,
              builder: _layout,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final p in ['Low', 'High']) part(p, () {}),
                ],
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byKey(const ValueKey('Low'))),
        same(tester.getSemantics(find.byKey(const ValueKey('High')))),
      );
      semantics.dispose();
    });
  });

  testWidgets('a failed submit shows every error and focuses the first wrong '
      'field; a good one saves and submits', (tester) async {
    final nameNode = FocusNode();
    final mailNode = FocusNode();
    final name = TextEditingController();
    final mail = TextEditingController();
    for (final d in [nameNode, mailNode, name, mail]) {
      addTearDown(d.dispose);
    }
    var submitted = 0;
    final saved = <String>[];
    late DesignFormState form;
    Widget field(
      String label,
      FocusNode node,
      TextEditingController text,
      String? Function(String) check,
    ) => DesignFormField<String>(
      focusNode: node,
      initialValue: '',
      validator: (value) => check(value ?? ''),
      onSaved: (value) => saved.add('$label=$value'),
      builder: (state) => RawInputDecorator(
        labelText: label,
        errorText: state.errorText,
        focusNode: node,
        builder: _layout,
        child: plainField(
          controller: text,
          focusNode: node,
          onChanged: state.didChange,
        ),
      ),
    );
    await tester.pumpWidget(
      harness(
        DesignForm(
          onSubmit: () => submitted++,
          child: Builder(
            builder: (context) {
              form = DesignForm.of(context);
              return Column(
                children: [
                  field(
                    'Name',
                    nameNode,
                    name,
                    (v) => v.isEmpty ? 'Name is required' : null,
                  ),
                  field(
                    'Email',
                    mailNode,
                    mail,
                    (v) => v.contains('@') ? null : 'Enter a valid email',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    expect(find.text('Name is required'), findsNothing);
    expect(form.submit(), isFalse);
    await tester.pump();
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(nameNode.hasPrimaryFocus, isTrue);
    expect(submitted, 0);

    await tester.enterText(find.byType(EditableText).first, 'Ada');
    await tester.pump();
    expect(find.text('Name is required'), findsNothing, reason: 'live now');
    expect(form.submit(), isFalse);
    await tester.pump();
    expect(mailNode.hasPrimaryFocus, isTrue);

    await tester.enterText(find.byType(EditableText).last, 'ada@x.io');
    await tester.pump();
    expect(form.submit(), isTrue);
    expect(submitted, 1);
    expect(saved, ['Name=Ada', 'Email=ada@x.io']);
  });
}
