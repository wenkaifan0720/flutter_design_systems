// A picker's title is Fluent 2's own English ("Choose a time", "Choose a date", "Choose dates") only in English or
// where the app gives Fluent 2 words of its own: in another language the time and date pickers take ui_core's words
// (RawPickerWords: "Uhrzeit auswählen" in German), as does a time field's prompt; the range picker, which ui_core has
// no word for, shows no title and a screen reader hears ui_core's word for a dialog in the app's language. And the
// theme's fontFamilyFallback reaches every step of the type ramp (a typeface of the app's own too), the host's default
// words and a part's words.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

/// A typeface of an app's own, as Stint's: its own style, slanted.
class _Slanted extends Fluent2Typeface {
  const _Slanted();

  @override
  TextStyle style(double size, double line, int weight, Color color) => super
      .style(size, line, weight, color)
      .copyWith(fontStyle: FontStyle.italic, fontFamilyFallback: const ['Own']);
}

/// An app's own German word for the time picker's title.
class _OwnWords extends Fluent2LocalizationsEn {
  const _OwnWords();

  @override
  String get chooseTime => 'Uhrzeit wählen';
}

class _OwnDelegate extends LocalizationsDelegate<Fluent2Localizations> {
  const _OwnDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<Fluent2Localizations> load(Locale locale) =>
      SynchronousFuture<Fluent2Localizations>(const _OwnWords());

  @override
  bool shouldReload(_OwnDelegate old) => false;
}

Future<void> _pump(
  WidgetTester t,
  String language,
  Widget home, {
  bool own = false,
  Fluent2ThemeData? theme,
}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = const Size(390, 844);
  addTearDown(t.view.reset);
  final locale = Locale(language);
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: <Locale>[locale],
      localizationsDelegates: [
        RawWidgetsLocalizations.delegate,
        if (own) const _OwnDelegate(),
        Fluent2Localizations.delegate,
      ],
      builder: (context, child) => Fluent2Host(light: theme, child: child!),
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        pageBuilder: (context, _, _) => home,
      ),
    ),
  );
  await t.pumpAndSettle();
}

Widget _opens(Future<Object?> Function(BuildContext context) open) => Center(
  child: Builder(
    builder: (context) => Fluent2Button('Open', onPressed: () => open(context)),
  ),
);

