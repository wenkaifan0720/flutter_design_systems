// Round 4's list and table fixes: one keyline for rows that lead with
// different marks (list rows and meta rows); a stack of segment bars that
// starts and ends on one line; a captionless code block's copy action on its
// first line; a sideways table's band and rules reaching the frame's edge
// under the faded words; a reorderable row with no ground of its own.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// [child] on a full-bleed page [width] wide, read [direction] at [scale].
Widget _app(
  Widget child, {
  double width = 390,
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: Directionality(textDirection: direction, child: navigator!),
    ),
  ),
  home: MinimalScaffold(
    padding: EdgeInsets.zero,
    body: Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(width: width, child: child),
    ),
  ),
);

/// Whether a widget paints the header band's fill in its own box.
bool Function(Widget) _bandOf(Color band) =>
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).color == band;

/// A rectangle [width] across in [colour], drawn on the canvas. A paint
/// keeps its colour in 32-bit floats, so the two are compared as 8-bit ARGB.
PaintPatternPredicate _across(double width, Color colour) =>
    (method, args) =>
        method == #drawRect &&
        ((args[0] as Rect).width - width).abs() < 0.01 &&
        (args[1] as Paint).color.toARGB32() == colour.toARGB32();

const _columns = [
  MinimalColumn('#', width: 54, mono: true),
  MinimalColumn('Customer'),
  MinimalColumn('Qty', width: 38, numeric: true),
];

const _rows = [
  MinimalTableRow([
    MinimalCell('1047'),
    MinimalCell('Hanna Berg', strong: true),
    MinimalCell('3'),
  ]),
  MinimalTableRow([
    MinimalCell('1046'),
    MinimalCell('Oskar Lind', strong: true),
    MinimalCell('1'),
  ], selected: true),
];

typedef _Order = ({String id, String customer, String status, int total});

const List<_Order> _orders = [
  (id: 'ORD-1042', customer: 'Ana Souza', status: 'Paid', total: 129),
  (id: 'ORD-1041', customer: 'Ben Okafor', status: 'Refunded', total: 45),
];

