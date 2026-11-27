// The README's first whole app is the mount (its install line, its imports, then the host): it imports frosted_ui
// and material_ui, calls runApp and mounts FrostedHost in the app's builder. Copied into a file of this package and
// analysed, it compiles with no error and no warning.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the README\'s first app mounts the host and compiles', () {
    final readme = File('README.md').readAsStringSync();
    final blocks = [
      for (final m in RegExp(r'```dart\n([\s\S]*?)```').allMatches(readme))
        m.group(1)!,
    ];
    final block = blocks.firstWhere((b) => b.contains('runApp('));
    expect(block, contains("import 'package:frosted_ui/frosted_ui.dart';"));
    expect(block, contains("import 'package:material_ui/material_ui.dart';"));
    expect(block, contains('FrostedHost('));
    expect(block, isNot(contains('package:flutter/material.dart')));
    final dir = Directory('test/zz_readme_app')..createSync(recursive: true);
    addTearDown(() => dir.deleteSync(recursive: true));
    final app = File('${dir.path}/main.dart')..writeAsStringSync(block);
    final root = Platform.environment['FLUTTER_ROOT'];
    final dart = root == null ? 'dart' : '$root/bin/dart';
    final result = Process.runSync(dart, [
      'analyze',
      '--fatal-warnings',
      app.path,
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  }, timeout: const Timeout(Duration(minutes: 4)));
}
