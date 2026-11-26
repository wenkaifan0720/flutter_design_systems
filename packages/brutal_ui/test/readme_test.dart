// The README's first Dart block is the minimal app: example/lib/minimal.dart
// word for word, which the example's analysis compiles; 12 lines or fewer,
// on the look's theme.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test("the README's first Dart block is example/lib/minimal.dart", () {
    final readme = File('README.md').readAsStringSync();
    final block = RegExp(r'```dart\n([\s\S]*?)```')
        .firstMatch(readme)!
        .group(1)!;
    expect(block, File('example/lib/minimal.dart').readAsStringSync());
    expect(block.trimRight().split('\n').length, lessThanOrEqualTo(12));
    expect(block, contains("import 'package:brutal_ui/brutal_ui.dart';"));
    expect(block, contains('runApp('));
    expect(block, contains('BrutalThemeData'));
  });
}
