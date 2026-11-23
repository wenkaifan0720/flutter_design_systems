// The parts that take a controller work without one: each makes its own and disposes it with itself (the leak tracking
// this suite runs under fails a test that leaves one undisposed). One handed in is the caller's and is never disposed,
// and a controller handed in, or taken away, while the part shows takes over from the one before.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void _nothing() {}

/// Whether [controller] is still in use: a disposed one throws in debug builds when a listener is added.
void _expectLive(ChangeNotifier controller) {
  expect(() => controller.addListener(_nothing), returnsNormally);
  controller.removeListener(_nothing);
}

/// The one list's offset.
double _offset(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).last).position.pixels;

final _june = (first: DateTime(2026, 6), last: DateTime(2026, 6, 30));

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadNeumorphicGlyphs();
  });

  group('NeumorphicScrollArea', () {
    List<Widget> rows() => [
      for (var i = 0; i < 40; i++) SizedBox(height: 40, child: Text('Note $i')),
    ];
    Widget area({ScrollController? controller}) => neumorphicApp(
      Center(
        child: SizedBox(
          height: 200,
          child: NeumorphicScrollArea(
            label: 'Notes',
            controller: controller,
            child: ListView(controller: controller, children: rows()),
          ),
        ),
      ),
    );

    Future<void> end(WidgetTester tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'with no controller, a list with none of its own scrolls on the area\'s',
      (tester) async {
        await tester.pumpWidget(area());
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await end(tester);
        expect(_offset(tester), greaterThan(0));
      },
    );

    testWidgets('a controller handed in drives it and is never disposed', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(area(controller: scroll));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await end(tester);
      expect(scroll.offset, greaterThan(0));
      await tester.pumpWidget(const SizedBox());
      _expectLive(scroll);
    });

    testWidgets('a controller handed in, then taken away, takes over', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(area());
      await tester.pumpWidget(area(controller: scroll));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await end(tester);
      expect(scroll.offset, greaterThan(0));
      await tester.pumpWidget(area());
      await tester.pumpAndSettle();
      expect(scroll.hasClients, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await end(tester);
      expect(_offset(tester), greaterThan(0));
      await tester.pumpWidget(const SizedBox());
      _expectLive(scroll);
    });
  });

  group('NeumorphicCalendar', () {
    Widget calendar({
      RawCalendarController? controller,
      DateTime? first,
      DateTime? last,
      ValueChanged<DateTime>? onChanged,
    }) => neumorphicApp(
      SingleChildScrollView(
        child: NeumorphicCalendar(
          controller: controller,
          firstDate: first ?? _june.first,
          lastDate: last ?? _june.last,
          initialDate: DateTime(2026, 6, 10),
          onChanged: onChanged,
        ),
      ),
    );

    testWidgets('with no controller, it picks a day between its bounds', (
      tester,
    ) async {
      final picked = <DateTime>[];
      await tester.pumpWidget(calendar(onChanged: picked.add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('14'));
      await tester.pumpAndSettle();
      expect(picked, [DateTime(2026, 6, 14)]);
    });

    testWidgets('new bounds make its own controller again', (tester) async {
      final picked = <DateTime>[];
      await tester.pumpWidget(calendar(onChanged: picked.add));
      await tester.pumpWidget(
        calendar(
          first: DateTime(2026, 7),
          last: DateTime(2026, 7, 31),
          onChanged: picked.add,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('31'));
      await tester.pumpAndSettle();
      expect(picked, [DateTime(2026, 7, 31)]);
    });

    testWidgets(
      'a controller handed in takes over, is never disposed, and taken away leaves one of its own',
      (tester) async {
        final dates = RawCalendarController(
          firstDate: _june.first,
          lastDate: _june.last,
        );
        addTearDown(dates.dispose);
        await tester.pumpWidget(calendar());
        await tester.pumpWidget(calendar(controller: dates));
        await tester.pumpAndSettle();
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();
        expect(dates.selectedDate, DateTime(2026, 6, 15));
        final picked = <DateTime>[];
        await tester.pumpWidget(calendar(onChanged: picked.add));
        await tester.pumpAndSettle();
        await tester.tap(find.text('16'));
        await tester.pumpAndSettle();
        expect(picked, [DateTime(2026, 6, 16)]);
        expect(dates.selectedDate, DateTime(2026, 6, 15));
        await tester.pumpWidget(const SizedBox());
        _expectLive(dates);
      },
    );
  });

  group('NeumorphicDateRangePicker', () {
    testWidgets('with no controller, it keeps a range between its bounds', (
      tester,
    ) async {
      final ranges = <RawDateRange?>[];
      await tester.pumpWidget(
        neumorphicApp(
          SingleChildScrollView(
            child: NeumorphicDateRangePicker(
              firstDate: _june.first,
              lastDate: _june.last,
              onChanged: ranges.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('14').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('18').first);
      await tester.pumpAndSettle();
      expect(ranges.last?.start, DateTime(2026, 6, 14));
      expect(ranges.last?.end, DateTime(2026, 6, 18));
    });

    testWidgets('a controller handed in is never disposed', (tester) async {
      final stay = RawCalendarController(
        firstDate: _june.first,
        lastDate: _june.last,
        mode: RawCalendarMode.range,
      );
      addTearDown(stay.dispose);
      Widget picker({RawCalendarController? controller}) => neumorphicApp(
        SingleChildScrollView(
          child: NeumorphicDateRangePicker(
            controller: controller,
            firstDate: _june.first,
            lastDate: _june.last,
          ),
        ),
      );
      await tester.pumpWidget(picker());
      await tester.pumpWidget(picker(controller: stay));
      await tester.pumpAndSettle();
      await tester.tap(find.text('14').first);
      await tester.pumpAndSettle();
      expect(stay.selectedRange?.start, DateTime(2026, 6, 14));
      await tester.pumpWidget(picker());
      await tester.pumpWidget(const SizedBox());
      _expectLive(stay);
    });
  });

  group('NeumorphicColorPicker', () {
    Widget picker({
      RawColorController? controller,
      ValueChanged<Color>? onChanged,
    }) => neumorphicApp(
      SingleChildScrollView(
        child: NeumorphicColorPicker(
          controller: controller,
          initialColor: const Color(0xFF3F51B5),
          onChanged: onChanged,
        ),
      ),
    );

    testWidgets(
      'with no controller, it starts on its colour and tells each change',
      (tester) async {
        final told = <Color>[];
        await tester.pumpWidget(picker(onChanged: told.add));
        await tester.pumpAndSettle();
        expect(find.text('#3F51B5'), findsOneWidget);
        for (var i = 0; i < 4 && told.isEmpty; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pumpAndSettle();
        }
        expect(told, isNotEmpty);
        expect(told.last, isNot(const Color(0xFF3F51B5)));
      },
    );

    testWidgets(
      'a controller handed in takes over, tells its changes, and is never disposed',
      (tester) async {
        final colour = RawColorController(const Color(0xFF00FF00));
        addTearDown(colour.dispose);
        final told = <Color>[];
        await tester.pumpWidget(picker(onChanged: told.add));
        await tester.pumpWidget(
          picker(controller: colour, onChanged: told.add),
        );
        await tester.pumpAndSettle();
        expect(find.text('#00FF00'), findsOneWidget);
        colour.color = const Color(0xFFFF0000);
        await tester.pumpAndSettle();
        expect(told, [const Color(0xFFFF0000)]);
        expect(find.text('#FF0000'), findsOneWidget);
        // Taken away: the picker keeps the colour it showed, on its own controller.
        await tester.pumpWidget(picker(onChanged: told.add));
        await tester.pumpAndSettle();
        expect(find.text('#FF0000'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        _expectLive(colour);
      },
    );
  });
}
