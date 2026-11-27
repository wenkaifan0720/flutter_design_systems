// A calendar's days from the months either side stand in a quiet tone of
// their own, clear of the 2.6:1 a faint figure falls under (2.85:1 or more)
// on the housing and a faceplate, and the month's own days read at least
// 2.5 times as strongly, by day and by night and in every finish.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:ui_core_test/ui_core_test.dart';

final _stage = GlobalKey();

Future<void> _show(
  WidgetTester tester,
  Widget part,
  ApplianceThemeData theme,
) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => ApplianceTheme(data: theme, child: app!),
      home: Builder(
        builder: (context) => ColoredBox(
          color: ApplianceTheme.of(context).colors.housingTop,
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(key: _stage, width: 342, child: part),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color _ink(WidgetTester tester, String figure) => tester
    .renderObject<RenderParagraph>(find.text(figure).first)
    .text
    .style!
    .color!;

void main() {
  setUpAll(applianceLoadFonts);

  for (final name in [for (final p in ApplianceThemeData.palettes) p.id]) {
    for (final brightness in Brightness.values) {
      final theme = ApplianceThemeData.preset(name, brightness);
      final c = theme.colors;

      // February 2027 opens on a Monday: the 31st of January stands before
      // it, the 1st to the 7th of March after it.
      testWidgets('$name, ${brightness.name}: the days outside the month '
          'stand quiet, never faint', (tester) async {
        final controller = RawCalendarController(
          firstDate: DateTime(2026),
          lastDate: DateTime(2028),
          selectedDate: DateTime(2027, 2, 10),
          currentDate: DateTime(2027, 2, 17),
        );
        addTearDown(controller.dispose);
        await _show(tester, ApplianceCalendar(controller: controller), theme);
        expect(find.text('31'), findsOneWidget);
        final outside = _ink(tester, '31');
        final month = _ink(tester, '15');
        for (final (ground, face) in [
          ('housing top', c.housingTop),
          ('housing bottom', c.housingBottom),
          ('faceplate', c.face),
        ]) {
          // Clear of the 2.6 a faint figure falls under, with margin.
          expect(
            applianceContrast(outside, face),
            greaterThanOrEqualTo(2.85),
            reason: ground,
          );
          // Clearly quieter than the month's own days.
          expect(
            applianceContrast(month, face) / applianceContrast(outside, face),
            greaterThanOrEqualTo(2.5),
            reason: ground,
          );
        }
        // A finding by design, as Cupertino's secondary words are; no fault.
        final report = await const DesignContrastCheck(look: 'appliance')
            .check(_stage.currentContext!, runAsync: tester.runAsync);
        expect(report.problems, isEmpty);
      });
    }
  }
}
