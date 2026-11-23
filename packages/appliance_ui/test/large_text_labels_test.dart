// At twice the text size, words stay whole and the parts holding them make
// room: a dialog's actions keep their complete labels, a narrow timeline
// puts a long time on its own line, the empty state's readout encloses its
// digits, the navigation's and a delivery's stages show whole words in
// either reading direction, and a chart's labels get room beside and
// beneath the plot.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  double scale = 2,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 620);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, navigator) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: direction,
          child: ApplianceTheme(
            data: ApplianceThemeData.light(),
            child: navigator!,
          ),
        ),
      ),
      home: Center(child: child),
    ),
  );
  await tester.pumpAndSettle();
}

void _wholeLine(WidgetTester tester, String label) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
  expect(paragraph.didExceedMaxLines, isFalse, reason: label);
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: label.length),
  );
  expect(boxes.map((box) => box.top).toSet(), hasLength(1), reason: label);
}

void main() {
  setUpAll(applianceLoadFonts);
  testWidgets('confirmation actions keep their complete labels', (
    tester,
  ) async {
    await _show(
      tester,
      SizedBox(
        width: 342,
        child: ApplianceDialog(
          title: 'Remove this item?',
          actions: [
            ApplianceButton('Keep it', onPressed: () {}),
            ApplianceButton.filled(
              'Remove',
              onPressed: () {},
              isDestructiveAction: true,
            ),
          ],
        ),
      ),
    );
    _wholeLine(tester, 'Keep it');
    _wholeLine(tester, 'Remove');
    expect(tester.takeException(), isNull);
  });
  testWidgets('a narrow timeline puts a long time on its own line', (
    tester,
  ) async {
    await _show(
      tester,
      const SizedBox(
        width: 310,
        child: ApplianceTimeline(
          entries: [
            ApplianceTimelineEntry(
              title: 'Ordered',
              time: 'Sat, 21 Nov at 10 am',
            ),
          ],
        ),
      ),
    );
    _wholeLine(tester, 'Ordered');
    expect(
      tester.getTopLeft(find.text('Sat, 21 Nov at 10 am')).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.text('Ordered')).dy),
    );
  });
  testWidgets('the empty-state readout encloses its scaled digits', (
    tester,
  ) async {
    await _show(
      tester,
      const ApplianceEmptyState(
        title: 'No results',
        message: 'Try another search.',
        reading: '0',
      ),
    );
    final digit = find.text('0');
    final glass = find
        .ancestor(of: digit, matching: find.byType(ApplianceSurface))
        .first;
    expect(
      tester.getRect(glass).bottom,
      greaterThan(tester.getRect(digit).bottom),
    );
    expect(
      find.ancestor(
        of: find.text('Try another search.'),
        matching: find.byType(AppliancePanel),
      ),
      findsOneWidget,
    );
  });
  for (final direction in TextDirection.values) {
    testWidgets(
      'navigation and delivery stages show whole words in ${direction.name}',
      (tester) async {
        const places = ['Home', 'Search', 'Basket', 'Orders', 'Settings'];
        final destinations = [
          for (final s in places)
            ApplianceDestination(label: s, icon: Icons.home),
        ];
        await _show(
          tester,
          ApplianceNavigationBar(
            destinations: destinations,
            selectedIndex: 2,
            onSelected: (_) {},
          ),
          direction: direction,
        );
        for (final s in places) {
          _wholeLine(tester, s);
        }
        await _show(
          tester,
          ApplianceNavigationRail(
            destinations: destinations.take(2).toList(),
            selectedIndex: 0,
            onSelected: (_) {},
          ),
          direction: direction,
        );
        _wholeLine(tester, 'Search');
        const steps = ['Ordered', 'Packed', 'Shipped', 'Delivered'];
        await _show(
          tester,
          const SizedBox(
            width: 310,
            child: ApplianceStepProgress(steps: steps, current: 1),
          ),
          direction: direction,
        );
        for (final s in steps) {
          _wholeLine(tester, s);
        }
      },
    );
  }
  testWidgets('larger chart labels get room beside and beneath the plot', (
    tester,
  ) async {
    const chart = ApplianceLineChart(
      semanticLabel: 'Orders',
      labels: ['Mon', 'Tue'],
      series: [
        ApplianceChartSeries('Orders', [5, 20]),
      ],
    );
    // The room beside the plot for a scale figure, and the band under it.
    (double, double) room() {
      final c = tester.widget<DesignChart>(find.byType(DesignChart));
      final beside = c.yLabelGutter!(const [
        DesignScaleTick(value: 20, position: 0, label: '20'),
      ]);
      return (beside, c.padding.resolve(TextDirection.ltr).bottom);
    }

    await _show(tester, chart, scale: 1);
    final normal = room();
    await _show(tester, chart);
    final large = room();
    expect(large.$1, greaterThan(normal.$1));
    expect(large.$2, greaterThan(normal.$2));
  });
}
