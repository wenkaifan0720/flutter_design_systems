// Minimal's parts under an app in another language that gives none of the
// look's Material or Cupertino words: an app on flutter_localizations gives
// Flutter's own types, not those of the Material the look is built on. The
// machinery under a part (an editable, its text menu, a route) still needs
// words, Cupertino's for the text menu on iOS; the look gives them in the
// app's language, and nothing throws.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

Widget _app(Locale locale, Widget part) => WidgetsApp(
  color: const Color(0xFF000000),
  locale: locale,
  supportedLocales: RawWidgetsLocalizations.supportedLocales,
  localizationsDelegates: const [RawWidgetsLocalizations.delegate],
  builder: (context, _) => Directionality(
    textDirection: locale.languageCode == 'ar'
        ? TextDirection.rtl
        : TextDirection.ltr,
    child: MinimalTheme(
      data: MinimalThemeData.standard(),
      child: Navigator(
        onGenerateRoute: (_) => PageRouteBuilder<void>(
          pageBuilder: (_, _, _) =>
              Center(child: SizedBox(width: 320, child: part)),
        ),
      ),
    ),
  ),
);

final Map<String, Widget Function()> _parts = {
  'text field': () => const MinimalTextField(label: 'Name', hint: 'Your name'),
  'search field': () => const MinimalSearchField(),
  'composer': () => MinimalComposer(onSend: (_) {}),
  'text area': () => const MinimalTextArea(hint: 'Notes'),
  'password field': () => const MinimalPasswordField(label: 'Password'),
  'combobox': () =>
      const MinimalCombobox<String>(options: ['Bug', 'Feature'], label: 'Type'),
  'code field': () => const MinimalInputOtp(label: 'Code'),
  'date picker': () => MinimalDatePicker(
    label: 'Due',
    value: DateTime(2026, 11, 14),
    onChanged: (_) {},
  ),
};

// A menu's words: English, or Material's and Cupertino's own translation.
const _copy = {'Copy', 'Kopieren', 'نسخ'};
const _paste = {'Paste', 'Einfügen', 'Einsetzen', 'لصق'};

Finder _oneOf(Set<String> words) =>
    find.byWidgetPredicate((w) => w is Text && words.contains(w.data));

void main() {
  // Every part in both languages on both platforms. The everyday tier takes
  // each part once, in Arabic and German in turn; the sweep tier the rest.
  for (final (l, locale) in const [Locale('ar'), Locale('de')].indexed) {
    for (final (p, MapEntry(key: name, value: build))
        in _parts.entries.indexed) {
      testWidgets(
        'a $name builds and opens its menu under an app in '
        '${locale.languageCode} with no Material or Cupertino words',
        tags: p % 2 == l ? null : 'sweep',
        variant: const TargetPlatformVariant({
          TargetPlatform.android,
          TargetPlatform.iOS,
        }),
        (tester) async {
          await tester.pumpWidget(_app(locale, build()));
          await tester.pump();
          expect(tester.takeException(), isNull);
          final editable = find.byType(EditableText);
          if (name == 'code field') {
            // A code's menu is its own: a long press offers Paste.
            tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
              SystemChannels.platform,
              (call) async => switch (call.method) {
                'Clipboard.hasStrings' => {'value': true},
                'Clipboard.getData' => {'text': '123456'},
                _ => null,
              },
            );
            addTearDown(
              () => tester.binding.defaultBinaryMessenger
                  .setMockMethodCallHandler(SystemChannels.platform, null),
            );
            await tester.longPress(find.byType(MinimalInputOtp));
            await tester.pump(const Duration(milliseconds: 400));
            expect(tester.takeException(), isNull);
            expect(_oneOf(_paste), findsOneWidget);
          } else if (editable.evaluate().isNotEmpty) {
            // Typed into, selected, and its text menu open: Material's words
            // on Android, Cupertino's on iOS.
            await tester.enterText(editable.first, '123456');
            await tester.pump();
            final state = tester.state<EditableTextState>(editable.first);
            state.selectAll(SelectionChangedCause.toolbar);
            await tester.pump();
            expect(state.showToolbar(), isTrue);
            await tester.pump(const Duration(milliseconds: 400));
            expect(tester.takeException(), isNull);
            // A hidden password offers no Copy.
            if (name != 'password field') {
              expect(_oneOf(_copy), findsOneWidget);
            }
          } else {
            // A picker opens its calendar.
            await tester.tap(find.byType(MinimalDatePicker));
            await tester.pump(const Duration(milliseconds: 400));
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('the shared words come in the app\'s language', (tester) async {
    late MinimalLocalizations words;
    await tester.pumpWidget(
      _app(
        const Locale('de'),
        Builder(
          builder: (context) {
            words = MinimalLocalizations.of(context);
            return const MinimalTextField(label: 'Name');
          },
        ),
      ),
    );
    final shared = RawWidgetsLocalizations.forLocale(const Locale('de'));
    expect(words.cancel, shared.cancelButtonLabel);
    expect(words.cancel, isNot('Cancel'));
  });
}
