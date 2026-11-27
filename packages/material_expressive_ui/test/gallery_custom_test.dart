// Every offered non-default Customize choice, plus combined settings, on every
// page by day and night. Default qualification runs before recording these pixels.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

// The gallery is the example app; a test reads its pages from there.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/gallery.dart';
import '../example/lib/kit_gallery/kit.dart';
import 'flutter_test_config.dart' show pageWalkLeakTesting;
import 'gallery_guidelines_test.dart' show galleryGuidelineFailures;
import 'gallery_parts_test.dart' show sectionsOrPage, slug;
import 'gallery_support.dart';
import 'support/tiers.dart';

final settings = <String, GalleryCustom>{
  'standard': const GalleryCustom(density: 'standard'),
  'comfortable': const GalleryCustom(density: 'comfortable'),
  'compact': const GalleryCustom(density: 'compact'),
  'expressive motion': const GalleryCustom(motion: 'expressive'),
  'standard motion': const GalleryCustom(motion: 'standard'),
  for (final seed in ['teal', 'plum', 'grey']) seed: GalleryCustom(seed: seed),
  'every knob': const GalleryCustom(
    density: 'compact',
    motion: 'standard',
    seed: 'teal',
  ),
};

const goldenSettings = ['compact'];
final _recorded =
    autoUpdateGoldenFiles || Directory('test/goldens').existsSync();

void main() {
  LeakTesting.settings = pageWalkLeakTesting;
  setUpAll(() async {
    await loadExpressiveFonts();
    await loadBundledFonts();
  });

  void customize(GalleryCustom custom) {
    kitShownTheme = custom.apply;
    addTearDown(() => kitShownTheme = null);
  }

  test('the untouched panel preserves each preset', () {
    for (final (preset, mode) in presetsAndModes) {
      final base = ExpressiveThemeData.preset(preset, mode);
      expect(const GalleryCustom().apply(base), base);
    }
  });

  test('an app face loads real proportional glyphs', () {
    final theme = ExpressiveThemeData.preset('baseline', Brightness.light)
        .copyWith(
          type: const ExpressiveTextTheme(
            displayFamily: 'Jost',
            textFamily: 'Jost',
            fontPackage: expressiveFontPackage,
          ),
        );
    double width(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: theme.type.bodyMedium),
        textDirection: TextDirection.ltr,
      )..layout();
      addTearDown(painter.dispose);
      return painter.width;
    }

    // Flutter's unloaded-font fallback is Ahem: every glyph has equal width.
    expect(width('iiii'), lessThan(width('WWWW')));
  });

  group('custom settings', () {
    // Every setting on every page by day and night; the everyday tier reads
    // each setting and mode once, each on another page (support/tiers).
    final columns = settings.length * Brightness.values.length;
    for (final (s, MapEntry(key: name, value: custom))
        in settings.entries.indexed) {
      for (final (row, page) in galleryExamplePages.indexed) {
        for (final (m, mode) in Brightness.values.indexed) {
          Future<void> meets(
            WidgetTester tester, {
            required bool contrast,
          }) async {
            customize(custom);
            final handle = tester.ensureSemantics();
            await pumpGalleryPage(tester, page, 'baseline', mode);
            final failed = await galleryGuidelineFailures(
              tester,
              page.id,
              'baseline',
              mode,
              targets: !contrast,
              contrast: contrast,
            );
            expect(failed, isEmpty, reason: failed.join('\n'));
            handle.dispose();
          }

          testWidgets(
            '${page.id}, $name ${mode.name}: guidelines',
            (tester) => meets(tester, contrast: false),
            tags: sweepUnless(
              everydayOnce(
                row,
                s * Brightness.values.length + m,
                galleryExamplePages.length,
                columns,
              ),
            ),
          );
          // Text contrast reads the drawn pixels, the rasterizer's as a
          // golden's are: macOS runs it.
          testWidgets(
            '${page.id}, $name ${mode.name}: text contrast',
            (tester) => meets(tester, contrast: true),
            tags: const ['goldens'],
          );
        }
      }
    }
    for (final name in goldenSettings) {
      for (final page in galleryExamplePages) {
        testWidgets('${page.id}, $name: customized pixels', (tester) async {
          if (!_recorded) return;
          customize(settings[name]!);
          await pumpGalleryPage(tester, page, 'baseline', Brightness.light);
          for (final (label, section) in sectionsOrPage(
            '${page.id}/baseline/light',
          )) {
            await expectLater(
              section,
              matchesGoldenFile(
                'goldens/${page.id}/${slug(label)}/custom_${slug(name)}.png',
              ),
            );
          }
        }, tags: const ['goldens']);
      }
    }
  });
}
