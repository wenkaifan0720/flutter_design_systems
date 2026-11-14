import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget _app(Widget child, {double width = 390}) => MaterialApp(
  builder: (context, child) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: child!,
  ),
  home: MinimalScaffold(
    padding: EdgeInsets.zero,
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, child: child),
    ),
  ),
);

/// [child] under a larger text scale.
Widget _scaled(Widget child, [double scale = 1.3]) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child,
  ),
);

const _orderColumns = [
  MinimalColumn('#', width: 54, mono: true, sortable: true),
  MinimalColumn('Customer'),
  MinimalColumn('Qty', width: 38, numeric: true, sortable: true),
  MinimalColumn('Due', width: 56, numeric: true, sortable: true),
  MinimalColumn('Status', width: 84, alignEnd: true),
];

const _orderRows = [
  MinimalTableRow([
    MinimalCell('1047'),
    MinimalCell('Hanna Berg', strong: true),
    MinimalCell('3'),
    MinimalCell('09:30'),
    MinimalCell.badge('Late', tone: MinimalTone.warning),
  ]),
  MinimalTableRow([
    MinimalCell('1045'),
    MinimalCell('Café Morgen', strong: true),
    MinimalCell('24'),
    MinimalCell('10:00'),
    MinimalCell.badge('Baking', tone: MinimalTone.primary),
  ]),
];

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

List<MinimalCommandItem> _actions(List<String> ran) => [
  MinimalCommandItem(
    'New habit',
    icon: LucideIcons.plus,
    group: 'Habits',
    shortcut: 'N',
    keywords: const ['create'],
    onSelected: () => ran.add('New habit'),
  ),
  const MinimalCommandItem('Export as CSV', group: 'Habits'),
  MinimalCommandItem(
    'Mark Morning run done',
    group: 'Habits',
    detail: 'HAB-4',
    onSelected: () => ran.add('Mark Morning run done'),
  ),
  MinimalCommandItem(
    'Go to Today',
    group: 'Navigate',
    shortcut: 'G T',
    onSelected: () => ran.add('Go to Today'),
  ),
];

