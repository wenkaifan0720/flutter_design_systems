// ui_core_test 0.6.0's package checks on comic_ui: the README works as an adopter follows it (its install line, what its
// blocks import, each block compiling), the example resolves from pub.dev alone, the public docs speak to the people
// who use the package, and the four status tones stay apart in each palette by day and by night.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

void main() {
  test('the README works as an adopter follows it', () async {
    const check = DesignReadmeCheck(look: 'Comic');
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
    const DesignExampleDepsCheck(look: 'Comic')
        .check(
          File('example/pubspec.yaml').readAsStringSync(),
          package: 'comic_ui',
          unpublished: {'ui_core_review'},
        )
        .verify();
  });

  test('the docs speak to the people who use the package', () {
    const DesignDocsCheck(look: 'Comic').check({
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart')) f.path: f.readAsStringSync(),
    }).verify();
  });

  test('the status tones stay apart in each palette', () {
    const DesignToneCheck(look: 'Comic').check([
      for (final palette in ComicThemeData.palettes)
        for (final brightness in Brightness.values)
          if (ComicThemeData(
                palette: palette,
                brightness: brightness,
              ).colors.tones
              case final tones)
            DesignToneSet(
              palette: palette.label,
              brightness: brightness,
              tones: {
                'info': tones.info,
                'success': tones.success,
                'warning': tones.warning,
                'danger': tones.danger,
              },
            ),
    ]).verify();
  });
}
