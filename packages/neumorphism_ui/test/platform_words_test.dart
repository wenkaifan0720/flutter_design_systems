// The package's own Material and Cupertino words (lib/src/neumorphism/internal/platform_words.dart, the package's twin
// of the catalog's English file). An app on Flutter's own MaterialApp and flutter_localizations gives the widgets'
// words in its language but none of material_ui's or cupertino_ui's: the theme gives those, in the app's language
// where material_ui and cupertino_ui translate it and in English where they don't, so a field's copy and paste menu
// opens without a throw and reads in the app's language.
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

/// The widgets' words in the app's language, as flutter_localizations gives an app: the one of material_ui's
/// delegates that is neither its Material nor its Cupertino words.
final LocalizationsDelegate<WidgetsLocalizations> _widgetsWords =
    GlobalMaterialLocalizations.delegates
        .whereType<LocalizationsDelegate<WidgetsLocalizations>>()
        .single;

void main() {
  for (final (locale, direction, copy) in const [
    (Locale('de'), TextDirection.ltr, 'Kopieren'),
    (Locale('ar'), TextDirection.rtl, 'نسخ'),
    (Locale('xx'), TextDirection.ltr, 'Copy'),
  ]) {
    testWidgets(
      'under an app in ${locale.languageCode}, a field\'s menu reads $copy',
      (tester) async {
        final text = TextEditingController(text: 'Morgan');
        addTearDown(text.dispose);
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF000000),
            locale: locale,
            // An app in a language nobody here speaks keeps it, rather than falling back to the first one listed.
            localeResolutionCallback: (wanted, _) => wanted,
            supportedLocales: DesignLocalizations.supportedLocales,
            localizationsDelegates: [
              DesignLocalizations.delegate,
              _widgetsWords,
            ],
            builder: (context, _) => Directionality(
              textDirection: direction,
              child: NeumorphicTheme(
                data: NeumorphicThemeData.porcelain(),
                child: Overlay.wrap(
                  child: Center(
                    child: SizedBox(
                      width: 320,
                      child: NeumorphicTextField(
                        label: 'Name',
                        controller: text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final editable = find.byType(EditableText);
        final field = tester.element(editable);
        expect(
          MaterialLocalizations.of(field).copyButtonLabel,
          copy,
          reason: 'Material\'s words are in the app\'s language',
        );
        expect(
          CupertinoLocalizations.of(field).copyButtonLabel,
          copy,
          reason: 'Cupertino\'s words are in the app\'s language',
        );
        final word = direction == TextDirection.rtl
            ? tester.getTopRight(editable) + const Offset(-12, 8)
            : tester.getTopLeft(editable) + const Offset(12, 8);
        await tester.tapAt(word);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tapAt(word);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          text.selection.isCollapsed,
          isFalse,
          reason: 'the word is selected',
        );
        expect(find.text(copy), findsOneWidget, reason: 'its menu reads $copy');
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.iOS,
        TargetPlatform.android,
      }),
    );
  }
}
