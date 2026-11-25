// An app that sets words in a script Frosted's faces lack (Japanese, Thai, Arabic) names the faces to fall back to once,
// on the theme (FrostedThemeData.fontFamilyFallback), as Material's ThemeData takes a fontFamilyFallback: every text
// style of the theme carries them after any of its own, and the host's default style too, so every word a part sets
// reaches them. Before, an app copied each of the theme's 25 styles to reach them, and words set in a part's own style
// missed them.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

import 'gallery_support.dart';

// The gallery is the example app; a test sets the theme it shows.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/theme.dart';

List<TextStyle> _slots(FrostedTextTheme t) => [
  t.displayLarge,
  t.displayMedium,
  t.displaySmall,
  t.headlineLarge,
  t.headlineMedium,
  t.headlineSmall,
  t.titleLarge,
  t.titleMedium,
  t.titleSmall,
  t.bodyLarge,
  t.bodyMedium,
  t.bodySmall,
  t.labelLarge,
  t.labelMedium,
  t.labelSmall,
  t.overline,
  t.stat,
  t.amount,
  t.amountSmall,
  t.link,
  t.tab,
  t.mono,
  t.monoSmall,
  t.monogram,
  t.wordmark,
];

const _jp = ['NotoSansJP'];

// Whether [text] is a glyph of an icon font (the private use area), which
// never falls back.
bool _glyph(String text) =>
    text.runes.every((r) => (r >= 0xE000 && r <= 0xF8FF) || r >= 0xF0000);

void main() {
  for (final brightness in Brightness.values) {
    test('every style of the theme ends with the fallback '
        '(${brightness.name})', () {
      for (final theme in [
        FrostedThemeData(brightness: brightness, fontFamilyFallback: _jp),
        FrostedThemeData.preset(
          'garnet',
          brightness,
        ).copyWith(fontFamilyFallback: _jp),
        FrostedThemeData.from(
          accent: const Color(0xFF1F3A68),
          brightness: brightness,
          fontFamilyFallback: _jp,
        ),
      ]) {
        expect(theme.fontFamilyFallback, _jp);
        for (final (i, style) in _slots(theme.textTheme).indexed) {
          expect(style.fontFamilyFallback, isNotNull, reason: 'slot $i');
          expect(style.fontFamilyFallback!.last, 'NotoSansJP');
        }
      }
    });
  }

  test('a new fallback replaces the last; a style\'s own stays first', () {
    final first = FrostedThemeData.preset(
      'opal',
      Brightness.light,
    ).copyWith(fontFamilyFallback: const ['NotoSansJP']);
    final own = first.copyWith(
      textTheme: first.textTheme.copyWith(
        bodyMedium: first.textTheme.bodyMedium.copyWith(
          fontFamilyFallback: const ['Own', 'NotoSansJP'],
        ),
      ),
    );
    final next = own.copyWith(fontFamilyFallback: const ['NotoSansTC']);
    expect(next.textTheme.bodyMedium.fontFamilyFallback, ['Own', 'NotoSansTC']);
    expect(next.textTheme.titleLarge.fontFamilyFallback!.last, 'NotoSansTC');
    expect(
      next.textTheme.titleLarge.fontFamilyFallback,
      isNot(contains('NotoSansJP')),
    );
    final none = next.copyWith(fontFamilyFallback: const []);
    expect(none.textTheme.bodyMedium.fontFamilyFallback, ['Own']);
    expect(
      none.textTheme.titleLarge.fontFamilyFallback ?? const <String>[],
      isNot(contains('NotoSansTC')),
    );
  });

  testWidgets('every word on every gallery page reaches the fallback', (
    tester,
  ) async {
    kitShownTheme = (b) =>
        FrostedThemeData.preset(kitPreset, b).copyWith(fontFamilyFallback: _jp);
    addTearDown(() => kitShownTheme = null);
    final missed = <String>[];
    for (final page in galleryPages) {
      await pumpGalleryPage(tester, page, kitPreset, Brightness.light);
      tester.takeException();
      for (final p in tester.renderObjectList<RenderParagraph>(
        find.byType(RichText),
      )) {
        void walk(InlineSpan span, TextStyle? above) {
          final style = above == null
              ? span.style
              : (span.style == null ? above : above.merge(span.style));
          if (span is! TextSpan) return;
          final text = (span.text ?? '').trim();
          if (text.isNotEmpty &&
              !_glyph(text) &&
              !(style?.fontFamilyFallback ?? const []).contains('NotoSansJP')) {
            missed.add('${page.id}: "$text"');
          }
          for (final child in span.children ?? const <InlineSpan>[]) {
            walk(child, style);
          }
        }

        walk(p.text, null);
      }
    }
    expect(missed, isEmpty);
  });
}
