// A key strip too narrow for its keys at large text wraps them onto a second row, the rows' faces as far apart as the
// keys' faces in a row.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets('wrapped rows stand as far apart as the keys in a row', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ApplianceHost(
          brightness: Brightness.light,
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 358,
                child: ApplianceToggleGroup<String>(
                  options: const [
                    ApplianceToggleOption(value: 'eco', label: 'Eco'),
                    ApplianceToggleOption(value: 'quick', label: 'Quick wash'),
                    ApplianceToggleOption(value: 'wool', label: 'Wool'),
                    ApplianceToggleOption(value: 'rinse', label: 'Rinse'),
                  ],
                  selected: const {'eco'},
                  onSelectionChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Rect face(String label) => tester.getRect(
      find
          .ancestor(
            of: find.text(label),
            matching: find.byType(AnimatedApplianceSurface),
          )
          .first,
    );
    final eco = face('Eco'), quick = face('Quick wash'), wool = face('Wool');
    expect(wool.top, greaterThan(eco.bottom), reason: 'the strip wraps');
    final across = quick.left - eco.right;
    expect(wool.top - eco.bottom, closeTo(across, 0.5));
  });
}
