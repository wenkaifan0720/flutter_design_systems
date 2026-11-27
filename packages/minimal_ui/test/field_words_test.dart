// Each of Minimal's fields is read with its help and with its error: a field
// typed in has them on its text field's node, never on a node of their own
// beside it (DesignFieldWordsCheck).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_review/ui_core_review.dart';
import 'package:minimal_ui/minimal_ui.dart';

const _help = 'Shown on Today';
const _error = 'Name the habit';

Widget _app(Widget field) => MaterialApp(
  builder: (context, app) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: app!,
  ),
  home: Scaffold(
    body: Center(child: SizedBox(width: 360, child: field)),
  ),
);

const _cases = [('help', _help, null), ('error', null, _error)];

void main() {
  final fields = <String, Widget Function(String? help, String? error)>{
    'text field': (h, e) =>
        MinimalTextField(labelText: 'Habit name', helperText: h, errorText: e),
    'text area': (h, e) => MinimalTextArea(
      labelText: 'Why it matters',
      helperText: h,
      errorText: e,
    ),
    'password field': (h, e) => MinimalPasswordField(
      labelText: 'Password',
      helperText: h,
      errorText: e,
    ),
    'input group': (h, e) => MinimalInputGroup(
      labelText: 'Water',
      suffixText: 'glasses',
      helperText: h,
      errorText: e,
    ),
    'combobox': (h, e) => MinimalCombobox<String>(
      labelText: 'Habit',
      options: const ['Read', 'Walk'],
      onSelected: (_) {},
      helperText: h,
      errorText: e,
    ),
    'multi-select': (h, e) => MinimalMultiSelect<String>(
      labelText: 'Tags',
      values: const [],
      options: const ['Health', 'Work'],
      onChanged: (_) {},
      helperText: h,
      errorText: e,
    ),
    'multi-select holding tags': (h, e) => MinimalMultiSelect<String>(
      labelText: 'Tags',
      values: const ['Health'],
      options: const ['Health', 'Work'],
      onChanged: (_) {},
      helperText: h,
      errorText: e,
    ),
  };
  for (final MapEntry(key: kind, value: field) in fields.entries) {
    for (final (words, help, error) in _cases) {
      testWidgets('a $kind reads its $words on its text field', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(_app(field(help, error)));
        await tester.pump(const Duration(seconds: 1));
        DesignFieldWordsCheck(
          look: 'Minimal',
          words: [?help, ?error],
        ).check(tester.element(find.byType(Center).first)).verify();
        semantics.dispose();
      });
    }
  }

  testWidgets('a one-time code reads its error on its field', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(const MinimalInputOtp(labelText: 'Code', errorText: _error)),
    );
    await tester.pump(const Duration(seconds: 1));
    const DesignFieldWordsCheck(
      look: 'Minimal',
      words: [_error],
    ).check(tester.element(find.byType(Center).first)).verify();
    semantics.dispose();
  });
}
