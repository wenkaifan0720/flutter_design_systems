// Every doc example of the review's checks, compiled and run: each fenced dart block
// in their files is written out below, so an example that stops compiling
// fails analysis, and the first test fails when they have an example this
// file lacks. The checks take a tester, so their examples are functions the
// checks' own tests run in their shapes.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_review/ui_core_review.dart';

import 'doc_examples.dart';

/// [DesignAlignmentMatrix.check]'s example: it takes a tester, so it is
/// compiled here and run by alignment_test.dart.
Future<void> _alignmentCheck(
  WidgetTester tester,
  DesignAlignmentMatrix matrix,
) async {
  final report = await matrix.check(
    pump: tester.pumpWidget,
    runAsync: tester.runAsync,
  );
  report.verify();
}

/// The screen [DesignKeylineCheck]'s example checks.
class SettingsScreen extends StatelessWidget {
  /// A screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// [DesignKeylineCheck]'s example: it takes a tester, so it is compiled
/// here and run by keyline_test.dart.
Future<void> _keylineCheck(WidgetTester tester) async {
  final report = await const DesignKeylineCheck(look: 'Comic').check(
    tester.element(find.byType(SettingsScreen)),
    runAsync: tester.runAsync,
  );
  report.verify();
}

/// [DesignRowCheck]'s example, run by row_check_test.dart's shape.
Future<void> _rowCheck(WidgetTester tester) async {
  final report = await const DesignRowCheck(look: 'Comic').check(
    tester.element(find.byType(SettingsScreen)),
    runAsync: tester.runAsync,
  );
  report.verify();
}

/// [DesignFieldPartsCheck]'s example, run by field_parts_check_test.dart's
/// shape.
Future<void> _fieldPartsCheck(WidgetTester tester) async {
  final report = await const DesignFieldPartsCheck(look: 'Comic').check(
    tester.element(find.byType(SettingsScreen)),
    runAsync: tester.runAsync,
  );
  report.verify();
}

/// [DesignWidthCheck]'s example, run by width_check_test.dart's shape.
Future<void> _widthCheck(WidgetTester tester, Key fieldKey) async {
  const widths = DesignWidthCheck(look: 'Comic');
  (await widths.check(
    tester.element(find.byType(SettingsScreen)),
    runAsync: tester.runAsync,
  )).verify();
  (await widths.checkList(
    tester.element(find.byKey(fieldKey)),
    runAsync: tester.runAsync,
  )).verify();
}

/// [DesignSpacingCheck]'s example.
Future<void> _spacingCheck(WidgetTester tester) async {
  final report = await const DesignSpacingCheck(look: 'Comic').check(
    tester.element(find.byType(SettingsScreen)),
    runAsync: tester.runAsync,
  );
  report.verify();
}

/// [DesignSpacingCheck.literals]' example: a look's sources read from its
/// lib folder.
void _spacingLiterals() {
  final lib = Directory('lib');
  final sources = {
    for (final f in lib.listSync(recursive: true).whereType<File>())
      if (f.path.endsWith('.dart')) f.path: f.readAsStringSync(),
  };
  const DesignSpacingCheck(look: 'Comic').literals(sources).verify();
}

/// [DesignSpacingCheck.literals]' example on the look's own grid.
void _spacingLiteralsOnGrid(WidgetTester tester, Map<String, String> sources) {
  const DesignSpacingCheck(look: 'Retro')
      .literals(sources, context: tester.element(find.byType(SettingsScreen)))
      .verify();
}

/// The image settling that [DesignKeylineCheck]'s docs ask for before a
/// check, run by keyline_test.dart.
Future<void> _settleImages(WidgetTester tester) async {
  await tester.runAsync(
    () => Future.wait([
      for (final e in find.byType(Image).evaluate())
        precacheImage((e.widget as Image).image, e),
    ]),
  );
  await tester.pump();
}

/// The review's files: ui_core_review's own, and part of drip's kit, whose
/// other files' examples are ui_core's and ui_core_test's.
const Set<String> _reviewFiles = {
  'review.dart',
  'alignment_matrix.dart',
  'field_parts_check.dart',
  'keyline_check.dart',
  'row_check.dart',
  'spacing_check.dart',
  'width_check.dart',
};

void main() {
  test('the checks the examples call are compiled here', () {
    expect(_alignmentCheck, isNotNull);
    expect(_keylineCheck, isNotNull);
    expect(_settleImages, isNotNull);
    expect(_rowCheck, isNotNull);
    expect(_fieldPartsCheck, isNotNull);
    expect(_widthCheck, isNotNull);
    expect(_spacingCheck, isNotNull);
    expect(_spacingLiterals, isNotNull);
    expect(_spacingLiteralsOnGrid, isNotNull);
  });

  testDocExamples(
    self: 'test/review_doc_examples_test.dart',
    examples: const {},
    wrap: (child) => child,
    skip: {
      for (final file in Directory('lib').listSync(recursive: true))
        if (!_reviewFiles.contains(file.uri.pathSegments.last))
          file.uri.pathSegments.last,
    },
  );
}
