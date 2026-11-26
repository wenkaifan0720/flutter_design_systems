// The checks a package's tests run on its texts: status tones apart, docs
// in the user's words, a README that works, an example from pub.dev alone.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

// A README's imports in the fixtures below, spelled through this: the
// package's export rewrites every line shaped as a directive, a string's too.
const String _import = 'import';

/// ui_core's package root where pub lays it out (beside this package in the
/// repository's workspace, or in the pub cache), from the nearest package
/// config; null in drip's design kit, where ui_core's libraries are
/// lib/design_kit and its README is ../package/README.md.
Directory? _uiCoreRoot() {
  for (var dir = Directory.current.absolute; ; dir = dir.parent) {
    final config = File('${dir.path}/.dart_tool/package_config.json');
    if (config.existsSync()) {
      final packages =
          (jsonDecode(config.readAsStringSync())
                  as Map<String, Object?>)['packages']!
              as List<Object?>;
      for (final package in packages.cast<Map<String, Object?>>()) {
        if (package['name'] == 'ui_core') {
          return Directory.fromUri(
            config.uri.resolve(package['rootUri']! as String),
          );
        }
      }
      return null;
    }
    if (dir.parent.path == dir.path) return null;
  }
}

void main() {
  group('DesignToneCheck', () {
    List<String> tones(
      String palette,
      Brightness brightness,
      Map<String, Color> tones,
    ) => const DesignToneCheck(look: 'Appliance').check([
      DesignToneSet(palette: palette, brightness: brightness, tones: tones),
    ]).problems;

    test(
      "appliance's Mint by day: its signal and its ready lamp both green",
      () {
        expect(
          tones('Mint', Brightness.light, const {
            'signal': Color(0xFF1F8A70),
            'ready': Color(0xFF2E8540),
            'danger': Color(0xFFB3261E),
          }),
          [
            'Mint by day: signal (#1F8A70) and ready (#2E8540) are 23 apart (at least 24)',
          ],
        );
      },
    );

    test('a brown success beside an amber warning, and two greys', () {
      expect(
        tones('Copper', Brightness.dark, const {
          'success': Color(0xFF8B5A2B),
          'warning': Color(0xFFB7791F),
          'info': Color(0xFF64748B),
          'neutral': Color(0xFF6B7280),
        }),
        [
          'Copper by night: success (#8B5A2B) and warning (#B7791F) are 19 apart (at least 24)',
          'Copper by night: info (#64748B) and neutral (#6B7280) are 7 apart (at least 24)',
        ],
      );
    });

    test("an error red beside an orange, and a lamp's day and night, pass", () {
      expect(
        tones('Warm', Brightness.light, const {
          'danger': Color(0xFFB3261E),
          'warning': Color(0xFFE8590C),
          'success': Color(0xFF2E8540),
          'info': Color(0xFF2563EB),
          'neutral': Color(0xFF6B7280),
        }),
        isEmpty,
      );
      expect(
        tones('Mint', Brightness.dark, const {
          'signal': Color(0xFF1F8A70),
          'ready': Color(0xFF63C77A),
        }),
        isEmpty,
      );
    });

    test('distance reads tone and chroma along the hue as one line', () {
      const white = Color(0xFFFFFFFF);
      const black = Color(0xFF000000);
      expect(
        DesignToneCheck.distance(white, black),
        moreOrLessEquals(100, epsilon: 0.5),
      );
      expect(DesignToneCheck.distance(white, white), 0);
    });
  });

  group('DesignDocsCheck', () {
    List<String> docs(String source) =>
        const DesignDocsCheck(look: 'Frosted')
            .check({'lib/src/metrics.dart': source})
            .problems;

    test("frosted's metrics: the source's classes and words", () {
      // As frosted_ui 0.7 shipped them (chrome_metrics.dart).
      expect(
        docs('''
/// The tab bar's metrics.
class FrostedTabBarMetrics {
  /// The tab bar (`.tabbar`): the slab on the page's gutter, 16 in from the
  /// sides (the source's 12 left it 4 outside the content above it), and 12
  /// over the foot (or the system's inset where that is more: DERIVED, the
  final double gutter = 16;

  /// The slab (`.tabbar-in`): 64 tall, corners 22.
  final double slab = 64;

  /// The Save key's place (decision 14): the end of the form's last row,
  /// as the ledger's .form-actions-row sets it.
  final double save = 0;
}
'''),
        [
          "lib/src/metrics.dart:4: the docs say \"the source's\", a design source's word",
          "lib/src/metrics.dart:5: the docs say \"DERIVED\", a design source's word",
          "lib/src/metrics.dart:8: the docs say \".tabbar-in\", a design source's word",
          "lib/src/metrics.dart:11: the docs say \"decision 14\", a design source's word",
          "lib/src/metrics.dart:12: the docs say \".form-actions-row\", a design source's word",
        ],
      );
    });

    test('a type that opens with code, a fragment or no doc', () {
      expect(
        docs('''
/// `context.clayTheme`: the [ClayThemeData] above.
extension ClayThemeContext on BuildContext {}

/// 4pt spacing scale
class MinimalSpacing {}

@immutable
class MinimalGap {}

/// A row of the list, 52 tall.
class MinimalRow {}

/// [MinimalRow]'s parts, as its builder takes them.
@immutable
class MinimalRowParts {}

/// Fixes the keys of the [RadioGroup] round it, until Flutter has them:
///
/// - Tab stops once.
mixin MinimalKeys {}

class _Private {}
'''),
        [
          'lib/src/metrics.dart:2: ClayThemeContext opens with "`context.clayTheme`: the [ClayThemeData] above.", not a plain sentence',
          'lib/src/metrics.dart:5: MinimalSpacing opens with "4pt spacing scale", not a plain sentence',
          'lib/src/metrics.dart:8: MinimalGap has no doc',
        ],
      );
    });

    test("words in code, in a fenced block or in a look's own list", () {
      const source = '''
/// A list row.
///
/// Its `DERIVED` flag, as the tool names it, and a range `.5-1`.
///
/// ```dart
/// const decision14 = 'the source's';
/// ```
class Row1 {}
''';
      expect(docs(source), isEmpty);
      expect(
        DesignDocsCheck(
          look: 'Frosted',
          vocabulary: [RegExp(r'\bflag\b')],
        ).check({'a.dart': source}).problems,
        ["a.dart:3: the docs say \"flag\", a design source's word"],
      );
    });

    test("ui_core's own docs pass", () {
      final root = _uiCoreRoot();
      final lib = Directory(
        root == null ? 'lib/design_kit' : '${root.path}/lib',
      );
      final libraries = {
        for (final f in lib.listSync(recursive: true))
          // This file's docs name the words it finds.
          if (f is File &&
              f.path.endsWith('.dart') &&
              !f.path.endsWith('package_check.dart'))
            f.path: f.readAsStringSync(),
      };
      expect(libraries, isNotEmpty);
      expect(
        const DesignDocsCheck(look: 'ui_core').check(libraries).problems,
        isEmpty,
      );
    });
  });

  group('DesignReadmeCheck', () {
    const check = DesignReadmeCheck(look: 'Minimal');
    const pubspec = 'name: minimal_ui\nversion: 0.8.0\n';

    test("minimal's README: its blocks import Flutter's Material library", () {
      // As minimal_ui 0.1 shipped it: no install line, and Material's import.
      expect(
        check
            .check('# minimal_ui\n\n$_minimalBlock', pubspec: pubspec)
            .problems,
        [
          'the README has no install line for minimal_ui',
          'a Dart block (the 1st) imports flutter/material.dart, which Flutter deprecates for package:material_ui',
        ],
      );
    });

    test('a block that imports a package no install line adds', () {
      const readme =
          '''
```sh
flutter pub add minimal_ui
```

```dart
$_import 'package:lucide_icons_flutter/lucide_icons.dart';
$_import 'package:minimal_ui/minimal_ui.dart';
```
''';
      expect(check.check(readme, pubspec: pubspec).problems, [
        'a Dart block (the 1st) imports package:lucide_icons_flutter, which no install line adds',
      ]);
      expect(
        check
            .check(
              readme.replaceFirst(
                'add minimal_ui',
                'add minimal_ui lucide_icons_flutter material_ui',
              ),
              pubspec: pubspec,
            )
            .problems,
        isEmpty,
      );
    });

    test('an install line that asks for another version', () {
      String readme(String range) =>
          '```yaml\ndependencies:\n  minimal_ui: $range\n```\n';
      expect(check.check(readme('^0.7.0'), pubspec: pubspec).problems, [
        "the README's install line asks for minimal_ui ^0.7.0, not 0.8.0",
      ]);
      expect(
        check.check(readme("'>=0.8.0 <0.9.0'"), pubspec: pubspec).problems,
        isEmpty,
      );
      expect(check.check(readme('^0.8.0'), pubspec: pubspec).problems, isEmpty);
      expect(
        check
            .check(
              '```sh\nflutter pub add minimal_ui:^0.7.1\n```\n',
              pubspec: pubspec,
            )
            .problems,
        ["the README's install line asks for minimal_ui ^0.7.1, not 0.8.0"],
      );
    });

    test('libraries: each block a library in its shape', () {
      final libraries = check.libraries('''
```sh
flutter pub add minimal_ui lucide_icons_flutter
flutter pub add flutter_localizations --sdk=flutter
```

```dart
MinimalButton(label: 'Save', onPressed: save)
```

```dart
final theme = MinimalTheme.of(context);
```

```dart
class InkApp extends StatelessWidget {}
```

```dart
$_import 'package:minimal_ui/minimal_ui.dart';

void main() {}
```
''');
      expect(libraries.keys, [
        'readme_block_1.dart',
        'readme_block_2.dart',
        'readme_block_3.dart',
        'readme_block_4.dart',
      ]);
      const preamble =
          '// ignore_for_file: unused_import, unused_element, unused_local_variable\n'
          "import 'package:flutter/widgets.dart';\n"
          "import 'package:minimal_ui/minimal_ui.dart';\n\n";
      expect(
        libraries['readme_block_1.dart'],
        "${preamble}Object? readmeBlock(BuildContext context) =>\nMinimalButton(label: 'Save', onPressed: save);\n",
      );
      expect(
        libraries['readme_block_2.dart'],
        '${preamble}Future<void> readmeBlock(BuildContext context) async {\nfinal theme = MinimalTheme.of(context);\n}\n',
      );
      expect(
        libraries['readme_block_3.dart'],
        '${preamble}class InkApp extends StatelessWidget {}\n',
      );
      expect(
        libraries['readme_block_4.dart'],
        "${preamble.trimRight()}\nimport 'readme_block_3.dart';\n\nvoid main() {}\n",
        reason: 'a block sees the declarations of the blocks before it',
      );
    });

    test('a Lucide install line: the library the blocks import, no other', () {
      // As civic_ui's README adds Lucide: its library is lucide_icons.dart,
      // not one named after the package.
      final libraries = check.libraries('''
```sh
flutter pub add civic_ui lucide_icons_flutter
```

```dart
$_import 'package:civic_ui/civic_ui.dart';
$_import 'package:lucide_icons_flutter/lucide_icons.dart';
```

```dart
Icon(LucideIcons.search)
```
''');
      expect(
        libraries['readme_block_2.dart'],
        '// ignore_for_file: unused_import, unused_element, unused_local_variable\n'
        "import 'package:flutter/widgets.dart';\n"
        "import 'package:civic_ui/civic_ui.dart';\n"
        "import 'package:lucide_icons_flutter/lucide_icons.dart';\n\n"
        'Object? readmeBlock(BuildContext context) =>\n'
        'Icon(LucideIcons.search);\n',
      );
      expect(
        libraries.values.where(
          (l) => l.contains('lucide_icons_flutter/lucide_icons_flutter.dart'),
        ),
        isEmpty,
      );
    });

    test('a block with imports of its own, a fragment after them', () {
      final libraries = check.libraries('''
```sh
flutter pub add minimal_ui
```

```dart
$_import 'package:flutter_localizations/flutter_localizations.dart';

MinimalApp(localizationsDelegates: [GlobalWidgetsLocalizations.delegate])
```
''');
      expect(
        libraries['readme_block_1.dart'],
        '// ignore_for_file: unused_import, unused_element, unused_local_variable\n'
        "import 'package:flutter/widgets.dart';\n"
        "import 'package:flutter_localizations/flutter_localizations.dart';\n\n"
        'Object? readmeBlock(BuildContext context) =>\n'
        'MinimalApp(localizationsDelegates: [GlobalWidgetsLocalizations.delegate]);\n',
      );
    });

    test("analysis: the analyser's errors, warnings and deprecations", () {
      // dart analyze's own words, from a run over two blocks: an unused
      // import still compiles.
      const output = '''
Analyzing readme_blocks...

  error - readme_block_1.dart:5:6 - Undefined name 'LucideIcons'. Try correcting the name to one that is defined, or defining the name. - undefined_identifier
warning - readme_block_1.dart:1:8 - Unused import: 'package:ui_core/ui_core.dart'. Try removing the import directive. - unused_import
  error - readme_block_2.dart:4:45 - The named parameter 'builder' is required, but there's no corresponding argument. Try adding the required argument. - missing_required_argument
   info - readme_block_2.dart:1:8 - 'MaterialApp' is deprecated and shouldn't be used. Use material_ui. - deprecated_member_use
   info - readme_block_1.dart:1:1 - Missing documentation explaining why the diagnostic is ignored. Try adding a comment immediately above the ignore comment. - document_ignores

4 issues found.
''';
      expect(check.analysis(output).problems, [
        "a Dart block (the 1st) does not compile: Undefined name 'LucideIcons'",
        "a Dart block (the 2nd) does not compile: The named parameter 'builder' is required, but there's no corresponding argument",
        "a Dart block (the 2nd) does not compile: 'MaterialApp' is deprecated and shouldn't be used",
      ]);
      expect(
        check
            .analysis('Analyzing readme_blocks...\nNo issues found!\n')
            .problems,
        isEmpty,
      );
    });

    test("ui_core's own README passes", () {
      final root = _uiCoreRoot();
      // The kit's README is a template the export fills in.
      final readme = root == null
          ? File('../package/README.md')
                .readAsStringSync()
                .replaceAll('{{name}}', 'ui_core')
                .replaceAll('{{version}}', '0.8.0')
          : File('${root.path}/README.md').readAsStringSync();
      final pubspec = root == null
          ? 'name: ui_core\nversion: 0.8.0\n'
          : File('${root.path}/pubspec.yaml').readAsStringSync();
      expect(
        const DesignReadmeCheck(look: 'ui_core')
            .check(readme, pubspec: pubspec)
            .problems,
        isEmpty,
      );
    });
  });

  group('DesignExampleDepsCheck', () {
    List<String> deps(String pubspec) =>
        const DesignExampleDepsCheck(look: 'Keycap')
            .check(
              pubspec,
              package: 'keycap_ui',
              unpublished: {'ui_core_review'},
            )
            .problems;

    test("keycap's published example: ui_core_review, which pub.dev lacks", () {
      // As keycap_ui 0.5.0 shipped it.
      expect(deps(_keycapExample), [
        'the example depends on ui_core_review, which pub.dev does not serve',
      ]);
      expect(
        deps(_keycapExample.replaceFirst('  ui_core_review: ^0.1.0\n', '')),
        isEmpty,
      );
    });

    test('a path, a git source and an override', () {
      expect(
        deps('''
name: keycap_ui_example
dependencies:
  flutter:
    sdk: flutter
  keycap_ui:
    path: ../
  steady:
    # The app the gallery borrows.
    path: ../../steady
  shared_kit:
    git:
      url: https://example.com/shared_kit.git
dependency_overrides:
  ui_core:
    path: ../../ui_core
'''),
        [
          'the example depends on steady by path, which an adopter does not have',
          "the example depends on shared_kit by git, which an adopter's pub get does not take from pub.dev",
          "the example overrides ui_core, which an adopter's pub get does not",
        ],
      );
    });
  });
}

