// The KPI strip's straight foot.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/chart_host.dart';

final MinimalThemeData _light = MinimalThemeData.preset(
  'standard',
  Brightness.light,
);

void main() {
  group('the KPI strip', () {
    testWidgets('a selected cell stands on one straight bar, clear of the '
        "strip's round corners", (tester) async {
      final corner = MinimalShapes.radiusOf(
        MinimalShapes.inset(_light.shapes.medium, _light.hairline),
      );
      for (final direction in TextDirection.values) {
        for (final picked in [0, 1, 2]) {
          await tester.pumpWidget(
            chartHost(
              SizedBox(
                width: 600,
                child: MinimalStatRow.joined(
                  children: [
                    for (var i = 0; i < 3; i++)
                      MinimalStat(
                        label: 'Cell $i',
                        value: '$i',
                        selected: i == picked,
                      ),
                  ],
                ),
              ),
              direction: direction,
            ),
          );
          await tester.pumpAndSettle();
          final cell = find.byType(MinimalStat).at(picked);
          final size = tester.getSize(cell);
          Rect? bar;
          // A paint keeps 8-bit channels; the theme's colours are floats.
          expect(
            cell,
            paints..something((method, args) {
              if (method != #drawRect) return false;
              final paint = args[1] as Paint;
              if (paint.color.toARGB32() != _light.foreground.toARGB32()) {
                return false;
              }
              bar = args[0] as Rect;
              return true;
            }),
          );
          final foot = bar!;
          final why = '${direction.name}, cell $picked';
          expect(
            foot.height,
            closeTo(MinimalStat.footWidth, 0.01),
            reason: why,
          );
          expect(foot.bottom, closeTo(size.height, 0.01), reason: why);
          final ltr = direction == TextDirection.ltr;
          final start = ltr ? foot.left : size.width - foot.right;
          final end = ltr ? size.width - foot.right : foot.left;
          // In the strip's bottom-start corner (the first cell) and its
          // bottom-end one (the last), the bar stands in by the corner's
          // radius; a middle cell's runs edge to edge.
          expect(start, closeTo(picked == 0 ? corner : 0, 0.01), reason: why);
          expect(end, closeTo(picked == 2 ? corner : 0, 0.01), reason: why);
        }
      }
    });
  });
}
