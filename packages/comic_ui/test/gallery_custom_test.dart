// The example's Customize panel, at every setting it offers: Flutter's four guidelines on every gallery page, by day and
// by night (Android's 48 px and iOS's 44 px targets, labelled targets, text contrast read with each word's own ink). For
// the corner scale, a heavy stroke and a compact density, a golden of every section; and a golden of one press
// caught between two shapes. `flutter test --update-goldens` records them.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

// The panel is the example app's; a test reads its settings from there.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/main.dart';
import 'gallery_support.dart';
import 'support.dart';

/// Every setting: each knob away from the look's own, each pair of your own colours, and every knob at once.
final Map<String, GalleryCustom> settings = {
  'square corners': const GalleryCustom(corners: GalleryCorners.square),
  'small corners': const GalleryCustom(corners: GalleryCorners.small),
  'medium corners': const GalleryCustom(corners: GalleryCorners.medium),
  'large corners': const GalleryCustom(corners: GalleryCorners.large),
  'bold strokes': const GalleryCustom(bold: true),
  'comfortable': const GalleryCustom(density: ComicDensity.comfortable),
  'compact': const GalleryCustom(density: ComicDensity.compact),
  'shantell alone larger': const GalleryCustom(oneFace: true, typeScale: 1.15),
  'smaller type': const GalleryCustom(typeScale: .9),
  for (final pair in galleryColours)
    pair.name.toLowerCase(): GalleryCustom(colours: pair),
  'every knob': GalleryCustom(
    corners: GalleryCorners.large,
    bold: true,
    density: ComicDensity.compact,
    oneFace: true,
    typeScale: 1.15,
    colours: galleryColours.first,
  ),
};

/// The settings every section has a golden in.
const goldenSettings = [
  'small corners',
  'medium corners',
  'large corners',
  'bold strokes',
  'compact',
];

/// The goldens are kept beside the catalog and laid here by the package build; a published copy compares nothing.
final bool _recorded =
    autoUpdateGoldenFiles || Directory('test/goldens').existsSync();

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });

  void customize(GalleryCustom custom) {
    kitShownTheme = (brightness) => custom.theme('offset', brightness);
    addTearDown(() => kitShownTheme = null);
  }

  test('the panel untouched is the preset as designed', () {
    for (final b in Brightness.values) {
      expect(
        const GalleryCustom().theme('offset', b),
        ComicThemeData.preset('offset', b),
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
            await pumpGalleryPage(tester, page, 'offset', b);
            final failed = <String>[];
            for (final (what, guideline) in [
              ('Android 48 px targets', androidTapTargetGuideline),
              ('iOS 44 px targets', iOSTapTargetGuideline),
              ('labelled targets', labeledTapTargetGuideline),
            ]) {
              final result = await guideline.evaluate(tester);
              if (!result.passed) failed.add('$what: ${result.reason}');
            }
            final pixels = await textContrastGuideline.evaluate(tester);
            final inked = await inkedContrastFailures(
              tester,
              diagnosticPath:
                  'test/failures/custom_${page.id}_${slug(name)}_${b.name}.png',
            );
            if (inked.isNotEmpty) {
              failed.add(
                'text contrast: ${inked.join('; ')}'
                '${pixels.passed ? '' : '\nFlutter reading: ${pixels.reason}'}',
              );
            }
            expect(failed, isEmpty, reason: failed.join('\n'));
          },
          // Contrast is read from the drawn pixels: the rasterizer's, as a golden's (Linux CI leaves it to macOS).
          tags: 'goldens',
        );
      }
    }
  }

  for (final name in goldenSettings) {
    for (final page in galleryPages) {
      for (final width in [galleryWidth, 1440.0]) {
        for (final brightness in Brightness.values) {
          testWidgets(
            '${page.id}, $name, ${brightness.name} at $width: each section matches its golden',
            (tester) async {
              customize(settings[name]!);
              await pumpGalleryPage(
                tester,
                page,
                'offset',
                brightness,
                width: width,
              );
              expect(tester.takeException(), isNull);
              final found = sections();
              expect(found, isNotEmpty);
              final suffix =
                  width == galleryWidth && brightness == Brightness.light
                  ? ''
                  : '_${brightness.name}_${width.toInt()}';
              for (final (label, section) in found) {
                await expectLater(
                  section,
                  matchesGoldenFile(
                    'goldens/${page.id}/${slug(label)}/custom_${slug(name)}$suffix.png',
                  ),
                );
              }
            },
            // Pixels recorded on macOS: `flutter test --exclude-tags goldens` leaves them out elsewhere.
            skip: !_recorded,
            tags: const ['goldens'],
          );
        }
      }
    }
  }

  testWidgets(
    'a press caught between two shapes',
    (tester) async {
      // The caller can animate a square control to a rounded one through its state style.
      final shape = WidgetStateProperty.resolveWith<OutlinedBorder?>(
        (s) => s.contains(WidgetState.pressed)
            ? const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              )
            : const RoundedRectangleBorder(),
      );
      final style = ComicStyle(shape: shape);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(galleryWidth, 160);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ComicTheme(
          data: ComicThemeData.preset('offset', Brightness.light),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) => ColoredBox(
                color: ComicTheme.of(context).colors.background,
                child: Center(
                  child: RepaintBoundary(
                    key: const ValueKey('press'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ComicButton.filled(
                        'Reserve',
                        style: style,
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.byWidgetPredicate(
        (w) => '${w.runtimeType}' == '_Filled',
      );
      final gesture = await tester.startGesture(tester.getCenter(button));
      await tester.pump();
      await tester.pump(ComicMotion.of(tester.element(button)).state ~/ 2);
      await expectLater(
        find.byKey(const ValueKey('press')),
        matchesGoldenFile('goldens/styled/press_mid_change.png'),
      );
      await gesture.up();
      await tester.pumpAndSettle();
    },
    skip: !_recorded,
    tags: const ['goldens'],
  );
}
