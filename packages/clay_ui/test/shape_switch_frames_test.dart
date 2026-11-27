// An app's change of shapes moves across with the host's theme, as day to
// night does: its corners and its relief pass through the steps between,
// never outside Clay's bands, and arrive; under Reduce Motion at once.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _round = RawShapeScheme(
  corners: RawCornerScale(
    style: RawCornerStyle.continuous,
    extraSmall: 8,
    small: 12,
    medium: 20,
    large: 30,
    extraLarge: 40,
  ),
  depth: 1.5,
);

void main() {
  for (final reduce in [false, true]) {
    testWidgets(
      'Clay to its roundest, deepest ends ${reduce ? 'at once under Reduce Motion' : 'through every frame'}',
      (tester) async {
        Widget host(RawShapeScheme scheme) => MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ClayHost(
              theme: ClayThemeData.clay(Brightness.light)
                  .copyWith(shapeScheme: scheme),
              brightness: Brightness.light,
              child: Center(
                child: ClaySurface(
                  face: ClayFace.raised(const ClayColors.light())
                      .copyWith(press: 1),
                  child: Builder(
                    builder: (context) => ClayWell(
                      key: const Key('well'),
                      child: SizedBox(
                        width: 160,
                        height: 48,
                        child: Text(
                          '${ClayTheme.of(context).shapeScheme.depth}',
                          key: const Key('depth'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        double radius() => tester
            .widget<ClaySurface>(
              find.descendant(
                of: find.byKey(const Key('well')),
                matching: find.byType(ClaySurface),
              ),
            )
            .face
            .radius;
        double depth() => double.parse(
          tester.widget<Text>(find.byKey(const Key('depth'))).data!,
        );

        await tester.pumpWidget(host(ClayThemeData.defaultShapeScheme));
        expect(radius(), 16);
        expect(depth(), 1);
        await tester.pumpWidget(host(_round));
        final seen = <(double, double)>[];
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 20));
          expect(tester.takeException(), isNull);
          seen.add((radius(), depth()));
        }
        for (final (r, d) in seen) {
          expect(r, inInclusiveRange(16, 20));
          expect(d, inInclusiveRange(1, 1.5));
        }
        if (reduce) {
          expect(seen.first, (20.0, 1.5));
        } else {
          final between = seen.where((s) => s.$1 > 16 && s.$1 < 20).length;
          expect(between, greaterThan(3));
          expect(seen.first.$1, lessThan(20));
        }
        await tester.pumpAndSettle();
        expect(radius(), 20);
        expect(depth(), 1.5);
        final face = tester.getRect(find.byKey(const Key('well')));
        final rest = tester.getRect(find.byType(ClaySurface).first);
        expect(face.top - rest.top, closeTo(2.25, 1e-9));
      },
    );
  }
}
