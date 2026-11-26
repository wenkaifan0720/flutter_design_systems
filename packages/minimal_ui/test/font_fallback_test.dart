// An app's fallback faces reach every one of Minimal's text styles, as
// ThemeData.fontFamilyFallback does, so a script Geist lacks (Japanese, say)
// is drawn in the app's face and not the platform's.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

List<TextStyle> _styles(MinimalThemeData t) => [
  t.body,
  t.bodySmall,
  t.caption,
  t.control,
  t.mono,
  t.giant,
];

void main() {
  const fallback = ['Noto Sans JP', 'Noto Sans Arabic'];

  test("every style falls back to the app's faces", () {
    final t = MinimalThemeData.standard().copyWith(
      typeface: const MinimalTypeface(fallback: fallback),
    );
    for (final style in _styles(t)) {
      expect(style.fontFamilyFallback, fallback);
    }
    expect(t.body.fontFamily, contains('Geist'));
  });

  test("an app's own faces keep their names with the fallback", () {
    final t = MinimalThemeData.standard().copyWith(
      typeface: const MinimalTypeface.app(
        sans: 'Inter',
        mono: 'JetBrainsMono',
        fallback: fallback,
      ),
    );
    expect(t.body.fontFamily, 'Inter');
    expect(t.mono.fontFamily, 'JetBrainsMono');
    for (final style in _styles(t)) {
      expect(style.fontFamilyFallback, fallback);
    }
  });

  test('none given, the styles carry none', () {
    for (final style in _styles(MinimalThemeData.standard())) {
      expect(style.fontFamilyFallback, isNull);
    }
  });

  test('two typefaces with different fallbacks differ', () {
    expect(
      const MinimalTypeface(fallback: fallback),
      isNot(MinimalTypeface.look),
    );
  });
}
