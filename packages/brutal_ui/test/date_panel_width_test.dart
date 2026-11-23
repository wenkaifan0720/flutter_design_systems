// A date field's calendar stands as wide as its field, edge to edge with
// it, as a select's list does, on a phone and on a wide window: it stood a
// fixed 320 (348 with its frame) under a 358 field, and under a 640 one.
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
  for (final MapEntry(key: kind, value: (icon, picker)) in pickers.entries) {
    for (final width in [390.0, 1440.0]) {
      for (final direction in TextDirection.values) {
        testWidgets('a $kind field at ${width.round()}, ${direction.name}: '
            'its calendar stands from its start, as wide as it', (
          tester,
        ) async {
          await _pump(
            tester,
            Align(
              alignment: AlignmentDirectional.topStart,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 16, top: 24),
                child: SizedBox(width: width < 600 ? 358 : 640, child: picker),
              ),
            ),
            width: width,
            height: width < 600 ? 844 : 900,
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
            moreOrLessEquals(field.width, epsilon: .5),
            reason: 'panel $panel, field $field',
          );
        });
      }
    }
  }
}
