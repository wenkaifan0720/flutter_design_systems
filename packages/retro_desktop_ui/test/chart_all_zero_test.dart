// A chart whose every value is zero (an empty week) stands on a scale from 0 up, as Material's charts and the other
// looks' do: no gridline below zero under data that has none.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

void main() {
  for (final type in RetroDesktopChartType.values) {
    testWidgets('an all-zero ${type.name} chart names no value below zero', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final named = <double>{};
      await tester.pumpWidget(
        retroDesktopApp(
          Center(
            child: SizedBox(
              width: 560,
              child: RetroDesktopChart(
                label: 'Hours',
                kind: type,
                series: const [
                  RetroDesktopChartSeries('Hours', [0, 0, 0, 0, 0, 0, 0]),
                ],
                labels: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
                format: (v) {
                  named.add(v);
                  return '$v h';
                },
              ),
            ),
          ),
          width: 1440,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(named.where((v) => v < 0), isEmpty, reason: '$named');
    });
  }
}
