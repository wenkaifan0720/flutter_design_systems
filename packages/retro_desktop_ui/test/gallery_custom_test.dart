// The example's Customize panel, at every setting it offers: Flutter's four guidelines on every gallery page, by day and
// by night (Android's 48 px and iOS's 44 px targets, labelled targets, text contrast read with each word's own ink). For
// the Chisel appearance and a compact density, a golden of every section (Platinum's are the plain ones);
// and a golden of one press caught between two shapes. `flutter test --update-goldens` records them.
import 'dart:io';

import 'package:flutter/gestures.dart' show kPressTimeout;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

// The panel is the example app's; a test reads its settings from there.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/main.dart';
import 'gallery_support.dart';
import 'support.dart';

/// Every setting: each knob away from the look's own, each pair of your own colours, and every knob at once.
final Map<String, GalleryCustom> settings = {
  'chisel': const GalleryCustom(appearance: RetroDesktopAppearance.chisel),
  'standard': const GalleryCustom(density: RetroDesktopDensity.standard),
  'comfortable': const GalleryCustom(density: RetroDesktopDensity.comfortable),
  'compact': const GalleryCustom(density: RetroDesktopDensity.compact),
  for (final pair in galleryColours)
    pair.name.toLowerCase(): GalleryCustom(colours: pair),
  'every knob': GalleryCustom(
    appearance: RetroDesktopAppearance.chisel,
    density: RetroDesktopDensity.compact,
    colours: galleryColours.first,
  ),
};

/// The settings every section has a golden in.
const goldenSettings = ['chisel', 'compact'];

/// The goldens are kept beside the catalog and laid here by the package build; a published copy compares nothing.
final bool _recorded =
    autoUpdateGoldenFiles || Directory('test/goldens').existsSync();

void main() {
  setUpAll(() async {
    await loadRetroDesktopFonts();
    await loadBundledFonts();
  });

  void customize(GalleryCustom custom) {
    kitShownTheme = (brightness) => custom.theme('classic', brightness);
    addTearDown(() => kitShownTheme = null);
  }

  test('the panel untouched is the preset as designed', () {
    for (final b in Brightness.values) {
      expect(
        const GalleryCustom().theme('classic', b),
        RetroDesktopThemeData.preset('classic', b),
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
              await pumpGalleryPage(tester, page, 'classic', b);
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
                  'text contrast: ${inked.join('; ')}'
                  '${pixels.passed ? '' : '\nFlutter reading: ${pixels.reason}'}',
                );
              }
              expect(failed, isEmpty, reason: failed.join('\n'));
            } finally {
              semantics.dispose();
            }
          },
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
          await pumpGalleryPage(tester, page, 'classic', Brightness.light);
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
    // At rest a square plate; pressed, one-pixel bevels. Half way through the press the outline is interpolated.
    final shape = WidgetStateProperty.resolveWith<OutlinedBorder?>(
      (s) => s.contains(WidgetState.pressed)
          ? const RetroDesktopBorder.bevelled()
          : const RetroDesktopBorder.square(),
    );
    final style = RetroDesktopStyle(shape: shape);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(galleryWidth, 160);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RetroDesktopTheme(
        data: RetroDesktopThemeData.preset('classic', Brightness.light)
            .copyWith(
              motion: const RetroDesktopMotion(
                state: Duration(milliseconds: 120),
              ),
            ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) => ColoredBox(
              color: RetroDesktopTheme.of(context).colors.desktop,
              child: Center(
                child: RepaintBoundary(
                  key: const ValueKey('press'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: RetroDesktopButton(
                      'Reserve',
                      isDefaultAction: true,
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
    final button = find.byType(RetroDesktopButton);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Reserve')),
    );
    await tester.pump(kPressTimeout);
    await tester.pump(RetroDesktopMotion.of(tester.element(button)).state ~/ 2);
    await expectLater(
      find.byKey(const ValueKey('press')),
      matchesGoldenFile('goldens/styled/press_mid_change.png'),
    );
    await gesture.up();
    await tester.pumpAndSettle();
  }, tags: const ['goldens']);
}
