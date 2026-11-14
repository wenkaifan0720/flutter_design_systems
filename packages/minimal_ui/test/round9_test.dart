// Round 9's fixes: a toned icon tile draws no rim; a dialog's actions end
// on its question's inset; an expanded button group stops at a control's
// measure on a laptop; a disabled row dims its words and keeps its rule; a
// table that scrolls cuts no name; the inventory shows a dialog and a side
// sheet at their own widths, and every specimen in it lays out (a
// navigation rail needs a height of its own).
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

/// [child] on a full-bleed page [width] wide at [scale].
Widget _app(Widget child, {double width = 390, double scale = 1}) =>
    MaterialApp(
      builder: (context, navigator) => MinimalHost(
        light: MinimalThemeData.preset('standard', Brightness.light),
        dark: MinimalThemeData.preset('standard', Brightness.dark),
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

/// The rim [decoration] paints, or null.
BorderSide? _rimOf(Decoration? decoration) => switch (decoration) {
  BoxDecoration(border: final Border border) => border.top,
  ShapeDecoration(shape: final OutlinedBorder shape)
      when shape.side != BorderSide.none =>
    shape.side,
  _ => null,
};

/// How opaque [part] paints: every fade above it, multiplied.
double _fade(WidgetTester tester, Finder part) {
  var opacity = 1.0;
  for (final o in tester.widgetList<Opacity>(
    find.ancestor(of: part, matching: find.byType(Opacity)),
  )) {
    opacity *= o.opacity;
  }
  for (final f in tester.widgetList<FadeTransition>(
    find.ancestor(of: part, matching: find.byType(FadeTransition)),
  )) {
    opacity *= f.opacity.value;
  }
  return opacity;
}

/// A container that rules its foot.
final Finder _ruled = find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.foregroundDecoration is BoxDecoration &&
      ((w.foregroundDecoration! as BoxDecoration).border as Border?)
              ?.bottom
              .width !=
          null &&
      ((w.foregroundDecoration! as BoxDecoration).border! as Border)
              .bottom
              .width >
          0,
);

bool _cut(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).didExceedMaxLines;

typedef _Order = ({String id, String customer, String status, int total});

const List<_Order> _orders = [
  (id: 'ORD-1042', customer: 'Café Morgenrot', status: 'Shipped', total: 129),
  (id: 'ORD-1041', customer: 'Studio Nordlicht', status: 'Pending', total: 45),
  (id: 'ORD-1040', customer: 'Mara Quintero', status: 'Paid', total: 312),
];

void main() {
  testWidgets('a toned icon tile draws no rim; a neutral one keeps its '
      'hairline', (tester) async {
    await tester.pumpWidget(
      _app(
        const Row(
          children: [
            MinimalIconTile(Icons.check, tone: MinimalTone.success),
            MinimalIconTile(Icons.check),
          ],
        ),
      ),
    );
    Decoration? frame(int i) => tester
        .widget<Container>(
          find
              .descendant(
                of: find.byType(MinimalIconTile).at(i),
                matching: find.byType(Container),
              )
              .first,
        )
        .decoration;
    expect(_rimOf(frame(0)), isNull);
    expect(_rimOf(frame(1)), isNotNull);
  });

  testWidgets("a dialog's actions end on its question's inset", (tester) async {
    await tester.pumpWidget(
      _app(
        const MinimalDialog(
          title: 'Archive habit?',
          message: 'It leaves Today; its history stays.',
          confirmLabel: 'Archive',
          cancelLabel: 'Keep',
        ),
        width: MinimalDialog.maxWidth,
      ),
    );
    final card = tester.getRect(find.byType(MinimalDialog));
    final title = tester.getRect(find.text('Archive habit?'));
    final act = tester.getRect(
      find
          .ancestor(
            of: find.text('Archive'),
            matching: find.byType(MinimalButton),
          )
          .first,
    );
    expect(card.right - act.right, closeTo(title.left - card.left, 0.01));
  });

  testWidgets('an expanded button group stops at the control measure on a '
      'laptop and spans a phone', (tester) async {
    Widget group() => MinimalButtonGroup(
      expand: true,
      items: [
        MinimalButtonGroupItem(label: 'Day', onPressed: () {}),
        MinimalButtonGroupItem(label: 'Week', onPressed: () {}),
        MinimalButtonGroupItem(label: 'Month', onPressed: () {}),
      ],
    );
    // The bar: the frame the cells stand in.
    double bar() => tester
        .getSize(
          find
              .descendant(
                of: find.byType(MinimalButtonGroup),
                matching: find.byType(Container),
              )
              .first,
        )
        .width;
    _view(tester, const Size(1440, 900));
    await tester.pumpWidget(_app(group(), width: 1000));
    expect(bar(), MinimalLayout.controlMax);
    _view(tester, const Size(390, 844));
    await tester.pumpWidget(_app(group()));
    expect(bar(), 390);
  });

  group('a disabled row dims its words and keeps its rule', () {
    Future<void> check(WidgetTester tester, Widget row, String label) async {
      await tester.pumpWidget(_app(row));
      await tester.pump(const Duration(milliseconds: 300));
      final words = find.text(label);
      final rule = find.ancestor(of: words, matching: _ruled).first;
      expect(_fade(tester, words), lessThan(1));
      expect(_fade(tester, rule), 1);
    }

    testWidgets('MinimalSelect', (tester) async {
      await check(
        tester,
        const MinimalSelect<String>(
          label: 'Repeats',
          value: 'daily',
          options: [MinimalSelectOption('daily', 'Every day')],
        ),
        'Repeats',
      );
    });

    testWidgets('MinimalChoiceRow', (tester) async {
      await check(
        tester,
        const MinimalChoiceRow(title: 'Every day', selected: false),
        'Every day',
      );
    });

    testWidgets('MinimalDatePicker', (tester) async {
      await check(
        tester,
        MinimalDatePicker(
          label: 'Paused until',
          value: DateTime(2026, 9, 14, 7),
        ),
        'Paused until',
      );
    });

    testWidgets('MinimalInputRow', (tester) async {
      await check(
        tester,
        const MinimalInputRow(label: 'Name', enabled: false),
        'Name',
      );
    });
  });

  group('a table that scrolls cuts no name', () {
    final scrolls = find.byWidgetPredicate(
      (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
    );

    testWidgets('MinimalTable', (tester) async {
      await tester.pumpWidget(
        _app(
          MinimalTable(
            columns: const [
              MinimalColumn('Order', width: 80, mono: true),
              MinimalColumn('Customer'),
              MinimalColumn('Status'),
              MinimalColumn('Total', width: 72, numeric: true),
            ],
            rows: [
              for (final o in _orders)
                MinimalTableRow([
                  MinimalCell(o.id),
                  MinimalCell(o.customer),
                  MinimalCell(o.status),
                  MinimalCell('\$${o.total}.00'),
                ]),
            ],
          ),
          width: 260,
          scale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(scrolls, findsWidgets);
      for (final o in _orders) {
        expect(_cut(tester, o.customer), isFalse, reason: o.customer);
      }
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
              MinimalDataColumn<_Order>('Status', value: (o) => o.status),
              MinimalDataColumn<_Order>(
                'Total',
                value: (o) => '\$${o.total}.00',
                numeric: true,
              ),
            ],
          ),
          width: 260,
          scale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(scrolls, findsWidgets);
      for (final o in _orders) {
        expect(_cut(tester, o.customer), isFalse, reason: o.customer);
      }
    });
  });

  testWidgets('the inventory shows a dialog at its own width, on the '
      "column's start", (tester) async {
    _view(tester, const Size(1000, 900));
    await tester.pumpWidget(_inventory());
    // Jump a screen at a time: a drag can land on a part that takes the
    // gesture itself (a slider, a split's handle) and not scroll the list.
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    while (find.byType(MinimalDialog).evaluate().isEmpty &&
        position.pixels < position.maxScrollExtent) {
      position.jumpTo(
        math.min(position.pixels + 600, position.maxScrollExtent),
      );
      await tester.pump();
    }
    expect(
      tester.getSize(find.byType(MinimalDialog)).width,
      MinimalDialog.maxWidth,
    );
    // Let any part's timers run out before the end.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });

  for (final width in [1000.0, 390.0]) {
    testWidgets('every inventory specimen lays out, top to bottom, $width '
        'wide', (tester) async {
      _view(tester, Size(width, 900));
      await tester.pumpWidget(_inventory());
      expect(tester.takeException(), isNull);
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      // The list builds lazily: walk it a screen at a time, so every row
      // is built and laid out once.
      while (position.pixels < position.maxScrollExtent) {
        position.jumpTo(
          math.min(position.pixels + 600, position.maxScrollExtent),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '${position.pixels}');
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
    });
  }
}

/// The inventory gallery as a page of its own.
Widget _inventory() => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: const MinimalScaffold(scroll: false, body: MinimalInventoryGallery()),
);
