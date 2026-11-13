import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

late DesignFieldParts _parts;

// The bare reference painter: label over the control over help or error.
Widget _layout(BuildContext context, DesignFieldParts parts) {
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
    'DesignField',
    build: (c) => Center(
      child: SizedBox(
        width: 240,
        child: DesignField(
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
        'DesignField names a control the look builds; the control carries '
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
          child: DesignField(
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
          child: DesignField(
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
          child: DesignField(
            labelText: 'Size',
            mergeSemantics: false,
            builder: _layout,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final size in ['S', 'M'])
                  DesignPressable(
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
      builder: (state) => DesignField(
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
