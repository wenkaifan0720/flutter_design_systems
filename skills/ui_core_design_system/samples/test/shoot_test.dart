import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:look_ui/look_ui.dart';
import 'package:look_ui/src/inventory.dart';

import '../../evals/sweep.dart';

void main() {
  testWidgets('the review pictures draw every part the look carries', (
    tester,
  ) async {
    final out =
        Platform.environment['SHOOT_DIR'] ??
        Directory.systemTemp.createTempSync('shoot').path;
    final files = await shootInventory(
      tester,
      inventory: lookInventory,
      host: (context, child, brightness) =>
          LookTheme(data: LookThemeData.of(brightness), child: child),
      outDir: out,
    );
    expect(files, isNotEmpty);
    expect(files.every((f) => File(f).lengthSync() > 0), isTrue);
  });
}
