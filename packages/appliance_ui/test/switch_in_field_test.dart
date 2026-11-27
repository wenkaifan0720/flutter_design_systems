// A switch keeps its slot's size wherever it stands: in a field (a column
// that stretches its children) it sits at the start, not stretched across
// the line, in either direction.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

void main() {
  setUpAll(applianceLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets('a switch in a field keeps its size (${direction.name})', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) =>
              ApplianceHost(brightness: Brightness.light, child: app!),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: SizedBox(
                width: 360,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ApplianceField(
                      labelText: 'Favourite',
                      child: ApplianceSwitch(value: false, onChanged: (_) {}),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final slot = tester.getRect(
        find
            .descendant(
              of: find.byType(ApplianceSwitch),
              matching: find.byType(AnimatedApplianceSurface),
            )
            .first,
      );
      expect(slot.size, ApplianceSwitch.size);
      final label = tester.getRect(find.text('Favourite'));
      if (direction == TextDirection.ltr) {
        expect((slot.left - label.left).abs(), lessThan(1));
      } else {
        expect((slot.right - label.right).abs(), lessThan(1));
      }
      // Its press is the switch's, not the line's.
      final hit = tester.getRect(
        find
            .descendant(
              of: find.byType(ApplianceSwitch),
              matching: find.byType(RawButton),
            )
            .first,
      );
      expect(hit.width, lessThan(120));
    });
  }
}
