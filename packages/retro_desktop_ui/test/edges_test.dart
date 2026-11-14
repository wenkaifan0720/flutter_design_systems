// Every example starts on its column's edge: the first pixel it draws is the column's first (the coordinator's walk of
// the example in a browser at 1440, 11-12: a 32 px face in a 44 px target stood 6 px in, a quiet glyph 17 px in, a chip
// row's first gap read 14 for 8). Read from the drawn frame, on a desk (macOS, where a target pads only what is pressed),
// for every page of the gallery the side navigation lists, at 1440 and 600.
//
// What it can judge, and only that: the start. A glyph's or a letter's side bearing may stand up to [_bearing] px in (a
// face's first ink is not its box's first pixel). The states that stand centred in their room by design (an empty list,
// loading, an error, done) are named in [_centred], and the scenes of a raised window over a stand-in page in [_scenes];
// neither is held to the edge. The end is not judged: a column hands
// every child its whole width, so an example's box always spans it and its last pixel says nothing about whether it
// should.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/main.dart';
import 'gallery_support.dart';
import 'support.dart';

/// The most a glyph's or a letter's side bearing stands its first ink in from its box.
const _bearing = 3;

/// Sections whose example's first ink is a large glyph's or a drawing's own side bearing, larger than a text letter's:
/// the big figure's numeral, alone or in the figure hero (Jersey at 96 px stands 4 px in), and a desk mark (drawn on a
/// 48 grid whose disk starts at 5, as the period's icons kept a margin). Each holds to its own bearing, no further.
const _drawnBearing = {
  'Objects and figures: A big figure': 5,
  'Objects and figures: An object beside its words': 6,
  'Objects and figures: A figure hero': 5,
};

/// Sections whose examples stand centred in their room by design: empty and loading states, an error, done.
const _centred = {
  'Feedback: Loading',
  'Feedback: An error',
  'Feedback: Done',
  'Feedback: Empty',
};

/// Sections whose example is a scene, a raised window standing over a stand-in page: the page's rows keep a page's
/// own inset, and the window stands where it opens, so neither starts on the column's edge.
const _scenes = {
  'Dialogs and sheets: A dialog window',
  'Dialogs and sheets: A sheet at the foot',
};

/// Whether two RGBA pixels differ by more than the anti-aliasing of an edge does.
bool _differs(int a, int b) {
  for (var s = 0; s < 32; s += 8) {
    if ((((a >> s) & 255) - ((b >> s) & 255)).abs() > 24) return true;
  }
  return false;
}

/// The examples of every section on screen, each with its section's label: the column's children after its header.
List<(String, RenderBox, RenderBox)> _examples() => [
  for (final (label, section) in sections())
    for (final column
        in find
            .descendant(of: section, matching: find.byType(RetroDesktopColumn))
            .evaluate()
            .take(1))
      for (final (i, kid) in () {
        final kids = <RenderBox>[];
        column.renderObject!.visitChildren((c) => kids.add(c as RenderBox));
        return kids.indexed;
      }())
        if (i > 0) (label, column.renderObject! as RenderBox, kid),
];

Future<List<String>> _misplaced(WidgetTester tester, String page) async {
  final view = tester.binding.renderViews.first;
  final width = view.size.width.round();
  final height = view.size.height.round();
  final image = (await tester.runAsync(
    () => captureImage(tester.binding.rootElement!),
  ))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final ratio = image.width / width;
  int at(int x, int y) => bytes.getUint32(
    ((y * ratio).floor() * image.width + (x * ratio).floor()) * 4,
  );
  final found = <String>[];
  for (final (label, column, example) in _examples()) {
    final col = MatrixUtils.transformRect(
      column.getTransformTo(null),
      Offset.zero & column.size,
    );
    final box = MatrixUtils.transformRect(
      example.getTransformTo(null),
      Offset.zero & example.size,
    );
    final left = col.left.round();
    final right = col.right.round();
    if (_centred.contains('$page: $label') ||
        _scenes.contains('$page: $label')) {
      continue;
    }
    if (box.height < 1 || box.bottom <= 0 || box.top >= height) continue;
    // The column's ground: what stands just outside its edge, where no example draws.
    final top = box.top.round().clamp(0, height - 1);
    final bottom = box.bottom.round().clamp(0, height);
    final ground = at((left - 4).clamp(0, width - 1), top);
    int? first;
    for (var y = top; y < bottom; y++) {
      for (var x = (left - 12).clamp(0, width - 1); x < (first ?? right); x++) {
        if (_differs(at(x, y), ground)) {
          first = x;
          break;
        }
      }
    }
    if (first == null) continue;
    final name = '$page: $label, example at ${box.top.round()}';
    if (first < left ||
        first - left > (_drawnBearing['$page: $label'] ?? _bearing)) {
      found.add('$name: its first pixel is ${first - left} px from the edge');
    }
  }
  image.dispose();
  return found;
}

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

  for (final width in const [1440.0, 600.0]) {
    testWidgets('every example starts on its column\'s edge at $width', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        addTearDown(tester.view.reset);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpWidget(const GalleryApp());
        await settle(tester);
        // The first page is an app, the whole screen: back to the gallery.
        if (find.byKey(galleryNavKey).evaluate().isEmpty &&
            find.text('Pages').evaluate().isEmpty) {
          await tester.tap(find.text('Gallery').first);
          await settle(tester);
        }
        final found = <String>[];
        for (final page in examplePages) {
          if (galleryAppPages.contains(page.name)) continue;
          if (width < gallerySideNavWidth) {
            await tester.tap(find.text('Pages').first);
            await settle(tester);
          }
          tester.view.physicalSize = Size(width, 900);
          await settle(tester);
          // The page list outgrows a 900 tall screen: bring the entry into view (built and on screen) first.
          final entry = find.descendant(
            of: find.byKey(galleryNavKey),
            matching: find.text(page.name),
          );
          if (entry.evaluate().isEmpty) {
            await tester.scrollUntilVisible(
              entry,
              40,
              scrollable: find
                  .descendant(
                    of: find.byKey(galleryNavKey),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
          }
          await tester.ensureVisible(entry.first);
          await settle(tester);
          await tester.tap(entry.first);
          await settle(tester);
          final scrollables = tester
              .stateList<ScrollableState>(find.byType(Scrollable))
              .where((s) => s.position.axis == Axis.vertical)
              .map((s) => s.position.maxScrollExtent);
          final extent = scrollables.isEmpty
              ? 0.0
              : scrollables.reduce((a, b) => a > b ? a : b);
          if (extent > 0) {
            tester.view.physicalSize = Size(width, 900 + extent);
            await settle(tester);
          }
          for (final p in await _misplaced(tester, page.name)) {
            debugPrint('EDGE $width $p');
            found.add(p);
          }
        }
        expect(found, isEmpty, reason: found.join('\n'));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    }, tags: const ['goldens']);
  }
}
