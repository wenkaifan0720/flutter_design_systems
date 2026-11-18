import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
  testWidgets('navigation centres its icon and label at ordinary text size', (
    tester,
  ) async {
    await _show(
      tester,
      ApplianceNavigationBar(
        destinations: const [
          ApplianceDestination(label: 'Home', icon: Icons.home),
          ApplianceDestination(label: 'Shop', icon: Icons.store),
        ],
        selectedIndex: 0,
        onSelected: (_) {},
      ),
      scale: 1,
    );
    final label = find.text('Home');
    final bounds = tester.getRect(
      find
          .ancestor(
            of: label,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is ConstrainedBox &&
                  w.constraints.minHeight == ApplianceNavigationBar.keyHeight,
            ),
          )
          .first,
    );
    final top = tester.getTopLeft(find.byIcon(Icons.home)).dy;
    final bottom = tester.getBottomLeft(label).dy;
    expect((top + bottom) / 2, closeTo(bounds.center.dy, 0.5));
  });
  testWidgets('a tracking timestamp and title share a baseline when they fit', (
    tester,
  ) async {
    await _show(
      tester,
      const ApplianceTimeline(
        entries: [ApplianceTimelineEntry(title: 'Packed', time: 'Sat 16:05')],
      ),
      scale: 1,
    );
    double baseline(String text) {
      final item = find.text(text);
      final paragraph = tester.renderObject<RenderParagraph>(item);
      return tester.getTopLeft(item).dy +
          paragraph.getDryBaseline(
            paragraph.constraints,
            TextBaseline.alphabetic,
          )!;
    }

    expect(baseline('Sat 16:05'), closeTo(baseline('Packed'), 0.1));
  });
  testWidgets('the reorder grip moves the focused row with Alt and Down', (
    tester,
  ) async {
    final items = ['Park', 'Market'];
    await _show(
      tester,
      StatefulBuilder(
        builder: (context, update) => ApplianceReorderableList<String>(
          items: List.of(items),
          labelOf: (item) => item,
          title: (item) => item,
          shrinkWrap: true,
          onReorder: (from, to) =>
              update(() => items.insert(to, items.removeAt(from))),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(items, ['Market', 'Park']);
  });
  testWidgets('price thumbs format their values in the selected currency', (
    tester,
  ) async {
    await _show(
      tester,
      ApplianceRangeSlider(
        values: const DesignRangeValues(25, 60),
        max: 100,
        startLabel: 'Minimum price',
        onChanged: (_) {},
        semanticFormatterCallback: (v) => '\$${v.round()}',
      ),
    );
    final slider = tester.widget<DesignRangeSlider>(
      find.byType(DesignRangeSlider),
    );
    expect(slider.semanticFormatterCallback!(25), r'$25');
    expect(
      tester.getSemantics(find.bySemanticsLabel('Minimum price')).value,
      r'$25',
    );
  });
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
    await _show(tester, chart, scale: 1);
    final normal = tester
        .widget<DesignChart>(find.byType(DesignChart))
        .padding
        .resolve(TextDirection.ltr);
    await _show(tester, chart);
    final large = tester
        .widget<DesignChart>(find.byType(DesignChart))
        .padding
        .resolve(TextDirection.ltr);
    expect(large.left, greaterThan(normal.left));
    expect(large.bottom, greaterThan(normal.bottom));
  });
  for (final range in [false, true]) {
    testWidgets(
      'the last week scrolls into view in the ${range ? 'range' : 'date'} picker',
      (tester) async {
        final start = DateTime(2026, 11),
            end = DateTime(2026, 12, 31),
            current = DateTime(2026, 11, 12);
        DateTime? selected;
        final picker = range
            ? ApplianceDateRangePicker(
                label: 'Dates',
                value: null,
                firstDate: start,
                lastDate: end,
                currentDate: current,
                onChanged: (v) => selected = v.end,
              )
            : ApplianceDatePicker(
                label: 'Dates',
                value: current,
                firstDate: start,
                lastDate: end,
                currentDate: current,
                onChanged: (v) => selected = v,
              );
        await _show(tester, SizedBox(width: 350, child: picker));
        await tester.tap(
          find
              .descendant(
                of: find.byWidget(picker),
                matching: find.byType(DesignPressable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        if (range) {
          await tester.tap(find.text('12').first);
          await tester.pumpAndSettle();
        }
        final plate = find.byType(ApplianceMenuPlate);
        final last = find
            .descendant(of: plate, matching: find.text('30'))
            .first;
        final scroll = find
            .descendant(of: plate, matching: find.byType(Scrollable))
            .first;
        final position = tester.state<ScrollableState>(scroll).position;
        expect(position.maxScrollExtent, greaterThan(0));
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: tester.getCenter(plate),
            scrollDelta: const Offset(0, 650),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(plate).contains(tester.getCenter(last)), isTrue);
        await tester.tap(last);
        await tester.pumpAndSettle();
        expect(selected, DateTime(2026, 11, 30));
      },
    );
  }
}
