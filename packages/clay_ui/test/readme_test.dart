// The README's first Dart block is the smallest app: at most 12 lines, it
// imports clay_ui, calls runApp, wraps Clay's theme round one widget, and it
// compiles (copied into a file in the package and analyzed).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    "the README's first Dart block is a minimal app that compiles",
    () async {
      final readme = File('README.md').readAsStringSync();
      final block = RegExp(r'```dart\n([\s\S]*?)```')
          .firstMatch(readme)!
          .group(1)!;
      expect(block.trim().split('\n'), hasLength(lessThanOrEqualTo(12)));
      expect(block, contains("import 'package:clay_ui/clay_ui.dart';"));
      expect(block, contains('runApp('));
      expect(block, contains('ClayTheme('));
      final dir = Directory('test/_readme')..createSync(recursive: true);
      addTearDown(() => dir.deleteSync(recursive: true));
      final source = File('${dir.path}/minimal_app.dart')
        ..writeAsStringSync(block);
      final root = Platform.environment['FLUTTER_ROOT'];
      final dart = root == null ? 'dart' : '$root/bin/dart';
      final result = await Process.run(dart, ['analyze', source.path]);
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
