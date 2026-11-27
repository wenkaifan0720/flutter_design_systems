// The README's first Dart block is a whole app of 12 lines or fewer (the production bar's line 5): it imports
// comic_ui, calls runApp and puts ComicHost, the one mount, over one widget. Copied into a file of this package and
// analysed, it compiles with no error and no warning.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the README opens with a minimal app that compiles', () {
    final readme = File('README.md').readAsStringSync();
    final block = RegExp(r'```dart\n([\s\S]*?)```')
        .firstMatch(readme)!
        .group(1)!;
    expect(block.trimRight().split('\n'), hasLength(lessThanOrEqualTo(12)));
    expect(block, contains("import 'package:comic_ui/comic_ui.dart';"));
    expect(block, contains('runApp('));
    expect(block, contains('ComicHost('));
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
