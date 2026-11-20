// What Clay paints must look the same in a browser. Flutter 3.47's web
// renderer does not cut a Path.combine difference or intersection whose
// result has a hole: it fills the whole first path, so a rim drawn that way
// stands as solid colour in a browser while the tests' renderer shows
// nothing wrong. Clay's lights and shades are cached sprites of the face's
// own shape, clipped to it; nothing combines paths, so the rule is the
// simplest one that holds that: no Path.combine at all, in the package or its
// example.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nothing in the package or its example combines paths', () {
    final offenders = [
      for (final root in ['lib', 'example/lib'])
        if (Directory(root).existsSync())
          for (final file in Directory(root).listSync(recursive: true))
            if (file is File &&
                file.path.endsWith('.dart') &&
                RegExp(r'Path\.combine|PathOperation\.')
                    .hasMatch(file.readAsStringSync()))
              file.path,
    ];
    expect(offenders, isEmpty);
  });
}
