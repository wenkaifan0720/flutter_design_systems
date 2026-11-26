// ui_core_test's contrast check over the gallery's pages in each of Brutal's
// six palettes, by day and by night, in the look's own fonts.
// ignore_for_file: avoid_relative_lib_imports
@Tags(['goldens'])
library;

import 'dart:convert';

import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart'
    show DefaultMaterialLocalizations, MaterialApp;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import '../example/lib/kit_gallery/demos/blocks.dart';
import '../example/lib/kit_gallery/demos/buttons.dart';
import '../example/lib/kit_gallery/demos/charts.dart';
import '../example/lib/kit_gallery/demos/choices.dart';
import '../example/lib/kit_gallery/demos/feedback.dart';
import '../example/lib/kit_gallery/demos/fields.dart';
import '../example/lib/kit_gallery/demos/foundations.dart';
import '../example/lib/kit_gallery/demos/lists.dart';
import '../example/lib/kit_gallery/kit.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : brutalRegisteredFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);

  group("DesignContrastCheck over the gallery's pages in each palette", () {
    final pages = <String, Widget Function(Brightness)>{
      'foundations': kitFoundationsDemo,
      'buttons': kitButtonsDemo,
      'choices': kitChoicesDemo,
      'fields': kitFieldsDemo,
      'feedback': kitFeedbackDemo,
      'blocks': kitBlocksDemo,
      'lists': kitListsDemo,
      'charts': kitChartsDemo,
    };
    for (final id in BrutalThemeData.presets) {
      testWidgets('$id: no faults by day or by night', (tester) async {
        final semantics = tester.ensureSemantics();
        tester.view
          ..physicalSize = const Size(390, 2400)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final faults = <String>[];
        for (final brightness in Brightness.values) {
          for (final MapEntry(key: name, value: page) in pages.entries) {
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                localizationsDelegates: const [
                  RawWidgetsLocalizations.delegate,
                  DefaultMaterialLocalizations.delegate,
                  DefaultWidgetsLocalizations.delegate,
                ],
                builder: (context, child) => BrutalTheme(
                  data: BrutalThemeData.preset(id, brightness),
                  child: BrutalToaster(child: KitGalleryScope(child: child!)),
                ),
                home: page(brightness),
              ),
            );
            await tester.pump(const Duration(seconds: 1));
            final report = await const DesignContrastCheck(look: 'Brutal')
                .check(
                  tester.element(find.byType(BrutalScaffold).first),
                  runAsync: tester.runAsync,
                );
            faults.addAll(report.problems.map((p) => '$name $brightness: $p'));
          }
        }
        semantics.dispose();
        expect(faults, isEmpty, reason: faults.join('\n'));
      });
    }
  });
}
