// ui_core_test's package checks on retro_desktop_ui: the README works as an adopter follows it (its install line,
// what its blocks import, each block compiling), the example resolves from pub.dev alone, the public docs speak to the
// people who use the package, and the alert pictures' inks stay apart in each palette by day and by night.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

void main() {
  test('the README works as an adopter follows it', () async {
    const check = DesignReadmeCheck(look: 'Retro Desktop');
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
    const DesignExampleDepsCheck(look: 'Retro Desktop')
        .check(
          File('example/pubspec.yaml').readAsStringSync(),
          package: 'retro_desktop_ui',
          unpublished: {'ui_core_review'},
        )
        .verify();
  });

  test('the docs speak to the people who use the package', () {
    const DesignDocsCheck(look: 'Retro Desktop').check({
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart')) f.path: f.readAsStringSync(),
    }).verify();
  });

  // Retro Desktop tells a notice's tone by the period's picture: the note balloon (info, and with a tick inside it
  // success), the caution triangle (warning) and the stop sign (danger). The three inks those pictures are drawn in
  // stay apart in every palette, by day and by night; info and success share the balloon and its blue, told apart by
  // the mark inside it, as the period's one balloon said anything.
  test("the alert pictures' inks stay apart in each palette", () {
    const DesignToneCheck(look: 'Retro Desktop').check([
      for (final palette in RetroDesktopThemeData.palettes)
        for (final brightness in Brightness.values)
          if (RetroDesktopThemeData.preset(
                palette.id,
                brightness,
              ).colors.illustration
              case final inks)
            DesignToneSet(
              palette: palette.label,
              brightness: brightness,
              tones: {
                'info': inks.note,
                'warning': inks.caution,
                'danger': inks.stop,
              },
            ),
    ]).verify();
  });
}
