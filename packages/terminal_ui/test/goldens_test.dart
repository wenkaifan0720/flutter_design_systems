// Pixels: slipway's ten screens at a phone's width and a desk's, night and
// paper, and every part the inventory carries, in the real faces. The
// goldens are kept beside the catalog and laid at test/goldens/ by the
// package build; a published copy goes without them and compares nothing.
// `flutter test --update-goldens --tags goldens` records them, on macOS.
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

// The example's screens are the ones under test.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/everyday_screens.dart';
import 'faces.dart';

final bool _recorded =
    autoUpdateGoldenFiles || Directory('test/goldens').existsSync();

void main() {
  setUpAll(loadFaces);

  for (final screen in everydayScreens) {
    for (final width in const [390.0, 1440.0]) {
      for (final b in Brightness.values) {
        testWidgets(
          '${screen.id} at ${width.toInt()}, ${b.name}, matches its golden',
          (tester) async {
            if (!_recorded) return;
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
            addTearDown(tester.view.reset);
            final key = GlobalKey();
            await tester.pumpWidget(
              RepaintBoundary(
                key: key,
                child: screen.app(b, TextDirection.ltr),
              ),
            );
            await tester.pump(const Duration(milliseconds: 500));
            await expectLater(
              find.byKey(key),
              matchesGoldenFile(
                'goldens/screens/${screen.id}_${width.toInt()}_${b.name}.png',
              ),
            );
            await tester.pumpWidget(const SizedBox.shrink());
          },
          tags: const ['goldens'],
        );
      }
    }
  }

  for (final entry in termInventory.entries) {
    final build = entry.builder;
    if (build == null) continue;
    testWidgets('${entry.row} matches its golden', (tester) async {
      if (!_recorded) return;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(720, 900);
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(720, 900),
              disableAnimations: true,
            ),
            child: TermTheme(
              data: TermThemeData.dark(),
              child: TermToaster(
                child: ColoredBox(
                  color: TermThemeData.dark().background,
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: RepaintBoundary(
                      key: key,
                      child: ColoredBox(
                        color: TermThemeData.dark().background,
                        child: Padding(
                          padding: const EdgeInsets.all(9),
                          child: Builder(builder: build),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/parts/${entry.row}.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }, tags: const ['goldens']);
  }
}
