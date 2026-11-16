// Civic answers every row of ui_core's shared component list once, each
// absent row with a reason rather than a to-do, and every live specimen
// builds and lays out on a phone, by day and by night, without a throw.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';

void main() {
  test('every row is answered once, with a specimen or a reason', () {
    civicInventory.verify();
    expect(
      civicInventory.presentCount + civicInventory.absentCount,
      DesignInventoryRow.all.length,
    );
  });

  for (final brightness in Brightness.values) {
    for (final entry in civicInventory.entries.where((e) => e.isPresent)) {
      testWidgets('${entry.row} builds (${brightness.name})', (tester) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final height = civicInventoryHeights[entry.row];
        await tester.pumpWidget(
          kitApp(
            brightness: brightness,
            home: Padding(
              padding: const EdgeInsets.all(CivicSpacing.s20),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: SizedBox(
                  height: height,
                  child: Builder(builder: entry.builder!),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
