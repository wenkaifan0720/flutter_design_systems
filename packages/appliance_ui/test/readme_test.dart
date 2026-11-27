// The README's first Dart block is the smallest app: at most 12 lines, it
// imports appliance_ui, calls runApp, wraps Appliance's theme (ApplianceHost) round
// one widget, and it compiles (copied into a file in the package and
// analyzed). Its Navigation section shows ApplianceScaffold.branches with a
// page pushed in a place, in a block that compiles too.
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
      expect(
        block,
        contains("import 'package:appliance_ui/appliance_ui.dart';"),
      );
      expect(block, contains('runApp('));
      expect(block, contains('ApplianceHost('));
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

  test(
    "the README's Navigation section shows branches in a block that compiles",
    () async {
      final readme = File('README.md').readAsStringSync();
      final section = RegExp(r'## Navigation\n([\s\S]*?)\n## ')
          .firstMatch(readme)!
          .group(1)!;
      final block = RegExp(r'```dart\n([\s\S]*?)```')
          .firstMatch(section)!
          .group(1)!;
      expect(block, contains('ApplianceScaffold.branches('));
      expect(block, contains('Navigator.of(context).push('));
      final dir = Directory('test/_readme_navigation')
        ..createSync(recursive: true);
      addTearDown(() => dir.deleteSync(recursive: true));
      final source = File('${dir.path}/navigation.dart')
        ..writeAsStringSync(block);
      final root = Platform.environment['FLUTTER_ROOT'];
      final dart = root == null ? 'dart' : '$root/bin/dart';
      final result = await Process.run(dart, ['analyze', source.path]);
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
