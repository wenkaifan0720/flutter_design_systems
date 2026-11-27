/// A part's corner on Gloss's steps.
library;

import 'package:ui_core/ui_core.dart';

import '../theme.dart';

/// The corner of [step] in [theme]; with [at], a part's corner at Gloss's own
/// [step], kept in proportion as an app's theme makes the step rounder or
/// squarer: a table's tick (6 beside a socket's 7), a row's plate in its
/// well (10 in a well of 16).
double glossCorner(GlossThemeData theme, RawCorner step, [double? at]) {
  final r = theme.shapeScheme.corners.radius(step);
  if (at == null) return r;
  return r * at / GlossThemeData.defaultShapeScheme.corners.radius(step);
}
