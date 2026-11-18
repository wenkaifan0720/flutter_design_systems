// What Studio paints must look the same in a browser. Flutter 3.47's web
// renderer does not cut a path boolean: Path.combine with a difference or an
// intersection whose result has a hole comes out filled whole, so a ring
// drawn that way would stand as a solid disc of ink on every focused key in a
// browser while the tests' renderer showed a ring. Studio draws its rings as
// strokes, and its rims, edge lights, inner shadows and wells as two nested
// outlines filled even-odd (surface.dart), or as a clip; it computes no path
// boolean at all, and this keeps it so. (The browser's own pictures are held
// by the pack's scripts/walk/web_rings.py.)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nothing in lib or the example combines paths', () {
    final roots = [
      Directory('lib'),
      if (Directory('example/lib').existsSync()) Directory('example/lib'),
    ];
    final offenders = [
      for (final root in roots)
        for (final file in root.listSync(recursive: true))
          if (file is File &&
              file.path.endsWith('.dart') &&
              RegExp(r'Path\.combine|PathOperation\.')
                  .hasMatch(file.readAsStringSync()))
            file.path,
    ];
    expect(
      offenders,
      isEmpty,
      reason:
          'a ring or a cut-out is two outlines filled even-odd, or a clip: '
          "the web's renderer fills a combined path's hole",
    );
  });
}
