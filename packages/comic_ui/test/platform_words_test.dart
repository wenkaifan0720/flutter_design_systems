// The package's own Material and Cupertino words (its twin of internal/platform_words.dart): under an app that gives
// none of material_ui's or cupertino_ui's, a field's text menu says the app's language where material_ui knows it,
// and English where it doesn't, on Android and iOS. The ComicHost stands under home, as many apps put it: the
// selection's handles and menu stand in the app's overlay, above it, and still find Comic's theme.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/comic_host.dart';

void main() {
  for (final (locale, direction, copy) in const [
    (Locale('de'), TextDirection.ltr, 'Kopieren'),
    (Locale('ar'), TextDirection.rtl, 'نسخ'),
    (Locale('tlh'), TextDirection.ltr, 'Copy'),
  ]) {
    testWidgets(
      'a field\'s menu under an app in ${locale.languageCode} says "$copy"',
      (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF000000),
            locale: locale,
            supportedLocales: [locale],
            localizationsDelegates: const [RawWidgetsLocalizations.delegate],
            pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, _, _) => builder(context),
            ),
            home: Directionality(
              textDirection: direction,
              child: ComicHost(
                light: ComicThemeData.offset(),
                child: const Center(
                  child: SizedBox(
                    width: 320,
                    child: ComicTextField(hintText: 'Your name'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.enterText(find.byType(EditableText), 'Ada Lovelace');
        await tester.pump();
        final state = tester.state<EditableTextState>(
          find.byType(EditableText),
        );
        state.selectAll(SelectionChangedCause.toolbar);
        await tester.pump();
        state.showToolbar();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.byType(ComicTextContextMenu), findsOneWidget);
        expect(find.text(copy), findsOneWidget);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );
  }
}
