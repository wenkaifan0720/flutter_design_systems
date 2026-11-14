/// The 15 rows round 4 paints on ui_core's behaviours (coverage4.md): each
/// one builds in the look, answers a press, a drag or a key as its
/// behaviour does, and reports back through its own words (`value` and
/// `onChanged`, `onPressed`).
library;

import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/focus_ring.dart'
    show expressivePaintFocusRing;
import 'package:material_expressive_ui/src/material_expressive/internal/state_face.dart'
    show ExpressiveStateFace;

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

/// [child] filling the screen in Expressive's host.
Widget _screen(Widget child) => MaterialApp(
  home: ExpressiveHost(
    light: _theme,
    brightness: Brightness.light,
    child: child,
  ),
);

const List<ExpressiveButtonSegment<String>> _aligns =
    <ExpressiveButtonSegment<String>>[
      ExpressiveButtonSegment('start', 'Start'),
      ExpressiveButtonSegment('center', 'Centre'),
      ExpressiveButtonSegment('end', 'End'),
    ];

typedef _Row = ({String name, int amount});

const List<_Row> _rows = <_Row>[
  (name: 'Cleo', amount: 30),
  (name: 'Ada', amount: 10),
  (name: 'Ben', amount: 20),
];

DesignTableController<_Row> _table({int? pageSize}) =>
    DesignTableController<_Row>(
      rows: _rows,
      rowKey: (r) => r.name,
      pageSize: pageSize,
      columns: <DesignTableColumn<_Row>>[
        DesignTableColumn<_Row>(
          id: 'name',
          label: 'Name',
          sortKey: (r) => r.name,
        ),
        DesignTableColumn<_Row>(
          id: 'amount',
          label: 'Amount',
          numeric: true,
          sortKey: (r) => r.amount,
        ),
      ],
    );

