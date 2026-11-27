// An app's change of corners moves across with the host's theme, as day to
// night does: a part's corner passes through the steps between, never
// outside Studio's bands, and arrives; under Reduce Motion at once.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

const _roundest = RawShapeScheme(
  corners: RawCornerScale(
    extraSmall: 5,
    small: 8,
    medium: 10,
    large: 14,
    extraLarge: 18,
  ),
);

void main() {
  for (final reduce in [false, true]) {
    testWidgets(
      "Studio to its roundest ${reduce ? 'at once under Reduce Motion' : 'through every frame'}",
      (tester) async {
        Widget host(RawShapeScheme scheme) => MaterialApp(
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
            child: StudioHost(
              theme: StudioThemeData.light().copyWith(shapeScheme: scheme),
              brightness: Brightness.light,
              child: app!,
            ),
          ),
          home: const Center(
            child: SizedBox(
              width: 200,
              child: StudioPanel(child: SizedBox(height: 60)),
            ),
          ),
        );
        double radius() => tester
            .widget<StudioSurface>(
              find.descendant(
                of: find.byType(StudioPanel),
                matching: find.byType(StudioSurface),
              ),
            )
            .face
            .radius;

        await tester.pumpWidget(host(StudioThemeData.defaultShapeScheme));
        await tester.pumpAndSettle();
        expect(radius(), 12);
        await tester.pumpWidget(host(_roundest));
        final seen = <double>[];
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 20));
          expect(tester.takeException(), isNull);
          seen.add(radius());
        }
        for (final r in seen) {
          expect(r, inInclusiveRange(12, 18));
        }
        if (reduce) {
          expect(seen.first, 18);
        } else {
          // No frame jumps: each step is a small part of the way.
          var last = 12.0;
          for (final r in seen) {
            expect(r - last, lessThan(2));
            last = r;
          }
          expect(seen.where((r) => r > 12 && r < 18).length, greaterThan(3));
        }
        await tester.pumpAndSettle();
        expect(radius(), 18);
      },
    );
  }
}
