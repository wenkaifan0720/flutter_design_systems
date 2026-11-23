// A field's help and its error are read on the field itself, as Material's
// TextField reads them, never on a node of their own beside it, as
// ui_core_test's DesignFieldWordsCheck reads them: the text field, the
// password field and the field with add-ons, with their help, then their
// error; the combobox and the tag input, with no tags, one and three, with
// their help.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'faces.dart';

const _help = 'the branch slipway builds';
const _error = 'no branch by that name';

final _fields = <String, Widget Function({String? help, String? error})>{
  'text field': ({help, error}) =>
      TermTextField(labelText: 'branch', helperText: help, errorText: error),
  'password field': ({help, error}) =>
      TermPasswordField(labelText: 'token', helperText: help, errorText: error),
  'field with add-ons': ({help, error}) => TermTextField(
    labelText: 'preview url',
    prefixText: 'https://',
    suffixText: '.slipway.dev',
    helperText: help,
    errorText: error,
  ),
  // A combobox shows help; it has no error of its own.
  'combobox': ({help, error}) => TermCombobox<String>(
    labelText: 'branch',
    options: const ['main', 'fix/retry'],
    helperText: help,
  ),
  // A tag input shows help; it has no error of its own. Its tags stand before
  // the entry, which reads the field's words.
  for (final tags in const [
    <String>[],
    ['eu-west'],
    ['eu-west', 'us-east', 'ap-south'],
  ])
    'tag input with ${tags.length} tags': ({help, error}) =>
        TermTagInput<String>(
          labelText: 'regions',
          values: tags,
          options: const ['eu-west', 'us-east', 'ap-south', 'sa-east'],
          onChanged: (_) {},
          helperText: help,
        ),
};

void main() {
  setUpAll(loadFaces);

  for (final MapEntry(key: kind, value: field) in _fields.entries) {
    for (final (what, words, built) in [
      ('help', _help, field(help: _help)),
      if (kind != 'combobox' && !kind.startsWith('tag input'))
        ('error', _error, field(help: _help, error: _error)),
    ]) {
      testWidgets('a $kind reads its $what on the field', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, app) =>
                TermTheme(data: TermThemeData.dark(), child: app!),
            home: Center(
              child: SizedBox(width: 360, child: Column(children: [built])),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final report = DesignFieldWordsCheck(
          look: 'terminal',
          words: [words],
        ).check(tester.element(find.byType(Column).first));
        expect(report.problems, isEmpty);
        semantics.dispose();
      });
    }
  }
}
