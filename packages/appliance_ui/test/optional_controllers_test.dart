// A scroll area, a calendar and a colour picker work with no controller
// handed in: each makes its own, uses it, and disposes it (the leak
// tracker fails a test whose controller is never disposed). A controller
// handed in replaces the part's own, and stays the caller's: the part never
// disposes it, so the caller's own dispose afterwards does not throw.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(WidgetTester tester, Widget part) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: 320, height: 420, child: part),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ListView _rows({ScrollController? controller}) => ListView(
  controller: controller,
  children: [for (var i = 0; i < 40; i++) Text('Row $i')],
);

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets('a scroll area with no controller hands its own to the list '
      'it scrolls', (tester) async {
    await _show(tester, ApplianceScrollArea(child: _rows()));
    final area = tester.widget<RawScrollArea>(find.byType(RawScrollArea));
    final list = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(area.controller.hasClients, isTrue);
    expect(area.controller.position, same(list.position));

    final mine = ScrollController();
    await _show(
      tester,
      ApplianceScrollArea(
        controller: mine,
        child: _rows(controller: mine),
      ),
    );
    expect(
      tester.widget<RawScrollArea>(find.byType(RawScrollArea)).controller,
      same(mine),
    );
    // Back to none: the area makes its own again.
    await _show(tester, ApplianceScrollArea(child: _rows()));
    expect(
      tester.widget<RawScrollArea>(find.byType(RawScrollArea)).controller,
      isNot(same(mine)),
    );
    await tester.pumpWidget(const SizedBox());
    mine.dispose();
  });

  testWidgets('a calendar with no controller chooses a day on its own', (
    tester,
  ) async {
    DateTime? chosen;
    await _show(tester, ApplianceCalendar(onChanged: (day) => chosen = day));
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    expect(chosen, DateTime(now.year, now.month, 15));

    final mine = RawCalendarController(
      firstDate: DateTime(2026),
      lastDate: DateTime(2026, 12, 31),
      initialMonth: DateTime(2026, 3),
    );
    await _show(tester, ApplianceCalendar(controller: mine));
    await tester.tap(find.text('18'));
    await tester.pumpAndSettle();
    expect(mine.selectedDate, DateTime(2026, 3, 18));
    await tester.pumpWidget(const SizedBox());
    mine.dispose();
  });

  testWidgets('a colour picker with no controller says each new colour', (
    tester,
  ) async {
    final colours = <Color>[];
    await _show(tester, ApplianceColorPicker(onChanged: colours.add));
    final area = tester.getRect(find.byType(ApplianceColorPicker));
    await tester.tapAt(area.topLeft + Offset(area.width * 0.8, 40));
    await tester.pumpAndSettle();
    expect(colours, isNotEmpty);

    colours.clear();
    final mine = RawColorController(const Color(0xFFEE6A26));
    await _show(
      tester,
      ApplianceColorPicker(controller: mine, onChanged: colours.add),
    );
    mine.color = const Color(0xFF2F7D5B);
    expect(colours, [mine.color]);
    await tester.pumpWidget(const SizedBox());
    mine.color = const Color(0xFF000000);
    expect(colours, hasLength(1), reason: 'no word once the picker is gone');
    mine.dispose();
  });
}
