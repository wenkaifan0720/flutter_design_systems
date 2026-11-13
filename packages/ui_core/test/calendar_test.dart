import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

final Map<DateTime, (DesignCalendarDay, Set<WidgetState>)> _seen = {};

// The bare reference painter: the day number in a 44 by 44 box.
// A locale whose weeks start on Monday.
class _Mondays extends DefaultDesignLocalizations {
  const _Mondays();

  @override
  int get firstDayOfWeek => DateTime.monday;
}

class _MondaysDelegate extends LocalizationsDelegate<DesignLocalizations> {
  const _MondaysDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<DesignLocalizations> load(Locale locale) =>
      SynchronousFuture<DesignLocalizations>(const _Mondays());

  @override
  bool shouldReload(_MondaysDelegate old) => false;
}

Widget _day(BuildContext context, DesignCalendarDay day, Set<WidgetState> s) {
  if (day.inMonth) _seen[day.date] = (day, s);
  return SizedBox(
    key: day.inMonth ? ValueKey('day-${day.date.month}-${day.date.day}') : null,
    height: 44,
    child: Center(child: Text('${day.date.day}')),
  );
}

DesignCalendarController _controller({
  DesignCalendarMode mode = DesignCalendarMode.single,
  DateTime? month,
  bool Function(DateTime)? selectable,
}) => DesignCalendarController(
  firstDate: DateTime(2025),
  lastDate: DateTime(2027, 12, 31),
  mode: mode,
  initialMonth: month ?? DateTime(2026, 1, 28),
  currentDate: DateTime(2026, 1, 15),
  selectable: selectable,
);

Widget _calendar(
  DesignCalendarController c, {
  int months = 1,
  FocusNode? node,
  TextDirection direction = TextDirection.ltr,
}) => harness(
  _view(c, months: months, node: node),
  textDirection: direction,
);

Widget _view(DesignCalendarController c, {int months = 1, FocusNode? node}) =>
    Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 340.0 * months,
        child: DesignCalendar(
          controller: c,
          months: months,
          focusNode: node,
          dayBuilder: _day,
          headerBuilder: (context, header) => Row(
            children: [
              Expanded(child: Text(header.label)),
              if (header.previous != null) const Text('<'),
              if (header.next != null) const Text('>'),
            ],
          ),
        ),
      ),
    );

late DesignCalendarController _cal;

bool _lit(int month, int day) =>
    _seen[DateTime(2026, month, day)]?.$2.contains(WidgetState.focused) ??
    false;

