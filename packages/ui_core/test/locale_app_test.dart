// A Material app that lists the 30 locales builds under any of them, with
// its Material library's delegates beside RawWidgetsLocalizations.delegate: its
// text fields find their words, and Arabic its direction. Without them, a
// Material text field under German asserts, which is why the delegates line
// names both: the README's line, which a look's gallery writes too
// (flutter_localizations, a dev dependency here, as ui_core stays on the
// widgets layer). A look loads its own material_ui and cupertino_ui words.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

Widget _gallery(
  Locale locale,
  List<LocalizationsDelegate<dynamic>> delegates,
  void Function(BuildContext context) read,
) => MaterialApp(
  locale: locale,
  localizationsDelegates: delegates,
  supportedLocales: RawWidgetsLocalizations.supportedLocales,
  home: Material(
    child: Builder(
      builder: (context) {
        read(context);
        return const Center(
          child: SizedBox(
            width: 240,
            child: TextField(decoration: InputDecoration(labelText: 'Name')),
          ),
        );
      },
    ),
  ),
);

void main() {
  for (final (locale, cancel, direction) in [
    (const Locale('de'), 'Abbrechen', TextDirection.ltr),
    (const Locale('ar'), 'الإلغاء', TextDirection.rtl),
  ]) {
    testWidgets('under $locale, a gallery with a text field builds', (
      tester,
    ) async {
      RawWidgetsLocalizations? words;
      TextDirection? shown;
      await tester.pumpWidget(
        _gallery(
          locale,
          const [
            RawWidgetsLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          (context) {
            words = RawWidgetsLocalizations.of(context);
            shown = Directionality.of(context);
          },
        ),
      );
      expect(tester.takeException(), isNull);
      expect(words?.cancelButtonLabel, cancel);
      expect(shown, direction);
      await tester.enterText(find.byType(TextField), 'Rechnung');
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('without Flutter\'s delegates, a text field under German '
      'asserts', (tester) async {
    final errors = <String>[];
    final onError = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.exceptionAsString());
    try {
      await tester.pumpWidget(
        _gallery(const Locale('de'), const [
          RawWidgetsLocalizations.delegate,
        ], (_) {}),
      );
    } finally {
      FlutterError.onError = onError;
    }
    expect(errors, contains(contains('No MaterialLocalizations found')));
  });
}
