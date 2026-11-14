part of 'graphics.dart';

/// MeasuredFeatures contains a list of all features in a polygon along with
/// the [0..1] progress at that feature.
typedef ExpressiveMeasuredFeatures = List<ExpressiveProgressableFeature>;

/// A feature and the outline progress it stands at.
class ExpressiveProgressableFeature {
  /// A feature [feature] at [progress].
  const ExpressiveProgressableFeature(this.progress, this.feature);

  /// The outline progress the feature stands at, from 0 to 1.
  final double progress;

  /// The feature.
  final ExpressiveFeature feature;
}

/// Maps the corners of [features1] onto those of [features2] (graphics-shapes
/// 1.0.1 `featureMapper`): the side with fewer corners is kept whole, and
/// each of its corners is matched in order to the nearest corner of the
/// other, never going backwards (`doMapping`).
ExpressiveDoubleMapper _featureMapper(
  ExpressiveMeasuredFeatures features1,
  ExpressiveMeasuredFeatures features2,
) {
  final filteredFeatures1 = <ExpressiveProgressableFeature>[
    for (final f in features1)
      if (f.feature.isCorner) f,
  ];
  final filteredFeatures2 = <ExpressiveProgressableFeature>[
    for (final f in features2)
      if (f.feature.isCorner) f,
  ];
  final (m1, m2) = filteredFeatures1.length > filteredFeatures2.length
      ? (_doMapping(filteredFeatures2, filteredFeatures1), filteredFeatures2)
      : (filteredFeatures1, _doMapping(filteredFeatures1, filteredFeatures2));
  final mm = <(double, double)>[
    for (var i = 0; i < m1.length && i < m2.length; i++)
      (m1[i].progress, m2[i].progress),
  ];
  return ExpressiveDoubleMapper(mm);
}

/// For each feature of [f1], in order, the nearest feature of [f2] after the
/// one last picked, leaving room for the rest (graphics-shapes 1.0.1).
ExpressiveMeasuredFeatures _doMapping(
  ExpressiveMeasuredFeatures f1,
  ExpressiveMeasuredFeatures f2,
) {
  int minBy(int from, int to, double Function(int) f) {
    var best = from;
    var bestValue = f(from);
    for (var i = from + 1; i <= to; i++) {
      final value = f(i);
      if (value < bestValue) {
        best = i;
        bestValue = value;
      }
    }
    return best;
  }

  final m = f1.length;
  final n = f2.length;
  final ix = minBy(
    0,
    n - 1,
    (i) => _featureDistSquared(f1[0].feature, f2[i].feature),
  );
  final ret = <ExpressiveProgressableFeature>[f2[ix]];
  var lastPicked = ix;
  for (var i = 1; i < m; i++) {
    var last = ix - (m - i);
    if (last <= lastPicked) last += n;
    final best = minBy(
      lastPicked + 1,
      last,
      (it) => _featureDistSquared(f1[i].feature, f2[it % n].feature),
    );
    ret.add(f2[best % n]);
    lastPicked = best;
  }
  return ret;
}

/// Returns distance along overall shape between two Features on the two
/// different shapes. This information is used to determine how to map features
/// (and the curves that make up those features).
double _featureDistSquared(ExpressiveFeature f1, ExpressiveFeature f2) {
  // TODO: We might want to enable concave-convex matching in some situations.
  // If so, the approach below will not work
  if (f1 is ExpressiveCornerFeature &&
      f2 is ExpressiveCornerFeature &&
      f1.convex != f2.convex) {
    // Simple hack to force all features to map only to features of the same
    // concavity, by returning an infinitely large distance in that case.
    return double.maxFinite;
  }

  return (_featureRepresentativePoint(f1) - _featureRepresentativePoint(f2))
      .getDistanceSquared();
}

// TODO: b/378441547 - Move to explicit parameter / expose?
/// The point midway between the first curve's start and the last curve's end.
ExpressivePoint _featureRepresentativePoint(ExpressiveFeature feature) {
  final cubics = feature.cubics;
  final x = (cubics.first.anchor0X + cubics.last.anchor1X) / 2;
  final y = (cubics.first.anchor0Y + cubics.last.anchor1Y) / 2;
  return ExpressivePoint(x, y);
}
