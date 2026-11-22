// A chart names every gridline at a round value, the names falling evenly down the axis, in both appearances by
// day and by night.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'still_pixels.dart';
import 'support.dart';

const appearances = <String, RetroDesktopAppearance>{
  'chisel': RetroDesktopAppearance.chisel,
  'platinum': RetroDesktopAppearance.platinum,
};

void main() {
  setUpAll(loadRetroDesktopFonts);

  for (final f in appearances.entries) {
    for (final b in Brightness.values) {
      final name = '${f.key} ${b.name}';

      testWidgets('$name: a chart names every gridline at a round value', (
        tester,
      ) async {
        for (final (kind, values, names) in [
          // ui_core's nice scale: steps of 1, 2 or 5 times a power of ten that
          // hold the data, so 12 tops out at 12 by twos.
          (
            RetroDesktopChartType.bar,
            <double>[3, 12, 7, 9],
            ['0', '2', '4', '6', '8', '10', '12'],
          ),
          (
            RetroDesktopChartType.line,
            <double>[9, 15, 22, 12],
            ['5', '10', '15', '20', '25'],
          ),
        ]) {
          await stillPixels(
            tester,
            f.value,
            b,
            SizedBox(
              width: 500,
              child: RetroDesktopChart(
                label: 'Visits',
                kind: kind,
                series: [RetroDesktopChartSeries('Visits', values)],
                labels: const ['Mon', 'Tue', 'Wed', 'Thu'],
              ),
            ),
          );
          final ys = [for (final n in names) tester.getCenter(find.text(n)).dy];
          // Read top to bottom, the values fall, and stand evenly apart.
          for (var i = 1; i < ys.length; i++) {
            expect(ys[i], lessThan(ys[i - 1]), reason: '$kind $names');
          }
          final gaps = [
            for (var i = 2; i < ys.length - 1; i++) ys[i - 1] - ys[i],
          ];
          for (final g in gaps) {
            expect(g, closeTo(gaps.first, 1.5), reason: '$kind $ys');
          }
        }
      }, tags: const ['goldens']);
    }
  }
}
