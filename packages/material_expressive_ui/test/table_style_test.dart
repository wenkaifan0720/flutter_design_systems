import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

void main() {
  for (final width in [240.0, 700.0]) {
    testWidgets('table style follows row selection and press at $width', (
      tester,
    ) async {
      const selectedInk = Color(0xff123456);
      const idleInk = Color(0xff345678);
      const pressedInk = Color(0xff654321);
      var hits = 0;
      final theme = ExpressiveThemeData.preset('baseline', Brightness.light)
          .copyWith(
            tableTheme: ExpressiveComponentThemeData(
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? selectedInk
                    : idleInk,
              ),
            ),
          );
      await tester.pumpWidget(
        MaterialApp(
          home: ExpressiveHost(
            light: theme,
            brightness: Brightness.light,
            child: Center(
              child: SizedBox(
                width: width,
                child: ExpressiveTable(
                  style: ExpressiveComponentThemeData(
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.pressed)
                          ? pressedInk
                          : null,
                    ),
                  ),
                  columns: const [
                    ExpressiveTableColumn('Plant'),
                    ExpressiveTableColumn('Water'),
                  ],
                  rows: [
                    ExpressiveTableRow(
                      const ['Fern', '200 ml'],
                      selected: true,
                      onPressed: () => hits++,
                    ),
                    const ExpressiveTableRow(['Cactus', '50 ml']),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Color? ink(String value) => tester
          .renderObject<RenderParagraph>(find.text(value))
          .text
          .style
          ?.color;
      expect(ink('Fern'), selectedInk);
      expect(ink('Cactus'), idleInk);
      final target = find
          .ancestor(
            of: find.text('Fern'),
            matching: find.byType(ExpressivePressable),
          )
          .first;
      final gesture = await tester.startGesture(tester.getCenter(target));
      await tester.pumpAndSettle();
      expect(ink('Fern'), pressedInk);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(ink('Fern'), selectedInk);
      expect(hits, 1);
    });
  }
}
