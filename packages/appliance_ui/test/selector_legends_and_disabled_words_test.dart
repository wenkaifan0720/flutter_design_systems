// At twice the text size, by day and by night, in either reading
// direction: a slide selector's legends (Light, Dark, System) stay whole on
// one line each, and a disabled key's words read at 4.5:1 or more on its
// face.
import 'dart:math' as math;

import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(applianceLoadFonts);
  for (final brightness in Brightness.values) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'appearance legends and disabled keys in ${brightness.name} ${direction.name}',
        (t) async {
          t.view.physicalSize = const Size(780, 1688);
          t.view.devicePixelRatio = 2;
          addTearDown(t.view.reset);
          await t.pumpWidget(
            MaterialApp(
              builder: (context, app) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: Directionality(
                  textDirection: direction,
                  child: ApplianceTheme(
                    data: ApplianceThemeData.from(brightness: brightness),
                    child: app!,
                  ),
                ),
              ),
              home: Center(
                child: SizedBox(
                  width: 326,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ApplianceSegmentedButton<int>(
                        segments: const [
                          ApplianceSegment(
                            value: 0,
                            label: 'Light',
                            icon: Icon(Icons.light_mode),
                          ),
                          ApplianceSegment(
                            value: 1,
                            label: 'Dark',
                            icon: Icon(Icons.dark_mode),
                          ),
                          ApplianceSegment(
                            value: 2,
                            label: 'System',
                            icon: Icon(Icons.computer),
                          ),
                        ],
                        value: 0,
                        onChanged: (_) {},
                      ),
                      const ApplianceButton('Discard', onPressed: null),
                      const ApplianceButton.filled('Save', onPressed: null),
                    ],
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          for (final label in ['Light', 'Dark', 'System']) {
            final p = t.renderObject<RenderParagraph>(find.text(label));
            expect(p.didExceedMaxLines, isFalse, reason: label);
            final lines = p.getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: label.length),
            );
            expect(
              lines.map((b) => b.top).toSet(),
              hasLength(1),
              reason: label,
            );
          }
          for (final word in ['Discard', 'Save']) {
            final p = t.renderObject<RenderParagraph>(find.text(word));
            final ink = p.text.style!.color!.computeLuminance();
            final face = t
                .widget<ApplianceSurface>(
                  find
                      .ancestor(
                        of: find.text(word),
                        matching: find.byType(ApplianceSurface),
                      )
                      .first,
                )
                .face;
            for (final bg in [face.top, face.bottom]) {
              final light = bg.computeLuminance();
              expect(
                (math.max(light, ink) + .05) / (math.min(light, ink) + .05),
                greaterThanOrEqualTo(4.5),
              );
            }
          }
        },
      );
    }
  }
}
