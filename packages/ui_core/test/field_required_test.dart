// A required field carries the platform's required flag, and keeps its
// "required" words where the platform says nothing of the flag (Flutter
// 3.47: everywhere but the web, and on the web wherever the field's node is
// not its text entry). A field is invalid with an error, or told so with no
// words.
import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/src/internal/field_words.dart';

import 'behaviour_harness.dart';

late RawInputDecoratorDetails _parts;

Widget _layout(BuildContext context, RawInputDecoratorDetails parts) {
  _parts = parts;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [?parts.label, parts.control, ?(parts.error ?? parts.helper)],
  );
}

final _fieldNode = find.byWidgetPredicate(
  (w) => '${w.runtimeType}' == '_FieldSemantics',
);

void main() {
  late FocusNode node;
  late TextEditingController text;
  setUp(() {
    node = FocusNode();
    text = TextEditingController();
  });
  tearDown(() {
    RawRequiredFlag.heard = false;
    node.dispose();
    text.dispose();
  });

  Widget field({
    bool required = true,
    bool invalid = false,
    String? errorText,
    bool? mergeSemantics,
    Widget? child,
  }) => harness(
    Center(
      child: RawInputDecorator(
        labelText: 'Email',
        helperText: 'Work address',
        errorText: errorText,
        required: required,
        invalid: invalid,
        mergeSemantics: mergeSemantics,
        focusNode: node,
        builder: _layout,
        child: child ?? plainField(controller: text, focusNode: node),
      ),
    ),
  );

  SemanticsData entry(WidgetTester tester) =>
      tester.getSemantics(find.byType(EditableText)).getSemanticsData();

  testWidgets('a required text field carries the required flag, and its '
      'words where the flag is not heard', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(field());
    final data = entry(tester);
    expect(data.flagsCollection.isRequired, Tristate.isTrue);
    expect(data.label, 'Email, required');
    expect(data.hint, 'Work address');
    semantics.dispose();
  });

  testWidgets("where the flag is heard (the web's aria-required), a text "
      "entry's name drops the words: the flag says them", (tester) async {
    final semantics = tester.ensureSemantics();
    RawRequiredFlag.heard = true;
    await tester.pumpWidget(field());
    final data = entry(tester);
    expect(data.flagsCollection.isRequired, Tristate.isTrue);
    expect(data.label, 'Email');
    semantics.dispose();
  });

  testWidgets('where the flag is heard, a group keeps its words: the web '
      'reads no aria-required on a group', (tester) async {
    final semantics = tester.ensureSemantics();
    RawRequiredFlag.heard = true;
    await tester.pumpWidget(
      field(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final word in ['Home', 'Work'])
              RawButton(
                onPressed: () {},
                builder: (context, states, _) => Text(word),
              ),
          ],
        ),
      ),
    );
    final data = tester.getSemantics(_fieldNode).getSemanticsData();
    expect(data.label, 'Email, required');
    expect(data.flagsCollection.isRequired, Tristate.isTrue);
    semantics.dispose();
  });

  testWidgets('a field that is not required has no required state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(field(required: false));
    final data = entry(tester);
    expect(data.flagsCollection.isRequired, Tristate.none);
    expect(data.label, 'Email');
    semantics.dispose();
  });

  testWidgets('merged whole, or a group of its own: the flag on the '
      "field's node, the words kept", (tester) async {
    final semantics = tester.ensureSemantics();
    RawRequiredFlag.heard = true;
    for (final merge in [true, false]) {
      await tester.pumpWidget(field(mergeSemantics: merge));
      final data = tester
          .getSemantics(find.bySemanticsLabel('Email, required'))
          .getSemanticsData();
      expect(
        data.flagsCollection.isRequired,
        Tristate.isTrue,
        reason: '$merge',
      );
    }
    semantics.dispose();
  });

  testWidgets("a number field carries the flag on the node that carries "
      "the field's words", (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(
        Center(
          child: RawInputDecorator(
            labelText: 'Guests',
            required: true,
            builder: _layout,
            child: RawNumberField(
              value: 2,
              onChanged: (value) {},
              min: 0,
              fieldBuilder: (context, field) => SizedBox(
                width: 80,
                child: EditableText(
                  controller: field.controller,
                  focusNode: field.focusNode,
                  keyboardType: field.keyboardType,
                  inputFormatters: field.inputFormatters,
                  onEditingComplete: field.onEditingComplete,
                  style: const TextStyle(),
                  cursorColor: const Color(0xFF000000),
                  backgroundCursorColor: const Color(0xFF808080),
                ),
              ),
              buttonBuilder: (context, button) =>
                  Text(button.isIncrement ? '+' : '−'),
            ),
          ),
        ),
      ),
    );
    final data = tester
        .getSemantics(find.bySemanticsLabel('Guests, required'))
        .getSemanticsData();
    expect(data.flagsCollection.isRequired, Tristate.isTrue);
    semantics.dispose();
  });

  group('a field with no label, named by what its control says', () {
    // The field's words: no label, the help, required.
    Widget unnamed({bool? mergeSemantics, required Widget child}) => harness(
      Center(
        child: RawInputDecorator(
          helperText: 'Work address',
          required: true,
          mergeSemantics: mergeSemantics,
          focusNode: node,
          builder: _layout,
          child: child,
        ),
      ),
    );

    // A text field named by the words it draws beside its entry.
    Widget drawn() => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Email'),
        plainField(controller: text, focusNode: node),
      ],
    );

    testWidgets('by the words it draws: the node they name says it is '
        'required, first in its hint', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(unnamed(child: drawn()));
      final data = entry(tester);
      expect(data.label, contains('Email'));
      expect(data.flagsCollection.isRequired, Tristate.isTrue);
      expect(data.hint, 'required, Work address');
      semantics.dispose();
    });

    testWidgets('by its semantic label: the same', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        unnamed(
          child: Semantics(
            label: 'Accept the terms',
            checked: false,
            onTap: () {},
            child: const SizedBox(width: 44, height: 44),
          ),
        ),
      );
      final data = tester
          .getSemantics(find.bySemanticsLabel('Accept the terms'))
          .getSemanticsData();
      expect(data.flagsCollection.isRequired, Tristate.isTrue);
      expect(data.hint, 'required, Work address');
      semantics.dispose();
    });

    testWidgets('merged whole: the same', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(unnamed(mergeSemantics: true, child: drawn()));
      final data = entry(tester);
      expect(data.label, contains('Email'));
      expect(data.flagsCollection.isRequired, Tristate.isTrue);
      expect(data.hint, 'required, Work address');
      semantics.dispose();
    });

    testWidgets("a group of its own: the group's node says it", (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(unnamed(mergeSemantics: false, child: drawn()));
      final data = tester
          .getSemantics(find.byType(RawInputDecorator))
          .getSemanticsData();
      expect(data.flagsCollection.isRequired, Tristate.isTrue);
      expect(data.hint, 'required, Work address');
      semantics.dispose();
    });

    testWidgets('a number field: the node that carries the words says it', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        unnamed(
          child: RawNumberField(
            value: 2,
            onChanged: (value) {},
            min: 0,
            fieldBuilder: (context, field) => SizedBox(
              width: 80,
              child: EditableText(
                controller: field.controller,
                focusNode: field.focusNode,
                keyboardType: field.keyboardType,
                inputFormatters: field.inputFormatters,
                onEditingComplete: field.onEditingComplete,
                style: const TextStyle(),
                cursorColor: const Color(0xFF000000),
                backgroundCursorColor: const Color(0xFF808080),
              ),
            ),
            buttonBuilder: (context, button) =>
                Text(button.isIncrement ? '+' : '−'),
          ),
        ),
      );
      final data = entry(tester);
      expect(data.flagsCollection.isRequired, Tristate.isTrue);
      expect(data.hint, 'required, Work address');
      semantics.dispose();
    });

    testWidgets("where the flag is heard, the text entry's node drops the "
        'words: the flag says them', (tester) async {
      final semantics = tester.ensureSemantics();
      RawRequiredFlag.heard = true;
      await tester.pumpWidget(unnamed(child: drawn()));
      final data = entry(tester);
      expect(data.flagsCollection.isRequired, Tristate.isTrue);
      expect(data.hint, 'Work address');
      semantics.dispose();
    });
  });

  testWidgets('invalid with no words: a screen reader hears it invalid, and '
      'the parts know it; an error makes it invalid too', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(field(invalid: true));
    expect(entry(tester).validationResult, SemanticsValidationResult.invalid);
    expect(entry(tester).hint, 'Work address', reason: 'no words added');
    expect(_parts.invalid, isTrue);
    expect(_parts.hasError, isFalse);
    await tester.pumpWidget(field());
    expect(entry(tester).validationResult, SemanticsValidationResult.none);
    expect(_parts.invalid, isFalse);
    await tester.pumpWidget(field(errorText: 'Enter an email'));
    expect(entry(tester).validationResult, SemanticsValidationResult.invalid);
    expect(_parts.invalid, isTrue);
    for (final merge in [true]) {
      await tester.pumpWidget(field(invalid: true, mergeSemantics: merge));
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Email, required'))
            .getSemanticsData()
            .validationResult,
        SemanticsValidationResult.invalid,
      );
    }
    semantics.dispose();
  });
}
