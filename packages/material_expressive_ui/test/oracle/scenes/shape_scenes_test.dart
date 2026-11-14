/// The `shape` oracle group (Compose twin: `ShapeScenes.kt`): the corner
/// scale, its inner-corner variants, and the 35 library shapes.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/keys.g.dart';

import '../harness/oracle.dart';

/// The scale, smallest first, by key segment.
const List<(String, ExpressiveCorner)> shapeCorners = [
  ('none', ExpressiveCorner.none),
  ('extra-small', ExpressiveCorner.extraSmall),
  ('small', ExpressiveCorner.small),
  ('medium', ExpressiveCorner.medium),
  ('large', ExpressiveCorner.large),
  ('large-increased', ExpressiveCorner.largeIncreased),
  ('extra-large', ExpressiveCorner.extraLarge),
  ('extra-large-increased', ExpressiveCorner.extraLargeIncreased),
  ('extra-extra-large', ExpressiveCorner.extraExtraLarge),
  ('full', ExpressiveCorner.full),
];

/// The inner-corner variants the tokens name.
const List<(String, ExpressiveShapeKey)> shapeVariants = [
  ('extra-small-top', ExpressiveShapeKey.cornerExtraSmallTop),
  ('large-top', ExpressiveShapeKey.cornerLargeTop),
  ('large-start', ExpressiveShapeKey.cornerLargeStart),
  ('large-end', ExpressiveShapeKey.cornerLargeEnd),
  ('extra-large-top', ExpressiveShapeKey.cornerExtraLargeTop),
];

/// `cookie4Sided` → `cookie-4-sided`, `clover4Leaf` → `clover-4-leaf`: the
/// library shape's key segment.
String shapeSegment(ExpressiveMaterialShape shape) => shape.name
    .replaceAll(RegExp('(?<=[a-z])(?=[A-Z0-9])|(?<=[0-9])(?=[A-Za-z])'), '-')
    .toLowerCase();

/// Three 96 dp `primaryContainer` boxes to a row, 16 dp apart, each
/// recording its radii.
Widget _grid(
  BuildContext context,
  List<(String, ShapeBorder Function(ExpressiveShapes))> shapes,
) {
  final theme = context.expressiveTheme;
  // Compose's Column starts its rows; a short last row sits left.
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 16,
    children: [
      for (var i = 0; i < shapes.length; i += 3)
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            for (final (name, shapeOf) in shapes.skip(i).take(3))
              OracleTag(
                'corner-$name',
                shape: shapeOf(theme.shapes),
                child: SizedBox.square(
                  dimension: 96,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: theme.colors.primaryContainer,
                      shape: shapeOf(theme.shapes),
                    ),
                  ),
                ),
              ),
          ],
        ),
    ],
  );
}

final OracleGroup shapeScenes = OracleGroup(
  id: 'shape',
  scenes: [
    OracleScene(
      key: 'shape/corners',
      size: const Size(336, 448),
      build: (context) => _grid(context, [
        for (final (name, corner) in shapeCorners)
          (name, (ExpressiveShapes s) => s.corner(corner)),
      ]),
    ),
    OracleScene(
      key: 'shape/corner-variants',
      size: const Size(336, 224),
      build: (context) => _grid(context, [
        for (final (name, key) in shapeVariants)
          (name, (ExpressiveShapes s) => s.of(key)),
      ]),
    ),
    for (final shape in ExpressiveMaterialShape.values)
      OracleScene(
        key: 'shape/library/${shapeSegment(shape)}',
        size: const Size(96, 96),
        build: (context) => OracleTag(
          'shape',
          child: SizedBox.square(
            dimension: 80,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: context.expressiveTheme.colors.primary,
                shape: ExpressiveMaterialShapeBorder(shape),
              ),
            ),
          ),
        ),
      ),
  ],
);

void main() => runOracleGroup(shapeScenes);
