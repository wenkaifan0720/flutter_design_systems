// Flutter 3.47's web renderer can fill a hole made by Path.combine. The inset painter
// uses an even-odd path for the outside of a face on every renderer.
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
