// A date picker's and a date range picker's month plate scrolls: at twice
// the text size its last week scrolls into view under a wheel, and a day
// in it can be chosen.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  double scale = 2,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 620);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, navigator) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: direction,
          child: ApplianceTheme(
            data: ApplianceThemeData.light(),
            child: navigator!,
          ),
        ),
      ),
      home: Center(child: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(applianceLoadFonts);
  for (final range in [false, true]) {
    testWidgets(
      'the last week scrolls into view in the ${range ? 'range' : 'date'} picker',
      (tester) async {
        final start = DateTime(2026, 11),
            end = DateTime(2026, 12, 31),
            current = DateTime(2026, 11, 12);
        DateTime? selected;
        final picker = range
            ? ApplianceDateRangePicker(
                labelText: 'Dates',
                value: null,
                firstDate: start,
                lastDate: end,
                currentDate: current,
                onChanged: (v) => selected = v.end,
              )
            : ApplianceDatePicker(
                labelText: 'Dates',
                value: current,
                firstDate: start,
                lastDate: end,
                currentDate: current,
                onChanged: (v) => selected = v,
              );
        await _show(tester, SizedBox(width: 350, child: picker));
        await tester.tap(
          find
              .descendant(
                of: find.byWidget(picker),
                matching: find.byType(RawButton),
              )
              .first,
        );
        await tester.pumpAndSettle();
        if (range) {
          await tester.tap(find.text('12').first);
          await tester.pumpAndSettle();
        }
        final plate = find.byType(ApplianceMenuPlate);
        final last = find
            .descendant(of: plate, matching: find.text('30'))
            .first;
        final scroll = find
            .descendant(of: plate, matching: find.byType(Scrollable))
            .first;
        final position = tester.state<ScrollableState>(scroll).position;
        expect(position.maxScrollExtent, greaterThan(0));
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: tester.getCenter(plate),
            scrollDelta: const Offset(0, 650),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(plate).contains(tester.getCenter(last)), isTrue);
        await tester.tap(last);
        await tester.pumpAndSettle();
        expect(selected, DateTime(2026, 11, 30));
      },
    );
  }
}
