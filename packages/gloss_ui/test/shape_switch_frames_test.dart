// An app's change of corners moves across with the host's theme, as day to
// night does: a well's corner passes through the steps between, never outside
// Gloss's bands, and arrives; under Reduce Motion at once.
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart';

const _roundest = RawShapeScheme(
  corners: RawCornerScale(
    extraSmall: 9,
    small: 16,
    medium: 22,
    large: 24,
    extraLarge: 32,
  ),
);

void main() {
  for (final reduce in [false, true]) {
    testWidgets(
      'Gloss to its roundest ends ${reduce ? 'at once under Reduce Motion' : 'through every frame'}',
      (tester) async {
        Widget host(RawShapeScheme scheme) => MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: GlossHost(
              theme: GlossThemeData.jade(Brightness.light)
                  .copyWith(shapeScheme: scheme),
              brightness: Brightness.light,
              child: const Center(
                child: SizedBox(
                  width: 240,
                  child: GlossWell(
                    key: Key('well'),
                    children: [GlossListTile(title: 'Basil')],
                  ),
                ),
              ),
            ),
          ),
        );
        double radius() {
          final w = tester.widget(
            find
                .descendant(
                  of: find.byKey(const Key('well')),
                  matching: find.byWidgetPredicate(
                    (w) => w is GlossSurface || w is AnimatedGlossSurface,
                  ),
                )
                .first,
          );
          return (w is GlossSurface
              ? w.face.radius
              : (w as AnimatedGlossSurface).face.radius)!;
        }

        await tester.pumpWidget(host(GlossThemeData.defaultShapeScheme));
        await tester.pumpAndSettle();
        expect(radius(), 16);
        await tester.pumpWidget(host(_roundest));
        final seen = <double>[];
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 20));
          expect(tester.takeException(), isNull);
          seen.add(radius());
        }
        for (final r in seen) {
          expect(r, inInclusiveRange(16, 22));
        }
        if (reduce) {
          expect(seen.first, 22);
        } else {
          // No frame jumps: each step is a small part of the way.
          var last = 16.0;
          for (final r in seen) {
            expect(r - last, lessThan(3));
            last = r;
          }
          expect(seen.where((r) => r > 16 && r < 22).length, greaterThan(3));
        }
        await tester.pumpAndSettle();
        expect(radius(), 22);
      },
    );
  }
}
