// Round 8's fixes: a column of names keeps a run of its words at larger
// text, as the words grow; a paged data table's count starts on the table's
// leading edge, its check boxes'; a banner's glyph centres on its title's
// line at any text size; a 12-hour wheel reads 7 AM under a RTL page.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

/// [child] on a full-bleed page [width] wide at [scale], read [direction].
Widget _app(
  Widget child, {
  double width = 390,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
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

typedef _Order = ({String id, String customer, int total});

const List<_Order> _orders = [
  (id: 'ORD-1042', customer: 'Ben Okafor', total: 129),
  (id: 'ORD-1041', customer: 'Hanna', total: 45),
  (id: 'ORD-1040', customer: 'Chen Wei', total: 312),
];

List<MinimalDataColumn<_Order>> get _orderColumns => [
  MinimalDataColumn<_Order>('Order', value: (o) => o.id, mono: true),
  MinimalDataColumn<_Order>('Customer', value: (o) => o.customer),
  MinimalDataColumn<_Order>(
    'Total',
    value: (o) => '\$${o.total}.00',
    numeric: true,
  ),
];

bool _cut(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).didExceedMaxLines;

void main() {
  group('a column of names keeps its words at larger text', () {
    testWidgets('MinimalTable', (tester) async {
      await tester.pumpWidget(
        _app(
          const MinimalTable(
            columns: [
              MinimalColumn('#', width: 54, mono: true),
              MinimalColumn('Customer'),
              MinimalColumn('Qty', width: 38, numeric: true),
            ],
            rows: [
              MinimalTableRow([
                MinimalCell('1043'),
                MinimalCell('Hanna'),
                MinimalCell('6'),
              ]),
            ],
          ),
          width: 180,
          scale: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      // Too narrow for every column, the table scrolls; the names column
      // stands at its least, which grows with the words (72 at 1×). The
      // test face sets every glyph an em wide: five at 1.3 × 13 are 84.5,
      // past 72 and inside 93.6.
      expect(_cut(tester, 'Hanna'), isFalse);
    });

    testWidgets('MinimalDataTable', (tester) async {
      await tester.pumpWidget(
        _app(
          MinimalDataTable<_Order>(
            rows: _orders,
            columns: _orderColumns,
            selectable: false,
          ),
          width: 200,
          scale: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      expect(_cut(tester, 'Hanna'), isFalse);
    });
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('a banner\'s glyph centres on its title at ${scale}x', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const MinimalBanner(
            title: 'Domain verified',
            tone: MinimalTone.success,
          ),
          scale: scale,
        ),
      );
      await tester.pumpAndSettle();
      final glyph = find.descendant(
        of: find.byType(MinimalBanner),
        matching: find.byType(MinimalIcon),
      );
      expect(glyph, findsOneWidget);
      expect(
        tester.getCenter(glyph).dy,
        moreOrLessEquals(
          tester.getCenter(find.text('Domain verified')).dy,
          epsilon: 0.01,
        ),
      );
    });
  }

  testWidgets('a range field grows with its words, as every field does', (
    tester,
  ) async {
    Future<double> fieldAt(double scale) async {
      await tester.pumpWidget(
        _app(
          MinimalDateRangePicker(
            label: 'Stay',
            hint: 'Choose',
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
            onChanged: (_) {},
          ),
          scale: scale,
        ),
      );
      await tester.pumpAndSettle();
      return tester
          .getSize(
            find
                .ancestor(
                  of: find.text('Choose'),
                  matching: find.byType(Container),
                )
                .first,
          )
          .height;
    }

    final at1 = await fieldAt(1);
    final at13 = await fieldAt(1.3);
    // The 16 px line grows to 20.8; the field grows by as much.
    expect(at13 - at1, moreOrLessEquals(16 * 0.3, epsilon: 0.01));
  });

  testWidgets('a colour picker stops at the control measure from a tablet up', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MinimalColorPicker(value: const Color(0xFF2563EB), onChanged: (_) {}),
        width: 720,
      ),
    );
    await tester.pumpAndSettle();
    // The page's column is 720; the picker's own box (the cap's) is not.
    final held = find
        .descendant(
          of: find.byType(MinimalColorPicker),
          matching: find.byType(ConstrainedBox),
        )
        .first;
    expect(
      tester.getSize(held).width,
      lessThanOrEqualTo(MinimalLayout.controlMax),
    );
    expect(
      tester.getTopLeft(held).dx,
      tester.getTopLeft(find.byType(MinimalColorPicker)).dx,
    );
  });

  testWidgets('a scroll area keeps its content 16 px off the bar\'s edge', (
    tester,
  ) async {
    const content = Key('content');
    await tester.pumpWidget(
      _app(
        const MinimalScrollArea(
          height: 80,
          alwaysShown: true,
          child: SizedBox(key: content, width: double.infinity, height: 400),
        ),
        width: 200,
      ),
    );
    await tester.pumpAndSettle();
    final area = tester.getRect(find.byType(MinimalScrollArea));
    expect(tester.getRect(find.byKey(content)).right, area.right - 16);
  });

  testWidgets('an empty chart says why in the caption ink', (tester) async {
    await tester.pumpWidget(
      _app(
        const Column(
          children: [
            MinimalLineChart(series: [], emptyLabel: 'No signups'),
            MinimalPieChart(slices: [], emptyLabel: 'No hours'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final t = tester.element(find.text('No signups')).minimalTheme;
    for (final why in ['No signups', 'No hours']) {
      expect(
        tester.widget<Text>(find.text(why)).style?.color,
        t.mutedForeground,
      );
    }
  });

  for (final fraction in [0.8, 1.0]) {
    testWidgets('a carousel at $fraction cuts its neighbours '
        '${fraction < 1 ? 'square, faded' : 'not at all'}', (tester) async {
      await tester.pumpWidget(
        _app(
          MinimalCarouselView(
            height: 120,
            viewportFraction: fraction,
            children: const [
              SizedBox.expand(),
              SizedBox.expand(),
              SizedBox.expand(),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fade = find.descendant(
        of: find.byType(MinimalCarouselView),
        matching: find.byType(ShaderMask),
      );
      expect(fade, fraction < 1 ? findsOneWidget : findsNothing);
    });
  }

  testWidgets('a tab strip\'s hairline runs the width it is given', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MinimalTabBar(
              tabs: const ['Overview', 'Activity'],
              selectedIndex: 0,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MinimalTabBar)).width, 390);
  });

  testWidgets('a 12-hour wheel reads its period after the hour in RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MinimalDatePicker(
          label: 'Wake-up',
          value: DateTime(2026, 8, 28, 7),
          mode: MinimalDatePickerMode.time,
          presentation: MinimalDatePickerPresentation.wheel,
          use24HourFormat: false,
          onChanged: (_) {},
        ),
        direction: TextDirection.rtl,
      ),
    );
    await tester.pumpAndSettle();
    final hour = find.text('7 AM');
    expect(hour, findsWidgets);
    for (final paragraph in tester.renderObjectList<RenderParagraph>(hour)) {
      expect(paragraph.textDirection, TextDirection.ltr);
    }
  });

  testWidgets('a paged data table\'s count starts on its check boxes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MinimalDataTable<_Order>(
          rows: _orders,
          columns: _orderColumns,
          pageSize: 2,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boxes = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.constraints?.maxWidth == 16 &&
          w.constraints?.maxHeight == 16,
    );
    expect(boxes, findsWidgets);
    final count = find.textContaining('of 3');
    expect(count, findsOneWidget);
    expect(
      tester.getTopLeft(count).dx,
      moreOrLessEquals(tester.getTopLeft(boxes.first).dx, epsilon: 0.01),
    );
  });
}