void main() {
  group('ExpressiveToggleGroup', () {
    testWidgets('one value: a press reports the segment pressed', (
      tester,
    ) async {
      String? chosen;
      await tester.pumpWidget(
        _kit(
          ExpressiveToggleGroup<String>(
            label: 'Alignment',
            value: 'start',
            onChanged: (v) => chosen = v,
            segments: _aligns,
          ),
        ),
      );
      await tester.tap(find.text('End'));
      await tester.pumpAndSettle();
      expect(chosen, 'end');
    });

    testWidgets('several: a press adds a segment to the set', (tester) async {
      Set<String>? chosen;
      await tester.pumpWidget(
        _kit(
          ExpressiveToggleGroup<String>.multiple(
            label: 'Alignment',
            values: const <String>{'start'},
            onChanged: (v) => chosen = v,
            segments: _aligns,
          ),
        ),
      );
      await tester.tap(find.text('Centre'));
      await tester.pumpAndSettle();
      expect(chosen, <String>{'start', 'center'});
    });

    testWidgets('a focused segment\'s ring stands inside it: the next '
        'segment, 2dp on, would paint over a ring outside', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await tester.pumpWidget(
        _kit(
          ExpressiveToggleGroup<String>(
            label: 'Alignment',
            value: 'end',
            onChanged: (_) {},
            segments: _aligns,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final rings = tester
          .widgetList<CustomPaint>(
            find.byWidgetPredicate(
              (w) =>
                  w is CustomPaint &&
                  w.foregroundPainter.runtimeType.toString() == '_Ring',
            ),
          )
          .toList();
      expect(rings, hasLength(1));
      expect((rings.single.foregroundPainter! as dynamic).inward, isTrue);
    });

    testWidgets('a focused filled segment keeps the surface between its face '
        'and the ring (the selected one\'s primary reads as secondary)', (
      tester,
    ) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await tester.pumpWidget(
        _kit(
          ExpressiveToggleGroup<String>(
            label: 'Alignment',
            value: 'start',
            onChanged: (_) {},
            segments: _aligns,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final ring = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.foregroundPainter.runtimeType.toString() == '_Ring',
        ),
      );
      final t = tester.element(find.text('Start')).expressiveTheme;
      expect((ring.foregroundPainter! as dynamic).gap, t.colors.surface);
    });

    testWidgets('the inward ring paints the surface band inside it, '
        'concentric; an outward ring has its offset and no band', (
      tester,
    ) async {
      const ink = Color(0xFF625B71);
      const surface = Color(0xFFFFFBFE);
      Widget ring({required bool inward}) => Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: CustomPaint(
            size: const Size(100, 40),
            painter: _RingProbe(inward: inward, ink: ink, surface: surface),
          ),
        ),
      );
      await tester.pumpWidget(ring(inward: true));
      final box = find.byType(CustomPaint).last;
      expect(
        tester.renderObject(box),
        paints
          ..rrect(
            rrect: RRect.fromRectAndRadius(
              const Rect.fromLTRB(4, 4, 96, 36),
              const Radius.circular(8),
            ),
            color: surface,
            strokeWidth: 2,
          )
          ..rrect(
            rrect: RRect.fromRectAndRadius(
              const Rect.fromLTRB(1.5, 1.5, 98.5, 38.5),
              const Radius.circular(10.5),
            ),
            color: ink,
            strokeWidth: 3,
          ),
      );
      await tester.pumpWidget(ring(inward: false));
      expect(
        tester.renderObject(find.byType(CustomPaint).last),
        paintsExactlyCountTimes(#drawRRect, 1),
      );
    });
  });

  group('ExpressivePasswordField', () {
    testWidgets('hidden until the eye shows it', (tester) async {
      await tester.pumpWidget(
        _kit(const ExpressivePasswordField(label: 'Password')),
      );
      bool obscured() =>
          tester.widget<EditableText>(find.byType(EditableText)).obscureText;
      expect(obscured(), isTrue);
      await tester.tap(find.bySemanticsLabel('Show password'));
      await tester.pumpAndSettle();
      expect(obscured(), isFalse);
    });
  });

  group('ExpressiveInputGroup', () {
    testWidgets('as tall as an outlined text field at every density', (
      tester,
    ) async {
      for (final density in const <ExpressiveDensity>[
        ExpressiveDensity.standard,
        ExpressiveDensity.comfortable,
        ExpressiveDensity.compact,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: ExpressiveHost(
              light: _theme.copyWith(density: density),
              brightness: Brightness.light,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: SizedBox(
                  width: 390,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      ExpressiveInputGroup(
                        hintText: 'example.com',
                        leading: <Widget>[
                          ExpressiveInputGroup.text('https://'),
                        ],
                      ),
                      const ExpressiveTextField(
                        hintText: 'Trip name',
                        kind: ExpressiveTextFieldKind.outlined,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        expect(
          tester.getSize(find.byType(ExpressiveInputGroup)).height,
          tester.getSize(find.byType(ExpressiveTextField)).height,
          reason: '$density',
        );
      }
    });

    testWidgets('a press on an add-on focuses the input; edits report', (
      tester,
    ) async {
      String? text;
      await tester.pumpWidget(
        _kit(
          ExpressiveInputGroup(
            hintText: 'example.com',
            leading: <Widget>[ExpressiveInputGroup.text('https://')],
            onChanged: (v) => text = v,
          ),
        ),
      );
      await tester.tap(find.text('https://'));
      await tester.pump();
      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.focusNode.hasFocus, isTrue);
      await tester.enterText(find.byType(EditableText), 'example.com');
      expect(text, 'example.com');
    });
  });

  group('ExpressiveFormField', () {
    testWidgets('the label above, the help under; an error takes its place', (
      tester,
    ) async {
      Widget field(String? error) => _kit(
        ExpressiveFormField(
          label: 'Display name',
          help: 'Others see it',
          error: error,
          required: true,
          child: const ExpressiveTextField(hintText: 'Ada'),
        ),
      );
      await tester.pumpWidget(field(null));
      expect(find.text('Display name'), findsOneWidget);
      expect(find.text('Others see it'), findsOneWidget);
      await tester.pumpWidget(field('Give a name'));
      await tester.pump();
      expect(find.text('Others see it'), findsNothing);
      expect(find.text('Give a name'), findsOneWidget);
    });

    testWidgets('a switch keeps its own size at the label\'s start; a text '
        'field still fills the row', (tester) async {
      await tester.pumpWidget(
        _kit(
          ExpressiveFormField(
            label: 'Notify me',
            child: ExpressiveSwitch(value: true, onChanged: (_) {}),
          ),
        ),
      );
      final row = tester.getRect(find.byType(ExpressiveFormField));
      final track = tester.getRect(
        find
            .descendant(
              of: find.byType(ExpressiveSwitch),
              matching: find.byType(CustomSingleChildLayout),
            )
            .first,
      );
      expect(track.width, lessThan(80));
      expect(track.left, closeTo(row.left, 8));
      await tester.pumpWidget(
        _kit(
          const ExpressiveFormField(
            label: 'Display name',
            child: ExpressiveTextField(hintText: 'Ada'),
          ),
        ),
      );
      expect(tester.getSize(find.byType(ExpressiveTextField)).width, 390);
    });
  });

  group('ExpressiveSwitch', () {
    testWidgets('stretched by its parent, it keeps its own track at the '
        'start, and its semantics (enabled and not)', (tester) async {
      final semantics = tester.ensureSemantics();
      for (final onChanged in <ValueChanged<bool>?>[(_) {}, null]) {
        await tester.pumpWidget(
          _kit(ExpressiveSwitch(value: true, onChanged: onChanged)),
        );
        final box = tester.getRect(find.byType(ExpressiveSwitch));
        expect(box.width, 390, reason: 'the column stretches it');
        Rect part(Type type) => tester.getRect(
          find
              .descendant(
                of: find.byType(ExpressiveSwitch),
                matching: find.byType(type),
              )
              .first,
        );
        final track = part(CustomSingleChildLayout);
        expect(track.width, lessThan(80));
        expect(track.left, closeTo(box.left, 8));
        expect(
          tester
              .getSemantics(find.byType(ExpressiveSwitch))
              .getSemanticsData()
              .flagsCollection
              .isToggled,
          Tristate.isTrue,
        );
      }
      semantics.dispose();
    });
  });

  group('ExpressiveMultiSelect', () {
    testWidgets('the chosen as chips; an option typed for joins them', (
      tester,
    ) async {
      List<String>? chosen;
      await tester.pumpWidget(
        _kit(
          ExpressiveMultiSelect<String>(
            label: 'Topics',
            options: const <ExpressiveSelectOption<String>>[
              ExpressiveSelectOption('design', 'Design'),
              ExpressiveSelectOption('travel', 'Travel'),
            ],
            values: const <String>['design'],
            onChanged: (v) => chosen = v,
          ),
        ),
      );
      expect(find.text('Design'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'tra');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Travel').last);
      await tester.pumpAndSettle();
      expect(chosen, <String>['design', 'travel']);
    });

    testWidgets('the input stands beside the chips while it fits: no empty '
        'line under them', (tester) async {
      // A phone's window: from 600 a multi-select keeps to a control's 320.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(560, 800);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _kit(
          ExpressiveMultiSelect<String>(
            label: 'Sizes',
            options: const <ExpressiveSelectOption<String>>[
              ExpressiveSelectOption('s', 'Small'),
              ExpressiveSelectOption('m', 'Medium'),
            ],
            values: const <String>['s', 'm'],
            onChanged: (_) {},
          ),
          // The test font's glyphs are a full em wide: room for both chips
          // and the input's 120dp on one line.
          width: 480,
        ),
      );
      final chip = tester.getRect(find.byType(ExpressiveChip).first);
      final input = tester.getRect(find.byType(EditableText));
      expect(input.center.dy, closeTo(chip.center.dy, 4));
      expect(input.left, greaterThan(chip.right));
      expect(
        tester.getSize(find.byType(ExpressiveMultiSelect<String>)).height,
        lessThan(72),
      );
    });
  });

  group('ExpressiveMenuBar', () {
    testWidgets('a menu opens under its label; an item runs and closes it', (
      tester,
    ) async {
      var opened = 0;
      await tester.pumpWidget(
        _kit(
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ExpressiveMenuBar(
              menus: <ExpressiveMenuBarEntry>[
                ExpressiveMenuBarEntry(
                  'File',
                  children: <ExpressiveMenuBarEntry>[
                    ExpressiveMenuBarEntry('Open', onPressed: () => opened++),
                  ],
                ),
                ExpressiveMenuBarEntry(
                  'Edit',
                  children: <ExpressiveMenuBarEntry>[
                    ExpressiveMenuBarEntry('Undo', onPressed: () {}),
                  ],
                ),
              ],
            ),
          ),
          width: 800,
        ),
      );
      expect(find.text('Open'), findsNothing);
      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(find.text('Open'), findsNothing);
    });
  });

  group('ExpressiveCalendar', () {
    testWidgets('a day pressed is the value', (tester) async {
      DateTime? chosen;
      await tester.pumpWidget(
        _kit(
          ExpressiveCalendar(
            firstDate: DateTime(2026),
            lastDate: DateTime(2027, 12, 31),
            currentDate: DateTime(2026, 11, 10),
            onChanged: (d) => chosen = d,
          ),
        ),
      );
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      expect(chosen, DateTime(2026, 11, 12));
    });

    testWidgets('a range: the first press starts it, the second ends it', (
      tester,
    ) async {
      DateTime? from;
      DateTime? to;
      await tester.pumpWidget(
        _kit(
          ExpressiveCalendar.range(
            firstDate: DateTime(2026),
            lastDate: DateTime(2027, 12, 31),
            currentDate: DateTime(2026, 11, 10),
            onChanged: (a, b) {
              from = a;
              to = b;
            },
          ),
        ),
      );
      await tester.tap(find.text('16'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();
      expect(from, DateTime(2026, 11, 16));
      expect(to, DateTime(2026, 11, 20));
    });
  });

  group('ExpressiveColorPicker', () {
    testWidgets('its hex shows the colour; a hex typed picks one', (
      tester,
    ) async {
      Color? chosen;
      await tester.pumpWidget(
        _kit(
          ExpressiveColorPicker(
            value: const Color(0xFF6750A4),
            onChanged: (c) => chosen = c,
          ),
        ),
      );
      expect(find.text('#6750A4'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), '#00FF00');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(chosen, const Color(0xFF00FF00));
    });

    testWidgets('a parent rebuilding with a new value reports nothing', (
      tester,
    ) async {
      var reports = 0;
      Widget picker(Color c) =>
          _kit(ExpressiveColorPicker(value: c, onChanged: (_) => reports++));
      await tester.pumpWidget(picker(const Color(0xFF6750A4)));
      await tester.pumpWidget(picker(const Color(0xFF123456)));
      await tester.pump();
      expect(reports, 0);
      expect(find.text('#123456'), findsOneWidget);
    });
  });

  group('ExpressiveDataTable', () {
    testWidgets('a header sorts; a row press chooses it', (tester) async {
      final table = _table();
      addTearDown(table.dispose);
      await tester.pumpWidget(
        _kit(
          ExpressiveDataTable<_Row>(
            controller: table,
            cellBuilder: (context, r, column) =>
                Text(column.id == 'name' ? r.name : '${r.amount}'),
          ),
          width: 600,
        ),
      );
      await tester.tap(find.text('Amount'));
      await tester.pumpAndSettle();
      expect(table.sortDirection, DesignSortDirection.ascending);
      expect(table.pageRows.first.name, 'Ada');
      final ada = tester.getTopLeft(find.text('Ada'));
      final cleo = tester.getTopLeft(find.text('Cleo'));
      expect(ada.dy, lessThan(cleo.dy));
      await tester.tap(find.text('Ben'));
      await tester.pumpAndSettle();
      expect(table.selectedRows.map((r) => r.name), <String>['Ben']);
    });

    testWidgets('a numeric header ends where its numbers do, sorted or not', (
      tester,
    ) async {
      final table = _table();
      addTearDown(table.dispose);
      await tester.pumpWidget(
        _kit(
          ExpressiveDataTable<_Row>(
            controller: table,
            cellBuilder: (context, r, column) =>
                Text(column.id == 'name' ? r.name : '${r.amount}'),
          ),
          width: 600,
        ),
      );
      double end(String text) => tester.getTopRight(find.text(text)).dx;
      final number = '${table.pageRows.first.amount}';
      expect(end('Amount'), moreOrLessEquals(end(number), epsilon: 0.5));
      await tester.tap(find.text('Amount'));
      await tester.pumpAndSettle();
      final first = '${table.pageRows.first.amount}';
      expect(end('Amount'), moreOrLessEquals(end(first), epsilon: 0.5));
    });

    testWidgets('past a page, the pagination turns it', (tester) async {
      final table = _table(pageSize: 2);
      addTearDown(table.dispose);
      await tester.pumpWidget(
        _kit(
          ExpressiveDataTable<_Row>(
            controller: table,
            selectable: false,
            cellBuilder: (context, r, column) =>
                Text(column.id == 'name' ? r.name : '${r.amount}'),
          ),
          width: 600,
        ),
      );
      expect(find.byType(ExpressivePagination), findsOneWidget);
      expect(find.text('Ben'), findsNothing);
      table.goToPage(1);
      await tester.pumpAndSettle();
      expect(find.text('Ben'), findsOneWidget);
    });
  });

  group('ExpressiveScrollArea', () {
    testWidgets('focused, the arrows scroll it', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        _kit(
          SizedBox(
            height: 200,
            child: ExpressiveScrollArea(
              controller: scroll,
              child: ListView(
                controller: scroll,
                children: <Widget>[
                  for (var i = 0; i < 40; i++)
                    SizedBox(height: 40, child: Text('Row $i')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(scroll.offset, greaterThan(0));
    });

    testWidgets('always shown, the thumb stands at rest before any scroll', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        _kit(
          SizedBox(
            height: 240,
            child: ExpressiveScrollArea(
              controller: scroll,
              alwaysShown: true,
              child: ListView.builder(
                controller: scroll,
                padding: const EdgeInsets.all(16),
                itemCount: 24,
                itemBuilder: (context, i) => Text('Version 1.$i'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final thumb = find.descendant(
        of: find.byType(ExpressiveScrollArea),
        matching: find.byWidgetPredicate(
          (w) => w is DecoratedBox && w.decoration is ShapeDecoration,
        ),
      );
      expect(thumb, findsOneWidget);
      expect(tester.getSize(thumb).width, 8);
      expect(tester.getSize(thumb).height, greaterThan(40));
      for (final fade in tester.widgetList<Opacity>(
        find.ancestor(of: thumb, matching: find.byType(Opacity)),
      )) {
        expect(fade.opacity, 1);
      }
    });
  });

  group('ExpressiveResizable', () {
    testWidgets('a drag on the handle moves the split', (tester) async {
      final shares = <double>[];
      await tester.pumpWidget(
        _kit(
          SizedBox(
            height: 200,
            child: ExpressiveResizable(
              onChanged: shares.add,
              first: const Text('Folders'),
              second: const Text('Messages'),
            ),
          ),
          width: 600,
        ),
      );
      final handle = tester.getCenter(find.byType(ExpressiveResizable));
      await tester.dragFrom(handle, const Offset(100, 0));
      await tester.pumpAndSettle();
      expect(shares, isNotEmpty);
      expect(shares.last, greaterThan(0.5));
    });
  });

  group('ExpressiveSheet', () {
    testWidgets('show slides the side sheet in; its close button closes it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _screen(
          Builder(
            builder: (context) => Center(
              child: ExpressiveFilledButton.tonal(
                'Filters',
                onPressed: () => ExpressiveSheet.show<void>(
                  context,
                  title: 'Sort and filter',
                  builder: (context) => const Text('Open orders'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      expect(find.text('Sort and filter'), findsOneWidget);
      expect(find.text('Open orders'), findsOneWidget);
      // The scrim is labelled Close too (the barrier's dismiss); press the
      // panel's own button.
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is ExpressiveIconButton && w.semanticLabel == 'Close',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sort and filter'), findsNothing);
    });
  });

  group('targets', () {
    testWidgets('a sort header, a menu-bar title, a calendar day where '
        'seven do not fit and a multi-select\'s input are named 48dp '
        'targets; their faces keep their size', (tester) async {
      final semantics = tester.ensureSemantics();
      // Tall enough for every part at once.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(334, 1400);
      addTearDown(tester.view.reset);
      final table = _table();
      addTearDown(table.dispose);
      await tester.pumpWidget(
        _kit(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: ExpressiveMenuBar(
                  menus: <ExpressiveMenuBarEntry>[
                    ExpressiveMenuBarEntry(
                      'File',
                      children: <ExpressiveMenuBarEntry>[
                        ExpressiveMenuBarEntry('Open', onPressed: () {}),
                      ],
                    ),
                  ],
                ),
              ),
              ExpressiveDataTable<_Row>(
                controller: table,
                cellBuilder: (context, r, column) =>
                    Text(column.id == 'name' ? r.name : '${r.amount}'),
              ),
              ExpressiveCalendar(
                firstDate: DateTime(2026),
                lastDate: DateTime(2027, 12, 31),
                currentDate: DateTime(2026, 11, 10),
                onChanged: (_) {},
              ),
              ExpressiveMultiSelect<String>(
                label: 'Topics',
                options: const <ExpressiveSelectOption<String>>[
                  ExpressiveSelectOption('design', 'Design'),
                ],
                values: const <String>[],
                onChanged: (_) {},
              ),
            ],
          ),
          width: 334,
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      double faceHeight(String label) => tester
          .getSize(
            find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(ExpressiveStateFace),
                )
                .first,
          )
          .height;
      expect(faceHeight('File'), 40);
      expect(faceHeight('Amount'), 32);
      expect(tester.getSemantics(find.text('12')).rect.width, 48);
      // The multi-select's input is named on its own node.
      final input = tester.getSemantics(find.byType(EditableText));
      expect(input.label, 'Topics');
      expect(input.rect.height, greaterThanOrEqualTo(48));
      semantics.dispose();
    });
  });
}

/// Strokes Expressive's focus ring on a 100 x 40 rounded rectangle, with a
/// surface band for a filled face.
class _RingProbe extends CustomPainter {
  const _RingProbe({
    required this.inward,
    required this.ink,
    required this.surface,
  });

  final bool inward;
  final Color ink;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) => expressivePaintFocusRing(
    canvas,
    Offset.zero & size,
    const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    color: ink,
    thickness: 3,
    offset: 2,
    textDirection: TextDirection.ltr,
    inward: inward,
    gap: surface,
  );

  @override
  bool shouldRepaint(_RingProbe old) => old.inward != inward;
}
