// ui_core_test 0.6.0's package checks, run on Civic: the status tones stand apart in every palette, the docs speak
// to the people who use the package, the README works as an adopter follows it, and the example resolves from pub.dev.
import 'dart:io';

import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

void main() {
  test(
    'the status tones stand apart in every palette, by day and by night',
    () {
      const DesignToneCheck(look: 'Civic').check([
        for (final palette in CivicThemeData.palettes)
          for (final brightness in Brightness.values)
            DesignToneSet(
              palette: palette.label,
              brightness: brightness,
              tones: {
                for (final tone in CivicTone.values)
                  tone.name:
                      (brightness == Brightness.dark
                              ? CivicThemeData.dark(palette: palette)
                              : CivicThemeData.light(palette: palette))
                          .toneOf(tone)
                          .$2,
              },
            ),
      ]).verify();
    },
  );

  test('the docs speak to the people who use the package', () {
    const DesignDocsCheck(look: 'Civic').check({
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart')) f.path: f.readAsStringSync(),
    }).verify();
  });

  test('the README works as an adopter follows it', () async {
    const check = DesignReadmeCheck(look: 'Civic');
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
    const DesignExampleDepsCheck(look: 'Civic')
        .check(
          File('example/pubspec.yaml').readAsStringSync(),
          package: 'civic_ui',
          unpublished: {'ui_core_review'},
        )
        .verify();
  });
}
