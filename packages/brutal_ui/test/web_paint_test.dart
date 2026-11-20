// CanvasKit on Flutter 3.47 can fill a path difference unexpectedly.
// Keep the drawing primitives portable across Flutter renderers.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nothing in lib cuts a path with Path.combine', () {
    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            file.readAsStringSync().contains('PathOperation.difference'))
          file.path,
    ];
    expect(offenders, isEmpty);
  });
}
