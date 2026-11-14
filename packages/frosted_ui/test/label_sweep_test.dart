// The label sweep (ui_core's DesignLabelCheck): every gallery page under each density Frosted ships by name, standard
// and compact, each labelled control's label and icon read off the middle of its face, as laid out and as drawn. A
// control centred under one density and not the other fails under that one's name. Harbor's screens are swept in
// harbor_test.dart.
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:ui_core/alignment.dart';

import 'gallery_support.dart';

// The gallery is the example app; a test sets the theme it shows.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';

const _densities = {
  'standard': FrostedDensity.standard,
  'compact': FrostedDensity.compact,
};

const _screen = ValueKey('label-sweep');

/// Pages whose sweep misreads on macOS, skipped until 0.2.0 ("design-sweep
/// reads"): ui_core reads a label 0.5-0.9 device px off its face's middle.
const _misread = {
  'command': 'ui_core misread, 0.2.0 design-sweep reads: label middles',
  'menu': 'ui_core misread, 0.2.0 design-sweep reads: label middles',
  'preview': 'ui_core misread, 0.2.0 design-sweep reads: label middles',
  'structure': 'ui_core misread, 0.2.0 design-sweep reads: label middles',
};

/// Lets images decode (they load in real time), then paints the frame they
/// mark, so a check that reads pixels finds every boundary painted.
Future<void> _painted(WidgetTester tester) async {
  await tester.runAsync(
    () => Future.wait([
      for (final e in find.byType(Image).evaluate())
        precacheImage((e.widget as Image).image, e),
    ]),
  );
  await tester.pump();
}

/// Every family the package's FontManifest.json lists (its faces and the
/// glyphs' Lucide), under the manifest's name and the package's: a check
/// fails, by name, on a control drawn in the test's own font.
Future<void> _fonts() async {
  final manifest = (json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>).cast<Map<String, dynamic>>();
  for (final family in manifest) {
    final name = family['family'] as String;
    final fonts = (family['fonts'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    for (final alias in [
      name,
      if (!name.startsWith('packages/')) 'packages/frosted_ui/$name',
    ]) {
      final loader = FontLoader(alias);
      for (final font in fonts) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  }
}

void main() {
  setUpAll(_fonts);

  for (final page in galleryPages) {
    testWidgets(
      '${page.id}: every label on its face\'s middle, standard '
      'and compact',
      (tester) async {
        addTearDown(() => kitShownTheme = null);
        addTearDown(tester.view.reset);
        tester.view.devicePixelRatio = 1;
        final problems = <String>[];
        for (final MapEntry(key: name, value: density) in _densities.entries) {
          kitShownTheme = (b) => FrostedThemeData.preset(
            kitShownPreset,
            b,
          ).copyWith(density: density);
          tester.view.physicalSize = const Size(galleryWidth, 844);
          await tester.pumpWidget(
            RepaintBoundary(
              key: _screen,
              child: KeyedSubtree(
                key: ValueKey('${page.id}/$name'),
                child: page.build(Brightness.light),
              ),
            ),
          );
          await settle(tester);
          // The whole page on screen at once, as the gallery tests grow it.
          final scrollables = tester
              .stateList<ScrollableState>(find.byType(Scrollable))
              .where((s) => s.position.axis == Axis.vertical);
          final extent = scrollables.isEmpty
              ? 0.0
              : scrollables.first.position.maxScrollExtent;
          if (extent > 0) {
            tester.view.physicalSize = Size(galleryWidth, 844 + extent);
            await settle(tester);
          }
          await _painted(tester);
          final report =
              await const DesignLabelCheck(
                look: 'Frosted',
                drawnTolerance: 0.5,
              ).check(
                tester.element(find.byKey(_screen)),
                runAsync: tester.runAsync,
              );
          problems.addAll([for (final p in report.problems) '$name · $p']);
        }
        expect(problems, isEmpty, reason: problems.join('\n'));
      },
      // The check reads drawn pixels, which depend on the rasterizer as a
      // golden does.
      tags: const ['goldens'],
      skip: _misread.containsKey(page.id),
    );
  }
}
