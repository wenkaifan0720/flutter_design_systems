// The description each of the checks' review sheets gives of itself in the
// inspector and in a failing test's tree: each field it is built with, a
// field at its default hidden.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_review/ui_core_review.dart';

const DesignAlignmentMatrix _matrix = DesignAlignmentMatrix(
  look: 'Test',
  themes: {},
  rows: [],
);

List<String> _description(Widget part) {
  final builder = DiagnosticPropertiesBuilder();
  part.debugFillProperties(builder);
  return [
    for (final p in builder.properties)
      if (!p.isFiltered(DiagnosticLevel.info)) p.toString(),
  ];
}

void main() {
  test('each sheet, built with what it requires, says so and hides its '
      'defaults', () {
    expect(_description(const DesignAlignmentSheet(matrix: _matrix)), [
      'matrix: Instance of \'DesignAlignmentMatrix\'',
    ]);
    expect(_description(const DesignKeylineSheet(child: SizedBox())), isEmpty);
  });

  test('each sheet says each field set off its default', () {
    expect(
      _description(
        const DesignAlignmentSheet(matrix: _matrix, theme: 'night', zoom: 2),
      ),
      [
        'matrix: Instance of \'DesignAlignmentMatrix\'',
        'theme: "night"',
        'zoom: 2.0',
      ],
    );
    expect(
      _description(
        const DesignKeylineSheet(
          check: DesignKeylineCheck(look: 'Comic'),
          child: SizedBox(),
        ),
      ),
      hasLength(1),
    );
  });

  test('an alignment sheet at no zoom asserts', () {
    expect(
      () => DesignAlignmentSheet(matrix: _matrix, zoom: 0),
      throwsAssertionError,
    );
  });
}
