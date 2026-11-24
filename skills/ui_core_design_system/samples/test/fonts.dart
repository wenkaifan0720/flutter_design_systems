import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The fonts the pixel checks read: Roboto for the words and Material's
/// icons for the glyphs, from the Flutter SDK's own cache. A design loads the
/// families its FontManifest.json lists; a family left out is drawn in the
/// test's own font, whose boxes stand on the baseline and read as off-centre.
Future<void> loadTendFonts(WidgetTester tester) async {
  final fonts =
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String name) =>
      File('$fonts/$name').readAsBytes().then(ByteData.sublistView);
  await tester.runAsync(() async {
    await (FontLoader('Roboto')
          ..addFont(read('Roboto-Regular.ttf'))
          ..addFont(read('Roboto-Medium.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(read('MaterialIcons-Regular.otf'))).load();
  });
}
