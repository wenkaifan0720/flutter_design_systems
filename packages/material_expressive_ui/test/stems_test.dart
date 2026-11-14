/// The shared stems round 4 adds (coverage4.md): the keyboard key, the
/// timeline and the description list (display.dart), the status view over
/// the three page states, the five chart classes over ExpressiveChart's
/// kinds, the navigation drawer standing and raised, and the wheel picker of
/// words on the time scroll's wheel.
library;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

/// [child] in Expressive's host, started in a column as a page starts it.
Widget _kit(Widget child, {double width = 390}) => MaterialApp(
  home: ExpressiveHost(
    light: _theme,
    brightness: Brightness.light,
    child: Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[child],
        ),
      ),
    ),
  ),
);

Color? _decorationColor(WidgetTester tester, Finder of) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: of, matching: find.byType(DecoratedBox)).first,
  );
  return (box.decoration as ShapeDecoration).color;
}

/// A navigation destination by its label: the whole item, which takes the
/// touch (at its indicator's centre, wherever the finger lands), not the
/// label's own text.
Finder _destination(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(MergeSemantics))
    .first;

void main() {
  group('ExpressiveTimeline', () {
    const entries = <ExpressiveTimelineEntry>[
      ExpressiveTimelineEntry(title: 'Placed', time: '09:12'),
      ExpressiveTimelineEntry(
        title: 'Shipped',
        time: '14:05',
        description: 'Tracking 4821',
      ),
      ExpressiveTimelineEntry(title: 'Delivered'),
    ];

    testWidgets('the current step marked in primary, the rest in '
        'outlineVariant; entries in order', (tester) async {
      await tester.pumpWidget(
        _kit(const ExpressiveTimeline(entries: entries, currentStep: 1)),
      );
      final markers = find.descendant(
        of: find.byType(ExpressiveTimeline),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox &&
              widget.width == ExpressiveSpacing.s8 &&
              widget.height == ExpressiveSpacing.s8,
        ),
      );
      expect(markers, findsNWidgets(3));
      final colors = <Color?>[
        for (var i = 0; i < 3; i++) _decorationColor(tester, markers.at(i)),
      ];
      expect(colors, <Color?>[
        _theme.colors.outlineVariant,
        _theme.colors.primary,
        _theme.colors.outlineVariant,
      ]);
      expect(
        tester.getTopLeft(find.text('Shipped')).dy,
        greaterThan(tester.getTopLeft(find.text('Placed')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Tracking 4821')).dy,
        greaterThan(tester.getTopLeft(find.text('Shipped')).dy),
      );
    });

    testWidgets('each entry is one node: title, time and description', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _kit(const ExpressiveTimeline(entries: entries, currentStep: 1)),
      );
      final node = tester.getSemantics(find.text('Shipped'));
      expect(node.label, contains('Shipped'));
      expect(node.label, contains('14:05'));
      expect(node.label, contains('Tracking 4821'));
      semantics.dispose();
    });
  });

  group('ExpressiveDescriptionList', () {
    const items = <ExpressiveDescriptionItem>[
      ExpressiveDescriptionItem('Order', '#4821'),
      ExpressiveDescriptionItem('Placed', '14 March'),
    ];

    testWidgets('narrow, the term stands over its value', (tester) async {
      await tester.pumpWidget(
        _kit(const ExpressiveDescriptionList(items: items)),
      );
      final term = tester.getTopLeft(find.text('Order'));
      final value = tester.getTopLeft(find.text('#4821'));
      expect(value.dy, greaterThan(term.dy));
      expect(value.dx, term.dx);
      expect(find.byType(ExpressiveDivider), findsOneWidget);
    });

    testWidgets('from 600dp, the term stands beside its value', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _kit(const ExpressiveDescriptionList(items: items), width: 900),
      );
      final term = tester.getTopLeft(find.text('Order'));
      final value = tester.getTopLeft(find.text('#4821'));
      expect(value.dy, term.dy);
      expect(value.dx, greaterThan(term.dx + 200));
    });

    testWidgets('each row is read as one node, term and value', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _kit(const ExpressiveDescriptionList(items: items, dividers: false)),
      );
      expect(find.byType(ExpressiveDivider), findsNothing);
      final node = tester.getSemantics(find.text('Order'));
      expect(node.label, contains('Order'));
      expect(node.label, contains('#4821'));
      semantics.dispose();
    });
  });

  group('ExpressiveStatusView', () {
    testWidgets('each constructor draws its state', (tester) async {
      await tester.pumpWidget(
        _kit(
          const SizedBox(
            height: 300,
            child: ExpressiveStatusView.loading(message: 'Loading trips'),
          ),
        ),
      );
      expect(find.byType(ExpressiveLoadingState), findsOneWidget);
      expect(find.text('Loading trips'), findsOneWidget);

      var retried = 0;
      await tester.pumpWidget(
        _kit(
          SizedBox(
            height: 300,
            child: ExpressiveStatusView.error(
              title: 'Could not load',
              onRetry: () => retried++,
            ),
          ),
        ),
      );
      expect(find.byType(ExpressiveErrorState), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retried, 1);

      var done = 0;
      await tester.pumpWidget(
        _kit(
          SizedBox(
            height: 300,
            child: ExpressiveStatusView.success(
              title: 'Booked',
              actionLabel: 'Done',
              onAction: () => done++,
            ),
          ),
        ),
      );
      expect(find.byType(ExpressiveSuccessState), findsOneWidget);
      await tester.tap(find.text('Done'));
      expect(done, 1);
    });
  });

  group('the chart stems', () {
    const points = <ExpressiveChartPoint>[
      ExpressiveChartPoint('M', 64),
      ExpressiveChartPoint('T', 72),
      ExpressiveChartPoint('W', 68),
    ];

    Future<ExpressiveChart> chartOf(WidgetTester tester, Widget stem) async {
      await tester.pumpWidget(_kit(stem));
      return tester.widget<ExpressiveChart>(find.byType(ExpressiveChart));
    }

    testWidgets('each draws its kind', (tester) async {
      final bar = await chartOf(
        tester,
        const ExpressiveBarChart(points: points),
      );
      expect(bar.kind, ExpressiveChartType.bar);

      final line = await chartOf(
        tester,
        const ExpressiveLineChart(points: points),
      );
      expect(line.kind, ExpressiveChartType.line);
      expect(line.domain, isNot(const ExpressiveChartDomain.zero()));
      expect(line.labels, ExpressiveChartLabels.sparse);

      final area = await chartOf(
        tester,
        const ExpressiveAreaChart(points: points),
      );
      expect(area.kind, ExpressiveChartType.line);
      expect(area.domain, const ExpressiveChartDomain.zero());

      final pie = await chartOf(
        tester,
        const SizedBox(width: 240, child: ExpressivePieChart(points: points)),
      );
      expect(pie.kind, ExpressiveChartType.donut);

      final spark = await chartOf(
        tester,
        const SizedBox(
          width: 88,
          height: 36,
          child: ExpressiveSparkline(points: points),
        ),
      );
      expect(spark.kind, ExpressiveChartType.line);
      expect(spark.labels, ExpressiveChartLabels.none);
    });
  });

  group('ExpressiveNavigationDrawer', () {
    const items = <ExpressiveNavItem>[
      ExpressiveNavItem(ExpressiveSymbols.inbox, 'Inbox'),
      ExpressiveNavItem(ExpressiveSymbols.chat, 'Chats'),
      ExpressiveNavItem(ExpressiveSymbols.group, 'Rooms'),
    ];

    testWidgets('standing, it is the expanded rail', (tester) async {
      var picked = -1;
      await tester.pumpWidget(
        _kit(
          SizedBox(
            height: 400,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ExpressiveNavigationDrawer(
                  destinations: items,
                  selectedIndex: 0,
                  onDestinationSelected: (index) => picked = index,
                ),
              ],
            ),
          ),
        ),
      );
      final rail = tester.widget<ExpressiveNavigationRail>(
        find.byType(ExpressiveNavigationRail),
      );
      expect(rail.expanded, isTrue);
      expect(
        tester.getSize(find.byType(ExpressiveNavigationRail)).width,
        greaterThanOrEqualTo(220),
      );
      await tester.tap(_destination('Rooms'));
      expect(picked, 2);
    });

    testWidgets('show raises it modally and resolves to the pick', (
      tester,
    ) async {
      int? picked;
      await tester.pumpWidget(
        _kit(
          Builder(
            builder: (context) => ExpressiveFilledButton(
              'Menu',
              onPressed: () async {
                picked = await ExpressiveNavigationDrawer.show(
                  context,
                  destinations: items,
                  selectedIndex: 0,
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Chats'), findsOneWidget);
      await tester.tap(_destination('Chats'));
      await tester.pumpAndSettle();
      expect(picked, 1);
      expect(find.text('Chats'), findsNothing);
    });
  });
}
