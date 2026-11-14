// The example's Customize panel, at every setting it offers: Flutter's four guidelines on every gallery page, by day and
// by night (Android's 48 px and iOS's 44 px targets, labelled targets, text contrast read with each word's own ink). For
// the corner families, a heavy stroke and a compact density, a golden of every section; and a golden of one press
// caught between two shapes. `flutter test --update-goldens` records them.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

// The panel is the example app's; a test reads its settings from there.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/main.dart';
import 'gallery_support.dart';
import 'support.dart';

/// Every setting: each knob away from the look's own, each pair of your own colours, and every knob at once.
final Map<String, GalleryCustom> settings = {
  'high contrast': const GalleryCustom(highContrast: true),
  'standard': const GalleryCustom(density: GalleryDensity.standard),
  'compact': const GalleryCustom(density: GalleryDensity.compact),
  'flat relief': const GalleryCustom(depth: 0),
  'shallow relief': const GalleryCustom(depth: .5),
  for (final pair in galleryColours)
    pair.name.toLowerCase(): GalleryCustom(colours: pair),
  'every knob': GalleryCustom(
    highContrast: true,
    density: GalleryDensity.compact,
    depth: .5,
    colours: galleryColours.first,
  ),
};

/// Settings represented by a golden of every section.
const goldenSettings = ['high contrast', 'compact', 'flat relief'];

/// The goldens are kept beside the catalog and laid here by the package build; a published copy compares nothing.
final bool _recorded =
    autoUpdateGoldenFiles || Directory('test/goldens').existsSync();

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });

  void customize(GalleryCustom custom) {
    kitShownTheme = (brightness) => custom.theme('porcelain', brightness);
    addTearDown(() => kitShownTheme = null);
  }

  test('the panel untouched is the preset as designed', () {
    for (final b in Brightness.values) {
      expect(
        const GalleryCustom().theme('porcelain', b),
        NeumorphicThemeData.preset('porcelain', b),
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
            try {
              await pumpGalleryPage(tester, page, 'porcelain', b);
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
              final inked = await inkedContrastFailures(tester);
              if (inked.isNotEmpty) {
                failed.add(
                  'text contrast: ${inked.join('; ')}; pixel reading: ${pixels.reason}',
                );
              }
              expect(failed, isEmpty, reason: failed.join('\n'));
            } finally {
              semantics.dispose();
            }
          },
          tags: ['goldens'],
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
          await pumpGalleryPage(tester, page, 'porcelain', Brightness.light);
          final found = sections();
          expect(found, isNotEmpty);
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

  testWidgets('a press caught between two shapes', (tester) async {
    if (!_recorded) return;
    // At rest a rounded face; pressed, a pill. Half way through the press the outline is neither.
    final shape = WidgetStateProperty.resolveWith<OutlinedBorder?>(
      (s) => s.contains(WidgetState.pressed)
          ? const NeumorphicStadiumBorder(maxRadius: 24)
          : const NeumorphicRoundedBorder(radius: 4),
    );
    final style = NeumorphicStyle(shape: shape);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(galleryWidth, 160);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      NeumorphicTheme(
        data: NeumorphicThemeData.preset('porcelain', Brightness.light),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) => ColoredBox(
              color: NeumorphicTheme.of(context).colors.ground,
              child: Center(
                child: RepaintBoundary(
                  key: const ValueKey('press'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: NeumorphicButton.filled(
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
    final button = find.byType(NeumorphicButton);
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump();
    await tester.pump(NeumorphicMotion.of(tester.element(button)).state ~/ 2);
    await expectLater(
      find.byKey(const ValueKey('press')),
      matchesGoldenFile('goldens/styled/press_mid_change.png'),
    );
    await gesture.up();
    await tester.pumpAndSettle();
  }, tags: const ['goldens']);
}
