// A field's help and its error are read on the field itself, as Material's
// TextField reads them, never on a node of their own beside it, as
// ui_core_test's DesignFieldWordsCheck reads them: a text field, a text area,
// a password field and a multi-select holding no tags, one and three, in a
// form field, with their help, then their error.
import 'package:fluent2_design_ui/fluent2_design_host.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'gallery_support.dart' show loadFluent2TestFonts;

Widget _app(
  Widget page, {
  double scale = 1,
  Brightness brightness = Brightness.light,
}) => WidgetsApp(
  color: const Color(0xFF000000),
  debugShowCheckedModeBanner: false,
  localizationsDelegates: const [
    RawWidgetsLocalizations.delegate,
    Fluent2Localizations.delegate,
  ],
  builder: (context, child) => MediaQuery.withClampedTextScaling(
    minScaleFactor: scale,
    maxScaleFactor: scale,
    child: Fluent2Host(brightness: brightness, child: child!),
  ),
  onGenerateRoute: (settings) => PageRouteBuilder<void>(
    settings: settings,
    pageBuilder: (context, _, _) => page,
  ),
);

const _help = 'The address receipts go to';
const _error = 'Enter an email address';

const _people = ['Ana Ruiz', 'Ben Okafor', 'Chen Wei', 'Dana Levi'];

final _controls = <String, Widget Function()>{
  'text field': Fluent2TextField.new,
  'text area': Fluent2TextArea.new,
  'password field': Fluent2PasswordField.new,
  for (final n in const [0, 1, 3])
    'multi-select holding $n tags': () => Fluent2MultiSelect<String>(
      options: [for (final p in _people) Fluent2Option(p, p)],
      selected: _people.take(n).toList(),
      onChanged: (_) {},
    ),
};

void main() {
  setUpAll(loadFluent2TestFonts);

  for (final MapEntry(key: kind, value: control) in _controls.entries) {
    for (final (what, words, error) in const [
      ('help', _help, false),
      ('error', _error, true),
    ]) {
      testWidgets('a $kind reads its $what on the field', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _app(
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 360,
                child: Column(
                  children: [
                    Fluent2FormField(
                      labelText: 'Email',
                      helperText: _help,
                      validationMessage: error ? _error : null,
                      validationState: error
                          ? Fluent2ValidationState.error
                          : null,
                      child: control(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final report = DesignFieldWordsCheck(
          look: 'fluent2',
          words: [words],
        ).check(tester.element(find.byType(Column).first));
        expect(report.problems, isEmpty);
        semantics.dispose();
      });
    }
  }
}
