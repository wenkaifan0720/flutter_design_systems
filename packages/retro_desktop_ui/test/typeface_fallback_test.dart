// A typeface's fallback list reaches every text style the theme builds and the Material theme it lays under the look's
// parts, as `ThemeData.fontFamilyFallback` does: on the web a face loaded at run time (a Noto Sans JP subset, say)
// draws only where a style names it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

void main() {
  const fallback = ['NotoSansJP', 'NotoSansArabic'];
  final theme = RetroDesktopThemeData.classic().copyWith(
    typeface: const RetroDesktopTypeface(fallback: fallback),
  );
  final type = theme.textTheme;

  test('every style of the text theme names the fallback list', () {
    for (final (name, style) in [
      ('chrome', type.chrome),
      ('small', type.small),
      ('sub', type.sub),
      ('head', type.head),
      ('big', type.big),
      ('title', type.title),
      ('body', type.body),
      ('row', type.row),
      ('read', type.read),
      ('note', type.note),
      ('caption', type.caption),
      ('meta', type.meta),
      ('figure', type.figure),
      ('pixel', type.pixel(24, 28)),
      ('text', type.text(15, 20)),
      ('mono', type.mono(13, 18)),
    ]) {
      expect(style.fontFamilyFallback, fallback, reason: name);
    }
  });

  testWidgets("the Material theme under the look's parts names it too", (
    tester,
  ) async {
    late ThemeData material;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            RetroDesktopTheme(data: theme, child: child!),
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

  test('with no fallback list the styles name none', () {
    expect(
      RetroDesktopThemeData.classic().textTheme.body.fontFamilyFallback,
      isNull,
    );
  });
}
