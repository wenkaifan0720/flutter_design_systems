// An app's change of corners moves across with the host's theme, as day to
// night does: a part's corner passes through the steps between, never
// outside Appliance's bands, and arrives; under Reduce Motion as a short
// change with no swing past its end (ui_core's effects policy: critically
// damped, settled within 150 ms).
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _roundest = RawShapeScheme(
  corners: RawCornerScale(
    extraSmall: 8,
    small: 14,
    medium: 16,
    large: 20,
    extraLarge: 24,
  ),
);

void main() {
  for (final reduce in [false, true]) {
    testWidgets(
      "Appliance to its roundest ${reduce ? 'within 150 ms under Reduce Motion' : 'through every frame'}",
      (tester) async {
        Widget host(RawShapeScheme scheme) => MaterialApp(
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
            child: ApplianceHost(
              light: ApplianceThemeData.light().copyWith(shapeScheme: scheme),
              brightness: Brightness.light,
              child: app!,
            ),
          ),
          home: const Center(
            child: SizedBox(
              width: 200,
              child: AppliancePanel(child: SizedBox(height: 60)),
            ),
          ),
        );
        double radius() => tester
            .widget<ApplianceSurface>(
              find.descendant(
                of: find.byType(AppliancePanel),
                matching: find.byType(ApplianceSurface),
              ),
            )
            .face
            .radius
            .topLeft
            .x;

        await tester.pumpWidget(host(ApplianceThemeData.defaultShapeScheme));
        await tester.pumpAndSettle();
        expect(radius(), 14);
        await tester.pumpWidget(host(_roundest));
        final seen = <double>[];
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 20));
          expect(tester.takeException(), isNull);
          seen.add(radius());
        }
        for (final r in seen) {
          expect(r, inInclusiveRange(14, 20));
        }
        if (reduce) {
          // Never back, never past its end, and there by the eighth frame.
          var last = 14.0;
          for (final r in seen) {
            expect(r, greaterThanOrEqualTo(last));
            last = r;
          }
          expect(seen[7], closeTo(20, 0.05));
        } else {
          // No frame jumps: each step is a small part of the way.
          var last = 14.0;
          for (final r in seen) {
            expect(r - last, lessThan(2));
            last = r;
          }
          expect(seen.where((r) => r > 14 && r < 20).length, greaterThan(3));
        }
        await tester.pumpAndSettle();
        expect(radius(), 20);
      },
    );
  }
}
