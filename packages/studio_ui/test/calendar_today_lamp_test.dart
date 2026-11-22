// Today's lamp stays lit when today is also the chosen day: the latched key
// lights its legend and keeps its lamp, as a latched key does. An unlit lamp
// on the one day that is both current and chosen read as off.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

void main() {
  for (final chosen in [true, false]) {
    testWidgets(
      "today's lamp is lit when today is ${chosen ? '' : 'not '}the chosen "
      'day',
      (tester) async {
        final today = DateTime(2026, 11, 20);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, app) => StudioHost(child: app!),
            home: Center(
              child: SizedBox(
                width: 376,
                child: StudioCalendar(
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2027),
                  currentDate: today,
                  selectedDate: chosen ? today : DateTime(2026, 11, 16),
                  onDateChanged: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final lamps = tester
            .widgetList<StudioLamp>(
              find.descendant(
                // The day's own column: its figures over its lamp.
                of: find
                    .ancestor(
                      of: find.text('20'),
                      matching: find.byType(Column),
                    )
                    .first,
                matching: find.byType(StudioLamp),
              ),
            )
            .toList();
        expect(lamps, hasLength(1), reason: "today's cell has one lamp");
        expect(lamps.single.on, isTrue);
      },
    );
  }
}
