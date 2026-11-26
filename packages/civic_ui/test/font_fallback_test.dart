// A theme-level font fallback, as Material's ThemeData.fontFamilyFallback:
// every step of both ramps (codes too) falls back on Civic's Noto Sans
// Arabic, then on the app's families under their own names, and Flutter's
// own text under Civic reads the same list. An app's own face keeps Civic's
// bundled Arabic behind it (it lost it before: the family went unprefixed).
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

List<TextStyle> _steps(CivicTextTheme r) => [
  r.headingXL,
  r.headingL,
  r.headingM,
  r.headingS,
  r.body,
  r.bodySmall,
  r.label,
  r.caption,
  r.button,
];

void main() {
  final arabic = civicFontFamily('NotoSansArabic');

  test('every step falls back on Arabic, then the app\'s families', () {
    for (final b in Brightness.values) {
      final t = CivicThemeData.from(
        brightness: b,
        fontFamilyFallback: const ['NotoSansJP'],
      );
      for (final ramp in [t.text, t.compactText]) {
        for (final step in _steps(ramp)) {
          expect(step.fontFamily, civicFontFamily('AtkinsonNext'));
          expect(step.fontFamilyFallback, [arabic, 'NotoSansJP']);
        }
        expect(ramp.code.fontFamily, civicFontFamily('AtkinsonMono'));
        expect(ramp.code.fontFamilyFallback, ['NotoSansJP']);
      }
    }
  });

  test('with none, Arabic alone, as before', () {
    final t = CivicThemeData.light();
    expect(t.text.body.fontFamilyFallback, [arabic]);
    expect(t.text.code.fontFamilyFallback, isNull);
  });

  test("an app's own face keeps Civic's Arabic behind it", () {
    final t = CivicThemeData.from(
      brightness: Brightness.light,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['NotoSansJP'],
    );
    expect(t.text.body.fontFamily, 'Inter');
    expect(t.text.body.fontFamilyFallback, [arabic, 'NotoSansJP']);
    final packaged = CivicThemeData.from(
      brightness: Brightness.light,
      fontFamily: 'Inter',
      fontPackage: 'my_fonts',
    );
    expect(packaged.text.body.fontFamily, 'packages/my_fonts/Inter');
    expect(packaged.text.body.fontFamilyFallback, [arabic]);
  });

  testWidgets("Flutter's own text under Civic falls back the same", (
    tester,
  ) async {
    late BuildContext page;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => CivicTheme(
          data: CivicThemeData.from(
            brightness: Brightness.light,
            fontFamilyFallback: const ['NotoSansJP'],
          ),
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            page = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(DefaultTextStyle.of(page).style.fontFamilyFallback, [
      arabic,
      'NotoSansJP',
    ]);
    expect(
      Theme.of(page).textTheme.bodyLarge!.fontFamilyFallback,
      contains('NotoSansJP'),
    );
  });
}
