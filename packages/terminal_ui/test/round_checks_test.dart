// ui_core_test 0.6.1's package checks, run on Terminal: the docs speak to the people who use the package, the README
// works as an adopter follows it, and the example resolves from pub.dev. The tones are tones_distinct_test's: the
// one-ink palettes draw every tone in the words' ink by design, a state there reading by its glyph.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

void main() {
  test('the docs speak to the people who use the package', () {
    const DesignDocsCheck(look: 'Terminal').check({
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart')) f.path: f.readAsStringSync(),
    }).verify();
  });

  test('the README works as an adopter follows it', () async {
    const check = DesignReadmeCheck(look: 'Terminal');
    final readme = File('README.md').readAsStringSync();
    check
        .check(readme, pubspec: File('pubspec.yaml').readAsStringSync())
        .verify();
    final dir = Directory('test/zz_readme_check')..createSync();
    addTearDown(() => dir.deleteSync(recursive: true));
    for (final MapEntry(:key, :value) in check.libraries(readme).entries) {
      File('${dir.path}/$key').writeAsStringSync(value);
    }
    final analysis = await Process.run('dart', ['analyze', dir.path]);
    check.analysis('${analysis.stdout}').verify();
  }, timeout: const Timeout(Duration(minutes: 4)));

  test('the example resolves from pub.dev alone', () {
    const DesignExampleDepsCheck(look: 'Terminal')
        .check(
          File('example/pubspec.yaml').readAsStringSync(),
          package: 'terminal_ui',
          unpublished: {'ui_core_review'},
        )
        .verify();
  });
}
