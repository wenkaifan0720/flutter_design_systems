// ignore_for_file: avoid_relative_lib_imports — the example app's pages are what this test checks; example/ is not a dependency of the package.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../example/lib/kit_gallery/demos/ordinary.dart';

import 'support.dart';

void main() {
  setUpAll(loadRetroDesktopFonts);
  const widths = [390.0, 768.0, 1024.0, 1440.0];
  for (final (i, screen) in kitOrdinaryScreens.indexed) {
    for (final width in widths) {
      for (final dark in [false, true]) {
        for (final direction in TextDirection.values) {
          // Every day one case a screen, the screens turning round the widths, modes and directions (seven screens:
          // every width, both modes and both directions); the rest in the sweep.
          final everyday =
              width == widths[i % widths.length] &&
              dark == i.isOdd &&
              (direction == TextDirection.rtl) == (i ~/ 2).isOdd;
          testWidgets(
            '$screen at $width, dark=$dark, $direction, text2',
            tags: sweepUnless(everyday),
            (tester) async {
              tester.view.physicalSize = Size(width, 1400);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              await tester.pumpWidget(
                retroDesktopApp(
                  RetroDesktopScaffold(
                    appBar: const RetroDesktopAppBar(
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
            },
          );
        }
      }
    }
  }
}
