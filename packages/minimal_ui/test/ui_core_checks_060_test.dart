// ui_core_test 0.6.0's package checks: the README works as an adopter follows
// it (its install line, its imports, every Dart block compiling), the example
// resolves from pub.dev alone, the docs speak to the people who use the
// package, and the status tones stay apart in the six palettes, by day and by
// night.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

void main() {
  test('the README works as an adopter follows it', () async {
    const check = DesignReadmeCheck(look: 'Minimal');
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
    const DesignExampleDepsCheck(look: 'Minimal')
        .check(
          File('example/pubspec.yaml').readAsStringSync(),
          package: 'minimal_ui',
          unpublished: {'ui_core_review'},
        )
        .verify();
  });

  test('the docs speak to the people who use the package', () {
    const DesignDocsCheck(look: 'Minimal').check({
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart')) f.path: f.readAsStringSync(),
    }).verify();
  });

  test('the status tones stay apart in every palette, day and night', () {
    const DesignToneCheck(look: 'Minimal').check([
      for (final palette in MinimalThemeData.palettes)
        for (final brightness in Brightness.values)
          DesignToneSet(
            palette: palette.label,
            brightness: brightness,
            tones: {
              for (final tone in MinimalTone.values)
                tone.name: MinimalThemeData.preset(
                  palette.id,
                  brightness,
                ).tone(tone).foreground,
            },
          ),
    ]).verify();
  });
}
