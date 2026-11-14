// Deliberately unusual app-supplied borders exercise the open OutlinedBorder API
// through a part's style. These are stress fixtures, not Material Expressive
// presets or gallery choices.
import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

/// One outline for each kind of part: a small mark, a one-line pill, a wide
/// one-line box and a tall box.
typedef TestShapes = ({
  OutlinedBorder mark,
  OutlinedBorder pill,
  OutlinedBorder wide,
  OutlinedBorder tall,
});

/// [shape] as a part's style.
ExpressiveComponentThemeData shapedStyle(
  OutlinedBorder shape, [
  ExpressiveComponentThemeData? style,
]) => (style ?? const ExpressiveComponentThemeData()).copyWith(
  shape: WidgetStatePropertyAll(shape),
);

const TestShapes roundedTestShapes = (
  mark: ExpressiveContentBorder(
    ExpressiveMaterialShapeBorder(ExpressiveMaterialShape.square),
    inset: 5,
  ),
  pill: ExpressiveContentBorder(
    ExpressiveCornerBorder.all(ExpressiveCornerSize.dp(20)),
    inset: 6,
  ),
  wide: ExpressiveContentBorder(
    ExpressiveCornerBorder.all(ExpressiveCornerSize.dp(12)),
    inset: 4,
  ),
  tall: ExpressiveContentBorder(
    ExpressiveCornerBorder.all(ExpressiveCornerSize.dp(16)),
    inset: 5,
  ),
);

const TestShapes cookieTestShapes = (
  mark: ExpressiveContentBorder(
    ExpressiveMaterialShapeBorder(ExpressiveMaterialShape.cookie6Sided),
    inset: 12,
  ),
  pill: ExpressiveContentBorder(
    ExpressiveCornerBorder.all(ExpressiveCornerSize.dp(20)),
    inset: 6,
  ),
  wide: ExpressiveContentBorder(
    ExpressiveCornerBorder.all(ExpressiveCornerSize.dp(12)),
    inset: 4,
  ),
  tall: ExpressiveContentBorder(
    ExpressiveCornerBorder.all(ExpressiveCornerSize.dp(16)),
    inset: 5,
  ),
);

const TestShapes scallopedTestShapes = (
  mark: ExpressiveContentBorder(
    ExpressiveMaterialShapeBorder(ExpressiveMaterialShape.cookie12Sided),
    inset: 12,
  ),
  pill: ExpressiveContentBorder(
    ExpressiveCornerBorder.all(ExpressiveCornerSize.dp(20)),
    inset: 6,
  ),
  wide: ExpressiveContentBorder(
    ExpressiveCornerBorder.all(ExpressiveCornerSize.dp(12)),
    inset: 4,
  ),
  tall: ExpressiveContentBorder(
    ExpressiveCornerBorder.all(ExpressiveCornerSize.dp(16)),
    inset: 5,
  ),
);
