// Each of Neumorphism's fields is read with its help and with its error: a field typed in has them on its text
// field's node, never on a node of their own beside it (DesignFieldWordsCheck).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';
import 'package:ui_core_review/ui_core_review.dart' show DesignFieldWordsCheck;

import 'support.dart';

const _help = 'Shown on the order';
const _error = 'Name the room';

Widget _host(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) =>
      NeumorphicHost(brightness: Brightness.light, child: app!),
  home: Scaffold(body: home),
);

const _cases = [('help', _help, null), ('error', null, _error)];

void main() {
  setUpAll(loadNeumorphicFonts);

  final fields = <String, Widget Function(String? help, String? error)>{
    'text field': (h, e) =>
        NeumorphicTextField(labelText: 'Room', helperText: h, errorText: e),
    'text area': (h, e) =>
        NeumorphicTextArea(labelText: 'Notes', helperText: h, errorText: e),
    'password field': (h, e) => NeumorphicPasswordField(
      labelText: 'Password',
      helperText: h,
      errorText: e,
    ),
    'input group': (h, e) => NeumorphicInputGroup(
      labelText: 'Website',
      prefix: 'https://',
      helperText: h,
      errorText: e,
    ),
    'combobox': (h, e) => NeumorphicCombobox<String>(
      labelText: 'Room',
      options: const ['Kitchen', 'Study'],
      onSelected: (_) {},
      helperText: h,
      errorText: e,
    ),
    'multi-select': (h, e) => NeumorphicMultiSelect<String>(
      labelText: 'Rooms',
      values: const [],
      options: const ['Kitchen', 'Study'],
      onChanged: (_) {},
      helperText: h,
      errorText: e,
    ),
    'multi-select holding tags': (h, e) => NeumorphicMultiSelect<String>(
      labelText: 'Rooms',
      values: const ['Kitchen'],
      options: const ['Kitchen', 'Study'],
      onChanged: (_) {},
      helperText: h,
      errorText: e,
    ),
    'one-time code': (h, e) =>
        NeumorphicInputOtp(labelText: 'Code', helperText: h, errorText: e),
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
          look: 'Neumorphism',
          words: [?help, ?error],
        ).check(tester.element(find.byType(Center).last)).verify();
        semantics.dispose();
      });
    }
  }
}
