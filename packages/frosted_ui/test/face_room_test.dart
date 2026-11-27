// The room a label keeps on its face (ui_core_test's DesignFaceInsetCheck, 4 at the least) where it ran short at 200%
// text, and the dimmed people's initials (DesignContrastCheck), on the gallery's pages where they were found:
// - by night a pill's heavier word drew past the width it was set at, 3.6 px from the round end of "Transfer \$500.00"
//   in a row of two; the pill now grows by what the heavier word reaches;
// - the floating bar's act wrapped "Remind me Thursday" onto a second line 3 px over its foot;
// - a person not chosen faded with its disc, its initials 3.7:1 on a seeded theme's warm disc by day (navy, green,
//   gold, purple and pastel briefs); the disc fades toward the page and the initials take the nearest tone of the
//   quiet ink that reads 4.5:1 on all of it, in Frosted's own palette and the five briefs, by day and by night.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'gallery_support.dart';

// The gallery is the example app; a test reads its pages from there.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/theme.dart';

GalleryPage _page(String id) => galleryPages.firstWhere((p) => p.id == id);

void main() {
  setUpAll(frostedLoadFonts);

  for (final brightness in Brightness.values) {
    final tag = brightness == Brightness.dark ? 'night' : 'day';
    for (final id in ['controls', 'action-bar']) {
      testWidgets('the $id page at 200% keeps every label 4 off its face '
          '($tag)', (t) async {
        t.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpGalleryPage(t, _page(id), kitPreset, brightness);
        t.takeException();
        final report = await const DesignFaceInsetCheck(look: 'Frosted')
            .check(t.binding.rootElement!, runAsync: t.runAsync);
        expect(report.problems, isEmpty);
      });
    }
  }

  testWidgets('people not chosen read 4.5:1 beside the one chosen, in its '
      'own palette and the five briefs', (t) async {
    addTearDown(() => kitShownTheme = null);
    final report = await const DesignContrastCheck(look: 'Frosted').sweep(
      show: (palette, brightness) async {
        kitShownTheme = palette == null
            ? null
            : (b) =>
                  FrostedThemeData.from(accent: palette.accent, brightness: b);
        await pumpGalleryPage(t, _page('marks'), kitPreset, brightness);
      },
      screen: () =>
          t.element(sections().firstWhere((s) => s.$1 == 'One chosen').$2),
      runAsync: t.runAsync,
    );
    expect(report.problems, isEmpty);
    expect(report.advisories, isEmpty);
  });

  testWidgets('a dimmed avatar\'s initials read 4.5:1 whatever quiet ink an '
      'app gives its theme', (t) async {
    final own = FrostedThemeData.preset('opal', Brightness.light);
    final faint = own.copyWith(
      colorScheme: own.colorScheme.copyWith(
        textSecondary: const Color(0xFF9A98A6),
      ),
    );
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => FrostedHost(
          theme: faint,
          brightness: Brightness.light,
          child: child!,
        ),
        home: const Center(child: FrostedAvatar('JR', dimmed: true)),
      ),
    );
    await t.pumpAndSettle();
    final report = await const DesignContrastCheck(look: 'Frosted')
        .check(t.binding.rootElement!, runAsync: t.runAsync);
    expect(report.problems, isEmpty);
    expect(report.advisories, isEmpty);
  });
}
