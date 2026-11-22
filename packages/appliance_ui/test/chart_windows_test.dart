// A chart's window holds what it says while it has nothing to show at any
// text size, on a phone's short chart; and a week of nothing is drawn as
// bars of no height over a scale from nought.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

const _week = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

Future<void> _show(
  WidgetTester tester,
  Widget chart, {
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: ApplianceHost(brightness: Brightness.light, child: app!),
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: 358, child: chart),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(applianceLoadFonts);

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('an empty phone chart holds its words at ${scale}x', (
      tester,
    ) async {
      await _show(
        tester,
        const ApplianceBarChart(
          semanticLabel: 'Hours logged',
          height: 134,
          labels: _week,
          series: [],
          emptyLabel: 'No time logged this week',
        ),
        scale: scale,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('No time logged this week'), findsOneWidget);
    });
  }

  testWidgets('a week of nothing draws no bar over a scale from nought', (
    tester,
  ) async {
    await _show(
      tester,
      const ApplianceBarChart(
        semanticLabel: 'Hours logged',
        height: 200,
        labels: _week,
        series: [
          ApplianceChartSeries('Hours logged', [0, 0, 0, 0, 0, 0, 0]),
        ],
      ),
    );
    final paint = tester
        .renderObjectList<RenderCustomPaint>(
          find.descendant(
            of: find.byType(ApplianceBarChart),
            matching: find.byType(CustomPaint),
          ),
        )
        .firstWhere((r) => '${r.painter.runtimeType}' == '_SeriesPainter');
    final canvas = TestRecordingCanvas();
    paint.painter!.paint(canvas, paint.size);
    final bars = [
      for (final call in canvas.invocations)
        if (call.invocation.memberName == #drawRRect)
          (call.invocation.positionalArguments.first as RRect).outerRect,
    ];
    expect(bars, hasLength(_week.length));
    for (final bar in bars) {
      expect(bar.height, lessThan(1));
    }
  });
}
