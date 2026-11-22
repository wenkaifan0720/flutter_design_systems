// A chart on a right-to-left page is its left-to-right one mirrored: the
// figures' side of the tray keeps its inset and the far side its own, so the
// grid stops as far from the far wall either way.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

import '../example/lib/kit_gallery/kit.dart';

// The plot's insets in its tray, from the start side and the end side.
Future<(double, double)> _insets(
  WidgetTester tester,
  TextDirection direction,
) async {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    kitApp(
      brightness: Brightness.light,
      home: Directionality(
        textDirection: direction,
        child: const Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 400,
            child: GlossBarChart(
              labels: ['Mon', 'Tue', 'Wed'],
              series: [
                GlossSeries('Hours', [2, 6, 3]),
              ],
              semanticLabel: 'Hours a day',
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final chart = find.byType(GlossBarChart);
  final plot = tester
      .renderObjectList<RenderCustomPaint>(
        find.descendant(of: chart, matching: find.byType(CustomPaint)),
      )
      .firstWhere((r) => '${r.painter.runtimeType}' == '_BarPainter');
  final paint = plot.localToGlobal(Offset.zero) & plot.size;
  final tray = tester.getRect(
    find.descendant(of: chart, matching: find.byType(GlossSurface)).first,
  );
  final (left, right) = (paint.left - tray.left, tray.right - paint.right);
  return direction == TextDirection.ltr ? (left, right) : (right, left);
}

void main() {
  setUpAll(glossLoadFonts);

  testWidgets('a right-to-left chart mirrors its left-to-right one', (
    tester,
  ) async {
    final ltr = await _insets(tester, TextDirection.ltr);
    await tester.pumpWidget(const SizedBox());
    final rtl = await _insets(tester, TextDirection.rtl);
    expect(rtl.$1, closeTo(ltr.$1, 0.5), reason: "the figures' side");
    expect(rtl.$2, closeTo(ltr.$2, 0.5), reason: 'the far side');
  });
}
