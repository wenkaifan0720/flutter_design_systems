import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);
  testWidgets('form decorators own the editable name and error announcement', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final controller = TextEditingController(text: 'secret');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        neumorphicApp(
          Center(
            child: NeumorphicTextField(
              label: 'Password',
              hint: 'Eight characters',
              error: 'Too short',
              controller: controller,
              obscureText: true,
              revealLabels: ('Reveal', 'Conceal'),
              decorate: (input) => Semantics(
                label: 'Account password',
                hint: 'Too short',
                child: input,
              ),
              failureLine: (failure) => ExcludeSemantics(child: failure),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final input = tester.getSemantics(find.byType(EditableText));
      expect(input.label, 'Account password');
      expect(input.hint, 'Too short');
      expect(find.bySemanticsLabel('Password'), findsNothing);
      expect(find.bySemanticsLabel('Reveal'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Reveal'));
      await tester.pump();
      expect(find.bySemanticsLabel('Conceal'), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isFalse,
      );
    } finally {
      semantics.dispose();
    }
  });
  testWidgets(
    'search draws no duplicate label and delegates editing completion',
    (tester) async {
      var complete = 0;
      await tester.pumpWidget(
        neumorphicApp(
          Center(
            child: NeumorphicSearchField(
              label: 'Search records',
              hint: 'Name or date',
              onEditingComplete: () => complete++,
              decorate: (input) =>
                  Semantics(label: 'Search records', child: input),
            ),
          ),
        ),
      );
      expect(find.text('Search records'), findsNothing);
      await tester.enterText(find.byType(EditableText), 'Ada');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(complete, 1);
    },
  );
  testWidgets('code field uses form completion and input decorators', (
    tester,
  ) async {
    var complete = 0, submitted = 0;
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        neumorphicApp(
          Center(
            child: NeumorphicInputOtp(
              label: 'Code',
              length: 4,
              textInputAction: TextInputAction.next,
              onCompleted: (_) => submitted++,
              onEditingComplete: () => complete++,
              decorate: (input) =>
                  Semantics(label: 'Security code', child: input),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '1234');
      await tester.pump();
      expect(submitted, 1);
      expect(
        tester.getSemantics(find.byType(EditableText)).label,
        'Security code',
      );
      await tester.testTextInput.receiveAction(TextInputAction.next);
      expect(complete, 1);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
  testWidgets(
    'field forwards focus, formatters, autofill, editing and submit',
    (tester) async {
      final node = FocusNode();
      final controller = TextEditingController();
      addTearDown(node.dispose);
      addTearDown(controller.dispose);
      String? changed, submitted;
      var completed = 0;
      await tester.pumpWidget(
        neumorphicApp(
          Center(
            child: NeumorphicTextField(
              controller: controller,
              focusNode: node,
              label: 'Phone',
              helper: 'Digits only',
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofillHints: const [AutofillHints.telephoneNumber],
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onChanged: (v) => changed = v,
              onSubmitted: (v) => submitted = v,
              onEditingComplete: () => completed++,
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      // One frame starts the well's clock, the next finds it deepened.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(node.hasFocus, isTrue);
      // The field's well deepens; no line is drawn round it.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == '_CastPainter' &&
              ((w.painter as dynamic).focus as double) > .99,
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byType(EditableText), '12ab34');
      expect(changed, '1234');
      expect(controller.text, '1234');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submitted, '1234');
      expect(completed, 1);
      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.autofillHints, [AutofillHints.telephoneNumber]);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'password uses its own reveal action, disabled prevents editing',
    (tester) async {
      await tester.pumpWidget(
        neumorphicApp(
          const Center(
            child: NeumorphicTextField(
              initialValue: 'secret',
              label: 'Password',
              obscureText: true,
            ),
          ),
        ),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue,
      );
      await tester.tap(find.byType(NeumorphicRoundButton));
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isFalse,
      );
      expect(
        tester
            .widget<NeumorphicRoundButton>(find.byType(NeumorphicRoundButton))
            .label,
        'Hide password',
      );
      await tester.pumpWidget(
        neumorphicApp(
          const Center(
            child: NeumorphicTextField(
              initialValue: 'secret',
              label: 'Password',
              obscureText: true,
              enabled: false,
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
      expect(
        tester
            .widget<NeumorphicRoundButton>(find.byType(NeumorphicRoundButton))
            .onPressed,
        isNull,
      );
    },
  );
  testWidgets(
    'navigation selection callback is optional beside destination callbacks',
    (tester) async {
      var item = 0, selected = -1;
      await tester.pumpWidget(
        neumorphicApp(
          Align(
            alignment: Alignment.bottomCenter,
            child: NeumorphicNavigationBar(
              items: [
                NeumorphicNavItem(
                  label: 'Home',
                  icon: NeumorphicGlyphs.house,
                  onPressed: () => item++,
                ),
              ],
              onDestinationSelected: (value) => selected = value,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Home'));
      await tester.pump();
      expect(selected, 0);
      expect(item, 0);
      await tester.pumpWidget(
        neumorphicApp(
          Align(
            alignment: Alignment.bottomCenter,
            child: NeumorphicNavigationBar(
              items: [
                NeumorphicNavItem(
                  label: 'Home',
                  icon: NeumorphicGlyphs.house,
                  onPressed: () => item++,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Home'));
      await tester.pump();
      expect(item, 1);
    },
  );
  testWidgets('a combobox says when no option fits the words', (tester) async {
    await tester.pumpWidget(
      neumorphicApp(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(24),
            child: NeumorphicCombobox<String>(
              label: 'Room',
              options: ['Bedroom', 'Study'],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Garage');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('No results'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Bed');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('No results'), findsNothing);
    expect(find.text('Bedroom'), findsOneWidget);
  });
  check(
    'field labels and errors at large text',
    () => const NeumorphicTextField(
      label: longLine,
      initialValue: longLine,
      error: longLine,
      helper: 'Helper',
      counter: '12 / 120',
      lines: 3,
    ),
  );
}
