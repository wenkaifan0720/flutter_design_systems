// A typeface's fallback list reaches every text style the theme builds and the Material theme it lays under the look's
// parts, as `ThemeData.fontFamilyFallback` does: on the web a face loaded at run time (a Noto Sans JP subset, say)
// draws only where a style names it. The look's own faces keep their package's path; the fallback faces, the app's
// own, keep theirs.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

void main() {
  const fallback = ['NotoSansJP', 'NotoSansArabic'];
  final theme = NeumorphicThemeData.porcelain().copyWith(
    typeface: const NeumorphicTypeface(fallback: fallback),
  );
  final type = theme.textTheme;

  test('every style of the text theme names the fallback list', () {
    for (final (name, style) in [
      ('micro', type.micro),
      ('caption', type.caption),
      ('title', type.title),
      ('body', type.body),
      ('value', type.value),
      ('page', type.page),
      ('figure', type.figure),
      ('text', type.text(15, 20)),
    ]) {
      expect(style.fontFamilyFallback, fallback, reason: name);
      expect(
        style.fontFamily,
        NeumorphicThemeData.porcelain().textTheme.body.fontFamily,
        reason: name,
      );
    }
  });

  testWidgets("the Material theme under the look's parts names it too", (
    tester,
  ) async {
    late ThemeData material;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            NeumorphicTheme(data: theme, child: child!),
        home: Builder(
          builder: (context) {
            material = Theme.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(material.textTheme.bodyMedium!.fontFamilyFallback, fallback);
  });

  test("an app's own faces take the fallback too", () {
    final own = NeumorphicThemeData.porcelain().copyWith(
      typeface: const NeumorphicTypeface.app(
        display: 'Brand',
        text: 'Brand',
        fallback: fallback,
      ),
    );
    expect(own.textTheme.body.fontFamily, 'Brand');
    expect(own.textTheme.body.fontFamilyFallback, fallback);
  });

  test('with no fallback list the styles name none', () {
    expect(
      NeumorphicThemeData.porcelain().textTheme.body.fontFamilyFallback,
      isNull,
    );
    expect(
      const NeumorphicTypeface(fallback: fallback),
      isNot(NeumorphicTypeface.look),
    );
    expect(
      NeumorphicTypeface.look.copyWith(fallback: fallback),
      const NeumorphicTypeface(fallback: fallback),
    );
  });
}
