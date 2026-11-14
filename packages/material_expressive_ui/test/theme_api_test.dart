/// The theme as an app on `material_ui` expects it (PACKAGE.md §3): a
/// named factory per preset, `of`/`maybeOf`, `lerp`, diagnostics, an
/// `InheritedTheme` a route captures, `AnimatedExpressiveTheme` springing
/// between themes, and the words through a `LocalizationsDelegate`.
library;

import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoApp, DefaultCupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show
        DefaultMaterialLocalizations,
        MaterialApp,
        TextSelectionTheme,
        ThemeData;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

const _presets = <String, ExpressiveThemeData Function(Brightness)>{
  'baseline': ExpressiveThemeData.baseline,
  'slate': ExpressiveThemeData.slate,
  'bloom': ExpressiveThemeData.bloom,
  'grove': ExpressiveThemeData.grove,
  'ember': ExpressiveThemeData.ember,
};

/// [child] under a bare app with [delegates], reading the theme at [read].
Widget _app(
  Widget child, {
  List<LocalizationsDelegate<dynamic>> delegates = const [],
  Locale locale = const Locale('en'),
}) => Localizations(
  locale: locale,
  delegates: [DefaultWidgetsLocalizations.delegate, ...delegates],
  child: Directionality(textDirection: TextDirection.ltr, child: child),
);

/// ui_core's shared words in French, as an app translates every look.
class _FrenchWords extends DefaultDesignLocalizations {
  const _FrenchWords();

  @override
  String get backButtonTooltip => 'Retour';
}

class _French extends LocalizationsDelegate<DesignLocalizations> {
  const _French();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'fr';

  @override
  Future<DesignLocalizations> load(Locale locale) =>
      SynchronousFuture(const _FrenchWords());

  @override
  bool shouldReload(_French old) => false;
}

