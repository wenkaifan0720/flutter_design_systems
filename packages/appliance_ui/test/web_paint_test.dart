// What Appliance paints must look the same in a browser. Flutter 3.47's web
// renderer fills a Path.combine difference or intersection whose result has
// a hole as the whole first path: a well, a bezel or a ring cut that way
// stands solid in a browser while the tests' renderer shows nothing wrong
// (Appliance's wells did, at M1). A ring or a cut-out is a DRRect, two nested
// outlines filled even-odd, or a clip; nothing in lib combines paths.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nothing in lib cuts a path with Path.combine', () {
    final combine = RegExp(r'Path\.combine\s*\(|PathOperation\.');
    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            combine.hasMatch(file.readAsStringSync()))
          file.path,
    ];
    expect(offenders, isEmpty);
  });
}
