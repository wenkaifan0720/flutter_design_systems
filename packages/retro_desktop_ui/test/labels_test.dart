// Labels (ui_core's DesignLabelCheck, 11-11): every labelled control's words and glyph on the middle of its face, as
// laid out and as drawn, under each density the look ships by default (standard on a phone, compact on a desktop), on
// every gallery page, the ordinary screens and Papers' windows, at 390 and 1440, in Platinum and Chisel. What the
// check misreads here is named by kind, with its reason, in misreads.dart; the rest must be empty.
// The package emitter carries the example's own app into example/lib.
// ignore_for_file: avoid_relative_lib_imports
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../example/lib/kit_gallery/demos/charts.dart';
import '../example/lib/kit_gallery/demos/chrome.dart';
import '../example/lib/kit_gallery/demos/complete.dart';
import '../example/lib/kit_gallery/demos/controls.dart';
import '../example/lib/kit_gallery/demos/coverage.dart';
import '../example/lib/kit_gallery/demos/entries.dart';
import '../example/lib/kit_gallery/demos/foundations.dart';
import '../example/lib/kit_gallery/demos/frames.dart';
import '../example/lib/kit_gallery/demos/lists.dart';
import '../example/lib/kit_gallery/demos/objects.dart';
import '../example/lib/kit_gallery/demos/ordinary.dart';
import '../example/lib/kit_gallery/demos/papers.dart';
import '../example/lib/kit_gallery/demos/raised.dart';
import '../example/lib/kit_gallery/demos/rows.dart';
import '../example/lib/kit_gallery/kit.dart';

import 'misreads.dart';
import 'support.dart';

final _pages = <String, Widget Function(Brightness)>{
  'foundations': kitFoundationsDemo,
  'controls': kitControlsDemo,
  'entries': kitEntriesDemo,
  'lists': kitListsDemo,
  'rows': kitRowsDemo,
  'objects': kitObjectsDemo,
  'frames': kitFramesDemo,
  'chrome': kitChromeDemo,
  'raised': kitRaisedDemo,
  'charts': kitChartsDemo,
  'complete': kitCompleteDemo,
  'coverage': kitCoverageDemo,
  'everyday': kitOrdinaryDemo,
};

void main() {
  setUpAll(() async {
    await loadRetroDesktopFonts();
    await loadRetroDesktopGlyphFace();
    await loadRetroDesktopManifestFonts();
  });
  tearDown(() => kitShownTheme = null);
  for (final width in [390.0, 1440.0]) {
    for (final appearance in [
      RetroDesktopAppearance.platinum,
      RetroDesktopAppearance.chisel,
    ]) {
      for (final density in [
        RetroDesktopDensity.standard,
        RetroDesktopDensity.compact,
      ]) {
        testWidgets('labels at $width in ${appearance.name}, '
            '${density.name}', (tester) async {
          // Tall enough to hold most of a page: the check reads what is on
          // screen.
          // At the check's own pixel ratio, 3: the look's painters draw their
          // faces on the view's device pixels, and at 1 a face standing on a
          // fractional logical y moved up to a whole pixel against its words,
          // which the check reads on a grid three times as fine (a screen of
          // any density draws both on its own grid).
          tester.view.devicePixelRatio = 3;
          tester.view.physicalSize = Size(width, width > 600 ? 1600 : 2400) * 3;
          addTearDown(tester.view.reset);
          RetroDesktopThemeData theme(Brightness b) =>
              RetroDesktopThemeData.preset(
                kitShownPreset,
                b,
              ).copyWith(appearance: appearance, density: density);
          kitShownTheme = theme;
          final problems = <String>[];
          Future<void> read(String screen) async {
            // The screen's images decoded and drawn first, as the check asks.
            await tester.runAsync(
              () => Future.wait([
                for (final e in find.byType(Image).evaluate())
                  precacheImage(
                    (e.widget as Image).image,
                    e,
                    onError: (_, _) {},
                  ),
              ]),
            );
            await tester.pump();
            final report = await const DesignLabelCheck(
              look: 'Retro Desktop',
              drawnTolerance: 0.5,
            ).check(tester.binding.rootElement!, runAsync: tester.runAsync);
            for (final p in report.problems) {
              debugPrint(
                'LABELP $width ${appearance.name} ${density.name} $screen: $p',
              );
              problems.add('$screen: $p');
            }
          }

          Future<void> show(String screen, Widget app) async {
            await tester.pumpWidget(
              KeyedSubtree(
                key: ValueKey('$screen/$width/$appearance/$density'),
                child: app,
              ),
            );
            await tester.pumpAndSettle();
            await read(screen);
          }

          for (final MapEntry(:key, :value) in _pages.entries) {
            await show(key, value(Brightness.light));
          }
          for (final screen in kitOrdinaryScreens) {
            await show(screen, kitOrdinaryScreen(screen, Brightness.light));
          }
          for (final front in [
            KitPapersWindow.documents,
            KitPapersWindow.details,
            KitPapersWindow.settings,
            KitPapersWindow.prints,
          ]) {
            await show(
              'Papers ${front.name}',
              MaterialApp(
                debugShowCheckedModeBanner: false,
                builder: (context, child) => RetroDesktopTheme(
                  data: theme(Brightness.light)
                      .atWidth(MediaQuery.sizeOf(context).width),
                  child: child!,
                ),
                home: KitPapers(front: front),
              ),
            );
          }
          debugPrint(
            'LABELS $width ${appearance.name} ${density.name}: '
            '${problems.length}',
          );
          final real = withoutMisreads('labels', problems, [
            ...labelMisreads,
            if (appearance == RetroDesktopAppearance.chisel)
              ...chiselLabelMisreads,
          ]);
          expect(real, isEmpty, reason: real.join('\n'));
        }, tags: const ['goldens']);
      }
    }
  }
}
