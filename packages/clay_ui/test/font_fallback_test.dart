// An app's fallback faces reach every one of Clay's text styles, as
// ThemeData.fontFamilyFallback does, so a script Rubik lacks (Japanese,
// say) is drawn in the app's face and not the platform's. The app's faces
// keep their own names: only Clay's own face carries its package.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

List<TextStyle> _styles(ClayTextTheme t) => [
  t.display,
  t.headline,
  t.title,
  t.body,
  t.label,
  t.secondary,
  t.caption,
];

void main() {
  const fallback = ['Noto Sans JP', 'Noto Sans Arabic'];

  final themes = {
    'light': ClayThemeData.light(fontFamilyFallback: fallback),
    'dark': ClayThemeData.dark(fontFamilyFallback: fallback),
    'clay': ClayThemeData.clay(Brightness.dark, fontFamilyFallback: fallback),
    'from': ClayThemeData.from(
      accent: const Color(0xFF1F3A68),
      fontFamilyFallback: fallback,
    ),
  };
  for (final MapEntry(key: name, value: theme) in themes.entries) {
    test("$name: every style falls back to the app's faces, unprefixed", () {
      for (final style in _styles(theme.textTheme)) {
        expect(style.fontFamilyFallback, fallback);
        expect(style.fontFamily, endsWith(clayFontFamily));
      }
    });
  }

  test("an app's own family keeps its name with the fallback", () {
    final t = ClayTextTheme.from(
      ink: const Color(0xFF000000),
      secondaryInk: const Color(0xFF444444),
      family: 'Inter',
      fontFamilyFallback: fallback,
    );
    for (final style in _styles(t)) {
      expect(style.fontFamily, 'Inter');
      expect(style.fontFamilyFallback, fallback);
    }
  });

  test('none given, the styles carry none', () {
    for (final style in _styles(ClayThemeData.light().textTheme)) {
      expect(style.fontFamilyFallback, isNull);
    }
  });
}
