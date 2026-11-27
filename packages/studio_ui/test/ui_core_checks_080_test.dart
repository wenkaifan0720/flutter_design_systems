// ui_core_test 0.6.1's package checks: the README works as an adopter
// follows it (its install line, its imports, every Dart block compiling),
// the example resolves from pub.dev alone, the docs speak to the people who
// use the package, and the lit and failing tones stay apart in the six
// palettes, by day and by night.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

void main() {
  test('the README works as an adopter follows it', () async {
    const check = DesignReadmeCheck(look: 'Studio');
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
    const DesignExampleDepsCheck(look: 'Studio')
        .check(
          File('example/pubspec.yaml').readAsStringSync(),
          package: 'studio_ui',
        )
        .verify();
  });

  test('the docs speak to the people who use the package', () {
    const DesignDocsCheck(look: 'Studio').check({
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart')) f.path: f.readAsStringSync(),
    }).verify();
  });

  test(
    'the lit and failing tones stay apart in every palette, day and night',
    () {
      const DesignToneCheck(look: 'Studio').check([
        for (final palette in StudioThemeData.palettes)
          for (final brightness in Brightness.values)
            DesignToneSet(
              palette: palette.label,
              brightness: brightness,
              tones: {
                'lit': StudioThemeData.preset(
                  palette.id,
                  brightness,
                ).colors.litLegend,
                'danger': StudioThemeData.preset(
                  palette.id,
                  brightness,
                ).colors.dangerLegend,
              },
            ),
      ]).verify();
    },
  );
}
