/// A theme supplies missing primitive words without replacing app resources.
library;

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizations;
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
                    labelText: 'Name',
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

  // An app in another language whose delegates give no Material or
  // Cupertino words of the primitives' own types (a MaterialApp's load
  // English only; flutter_localizations' are package:flutter's types): a
  // field, typed in and its context menu opened, throws nothing on Android
  // or iOS (0.1.1 threw "No CupertinoLocalizations found" on iOS). With the
  // theme under the app's home rather than in its builder, the selection's
  // handles and menu build in the navigator's overlay, above the theme: the
  // theme they capture brings its words along.
  for (final underHome in const [false, true]) {
    for (final locale in const [Locale('en'), Locale('de'), Locale('ar')]) {
      _fieldInApp(theme, locale, underHome: underHome);
    }
  }
}

void _fieldInApp(
  ExpressiveThemeData theme,
  Locale locale, {
  required bool underHome,
}) {
  testWidgets(
    'a field and its context menu in an app in ${locale.languageCode}, '
    'the theme ${underHome ? 'under home' : 'in the builder'}',
    (tester) async {
      final controller = TextEditingController(text: 'Lisbon in spring');
      addTearDown(controller.dispose);
      MaterialLocalizations? material;
      CupertinoLocalizations? cupertino;
      final page = Builder(
        builder: (context) {
          material = Localizations.of<MaterialLocalizations>(
            context,
            MaterialLocalizations,
          );
          cupertino = Localizations.of<CupertinoLocalizations>(
            context,
            CupertinoLocalizations,
          );
          return Center(
            child: SizedBox(
              width: 300,
              child: ExpressiveTextField(
                controller: controller,
                labelText: 'Name',
              ),
            ),
          );
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('de'), Locale('ar')],
          localizationsDelegates: const [_AppWordsDelegate()],
          builder: underHome
              ? null
              : (context, child) => ExpressiveTheme(data: theme, child: child!),
          home: underHome ? ExpressiveTheme(data: theme, child: page) : page,
        ),
      );
      await tester.pumpAndSettle();
      // Flutter's own notice that the app's English-only delegates do not
      // speak its language is a warning, not the failure looked for.
      final notice = tester.takeException();
      expect(
        notice == null || '$notice'.startsWith('Warning: '),
        isTrue,
        reason: '$notice',
      );
      expect(Localizations.localeOf(tester.element(find.text('Name'))), locale);
      expect(material, isNotNull);
      expect(cupertino, isNotNull);
      final field = find.byType(EditableText);
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, 'Porto in May');
      await tester.pumpAndSettle();
      await tester.longPress(field);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget.runtimeType.toString().contains('TextSelectionToolbar') &&
              widget.runtimeType.toString().endsWith('Button'),
        ),
        findsWidgets,
        reason: 'the context menu is open',
      );
      expect(controller.text, 'Porto in May');
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );
}