void main() {
  for (final (name, word, open, shared)
      in <
        (
          String,
          String,
          Future<Object?> Function(BuildContext),
          String Function(RawWidgetsLocalizations)?,
        )
      >[
        (
          'time',
          'Choose a time',
          (c) => showFluent2TimePicker(c),
          (w) => w.timePickerDialHelpText,
        ),
        (
          'date',
          'Choose a date',
          (c) => showFluent2DatePicker(c),
          (w) => w.datePickerHelpText,
        ),
        (
          'date range',
          'Choose dates',
          (c) => showFluent2DateRangePicker(
            c,
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
          ),
          null,
        ),
      ]) {
    testWidgets('the $name picker is titled "$word" in English', (t) async {
      await _pump(t, 'en', _opens(open));
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      expect(find.text(word), findsOneWidget);
    });

    testWidgets('in German the $name picker shows no English title, '
        "and ui_core's words where it has them", (t) async {
      final semantics = t.ensureSemantics();
      await _pump(t, 'de', _opens(open));
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      expect(find.text(word), findsNothing);
      final words = RawWidgetsLocalizations.of(
        t.element(find.byType(Fluent2Dialog)),
      );
      if (shared != null) {
        expect(find.text(shared(words)), findsOneWidget);
        expect(
          shared(words),
          isNot(shared(const DefaultRawWidgetsLocalizations())),
          reason: "ui_core's German word",
        );
      } else {
        expect(words.dialogLabel, isNot('Dialog'), reason: "ui_core's German");
        expect(find.bySemanticsLabel(words.dialogLabel), findsWidgets);
      }
      semantics.dispose();
    });
  }

  testWidgets("in German an app's own word titles the time picker", (t) async {
    await _pump(t, 'de', _opens((c) => showFluent2TimePicker(c)), own: true);
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
    expect(find.text('Uhrzeit wählen'), findsOneWidget);
  });

  for (final (language, shows) in [('en', true), ('de', false)]) {
    testWidgets('a time field prompts "Choose a time" only in English, '
        "else in ui_core's words ($language)", (t) async {
      await _pump(
        t,
        language,
        Center(
          child: SizedBox(
            width: 240,
            child: Fluent2TimePicker(onChanged: (_) {}),
          ),
        ),
      );
      expect(find.text('Choose a time'), shows ? findsOneWidget : findsNothing);
      if (!shows) {
        final words = RawWidgetsLocalizations.of(
          t.element(find.byType(Fluent2TimePicker)),
        );
        expect(find.text(words.timePickerDialHelpText), findsOneWidget);
      }
    });
  }

  group("the theme's fontFamilyFallback", () {
    const fallback = <String>['NotoSansJP'];
    final theme = Fluent2ThemeData.lapis().copyWith(
      fontFamilyFallback: fallback,
    );

    test('reaches every step of the type ramp', () {
      final steps = <String, TextStyle>{
        'caption2': theme.caption2,
        'caption2Strong': theme.caption2Strong,
        'caption1': theme.caption1,
        'caption1Strong': theme.caption1Strong,
        'caption1Stronger': theme.caption1Stronger,
        'body1': theme.body1,
        'body1Strong': theme.body1Strong,
        'body1Stronger': theme.body1Stronger,
        'body2': theme.body2,
        'subtitle2': theme.subtitle2,
        'subtitle2Stronger': theme.subtitle2Stronger,
        'subtitle1': theme.subtitle1,
        'title3': theme.title3,
        'title2': theme.title2,
        'title1': theme.title1,
        'largeTitle': theme.largeTitle,
        'display': theme.display,
      };
      for (final MapEntry(:key, :value) in steps.entries) {
        expect(value.fontFamilyFallback, fallback, reason: key);
      }
      expect(Fluent2ThemeData.lapis().body1.fontFamilyFallback, isNull);
    });

    test("follows a typeface of the app's own, the face named whole", () {
      final package = Fluent2Typeface.look.package;
      String whole(String family) =>
          package == null ? family : 'packages/$package/$family';
      final own = theme.copyWith(typeface: const _Slanted()).body1;
      expect(own.fontStyle, FontStyle.italic);
      expect(own.fontFamily, whole('Selawik'));
      expect(own.fontFamilyFallback, [whole('Own'), ...fallback]);
      expect(theme.body1.fontFamily, whole('Selawik'));
      expect(theme.body1.fontSize, Fluent2ThemeData.lapis().body1.fontSize);
      expect(theme.body1.height, Fluent2ThemeData.lapis().body1.height);
      expect(theme.body1.letterSpacing, 0);
      expect(theme.body1.leadingDistribution, TextLeadingDistribution.even);
    });

    test('rides along from(brand:), copyWith, lerp and equality', () {
      final custom = Fluent2ThemeData.from(
        brand: const Color(0xFF8A3FFC),
        fontFamilyFallback: fallback,
      );
      expect(custom.fontFamilyFallback, fallback);
      expect(custom.title1.fontFamilyFallback, fallback);
      expect(
        theme.copyWith(density: Fluent2Density.compact).fontFamilyFallback,
        fallback,
      );
      expect(
        theme.lerp(Fluent2ThemeData.lapis(), .2).fontFamilyFallback,
        fallback,
      );
      expect(
        theme.lerp(Fluent2ThemeData.lapis(), .8).fontFamilyFallback,
        isEmpty,
      );
      expect(theme, isNot(Fluent2ThemeData.lapis()));
      expect(
        theme,
        Fluent2ThemeData.lapis().copyWith(fontFamilyFallback: fallback),
      );
    });

    testWidgets("reaches the host's default words and a part's words", (
      t,
    ) async {
      late BuildContext page;
      await _pump(
        t,
        'en',
        Builder(
          builder: (context) {
            page = context;
            return Center(child: Fluent2Button('Save', onPressed: () {}));
          },
        ),
        theme: theme,
      );
      expect(DefaultTextStyle.of(page).style.fontFamilyFallback, fallback);
      final label = t.widget<RichText>(
        find.descendant(
          of: find.byType(Fluent2Button),
          matching: find.byType(RichText),
        ),
      );
      expect(label.text.style?.fontFamilyFallback, fallback);
    });
  });
}
