import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/page_host.dart';
import 'support/table_orders.dart';

const _columns = [
  MinimalColumn('#', width: 54, mono: true, sortable: true),
  MinimalColumn('Customer'),
  MinimalColumn('Qty', width: 38, numeric: true, sortable: true),
  MinimalColumn('Status', width: 84, alignEnd: true),
];

List<MinimalTableRow> _rows({bool selectSecond = false}) => [
  const MinimalTableRow([
    MinimalCell('1047'),
    MinimalCell('Hanna Berg', strong: true),
    MinimalCell('3'),
    MinimalCell.badge('Late', tone: MinimalTone.warning),
  ], semanticLabel: 'Order 1047'),
  MinimalTableRow(
    const [
      MinimalCell('1046'),
      MinimalCell('Oskar Lind', strong: true),
      MinimalCell('1'),
      MinimalCell.badge('Baking', tone: MinimalTone.primary),
    ],
    selected: selectSecond,
    semanticLabel: 'Order 1046',
  ),
  const MinimalTableRow([
    MinimalCell('1039'),
    MinimalCell('Jonas Weber'),
    MinimalCell('1'),
    MinimalCell.badge('Picked up'),
  ], faded: true),
];

void main() {
  group('MinimalTable', () {
    testWidgets('prints an uppercase header and every cell', (tester) async {
      await tester.pumpWidget(
        pageApp(MinimalTable(columns: _columns, rows: _rows())),
      );
      expect(find.text('CUSTOMER'), findsOneWidget);
      expect(find.text('Hanna Berg'), findsOneWidget);
      expect(find.text('Late'), findsOneWidget);
      expect(find.text('Picked up'), findsOneWidget);
    });

    testWidgets('a row tap reports its index', (tester) async {
      int? tapped;
      await tester.pumpWidget(
        pageApp(
          MinimalTable(
            columns: _columns,
            rows: _rows(),
            onRowPressed: (i) => tapped = i,
          ),
        ),
      );
      await tester.tap(find.text('Oskar Lind'));
      expect(tapped, 1);
      final semantics = tester.getSemantics(
        find.bySemanticsLabel('Order 1046'),
      );
      expect(semantics, isSemantics(isButton: true, isEnabled: true));
    });

    testWidgets('a selected row announces it; a faded one is half strength', (
      tester,
    ) async {
      await tester.pumpWidget(
        pageApp(
          MinimalTable(
            columns: _columns,
            rows: _rows(selectSecond: true),
            onRowPressed: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Order 1046')),
        isSemantics(isSelected: true),
      );
      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.text('Jonas Weber'),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.5);
    });

    testWidgets('a sortable header reports the column and flips the way', (
      tester,
    ) async {
      final calls = <(int, bool)>[];
      Widget table({int? sort, bool ascending = true}) => pageApp(
        MinimalTable(
          columns: _columns,
          rows: _rows(),
          sortColumn: sort,
          sortAscending: ascending,
          onSort: (column, asc) => calls.add((column, asc)),
        ),
      );
      await tester.pumpWidget(table());
      await tester.tap(find.text('QTY'));
      expect(calls.last, (2, true));
      // A column that is not sortable is not a control.
      await tester.tap(find.text('CUSTOMER'));
      expect(calls, hasLength(1));

      await tester.pumpWidget(table(sort: 2));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Qty, sorted ascending')),
        isSemantics(isButton: true, isSelected: true),
      );
      await tester.tap(find.text('QTY'));
      expect(calls.last, (2, false));
    });

    testWidgets('columns wider than the table scroll sideways', (tester) async {
      await tester.pumpWidget(
        pageApp(
          MinimalTable(minWidth: 560, columns: _columns, rows: _rows()),
          width: 320,
        ),
      );
      final scroll = tester.widget<SingleChildScrollView>(
        find.descendant(
          of: find.byType(MinimalTable),
          matching: find.byType(SingleChildScrollView),
        ),
      );
      expect(scroll.scrollDirection, Axis.horizontal);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a bounded table keeps its header while the rows scroll', (
      tester,
    ) async {
      await tester.pumpWidget(
        pageApp(
          SizedBox(
            height: 120,
            child: MinimalTable(
              columns: _columns,
              rows: [for (var i = 0; i < 6; i++) ..._rows()],
            ),
          ),
        ),
      );
      final header = tester.getTopLeft(find.text('CUSTOMER'));
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump();
      expect(tester.getTopLeft(find.text('CUSTOMER')), header);
    });

    testWidgets('a status cell is the system badge', (tester) async {
      await tester.pumpWidget(
        pageApp(MinimalTable(columns: _columns, rows: _rows())),
      );
      expect(find.byType(MinimalStatusBadge), findsNWidgets(3));
    });

    testWidgets('a sortable header takes taps across its floor-tall band', (
      tester,
    ) async {
      final calls = <int>[];
      await tester.pumpWidget(
        pageApp(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              MinimalTable(
                columns: _columns,
                rows: _rows(),
                onSort: (column, _) => calls.add(column),
              ),
            ],
          ),
        ),
      );
      final qty = tester.getRect(find.text('QTY'));
      final header = tester.getRect(
        find
            .ancestor(of: find.text('QTY'), matching: find.byType(SizedBox))
            .first,
      );
      // The band stands the floor tall: its top row of pixels sorts.
      expect(header.height, MinimalLayout.tapTargets.touch.height);
      await tester.tapAt(Offset(qty.center.dx, header.top + 2));
      expect(calls, [2]);
      // A label header takes no tap.
      final customer = tester.getRect(find.text('CUSTOMER'));
      await tester.tapAt(Offset(customer.center.dx, header.top + 2));
      expect(calls, [2]);
      // Above the band it is the page's.
      await tester.tapAt(Offset(qty.center.dx, header.top - 6));
      expect(calls, [2]);
    });

    testWidgets('the sliver form pins its header in a scrolling page', (
      tester,
    ) async {
      await tester.pumpWidget(
        pageApp(
          SizedBox(
            height: 300,
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 60)),
                MinimalTable.sliver(
                  columns: _columns,
                  rows: [for (var i = 0; i < 8; i++) ..._rows()],
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 600)),
              ],
            ),
          ),
        ),
      );
      final top = tester.getTopLeft(find.byType(CustomScrollView)).dy;
      final before = tester.getTopLeft(find.text('CUSTOMER')).dy;
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
      await tester.pump();
      // Scrolled 200 px, the header stands at the top of the view.
      // (Within a hundredth: the header's label stands on its capitals, a
      // fraction of a pixel that two sums round differently.)
      expect(
        tester.getTopLeft(find.text('CUSTOMER')).dy,
        closeTo(before - 60, 0.01),
      );
      expect(before - 60, greaterThanOrEqualTo(top));
    });

    testWidgets('an empty table prints its empty line', (tester) async {
      await tester.pumpWidget(
        pageApp(
          const MinimalTable(
            columns: _columns,
            rows: [],
            emptyLabel: 'No orders yet',
          ),
        ),
      );
      expect(find.text('No orders yet'), findsOneWidget);
    });

    testWidgets('columns stand 16 px apart where there is room', (
      tester,
    ) async {
      await tester.pumpWidget(
        pageApp(
          const MinimalTable(columns: orderColumns, rows: orderRows),
          width: 800,
        ),
      );
      // The id column's 54 px, then the gap.
      expect(
        tester.getRect(find.text('CUSTOMER')).left -
            tester.getRect(find.text('#')).left,
        closeTo(54 + 16, 0.01),
      );
    });

    testWidgets('a fixed column gives up its air before a name is cut', (
      tester,
    ) async {
      await tester.pumpWidget(
        pageApp(
          const MinimalTable(
            columns: [
              MinimalColumn('Name'),
              MinimalColumn('Status', width: 120, alignEnd: true),
            ],
            rows: [
              MinimalTableRow([
                MinimalCell('Hanna Berg Lindqvist', strong: true),
                MinimalCell.badge('Late', tone: MinimalTone.warning),
              ]),
            ],
          ),
        ),
      );
      final name = tester.renderObject<RenderParagraph>(
        find.text('Hanna Berg Lindqvist'),
      );
      expect(name.didExceedMaxLines, isFalse);
      final late = tester.renderObject<RenderParagraph>(find.text('Late'));
      expect(late.didExceedMaxLines, isFalse);
      expect(tester.getRect(find.text('Late')).right, lessThanOrEqualTo(390));
    });
  });
}