const String _minimalBlock =
    """
```dart
$_import 'package:flutter/material.dart';
$_import 'package:minimal_ui/minimal_ui.dart';

void main() => runApp(
  MaterialApp(
    builder: (context, child) => MinimalTheme(data: MinimalThemeData.standard(), child: child!),
    home: const MinimalScaffold(
      topBar: MinimalAppBar(title: 'Requests'),
      body: MinimalListTile(title: 'Replace the lobby lights', meta: 'REQ-142'),
    ),
  ),
);
```
""";

const String _keycapExample = '''
name: keycap_ui_example
description: The Keycap gallery, every component in every preset by day and by night.
publish_to: none

environment:
  sdk: ">=3.13.0 <4.0.0"

resolution: workspace

dependencies:
  cupertino_ui: ^1.0.0
  material_ui: ^1.9.0
  flutter:
    sdk: flutter
  # The gallery's delegates for the 30 locales (the README's line): the widgets' from here, Material's from material_ui.
  flutter_localizations:
    sdk: flutter
  keycap_ui:
    path: ../
  # An example imports the foundation itself too (its inventory, say).
  ui_core: ^0.7.1
  # A review page shows a review check's sheet.
  ui_core_review: ^0.1.0
  lucide_icons_flutter: ">=3.1.25 <5.0.0"

dev_dependencies:
  flutter_driver:
    sdk: flutter
  flutter_lints: ^6.0.0
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter''';
