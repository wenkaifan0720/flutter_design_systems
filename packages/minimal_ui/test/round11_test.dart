// Round 11's fixes: a toggle that is off mutes its glyph in every register;
// a selectable table's sides match; the gap after an id or figure column
// never closes; a swipe square keeps 12 px each side of its word; the
// inventory's rail and drawer stand as tall as their rows.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

final MinimalThemeData _day = MinimalThemeData.preset(
  'standard',
  Brightness.light,
);
final MinimalThemeData _night = MinimalThemeData.preset(
  'standard',
  Brightness.dark,
);

/// [child] on a full-bleed page [width] wide at [scale].
Widget _app(Widget child, {double width = 390, double scale = 1}) =>
    MaterialApp(
      builder: (context, navigator) => MinimalHost(
        light: _day,
        dark: _night,
        brightness: Brightness.light,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: navigator!,
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

/// The view [size] at one device pixel a logical pixel, for this test.
void _view(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

typedef _Order = ({String id, String customer, String status, int cents});

const List<_Order> _orders = [
  (id: 'ORD-1042', customer: 'Ana Souza', status: 'Paid', cents: 12900),
  (id: 'ORD-1041', customer: 'Ben Okafor', status: 'Refunded', cents: 4500),
  (id: 'ORD-1040', customer: 'Chen Wei', status: 'Paid', cents: 31250),
];

List<MinimalDataColumn<_Order>> get _columns => [
  MinimalDataColumn<_Order>('Order', value: (o) => o.id, mono: true),
  MinimalDataColumn<_Order>('Customer', value: (o) => o.customer),
  MinimalDataColumn<_Order>('Status', value: (o) => o.status),
  MinimalDataColumn<_Order>(
    'Total',
    value: (o) =>
        '\$${o.cents ~/ 100}.${(o.cents % 100).toString().padLeft(2, '0')}',
    numeric: true,
  ),
];

void _none() {}

/// The ink [index]'s glyph is painted in, among the icon buttons.
Color? _glyphInk(WidgetTester tester, int index) {
  final glyph = tester.widget<RichText>(
    find
        .descendant(
          of: find.byType(MinimalIconButton).at(index),
          matching: find.byType(RichText),
        )
        .first,
  );
  return glyph.text.style?.color;
}

void main() {
  testWidgets('a toggle that is off mutes its glyph in every register; '
      'on, and a plain action, it is the ink', (tester) async {
    await tester.pumpWidget(
      _app(
        Wrap(
          children: [
            for (final variant in const [
              MinimalIconButtonVariant.outline,
              MinimalIconButtonVariant.secondary,
              MinimalIconButtonVariant.ghost,
            ]) ...[
              MinimalIconButton(
                Icons.star_border,
                label: 'Pin',
                variant: variant,
                selected: true,
                onPressed: _none,
              ),
              MinimalIconButton(
                Icons.star_border,
                label: 'Pin',
                variant: variant,
                selected: false,
                onPressed: _none,
              ),
            ],
            const MinimalIconButton(
              Icons.search,
              label: 'Search',
              variant: MinimalIconButtonVariant.outline,
              onPressed: _none,
            ),
          ],
        ),
      ),
    );
    for (final i in [0, 2, 4]) {
      expect(_glyphInk(tester, i), _day.foreground, reason: 'on $i');
      expect(_glyphInk(tester, i + 1), _day.mutedForeground, reason: 'off $i');
    }
    expect(_glyphInk(tester, 6), _day.foreground);
  });

  for (final (selectable, end) in [(true, 12.0), (false, 18.0)]) {
    testWidgets('a table\'s figures end as far in as its rows start '
        '(selectable: $selectable)', (tester) async {
      _view(tester, const Size(1200, 900));
      await tester.pumpWidget(
        _app(
          MinimalDataTable<_Order>(
            rows: _orders,
            columns: _columns,
            rowKey: (o) => o.id,
            selectable: selectable,
          ),
          width: 1000,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopRight(find.text('\$129.00')).dx,
        closeTo(1000 - end, 0.5),
      );
    });
  }

  testWidgets('an id keeps its full gap from the name after it on a phone', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MinimalDataTable<_Order>(
          rows: _orders,
          columns: _columns,
          rowKey: (o) => o.id,
        ),
        width: 354,
      ),
    );
    await tester.pumpAndSettle();
    final gap =
        tester.getTopLeft(find.text('Ana Souza')).dx -
        tester.getTopRight(find.text('ORD-1042')).dx;
    expect(gap, greaterThanOrEqualTo(16 - 0.5));
  });

  testWidgets('a swipe square keeps 12 px each side of its word at larger '
      'text', (tester) async {
    await tester.pumpWidget(
      _app(
        const MinimalSwipeActions(
          initiallyOpen: true,
          trailing: [
            MinimalSwipeAction('Archive', onPressed: _none),
            MinimalSwipeAction('Delete', destructive: true, onPressed: _none),
          ],
          child: MinimalListTile(title: 'Morning run', meta: '12d'),
        ),
        scale: 1.3,
      ),
    );
    await tester.pumpAndSettle();
    // The square [label] stands in: its ruled box.
    Rect square(String label) => tester.getRect(
      find
          .ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is DecoratedBox &&
                  w.decoration is BoxDecoration &&
                  (w.decoration as BoxDecoration).border is BorderDirectional,
            ),
          )
          .first,
    );
    for (final label in ['Archive', 'Delete']) {
      final word = tester.getRect(find.text(label));
      final box = square(label);
      expect(
        math.min(word.left - box.left, box.right - word.right),
        greaterThanOrEqualTo(12 - 1.5),
        reason: label,
      );
    }
  });

  testWidgets("the inventory's rail and drawer stand as tall as their rows", (
    tester,
  ) async {
    _view(tester, const Size(1000, 900));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, navigator) => MinimalHost(
          light: _day,
          dark: _night,
          brightness: Brightness.light,
          child: navigator!,
        ),
        home: const MinimalScaffold(
          scroll: false,
          body: MinimalInventoryGallery(),
        ),
      ),
    );
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    while (find.byType(MinimalNavigationDrawer).evaluate().isEmpty &&
        position.pixels < position.maxScrollExtent) {
      position.jumpTo(
        math.min(position.pixels + 600, position.maxScrollExtent),
      );
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
    // Two rows each, and their padding: well under the old 160 band.
    expect(
      tester.getSize(find.byType(MinimalNavigationDrawer)).height,
      lessThan(120),
    );
    expect(
      tester.getSize(find.byType(MinimalNavigationRail)).height,
      lessThan(160),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}
