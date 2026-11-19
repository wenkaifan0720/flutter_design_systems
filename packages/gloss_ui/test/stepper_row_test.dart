// A stepper's beads stand as tall as its readout: one row, one height (the
// user, more than once; ui_core_test 0.1.2's DesignFieldPartsCheck holds it
// within 1 px). At 1x, 2x and 3x text, both directions, on and off; the
// readout grows with its words and the beads with it, and the words stay
// whole in the window (its words and its count at 1x and 2x, its count at
// 3x on a phone).
import 'dart:convert';

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

// Gloss's own faces.
Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : glossRegisteredFamily(family),
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

  for (final scale in [1.0, 2.0, 3.0]) {
    final shown = scale < 3 ? '4 servings' : '4';
    for (final direction in TextDirection.values) {
      for (final enabled in [true, false]) {
        testWidgets('a${enabled ? 'n' : ' disabled'} stepper\'s beads are as '
            'tall as its readout at ${scale}x, ${direction.name}', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 2;
          tester.view.physicalSize = const Size(390 * 2, 600 * 2);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, app) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: Directionality(
                  textDirection: direction,
                  child: GlossHost(brightness: Brightness.light, child: app!),
                ),
              ),
              home: Align(
                alignment: Alignment.topCenter,
                child: GlossStepper(
                  value: 4,
                  min: 1,
                  max: 12,
                  semanticLabel: 'Servings',
                  format: scale < 3 ? (v) => '$v servings' : null,
                  onChanged: enabled ? (_) {} : null,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final faces = [
            for (final e
                in find
                    .descendant(
                      of: find.byType(GlossStepper),
                      matching: find.byType(AnimatedGlossSurface),
                    )
                    .evaluate())
              tester.getRect(find.byElementPredicate((x) => x == e)),
          ];
          // Minus, the readout, plus.
          expect(faces, hasLength(3));
          final readout = faces[1];
          expect(
            readout.height,
            greaterThanOrEqualTo(
              GlossTheme.of(tester.element(find.byType(GlossStepper)))
                  .controlHeight,
            ),
          );
          for (final bead in [faces[0], faces[2]]) {
            expect(
              bead.height,
              moreOrLessEquals(readout.height, epsilon: 0.5),
              reason: 'a bead $bead beside a readout $readout',
            );
            expect(bead.center.dy, moreOrLessEquals(readout.center.dy));
          }
          final words = find.text(shown);
          final paragraph = tester.renderObject<RenderParagraph>(words);
          expect(paragraph.didExceedMaxLines, isFalse);
          final box = tester.getRect(words);
          expect(
            readout.contains(box.topLeft) && readout.contains(box.bottomRight),
            isTrue,
            reason: 'the words $box leave the readout $readout',
          );
        });
      }
    }
  }
}
