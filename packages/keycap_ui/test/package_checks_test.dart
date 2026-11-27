// ui_core_test's package checks on keycap_ui: the README works as an adopter follows it (its install line, what its
// blocks import, each block compiling), the example resolves from pub.dev alone, and the public docs speak to the
// people who use the package.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

void main() {
  test('the README works as an adopter follows it', () async {
    const check = DesignReadmeCheck(look: 'Keycap');
    final readme = File('README.md').readAsStringSync();
    check
        .check(readme, pubspec: File('pubspec.yaml').readAsStringSync())
        .verify();
    final dir = Directory('test/zz_readme_blocks')..createSync(recursive: true);
    addTearDown(() => dir.deleteSync(recursive: true));
    for (final MapEntry(:key, :value) in check.libraries(readme).entries) {
      File('${dir.path}/$key').writeAsStringSync(value);
    }
    final root = Platform.environment['FLUTTER_ROOT'];
    final dart = root == null ? 'dart' : '$root/bin/dart';
    final analysis = await Process.run(dart, ['analyze', dir.path]);
    check.analysis('${analysis.stdout}').verify();
  }, timeout: const Timeout(Duration(minutes: 4)));

  test('the example resolves from pub.dev alone', () {
    const DesignExampleDepsCheck(look: 'Keycap')
        .check(
          File('example/pubspec.yaml').readAsStringSync(),
          package: 'keycap_ui',
          unpublished: {'ui_core_review'},
        )
        .verify();
  });

  test('the docs speak to the people who use the package', () {
    const DesignDocsCheck(look: 'Keycap').check({
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart')) f.path: f.readAsStringSync(),
    }).verify();
  });
}
