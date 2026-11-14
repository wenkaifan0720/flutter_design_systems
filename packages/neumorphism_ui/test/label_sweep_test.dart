// ui_core's label sweep (design6 P): every labelled control on the Overview, every Hearth screen and every gallery
// page, its label and its icon on the middle of its face as laid out and as drawn, under each density the gallery
// offers (standard and compact; a control can be centred under one and not the other). Hearth's screens at a phone's
// and a desk's width; the gallery's pages at the gallery's phone width, as tall as their sections.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart'
    show DesignAlignmentReport, DesignLabelCheck;
import 'package:neumorphism_ui/src/neumorphism/internal/cap_label.dart'
    show neumorphicCapCentred;

// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/hearth.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/live.dart';
import 'gallery_support.dart' show fitPage, loadBundledFonts, settle;
import 'support.dart' show loadNeumorphicFonts;

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });
  final app = ['overview', for (final s in hearthScreens) s.id];
  final runs = <(String, double)>[
    for (final s in app)
      for (final width in [390.0, 1440.0]) (s, width),
    for (final p in liveGalleryPages)
      if (!app.contains(p.id)) (p.id, 390.0),
  ];
  for (final (screen, width) in runs) {
    testWidgets('labels on their faces $screen $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(
        width,
        app.contains(screen) ? (width < 600 ? 1400 : 1100) : 2600,
      );
      addTearDown(tester.view.reset);
      addTearDown(() => neumorphicCapCentred = true);
      // Before: labels centred by their line boxes; after: by their capitals (DesignCapCenter). Only after is held.
      final counts = <String>[];
      var found = <String>[];
      for (final centred in [false, true]) {
        neumorphicCapCentred = centred;
        found = [];
        for (final density in [
          GalleryDensity.standard,
          GalleryDensity.compact,
        ]) {
          await tester.pumpWidget(
            GalleryApp(
              key: ValueKey((density, centred)),
              initialPage: screen,
              initialCustom: GalleryCustom(density: density),
            ),
          );
          await settle(tester);
          // Every picture decoded before the screen is read (a picture finishing mid-read repaints it).
          await tester.runAsync(() async {
            for (final e in find.byType(Image).evaluate()) {
              await precacheImage((e.widget as Image).image, e);
            }
          });
          // Bounded: a page with a placeholder's shimmer never settles.
          await settle(tester);
          Future<DesignAlignmentReport> read() =>
              const DesignLabelCheck(
                look: 'Neumorphism',
                drawnTolerance: 0.5,
              ).check(
                tester.element(find.byType(GalleryApp)),
                runAsync: tester.runAsync,
              );
          // A picture finished decoding while the screen was read: let it land, then read again, at most three
          // times. A lazy list's rows built past the view are never painted: the view grows to hold the page.
          DesignAlignmentReport report;
          for (var attempt = 1; ; attempt++) {
            try {
              report = await read();
              break;
            } on StateError {
              if (attempt == 3) rethrow;
              await fitPage(tester);
              await tester.runAsync(
                () =>
                    Future<void>.delayed(Duration(milliseconds: 400 * attempt)),
              );
              await settle(tester);
            }
          }
          found.addAll([
            for (final p in report.problems) '${density.name} · $p',
          ]);
          final drawn = report.problems
              .where((p) => p.contains('device px'))
              .length;
          counts.add(
            '${centred ? 'after' : 'before'} ${density.name}: '
            '${report.problems.length - drawn} laid out, $drawn drawn',
          );
        }
      }
      final named = <String>[];
      final left = <String>[];
      for (final p in found) {
        final why = _named(p);
        (why == null ? left : named).add(why == null ? p : '$p  [$why]');
      }
      // ignore: avoid_print
      print(
        'LABELS $screen ${width.toInt()}: ${left.length} (named ${named.length}) '
        '[${counts.join('; ')}]'
        '${found.isEmpty ? '' : '\n  ${[...left, ...named].join('\n  ')}'}',
      );
      expect(left, isEmpty, reason: left.join('\n'));
    }, tags: ['goldens']);
  }
}

final _problem = RegExp(
  r'(?:a|an) (\w+) "([^"]*)": (?:the label "([^"]*)"|the capitals of "([^"]*)"|its icon)'
  r'(?: is| are drawn| is drawn) ([\d.]+) (?:device )?px (above|below)',
);

/// Why a problem the sweep reports is not a fault of the look, or null: a fault. Each class is named, and each is
/// held to its own reading so a new fault of the same look never hides in it.
String? _named(String problem) {
  // An act's face is the pigment in a 145° gradient with a sheen (controls.dart, _ActPainter): read against one face
  // colour, the gradient's rows count as ink, so the whole line box reads as capitals or as solid boxes. Every
  // family in FontManifest.json is loaded (loadBundledFonts); the same labels on flat faces read true.
  final tall = RegExp(
    r'are drawn ([\d.]+) device px high; its DesignCapCenter.s capHeightFactor gives ([\d.]+)',
  ).firstMatch(problem);
  if (tall != null && double.parse(tall[1]!) > 1.3 * double.parse(tall[2]!)) {
    return "an act's gradient face read as ink";
  }
  if (RegExp(
    r"draws its text in the test's own font \(solid boxes\), a button "
    r'"(Open Hearth, a home app|Small)" first',
  ).hasMatch(problem)) {
    return "an act's gradient face read as solid ink";
  }
  // The Appearance control's chosen cell under compact (Hearth's desk rail): its washed well, 40 tall in its 48
  // target, read as a face reaching into the bank's cast above it; drawn, "Day" stands on the cell's middle
  // (shapes/log/probe-day-compact-crop.png), and laid out it is on it.
  if (RegExp(
    r'^compact · a button "Day": the capitals of "Day" are drawn 11\.\d device px below the middle of its face$',
  ).hasMatch(problem)) {
    return "the chosen cell's well read with the bank's cast";
  }
  // A busy key turns its ring in its glyph's box (controls.dart, _glyphOrRing), centred as the glyph is, and keeps its
  // words. The ring's ink is a quarter arc: read by it, the mark stands as far off the capitals' middle as the turn
  // has it, up to the ring's radius (10), and the turn's phase depends on how many frames the page took to settle.
  // The same key at rest, its glyph in that box, reads level.
  final ring = RegExp(
    r'^(?:standard|compact) · a button "Uploading": its painted mark, before its words, is drawn ([\d.]+) device px '
    r'(?:above|below) the capitals of "Uploading"$',
  ).firstMatch(problem);
  if (ring != null && double.parse(ring[1]!) <= 10) {
    return "a busy key's turning arc read as its ring";
  }
  final m = _problem.firstMatch(problem);
  if (m == null) return null;
  final (kind, control, label) = (m[1]!, m[2]!, m[3] ?? m[4]);
  final below = m[6] == 'below';
  // A destination stands its icon over its label: the pair is centred, not the label.
  if (kind == 'control' &&
      below &&
      {'Overview', for (final s in hearthScreens) s.title}.contains(control)) {
    return 'a destination: icon over label';
  }
  // A dome stands its word over its figure: the pair is centred in the dome, not the figure.
  if (label == '63' && below) {
    return "a dial's figure under its word";
  }
  // A chosen box's LED stands in its own corner, inside the label's rows: the sweep reads its ink as the label's
  // (the box beside it, unchosen, reads on its middle).
  if (label == 'Warm' && !below) {
    return "the chosen box's LED read as label ink";
  }
  return null;
}
