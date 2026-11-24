import 'dart:ui' show PointerDeviceKind, Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const double _extent = 40;

// Month and year are 0-based indices; the year column starts at 2020.
int _daysIn(int year, int month) => DateTime(year, month + 2, 0).day;

/// A date wheel in month, day, year order: the day column, between the
/// other two, follows both (February of a leap year); 2020 is before the
/// minimum.
List<RawPickerColumn> _dateColumns(List<int> s) => [
  RawPickerColumn(
    itemCount: 12,
    itemLabel: (i) => _months[i],
    semanticLabel: 'Month',
  ),
  RawPickerColumn(
    itemCount: _daysIn(2020 + s[2], s[0]),
    itemLabel: (i) => '${i + 1}',
    semanticLabel: 'Day',
  ),
  RawPickerColumn(
    itemCount: 11,
    itemLabel: (i) => '${2020 + i}',
    semanticLabel: 'Year',
    minIndex: 1,
  ),
];

late _HostState _host;
final List<RawPickerItemDetails> _painted = [];
final Map<int, Set<WidgetState>> _frames = {};

class _Host extends StatefulWidget {
  const _Host({
    this.selection = const [2, 14, 6],
    this.columns = _dateColumns,
    this.enabled = true,
  });

  final List<int> selection;
  final List<RawPickerColumn> Function(List<int> selection) columns;
  final bool enabled;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late List<int> selection = widget.selection;
  int changes = 0;

  void select(List<int> next) => setState(() => selection = next);

  @override
  Widget build(BuildContext context) {
    _host = this;
    // The bare reference painter: each row's name, grey when it can't be
    // chosen, and a column frame that only reports its states.
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 600,
        child: RawPicker(
          semanticLabel: 'Date',
          columns: widget.columns,
          selection: selection,
          itemExtent: _extent,
          onChanged: widget.enabled
              ? (next) => setState(() {
                  changes++;
                  selection = next;
                })
              : null,
          itemBuilder: (context, details) {
            _painted.add(details);
            return Center(
              child: Text(
                details.label,
                style: TextStyle(
                  color: details.enabled
                      ? const Color(0xFF000000)
                      : const Color(0xFF999999),
                ),
              ),
            );
          },
          columnBuilder: (context, details, wheel) {
            _frames[details.column] = details.states;
            return wheel;
          },
        ),
      ),
    );
  }
}

Finder _columnNode(String label) => find.bySemanticsLabel(label);

bool _focusedOn(WidgetTester tester, String label) =>
    _node(tester, label).getSemanticsData().flagsCollection.isFocused ==
    Tristate.isTrue;

SemanticsNode _node(WidgetTester tester, String label) =>
    semanticsOf(tester, _columnNode(label));

/// The row a column's wheel stands on.
int _wheelRow(WidgetTester tester, int column) {
  final wheels = tester
      .widgetList<ListWheelScrollView>(find.byType(ListWheelScrollView))
      .toList();
  final controller = wheels[column].controller! as FixedExtentScrollController;
  return controller.selectedItem;
}

