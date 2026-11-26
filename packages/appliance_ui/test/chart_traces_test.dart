// By day the display's first trace is the signal itself wherever it stands
// 3:1 on the LCD, and else the signal's nearest tone that does: never the
// signal's words, which are deep enough for the housing and read muddy on
// the glass.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final name in ApplianceThemeData.presets) {
    for (final b in Brightness.values) {
      testWidgets('$name, ${b.name}: the first trace', (tester) async {
        final theme = ApplianceThemeData.preset(name, b);
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ApplianceTheme(
              data: theme,
              child: const Center(
                child: ApplianceDonutChart(
                  semanticLabel: 'Hours',
                  slices: [('Design', 3), ('Build', 2)],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final c = theme.colors;
        final first = tester
            .widgetList<ApplianceLamp>(find.byType(ApplianceLamp))
            .first
            .color!;
        if (b == Brightness.light) {
          expect(
            first,
            RawPalette.readableTone(c.signal, on: [c.display], ratio: 3),
          );
          expect(
            applianceContrast(first, c.display),
            greaterThanOrEqualTo(2.95),
          );
          if (applianceContrast(c.signal, c.display) >= 3) {
            expect(first, c.signal);
          }
        } else {
          expect(first, c.signal);
        }
      });
    }
  }
}
