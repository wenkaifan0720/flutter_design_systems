// Each of Retro Desktop's fields is read with its help and with its error: a field typed in has them on its text
// field's node, never on a node of their own beside it (DesignFieldWordsCheck).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:ui_core_review/ui_core_review.dart' show DesignFieldWordsCheck;

import 'support.dart';

const _help = 'Shown on the label';
const _error = 'Name the folder';

Widget _host(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) =>
      RetroDesktopHost(brightness: Brightness.light, child: app!),
  home: home,
);

const _cases = [('help', _help, null), ('error', null, _error)];

void main() {
  setUpAll(loadRetroDesktopFonts);

  final fields = <String, Widget Function(String? help, String? error)>{
    'text field': (h, e) =>
        RetroDesktopTextField(labelText: 'Folder', helperText: h, errorText: e),
    'text area': (h, e) =>
        RetroDesktopTextArea(labelText: 'Notes', helperText: h, errorText: e),
    'password field': (h, e) => RetroDesktopPasswordField(
      labelText: 'Password',
      helperText: h,
      errorText: e,
    ),
    'input group': (h, e) => RetroDesktopInputGroup(
      labelText: 'Site',
      prefix: 'https://',
      helperText: h,
      errorText: e,
    ),
    'search field': (h, e) => RetroDesktopSearchField(
      name: 'Find',
      hintText: 'Find a folder',
      helperText: h,
      errorText: e,
    ),
    'combobox': (h, e) => RetroDesktopCombobox<String>(
      labelText: 'Folder',
      options: const ['Documents', 'Pictures'],
      onSelected: (_) {},
      helperText: h,
      errorText: e,
    ),
    'one-time code': (h, e) =>
        RetroDesktopInputOtp(labelText: 'Code', helperText: h, errorText: e),
    'form field': (h, e) => RetroDesktopFormField(
      labelText: 'Folder',
      helperText: h,
      errorText: e,
      child: const RetroDesktopTextField(),
    ),
  };
  for (final MapEntry(key: kind, value: field) in fields.entries) {
    for (final (words, help, error) in _cases) {
      testWidgets('a $kind reads its $words on its text field', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(Center(child: SizedBox(width: 340, child: field(help, error)))),
        );
        await tester.pump(const Duration(seconds: 1));
        DesignFieldWordsCheck(
          look: 'Retro Desktop',
          words: [?help, ?error],
        ).check(tester.element(find.byType(Center).last)).verify();
        semantics.dispose();
      });
    }
  }
}
