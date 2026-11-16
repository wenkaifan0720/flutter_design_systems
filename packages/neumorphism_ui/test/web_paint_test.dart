// What Neumorphism paints must look the same in a browser. Flutter 3.47's web renderer fills a Path.combine whose
// result has a hole as its whole first path: the inset of a pressed well, clipped to the outline less the room it
// holds, ran on across a field's words, a calendar's days and a list's rows in a browser, while the tests' renderer
// and every other platform cut it at the room. A shape less a hole is the two outlines filled even-odd instead. An
// intersection of two outlines has no hole, so it stays.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nothing in lib cuts a hole with Path.combine', () {
    final cuts = RegExp(r'PathOperation\.(difference|reverseDifference|xor)\b');
    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            cuts.hasMatch(file.readAsStringSync()))
          file.path,
    ];
    expect(offenders, isEmpty);
  });
}
