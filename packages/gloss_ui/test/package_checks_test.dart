// ui_core_test's package checks over gloss_ui: the status tones keep apart in each palette, by day and by night; the
// docs speak to the people who use the package; the README works as an adopter follows it; the example resolves from
// pub.dev alone.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

void main() {
  test('the status tones keep apart in each palette, by day and by night', () {
    const DesignToneCheck(look: 'Gloss').check([
      for (final palette in GlossThemeData.palettes)
        for (final brightness in Brightness.values)
          DesignToneSet(
            palette: palette.label,
            brightness: brightness,
            tones: {
              for (final tone in GlossBannerTone.values)
                tone.name: glossToneInk(
                  GlossThemeData.preset(palette.id, brightness).colors,
                  tone,
                ),
            },
          ),
    ]).verify();
  });

  test('the docs speak to the people who use the package', () {
    const DesignDocsCheck(look: 'Gloss').check({
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart')) f.path: f.readAsStringSync(),
    }).verify();
  });

  test('the README works as an adopter follows it', () async {
    const check = DesignReadmeCheck(look: 'Gloss');
    final readme = File('README.md').readAsStringSync();
    check
        .check(readme, pubspec: File('pubspec.yaml').readAsStringSync())
        .verify();
    final dir = Directory('test/readme_blocks')..createSync();
    addTearDown(() => dir.deleteSync(recursive: true));
    for (final MapEntry(:key, :value) in check.libraries(readme).entries) {
      File('${dir.path}/$key').writeAsStringSync(value);
    }
    final root = Platform.environment['FLUTTER_ROOT'];
    final analysis = await Process.run(
      root == null ? 'dart' : '$root/bin/dart',
      ['analyze', dir.path],
    );
    check.analysis('${analysis.stdout}').verify();
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('the example resolves from pub.dev alone', () {
    const DesignExampleDepsCheck(look: 'Gloss')
        .check(
          File('example/pubspec.yaml').readAsStringSync(),
          package: 'gloss_ui',
          unpublished: {'ui_core_review'},
        )
        .verify();
  });
}
