// By night, a skeleton's and a spinner's track.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/chart_host.dart';

final MinimalThemeData _dark = MinimalThemeData.preset(
  'standard',
  Brightness.dark,
);

void main() {
  group('by night', () {
    testWidgets("a skeleton and a spinner's track take the stronger "
        'hairline, clear of the ground', (tester) async {
      // Still, so the pulse and the turn let the host settle.
      MinimalMotion.animate = false;
      addTearDown(() => MinimalMotion.animate = true);
      await tester.pumpWidget(
        chartHost(
          const SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [MinimalSkeleton(), MinimalCircularProgressIndicator()],
            ),
          ),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();
      final block = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(MinimalSkeleton),
              matching: find.byType(Container),
            )
            .first,
      );
      final fill = switch (block.decoration) {
        BoxDecoration(:final color?) => color,
        ShapeDecoration(:final color?) => color,
        _ => throw StateError('no fill'),
      };
      expect(fill, _dark.borderStrong);
      // At full strength and at the pulse's half (the hairline's grey would
      // be 1.30:1 and 1.12:1 on the dark ground).
      expect(contrastRatio(fill, _dark.background), greaterThan(1.6));
      expect(
        contrastRatio(
          Color.alphaBlend(fill.withValues(alpha: 0.5), _dark.background),
          _dark.background,
        ),
        greaterThan(1.2),
      );
      // The spinner's track is the first ring it draws.
      expect(
        find
            .descendant(
              of: find.byType(MinimalCircularProgressIndicator),
              matching: find.byType(CustomPaint),
            )
            .first,
        paints..something(
          (method, args) =>
              method == #drawArc &&
              (args[4] as Paint).color.toARGB32() ==
                  _dark.borderStrong.toARGB32(),
        ),
      );
    });
  });
}
