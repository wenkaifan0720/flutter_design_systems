// The text theme's fallback families reach every style of the scale, the
// text a theme sets under a bare app, and the Material theme ExpressiveHost
// lays under the look's parts, as Material's ThemeData.fontFamilyFallback
// does: on the web a face loaded at run time (a Noto Sans JP subset, say)
// draws only where a style names it. The look's faces keep their package's
// name; the fallback faces, the app's own, keep theirs.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

const _fallback = ['NotoSansJP', 'NotoSansArabic'];

ExpressiveThemeData _theme(Brightness b) => ExpressiveThemeData.preset(
  ExpressiveThemeData.defaultPreset,
  b,
).copyWith(type: const ExpressiveTextTheme(fontFamilyFallback: _fallback));

void main() {
  const type = ExpressiveTextTheme(fontFamilyFallback: _fallback);
  const plain = ExpressiveTextTheme();

  test('every style of the scale names the fallback families', () {
    List<(String, TextStyle)> scale(ExpressiveTextTheme t) => [
      ('displayLarge', t.displayLarge),
      ('displayMedium', t.displayMedium),
      ('displaySmall', t.displaySmall),
      ('headlineLarge', t.headlineLarge),
      ('headlineMedium', t.headlineMedium),
      ('headlineSmall', t.headlineSmall),
      ('titleLarge', t.titleLarge),
      ('titleMedium', t.titleMedium),
      ('titleSmall', t.titleSmall),
      ('bodyLarge', t.bodyLarge),
      ('bodyMedium', t.bodyMedium),
      ('bodySmall', t.bodySmall),
      ('labelLarge', t.labelLarge),
      ('labelMedium', t.labelMedium),
      ('labelSmall', t.labelSmall),
      ('displayLargeEmphasized', t.displayLargeEmphasized),
      ('displayMediumEmphasized', t.displayMediumEmphasized),
      ('displaySmallEmphasized', t.displaySmallEmphasized),
      ('headlineLargeEmphasized', t.headlineLargeEmphasized),
      ('headlineMediumEmphasized', t.headlineMediumEmphasized),
      ('headlineSmallEmphasized', t.headlineSmallEmphasized),
      ('titleLargeEmphasized', t.titleLargeEmphasized),
      ('titleMediumEmphasized', t.titleMediumEmphasized),
      ('titleSmallEmphasized', t.titleSmallEmphasized),
      ('bodyLargeEmphasized', t.bodyLargeEmphasized),
      ('bodyMediumEmphasized', t.bodyMediumEmphasized),
      ('bodySmallEmphasized', t.bodySmallEmphasized),
      ('labelLargeEmphasized', t.labelLargeEmphasized),
      ('labelMediumEmphasized', t.labelMediumEmphasized),
      ('labelSmallEmphasized', t.labelSmallEmphasized),
    ];
    final faces = scale(plain);
    for (final (i, (name, style)) in scale(type).indexed) {
      expect(style.fontFamilyFallback, _fallback, reason: name);
      expect(
        style.fontFamily,
        faces[i].$2.fontFamily,
        reason: '$name keeps its face',
      );
    }
  });

  test("the look's faces keep their package's name", () {
    expect(
      type.bodyLarge.fontFamily,
      expressiveFontFamily(ExpressiveTextTheme.family),
    );
    expect(type.bodyLarge.fontFamilyFallback, _fallback);
  });

  test("an app's own faces from its package take the fallback unprefixed", () {
    const own = ExpressiveTextTheme(
      displayFamily: 'Brand',
      textFamily: 'Brand',
      fontPackage: 'brand_fonts',
      fontFamilyFallback: _fallback,
    );
    expect(own.bodyLarge.fontFamily, 'packages/brand_fonts/Brand');
    expect(own.displayLarge.fontFamily, 'packages/brand_fonts/Brand');
    expect(own.bodyLarge.fontFamilyFallback, _fallback);
  });

  testWidgets("the Material theme under the look's parts names them", (
    tester,
  ) async {
    late ThemeData material;
    late TextStyle text;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => ExpressiveHost(
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            material = Theme.of(context);
            text = DefaultTextStyle.of(context).style;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(material.textTheme.bodyMedium!.fontFamilyFallback, _fallback);
    expect(material.textTheme.titleLarge!.fontFamilyFallback, _fallback);
    expect(text.fontFamilyFallback, _fallback);
  });

  testWidgets('a theme over a bare app sets text that names them', (
    tester,
  ) async {
    late TextStyle text;
    await tester.pumpWidget(
      ExpressiveTheme(
        data: _theme(Brightness.light),
        child: Builder(
          builder: (context) {
            text = DefaultTextStyle.of(context).style;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(text.fontFamilyFallback, _fallback);
  });

  test('with no families the styles name none', () {
    expect(plain.bodyLarge.fontFamilyFallback, isNull);
    expect(type, isNot(plain));
    expect(plain.copyWith(fontFamilyFallback: _fallback), type);
    expect(
      plain.copyWith(fontFamilyFallback: List.of(_fallback)).hashCode,
      type.hashCode,
    );
  });
}
