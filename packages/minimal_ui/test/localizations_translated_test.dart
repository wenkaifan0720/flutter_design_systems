// The package's own Material and Cupertino words: under an app that gives
// none of them, a field's text menu speaks the app's language where
// material_ui and cupertino_ui have it, and English where they don't.
// (Package only: drip's twin of platform_words.dart is English throughout.)
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

Widget _app(Locale locale) => WidgetsApp(
  color: const Color(0xFF000000),
  locale: locale,
  supportedLocales: [locale],
  localizationsDelegates: const [DesignLocalizations.delegate],
  builder: (context, _) => Directionality(
    textDirection: locale.languageCode == 'ar'
        ? TextDirection.rtl
        : TextDirection.ltr,
    child: MinimalTheme(
      data: MinimalThemeData.standard(),
      child: Navigator(
        onGenerateRoute: (_) => PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => const Center(
            child: SizedBox(width: 320, child: MinimalTextField(label: 'Name')),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _openMenu(WidgetTester tester) async {
  final editable = find.byType(EditableText);
  await tester.enterText(editable, 'Hallo Welt');
  await tester.pump();
  final state = tester.state<EditableTextState>(editable);
  state.selectAll(SelectionChangedCause.toolbar);
  await tester.pump();
  expect(state.showToolbar(), isTrue);
  await tester.pump(const Duration(milliseconds: 400));
  expect(tester.takeException(), isNull);
}

void main() {
  for (final (locale, copy) in const [
    (Locale('de'), 'Kopieren'),
    (Locale('ar'), 'نسخ'),
    // A language neither library speaks: English.
    (Locale('tlh'), 'Copy'),
  ]) {
    testWidgets(
      'a field\'s text menu under an app in ${locale.languageCode} says '
      '"$copy"',
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
      (tester) async {
        await tester.pumpWidget(_app(locale));
        await tester.pumpAndSettle();
        await _openMenu(tester);
        expect(
          find.text(copy),
          findsOneWidget,
          reason: '$debugDefaultTargetPlatformOverride',
        );
      },
    );
  }
}
