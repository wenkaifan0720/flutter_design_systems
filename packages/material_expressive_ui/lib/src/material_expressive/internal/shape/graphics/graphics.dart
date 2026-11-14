/// androidx graphics-shapes (1.0.1, the version Compose material3
/// 1.5.0-alpha29 depends on) in Dart: [ExpressiveRoundedPolygon], [ExpressiveCornerRounding],
/// [ExpressiveShapeCubic] and [ExpressivePolygonMorph] — what `MaterialShapes.kt` builds its 35 shapes on.
///
/// VENDORED from `material_new_shapes` 1.0.0 (MIT, Copyright (c) 2025
/// Agbama Gifted; its notice is THIRD_PARTY_NOTICES/
/// material_new_shapes-1.0.0-MIT.txt), itself a port of androidx
/// graphics-shapes (Apache-2.0, The Android Open Source Project; notice
/// beside it). The package ports graphics-shapes 1.1, whose morph matching
/// differs from the 1.0.1 Compose runs, so the matching is taken back to
/// 1.0.1: `AngleMeasurer` (not `LengthMeasurer`), 1.0.1's `featureMapper`
/// and `doMapping`, its progress validation and its `DistanceEpsilon`
/// (1e-4). Also: the package's `meta` and `vector_math` imports dropped
/// (Flutter's foundation gives `immutable`), its Matrix4 and Path
/// extensions removed, `Morph.morphMatch` exposed as in Kotlin, and
/// [ExpressivePolygonMorph.writePath] added, which interpolates the matched cubics straight
/// into a caller's reused `Path` without allocating (the package's
/// `asCubics` builds new cubics every frame). Held to Compose's own cubics
/// by `test/shape_test.dart` (`test/shape_golden.json`).
///
/// Owner: w1-shape. Internal: `shape.dart` is the public surface.
library;

import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show immutable;

part 'corner_rounding.dart';
part 'cubic.dart';
part 'feature_mapping.dart';
part 'features.dart';
part 'float_mapping.dart';
part 'morph.dart';
part 'point.dart';
part 'polygon_measure.dart';
part 'rounded_polygon.dart';
part 'utils.dart';
