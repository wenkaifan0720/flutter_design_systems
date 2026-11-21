import 'package:flutter_test/flutter_test.dart';
import 'package:look_ui/look_ui.dart';
import 'package:look_ui/src/inventory.dart';

import '../../evals/sweep.dart';

void main() {
  testWidgets('every part the look carries holds in the scoring sweep', (
    tester,
  ) async {
    final found = await sweepInventory(
      tester,
      inventory: lookInventory,
      host: (context, child, brightness) =>
          LookTheme(data: LookThemeData.of(brightness), child: child),
    );
    expect(found, isEmpty);
  });
}
