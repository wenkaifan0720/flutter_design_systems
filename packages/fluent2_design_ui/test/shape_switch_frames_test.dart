// An app's change of corners moves across with the host's theme, as day to
// night does: a control's corner passes through the steps between, never
// outside Fluent's bands, and arrives; under Reduce Motion at once.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

const _roundest = RawShapeScheme(
  corners: RawCornerScale(
    extraSmall: 4,
    small: 8,
    medium: 10,
    large: 12,
    extraLarge: 16,
  ),
);

void main() {
  for (final reduce in [false, true]) {
    testWidgets(
      "Fluent 2 to its roundest ${reduce ? 'at once under Reduce Motion' : 'through every frame'}",
      (tester) async {
        Widget host(RawShapeScheme scheme) => MaterialApp(
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
            child: Fluent2Host(
              light: Fluent2ThemeData.lapis().copyWith(shapeScheme: scheme),
              brightness: Brightness.light,
              child: app!,
            ),
          ),
          home: const Center(
            child: SizedBox(width: 80, height: 40, child: Fluent2FocusRing()),
          ),
        );
        double radius() =>
            (tester
                        .widget<DecoratedBox>(
                          find
                              .descendant(
                                of: find.byType(Fluent2FocusRing),
                                matching: find.byType(DecoratedBox),
                              )
                              .first,
                        )
                        .decoration
                    as BoxDecoration)
                .borderRadius!
                .resolve(TextDirection.ltr)
                .topLeft
                .x;

        await tester.pumpWidget(host(Fluent2ThemeData.defaultShapeScheme));
        await tester.pumpAndSettle();
        expect(radius(), 4);
        await tester.pumpWidget(host(_roundest));
        final seen = <double>[];
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 20));
          expect(tester.takeException(), isNull);
          seen.add(radius());
        }
        for (final r in seen) {
          expect(r, inInclusiveRange(4, 8));
        }
        if (reduce) {
          expect(seen.first, 8);
        } else {
          // No frame jumps: each step is a small part of the way.
          var last = 4.0;
          for (final r in seen) {
            expect(r - last, lessThan(1.5));
            last = r;
          }
          expect(seen.where((r) => r > 4 && r < 8).length, greaterThan(3));
        }
        await tester.pumpAndSettle();
        expect(radius(), 8);
      },
    );
  }
}
