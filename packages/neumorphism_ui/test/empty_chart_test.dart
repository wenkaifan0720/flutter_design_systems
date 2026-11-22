// A chart with no data says so, in the look's empty state, with no empty axis.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'flat_stage.dart';
import 'support.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadNeumorphicFonts();
  });

  group('a chart with no data says so, with no empty axis', () {
    final parts = <String, Widget>{
      'two way': const NeumorphicTwoWayBars(above: []),
      'columns': const NeumorphicColumnBars(values: []),
      'step line': const NeumorphicStepLine(
        readings: [],
        xMax: 1,
        yMin: 0,
        yMax: 1,
      ),
      'shares': const NeumorphicShareBars(rows: []),
    };
    for (final e in parts.entries) {
      testWidgets(e.key, (tester) async {
        await pumpFlat(
          tester,
          e.value,
          NeumorphicThemeData.preset('porcelain', Brightness.light),
        );
        expect(find.byType(NeumorphicEmptyState), findsOneWidget);
      });
    }
  });
}
