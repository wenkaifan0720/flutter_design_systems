// The example's Customize panel, at every setting it offers: Flutter's four guidelines on every gallery page, by day and
// by night (Android's 48 px and iOS's 44 px targets, labelled targets, text contrast read with each word's own ink). For
// a compact density, a golden of every section. `flutter test --update-goldens`
// records them.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

// The panel is the example app's; a test reads its settings from there.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/main.dart';
import 'gallery_support.dart';

/// Every setting: each knob away from the look's own, each accent of your own, and every knob at once.
final Map<String, GalleryCustom> settings = {
  'comfortable': const GalleryCustom(density: FrostedDensity.comfortable),
  'compact': const GalleryCustom(density: FrostedDensity.compact),
  for (final accent in galleryAccents)
    accent.name.toLowerCase(): GalleryCustom(accent: accent),
  'every knob': GalleryCustom(
    density: FrostedDensity.compact,
    accent: galleryAccents.first,
  ),
};

/// The settings every section has a golden in.
const goldenSettings = ['compact'];

/// The goldens are kept beside the catalog and laid here by the package build; a published copy compares nothing.
final bool _recorded =
    autoUpdateGoldenFiles || Directory('test/goldens').existsSync();

void main() {
  setUpAll(() async {
    await frostedLoadFonts();
    await loadBundledFonts();
  });

  void customize(GalleryCustom custom) {
    kitShownTheme = (brightness) => custom.theme('opal', brightness);
    addTearDown(() => kitShownTheme = null);
  }

  test('the panel untouched is the preset as designed', () {
    for (final b in Brightness.values) {
      expect(
        const GalleryCustom().theme('opal', b),
        FrostedThemeData.preset('opal', b),
      );
    }
  });

  for (final MapEntry(key: name, value: custom) in settings.entries) {
    for (final page in galleryPages) {
      for (final b in Brightness.values) {
        testWidgets(
          '${page.id} by ${b == Brightness.light ? 'day' : 'night'}, $name: the guidelines hold',
          (tester) async {
            customize(custom);
            final semantics = tester.ensureSemantics();
            await pumpGalleryPage(tester, page, 'opal', b);
            final failed = <String>[];
            for (final (what, guideline) in [
              ('Android 48 px targets', androidTapTargetGuideline),
              ('iOS 44 px targets', iOSTapTargetGuideline),
              ('labelled targets', labeledTapTargetGuideline),
            ]) {
              final result = await guideline.evaluate(tester);
              if (!result.passed) failed.add('$what: ${result.reason}');
            }
            final inked = await inkedContrastFailures(tester);
            if (inked.isNotEmpty) {
              failed.add('text contrast: ${inked.join('; ')}');
            }
            semantics.dispose();
            expect(failed, isEmpty, reason: failed.join('\n'));
          },
          // The words' contrast is read from drawn pixels, which depend on
          // the rasterizer as a golden does.
          tags: const ['goldens'],
        );
      }
    }
  }

  for (final name in goldenSettings) {
    for (final page in galleryPages) {
      testWidgets(
        '${page.id}, $name: each section matches its golden',
        (tester) async {
          if (!_recorded) return;
          customize(settings[name]!);
          await pumpGalleryPage(tester, page, 'opal', Brightness.light);
          // A page of no sections (the inventory) is one, the whole page, as
          // in the parts test.
          final found = [...sections()];
          if (found.isEmpty) {
            found.add((
              'page',
              find.byKey(ValueKey<String>('${page.id}/opal/light')),
            ));
          }
          expect(found.first.$2, findsOneWidget);
          for (final (label, section) in found) {
            await expectLater(
              section,
              matchesGoldenFile(
                'goldens/${page.id}/${slug(label)}/custom_${slug(name)}.png',
              ),
            );
          }
        },
        // Pixels recorded on macOS: `flutter test --exclude-tags goldens` leaves them out elsewhere.
        tags: const ['goldens'],
      );
    }
  }
}
