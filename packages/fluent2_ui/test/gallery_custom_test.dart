// The example's Customize panel, at every setting it offers: Flutter's four guidelines on every gallery page, light and
// dark (Android's 48 px and iOS's 44 px targets, labelled targets, text contrast read with each word's own ink). For
// a compact density, a golden of every section; and a golden of one press caught between two shapes (a component
// theme's). `flutter test --update-goldens` records them.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

// The panel is the example app's; a test reads its settings from there.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/main.dart';
import 'gallery_support.dart';

/// Every setting: each density away from the look's own, each brand colour of your own, and both at once.
final Map<String, GalleryCustom> settings = {
  'comfortable': const GalleryCustom(density: Fluent2Density.comfortable),
  'compact': const GalleryCustom(density: Fluent2Density.compact),
  for (final brand in galleryBrands)
    brand.name.toLowerCase(): GalleryCustom(brand: brand),
  'every setting': GalleryCustom(
    density: Fluent2Density.compact,
    brand: galleryBrands.first,
  ),
};

/// The settings every section has a golden in.
const goldenSettings = ['compact'];

/// The goldens are kept with the source and laid here by its build; a published copy compares nothing.
final bool _recorded =
    autoUpdateGoldenFiles || Directory('test/goldens').existsSync();

void main() {
  setUpAll(loadFluent2TestFonts);

  void customize(GalleryCustom custom) {
    kitShownTheme = (brightness) => custom.theme('lapis', brightness);
    addTearDown(() => kitShownTheme = null);
  }

  test('the panel untouched is the preset as designed', () {
    for (final b in Brightness.values) {
      expect(
        const GalleryCustom().theme('lapis', b),
        Fluent2ThemeData.preset('lapis', b),
      );
    }
  });

  for (final MapEntry(key: name, value: custom) in settings.entries) {
    for (final page in galleryPages) {
      for (final b in Brightness.values) {
        testWidgets('${page.id} ${b.name}, $name: the target guidelines hold', (
          tester,
        ) async {
          customize(custom);
          final semantics = tester.ensureSemantics();
          try {
            await pumpGalleryPage(tester, page, 'lapis', b);
            final failed = <String>[];
            for (final (what, guideline) in [
              ('Android 48 px targets', androidTapTargetGuideline),
              ('iOS 44 px targets', iOSTapTargetGuideline),
              ('labelled targets', labeledTapTargetGuideline),
            ]) {
              final result = await guideline.evaluate(tester);
              if (!result.passed) failed.add('$what: ${result.reason}');
            }
            expect(failed, isEmpty, reason: failed.join('\n'));
          } finally {
            semantics.dispose();
          }
        });

        // Contrast reads drawn pixels (the rasterizer's, as a golden's).
        testWidgets('${page.id} ${b.name}, $name: text contrast holds', (
          tester,
        ) async {
          customize(custom);
          final semantics = tester.ensureSemantics();
          try {
            await pumpGalleryPage(tester, page, 'lapis', b);
            final inked = await inkedContrastFailures(tester);
            expect(
              inked,
              isEmpty,
              reason: 'text contrast: ${inked.join('; ')}',
            );
          } finally {
            semantics.dispose();
          }
        }, tags: const ['goldens']);
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
          await pumpGalleryPage(tester, page, 'lapis', Brightness.light);
          for (final (label, section) in sections()) {
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

  testWidgets('a press caught between two shapes', (tester) async {
    if (!_recorded) return;
    // At rest a square face; pressed, a rounded rectangle. Half way through the press the radius is between them.
    final shape = WidgetStateProperty.resolveWith<OutlinedBorder?>(
      (s) => s.contains(WidgetState.pressed)
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            )
          : const RoundedRectangleBorder(),
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(galleryWidth, 160);
    addTearDown(tester.view.reset);
    final theme = Fluent2ThemeData.preset('lapis', Brightness.light);
    await tester.pumpWidget(
      Fluent2Theme(
        data: theme,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: theme.background,
            child: Center(
              child: RepaintBoundary(
                key: const ValueKey('press'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Fluent2Button(
                    'Send',
                    appearance: Fluent2ButtonAppearance.primary,
                    style: Fluent2Style(shape: shape),
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byType(Fluent2Button);
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump();
    await tester.pump(Fluent2Motion.normal ~/ 2);
    await expectLater(
      find.byKey(const ValueKey('press')),
      matchesGoldenFile('goldens/styled/press_mid_change.png'),
    );
    await gesture.up();
    await tester.pumpAndSettle();
  }, tags: const ['goldens']);
}
