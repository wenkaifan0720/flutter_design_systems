// What a dialog holds takes the dialog's face for its page: by night a
// dialog stands on the raised band, and a calendar in it painted its days on
// the page's darker ground, so the month read as a dark block with a ragged
// end (Stint's due date at 390). By day both were white. The days sit on the
// dialog's face, by day and by night, in every palette.
// ignore_for_file: implementation_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:civic_ui/src/civic/internal/paint.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final palette in CivicThemeData.palettes) {
    for (final brightness in Brightness.values) {
      testWidgets('${palette.label} ${brightness.name}: a calendar in a '
          "dialog sits on the dialog's face", (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final theme = brightness == Brightness.dark
            ? CivicThemeData.dark(palette: palette)
            : CivicThemeData.light(palette: palette);
        final days = RawCalendarController(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          initialMonth: DateTime(2026, 11),
        );
        addTearDown(days.dispose);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, app) => CivicTheme(data: theme, child: app!),
            home: CivicDialog(
              title: 'Due date',
              content: CivicCalendar(controller: days),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final face = theme.isDark ? theme.surface : theme.background;
        final fills = <Color, int>{};
        for (final paint in tester.widgetList<CustomPaint>(
          find.descendant(
            of: find.byType(CivicCalendar),
            matching: find.byType(CustomPaint),
          ),
        )) {
          final painter = paint.painter;
          if (painter is CivicFacePainter) {
            fills.update(painter.fill, (n) => n + 1, ifAbsent: () => 1);
          }
        }
        final resting = fills.entries
            .reduce((a, b) => a.value >= b.value ? a : b)
            .key;
        expect(
          resting,
          face,
          reason: 'a resting day on $resting, the dialog $face',
        );
      });
    }
  }
}
