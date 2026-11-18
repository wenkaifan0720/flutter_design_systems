// What Gloss paints must look the same in a browser. Flutter 3.47's web
// renderer does not cut a Path.combine difference or intersection whose result
// has a hole: it fills the whole first path, so a ring or a rim drawn that way
// stands as solid colour in a browser while the tests' renderer shows nothing
// wrong. Gloss draws every ring and cut-out as one path filled even-odd (an
// outer and an inner outline), as a stroke, or under a clip; it never combines
// paths, so the rule here is the simplest one that holds that: no Path.combine
// at all, in the package or in its example.
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

  test('the cut-outs Gloss does paint are even-odd paths', () {
    // The wells' inner shade is the one shape with a hole: a frame round the
    // face, filled even-odd and clipped to the face.
    final surface = File('lib/src/gloss/surface.dart').readAsStringSync();
    expect(surface, contains('PathFillType.evenOdd'));
  });
}
