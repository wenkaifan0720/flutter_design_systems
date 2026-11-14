/// A theme supplies missing primitive words without replacing app resources.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class _AppWords {
  const _AppWords();
}

class _AppWordsDelegate extends LocalizationsDelegate<_AppWords> {
  const _AppWordsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<_AppWords> load(Locale locale) => SynchronousFuture(const _AppWords());

  @override
  bool shouldReload(_AppWordsDelegate old) => false;
}

class _TranslatedMaterial extends DefaultMaterialLocalizations {
  const _TranslatedMaterial();

  @override
  String get pasteButtonLabel => 'App translation';
}

class _TranslatedDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _TranslatedDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(const _TranslatedMaterial());

  @override
  bool shouldReload(_TranslatedDelegate old) => false;
}

void main() {
  final theme = ExpressiveThemeData.preset('baseline', Brightness.light);
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets(
      'WidgetsApp primitive fallback preserves $locale app words and direction',
      (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        final direction = locale.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr;
        late Locale readLocale;
        late TextDirection readDirection;
        _AppWords? words;
        MaterialLocalizations? primitives;
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xff000000),
            locale: locale,
            supportedLocales: [locale],
            localizationsDelegates: const [_AppWordsDelegate()],
            pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, animation, secondaryAnimation) =>
                  builder(context),
            ),
            builder: (context, child) => Directionality(
              textDirection: direction,
              child: ExpressiveTheme(data: theme, child: child!),
            ),
            home: Builder(
              builder: (context) {
                readLocale = Localizations.localeOf(context);
                readDirection = Directionality.of(context);
                words = Localizations.of<_AppWords>(context, _AppWords);
                primitives = Localizations.of<MaterialLocalizations>(
                  context,
                  MaterialLocalizations,
                );
                return Center(
                  child: ExpressiveTextField(
                    controller: controller,
                    label: 'Name',
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(readLocale, locale);
        expect(readDirection, direction);
        expect(words, isA<_AppWords>());
        expect(primitives, isNotNull);
        await tester.enterText(find.byType(EditableText), 'Ada');
        expect(controller.text, 'Ada');
      },
    );
  }

  testWidgets('a supplied primitive translation wins over the fallback', (
    tester,
  ) async {
    String? paste;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TranslatedDelegate()],
        home: ExpressiveTheme(
          data: theme,
          child: Builder(
            builder: (context) {
              paste = MaterialLocalizations.of(context).pasteButtonLabel;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(paste, 'App translation');
    expect(tester.takeException(), isNull);
  });
}
