// Appliance answers every row of ui_core's shared component list once, its
// one absent row with a reason rather than a to-do, and every live specimen
// builds and lays out on a phone, by day and by night, in both reading
// directions, without a throw.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Brightness brightness, TextDirection direction, Widget child) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: ApplianceHost(brightness: brightness, child: app!),
      ),
      home: ApplianceScreen(body: child),
    );

void main() {
  test('every row is answered once, with a specimen or a reason', () {
    applianceInventory.verify();
    expect(
      applianceInventory.presentCount + applianceInventory.absentCount,
      DesignInventoryRow.all.length,
    );
    expect(applianceInventory.absentCount, 1);
  });

  for (final brightness in Brightness.values) {
    for (final direction in TextDirection.values) {
      for (final entry in applianceInventory.entries.where(
        (e) => e.isPresent,
      )) {
        testWidgets(
          '${entry.row} builds (${brightness.name}, ${direction.name})',
          (tester) async {
            tester.view.physicalSize = const Size(390, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final height = applianceInventoryHeights[entry.row];
            await tester.pumpWidget(
              _app(
                brightness,
                direction,
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: SizedBox(
                    height: height,
                    child: Builder(builder: entry.builder!),
                  ),
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 500));
            expect(tester.takeException(), isNull);
            // Let springs and loops come to rest before the tree goes.
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }
}
