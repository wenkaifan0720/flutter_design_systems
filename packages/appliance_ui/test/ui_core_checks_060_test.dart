// ui_core_test 0.6.0's package checks: the README works as an adopter follows
// it (its install line, its imports, every Dart block compiling), the example
// resolves from pub.dev alone, and the docs speak to the people who use the
// package. The lamps' tones stay apart in tones_apart_test.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

void main() {
  test('the README works as an adopter follows it', () async {
    const check = DesignReadmeCheck(look: 'Appliance');
    final readme = File('README.md').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    check.check(readme, pubspec: pubspec).verify();
    final dir = Directory('test/zz_readme_blocks')..createSync();
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
    const DesignExampleDepsCheck(look: 'Appliance')
        .check(
          File('example/pubspec.yaml').readAsStringSync(),
          package: 'appliance_ui',
          unpublished: {'ui_core_review'},
        )
        .verify();
  });

  test('the docs speak to the people who use the package', () {
    const DesignDocsCheck(look: 'Appliance').check({
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart')) f.path: f.readAsStringSync(),
    }).verify();
  });
}
