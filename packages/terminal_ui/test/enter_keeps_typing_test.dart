// Return in a field that keeps the focus (a combobox's, a tag input's, the
// command palette's search) keeps its text input too: the focus stays, the
// input is not restarted (no TextInput.clearClient or setClient after the
// action), and typing edits the field again. Flutter restarts the input of a
// field told of a submit (onSubmitted) that keeps its focus, and in a
// browser the restarted input takes no more typing; so these take Return in
// onEditingComplete, with no onSubmitted (_coord's
// specs/web-enter-keeps-typing.md). A field that gives up the focus on
// Return keeps onSubmitted and lets the focus go.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

Widget _host(Widget child) => MaterialApp(
  builder: (context, page) =>
      TermTheme(data: TermThemeData.dark(), child: page!),
  home: Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(width: 420, child: child),
    ),
  ),
);

EditableText _field(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

/// Sends Return (the field's done action) with the input's log cleared, so
/// what the log holds after it is what Return did.
Future<void> _return(
  WidgetTester tester, [
  TextInputAction action = TextInputAction.done,
]) async {
  tester.testTextInput.log.clear();
  await tester.testTextInput.receiveAction(action);
  await tester.pumpAndSettle();
}

/// The field kept its focus and its text input through Return.
void _keptItsInput(WidgetTester tester) {
  expect(_field(tester).focusNode.hasFocus, isTrue, reason: 'lost the focus');
  expect(
    tester.testTextInput.log.map((call) => call.method),
    isNot(
      anyOf(contains('TextInput.clearClient'), contains('TextInput.setClient')),
    ),
    reason: "the field's text input was restarted",
  );
}

/// Types [words] on the input as it stands (no new focus, no new client).
Future<void> _typeOn(WidgetTester tester, String words) async {
  tester.testTextInput.enterText(words);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("a combobox's field: Return takes the option and keeps the "
      'focus and the input; typing edits it again', (tester) async {
    String? chosen;
    await tester.pumpWidget(
      _host(
        TermCombobox<String>(
          labelText: 'environment',
          options: const ['preview', 'staging', 'production'],
          onSelected: (v) => chosen = v,
        ),
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'stag');
    await tester.pumpAndSettle();
    await _return(tester);
    expect(chosen, 'staging');
    _keptItsInput(tester);
    await _typeOn(tester, 'prod');
    expect(_field(tester).controller.text, 'prod');
    await _return(tester);
    expect(chosen, 'production');
    _keptItsInput(tester);
  });

  testWidgets("a tag input's field: Return adds a tag and keeps the focus and "
      'the input for the next', (tester) async {
    var regions = <String>[];
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => TermTagInput<String>(
            labelText: 'regions',
            values: regions,
            options: const ['eu-west', 'us-east', 'ap-south'],
            onChanged: (next) => setState(() => regions = next),
          ),
        ),
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'us');
    await tester.pumpAndSettle();
    await _return(tester);
    expect(regions, ['us-east']);
    _keptItsInput(tester);
    await _typeOn(tester, 'ap');
    expect(_field(tester).controller.text, 'ap');
    await _return(tester);
    expect(regions, ['us-east', 'ap-south']);
    _keptItsInput(tester);
  });

  testWidgets("the palette's search: Return with nothing matching keeps the "
      'focus and the input; with a match it runs the command', (tester) async {
    var ran = '';
    late BuildContext page;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            page = context;
            return const SizedBox(height: 40);
          },
        ),
      ),
    );
    final commands = [
      DesignCommand(label: 'go home', onPressed: () => ran = 'home'),
      DesignCommand(label: 'deploy to staging', onPressed: () => ran = 'stg'),
    ];
    unawaited(showTermCommandPalette(context: page, commands: commands));
    await tester.pumpAndSettle();
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'zzz');
    await tester.pumpAndSettle();
    await _return(tester, TextInputAction.go);
    expect(find.byType(TermCommandPalette), findsOneWidget);
    expect(ran, '');
    _keptItsInput(tester);
    await _typeOn(tester, 'stag');
    expect(_field(tester).controller.text, 'stag');
    expect(find.textContaining('1/2'), findsOneWidget);
    await _return(tester, TextInputAction.go);
    expect(ran, 'stg');
    expect(find.byType(TermCommandPalette), findsNothing);
  });

  testWidgets('a field that gives up the focus on Return: onSubmitted hears '
      'the words, the focus goes, the input is not restarted', (tester) async {
    String? submitted;
    await tester.pumpWidget(
      _host(
        TermTextField(labelText: 'branch', onSubmitted: (v) => submitted = v),
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'main');
    await _return(tester);
    expect(submitted, 'main');
    expect(_field(tester).focusNode.hasFocus, isFalse);
    expect(
      tester.testTextInput.log.map((call) => call.method),
      isNot(contains('TextInput.setClient')),
    );
  });
}
