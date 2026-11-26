import 'dart:convert';
import 'dart:io';

import 'package:design_system_examples/generated/studies.dart' as studies;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_core/stint_core.dart';

/// Every edition's four places open in Japanese and German, the languages
/// the Stint page's quick controls add, at phone and desktop width, with
/// nothing overflowing and no error. English and Arabic are each edition's
/// own suite.
void main() {
  final looks = (jsonDecode(File('../looks.json').readAsStringSync()) as Map)
      .keys
      .cast<String>();
  for (final look in looks) {
    for (final language in [StintLanguage.ja, StintLanguage.de]) {
      for (final size in [const Size(390, 844), const Size(1440, 960)]) {
        testWidgets('$look in ${language.name} at ${size.width.round()}', (
          tester,
        ) async {
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          for (final place in Place.values) {
            // Opening loads the look's fonts, real I/O the test's fake
            // clock would never finish.
            final app = await tester.runAsync(
              () => studies.openStudy(
                look,
                StintLaunch(place: place, language: language),
              ),
            );
            if (app == null) return;
            await tester.pumpWidget(app);
            for (var i = 0; i < 4; i++) {
              await tester.pump(const Duration(milliseconds: 400));
            }
            expect(
              tester.takeException(),
              isNull,
              reason: '$look, ${place.name}',
            );
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump(const Duration(seconds: 1));
          }
        });
      }
    }
  }
}
