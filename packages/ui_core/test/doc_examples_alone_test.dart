// Every doc example of ui_core compiled on its own, as a look's package
// check compiles it in the look's copy-out app (drip_catalog's
// look-package-checks.ts): each fenced dart block of a doc comment (and
// each `/// Example:` line, which the package ships as one) is a
// library of its own when it declares a class, imports or has a main, else
// the body of a function given a BuildContext (statements), else an
// expression; each sees Flutter's widgets and services, Material and
// ui_core's libraries, and a name no example declares (what an app would have: a
// callback, a screen) as a free one, a widget when capitalised. An example
// that leans on a declaration the docs leave out (a state's field) does not
// compile, and fails every look's check. doc_examples_test.dart compiles
// the same examples in the contexts it gives them.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The examples' imports, spelled through this: the package's export
// rewrites every line shaped as a directive, a string's too.
const String _import = 'import';

// In drip's design kit, ui_core's libraries are lib/design_kit, beside the
// checks' (checks/, alignment.dart, review.dart, internal/drawn_pixels.dart:
// their examples are compiled by checks_doc_examples_test.dart and
// review_doc_examples_test.dart) and drip's own (design_kit.dart,
// annotations.dart, chrome.dart, routing.dart), which ui_core leaves out.
// The package's lib holds ui_core's alone.
const Set<String> _notUiCore = {
  'alignment.dart',
  'review.dart',
  'internal/drawn_pixels.dart',
  'design_kit.dart',
  'annotations.dart',
  'chrome.dart',
  'routing.dart',
};

/// The fenced dart blocks of [source]'s doc comments, each as its lines
/// without the `///`, as a look's check reads them.
List<String> docSnippets(String source) {
  final snippets = <String>[];
  List<String>? open;
  for (final raw in source.split('\n')) {
    final m = RegExp(r'^\s*/// ?(.*)$').firstMatch(raw);
    if (m == null) {
      open = null;
      continue;
    }
    final line = m[1]!;
    if (open == null && line.trim() == '```dart') {
      open = [];
    } else if (open != null && line.trim() == '```') {
      snippets.add(open.join('\n'));
      open = null;
    } else {
      open?.add(line);
    }
  }
  return snippets;
}

/// [source] as the package ships it: each `/// Example: <call>` line (the
/// one call the planner's sheet shows for a part) a fenced dart block.
String exampleSnippets(String source) => source.replaceAllMapped(
  RegExp(r'^([ \t]*)/// Example: (.+)$', multiLine: true),
  (m) => '${m[1]}///\n${m[1]}/// ```dart\n${m[1]}/// ${m[2]}\n${m[1]}/// ```',
);

/// [snippet] as a look's check declares it: a library of its own, else a
/// function's body or an expression, the [i]th.
({String? library, String? member}) snippetDeclaration(String snippet, int i) {
  if (RegExp(
    r'^(?:class|import|(?:void|Future(?:<void>)?)\s+main)\b',
    multiLine: true,
  ).hasMatch(snippet)) {
    return (library: snippet, member: null);
  }
  final code = snippet.trim();
  final statements =
      RegExp(r';\s*$').hasMatch(code) ||
      RegExp(
        r'^(?:final|var|late|await|if|for|return)\b',
        multiLine: true,
      ).hasMatch(code);
  return (
    library: null,
    member: statements
        ? 'Future<void> snippet$i(BuildContext context) async {\n$snippet\n}'
        : 'Object? snippet$i(BuildContext context) => '
              '${code.replaceFirst(RegExp(r';$'), '')};',
  );
}

/// The names the analyser's machine [output] calls undefined, as a look's
/// check frees them.
Set<String> undefinedNames(String output) => {
  for (final line in output.split('\n'))
    if (line.split('|') case final p when p.length >= 8)
      if (RegExp(
        r'^UNDEFINED_(IDENTIFIER|FUNCTION|CLASS|METHOD)$|'
        r'^CREATION_WITH_NON_TYPE$|^CONST_WITH_NON_TYPE$',
      ).hasMatch(p[2]))
        if (RegExp(r"'([A-Za-z_]\w*)'").firstMatch(p.skip(7).join('|'))
            case final m?)
          m[1]!,
};

