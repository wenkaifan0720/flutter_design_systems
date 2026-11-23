// The published package's Material and Cupertino words (its
// lib_overrides twin of internal/platform_words.dart): in an app that gives
// none of the primitives' own, a field's context menu speaks the app's
// language where material_ui and cupertino_ui do, and English elsewhere.
// Package-only: the look's source keeps English in any locale.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final theme = ExpressiveThemeData.preset('baseline', Brightness.light);
  for (final (locale, copy) in const [
    (Locale('de'), 'Kopieren'),
    (Locale('ar'), 'نسخ'),
    // A language neither speaks: English.
    (Locale('tlh'), 'Copy'),
  ]) {
    testWidgets(
      "a field's context menu in an app in ${locale.languageCode} says $copy",
      (tester) async {
        final controller = TextEditingController(text: 'Porto in May');
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: [const Locale('en'), locale],
            localizationsDelegates: const [RawWidgetsLocalizations.delegate],
            builder: (context, child) =>
                ExpressiveTheme(data: theme, child: child!),
            home: Center(
              child: SizedBox(
                width: 300,
                child: ExpressiveTextField(
                  controller: controller,
                  labelText: 'Name',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // Flutter's notice that MaterialApp's English-only delegates do not
        // speak the app's language is a warning, not the failure looked for.
        final notice = tester.takeException();
        expect(notice == null || '$notice'.startsWith('Warning: '), isTrue);
        await tester.longPress(find.byType(EditableText));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(copy), findsOneWidget);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );
  }
}
