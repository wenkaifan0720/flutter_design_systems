// The coordinator's walk of the example in a browser at 1440 and 600 (msg_401ee832e8e5, 11-12) found faults no shared
// check reads. Each is held here, with the check that should have caught it:
// - One row, one height, in the gallery's own bar: Day and night stood 44 high beside Customize's 37. DesignRowCheck
//   reads the rows of the pages it is shown; the example's own app bar is chrome no page carries, so no check was ever
//   shown it. Held by DesignRowCheck over the example app itself, and over a segmented control beside a button.
// - The way back's ◂ stood in its face's top corner. DesignLabelCheck holds a control's words and icon glyph on its face's
//   middle; a mark the look paints itself (a triangle, a chevron) is neither, so it is not read. Held by the mark's
//   middle against its press's.
// ignore_for_file: avoid_relative_lib_imports
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:ui_core/alignment.dart';

import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/main.dart';
import 'gallery_support.dart';
import 'misreads.dart';
import 'support.dart';

const _look = 'Retro Desktop';

/// The view's device pixel ratio: the checks' own.
const _ratio = 3.0;

Future<List<String>> _rows(WidgetTester tester) async =>
    (await const DesignRowCheck(
      look: _look,
    ).check(tester.binding.rootElement!, runAsync: tester.runAsync)).problems;

void main() {
  setUpAll(() async {
    await loadRetroDesktopFonts();
    await loadRetroDesktopGlyphFace();
    await loadRetroDesktopManifestFonts();
  });
  tearDown(() {
    kitShownTheme = null;
    kitShownChrome = true;
  });

  testWidgets('the gallery\'s own bar shows one top and one bottom: Day and '
      'night beside Customize', (tester) async {
    addTearDown(tester.view.reset);
    final problems = <String>[];
    for (final width in const [600.0, 1024.0, 1440.0]) {
      tester.view.devicePixelRatio = _ratio;
      tester.view.physicalSize = Size(width, 900) * _ratio;
      await tester.pumpWidget(
        KeyedSubtree(key: ValueKey(width), child: const GalleryApp()),
      );
      await settle(tester);
      for (final p in await _rows(tester)) {
        debugPrint('BARP $width: $p');
        problems.add('$width: $p');
      }
    }
    // The page under the bar (Overview) is read by the rows test too; what it
    // misreads there it misreads here.
    final real = withoutMisreads('rows', problems, rowMisreads);
    expect(real, isEmpty, reason: real.join('\n'));
  }, tags: const ['goldens']);

  for (final appearance in RetroDesktopAppearance.values) {
    for (final density in RetroDesktopDensity.values) {
      testWidgets('a segmented control beside a button shows the button\'s '
          'face height: ${appearance.name}, ${density.name}', (tester) async {
        addTearDown(tester.view.reset);
        tester.view.devicePixelRatio = _ratio;
        tester.view.physicalSize = const Size(1440, 400) * _ratio;
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, child) => RetroDesktopTheme(
              data: RetroDesktopThemeData.preset(
                kitShownPreset,
                Brightness.light,
              ).copyWith(appearance: appearance, density: density),
              child: child!,
            ),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: RetroDesktopSegmentedButton<int>(
                        showLabel: false,
                        label: 'Day and night',
                        value: 0,
                        segments: const [
                          RetroDesktopButtonSegment(0, 'Day'),
                          RetroDesktopButtonSegment(1, 'Night'),
                        ],
                        onChanged: (_) {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    RetroDesktopButton('Customize', onPressed: () {}),
                  ],
                ),
              ),
            ),
          ),
        );
        await settle(tester);
        final real = withoutMisreads('rows', await _rows(tester), [
          ...rowMisreads,
          if (appearance == RetroDesktopAppearance.chisel) ...chiselRowMisreads,
        ]);
        expect(real, isEmpty, reason: real.join('\n'));
      }, tags: const ['goldens']);
    }
  }

  for (final appearance in RetroDesktopAppearance.values) {
    for (final width in const [390.0, 1440.0]) {
      testWidgets('the way back\'s painted triangle stands on its face\'s '
          'middle: ${appearance.name}, $width', (tester) async {
        addTearDown(tester.view.reset);
        tester.view.devicePixelRatio = _ratio;
        tester.view.physicalSize = Size(width, 400) * _ratio;
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, child) => RetroDesktopTheme(
              data: RetroDesktopThemeData.preset(
                kitShownPreset,
                Brightness.light,
              ).copyWith(appearance: appearance).atWidth(width),
              child: child!,
            ),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: RetroDesktopBackButton(onPressed: () {}),
                ),
              ),
            ),
          ),
        );
        await settle(tester);
        final back = find.byType(RetroDesktopBackButton);
        final press = find
            .descendant(of: back, matching: find.byType(RetroDesktopPressable))
            .first;
        final mark = find
            .descendant(
              of: back,
              matching: find.byWidgetPredicate(
                (w) => w.runtimeType.toString() == 'RetroDesktopPixelPaint',
              ),
            )
            .first;
        final face = tester.getRect(press).center;
        final drawn = tester.getRect(mark).center;
        expect(
          (drawn - face).distance,
          lessThanOrEqualTo(0.5),
          reason: 'the mark at $drawn, its press\'s middle at $face',
        );
      });
    }
  }
}
