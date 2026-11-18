// Counts are plurals: a counted phrase takes its noun's form for the count in
// the reader's language (one and other in English and French, few and many
// in Polish, the dual in Arabic), at 1 and at 2; and Simmer's own counts
// read "1 person", "2 people", never "1 people".
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/everyday_screens.dart';

Future<String> _said(WidgetTester tester, Locale locale, int count) async {
  late String said;
  await tester.pumpWidget(
    Localizations(
      locale: locale,
      delegates: const [DefaultWidgetsLocalizations.delegate],
      child: Builder(
        builder: (context) {
          said = glossPlural(
            context,
            count,
            zero: 'zero',
            one: 'one',
            two: 'two',
            few: 'few',
            many: 'many',
            other: 'other',
          );
          return const SizedBox();
        },
      ),
    ),
  );
  return said;
}

void main() {
  test('the categories at 1 and 2', () {
    GlossPluralCategory at(String language, int n) =>
        glossPluralCategory(Locale(language), n);
    expect(
      [at('en', 1), at('en', 2)],
      [GlossPluralCategory.one, GlossPluralCategory.other],
    );
    expect(
      [at('fr', 0), at('fr', 1), at('fr', 2)],
      [
        GlossPluralCategory.one,
        GlossPluralCategory.one,
        GlossPluralCategory.other,
      ],
    );
    expect(
      [at('pl', 1), at('pl', 2), at('pl', 5), at('pl', 22)],
      [
        GlossPluralCategory.one,
        GlossPluralCategory.few,
        GlossPluralCategory.many,
        GlossPluralCategory.few,
      ],
    );
    expect(
      [at('ru', 1), at('ru', 2), at('ru', 11), at('ru', 21)],
      [
        GlossPluralCategory.one,
        GlossPluralCategory.few,
        GlossPluralCategory.many,
        GlossPluralCategory.one,
      ],
    );
    expect(
      [at('ar', 0), at('ar', 1), at('ar', 2), at('ar', 3), at('ar', 11)],
      [
        GlossPluralCategory.zero,
        GlossPluralCategory.one,
        GlossPluralCategory.two,
        GlossPluralCategory.few,
        GlossPluralCategory.many,
      ],
    );
    expect(
      [at('ja', 1), at('ja', 2)],
      [GlossPluralCategory.other, GlossPluralCategory.other],
    );
  });

  testWidgets('the form follows the locale', (tester) async {
    expect(await _said(tester, const Locale('en'), 1), 'one');
    expect(await _said(tester, const Locale('en'), 2), 'other');
    expect(await _said(tester, const Locale('pl'), 2), 'few');
    expect(await _said(tester, const Locale('ar'), 2), 'two');
  });

  testWidgets('a form left out falls back to other', (tester) async {
    late String said;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('pl'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Builder(
          builder: (context) {
            said = glossPlural(context, 2, one: '1 plik', other: '2 pliki');
            return const SizedBox();
          },
        ),
      ),
    );
    expect(said, '2 pliki');
  });

  testWidgets('Simmer: cooking for 2 people, then 1 person', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = everydayScreens.firstWhere((s) => s.id == 'settings');
    await tester.pumpWidget(settings.app(Brightness.light, TextDirection.ltr));
    await tester.pumpAndSettle();
    expect(find.text('2 people'), findsOneWidget);
    final row = find.ancestor(
      of: find.text('Cooking for'),
      matching: find.byType(GlossListTile),
    );
    await tester.tap(
      find.descendant(of: row, matching: find.byIcon(LucideIcons.minus)),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 person'), findsOneWidget);
    expect(find.text('1 people'), findsNothing);
  });
}
