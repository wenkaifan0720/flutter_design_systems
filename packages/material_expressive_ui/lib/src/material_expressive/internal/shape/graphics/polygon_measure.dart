part of 'graphics.dart';

/// A polygon whose curves are measured and given outline progress values.
class ExpressiveMeasuredPolygon {
  ExpressiveMeasuredPolygon._({
    required ExpressiveMeasurer measurer,
    required this._features,
    required List<ExpressiveShapeCubic> cubics,
    required List<double> outlineProgress,
  }) : assert(
         outlineProgress.length == cubics.length + 1,
         'Outline progress length is expected to be the cubics length + 1',
       ),
       assert(
         outlineProgress.first == 0,
         'First outline progress value is expected to be zero',
       ),
       assert(
         outlineProgress.last == 1,
         'Last outline progress value is expected to be one',
       ),
       _measurer = measurer {
    final measuredCubics = <ExpressiveMeasuredCubic>[];
    var startOutlineProgress = 0.0;
    for (var i = 0; i < cubics.length; i++) {
      // Filter out "empty" cubics.
      if ((outlineProgress[i + 1] - outlineProgress[i]) > _distanceEpsilon) {
        measuredCubics.add(
          ExpressiveMeasuredCubic(
            measurer: measurer,
            cubic: cubics[i],
            startOutlineProgress: startOutlineProgress,
            endOutlineProgress: outlineProgress[i + 1],
          ),
        );
        // The next measured cubic will start exactly where this one ends.
        startOutlineProgress = outlineProgress[i + 1];
      }
    }
    // We could have removed empty cubics at the end. Ensure the last measured
    // cubic ends at 1.
    measuredCubics[measuredCubics.length - 1].updateProgressRange(
      endOutlineProgress: 1,
    );
    _cubics = measuredCubics;
  }

  /// The polygon [polygon] measured by [measurer].
  factory ExpressiveMeasuredPolygon.measurePolygon(
    ExpressiveMeasurer measurer,
    ExpressiveRoundedPolygon polygon,
  ) {
    final cubics = <ExpressiveShapeCubic>[];
    final featureToCubic = <(ExpressiveFeature, int)>[];

    // Get the cubics from the polygon, at the same time, extract the features
    // and keep a reference to the representative cubic we will use.
    for (
      var featureIndex = 0;
      featureIndex < polygon.features.length;
      featureIndex++
    ) {
      final feature = polygon.features[featureIndex];
      for (
        var cubicIndex = 0;
        cubicIndex < feature.cubics.length;
        cubicIndex++
      ) {
        if (feature is ExpressiveCornerFeature &&
            cubicIndex == feature.cubics.length ~/ 2) {
          featureToCubic.add((feature, cubics.length));
        }
        cubics.add(feature.cubics[cubicIndex]);
      }
    }

    final measures = List<double>.filled(cubics.length + 1, 0);
    var totalMeasure = 0.0;

    for (var i = 0; i < cubics.length; i++) {
      final measure = measurer.measureCubic(cubics[i]);
      if (measure < 0) {
        throw StateError(
          'Measured cubic is expected to be greater or equal to zero',
        );
      }
      totalMeasure += measure;
      measures[i + 1] = totalMeasure;
    }

    final outlineProgress = List<double>.filled(measures.length, 0);
    for (var i = 0; i < measures.length; i++) {
      outlineProgress[i] = measures[i] / totalMeasure;
    }

    final features = List<ExpressiveProgressableFeature>.generate(
      featureToCubic.length,
      (i) {
        final ix = featureToCubic[i].$2;
        return ExpressiveProgressableFeature(
          (outlineProgress[ix] + outlineProgress[ix + 1]) / 2,
          featureToCubic[i].$1,
        );
      },
    );

    return ExpressiveMeasuredPolygon._(
      measurer: measurer,
      features: features,
      cubics: cubics,
      outlineProgress: outlineProgress,
    );
  }

  final ExpressiveMeasurer _measurer;

  late final List<ExpressiveMeasuredCubic> _cubics;

  final List<ExpressiveProgressableFeature> _features;

  /// The polygon's features with their outline progress.
  List<ExpressiveProgressableFeature> get features =>
      UnmodifiableListView(_features);

  /// The first measured curve.
  ExpressiveMeasuredCubic get first => _cubics.first;

  /// The last measured curve.
  ExpressiveMeasuredCubic get last => _cubics.last;

  /// The number of measured curves.
  int get length => _cubics.length;

  /// The measured curve at [index].
  ExpressiveMeasuredCubic operator [](int index) => _cubics[index];

  /// The measured curve at [index], or null when [index] is out of range.
  ExpressiveMeasuredCubic? getOrNull(int index) {
    final length = _cubics.length;

    if (index < 0 || index >= length) {
      return null;
    }

    return _cubics[index];
  }