void main() {
  group('MinimalTable', () {
    testWidgets('prints an uppercase header and every cell', (tester) async {
      await tester.pumpWidget(
        _app(MinimalTable(columns: _columns, rows: _rows())),
      );
      expect(find.text('CUSTOMER'), findsOneWidget);
      expect(find.text('Hanna Berg'), findsOneWidget);
      expect(find.text('Late'), findsOneWidget);
      expect(find.text('Picked up'), findsOneWidget);
    });

    testWidgets('a row tap reports its index', (tester) async {
      int? tapped;
      await tester.pumpWidget(
        _app(
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
        _app(
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
      Widget table({int? sort, bool ascending = true}) => _app(
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
        _app(
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
        _app(
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
        _app(MinimalTable(columns: _columns, rows: _rows())),
      );
      expect(find.byType(MinimalStatusBadge), findsNWidgets(3));
    });

    testWidgets('a sortable header takes taps just above its band', (
      tester,
    ) async {
      final calls = <int>[];
      await tester.pumpWidget(
        _app(
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
      await tester.tapAt(Offset(qty.center.dx, header.top - 6));
      expect(calls, [2]);
      // Above a label header the tap is not taken.
      final customer = tester.getRect(find.text('CUSTOMER'));
      await tester.tapAt(Offset(customer.center.dx, header.top - 6));
      expect(calls, [2]);
      // Further out it is the page's again.
      await tester.tapAt(Offset(qty.center.dx, header.top - 12));
      expect(calls, [2]);
    });

    testWidgets('the sliver form pins its header in a scrolling page', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
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
        _app(
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
        _app(
          const MinimalTable(columns: _orderColumns, rows: _orderRows),
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
        _app(
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

  group('MinimalDataTable', () {
    testWidgets('a status badge stays whole while a name is cut', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          MinimalDataTable<List<String>>(
            rows: const [
              ['ORD-1041', 'Ben Okafor', 'Refunded'],
              ['ORD-1039', 'Dara Kelly', 'Pending'],
            ],
            columns: [
              MinimalDataColumn<List<String>>(
                'Order',
                value: (r) => r[0],
                mono: true,
              ),
              MinimalDataColumn<List<String>>(
                'Customer',
                value: (r) => r[1],
                flex: 2,
              ),
              MinimalDataColumn<List<String>>(
                'Status',
                value: (r) => r[2],
                cell: (context, r) => Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: MinimalStatusBadge(r[2]),
                ),
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      for (final status in ['Refunded', 'Pending']) {
        final badge = tester.renderObject<RenderParagraph>(find.text(status));
        expect(badge.didExceedMaxLines, isFalse, reason: status);
      }
    });
  });

  group('MinimalProperty', () {
    testWidgets('an editable row is a labelled button', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          MinimalDescriptionList(
            properties: [
              MinimalProperty(
                icon: LucideIcons.circleDot,
                label: 'Status',
                value: 'Active',
                tone: MinimalTone.success,
                onPressed: () => taps++,
              ),
              const MinimalProperty(
                icon: LucideIcons.flame,
                label: 'Streak',
                value: '12d',
                mono: true,
                detail: 'best 21d',
              ),
              const MinimalProperty(icon: LucideIcons.target, label: 'Goal'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Status'));
      expect(taps, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Status, Active')),
        isSemantics(isButton: true, isEnabled: true),
      );
      expect(find.text('Empty'), findsOneWidget);
      expect(
        find.textContaining('best 21d', findRichText: true),
        findsOneWidget,
      );
      // A row that only reads is not a control.
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Streak'))),
        isSemantics(isButton: false),
      );
    });

    testWidgets('a widget value speaks for itself after the label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          MinimalDescriptionList(
            properties: [
              MinimalProperty(
                icon: LucideIcons.user,
                label: 'Owner',
                onPressed: () {},
                child: const Text('Ana Berg'),
              ),
              MinimalProperty(
                icon: LucideIcons.user,
                label: 'Reviewer',
                semanticValue: 'Ines Duarte',
                onPressed: () {},
                child: const Text('ID'),
              ),
              const MinimalProperty(
                icon: LucideIcons.flame,
                label: 'Streak',
                value: '12d',
                mono: true,
                detail: 'best 21d',
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Owner, Empty'), findsNothing);
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(RegExp(r'^Owner\s+Ana Berg$')),
        ),
        isSemantics(isButton: true, isEnabled: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Reviewer, Ines Duarte')),
        isSemantics(isButton: true),
      );
      expect(find.bySemanticsLabel('Streak, 12d, best 21d'), findsOneWidget);
    });

    testWidgets('a pill announces its property and state', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          MinimalPropertyBar(
            pills: [
              MinimalPropertyPill(
                icon: LucideIcons.bell,
                label: '21:30',
                name: 'Reminder',
                mono: true,
                hasValue: true,
                onPressed: () => taps++,
              ),
              MinimalPropertyPill(
                icon: LucideIcons.target,
                label: 'Goal',
                onPressed: () => taps++,
              ),
              const MinimalPropertyPill(icon: LucideIcons.lock, label: 'Area'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('21:30'));
      await tester.tap(find.text('Goal'));
      expect(taps, 2);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Reminder, 21:30')),
        isSemantics(isButton: true, isEnabled: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Goal, not set')),
        isSemantics(isButton: true, isEnabled: true),
      );
      // No handler: disabled, and a tap does nothing.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Area, not set')),
        isSemantics(isButton: true, isEnabled: false),
      );
      await tester.tap(find.text('Area'), warnIfMissed: false);
      expect(taps, 2);
    });
  });

  group('MinimalBreadcrumb', () {
    testWidgets('ancestors are controls, the current step is not', (
      tester,
    ) async {
      var back = 0;
      await tester.pumpWidget(
        _app(
          MinimalBreadcrumb(
            crumbs: [
              MinimalBreadcrumbItem('Habits', onPressed: () => back++),
              const MinimalBreadcrumbItem('HAB-4', mono: true),
            ],
          ),
        ),
      );
      expect(find.text('/'), findsOneWidget);
      await tester.tap(find.text('Habits'));
      expect(back, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Habits')),
        isSemantics(isButton: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('HAB-4')),
        isSemantics(isButton: false, isSelected: true),
      );
    });
  });

  testWidgets('a tappable crumb has the full 44 px tap band', (tester) async {
    var back = 0;
    await tester.pumpWidget(
      _app(
        MinimalBreadcrumb(
          crumbs: [
            MinimalBreadcrumbItem('Habits', onPressed: () => back++),
            const MinimalBreadcrumbItem('HAB-4', mono: true),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byType(MinimalBreadcrumb)).height, 44);
    final crumb = tester.getRect(find.bySemanticsLabel('Habits'));
    await tester.tapAt(Offset(crumb.center.dx, crumb.top - 6));
    await tester.tapAt(Offset(crumb.center.dx, crumb.bottom + 6));
    expect(back, 2);
    // A path of context alone is as tall as its text.
    await tester.pumpWidget(
      _app(
        const MinimalBreadcrumb(
          crumbs: [
            MinimalBreadcrumbItem('Habits'),
            MinimalBreadcrumbItem('HAB-4', mono: true),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byType(MinimalBreadcrumb)).height, lessThan(44));
  });

  testWidgets('a long path shortens its longest step, never overflows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const MinimalBreadcrumb(
          crumbs: [
            MinimalBreadcrumbItem('Orders'),
            MinimalBreadcrumbItem('Café Morgen, weekly bread and pastry order'),
            MinimalBreadcrumbItem('#1045', mono: true),
          ],
        ),
        width: 320,
      ),
    );
    expect(tester.takeException(), isNull);
    final orders = tester.renderObject<RenderParagraph>(find.text('Orders'));
    expect(orders.didExceedMaxLines, isFalse);
    final long = tester.renderObject<RenderParagraph>(
      find.text('Café Morgen, weekly bread and pastry order'),
    );
    expect(long.didExceedMaxLines, isTrue);
    expect(tester.getRect(find.text('#1045')).right, lessThanOrEqualTo(320));
  });

  group('MinimalTimeline', () {
    testWidgets('prints a mono stamp and the event, and opens it', (
      tester,
    ) async {
      var opened = 0;
      await tester.pumpWidget(
        _app(
          MinimalTimeline(
            entries: [
              MinimalActivity(
                at: DateTime(2026, 8, 27, 7, 40),
                text: 'Marked done',
                detail: 'note added',
                onPressed: () => opened++,
              ),
              MinimalActivity(
                at: DateTime(2026, 8, 19, 20, 15),
                actor: 'Ana',
                text: 'moved the reminder',
              ),
            ],
          ),
        ),
      );
      expect(find.text('27 Aug 07:40'), findsOneWidget);
      await tester.tap(find.text('27 Aug 07:40'));
      expect(opened, 1);
      expect(
        tester.getSemantics(
          find.bySemanticsLabel('27 Aug 07:40, Marked done, note added'),
        ),
        isSemantics(isButton: true),
      );
      expect(
        find.bySemanticsLabel('19 Aug 20:15, Ana, moved the reminder'),
        findsOneWidget,
      );
    });

    testWidgets('a figure the event set prints after its words, in mono', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          MinimalTimeline(
            entries: [
              MinimalActivity(
                at: DateTime(2026, 9, 24, 17, 5),
                actor: 'Katherine',
                text: 'set it due',
                figure: '25 Sep',
              ),
            ],
          ),
        ),
      );
      final t = MinimalThemeData.preset('standard', Brightness.light);
      final event = tester.widget<RichText>(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText() == 'Katherine set it due 25 Sep',
        ),
      );
      final faces = <String, TextStyle?>{};
      event.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) {
          faces[span.text!] = span.style;
        }
        return true;
      });
      expect(faces['set it due']?.fontFamily, t.bodySmall.fontFamily);
      expect(faces['25 Sep']?.fontFamily, t.mono.fontFamily);
      // At the event's size, so the line keeps one measure.
      expect(faces['25 Sep']?.fontSize, t.bodySmall.fontSize);
      expect(
        find.bySemanticsLabel('24 Sep 17:05, Katherine, set it due 25 Sep'),
        findsOneWidget,
      );
    });

    testWidgets('an empty log says so', (tester) async {
      await tester.pumpWidget(_app(const MinimalTimeline(entries: [])));
      expect(find.text('No activity yet'), findsOneWidget);
    });

    testWidgets('rules run between entries, none under the last', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          MinimalTimeline(
            entries: [
              MinimalActivity(
                at: DateTime(2026, 3, 11, 20, 15),
                text: 'Reminder moved',
              ),
              MinimalActivity(at: DateTime(2026, 3, 10, 9, 2), text: 'Created'),
            ],
          ),
        ),
      );
      bool ruled(int entry) => tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(MinimalActivity).at(entry),
              matching: find.byType(Container),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .any((d) => d.border != null);
      expect(ruled(0), isTrue);
      expect(ruled(1), isFalse);
    });

    testWidgets('with one dot in the log, every event starts on its keyline', (
      tester,
    ) async {
      // The x where [words] start in the entry that prints them.
      double startOf(String words) {
        final finder = find.byWidgetPredicate(
          (widget) =>
              widget is RichText && widget.text.toPlainText().contains(words),
        );
        final paragraph = tester.renderObject<RenderParagraph>(finder);
        final at = tester
            .widget<RichText>(finder)
            .text
            .toPlainText()
            .indexOf(words);
        final caret = paragraph.getOffsetForCaret(
          TextPosition(offset: at),
          Rect.zero,
        );
        return paragraph.localToGlobal(caret).dx;
      }

      await tester.pumpWidget(
        _app(
          MinimalTimeline(
            entries: [
              MinimalActivity(
                at: DateTime(2026, 3, 12, 7, 12),
                actor: 'Ana',
                text: 'marked it done',
                tone: MinimalTone.success,
              ),
              MinimalActivity(
                at: DateTime(2026, 3, 11, 20, 15),
                text: 'Reminder moved',
              ),
              MinimalActivity(at: DateTime(2026, 3, 10, 9, 2), text: 'Created'),
            ],
          ),
        ),
      );
      final keyline = startOf('Ana');
      expect(startOf('Reminder moved'), moreOrLessEquals(keyline));
      expect(startOf('Created'), moreOrLessEquals(keyline));

      // A log with no dots keeps no slot: its words start after the gap.
      await tester.pumpWidget(
        _app(
          MinimalTimeline(
            entries: [
              MinimalActivity(
                at: DateTime(2026, 3, 11, 20, 15),
                text: 'Reminder moved',
              ),
            ],
          ),
        ),
      );
      expect(startOf('Reminder moved'), lessThan(keyline - 10));
    });
  });

  group('MinimalTreeView', () {
    testWidgets('rows stand in the ink until one is selected', (tester) async {
      final t = MinimalThemeData.preset('standard', Brightness.light);
      await tester.pumpWidget(
        _app(
          MinimalTreeView<String>(
            roots: const ['lib', 'test'],
            childrenOf: (_) => const <String>[],
            labelOf: (node) => node,
          ),
        ),
      );
      Color? ink(String row) =>
          tester.widget<Text>(find.text(row)).style?.color;
      expect(ink('lib'), t.foreground);
      expect(ink('test'), t.foreground);
      await tester.tap(find.text('lib'));
      await tester.pumpAndSettle();
      expect(ink('lib'), t.foreground);
      expect(ink('test'), t.mutedForeground);
    });
  });

  group('MinimalCodeBlock', () {
    testWidgets('copy puts the code on the clipboard and toasts', (
      tester,
    ) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      var copied = 0;
      await tester.pumpWidget(
        _app(
          MinimalCodeBlock(
            'curl https://api.ritual.app',
            label: 'bash',
            onCopy: () => copied++,
          ),
        ),
      );
      expect(find.text('BASH'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Copy'));
      await tester.pump();
      expect(clipboard, 'curl https://api.ritual.app');
      expect(copied, 1);
      expect(find.text('Copied to clipboard'), findsOneWidget);
      await tester.pump(MinimalChromeMetrics.toast);
      await tester.pump();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    testWidgets('copyable: false drops the action; key caps print', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Column(
            children: [
              MinimalCodeBlock('HAB-4', copyable: false, lineNumbers: true),
              MinimalKbd('⌘'),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Copy'), findsNothing);
      // The mono face has no ⌘: the cap draws it as a glyph, named.
      expect(find.text('⌘'), findsNothing);
      expect(find.bySemanticsLabel('Command'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });

  group('MinimalCodeBlock line numbers', () {
    testWidgets('wrapped, each number stays beside its own line', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const MinimalCodeBlock(
            'id: HAB-4\n'
            'note: out the door before 8, any distance counts, a run logged '
            'before 08:00 keeps the streak\n'
            'streak: 12',
            wrap: true,
            lineNumbers: true,
            copyable: false,
          ),
          width: 240,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(find.text('3')).dy,
        tester.getTopLeft(find.text('streak: 12')).dy,
      );
      // The middle line wrapped, and the third number waited for it.
      expect(
        tester.getTopLeft(find.text('3')).dy -
            tester.getTopLeft(find.text('2')).dy,
        greaterThan(18),
      );
    });

    testWidgets('the number column fits its numbers at text scale 1.3', (
      tester,
    ) async {
      final code = [for (var i = 1; i <= 120; i++) 'line $i'].join('\n');
      final numbers = [for (var i = 1; i <= 120; i++) '$i'].join('\n');
      await tester.pumpWidget(
        _app(
          _scaled(MinimalCodeBlock(code, lineNumbers: true, copyable: false)),
        ),
      );
      final column = tester.renderObject<RenderParagraph>(find.text(numbers));
      expect(
        column.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(column.size.width + 0.01),
      );
    });
  });

  group('MinimalCommand', () {
    testWidgets('typing filters; nothing matching shows the empty state', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(MinimalCommand(actions: _actions([]), autofocus: false)),
      );
      // Unfocused at first, the palette takes focus from its second frame.
      await tester.pump();
      await tester.pump();
      expect(find.text('HABITS'), findsOneWidget);
      expect(find.text('NAVIGATE'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'create');
      await tester.pump();
      expect(find.bySemanticsLabel('New habit, N'), findsOneWidget);
      expect(find.text('Go to Today'), findsNothing);
      await tester.enterText(find.byType(TextField), 'invoice');
      await tester.pump();
      expect(find.text('No results'), findsOneWidget);
    });

    testWidgets('at text scale 1.3 a result row grows with its words; a '
        'group opens on more air than lies between rows', (tester) async {
      await tester.pumpWidget(
        _app(_scaled(MinimalCommand(actions: _actions([]), autofocus: false))),
      );
      await tester.pump();
      await tester.pump();
      final t = MinimalThemeData.preset('standard', Brightness.light);
      Rect row(Finder words) => tester.getRect(
        find.ancestor(of: words, matching: find.byType(Container)).first,
      );
      expect(
        row(find.text('Go to Today')).height,
        greaterThan(t.rowHeightCompact),
      );
      final above = row(find.textContaining('Mark Morning run done'));
      expect(
        tester.getRect(find.text('NAVIGATE')).top - above.bottom,
        moreOrLessEquals(MinimalSpacing.s16, epsilon: 0.5),
      );
    });

    testWidgets('arrows move past disabled actions; Enter runs', (
      tester,
    ) async {
      final chosen = <String>[];
      await tester.pumpWidget(
        _app(
          MinimalCommand(
            actions: _actions([]),
            onSelected: (a) => chosen.add(a.label),
          ),
        ),
      );
      await tester.pump();
      void highlighted(String label) => expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(isSelected: true),
      );
      highlighted('New habit, N');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      // Export has no handler: the highlight skips it.
      highlighted('Mark Morning run done');
      expect(
        tester.getSemantics(find.bySemanticsLabel('Export as CSV')),
        isSemantics(isEnabled: false),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      highlighted('New habit, N');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      highlighted('Go to Today, G T');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(chosen, ['Go to Today']);
      await tester.tap(find.text('Export as CSV'), warnIfMissed: false);
      expect(chosen, ['Go to Today']);
    });

    testWidgets('show runs the chosen action after the card closes', (
      tester,
    ) async {
      final ran = <String>[];
      MinimalCommandItem? result;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => MinimalButton(
              'Open',
              onPressed: () async => result = await MinimalCommand.show(
                context,
                subtitle: 'Habits',
                actions: _actions(ran),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // The subtitle stands as a pill over the field.
      expect(find.text('Habits'), findsOneWidget);
      // The route is named Commands, and so is its list of results.
      expect(find.bySemanticsLabel('Commands'), findsNWidgets(2));
      await tester.tap(find.text('Go to Today'));
      await tester.pumpAndSettle();
      expect(find.text('Go to Today'), findsNothing);
      expect(ran, ['Go to Today']);
      expect(result?.label, 'Go to Today');
    });

    testWidgets('the shown palette stands its field as far from the top as '
        'from the sides', (tester) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => MinimalButton(
              'Open',
              onPressed: () =>
                  MinimalCommand.show(context, actions: _actions(<String>[])),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      bool framed(Widget w, {required bool shadowed}) {
        if (w is! DecoratedBox) return false;
        final d = w.decoration;
        return d is BoxDecoration &&
            d.border != null &&
            (d.boxShadow != null) == shadowed;
      }

      // The card wears the large shadow; the field's box is the nearest
      // rim round its hint.
      final card = find.byWidgetPredicate((w) => framed(w, shadowed: true));
      final box = find
          .ancestor(
            of: find.text('Type a command or search'),
            matching: find.byWidgetPredicate((w) => framed(w, shadowed: false)),
          )
          .first;
      final outer = tester.getRect(card.first);
      final field = tester.getRect(box);
      expect(field.top - outer.top, moreOrLessEquals(field.left - outer.left));
    });

    testWidgets('a shortcut is announced by its keys\' names', (tester) async {
      await tester.pumpWidget(
        _app(
          MinimalCommand(
            autofocus: false,
            actions: [
              MinimalCommandItem(
                'Open commands',
                shortcut: '⌘ ⇧ K',
                onSelected: () {},
              ),
            ],
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Open commands, Command Shift K'),
        findsOneWidget,
      );
    });

    testWidgets('a pointer moves the highlight; a rebuild keeps it', (
      tester,
    ) async {
      late StateSetter rebuild;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              // A fresh list on every build, as a page often builds it.
              return MinimalCommand(actions: _actions([]));
            },
          ),
        ),
      );
      await tester.pump();
      void highlighted(String label) => expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(isSelected: true),
      );
      highlighted('New habit, N');
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Go to Today')));
      await tester.pump();
      highlighted('Go to Today, G T');
      await mouse.moveTo(Offset.zero);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      highlighted('Mark Morning run done');
      rebuild(() {});
      await tester.pump();
      highlighted('Mark Morning run done');
    });
  });

  // Last, because the faces stay loaded for every test after them: the
  // default test font sets every glyph a full em wide, which no real
  // column is sized for.
  group('with the real faces', () {
    setUpAll(minimalLoadFonts);

    testWidgets('at text scale 1.3 the orders table still fits 390 px', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _scaled(
            MinimalTable(
              columns: _orderColumns,
              rows: _orderRows,
              onSort: (_, _) {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(MinimalTable),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      final status = tester.getRect(find.text('STATUS'));
      expect(status.left, greaterThan(0));
      expect(status.right, lessThanOrEqualTo(390));
      expect(tester.getRect(find.text('Late')).right, lessThanOrEqualTo(390));
      // The fixed columns grew with their figures, no further.
      final id = tester.renderObject<RenderParagraph>(find.text('1047'));
      expect(id.didExceedMaxLines, isFalse);
    });

    testWidgets('two columns of figures keep 16 px apart when room is short', (
      tester,
    ) async {
      // A phone card's table at text scale 1.3: the other gaps close to 8,
      // but Café Morgen's 24 and its 10:00 still read as two figures.
      await tester.pumpWidget(
        _app(
          _scaled(
            MinimalTable(
              columns: const [
                MinimalColumn('#', width: 40, mono: true, sortable: true),
                MinimalColumn('Customer'),
                MinimalColumn('Qty', width: 38, numeric: true, sortable: true),
                MinimalColumn('Due', width: 56, numeric: true, sortable: true),
                MinimalColumn('Status', width: 84, alignEnd: true),
              ],
              rows: _orderRows,
              onSort: (_, _) {},
            ),
          ),
          width: 352,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.text('10:00')).left -
            tester.getRect(find.text('24')).right,
        greaterThanOrEqualTo(16),
      );
    });
  });
}
