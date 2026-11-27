// A Fluent 2 app in any language builds: the machinery under the look (a
// field's editable and its selection, a calendar's dates, a sheet's route)
// needs Material's and Cupertino's words, and an app that gives none for its
// language (or gives another library's) gets them from the theme rather
// than a throw: English here, Material's and Cupertino's own translations in
// the published package. ui_core's shared words still speak the app's
// language.
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizations;
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:material_ui/material_ui.dart'
    show DefaultMaterialLocalizations, MaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

/// An app in [locale] with ui_core's and Fluent 2's words and no Material or
/// Cupertino words at all (but [words], listed first), Fluent 2's host round
/// its one page.
Widget _app(
  Locale locale,
  Widget page, {
  List<LocalizationsDelegate<Object?>> words = const [],
}) => WidgetsApp(
  color: const Color(0xFF000000),
  locale: locale,
  supportedLocales: RawWidgetsLocalizations.supportedLocales,
  localizationsDelegates: [
    ...words,
    RawWidgetsLocalizations.delegate,
    Fluent2Localizations.delegate,
  ],
  builder: (context, child) => Fluent2Host(child: child!),
  onGenerateRoute: (settings) => PageRouteBuilder<void>(
    settings: settings,
    pageBuilder: (context, _, _) =>
        Center(child: SizedBox(width: 320, child: page)),
  ),
);

/// Types two words in the field, double-taps the first so the selection's
/// menu opens, then selects all and asks for the menu again, as copy and
/// paste would.
Future<EditableTextState> _select(WidgetTester tester) async {
  await tester.tap(find.byType(EditableText));
  await tester.pump();
  await tester.enterText(find.byType(EditableText), 'Hallo Welt');
  await tester.pumpAndSettle();
  final at = tester.getTopLeft(find.byType(EditableText)) + const Offset(12, 8);
  await tester.tapAt(at);
  await tester.pump(const Duration(milliseconds: 60));
  await tester.tapAt(at);
  await tester.pumpAndSettle();
  final state = tester.state<EditableTextState>(find.byType(EditableText));
  state.selectAll(SelectionChangedCause.toolbar);
  await tester.pump();
  state.showToolbar();
  await tester.pumpAndSettle();
  return state;
}

void main() {
  final platforms = const TargetPlatformVariant({
    TargetPlatform.android,
    TargetPlatform.iOS,
  });

  for (final locale in const [Locale('ar'), Locale('de')]) {
    final name = locale.languageCode;

    for (final (label, field) in [
      (
        'text field',
        Fluent2TextField(value: '', semanticLabel: 'Name', onChanged: (_) {}),
      ),
      ('search box', Fluent2SearchBox(value: '', onChanged: (_) {})),
    ]) {
      testWidgets(
        'a $label builds, takes words and opens its selection menu '
        'in $name with no Material or Cupertino words',
        variant: platforms,
        (tester) async {
          await tester.pumpWidget(_app(locale, field));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final state = await _select(tester);
          expect(tester.takeException(), isNull);
          expect(state.textEditingValue.text, 'Hallo Welt');
          expect(state.selectionOverlay?.toolbarIsVisible, isTrue);
          // The machinery's words are there: English in the module, the
          // app's language in the published package (its locale test).
          final context = tester.element(find.byType(EditableText));
          final copy = anyOf('Copy', name == 'de' ? 'Kopieren' : 'نسخ');
          expect(MaterialLocalizations.of(context).copyButtonLabel, copy);
          expect(CupertinoLocalizations.of(context).copyButtonLabel, copy);
          // ui_core's shared words speak the app's language under the host.
          expect(
            RawWidgetsLocalizations.of(context).closeButtonLabel,
            RawWidgetsLocalizations.forLocale(locale).closeButtonLabel,
          );
          expect(
            RawWidgetsLocalizations.of(context).closeButtonLabel,
            isNot('Close'),
          );
        },
      );
    }

    testWidgets(
      'a date picker opens its calendar in $name with no Material '
      'words',
      variant: platforms,
      (tester) async {
        await tester.pumpWidget(
          _app(
            locale,
            Fluent2DatePicker(
              value: DateTime(2026, 11, 14),
              semanticLabel: 'Due',
              onChanged: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Fluent2DatePicker));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(Fluent2Calendar), findsOneWidget);
      },
    );

    testWidgets(
      'a rating counts and a sheet opens in $name with no Material '
      'words',
      variant: platforms,
      (tester) async {
        await tester.pumpWidget(
          _app(
            locale,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Fluent2RatingDisplay(value: 4, count: 1204),
                Builder(
                  builder: (context) => Fluent2Button(
                    'Open',
                    onPressed: () => Fluent2Sheet.show<void>(
                      context,
                      title: 'Sheet',
                      builder: (_) => const [Text('Body')],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Body'), findsOneWidget);
      },
    );
  }

  for (final (label, words, copy) in [
    ('English', const <LocalizationsDelegate<Object?>>[], 'Copy'),
    (
      'German Material words',
      const [_Words<MaterialLocalizations>(_GermanMaterial())],
      'Kopieren',
    ),
    (
      'its own Fluent 2 words',
      const [
        _Words<MaterialLocalizations>(_GermanMaterial()),
        _Words<Fluent2Localizations>(_OwnFluent()),
      ],
      'Kopie',
    ),
  ]) {
    testWidgets('a field\'s menu reads "$copy" under an app with $label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          label == 'English' ? const Locale('en') : const Locale('de'),
          Fluent2TextField(value: '', semanticLabel: 'Name', onChanged: (_) {}),
          words: words,
        ),
      );
      await tester.pumpAndSettle();
      await _select(tester);
      expect(tester.takeException(), isNull);
      expect(find.text(copy), findsOneWidget);
    });
  }

  testWidgets(
    'a field selects on iOS with its theme under home, not in the '
    'app\'s builder',
    variant: platforms,
    (tester) async {
      // The handles and the menu build in the root overlay, above the theme:
      // they draw in the default preset rather than throw.
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          onGenerateRoute: (settings) => PageRouteBuilder<void>(
            settings: settings,
            pageBuilder: (context, _, _) => Fluent2Host(
              child: Center(
                child: SizedBox(
                  width: 320,
                  child: Fluent2TextField(
                    value: '',
                    semanticLabel: 'Name',
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = await _select(tester);
      expect(tester.takeException(), isNull);
      expect(state.selectionOverlay?.toolbarIsVisible, isTrue);
      expect(find.text('Copy'), findsOneWidget);
    },
  );

  testWidgets('Fluent 2\'s own words load in any locale, in English until an '
      'app gives its own', (tester) async {
    late Fluent2Localizations words;
    await tester.pumpWidget(
      _app(
        const Locale('ja'),
        Builder(
          builder: (context) {
            words = Fluent2Localizations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(words, isA<Fluent2LocalizationsEn>());
  });
}

/// Material's words with a German copy.
class _GermanMaterial extends DefaultMaterialLocalizations {
  const _GermanMaterial();

  @override
  String get copyButtonLabel => 'Kopieren';
}

/// An app's own Fluent 2 words.
class _OwnFluent extends Fluent2LocalizationsEn {
  const _OwnFluent();

  @override
  String get copy => 'Kopie';
}

/// [words] in any locale.
class _Words<T> extends LocalizationsDelegate<T> {
  const _Words(this.words);

  final T words;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) => SynchronousFuture<T>(words);

  @override
  bool shouldReload(_Words<T> old) => false;

  @override
  Type get type => T;
}