void main() {
  group('presets', () {
    for (final MapEntry(key: id, value: factory) in _presets.entries) {
      test('$id: its factory is the preset, light and dark, baked apart', () {
        for (final brightness in Brightness.values) {
          final made = factory(brightness);
          final preset = ExpressiveThemeData.preset(id, brightness);
          expect(made.id, id);
          expect(made.brightness, brightness);
          expect(made.colors.primary, preset.colors.primary);
          expect(made.colors.surface, preset.colors.surface);
        }
        expect(
          factory(Brightness.dark).colors.surface,
          isNot(factory(Brightness.light).colors.surface),
        );
      });
    }

    test('the five presets are five seeds', () {
      final primaries = {
        for (final f in _presets.values) f(Brightness.light).colors.primary,
      };
      expect(primaries, hasLength(_presets.length));
    });
  });

  group('lerp', () {
    final a = ExpressiveThemeData.grove();
    final b = ExpressiveThemeData.ember();

    test('lands on each end and blends between', () {
      expect(
        ExpressiveThemeData.lerp(a, b, 0).colors.primary,
        a.colors.primary,
      );
      expect(
        ExpressiveThemeData.lerp(a, b, 1).colors.primary,
        b.colors.primary,
      );
      final mid = ExpressiveThemeData.lerp(a, b, 0.5).colors.primary;
      expect(mid, Color.lerp(a.colors.primary, b.colors.primary, 0.5));
      expect(identical(ExpressiveThemeData.lerp(a, a, 0.3), a), isTrue);
    });

    test('what does not interpolate switches at one half', () {
      expect(ExpressiveThemeData.lerp(a, b, 0.49).id, a.id);
      expect(ExpressiveThemeData.lerp(a, b, 0.5).id, b.id);
      expect(ExpressiveThemeData.lerp(a, b, 0.49).motion, a.motion);
      expect(ExpressiveThemeData.lerp(a, b, 0.5).motion, b.motion);
    });
  });

  test('diagnostics name the preset, the mode and the scales', () {
    final text = ExpressiveThemeData.bloom(Brightness.dark)
        .toDiagnosticsNode()
        .toStringDeep();
    expect(text, contains('id: "bloom"'));
    expect(text, contains('brightness: dark'));
    expect(text, contains('colors:'));
    expect(text, contains('motion:'));
  });

  testWidgets(
    'of reads the nearest ExpressiveTheme; maybeOf is null with none',
    (tester) async {
      ExpressiveThemeData? outside;
      late ExpressiveThemeData fallback;
      late ExpressiveThemeData near;
      late ExpressiveThemeData nested;
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              Builder(
                builder: (context) {
                  outside = ExpressiveTheme.maybeOf(context);
                  fallback = ExpressiveTheme.of(context);
                  return const SizedBox();
                },
              ),
              ExpressiveTheme(
                data: ExpressiveThemeData.grove(),
                child: Builder(
                  builder: (context) {
                    near = ExpressiveThemeData.of(context);
                    return ExpressiveTheme(
                      data: ExpressiveThemeData.ember(Brightness.dark),
                      child: Builder(
                        builder: (context) {
                          nested = context.expressiveTheme;
                          return const SizedBox();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
      expect(outside, isNull);
      expect(fallback.id, 'baseline');
      expect(near.id, 'grove');
      expect(nested.id, 'ember');
      expect(nested.brightness, Brightness.dark);
    },
  );

  testWidgets('an InheritedTheme: what a route captures keeps its Expressive', (
    tester,
  ) async {
    late BuildContext inside;
    await tester.pumpWidget(
      _app(
        ExpressiveTheme(
          data: ExpressiveThemeData.slate(Brightness.dark),
          child: Builder(
            builder: (context) {
              inside = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    late ExpressiveThemeData captured;
    await tester.pumpWidget(
      _app(
        InheritedTheme.capture(from: inside, to: null).wrap(
          Builder(
            builder: (context) {
              captured = ExpressiveTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(captured.id, 'slate');
    expect(captured.brightness, Brightness.dark);
  });

  testWidgets('AnimatedExpressiveTheme springs from one theme to the next', (
    tester,
  ) async {
    late ExpressiveThemeData seen;
    Widget at(ExpressiveThemeData data) => _app(
      AnimatedExpressiveTheme(
        data: data,
        child: Builder(
          builder: (context) {
            seen = context.expressiveTheme;
            return const SizedBox();
          },
        ),
      ),
    );
    final a = ExpressiveThemeData.grove();
    final b = ExpressiveThemeData.ember();
    await tester.pumpWidget(at(a));
    expect(seen.colors.primary, a.colors.primary);
    await tester.pumpWidget(at(b));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(seen.colors.primary, isNot(a.colors.primary));
    expect(seen.colors.primary, isNot(b.colors.primary));
    await tester.pumpAndSettle();
    expect(seen.colors.primary, b.colors.primary);
    expect(seen.id, 'ember');
  });

  // One install for every app: ExpressiveTheme in the app's builder. A field
  // types, a button presses, and the field's caret and selection are
  // Expressive's, whatever Material theme the app wears.
  for (final (kind, app)
      in <
        (
          String,
          Widget Function(Widget Function(BuildContext, Widget?), Widget),
        )
      >[
        (
          'MaterialApp',
          (builder, home) => MaterialApp(
            theme: ThemeData(colorSchemeSeed: const Color(0xFFFF0000)),
            builder: builder,
            home: home,
          ),
        ),
        // A field is Flutter's Material TextField underneath, so an app that is not a MaterialApp lists Material's
        // words, as it would for any Material widget.
        (
          'CupertinoApp',
          (builder, home) => CupertinoApp(
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultCupertinoLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            builder: builder,
            home: home,
          ),
        ),
        (
          'WidgetsApp',
          (builder, home) => WidgetsApp(
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            color: const Color(0xFF000000),
            builder: builder,
            home: home,
            pageRouteBuilder: <T>(settings, build) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, _, _) => build(context),
            ),
          ),
        ),
      ]) {
    testWidgets("ExpressiveTheme in a $kind's builder is the whole install", (
      tester,
    ) async {
      final grove = ExpressiveThemeData.grove();
      var pressed = 0;
      String? typed;
      await tester.pumpWidget(
        app(
          (context, child) => ExpressiveTheme(data: grove, child: child!),
          Column(
            children: [
              ExpressiveTextField(label: 'Name', onChanged: (v) => typed = v),
              ExpressiveFilledButton('Book', onPressed: () => pressed++),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(EditableText), 'Ada');
      await tester.tap(find.text('Book'));
      await tester.pump();
      expect(typed, 'Ada');
      expect(pressed, 1);
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.cursorColor, grove.colors.primary);
      final selection = TextSelectionTheme.of(
        tester.element(find.byType(EditableText)),
      );
      expect(selection.selectionHandleColor, grove.colors.primary);
      expect(
        editable.selectionColor,
        // Compose's TextSelectionBackgroundOpacity.
        grove.colors.primary.withValues(alpha: 0.4),
      );
      await tester.pumpAndSettle();
    });
  }

  group('localizations', () {
    Future<String> back(
      WidgetTester tester, {
      List<LocalizationsDelegate<dynamic>> delegates = const [],
      Locale locale = const Locale('en'),
    }) async {
      late String word;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              word = ExpressiveLocalizations.of(context).back;
              return const SizedBox();
            },
          ),
          delegates: delegates,
          locale: locale,
        ),
      );
      return word;
    }

    testWidgets('with no delegate the words are English', (tester) async {
      expect(await back(tester), 'Back');
      expect(ExpressiveLocalizations.english.back, 'Back');
    });

    testWidgets("ui_core's delegate loads English", (tester) async {
      expect(
        await back(tester, delegates: [DefaultDesignLocalizations.delegate]),
        'Back',
      );
    });

    testWidgets("an app's own shared words give its language", (tester) async {
      expect(
        await back(
          tester,
          delegates: [const _French()],
          locale: const Locale('fr'),
        ),
        'Retour',
      );
    });

    Future<String> selectDate(
      WidgetTester tester, {
      List<LocalizationsDelegate<dynamic>> delegates = const [],
      ExpressiveLocalizations? scope,
    }) async {
      late String word;
      final reader = Builder(
        builder: (context) {
          word = ExpressiveLocalizations.of(context).selectDate;
          return const SizedBox();
        },
      );
      await tester.pumpWidget(
        _app(
          scope == null
              ? reader
              : ExpressiveLocalizationsScope(strings: scope, child: reader),
          delegates: delegates,
        ),
      );
      return word;
    }

    testWidgets("the look's delegate loads its own words in English", (
      tester,
    ) async {
      expect(
        await selectDate(tester, delegates: [ExpressiveLocalizations.delegate]),
        'Select date',
      );
      expect(
        ExpressiveLocalizations.delegate.isSupported(const Locale('en')),
        isTrue,
      );
    });

    testWidgets("a scope gives a subtree the look's own words", (tester) async {
      expect(
        await selectDate(
          tester,
          scope: const ExpressiveLocalizations(selectDate: 'Datum wählen'),
        ),
        'Datum wählen',
      );
    });
  });
}