void main() {
  setUp(() {
    _painted.clear();
    _frames.clear();
  });

  testWidgets('a mouse drag turns a wheel under the default scroll behavior', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const _Host()));
    final before = _wheelRow(tester, 0);
    await tester.drag(
      find.text('March'),
      const Offset(0, -100),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(_wheelRow(tester, 0), greaterThan(before));
    expect(_host.selection.first, _wheelRow(tester, 0));
  });

  behaviourContract(
    'RawPicker',
    build: (c) => _Host(enabled: c.enabled),
    node: () => _columnNode('Month'),
    root: () => find.byType(RawPicker),
    semantics: isSemantics(
      label: 'Month',
      value: 'March',
      increasedValue: 'April',
      decreasedValue: 'February',
      isFocusable: true,
      hasEnabledState: true,
      isEnabled: true,
      hasIncreaseAction: true,
      hasDecreaseAction: true,
    ),
    disabled: isSemantics(
      label: 'Month',
      value: 'March',
      hasEnabledState: true,
      isEnabled: false,
      isFocusable: false,
      hasIncreaseAction: false,
      hasDecreaseAction: false,
    ),
    // The rows are drawn, not read: a screen reader hears the column.
    hidden: const ['April', '14'],
    keyboard: (p) async {
      final t = p.tester;
      await p.tabInto();
      expect(_frames[0], contains(WidgetState.focused));
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(p.data.value, 'April');
      expect(_wheelRow(t, 0), 3, reason: 'the wheel turned there');
      await p.key(LogicalKeyboardKey.arrowUp);
      expect(p.data.value, 'March');
      await p.key(LogicalKeyboardKey.end);
      expect(p.data.value, 'December');
      await p.key(LogicalKeyboardKey.home);
      expect(p.data.value, 'January');
      await p.key(LogicalKeyboardKey.pageDown);
      expect(p.data.value, 'June');
      await p.key(LogicalKeyboardKey.pageUp);
      expect(p.data.value, 'January');
      // Typing jumps to the next row whose name starts with it.
      await p.key(LogicalKeyboardKey.keyN);
      expect(p.data.value, 'November');
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(_focusedOn(t, 'Day'), isTrue);
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(p.focused, isTrue);
      await p.tab();
      expect(_focusedOn(t, 'Day'), isTrue, reason: 'Tab goes column to column');
    },
    rtl: (p) async {
      final t = p.tester;
      await p.tabInto();
      // Right to left, the day column is drawn left of the month.
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(_focusedOn(t, 'Day'), isTrue);
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(p.focused, isTrue);
    },
    motion: (p) async {
      await p.tabInto();
      await p.tester.sendKeyEvent(LogicalKeyboardKey.end);
      await p.tester.pump();
    },
  );

  testWidgets('a screen reader steps a column', (tester) async {
    await tester.pumpWidget(harness(const _Host()));
    final owner = semanticsOwner();
    owner.performAction(_node(tester, 'Month').id, SemanticsAction.increase);
    await tester.pumpAndSettle();
    expect(_host.selection, [3, 14, 6]);
    expect(_node(tester, 'Month').getSemanticsData().value, 'April');
    owner.performAction(_node(tester, 'Year').id, SemanticsAction.decrease);
    await tester.pumpAndSettle();
    expect(_host.selection[2], 5);
    expect(_wheelRow(tester, 2), 5);
  });

  testWidgets('the whole picker is named, and each column', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(harness(const _Host()));
    expect(find.bySemanticsLabel('Date'), findsOneWidget);
    expect(_node(tester, 'Year').getSemanticsData().value, '2026');
    handle.dispose();
  });

  group('linked columns', () {
    testWidgets('a month with fewer days moves the day back', (tester) async {
      await tester.pumpWidget(
        harness(const _Host(selection: [0, 30, 1])), // 31 January 2021
      );
      await tester.pumpAndSettle();
      semanticsOwner().performAction(
        _node(tester, 'Month').id,
        SemanticsAction.increase,
      );
      await tester.pumpAndSettle();
      expect(_host.selection, [1, 27, 1], reason: '28 February 2021');
      expect(_host.changes, 1, reason: 'one change, already whole');
      expect(_wheelRow(tester, 1), 27, reason: 'the day wheel turned there');
    });

    testWidgets('a later column refills an earlier one', (tester) async {
      await tester.pumpWidget(
        harness(const _Host(selection: [1, 28, 4])), // 29 February 2024
      );
      await tester.pumpAndSettle();
      semanticsOwner().performAction(
        _node(tester, 'Year').id,
        SemanticsAction.increase,
      );
      await tester.pumpAndSettle();
      expect(_host.selection, [1, 27, 5], reason: '28 February 2025');
    });

    testWidgets('a parent\'s new selection turns the wheels on a spring', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const _Host()));
      _host.select([8, 2, 3]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(_wheelRow(tester, 0), isNot(8), reason: 'it turns, not jumps');
      await tester.pumpAndSettle();
      expect([for (var c = 0; c < 3; c++) _wheelRow(tester, c)], [8, 2, 3]);
      expect(_host.changes, 0, reason: 'the parent set it: no onChanged');
    });
  });

  group('a wheel comes to rest on a live row', () {
    testWidgets('a drag onto a row before the minimum turns back', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const _Host(selection: [2, 14, 1])));
      await tester.pumpAndSettle();
      // Down by a row: 2020, before the minimum.
      await tester.drag(find.text('2021'), const Offset(0, _extent));
      await tester.pumpAndSettle();
      expect(_wheelRow(tester, 2), 1);
      expect(_host.selection[2], 1);
      final row2020 = _painted.lastWhere((d) => d.label == '2020');
      expect(row2020.enabled, isFalse, reason: 'drawn disabled');
    });

    testWidgets('a refused row is passed the way the wheel turned', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(const _Host(selection: [2], columns: _slots)),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.text('11:00'), const Offset(0, -_extent));
      await tester.pumpAndSettle();
      expect(_host.selection, [4], reason: 'past 12:00, the way it turned');
      expect(_wheelRow(tester, 0), 4);
      // The keys skip it both ways.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(_host.selection, [2]);
    });

    testWidgets('a fling settles on a row and picks it', (tester) async {
      await tester.pumpWidget(harness(const _Host()));
      await tester.pumpAndSettle();
      await tester.fling(find.text('March'), const Offset(0, -150), 800);
      await tester.pumpAndSettle();
      final month = _host.selection[0];
      expect(month, greaterThan(2));
      expect(_wheelRow(tester, 0), month);
      final wheel = tester.widget<ListWheelScrollView>(
        find.byType(ListWheelScrollView).first,
      );
      final pixels = wheel.controller!.position.pixels;
      expect(pixels % _extent, closeTo(0, 0.01), reason: 'on a row exactly');
    });

    testWidgets('a tap on a row turns to it', (tester) async {
      await tester.pumpWidget(harness(const _Host()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('April'));
      await tester.pumpAndSettle();
      expect(_host.selection[0], 3);
    });
  });

  testWidgets('a looping column wraps, and goes the short way round', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(const _Host(selection: [23], columns: _hours)),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_host.selection, [0]);
    final controller =
        tester
                .widget<ListWheelScrollView>(find.byType(ListWheelScrollView))
                .controller!
            as FixedExtentScrollController;
    expect(controller.selectedItem, 24, reason: 'one row on, not 23 back');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(_host.selection, [23]);
    // Typing two digits within a second finds "12".
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pumpAndSettle();
    expect(_host.selection, [12]);
    // A second later the buffer is gone: "1" finds the next row from 12.
    await tester.pump(const Duration(seconds: 2));
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pumpAndSettle();
    expect(_host.selection, [13]);
  });

  testWidgets('a row crossing the centre plays a step', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(
      harness(
        RawHapticsScope(
          haptics: RawHaptics(selectionChanged: () => log.add('step')),
          child: const _Host(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(log, isEmpty, reason: 'showing plays nothing');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(log, ['step']);
    log.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(_host.selection[0], 8);
    expect(log.length, inInclusiveRange(1, 5), reason: 'at most one a frame');
  });

  testWidgets('disabled: the wheels do not turn', (tester) async {
    await tester.pumpWidget(harness(const _Host(enabled: false)));
    await tester.pumpAndSettle();
    await tester.drag(find.text('March'), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(_wheelRow(tester, 0), 2);
    expect(_frames[0], contains(WidgetState.disabled));
    expect(_painted.every((d) => !d.enabled), isTrue);
    await tester.tap(find.text('April'));
    await tester.pumpAndSettle();
    expect(_host.selection[0], 2);
  });

  testWidgets('hover and a finger show in the column\'s states', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const _Host()));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('March')));
    await tester.pump();
    expect(_frames[0], contains(WidgetState.hovered));
    await mouse.removePointer();
    final finger = await tester.startGesture(
      tester.getCenter(find.text('March')),
    );
    await finger.moveBy(const Offset(0, -30));
    await tester.pump();
    expect(_frames[0], containsAll([WidgetState.pressed, WidgetState.dragged]));
    await finger.up();
    await tester.pumpAndSettle();
    expect(_frames[0], isNot(contains(WidgetState.pressed)));
    expect(_frames[0], isNot(contains(WidgetState.dragged)));
  });

  group('RawPickerColumn', () {
    final column = RawPickerColumn(
      itemCount: 10,
      itemLabel: (i) => '$i',
      minIndex: 2,
      maxIndex: 7,
      isItemEnabled: (i) => i != 5,
    );
    final ring = RawPickerColumn(
      itemCount: 10,
      itemLabel: (i) => '$i',
      isItemEnabled: (i) => i > 1 && i < 9,
      looping: true,
    );

    test('which rows are live', () {
      expect(
        [for (var i = 0; i < 10; i++) column.isEnabled(i)],
        [
          false, false, true, true, true, false, true, true, false, false, //
        ],
      );
      expect(column.firstEnabled, 2);
      expect(column.lastEnabled, 7);
    });

    test('the nearest live row', () {
      expect(column.nearestEnabled(4), 4);
      expect(column.nearestEnabled(5), 4, reason: 'a tie goes back');
      expect(column.nearestEnabled(5, forward: true), 6);
      expect(column.nearestEnabled(0), 2);
      expect(column.nearestEnabled(30), 7, reason: 'clamped first');
      expect(column.nearestEnabled(9, forward: true), 7, reason: 'then back');
      expect(ring.nearestEnabled(0), 8, reason: 'round the end is nearer');
      expect(ring.nearestEnabled(1), 2);
      final none = RawPickerColumn(
        itemCount: 3,
        itemLabel: (i) => '$i',
        isItemEnabled: (i) => false,
      );
      expect(none.nearestEnabled(1), isNull);
      expect(none.firstEnabled, isNull);
    });

    test('steps skip refused rows and stop at the ends', () {
      expect(column.stepFrom(4, 1), 6);
      expect(column.stepFrom(6, -1), 4);
      expect(column.stepFrom(6, 5), 7);
      expect(column.stepFrom(3, -5), 2);
      expect(ring.stepFrom(8, 1), 2, reason: 'a loop wraps');
      expect(ring.stepFrom(2, -1), 8);
    });
  });

  testWidgets('its diagnostics name what it was given', (tester) async {
    await tester.pumpWidget(harness(const _Host()));
    final picker = tester.widget<RawPicker>(find.byType(RawPicker));
    final names = picker
        .toDiagnosticsNode()
        .getProperties()
        .map((p) => p.name)
        .toSet();
    expect(names, containsAll(['selection', 'onChanged', 'itemExtent']));
  });
}

List<RawPickerColumn> _slots(List<int> s) => [
  RawPickerColumn(
    itemCount: 8,
    itemLabel: (i) => '${9 + i}:00',
    semanticLabel: 'Slot',
    isItemEnabled: (i) => i != 3,
  ),
];

List<RawPickerColumn> _hours(List<int> s) => [
  RawPickerColumn(
    itemCount: 24,
    itemLabel: (i) => '$i',
    semanticLabel: 'Hour',
    looping: true,
  ),
];