void main() {
  group('rows that lead with different marks share one keyline', () {
    for (final direction in TextDirection.values) {
      testWidgets('list rows in one slot, ${direction.name}', (tester) async {
        await tester.pumpWidget(
          _app(
            const MinimalListSection(
              children: [
                MinimalListTile(
                  icon: LucideIcons.flame,
                  leadingWidth: 28,
                  title: 'Glyph',
                ),
                MinimalListTile(
                  leading: MinimalIconTile(LucideIcons.croissant),
                  leadingWidth: 28,
                  title: 'Tile',
                ),
                MinimalListTile(
                  leading: MinimalAvatar('Hanna Berg', size: 24),
                  leadingWidth: 28,
                  title: 'Face',
                ),
                MinimalListTile(
                  leading: MinimalPriorityIcon(MinimalPriority.high),
                  leadingWidth: 28,
                  title: 'Priority',
                ),
              ],
            ),
            direction: direction,
          ),
        );
        await tester.pumpAndSettle();
        double start(String title) => direction == TextDirection.ltr
            ? tester.getTopLeft(find.text(title)).dx
            : tester.getTopRight(find.text(title)).dx;
        final keyline = start('Glyph');
        for (final title in ['Tile', 'Face', 'Priority']) {
          expect(start(title), closeTo(keyline, 0.01), reason: title);
        }
      });
    }

    testWidgets('a 16 px glyph stands in an 18 px glyph\'s slot', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const MinimalListSection(
            children: [
              MinimalListTile(icon: LucideIcons.calendarDays, title: 'Glyph'),
              MinimalListTile(
                leading: MinimalPriorityIcon(MinimalPriority.high),
                title: 'Priority',
              ),
              MinimalListTile(
                leading: MinimalStatusIcon(MinimalTaskStatus.done, size: 16),
                title: 'Status',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final keyline = tester.getTopLeft(find.text('Glyph')).dx;
      expect(
        tester.getTopLeft(find.text('Priority')).dx,
        closeTo(keyline, 0.01),
      );
      expect(tester.getTopLeft(find.text('Status')).dx, closeTo(keyline, 0.01));
    });

    testWidgets('meta rows in one slot start their middles together', (
      tester,
    ) async {
      for (final scale in [1.0, 1.3]) {
        await tester.pumpWidget(
          _app(
            const Column(
              children: [
                MinimalMetaRow(
                  leading: Text('1047'),
                  leadingWidth: 64,
                  middle: Text('Hanna Berg'),
                ),
                MinimalMetaRow(
                  leading: MinimalTag('New', tone: MinimalTone.primary),
                  leadingWidth: 64,
                  middle: Text('Studio North'),
                ),
                MinimalMetaRow(
                  leading: MinimalStatusIcon(MinimalTaskStatus.done, size: 16),
                  leadingWidth: 64,
                  middle: Text('Marked done'),
                ),
                MinimalMetaRow(
                  leading: MinimalAvatar('Ines Duarte', size: 24),
                  leadingWidth: 64,
                  middle: Text('Joined'),
                ),
              ],
            ),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        final keyline = tester.getTopLeft(find.text('Hanna Berg')).dx;
        for (final middle in ['Studio North', 'Marked done', 'Joined']) {
          expect(
            tester.getTopLeft(find.text(middle)).dx,
            closeTo(keyline, 0.01),
            reason: '$middle at $scale',
          );
        }
      }
    });
  });

  testWidgets('a stack of segment bars starts and ends on one line', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        width: 600,
        const Column(
          children: [
            MinimalSegmentBar(
              value: 3,
              total: 5,
              label: 'kept',
              labelWidth: 240,
              showPercent: true,
            ),
            MinimalSegmentBar(
              value: 2,
              total: 12,
              tone: MinimalTone.warning,
              label: 'weeks missed',
              labelWidth: 240,
              showPercent: true,
            ),
            // A whole bar prints 100%, a widest figure: its end holds.
            MinimalSegmentBar(
              value: 5,
              total: 5,
              label: 'kept',
              labelWidth: 240,
              showPercent: true,
            ),
            MinimalSegmentBar(
              value: 0,
              total: 0,
              label: 'kept',
              labelWidth: 240,
              showPercent: true,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    (double, double) ends(int i) {
      final cells = find.descendant(
        of: find.byType(MinimalSegmentBar).at(i),
        matching: find.byType(AnimatedContainer),
      );
      return (
        tester.getTopLeft(cells.first).dx,
        tester.getTopRight(cells.last).dx,
      );
    }

    final (start, end) = ends(0);
    for (var i = 1; i < 4; i++) {
      final (s, e) = ends(i);
      expect(s, closeTo(start, 0.01), reason: 'bar $i starts');
      expect(e, closeTo(end, 0.01), reason: 'bar $i ends');
    }
  });

  testWidgets('a captionless code block\'s copy stands on its first line', (
    tester,
  ) async {
    const code = 'rk_live_7Hc2QpX9vB41mNf0';
    for (final scale in [1.0, 1.3]) {
      await tester.pumpWidget(_app(const MinimalCodeBlock(code), scale: scale));
      await tester.pumpAndSettle();
      expect(
        tester.getCenter(find.byType(MinimalIconButton)).dy,
        closeTo(tester.getCenter(find.text(code)).dy, 0.5),
        reason: 'at $scale',
      );
    }
  });

  group('a sideways table\'s band and rules reach the frame\'s edge', () {
    testWidgets('MinimalTable', (tester) async {
      await tester.pumpWidget(
        _app(
          const MinimalTable(minWidth: 560, columns: _columns, rows: _rows),
          width: 320,
        ),
      );
      await tester.pumpAndSettle();
      // The theme a row is built in (a table may stand its rows on a ground
      // of its own).
      final t = tester.element(find.text('Hanna Berg')).minimalTheme;
      // Nothing in the faded strip paints the band: it would fade with
      // the words and stop short of the edge.
      expect(
        find.descendant(
          of: find.byType(ShaderMask),
          matching: find.byWidgetPredicate(_bandOf(t.muted)),
        ),
        findsNothing,
      );
      final table = tester.renderObject(find.byType(MinimalTable));
      expect(table, paints..something(_across(320, t.muted)));
      expect(table, paints..something(_across(320, t.selection)));
      expect(table, paints..something(_across(320, t.rule.color)));
    });

    testWidgets('MinimalDataTable', (tester) async {
      await tester.pumpWidget(
        _app(
          MinimalDataTable<_Order>(
            rows: _orders,
            columns: [
              MinimalDataColumn<_Order>(
                'Order',
                value: (o) => o.id,
                mono: true,
              ),
              MinimalDataColumn<_Order>('Customer', value: (o) => o.customer),
              MinimalDataColumn<_Order>(
                'Status',
                value: (o) => o.status,
                cell: (context, o) => MinimalStatusBadge(o.status),
              ),
              MinimalDataColumn<_Order>(
                'Total',
                value: (o) => '\$${o.total}.00',
                numeric: true,
              ),
            ],
          ),
          width: 240,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShaderMask), findsOneWidget);
      final t = tester.element(find.text('Ana Souza')).minimalTheme;
      expect(
        find.descendant(
          of: find.byType(ShaderMask),
          matching: find.byWidgetPredicate(_bandOf(t.muted)),
        ),
        findsNothing,
      );
      final table = tester.renderObject(find.byType(MinimalDataTable<_Order>));
      expect(table, paints..something(_across(240, t.muted)));
      expect(table, paints..something(_across(240, t.rule.color)));
    });
  });

  testWidgets('a reorderable row has no ground of its own', (tester) async {
    await tester.pumpWidget(
      _app(
        MinimalCard(
          padding: EdgeInsets.zero,
          child: MinimalReorderableListView<String>(
            items: const ['Warm up', 'Stretch'],
            labelOf: (s) => s,
            onReorder: (_, _) {},
            itemBuilder: (context, s) => Text(s),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // A fill would paint over the card's rounded rim at its corners.
    final grounds = tester.widgetList<ColoredBox>(
      find.descendant(
        of: find.byType(MinimalReorderableListView<String>),
        matching: find.ancestor(
          of: find.text('Warm up'),
          matching: find.byType(ColoredBox),
        ),
      ),
    );
    expect(grounds.where((g) => g.color.a > 0), isEmpty);
  });
}
