// What a reader is told while they wait, and what the figures say: a wait
// is heard in words and stands still under Reduce Motion; a progress bar
// and a meter say how far in words and spring to a new value; a skeleton
// is heard once; a busy button takes no press but keeps its focus and its
// width; a pull, or its button, refreshes and says so; an action bar is
// heard only while rows are picked; a chart is heard by its name and folds
// out its figures as a table.
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {bool still = false, double width = 600}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: still),
        child: CivicHost(child: app ?? const SizedBox.shrink()),
      ),
      home: Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(width: width, child: child),
      ),
    );

Future<void> _frames(WidgetTester tester, [int count = 20]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

SemanticsNode _node(WidgetTester tester, Finder finder) =>
    tester.getSemantics(finder);

void main() {
  group('a spinner', () {
    testWidgets('is heard once, in words, as a wait', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(const CivicSpinner(label: 'Checking your vehicle')),
      );
      await _frames(tester, 2);
      final node = _node(tester, find.byType(CivicSpinner));
      expect(node.label, 'Checking your vehicle');
      expect(node.role, SemanticsRole.loadingSpinner);
      expect(node.flagsCollection.isLiveRegion, isTrue);
      semantics.dispose();
    });

    testWidgets('says "Loading" in the reader\'s language by default', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const CivicSpinner()));
      await _frames(tester, 2);
      expect(find.text('Loading'), findsOneWidget);
    });

    testWidgets('turns, and stands still under Reduce Motion', (tester) async {
      await tester.pumpWidget(_app(const CivicSpinner()));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(_app(const CivicSpinner(), still: true));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('a progress bar', () {
    testWidgets('is heard as a progress bar at its share', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const CivicProgressBar(
            label: 'Uploading proof of address',
            value: 0.4,
            valueLabel: '2 of 5 pages uploaded',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final node = _node(tester, find.byType(CivicProgressBar));
      expect(node.label, 'Uploading proof of address, 2 of 5 pages uploaded');
      expect(node.value, '40');
      expect(node.getSemanticsData().minValue, '0');
      expect(node.getSemanticsData().maxValue, '100');
      expect(node.role, SemanticsRole.progressBar);
      expect(find.text('2 of 5 pages uploaded'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('says its share in words when it has no words of its own', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const CivicProgressBar(label: 'Uploading', value: 0.25)),
      );
      await tester.pumpAndSettle();
      expect(find.text('25%'), findsOneWidget);
    });

    testWidgets('springs to a new value', (tester) async {
      Widget at(double v) => _app(
        RepaintBoundary(
          child: CivicProgressBar(label: 'Uploading', value: v),
        ),
      );
      await tester.pumpWidget(at(0.2));
      await tester.pumpAndSettle();
      await tester.pumpWidget(at(0.8));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.binding.hasScheduledFrame, isTrue, reason: 'it moves');
      await tester.pumpAndSettle();
    });

    testWidgets('without a measure slides, and stands still under Reduce '
        'Motion', (tester) async {
      await tester.pumpWidget(
        _app(const CivicProgressBar(label: 'Checking your documents')),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(
        _app(
          const CivicProgressBar(label: 'Checking your documents'),
          still: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('a meter', () {
    testWidgets('says its amount, and past its mark says so in words', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      Widget at(double v) => _app(
        CivicMeter(
          label: 'Visitor days used this year',
          value: v,
          max: 60,
          high: 50,
          highLabel: 'You have 6 days left',
        ),
      );
      await tester.pumpWidget(at(38));
      await tester.pumpAndSettle();
      expect(find.text('38 of 60'), findsOneWidget);
      expect(find.text('You have 6 days left'), findsNothing);
      expect(_node(tester, find.byType(CivicMeter)).value, '38 of 60');
      await tester.pumpWidget(at(54));
      await tester.pumpAndSettle();
      expect(find.text('You have 6 days left'), findsOneWidget);
      expect(
        _node(tester, find.byType(CivicMeter)).value,
        '54 of 60, You have 6 days left',
      );
      semantics.dispose();
    });
  });

  group('a skeleton', () {
    testWidgets('is heard once as a wait, its blocks not at all', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const CivicSkeleton(
            semanticLabel: 'Loading your applications',
            child: Column(
              children: [
                CivicSkeletonBlock(height: 40),
                CivicSkeletonText(lines: 2),
              ],
            ),
          ),
          still: true,
        ),
      );
      await tester.pumpAndSettle();
      final node = _node(tester, find.byType(CivicSkeleton));
      expect(node.label, 'Loading your applications');
      expect(node.role, SemanticsRole.loadingSpinner);
      expect(node.mergeAllDescendantsIntoThisNode || !node.hasChildren, isTrue);
      semantics.dispose();
    });

    testWidgets('fades, and stands still under Reduce Motion', (tester) async {
      const part = CivicSkeleton(child: CivicSkeletonText());
      await tester.pumpWidget(_app(part));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(_app(part, still: true));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('its text lines are the body\'s, the last one shorter', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const CivicSkeletonText(lines: 3), still: true),
      );
      await tester.pumpAndSettle();
      final blocks = tester
          .widgetList<CivicSkeletonBlock>(find.byType(CivicSkeletonBlock))
          .toList();
      expect(blocks, hasLength(3));
      final widths = [
        for (final b in find.byType(CivicSkeletonBlock).evaluate())
          tester.getSize(find.byWidget(b.widget)).width,
      ];
      expect(widths.last, lessThan(widths.first));
    });
  });

  group('a busy button', () {
    testWidgets('takes no press, keeps its focus and says it is busy', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var presses = 0;
      Widget button({required bool busy}) => _app(
        Center(
          child: CivicButton(
            onPressed: () => presses++,
            focusNode: focus,
            expand: false,
            busy: busy,
            busyLabel: 'Sending',
            child: const Text('Send application'),
          ),
        ),
        still: true,
      );
      await tester.pumpWidget(button(busy: false));
      final rest = tester.getSize(find.byType(CivicButton));
      focus.requestFocus();
      await tester.pumpWidget(button(busy: true));
      await _frames(tester);
      expect(focus.hasFocus, isTrue, reason: 'busy, it keeps its focus');
      await tester.tap(find.byType(CivicButton));
      await _frames(tester);
      expect(presses, 0, reason: 'busy, it takes no press');
      expect(tester.getSize(find.byType(CivicButton)), rest);
      final node = find.semantics.byLabel('Sending').evaluate().single;
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isLiveRegion, isTrue);
      expect(find.semantics.byLabel('Send application'), findsNothing);
      await tester.pumpWidget(button(busy: false));
      await _frames(tester);
      await tester.tap(find.byType(CivicButton));
      expect(presses, 1);
      expect(find.semantics.byLabel('Send application'), findsOne);
      expect(find.semantics.byLabel('Sending'), findsNothing);
      semantics.dispose();
    });

    testWidgets('shows the progress cursor to a pointer', (tester) async {
      await tester.pumpWidget(
        _app(
          Center(
            child: CivicButton(
              onPressed: () {},
              expand: false,
              busy: true,
              child: const Text('Send application'),
            ),
          ),
          still: true,
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(
        location: tester.getCenter(find.byType(CivicButton)),
      );
      addTearDown(mouse.removePointer);
      await tester.pump();
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.progress,
      );
    });
  });

  group('pull to refresh', () {
    testWidgets('a pull far enough refreshes, and the band says so', (
      tester,
    ) async {
      var fetched = 0;
      final done = <Future<void>>[];
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 400,
            child: CivicPullToRefresh(
              onRefresh: () {
                fetched++;
                final f = Future<void>.delayed(const Duration(seconds: 1));
                done.add(f);
                return f;
              },
              child: ListView(
                children: const [
                  CivicListRow(title: Text('Resident permit, Zone B')),
                ],
              ),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Resident permit, Zone B')),
      );
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, 30));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.text('Refresh'), findsOneWidget, reason: 'armed');
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(fetched, 1);
      expect(find.text('Refreshing'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      final band = tester.getRect(find.text('Refreshing'));
      final row = tester.getRect(find.text('Resident permit, Zone B'));
      expect(
        row.top,
        greaterThanOrEqualTo(band.bottom),
        reason: 'the list moves down under the band, nothing hidden',
      );
      // The fetch ends a second after the release.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Refreshed'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Refreshed'), findsNothing, reason: 'the band closes');
    });

    testWidgets('its button refreshes it as a pull does', (tester) async {
      final key = GlobalKey<CivicPullToRefreshState>();
      var fetched = 0;
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 400,
            child: CivicPullToRefresh(
              key: key,
              onRefresh: () async => fetched++,
              child: ListView(children: const [Text('Your applications')]),
            ),
          ),
        ),
      );
      final refreshed = key.currentState!.refresh();
      await tester.pumpAndSettle();
      await refreshed;
      expect(fetched, 1);
      await tester.pump(const Duration(milliseconds: 300));
    });
  });

  group('an action bar', () {
    testWidgets('is heard and reached only while rows are picked', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var cleared = 0;
      Widget bar(int count) => _app(
        CivicActionBar(
          count: count,
          onClear: () => cleared++,
          actions: [
            CivicButton.secondary(
              onPressed: () {},
              expand: false,
              child: const Text('Renew'),
            ),
          ],
        ),
      );
      await tester.pumpWidget(bar(0));
      await tester.pumpAndSettle();
      expect(find.text('Renew'), findsNothing);
      await tester.pumpWidget(bar(2));
      await tester.pumpAndSettle();
      expect(find.text('2 items selected'), findsOneWidget);
      expect(
        _node(
          tester,
          find.text('2 items selected'),
        ).flagsCollection.isLiveRegion,
        isTrue,
      );
      await tester.tap(find.text('Clear'));
      expect(cleared, 1);
      // Let go of the last row: it keeps its words as it closes, then goes.
      await tester.pumpWidget(bar(0));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('2 items selected'), findsOneWidget);
      expect(
        find.semantics.byLabel('2 items selected'),
        findsNothing,
        reason: 'closing, it is not heard',
      );
      await tester.pumpAndSettle();
      expect(find.text('2 items selected'), findsNothing);
      semantics.dispose();
    });
  });

  group('a chart', () {
    const chart = CivicLineChart(
      title: 'Permits issued each month',
      labelHeader: 'Month',
      labels: ['Jan', 'Feb', 'Mar'],
      series: [
        CivicChartSeries('Resident', [120, 135, 128]),
        CivicChartSeries('Visitor', [80, 92, 110]),
      ],
    );

    testWidgets('is heard by its name and names its series in words', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(chart));
      await tester.pumpAndSettle();
      expect(
        find.semantics.byPredicate(
          (n) => n.label.startsWith('Permits issued each month'),
        ),
        findsOneWidget,
      );
      expect(find.text('Resident'), findsOneWidget, reason: 'the legend');
      expect(find.text('Visitor'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('folds out its figures as a table, one press away', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const SingleChildScrollView(child: chart)));
      await tester.pumpAndSettle();
      expect(find.text('135'), findsNothing);
      await tester.tap(find.text('Show data table'));
      await tester.pumpAndSettle();
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('135'), findsOneWidget);
      expect(find.text('110'), findsOneWidget);
    });

    testWidgets("a screen reader's Show data table opens it too", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(const SingleChildScrollView(child: chart)));
      await tester.pumpAndSettle();
      tester.semantics.customAction(
        find.semantics.byPredicate(
          (n) => n.label.startsWith('Permits issued each month'),
        ),
        const CustomSemanticsAction(label: 'Show data table'),
      );
      await tester.pumpAndSettle();
      expect(find.text('135'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('takes the keys as one stop, ringed in the focus yellow', (
      tester,
    ) async {
      await tester.pumpWidget(_app(chart));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final t = CivicThemeData.light();
      final ring = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where(
            (d) =>
                d.decoration is BoxDecoration &&
                ((d.decoration as BoxDecoration).border as Border?)
                        ?.top
                        .color ==
                    t.focus,
          );
      expect(ring, isNotEmpty);
    });

    testWidgets('a pie names each slice with its value and share', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const CivicPieChart(
            title: 'Permits by kind',
            slices: [
              CivicPieSlice('Resident', 1240),
              CivicPieSlice('Visitor', 610),
              CivicPieSlice('Business', 150),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Resident, 1,240, 62%', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text('Business, 150, 8%', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a sparkline says where it starts and ends', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const CivicSparkline(
            label: 'Visitor permits this week',
            values: [12, 18, 31],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('31'), findsOneWidget);
      expect(
        _node(tester, find.byType(CivicSparkline)).label,
        'Visitor permits this week, 12 to 31',
      );
      semantics.dispose();
    });
  });
}
