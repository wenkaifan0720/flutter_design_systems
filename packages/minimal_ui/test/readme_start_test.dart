// The README's first Dart block is a whole app that compiles and runs:
// readme_start.dart holds it word for word.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'readme_start.dart' as start;

// The code alone: whitespace aside, and Material by either of its imports
// (a package's tests may name material_ui where an app names Flutter's).
String _code(String source) => source
    .substring(source.indexOf('import '))
    .replaceAll(
      'package:material_ui/material_ui.dart',
      'package:flutter/material.dart',
    )
    .replaceAll(RegExp(r'\s+'), '');

void main() {
  test('the README opens with readme_start.dart, in 12 lines or fewer', () {
    final readme = File('README.md').readAsStringSync();
    final open = readme.indexOf('```dart\n') + '```dart\n'.length;
    final block = readme.substring(open, readme.indexOf('```', open));
    expect(
      _code(block),
      _code(File('test/readme_start.dart').readAsStringSync()),
    );
    expect(block.trim().split('\n'), hasLength(lessThanOrEqualTo(12)));
  });

  testWidgets("the start runs: its row stands in the host's theme", (
    tester,
  ) async {
    start.main();
    await tester.pump();
    expect(find.text('Middlemarch'), findsOneWidget);
    expect(
      MinimalTheme.of(tester.element(find.byType(MinimalListTile))).id,
      'standard',
    );
  });
}
