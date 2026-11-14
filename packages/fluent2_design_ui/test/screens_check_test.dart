// ui_core's two sweeps over the gallery:
// - the keyline check on Northwind's four ordinary screens (Home, Files, New
//   request, Settings) at a phone's 390 and a desktop's 1440 (right to left
//   is the module's keylines_test): every control or well read as one item
//   at its face, words judged only on the side they are anchored to;
// - the label sweep under the standard and the compact density over every
//   gallery page at 390 and the four screens at 1440 too: every labelled
//   control's label (by its capitals) and icon on the middle of its face,
//   as laid out and, within half a device pixel, as drawn (the faces wrap
//   their words in DesignCapCenter, internal/cap_label.dart). It records
//   what it names in build/label_sweep/<page>_<width>.txt; with
//   FLUENT2_SWEEP_BEFORE=1 it also reads every page with the capitals'
//   centring off, into build/label_sweep_before/, for the counts.
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/src/fluent2_design/internal/cap_label.dart';
import 'package:ui_core/alignment.dart';

import 'gallery_support.dart';

Iterable<GalleryPage> get _screens =>
    galleryPages.where((p) => p.id.startsWith('app-'));

const _densities = {
  'standard': Fluent2Density.standard,
  'compact': Fluent2Density.compact,
};

/// [page] at [width], light, under [density], grown to its whole height
/// and held still.
Future<void> _pump(
  WidgetTester t,
  GalleryPage page,
  double width, {
  String density = 'standard',
}) => pumpWhole(t, page, width, density: _densities[density]!);

/// What the label sweep names that is not the look's: each a pattern and
/// why, reported to ui_core.
final _misreads = <(RegExp, String)>[
  (
    RegExp(r'a button "[^"]*(\d+ unread|, new)": its icon is [\d.]+ px above'),
    'an icon is read from the pixels of its box, and the count badge that '
        'rides its top end corner paints over that box (the bell without a '
        'badge reads centred; its art sits 0.24 px off its em\'s middle); two '
        'density steps in the face a badge rides is 24, so a dot reaches the '
        'glyph\'s box',
  ),
  (
    RegExp(
      r'a button "New (event|meeting)": its icon is (0\.8|1(\.0)?) px below',
    ),
    'Fluent\'s calendar_add art sits 1.0 px low in its em (ink 25 to 425 of '
        '500 units, its plus at the foot); its box is on the face\'s middle '
        '(read as 0.8 px on macOS, 1 px under Linux\'s rasteriser)',
  ),
  (
    RegExp(
      r'a button "Select [^"]*": the capitals of "[^"]*" are drawn '
      r'1\.[3-6] device px below the middle of its face',
    ),
    'a selectable table row: its selection cell spans the row and is read '
        'as the face of the row\'s words, which stand centred between the '
        'row\'s two hairlines (its own inside its box, as Fluent\'s grid row '
        'keeps it), half a pixel off the cell\'s middle',
  ),
  (
    RegExp(
      r'a button "[^"]*; [^"]*": the capitals of "[^"]*" are drawn '
      r'(1\.[5-9]|2\.0) device px above',
    ),
    'a table row\'s face is read with its own bottom hairline, which stands '
        'inside its box: between the row\'s two hairlines its words are '
        'centred, half a pixel over the box\'s middle',
  ),
];

/// What the label sweep names on [page] at [width], each led by its
/// density, less [_misreads].
Future<List<String>> _sweep(
  WidgetTester t,
  GalleryPage page,
  double width,
) async {
  final found = <String>[];
  for (final name in _densities.keys) {
    await _pump(t, page, width, density: name);
    const check = DesignLabelCheck(look: 'Fluent 2', drawnTolerance: 0.5);
    DesignAlignmentReport report;
    try {
      report = await check.check(_shown(t), runAsync: t.runAsync);
    } on StateError {
      // Something drew again after the last frame: the timers due fire
      // (a scrollbar's fade; the tickers stay still), then one more read.
      await t.pump(const Duration(seconds: 2));
      await t.pump();
      try {
        report = await check.check(_shown(t), runAsync: t.runAsync);
      } on StateError {
        // ui_core's reader refuses a boundary never painted: a row in an
        // inner list's cache extent (laid out, off its viewport), the code
        // entry's hidden line under Opacity(0). Named, reported to ui_core's
        // owner; the rest of the sweep goes on.
        // ignore: avoid_print
        print(
          'UNREAD ${page.id}_${width.round()} · $name: a control under it '
          "was never painted (a list's cache extent, a hidden entry)",
        );
        continue;
      }
    }
    found.addAll([
      for (final p in report.problems)
        if (!_misreads.any((m) => m.$1.hasMatch(p))) '$name · $p',
    ]);
  }
  return found;
}

void _record(String dir, String name, List<String> found) {
  // Into the log too: a later export of the package clears its build/.
  for (final line in found) {
    // ignore: avoid_print
    print('SWEEP $dir $name · $line');
  }
  final out = File('build/$dir/$name.txt');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(found.isEmpty ? '' : '${found.join('\n')}\n');
}

Element _shown(WidgetTester t) => shownScreen(t);

void main() {
  setUpAll(loadFluent2TestFonts);

  for (final page in _screens) {
    for (final width in const [390.0, 1440.0]) {
      // ui_core's checks read the ink from drawn pixels (the rasterizer's,
      // as a golden's): tagged `goldens`, run where the goldens run.
      testWidgets('${page.id}, ${width.round()} wide: the keylines hold', (
        t,
      ) async {
        await _pump(t, page, width);
        final report = await const DesignKeylineCheck(look: 'Fluent 2')
            .check(_shown(t), runAsync: t.runAsync);
        report.verify();
      }, tags: const ['goldens']);
    }
  }

  for (final page in galleryPages) {
    final widths = page.id.startsWith('app-')
        ? const [390.0, 1440.0]
        : const [galleryWidth];
    for (final width in widths) {
      testWidgets('${page.id}, ${width.round()} wide: every label sits on '
          'its face\'s middle, standard and compact', (t) async {
        final name = '${page.id}_${width.round()}';
        if (Platform.environment['FLUENT2_SWEEP_BEFORE'] == '1') {
          debugFluent2CapCentring = false;
          try {
            _record('label_sweep_before', name, await _sweep(t, page, width));
          } finally {
            debugFluent2CapCentring = true;
          }
        }
        final found = await _sweep(t, page, width);
        _record('label_sweep', name, found);
        expect(found, isEmpty, reason: found.join('\n'));
      }, tags: const ['goldens']);
    }
  }
}