void main() {
  test(
    "each example compiles on its own, as a look's check compiles it",
    () async {
      final kit = Directory('lib/design_kit').existsSync();
      final lib = Directory(kit ? 'lib/design_kit' : 'lib');
      final name = RegExp(
        r'^name:\s*(\S+)',
        multiLine: true,
      ).firstMatch(File('pubspec.yaml').readAsStringSync())![1]!;
      final under = kit ? 'design_kit/' : '';
      String relative(File f) =>
          f.path.substring(lib.path.length + 1).replaceAll(r'\', '/');
      final files = [
        for (final f in lib.listSync(recursive: true))
          if (f is File &&
              f.path.endsWith('.dart') &&
              !relative(f).startsWith('checks/') &&
              !_notUiCore.contains(relative(f)))
            f,
      ]..sort((a, b) => a.path.compareTo(b.path));
      final imports = [
        "$_import 'package:flutter/services.dart';",
        "$_import 'package:flutter/widgets.dart';",
        // Material, as an app has it (material_ui, as a look's check imports
        // it; Flutter's own library in drip's kit, which takes no package).
        kit
            ? "$_import 'package:flutter/material.dart';"
            : "$_import 'package:material_ui/material_ui.dart';",
        for (final f in files)
          if (!relative(f).contains('/') &&
              !RegExp(
                r'^part of\b',
                multiLine: true,
              ).hasMatch(f.readAsStringSync()))
            "$_import 'package:$name/$under${relative(f)}';",
        "$_import 'free.dart';",
      ];
      final examples = [
        for (final f in files)
          for (final snippet in docSnippets(
            exampleSnippets(f.readAsStringSync()),
          ))
            (file: relative(f), snippet: snippet),
      ];
      expect(examples, isNotEmpty);

      final dir = Directory('test').createTempSync('doc_examples_alone_');
      addTearDown(() => dir.deleteSync(recursive: true));
      // As a look's copy-out app analyses them: Dart's own defaults.
      File('${dir.path}/analysis_options.yaml').writeAsStringSync('\n');
      for (final (i, e) in examples.indexed) {
        final d = snippetDeclaration(e.snippet, i);
        final library = d.library;
        File('${dir.path}/example_$i.dart').writeAsStringSync(
          library == null
              ? '${imports.join('\n')}\n\n${d.member}\n'
              : RegExp(r'^import ', multiLine: true).hasMatch(library)
              ? '$library\n'
              : '${imports.join('\n')}\n\n$library\n',
        );
      }
      Future<String> analyse(Set<String> free) async {
        File('${dir.path}/free.dart').writeAsStringSync(
          [
            "$_import 'package:flutter/widgets.dart';",
            for (final n in free)
              RegExp('^[A-Z]').hasMatch(n)
                  ? 'class $n extends StatelessWidget {\n'
                        '  const $n({super.key});\n'
                        '  @override\n'
                        '  Widget build(BuildContext context) => '
                        'const SizedBox();\n'
                        '}'
                  : 'dynamic $n;',
          ].join('\n'),
        );
        final run = await Process.run('dart', [
          'analyze',
          '--format=machine',
          dir.path,
        ]);
        return '${run.stdout}\n${run.stderr}';
      }

      final free = undefinedNames(await analyse(const {}));
      final output = await analyse(free);
      expect(
        [
          for (final line in output.split('\n'))
            if (line.split('|') case final p
                when p.length >= 8 && p[0] == 'ERROR')
              if (RegExp(r'example_(\d+)\.dart$').firstMatch(p[3])
                  case final m?)
                '${examples[int.parse(m[1]!)].file}: '
                    '${p.skip(7).join('|').trim()} (${p[2]})',
        ],
        isEmpty,
        reason: 'free names: ${(free.toList()..sort()).join(', ')}',
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
