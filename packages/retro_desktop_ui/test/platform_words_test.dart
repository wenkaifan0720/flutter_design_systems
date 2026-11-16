// The package's own Material and Cupertino words follow the app's language (lib/src/retro_desktop/internal/
// platform_words.dart, the package's twin of the module's English file): an app that gives none of them, in German
// or Arabic, gets material_ui's and cupertino_ui's translations, and a field's menu opens in that language on Android
// and on iOS; a locale they don't know builds in English. An app's flutter_localizations gives package:flutter's
// words, never these, so the look loads them itself.
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

void main() {
  for (final (locale, direction, copy) in const [
    (Locale('de'), TextDirection.ltr, 'Kopieren'),
    (Locale('ar'), TextDirection.rtl, 'نسخ'),
    (Locale('xx'), TextDirection.ltr, 'Copy'),
  ]) {
    testWidgets(
      'a field under an app in ${locale.languageCode} says $copy',
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
      (tester) async {
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF000000),
            locale: locale,
            supportedLocales: {
              ...DesignLocalizations.supportedLocales,
              locale,
            }.toList(),
            localizationsDelegates: const [DesignLocalizations.delegate],
            builder: (context, _) => Directionality(
              textDirection: direction,
              child: Overlay(
                initialEntries: [
                  _ownedEntry(
                    builder: (context) => RetroDesktopTheme(
                      data: RetroDesktopThemeData.classic(),
                      child: const Center(
                        child: SizedBox(
                          width: 320,
                          child: RetroDesktopTextField(
                            label: 'Name',
                            initial: 'Ada Lovelace',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final field = find.byType(EditableText);
        final at = tester.element(field);
        expect(MaterialLocalizations.of(at).copyButtonLabel, copy);
        expect(CupertinoLocalizations.of(at).copyButtonLabel, copy);
        // A double tap selects a word: the handles and the menu show, in the app's language.
        await tester.tap(field);
        await tester.pumpAndSettle();
        await tester.tap(field);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(field);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(RetroDesktopTextContextMenu), findsOneWidget);
        expect(find.text(copy), findsWidgets);
      },
    );
  }
}

/// The overlay entries a test's app built: the first is the one its Overlay took (initialEntries are read once).
final _entries = <OverlayEntry>[];

/// An overlay entry the test owns: when the test ends the one its Overlay took is removed, and every one built is
/// disposed, so the leak tracker finds none left.
OverlayEntry _ownedEntry({required WidgetBuilder builder}) {
  final entry = OverlayEntry(builder: builder);
  if (_entries.isEmpty) {
    addTearDown(() {
      _entries.first.remove();
      for (final built in _entries) {
        built.dispose();
      }
      _entries.clear();
    });
  }
  _entries.add(entry);
  return entry;
}
