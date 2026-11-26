// ui_core_test's contrast check over the gallery's pages in each of the six palettes, by day and by night, in the
// look's own faces: what theme_test holds per pair of colours, held here on drawn screens.
// ignore_for_file: avoid_relative_lib_imports — the example app's pages are what this test checks; example/ is not a dependency of the package.
@Tags(['goldens'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

import '../example/lib/kit_gallery/demos/actions.dart';
import '../example/lib/kit_gallery/demos/charts.dart';
import '../example/lib/kit_gallery/demos/chrome.dart';
import '../example/lib/kit_gallery/demos/collections.dart';
import '../example/lib/kit_gallery/demos/controls.dart';
import '../example/lib/kit_gallery/demos/entries.dart';
import '../example/lib/kit_gallery/demos/fields.dart';
import '../example/lib/kit_gallery/demos/foundations.dart';
import '../example/lib/kit_gallery/demos/rows.dart';
import '../example/lib/kit_gallery/demos/tell.dart';
import '../example/lib/kit_gallery/kit.dart';
import 'support.dart';

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadNeumorphicGlyphs();
  });
  tearDown(() => kitShownTheme = null);

  final pages = <String, Widget Function(Brightness)>{
    'foundations': kitFoundationsDemo,
    'controls': kitControlsDemo,
    'actions': kitActionsDemo,
    'fields': kitFieldsDemo,
    'entries': kitEntriesDemo,
    'rows': kitRowsDemo,
    'collections': kitCollectionsDemo,
    'chrome': kitChromeDemo,
    'charts': kitChartsDemo,
    'tell': kitTellDemo,
  };
  for (final id in NeumorphicThemeData.presets) {
    testWidgets('$id: no contrast faults by day or by night', (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view
        ..physicalSize = const Size(390, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      kitShownTheme = (b) => NeumorphicThemeData.preset(id, b);
      final faults = <String>[];
      for (final brightness in Brightness.values) {
        for (final MapEntry(key: name, value: page) in pages.entries) {
          await tester.pumpWidget(
            KeyedSubtree(
              key: ValueKey('$id/$name/${brightness.name}'),
              child: page(brightness),
            ),
          );
          for (var i = 0; i < 30; i++) {
            await tester.pump(const Duration(milliseconds: 34));
          }
          final report = await const DesignContrastCheck(look: 'Neumorphism')
              .check(tester.binding.rootElement!, runAsync: tester.runAsync);
          faults.addAll(
            report.problems.map((p) => '$name ${brightness.name}: $p'),
          );
        }
      }
      semantics.dispose();
      expect(faults, isEmpty, reason: faults.join('\n'));
    });
  }
}
