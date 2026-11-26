// A calendar's days from the months either side stand in a quiet tone of
// their own, about 3:1 on the case, a page and a panel (never faint), well
// below the month's own days, by day and by night and in every colourway.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:ui_core_test/ui_core_test.dart';

final _stage = GlobalKey();

Future<void> _show(
  WidgetTester tester,
  Widget part,
  KeycapThemeData theme,
) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => KeycapTheme(data: theme, child: app!),
      home: Builder(
        builder: (context) => ColoredBox(
          color: KeycapTheme.of(context).colors.ground,
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
  setUpAll(keycapLoadFonts);

  for (final name in KeycapThemeData.presets) {
    for (final brightness in Brightness.values) {
      final theme = KeycapThemeData.preset(name, brightness);
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
        await _show(tester, KeycapCalendar(controller: controller), theme);
        expect(find.text('31'), findsOneWidget);
        final outside = _ink(tester, '31');
        final month = _ink(tester, '15');
        for (final (ground, face) in [
          ('case', c.ground),
          ('page', c.page),
          ('panel', c.panel),
        ]) {
          // Clear of the 2.6 a faint figure falls under, with margin.
          expect(
            keycapContrast(outside, face),
            greaterThanOrEqualTo(2.95),
            reason: ground,
          );
          // Clearly quieter than the month's own days.
          expect(
            keycapContrast(month, face) / keycapContrast(outside, face),
            greaterThanOrEqualTo(2.5),
            reason: ground,
          );
        }
        // A finding by design, as Cupertino's secondary words are; no fault.
        final report = await const DesignContrastCheck(look: 'keycap')
            .check(_stage.currentContext!, runAsync: tester.runAsync);
        expect(report.problems, isEmpty);
      });
    }
  }
}
