// Flutter's tap-target, label and contrast guidelines on every live page, in every preset, by day and by night; and on
// each of Hearth's screens, by day and by night.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/hearth.dart'
    show hearthScreens, isHearthScreen;
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/live.dart';
import 'gallery_support.dart'
    show inkedContrastFailures, loadBundledFonts, settle;
import 'support.dart' show loadNeumorphicFonts;

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });

  Future<List<String>> guidelines(WidgetTester tester) async {
    final failed = <String>[];
    for (final (name, guideline) in [
      ('Android 48 px targets', androidTapTargetGuideline),
      ('iOS 44 px targets', iOSTapTargetGuideline),
      ('labelled targets', labeledTapTargetGuideline),
    ]) {
      final result = await guideline.evaluate(tester);
      if (!result.passed) failed.add('$name: ${result.reason}');
    }
    // As in the component matrices, also read the original text ink:
    // a one-pixel antialiased glyph is not its foreground colour.
    await textContrastGuideline.evaluate(tester);
    final inked = await inkedContrastFailures(tester);
    if (inked.isNotEmpty) {
      failed.add('text contrast: ${inked.join('; ')}');
    }
    return failed;
  }

  for (final screen in hearthScreens) {
    for (final brightness in Brightness.values) {
      testWidgets('Hearth ${screen.id} guidelines ${brightness.name}', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 3000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            GalleryApp(initialPage: screen.id, initialBrightness: brightness),
          );
          await settle(tester);
          final failed = await guidelines(tester);
          expect(failed, isEmpty, reason: failed.join('\n'));
        } finally {
          semantics.dispose();
        }
      }, tags: ['goldens']);
    }
  }

  for (final page in liveGalleryPages) {
    if (isHearthScreen(page.id)) continue;
    for (final preset in NeumorphicThemeData.presets) {
      for (final brightness in Brightness.values) {
        testWidgets(
          'live ${page.id} guidelines in $preset ${brightness.name}',
          (tester) async {
            tester.view.physicalSize = const Size(390, 3000);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final semantics = tester.ensureSemantics();
            try {
              await tester.pumpWidget(
                MaterialApp(
                  builder: (context, child) => NeumorphicTheme(
                    data: NeumorphicThemeData.preset(preset, brightness),
                    child: child!,
                  ),
                  home: LiveExample(page: page.id),
                ),
              );
              await settle(tester);
              final failed = await guidelines(tester);
              expect(failed, isEmpty, reason: failed.join('\n'));
            } finally {
              semantics.dispose();
            }
          },
          tags: ['goldens'],
        );
      }
    }
  }
}
