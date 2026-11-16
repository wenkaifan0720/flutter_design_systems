// What Brutal paints must look the same in a browser. Flutter 3.47's web
// renderer does not cut a Path.combine difference: it fills the whole first
// path, so a focus ring drawn that way painted every focused field, switch and
// button solid ink in a browser, and the tests' renderer showed nothing wrong.
// A ring is two nested outlines filled even-odd instead.
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