  /// Finds the point in the input list of measured cubics that pass the given
  /// outline progress, and generates a new MeasuredPolygon (equivalent to
  /// this), that starts at that point. This usually means cutting the cubic
  /// that crosses the outline progress (unless the cut is at one of its ends).
  /// For example, given outline progress 0.4f and measured cubics on these
  /// outline progress ranges:
  ///
  /// c1 [0 -> 0.2] c2 [0.2 -> 0.5] c3 [0.5 -> 1.0]
  ///
  /// c2 will be cut in two, at the given outline progress, we can name these
  /// c2a [0.2 -> 0.4] and c2b [0.4 -> 0.5]
  ///
  /// The return then will have measured cubics [c2b, c3, c1, c2a], and they
  /// will have their outline progress ranges adjusted so the new list starts
  /// at 0.
  ///
  /// c2b [0 -> 0.1] c3 [0.1 -> 0.6] c1 [0.6 -> 0.8] c2a [0.8 -> 1.0]
  ExpressiveMeasuredPolygon cutAndShift(double cuttingPoint) {
    if (cuttingPoint < 0 && cuttingPoint > 1) {
      throw ArgumentError('Cutting point is expected to be between 0 and 1');
    }

    if (cuttingPoint < _distanceEpsilon) return this;

    // Find the index of cubic we want to cut
    final targetIndex = _cubics.indexWhere(
      (c) =>
          cuttingPoint >= c._startOutlineProgress &&
          cuttingPoint <= c._endOutlineProgress,
    );
    final target = _cubics[targetIndex];

    // Cut the target cubic.
    // b1, b2 are two resulting cubics after cut
    final (b1, b2) = target.cutAtProgress(cuttingPoint);

    // Construct the list of the cubics we need:
    // * The second part of the target cubic (after the cut)
    // * All cubics after the target, until the end + All cubics from the
    //   start, before the target cubic
    // * The first part of the target cubic (before the cut)
    final retCubics = [b2.cubic];
    for (var i = 1; i < _cubics.length; i++) {
      retCubics.add(_cubics[(i + targetIndex) % _cubics.length].cubic);
    }
    retCubics.add(b1.cubic);

    // Construct the array of outline progress.
    // For example, if we have 3 cubics with outline progress [0 .. 0.3],
    // [0.3 .. 0.8] & [0.8 .. 1.0], and we cut + shift at 0.6:
    // 0.  0123456789
    //     |--|--/-|-|
    // The outline progresses will start at 0 (the cutting point, that shifts
    // to 0.0), then 0.8 - 0.6 = 0.2, then 1 - 0.6 = 0.4, then 0.3 - 0.6 + 1 =
    // 0.7, then 1 (the cutting point again), all together: (0.0, 0.2, 0.4,
    // 0.7, 1.0)
    final retOutlineProgress = List<double>.filled(_cubics.length + 2, 0);

    for (var i = 0; i < _cubics.length + 2; i++) {
      if (i == 0) {
        retOutlineProgress[i] = 0;
      } else if (i == _cubics.length + 1) {
        retOutlineProgress[i] = 1;
      } else {
        final cubicIndex = (targetIndex + i - 1) % _cubics.length;
        retOutlineProgress[i] = _positiveModulo(
          _cubics[cubicIndex]._endOutlineProgress - cuttingPoint,
          1,
        );
      }
    }

    // Shift the feature's outline progress too.
    final newFeatures = [
      for (var i = 0; i < _features.length; i++)
        ExpressiveProgressableFeature(
          _positiveModulo(_features[i].progress - cuttingPoint, 1),
          _features[i].feature,
        ),
    ];

    // Filter out all empty cubics (i.e. start and end anchor are (almost) the
    // same point.)
    return ExpressiveMeasuredPolygon._(
      measurer: _measurer,
      features: newFeatures,
      cubics: retCubics,
      outlineProgress: retOutlineProgress,
    );
  }
}

/// A MeasuredCubic holds information about the cubic itself, the feature
/// (if any) associated with it, and the outline progress values (start and
/// end) for the cubic. This information is used to match cubics between shapes
/// that lie at similar outline progress positions along their respective
/// shapes (after matching features and shifting).
///
/// Outline progress is a value in [0..1) that represents the distance traveled
/// along the overall outline path of the shape.
class ExpressiveMeasuredCubic {
  /// A measured [cubic] spanning the given outline progress range.
  ExpressiveMeasuredCubic({
    required this.measurer,
    required this.cubic,
    required double startOutlineProgress,
    required double endOutlineProgress,
  }) : assert(
         startOutlineProgress >= 0 && startOutlineProgress <= 1,
         'startOutlineProgress has to be in [0..1] range',
       ),
       assert(
         endOutlineProgress >= 0 && endOutlineProgress <= 1,
         'endOutlineProgress has to be in range [0..1]',
       ),
       assert(
         endOutlineProgress >= startOutlineProgress,
         'endOutlineProgress is expected to be equal or greater than '
         'startOutlineProgress',
       ),
       _startOutlineProgress = startOutlineProgress,
       _endOutlineProgress = endOutlineProgress {
    measuredSize = measurer.measureCubic(cubic);
  }

  /// The measurer that sized the curve.
  final ExpressiveMeasurer measurer;

  /// The curve.
  final ExpressiveShapeCubic cubic;