void main() {
  List<String> said(WidgetTester t) => [
    for (final a in t.takeAnnouncements()) a.message,
  ];

  behaviourContract(
    'DesignCalendar',
    build: (c) => Owned<DesignCalendarController>(
      create: () =>
          _cal = _controller(selectable: c.enabled ? null : (d) => false),
      builder: (context, c) => _view(c),
    ),
    node: () => find.byKey(const ValueKey('day-1-28')),
    semantics: isSemantics(
      label: 'Wednesday, 28 January 2026',
      isButton: true,
      hasTapAction: true,
      hasEnabledState: true,
      isEnabled: true,
    ),
    // A day that may not be chosen still takes the keyboard's day (a
    // reader browses past it), so no focus check reaches past the node.
    disabled: isSemantics(
      label: 'Wednesday, 28 January 2026',
      isButton: true,
      hasTapAction: false,
      hasEnabledState: true,
      isEnabled: false,
    ),
    keyboard: (p) async {
      final t = p.tester;
      t.takeAnnouncements();
      await p.tabInto(find.byType(DesignCalendar));
      expect(
        said(t),
        contains('Wednesday, 28 January 2026'),
        reason: 'arriving, the keyboard\'s day is told',
      );
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(said(t), contains('Thursday, 29 January 2026'));
      await p.key(LogicalKeyboardKey.enter);
      expect(_cal.selectedDate, DateTime(2026, 1, 29));
      expect(
        p.tester.getSemantics(find.byKey(const ValueKey('day-1-29'))),
        isSemantics(isSelected: true),
      );
      await p.key(LogicalKeyboardKey.pageDown);
      expect(_cal.month, DateTime(2026, 2));
      expect(said(t), anyElement(contains('February 2026')));
    },
    rtl: (p) async {
      await p.tabInto(find.byType(DesignCalendar));
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(_cal.focusedDay, DateTime(2026, 1, 29), reason: 'Left is on');
    },
    motion: (p) async {
      await p.tabInto(find.byType(DesignCalendar));
      await p.key(LogicalKeyboardKey.pageDown);
    },
  );

  setUp(_seen.clear);

  test('weeks start on the chosen weekday and cover the month', () {
    final c = _controller();
    final weeks = c.weeksOf(DateTime(2026, 3), DateTime.sunday);
    expect(weeks.first.first, DateTime(2026, 3, 1), reason: 'a Sunday');
    expect(weeks.every((w) => w.length == 7), isTrue);
    expect(weeks.last.any((d) => d == DateTime(2026, 3, 31)), isTrue);
    final monday = c.weeksOf(DateTime(2026, 3), DateTime.monday);
    expect(monday.first.first, DateTime(2026, 2, 23));
  });

  test('a range: start, then end; an earlier day starts again; it can span '
      'months; a day off the bounds or refused cannot be chosen', () {
    final c = _controller(
      mode: DesignCalendarMode.range,
      selectable: (d) => d.weekday != DateTime.sunday,
    );
    c.select(DateTime(2026, 1, 28));
    expect(c.selectedRange, DesignDateRange(DateTime(2026, 1, 28)));
    c.hovered = DateTime(2026, 2, 2);
    expect(c.preview!.contains(DateTime(2026, 1, 31)), isTrue);
    c.select(DateTime(2026, 1, 20));
    expect(c.selectedRange, DesignDateRange(DateTime(2026, 1, 20)));
    c.select(DateTime(2026, 2, 3));
    expect(
      c.selectedRange,
      DesignDateRange(DateTime(2026, 1, 20), DateTime(2026, 2, 3)),
    );
    expect(c.selectedRange!.dayCount, 15);
    expect(c.preview, isNull);
    c.select(DateTime(2026, 2, 8)); // a Sunday
    expect(
      c.selectedRange!.isComplete,
      isTrue,
      reason: 'the refused day changed nothing',
    );
    c.select(DateTime(2030));
    expect(c.selectedRange!.start, DateTime(2026, 1, 20));
  });

  test('a day at a time, never skipping or repeating one', () {
    final c = _controller(month: DateTime(2026, 3, 7));
    final seen = <DateTime>[c.focusedDay];
    for (var i = 0; i < 300; i++) {
      c.moveFocus(1);
      seen.add(c.focusedDay);
    }
    for (var i = 1; i < seen.length; i++) {
      expect(seen[i].difference(seen[i - 1]).inHours, inInclusiveRange(23, 25));
      expect(seen[i].hour, 0);
    }
  });

  testWidgets('one tab stop; arrows and pages move the keyboard\'s day, the '
      'month turns with it, Enter takes a range across months', (tester) async {
    final c = _controller(mode: DesignCalendarMode.range);
    final node = FocusNode();
    addTearDown(node.dispose);
    addTearDown(c.dispose);
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.pumpWidget(_calendar(c, node: node));
    node.requestFocus();
    await tester.pump();
    expect(_lit(1, 28), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    }
    await tester.pump();
    expect(c.month, DateTime(2026, 2), reason: 'the page turned');
    expect(_lit(2, 1), isTrue);
    expect(_seen[DateTime(2026, 2, 1)]!.$1.inPreview, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(
      c.selectedRange,
      DesignDateRange(DateTime(2026, 1, 28), DateTime(2026, 2, 1)),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(
      c.focusedDay,
      DateTime(2026, 2, 14),
      reason: 'a week on, then Saturday',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pump();
    expect(c.focusedDay, DateTime(2026, 3, 14));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(c.focusedDay, DateTime(2025, 3, 14));
  });

  testWidgets('a waiting range\'s preview ends on the pointer\'s day or the '
      'keyboard\'s, across weeks; before the start it ends nowhere', (
    tester,
  ) async {
    final c = _controller(mode: DesignCalendarMode.range);
    final node = FocusNode();
    addTearDown(node.dispose);
    addTearDown(c.dispose);
    await tester.pumpWidget(_calendar(c, node: node));
    // January's days, by what the look is told.
    List<int> where(bool Function(DesignCalendarDay day) told) => [
      for (final MapEntry(key: date, value: (day, _)) in _seen.entries)
        if (date.year == 2026 && date.month == 1 && told(day)) date.day,
    ]..sort();
    List<int> ends() => where((d) => d.isPreviewEnd);

    await tester.tap(find.byKey(const ValueKey('day-1-5')));
    await tester.pump();
    expect(where((d) => d.isRangeStart), [5], reason: 'the waiting start');
    expect(ends(), isEmpty, reason: 'no pointer yet');

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(
      tester.getCenter(find.byKey(const ValueKey('day-1-14'))),
    );
    await tester.pump();
    expect(ends(), [14], reason: 'Wednesday of the next week');
    expect(where((d) => d.inPreview), [for (var d = 5; d <= 14; d++) d]);
    await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('day-1-5'))));
    await tester.pump();
    expect(ends(), [5], reason: 'on the start, it is both ends');
    await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('day-1-3'))));
    await tester.pump();
    expect(ends(), isEmpty, reason: 'before the start');
    expect(where((d) => d.inPreview), isEmpty);
    await mouse.moveTo(const Offset(1, 599));
    await tester.pump();

    node.requestFocus();
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    }
    await tester.pump();
    expect(ends(), [8]);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(ends(), [15], reason: 'the keyboard\'s day, a week on');
    expect(where((d) => d.inPreview), [for (var d = 5; d <= 15; d++) d]);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(ends(), isEmpty, reason: 'a finished range has no preview');
    expect(where((d) => d.isRangeEnd), [15]);
  });

  testWidgets('right to left: Left is the next day', (tester) async {
    final c = _controller();
    final node = FocusNode();
    addTearDown(node.dispose);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      _calendar(c, node: node, direction: TextDirection.rtl),
    );
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(c.focusedDay, DateTime(2026, 1, 29));
    final first = tester.getRect(find.byKey(const ValueKey('day-1-4')));
    final second = tester.getRect(find.byKey(const ValueKey('day-1-5')));
    expect(
      second.left,
      lessThan(first.left),
      reason: 'the week runs right to left',
    );
  });

  testWidgets('a tap selects; a pointer previews a range; a screen reader '
      'hears whole dates and skips the neighbours\' days', (tester) async {
    final semantics = tester.ensureSemantics();
    final c = _controller(mode: DesignCalendarMode.range);
    addTearDown(c.dispose);
    await tester.pumpWidget(_calendar(c));
    await tester.tap(find.byKey(const ValueKey('day-1-5')));
    await tester.pump();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('day-1-9'))));
    await tester.pump();
    expect(_seen[DateTime(2026, 1, 7)]!.$1.inPreview, isTrue);
    expect(_seen[DateTime(2026, 1, 12)]!.$1.inPreview, isFalse);

    expect(
      tester.getSemantics(find.byKey(const ValueKey('day-1-5'))),
      isSemantics(
        label: 'Monday, 5 January 2026',
        isButton: true,
        isSelected: true,
      ),
    );
    expect(find.bySemanticsLabel('Sunday, 1 February 2026'), findsNothing);
    semantics.dispose();
  });

  testWidgets('two months: the first header goes back, the last goes on', (
    tester,
  ) async {
    final c = _controller();
    addTearDown(c.dispose);
    await tester.pumpWidget(_calendar(c, months: 2));
    expect(find.text('January 2026'), findsOneWidget);
    expect(find.text('February 2026'), findsOneWidget);
    expect(find.text('<'), findsOneWidget);
    expect(find.text('>'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('<')).dx,
      lessThan(tester.getTopLeft(find.text('February 2026')).dx),
    );
  });

  testWidgets('minDayWidth: where seven do not fit, each day keeps it, '
      'centred on its seventh; by default a day is its seventh', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final c = _controller();
    addTearDown(c.dispose);
    Widget narrow(double min) => harness(
      Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 7 * 46,
          child: DesignCalendar(
            controller: c,
            minDayWidth: min,
            dayBuilder: _day,
          ),
        ),
      ),
    );
    await tester.pumpWidget(narrow(0));
    final day = find.byKey(const ValueKey('day-1-14'));
    expect(tester.getSize(day).width, 46);
    await tester.pumpWidget(narrow(48));
    expect(tester.getSize(day).width, 48);
    expect(tester.getSemantics(day).rect.width, 48);
    // Wednesday the 14th stands in the fourth seventh, centred on it.
    final left =
        (tester.view.physicalSize.width / tester.view.devicePixelRatio -
            7 * 46) /
        2;
    expect(tester.getCenter(day).dx, closeTo(left + 3.5 * 46, 0.01));
    semantics.dispose();
  });

  test('many days: each press toggles one, the days come back in order, and '
      'clear empties every selection', () {
    final c = _controller(mode: DesignCalendarMode.multiple);
    addTearDown(c.dispose);
    var told = 0;
    c.addListener(() => told++);
    for (final d in [20, 5, 12]) {
      c.select(DateTime(2026, 1, d));
    }
    expect(c.selectedDates, [
      DateTime(2026, 1, 5),
      DateTime(2026, 1, 12),
      DateTime(2026, 1, 20),
    ]);
    final jan = DateTime(2026);
    expect(c.dayOf(DateTime(2026, 1, 12), inMonth: jan).selected, isTrue);
    c.select(DateTime(2026, 1, 12, 9, 30));
    expect(c.selectedDates, [DateTime(2026, 1, 5), DateTime(2026, 1, 20)]);
    expect(told, 4);
    c.clear();
    expect(c.selectedDates, isEmpty);
    expect(c.selectedDate, isNull);
    expect(c.selectedRange, isNull);
    expect(told, 5);

    final given = DesignCalendarController(
      firstDate: DateTime(2025),
      lastDate: DateTime(2027),
      mode: DesignCalendarMode.multiple,
      selectedDates: [DateTime(2026, 2, 3, 8), DateTime(2026, 2, 1)],
    );
    addTearDown(given.dispose);
    expect(given.selectedDates, [DateTime(2026, 2, 1), DateTime(2026, 2, 3)]);
    expect(given.month, DateTime(2026, 2), reason: 'it opens on a chosen day');
  });

  test('turn: a month on or back, the keyboard\'s day kept in bounds, and '
      'never past the first or last month', () {
    final c = DesignCalendarController(
      firstDate: DateTime(2026, 1, 10),
      lastDate: DateTime(2026, 3, 20),
      initialMonth: DateTime(2026, 1, 28),
      currentDate: DateTime(2026, 1, 15),
    );
    addTearDown(c.dispose);
    expect(c.canGoBack, isFalse);
    c.turn(1);
    expect(c.month, DateTime(2026, 2));
    expect(c.focusedDay, DateTime(2026, 2, 28));
    c.turn(1);
    expect(c.month, DateTime(2026, 3));
    expect(c.focusedDay, DateTime(2026, 3, 20), reason: 'the last day');
    expect(c.canGoForward(), isFalse);
    var told = 0;
    c.addListener(() => told++);
    c.turn(1);
    c.turn(-3);
    expect(c.month, DateTime(2026, 3));
    expect(told, 0, reason: 'a refused turn says nothing');
    c.turn(-2);
    expect(c.month, DateTime(2026, 1));
    expect(c.focusedDay, DateTime(2026, 1, 20));
  });

  test('a waiting start and a resting pointer preview a range; a pointer '
      'before the start previews nothing', () {
    final c = _controller(mode: DesignCalendarMode.range);
    addTearDown(c.dispose);
    final jan = DateTime(2026);
    c.hovered = DateTime(2026, 1, 14);
    expect(c.preview, isNull, reason: 'no start yet');
    c.select(DateTime(2026, 1, 10));
    c.hovered = DateTime(2026, 1, 14, 18);
    expect(c.hovered, DateTime(2026, 1, 14));
    expect(
      c.preview,
      DesignDateRange(DateTime(2026, 1, 10), DateTime(2026, 1, 14)),
    );
    expect(c.dayOf(DateTime(2026, 1, 12), inMonth: jan).inPreview, isTrue);
    expect(c.dayOf(DateTime(2026, 1, 15), inMonth: jan).inPreview, isFalse);
    var told = 0;
    c.addListener(() => told++);
    c.hovered = DateTime(2026, 1, 14, 9);
    expect(told, 0, reason: 'the same day again is no change');
    c.hovered = DateTime(2026, 1, 5);
    expect(c.preview, isNull);
    c.hovered = null;
    c.hovered = null;
    expect(c.hovered, isNull);
    expect(told, 2);
    c.hovered = DateTime(2026, 1, 14);
    c.select(DateTime(2026, 1, 14));
    expect(c.hovered, isNull, reason: 'a finished range drops the pointer');
    expect(
      c.selectedRange,
      DesignDateRange(DateTime(2026, 1, 10), DateTime(2026, 1, 14)),
    );
    expect(c.preview, isNull);
    final start = c.dayOf(DateTime(2026, 1, 10), inMonth: jan);
    final end = c.dayOf(DateTime(2026, 1, 14), inMonth: jan);
    expect((start.isRangeStart, start.isRangeEnd), (true, false));
    expect((end.isRangeStart, end.isRangeEnd), (false, true));
    expect(c.dayOf(DateTime(2026, 1, 12), inMonth: jan).inRange, isTrue);
  });

  test('a date range: days only, equal by its ends, and counted across a '
      'daylight-saving change', () {
    final a = DesignDateRange(
      DateTime(2026, 3, 1, 23, 59),
      DateTime(2026, 3, 31, 1),
    );
    final b = DesignDateRange(DateTime(2026, 3, 1), DateTime(2026, 3, 31));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a.isComplete, isTrue);
    expect(a.dayCount, 31);
    expect(
      DesignDateRange(DateTime(2026, 10, 1), DateTime(2026, 11, 30)).dayCount,
      61,
    );
    expect(a, isNot(DesignDateRange(DateTime(2026, 3))));
    final half = DesignDateRange(DateTime(2026, 3, 29));
    expect(half.isComplete, isFalse);
    expect(half.dayCount, 1);
    expect(half.contains(DateTime(2026, 3, 29, 12)), isTrue);
    expect(half.contains(DateTime(2026, 3, 30)), isFalse);
    expect(
      b.toString(),
      'DesignDateRange(2026-03-01 00:00:00.000, 2026-03-31 00:00:00.000)',
    );
  });

  testWidgets('Up and Down move a week, Home and End to the week\'s ends; a '
      'header turns the month; a new controller takes over', (tester) async {
    final first = _controller();
    final second = _controller(month: DateTime(2026, 6, 10));
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    final node = FocusNode();
    addTearDown(node.dispose);
    DesignCalendarHeader? header;
    Widget calendar(DesignCalendarController c) => harness(
      SizedBox(
        width: 340,
        child: DesignCalendar(
          controller: c,
          focusNode: node,
          firstWeekday: DateTime.monday,
          weekdayLabel: (w) => 'w$w',
          dayBuilder: _day,
          headerBuilder: (context, h) => Text((header = h).label),
        ),
      ),
    );
    await tester.pumpWidget(calendar(first));
    expect(find.text('w1'), findsOneWidget);
    expect(find.text('w7'), findsOneWidget);
    node.requestFocus();
    await tester.pump();
    // Wednesday the 28th of January 2026, weeks from Monday.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(first.focusedDay, DateTime(2026, 1, 21));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(first.focusedDay, DateTime(2026, 2, 4));
    expect(first.month, DateTime(2026, 2), reason: 'the keyboard turns it');
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    expect(first.focusedDay, DateTime(2026, 2, 2));
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    expect(first.focusedDay, DateTime(2026, 2, 8));
    expect(
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA),
      isFalse,
      reason: 'another key is not the calendar\'s',
    );
    await tester.pump();
    expect(header!.label, 'February 2026');
    header!.next!();
    await tester.pump();
    expect(find.text('March 2026'), findsOneWidget);
    header!.previous!();
    await tester.pump();
    expect(find.text('February 2026'), findsOneWidget);

    await tester.pumpWidget(calendar(second));
    expect(find.text('June 2026'), findsOneWidget);
    first.turn(1);
    second.turn(1);
    await tester.pump();
    expect(find.text('July 2026'), findsOneWidget, reason: 'the new one');
  });

  testWidgets('with no firstWeekday a week starts where the locale says, '
      'and Home goes there; one passed in wins', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    final node = FocusNode();
    addTearDown(node.dispose);
    Widget calendar({bool mondays = false, int? firstWeekday}) {
      final grid = SizedBox(
        width: 340,
        child: DesignCalendar(
          controller: controller,
          focusNode: node,
          firstWeekday: firstWeekday,
          weekdayLabel: (w) => 'w$w',
          dayBuilder: _day,
        ),
      );
      return harness(
        Builder(
          builder: (context) => mondays
              ? Localizations.override(
                  context: context,
                  locale: const Locale('fr'),
                  delegates: const [_MondaysDelegate()],
                  child: grid,
                )
              : grid,
        ),
      );
    }

    double x(int weekday) => tester.getTopLeft(find.text('w$weekday')).dx;

    await tester.pumpWidget(calendar());
    expect(x(7), lessThan(x(1)), reason: 'English: Sunday');

    await tester.pumpWidget(calendar(mondays: true));
    await tester.pumpAndSettle();
    expect(x(1), lessThan(x(7)), reason: 'the locale: Monday');
    node.requestFocus();
    await tester.pump();
    // Wednesday the 28th of January 2026.
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    expect(controller.focusedDay, DateTime(2026, 1, 26));

    await tester.pumpWidget(
      calendar(mondays: true, firstWeekday: DateTime.saturday),
    );
    expect(x(6), lessThan(x(7)));
    expect(x(7), lessThan(x(1)));
  });
}
