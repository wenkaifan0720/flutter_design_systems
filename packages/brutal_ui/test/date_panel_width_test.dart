// A date field's calendar stands edge to edge with its field, as a select's
// list does, while the field is at most half again the calendar's own width
// (360 a month, Material's docked date picker's); under a wider field it
// stands at its own width from the field's start. It meets the field on the
// field's rule, its own ruled table the only frame: it stood 4 below the
// field in a padded frame of its own, and under a 640 field on a desk window
// it spread 640 wide over the form's actions.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  double width = 390,
  double height = 844,
  TextDirection direction = TextDirection.ltr,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) => Directionality(
        textDirection: direction,
        child: BrutalTheme(
          data: brightness == Brightness.light
              ? BrutalThemeData.light()
              : BrutalThemeData.dark(),
          child: BrutalToaster(child: navigator!),
        ),
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final pickers = <String, (IconData, Widget)>{
    'date': (
      LucideIcons.calendar,
      BrutalDatePicker(
        labelText: 'Date',
        value: DateTime(2026, 11, 20),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        onChanged: (_) {},
      ),
    ),
    'date range': (
      LucideIcons.calendarRange,
      BrutalDateRangePicker(
        labelText: 'Dates',
        value: BrutalDateRange(
          start: DateTime(2026, 11, 20),
          end: DateTime(2026, 11, 24),
        ),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        onChanged: (_) {},
      ),
    ),
  };
  // (window, field, the calendar's width for a date, for a span): a span
  // on a window of 600 or more shows two months, at least 600.
  const cases = [
    (390.0, 358.0, 358.0, 358.0),
    (1440.0, 480.0, 480.0, 600.0),
    (1440.0, 640.0, 360.0, 640.0),
  ];
  for (final MapEntry(key: kind, value: (icon, picker)) in pickers.entries) {
    for (final (window, fieldWidth, date, span) in cases) {
      final expected = kind == 'date' ? date : span;
      for (final direction in TextDirection.values) {
        testWidgets('a $kind field ${fieldWidth.round()} wide at '
            '${window.round()}, ${direction.name}: its calendar stands '
            '${expected.round()} from its start, on its rule', (tester) async {
          await _pump(
            tester,
            Align(
              alignment: AlignmentDirectional.topStart,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 16, top: 24),
                child: SizedBox(width: fieldWidth, child: picker),
              ),
            ),
            width: window,
            height: window < 600 ? 844 : 900,
            direction: direction,
          );
          final field = tester.getRect(
            find
                .ancestor(
                  of: find.byIcon(icon),
                  matching: find.byType(AnimatedBrutalSurface),
                )
                .first,
          );
          await tester.tap(find.byIcon(icon));
          await tester.pumpAndSettle();
          final panel = tester.getRect(
            find
                .ancestor(
                  of: find.byType(BrutalCalendar),
                  matching: find.byType(BrutalSurface),
                )
                .first,
          );
          final rtl = direction == TextDirection.rtl;
          expect(
            rtl ? panel.right : panel.left,
            moreOrLessEquals(rtl ? field.right : field.left, epsilon: .5),
            reason: 'panel $panel, field $field',
          );
          expect(
            panel.width,
            moreOrLessEquals(expected, epsilon: .5),
            reason: 'panel $panel, field $field',
          );
          // On the field's own rule, its table its only frame.
          final w = BrutalThemeData.light().borderWidth;
          expect(panel.top, moreOrLessEquals(field.bottom - w, epsilon: .5));
          expect(tester.getRect(find.byType(BrutalCalendar)), panel);
        });
      }
    }
  }
}
