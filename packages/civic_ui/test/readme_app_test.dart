// The README's Dart. Its first block is a whole app of 12 lines or fewer
// (the production bar's line 5): it imports civic_ui, calls runApp and puts
// Civic's host over the app. Every block compiles: a block with imports as
// a file of its own, any other one as an expression in a file that imports
// Civic and Material, where `context` and `child` are in scope. Copied into
// files of this package and analysed, they give no error and no warning.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _prelude = '''
// ignore_for_file: unused_import, unused_element
import 'package:civic_ui/civic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
''';

List<String> _blocks() => [
  for (final match in RegExp(
    r'```dart\n([\s\S]*?)```',
  ).allMatches(File('README.md').readAsStringSync()))
    match.group(1)!,
];

ProcessResult _analyze(String path) {
  final root = Platform.environment['FLUTTER_ROOT'];
  final dart = root == null ? 'dart' : '$root/bin/dart';
  return Process.runSync(dart, ['analyze', '--fatal-warnings', path]);
}

void main() {
  test('the README opens with a minimal app', () {
    final block = _blocks().first;
    expect(block.trimRight().split('\n'), hasLength(lessThanOrEqualTo(12)));
    expect(block, contains("import 'package:civic_ui/civic_ui.dart';"));
    expect(block, contains('runApp('));
    expect(block, contains('CivicHost('));
  });

  test('every Dart block in the README compiles', () {
    final blocks = _blocks();
    expect(blocks, hasLength(greaterThan(6)));
    final dir = Directory('test/zz_readme_blocks')..createSync(recursive: true);
    addTearDown(() => dir.deleteSync(recursive: true));
    for (final (i, block) in blocks.indexed) {
      final source = block.contains("import '")
          ? block
          : '$_prelude\n'
                'Object? readmeBlock$i(BuildContext context, Widget child) =>\n'
                '    ${block.trim().replaceFirst(RegExp(r';$'), '')};\n';
      File('${dir.path}/block_$i.dart').writeAsStringSync(source);
    }
    final result = _analyze(dir.path);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  }, timeout: const Timeout(Duration(minutes: 4)));
}
