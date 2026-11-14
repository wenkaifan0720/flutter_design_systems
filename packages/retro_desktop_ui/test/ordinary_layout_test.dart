// The package emitter carries the actual example content into example/lib.
// ignore_for_file: avoid_relative_lib_imports
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../example/lib/kit_gallery/demos/ordinary.dart';

import 'support.dart';

void main() {
  setUpAll(loadRetroDesktopFonts);
  for (final screen in kitOrdinaryScreens) {
    for (final width in [390.0, 768.0, 1024.0, 1440.0]) {
      for (final dark in [false, true]) {
        for (final direction in TextDirection.values) {
          testWidgets('$screen at $width, dark=$dark, $direction, text2', (
            tester,
          ) async {
            tester.view.physicalSize = Size(width, 1400);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              retroDesktopApp(
                RetroDesktopScaffold(
                  topBar: const RetroDesktopAppBar(
                    title: 'Everyday application',
                  ),
                  body: RetroDesktopSections(
                    children: [kitOrdinaryContent(screen)],
                  ),
                ),
                dark: dark,
                direction: direction,
                scale: 2,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }
}
