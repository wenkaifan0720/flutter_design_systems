// The README's first Dart block is the minimal app: example/lib/minimal.dart
// word for word, which the example's analysis compiles; 13 lines or fewer,
// the faces loaded and the host mounted.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test("the README's first Dart block is example/lib/minimal.dart", () {
    final readme = File('README.md').readAsStringSync();
    final block = RegExp(r'```dart\n([\s\S]*?)```')
        .firstMatch(readme)!
        .group(1)!;
    expect(block, File('example/lib/minimal.dart').readAsStringSync());
    expect(block.trimRight().split('\n').length, lessThanOrEqualTo(13));
    expect(
      block,
      contains("import 'package:retro_desktop_ui/retro_desktop_ui.dart';"),
    );
    expect(block, contains('runApp('));
    expect(block, contains('RetroDesktopHost('));
    expect(block, contains('retroDesktopLoadFonts()'));
  });
}
