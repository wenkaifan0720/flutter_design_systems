/// Breadcrumbs and pagination: what they show, what a tap does, how a long
/// trail folds and a narrow pagination shrinks to its count, and the
/// tooltip, loading, empty and donut forms of the chart; and the file
/// input's area, picker button, files and error.
library;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

Widget _kit(
  Widget child, {
  double width = 390,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  home: ExpressiveHost(
    light: ExpressiveThemeData.preset('baseline', Brightness.light),
    dark: ExpressiveThemeData.preset('baseline', Brightness.dark),
    brightness: Brightness.light,
    child: Directionality(
      textDirection: direction,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(
          width: width,
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  ),
);

void main() {
  group('breadcrumbs', () {
    testWidgets('an ancestor goes to its page; the current one is plain', (
      tester,
    ) async {
      final went = <String>[];
      await tester.pumpWidget(
        _kit(
          ExpressiveBreadcrumb(
            items: <ExpressiveBreadcrumbItem>[
              ExpressiveBreadcrumbItem(
                'Home',
                onPressed: () => went.add('Home'),
              ),
              ExpressiveBreadcrumbItem(
                'Orders',
                onPressed: () => went.add('Orders'),
              ),
              const ExpressiveBreadcrumbItem('#1042'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();
      expect(went, <String>['Orders']);
      expect(
        find.ancestor(
          of: find.text('#1042'),
          matching: find.bySubtype<ExpressiveButton>(),
        ),
        findsNothing,
      );
      expect(
        tester.getSemantics(find.text('#1042')),
        matchesSemantics(
          label: '#1042',
          hasSelectedState: true,
          isSelected: true,
        ),
      );
    });

    testWidgets('a long trail folds its middle into a menu', (tester) async {
      final went = <String>[];
      final items = <ExpressiveBreadcrumbItem>[
        for (final name in ['Home', 'Library', 'Music', 'Albums', 'Blue'])
          ExpressiveBreadcrumbItem(name, onPressed: () => went.add(name)),
        const ExpressiveBreadcrumbItem('Track'),
      ];
      await tester.pumpWidget(
        _kit(ExpressiveBreadcrumb(items: items, maxShown: 4), width: 1000),
      );
      // The root, the fold and the last two show.
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Library'), findsNothing);
      expect(find.text('Music'), findsNothing);
      expect(find.text('Albums'), findsNothing);
      expect(find.text('Blue'), findsOneWidget);
      expect(find.text('Track'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Show the folded steps'));
      await tester.pumpAndSettle();
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Albums'), findsOneWidget);
      await tester.tap(find.text('Music'));
      await tester.pumpAndSettle();
      expect(went, <String>['Music']);
    });

    testWidgets('a trail too wide for its room folds further', (tester) async {
      final items = <ExpressiveBreadcrumbItem>[
        for (final name in ['Home', 'Library', 'Music', 'Albums'])
          ExpressiveBreadcrumbItem(name, onPressed: () {}),
        const ExpressiveBreadcrumbItem('Track'),
      ];
      await tester.pumpWidget(
        _kit(ExpressiveBreadcrumb(items: items, maxShown: 5), width: 1000),
      );
      expect(find.text('Library'), findsOneWidget);
      expect(find.bySemanticsLabel('Show the folded steps'), findsNothing);
      await tester.pumpWidget(
        _kit(ExpressiveBreadcrumb(items: items, maxShown: 5), width: 360),
      );
      // The root, the fold and the current page are always there.
      expect(find.text('Home'), findsOneWidget);
      expect(find.bySemanticsLabel('Show the folded steps'), findsOneWidget);
      expect(find.text('Track'), findsOneWidget);
      expect(find.text('Library'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the chevrons turn round right to left', (tester) async {
      await tester.pumpWidget(
        _kit(
          ExpressiveBreadcrumb(
            items: <ExpressiveBreadcrumbItem>[
              ExpressiveBreadcrumbItem('Home', onPressed: () {}),
              const ExpressiveBreadcrumbItem('Here'),
            ],
          ),
          direction: TextDirection.rtl,
        ),
      );
      expect(
        _drawnFlip(tester, find.byIcon(ExpressiveSymbols.chevronRight)),
        -1,
      );
    });
  });

  group('pagination', () {
    List<int?> pages(int page, int count) =>
        ExpressivePagination(page: page, count: count, onChanged: (_) {}).pages;

    test('first, last and the current page with a sibling each side', () {
      expect(pages(5, 12), <int?>[1, null, 4, 5, 6, null, 12]);
      expect(pages(1, 12), <int?>[1, 2, null, 12]);
      expect(pages(12, 12), <int?>[1, null, 11, 12]);
      // A fold that would hide one page shows it.
      expect(pages(3, 7), <int?>[1, 2, 3, 4, null, 7]);
      expect(pages(3, 5), <int?>[1, 2, 3, 4, 5]);
      expect(pages(1, 1), <int?>[1]);
    });

    testWidgets('arrows and pages ask for their page; ends disable', (
      tester,
    ) async {
      final asked = <int>[];
      Future<void> pump(int page) => tester.pumpWidget(
        _kit(
          ExpressivePagination(page: page, count: 12, onChanged: asked.add),
          width: 1000,
        ),
      );
      await pump(5);
      await tester.tap(find.bySemanticsLabel('Next page'));
      await tester.tap(find.bySemanticsLabel('Previous page'));
      await tester.tap(find.text('12'));
      expect(asked, <int>[6, 4, 12]);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Page 5 of 12')),
        matchesSemantics(
          label: 'Page 5 of 12',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await pump(1);
      asked.clear();
      await tester.tap(find.bySemanticsLabel('Previous page'));
      expect(asked, isEmpty);
    });

    testWidgets('the parts stand apart by more than a focus ring reaches, '
        'so the next page never covers it', (tester) async {
      await tester.pumpWidget(
        _kit(
          ExpressivePagination(page: 5, count: 12, onChanged: (_) {}),
          width: 1000,
        ),
      );
      Rect page(String p) => tester.getRect(
        find.ancestor(
          of: find.text(p),
          matching: find.bySubtype<ExpressiveButton>(),
        ),
      );
      const reach = ExpressiveFocusRing.offset + ExpressiveFocusRing.thickness;
      // Page 5 is the current one, its tonal pill on show.
      expect(page('5').left - page('4').right, greaterThan(reach));
      expect(page('6').left - page('5').right, greaterThan(reach));
      expect(tester.takeException(), isNull);
    });

    testWidgets('where the pages do not fit, the count stands instead', (
      tester,
    ) async {
      await tester.pumpWidget(
        _kit(
          ExpressivePagination(page: 5, count: 12, onChanged: (_) {}),
          width: 260,
        ),
      );
      expect(find.text('Page 5 of 12'), findsOneWidget);
      expect(find.text('6'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    for (final direction in TextDirection.values) {
      testWidgets('next points the way the pages run (${direction.name})', (
        tester,
      ) async {
        await tester.pumpWidget(
          _kit(
            ExpressivePagination(page: 5, count: 12, onChanged: (_) {}),
            direction: direction,
          ),
        );
        final next = find.byIcon(ExpressiveSymbols.chevronRight);
        final previous = find.byIcon(ExpressiveSymbols.chevronLeft);
        final rtl = direction == TextDirection.rtl;
        // Next stands at the row's end and points on, past the pages.
        expect(tester.getCenter(next).dx > tester.getCenter(previous).dx, !rtl);
        expect(_drawnFlip(tester, next), rtl ? -1 : 1);
        expect(_drawnFlip(tester, previous), rtl ? -1 : 1);
      });
    }
  });

  group('file input', () {
    testWidgets('the button opens the picker; a file removes; an error says', (
      tester,
    ) async {
      var browsed = 0;
      final removed = <int>[];
      await tester.pumpWidget(
        _kit(
          ExpressiveFileUpload(
            label: 'Drop receipts here',
            supportingText: 'PDF or JPG',
            onBrowse: () => browsed++,
            files: const <ExpressiveChosenFile>[
              ExpressiveChosenFile('a.pdf', detail: '1 KB'),
              ExpressiveChosenFile('b.jpg'),
            ],
            onRemove: removed.add,
            errorText: 'That file is too big',
          ),
        ),
      );
      expect(find.text('Drop receipts here'), findsOneWidget);
      expect(find.text('PDF or JPG'), findsOneWidget);
      expect(find.text('That file is too big'), findsOneWidget);
      await tester.tap(find.text('Choose files'));
      expect(browsed, 1);
      await tester.tap(find.bySemanticsLabel('Remove b.jpg'));
      expect(removed, <int>[1]);
      expect(tester.takeException(), isNull);
    });
  });

  group('chart', () {
    const week = <ExpressiveChartPoint>[
      ExpressiveChartPoint('Mon', 10),
      ExpressiveChartPoint('Tue', 45),
      ExpressiveChartPoint('Wed', 20),
    ];

    testWidgets('a donut names each part with its share', (tester) async {
      await tester.pumpWidget(
        _kit(
          const ExpressiveChart.donut(
            points: <ExpressiveChartPoint>[
              ExpressiveChartPoint('Rent', 75),
              ExpressiveChartPoint('Food', 25),
            ],
            centerValue: '100',
            centerLabel: 'Spent',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rent · 75 (75%)'), findsOneWidget);
      expect(find.text('Food · 25 (25%)'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Spent 100; Rent 75 (75%), Food 25 (25%)'),
        findsOneWidget,
      );
    });

    testWidgets('loading shows a skeleton; no points say so', (tester) async {
      await tester.pumpWidget(
        _kit(const ExpressiveChart.bar(points: week, loading: true)),
      );
      expect(find.byType(ExpressiveSkeleton), findsOneWidget);
      await tester.pumpWidget(
        _kit(const ExpressiveChart.bar(points: <ExpressiveChartPoint>[])),
      );
      expect(find.text('No data yet'), findsOneWidget);
    });

    testWidgets('a tooltip shows the point under a pointer, and a card '
        'still takes the tap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _kit(
          ExpressiveCard(
            onPressed: () => tapped++,
            child: const ExpressiveChart.bar(points: week, tooltip: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final plot = find.byType(AspectRatio).first;
      final box = tester.getRect(plot);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: box.center);
      await tester.pump();
      expect(find.text('Tue · 45'), findsOneWidget);
      await mouse.moveTo(Offset(box.left + 4, box.center.dy));
      await tester.pump();
      expect(find.text('Mon · 10'), findsOneWidget);
      await mouse.removePointer();
      await tester.tapAt(box.center);
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });
  });
}

/// How [icon]'s glyph is drawn across: -1 mirrored, 1 as designed (its own
/// right-to-left mirroring times every flip around it).
double _drawnFlip(WidgetTester tester, Finder icon) {
  final glyph = tester.widget<Icon>(icon).icon!;
  final rtl = Directionality.of(tester.element(icon)) == TextDirection.rtl;
  var across = glyph.matchTextDirection && rtl ? -1.0 : 1.0;
  for (final transform in tester.widgetList<Transform>(
    find.ancestor(of: icon, matching: find.byType(Transform)),
  )) {
    across *= transform.transform.entry(0, 0).sign;
  }
  return across;
}