  /// The curve's size as [measurer] measures it.
  late final double measuredSize;

  double _startOutlineProgress;

  double _endOutlineProgress;

  /// The outline progress where the curve starts.
  double get startOutlineProgress => _startOutlineProgress;

  /// The outline progress where the curve ends.
  double get endOutlineProgress => _endOutlineProgress;

  /// Sets the outline progress range, keeping a bound left null.
  void updateProgressRange({
    double? startOutlineProgress,
    double? endOutlineProgress,
  }) {
    startOutlineProgress ??= _startOutlineProgress;
    endOutlineProgress ??= _endOutlineProgress;

    if (endOutlineProgress < startOutlineProgress) {
      throw ArgumentError(
        'endOutlineProgress is expected to be equal or greater than '
        'startOutlineProgress',
      );
    }

    _startOutlineProgress = startOutlineProgress;
    _endOutlineProgress = endOutlineProgress;
  }

  /// Cut this [ExpressiveMeasuredCubic] into two at the given outline progress value.
  (ExpressiveMeasuredCubic, ExpressiveMeasuredCubic) cutAtProgress(
    double cutOutlineProgress,
  ) {
    // Floating point errors further up can cause cutOutlineProgress to land
    // just slightly outside of the start/end progress for this cubic, so we
    // limit it to those bounds to avoid further errors later
    final boundedCutOutlineProgress = cutOutlineProgress.coerceIn(
      _startOutlineProgress,
      _endOutlineProgress,
    );
    final outlineProgressSize = _endOutlineProgress - _startOutlineProgress;
    final progressFromStart = boundedCutOutlineProgress - _startOutlineProgress;

    // Note that in earlier parts of the computation, we have empty
    // MeasuredCubics (cubics with progressSize == 0), but those cubics are
    // filtered out before this method is called.
    final relativeProgress = progressFromStart / outlineProgressSize;
    final t = measurer.findCubicCutPoint(
      cubic,
      relativeProgress * measuredSize,
    );

    if (t < 0 || t > 1) {
      throw ArgumentError(
        'ShapeCubic cut point is expected to be between 0 and 1.',
      );
    }

    // c1/c2 are the two new cubics, then we return MeasuredCubics created
    // from them.
    final (c1, c2) = cubic.split(t);
    return (
      ExpressiveMeasuredCubic(
        measurer: measurer,
        cubic: c1,
        startOutlineProgress: _startOutlineProgress,
        endOutlineProgress: boundedCutOutlineProgress,
      ),
      ExpressiveMeasuredCubic(
        measurer: measurer,
        cubic: c2,
        startOutlineProgress: boundedCutOutlineProgress,
        endOutlineProgress: _endOutlineProgress,
      ),
    );
  }

  @override
  String toString() {
    return 'MeasuredCubic(outlineProgress='
        '[$_startOutlineProgress .. $_endOutlineProgress], '
        'size=$measuredSize, cubic=$cubic)';
  }
}

/// Interface for measuring a cubic. Implementations can use whatever algorithm
/// desired to produce these measurement values.
abstract interface class ExpressiveMeasurer {
  const ExpressiveMeasurer();

  /// Returns size of given cubic, according to however the implementation
  /// wants to measure the size (angle, length, etc). It has to be greater or
  /// equal to 0.
  double measureCubic(ExpressiveShapeCubic c);

  /// Given a cubic and a measure that should be between 0 and the value
  /// returned by measureCubic (if not, it will be capped), finds the parameter
  /// t of the cubic at which that measure is reached.
  double findCubicCutPoint(ExpressiveShapeCubic c, double m);
}

/// Measures a cubic by the angle it sweeps around ([centerX], [centerY]):
/// the measurer graphics-shapes 1.0.1 (what Compose material3 1.5.0-alpha29
/// runs on) matches morphs with.
class ExpressiveAngleMeasurer implements ExpressiveMeasurer {
  /// A measurer about ([centerX], [centerY]).
  const ExpressiveAngleMeasurer(this.centerX, this.centerY);

  /// The x coordinate of the centre the angle is taken about.
  final double centerX;

  /// The y coordinate of the centre the angle is taken about.
  final double centerY;

  @override
  double measureCubic(ExpressiveShapeCubic c) {
    final swept = _positiveModulo(
      _angle(c.anchor1X - centerX, c.anchor1Y - centerY) -
          _angle(c.anchor0X - centerX, c.anchor0Y - centerY),
      _twoPi,
    );
    // Avoid an empty cubic to measure almost 2π.
    return swept > _twoPi - _distanceEpsilon ? 0 : swept;
  }

  @override
  double findCubicCutPoint(ExpressiveShapeCubic c, double m) {
    final angle0 = _angle(c.anchor0X - centerX, c.anchor0Y - centerY);
    return _findMinimum(0, 1, tolerance: 1e-5, (t) {
      final point = c.pointOnCurve(t);
      final a = _angle(point.x - centerX, point.y - centerY);
      return (_positiveModulo(a - angle0, _twoPi) - m).abs();
    });
  }
}
