// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Material's HCT colour space (hue, chroma, tone), as material_color_utilities
/// 0.13.0 computes it: its math and colour utilities, CAM16 and its viewing
/// conditions, the HCT solver, `Hct` and `Contrast`, copied unchanged but
/// for their imports. What ui_core's palette maths stands on, so a tone it
/// gives is the tone a Material scheme gives. Internal; not exported.
///
/// ui_core carries no dependency on material_color_utilities: Flutter pins
/// it exactly, and a range here would stop resolving when Flutter moves.
/// THIRD_PARTY_NOTICES/material_color_utilities-0.13.0-Apache-2.0.txt.
library;

// Copied as material_color_utilities documents it, a few of its members
// without a comment of their own.
// ignore_for_file: public_member_api_docs

import 'dart:core';
import 'dart:math';
import 'dart:math' as math;

// ---- utils/math_utils.dart ----

/// Number helpers for the colour space below: clamping, rounding and
/// wrapping degrees.
class MathUtils {
  /// The signum function.
  ///
  /// Returns 1 if num > 0, -1 if num < 0, and 0 if num = 0
  static int signum(double num) {
    if (num < 0) {
      return -1;
    } else if (num == 0) {
      return 0;
    } else {
      return 1;
    }
  }

  /// The linear interpolation function.
  ///
  /// Returns start if amount = 0 and stop if amount = 1
  static double lerp(double start, double stop, double amount) {
    return (1.0 - amount) * start + amount * stop;
  }

  /// Clamps an integer between two integers.
  ///
  /// Returns input when min <= input <= max, and either min or max
  /// otherwise.
  static int clampInt(int min, int max, int input) {
    if (input < min) {
      return min;
    } else if (input > max) {
      return max;
    }

    return input;
  }

  /// Clamps an integer between two floating-point numbers.
  ///
  /// Returns input when min <= input <= max, and either min or max
  /// otherwise.
  static double clampDouble(double min, double max, double input) {
    if (input < min) {
      return min;
    } else if (input > max) {
      return max;
    }

    return input;
  }

  /// Sanitizes a degree measure as an integer.
  ///
  /// Returns a degree measure between 0 (inclusive) and 360
  /// (exclusive).
  static int sanitizeDegreesInt(int degrees) {
    degrees = degrees % 360;
    if (degrees < 0) {
      degrees = degrees + 360;
    }
    return degrees;
  }

  /// Sanitizes a degree measure as a floating-point number.
  ///
  /// Returns a degree measure between 0.0 (inclusive) and 360.0
  /// (exclusive).
  static double sanitizeDegreesDouble(double degrees) {
    degrees = degrees % 360.0;
    if (degrees < 0) {
      degrees = degrees + 360.0;
    }
    return degrees;
  }

  /// Sign of direction change needed to travel from one angle to
  /// another.
  ///
  /// For angles that are 180 degrees apart from each other, both
  /// directions have the same travel distance, so either direction is
  /// shortest. The value 1.0 is returned in this case.
  ///
  /// [from] The angle travel starts from, in degrees.
  /// [to] The angle travel ends at, in degrees.
  /// Returns -1 if decreasing from leads to the shortest travel
  /// distance, 1 if increasing from leads to the shortest travel
  /// distance.
  static double rotationDirection(double from, double to) {
    final increasingDifference = sanitizeDegreesDouble(to - from);
    return increasingDifference <= 180.0 ? 1.0 : -1.0;
  }

  /// Distance of two points on a circle, represented using degrees.
  static double differenceDegrees(double a, double b) {
    return 180.0 - ((a - b).abs() - 180.0).abs();
  }

  /// Multiplies a 1x3 row vector with a 3x3 matrix.
  static List<double> matrixMultiply(
    List<double> row,
    List<List<double>> matrix,
  ) {
    final a =
        row[0] * matrix[0][0] + row[1] * matrix[0][1] + row[2] * matrix[0][2];
    final b =
        row[0] * matrix[1][0] + row[1] * matrix[1][1] + row[2] * matrix[1][2];
    final c =
        row[0] * matrix[2][0] + row[1] * matrix[2][1] + row[2] * matrix[2][2];
    return [a, b, c];
  }
}

// ---- utils/color_utils.dart ----

/// Color science utilities.
///
/// Utility methods for color science constants and color space
/// conversions that aren't HCT or CAM16.
class ColorUtils {
  static const _srgbToXyz = [
    [0.41233895, 0.35762064, 0.18051042],
    [0.2126, 0.7152, 0.0722],
    [0.01932141, 0.11916382, 0.95034478],
  ];

  static const _xyzToSrgb = [
    [3.2413774792388685, -1.5376652402851851, -0.49885366846268053],
    [-0.9691452513005321, 1.8758853451067872, 0.04156585616912061],
    [0.05562093689691305, -0.20395524564742123, 1.0571799111220335],
  ];

  static const _whitePointD65 = [95.047, 100.0, 108.883];

  /// Converts a color from RGB components to ARGB format.
  static int argbFromRgb(int red, int green, int blue) {
    return 255 << 24 | (red & 255) << 16 | (green & 255) << 8 | blue & 255;
  }

  /// Converts a color from linear RGB components to ARGB format.
  static int argbFromLinrgb(List<double> linrgb) {
    final r = delinearized(linrgb[0]);
    final g = delinearized(linrgb[1]);
    final b = delinearized(linrgb[2]);
    return argbFromRgb(r, g, b);
  }

  /// Returns the alpha component of a color in ARGB format.
  static int alphaFromArgb(int argb) {
    return argb >> 24 & 255;
  }

  /// Returns the red component of a color in ARGB format.
  static int redFromArgb(int argb) {
    return argb >> 16 & 255;
  }

  /// Returns the green component of a color in ARGB format.
  static int greenFromArgb(int argb) {
    return argb >> 8 & 255;
  }

  /// Returns the blue component of a color in ARGB format.
  static int blueFromArgb(int argb) {
    return argb & 255;
  }

  /// Returns whether a color in ARGB format is opaque.
  static bool isOpaque(int argb) {
    return alphaFromArgb(argb) >= 255;
  }

  /// Converts a color from ARGB to XYZ.
  static int argbFromXyz(double x, double y, double z) {
    final matrix = _xyzToSrgb;
    final linearR = matrix[0][0] * x + matrix[0][1] * y + matrix[0][2] * z;
    final linearG = matrix[1][0] * x + matrix[1][1] * y + matrix[1][2] * z;
    final linearB = matrix[2][0] * x + matrix[2][1] * y + matrix[2][2] * z;
    final r = delinearized(linearR);
    final g = delinearized(linearG);
    final b = delinearized(linearB);
    return argbFromRgb(r, g, b);
  }

  /// Converts a color from XYZ to ARGB.
  static List<double> xyzFromArgb(int argb) {
    final r = linearized(redFromArgb(argb));
    final g = linearized(greenFromArgb(argb));
    final b = linearized(blueFromArgb(argb));
    return MathUtils.matrixMultiply([r, g, b], _srgbToXyz);
  }

  /// Converts a color represented in Lab color space into an ARGB
  /// integer.
  static int argbFromLab(double l, double a, double b) {
    final whitePoint = _whitePointD65;
    final fy = (l + 16.0) / 116.0;
    final fx = a / 500.0 + fy;
    final fz = fy - b / 200.0;
    final xNormalized = _labInvf(fx);
    final yNormalized = _labInvf(fy);
    final zNormalized = _labInvf(fz);
    final x = xNormalized * whitePoint[0];
    final y = yNormalized * whitePoint[1];
    final z = zNormalized * whitePoint[2];
    return argbFromXyz(x, y, z);
  }

  /// Converts a color from ARGB representation to L*a*b*
  /// representation.
  ///
  /// [argb] the ARGB representation of a color
  /// Returns a Lab object representing the color
  static List<double> labFromArgb(int argb) {
    final linearR = linearized(redFromArgb(argb));
    final linearG = linearized(greenFromArgb(argb));
    final linearB = linearized(blueFromArgb(argb));
    final matrix = _srgbToXyz;
    final x =
        matrix[0][0] * linearR +
        matrix[0][1] * linearG +
        matrix[0][2] * linearB;
    final y =
        matrix[1][0] * linearR +
        matrix[1][1] * linearG +
        matrix[1][2] * linearB;
    final z =
        matrix[2][0] * linearR +
        matrix[2][1] * linearG +
        matrix[2][2] * linearB;
    final whitePoint = _whitePointD65;
    final xNormalized = x / whitePoint[0];
    final yNormalized = y / whitePoint[1];
    final zNormalized = z / whitePoint[2];
    final fx = _labF(xNormalized);
    final fy = _labF(yNormalized);
    final fz = _labF(zNormalized);
    final l = 116.0 * fy - 16;
    final a = 500.0 * (fx - fy);
    final b = 200.0 * (fy - fz);
    return [l, a, b];
  }

  /// Converts an L* value to an ARGB representation.
  ///
  /// [lstar] L* in L*a*b*
  /// Returns ARGB representation of grayscale color with lightness
  /// matching L*
  static int argbFromLstar(double lstar) {
    final y = yFromLstar(lstar);
    final component = delinearized(y);
    return argbFromRgb(component, component, component);
  }

  /// Computes the L* value of a color in ARGB representation.
  ///
  /// [argb] ARGB representation of a color
  /// Returns L*, from L*a*b*, coordinate of the color
  static double lstarFromArgb(int argb) {
    final y = xyzFromArgb(argb)[1];
    return 116.0 * _labF(y / 100.0) - 16.0;
  }

  /// Converts an L* value to a Y value.
  ///
  /// L* in L*a*b* and Y in XYZ measure the same quantity, luminance.
  ///
  /// L* measures perceptual luminance, a linear scale. Y in XYZ
  /// measures relative luminance, a logarithmic scale.
  ///
  /// [lstar] L* in L*a*b*
  /// Returns Y in XYZ
  static double yFromLstar(double lstar) {
    return 100.0 * _labInvf((lstar + 16.0) / 116.0);
  }

  /// Converts a Y value to an L* value.
  ///
  /// L* in L*a*b* and Y in XYZ measure the same quantity, luminance.
  ///
  /// L* measures perceptual luminance, a linear scale. Y in XYZ
  /// measures relative luminance, a logarithmic scale.
  ///
  /// [y] Y in XYZ
  /// Returns L* in L*a*b*
  static double lstarFromY(double y) {
    return _labF(y / 100.0) * 116.0 - 16.0;
  }

  /// Linearizes an RGB component.
  ///
  /// [rgbComponent] 0 <= rgb_component <= 255, represents R/G/B
  /// channel
  /// Returns 0.0 <= output <= 100.0, color channel converted to
  /// linear RGB space
  static double linearized(int rgbComponent) {
    final normalized = rgbComponent / 255.0;
    if (normalized <= 0.040449936) {
      return normalized / 12.92 * 100.0;
    } else {
      return pow((normalized + 0.055) / 1.055, 2.4).toDouble() * 100.0;
    }
  }

  /// Delinearizes an RGB component.
  ///
  /// [rgbComponent] 0.0 <= rgb_component <= 100.0, represents linear
  /// R/G/B channel
  /// Returns 0 <= output <= 255, color channel converted to regular
  /// RGB space
  static int delinearized(double rgbComponent) {
    final normalized = rgbComponent / 100.0;
    var delinearized = 0.0;
    if (normalized <= 0.0031308) {
      delinearized = normalized * 12.92;
    } else {
      delinearized = 1.055 * pow(normalized, 1.0 / 2.4).toDouble() - 0.055;
    }
    return MathUtils.clampInt(0, 255, (delinearized * 255.0).round());
  }

  /// Returns the standard white point; white on a sunny day.
  ///
  /// Returns The white point
  static List<double> whitePointD65() {
    return _whitePointD65;
  }

  static double _labF(double t) {
    final e = 216.0 / 24389.0;
    final kappa = 24389.0 / 27.0;
    if (t > e) {
      return pow(t, 1.0 / 3.0).toDouble();
    } else {
      return (kappa * t + 16) / 116;
    }
  }

  static double _labInvf(double ft) {
    final e = 216.0 / 24389.0;
    final kappa = 24389.0 / 27.0;
    final ft3 = ft * ft * ft;
    if (ft3 > e) {
      return ft3;
    } else {
      return (116 * ft - 16) / kappa;
    }
  }
}

// ---- hct/viewing_conditions.dart ----

/// In traditional color spaces, a color can be identified solely by the
/// observer's measurement of the color. Color appearance models such as CAM16
/// also use information about the environment where the color was
/// observed, known as the viewing conditions.
///
/// For example, white under the traditional assumption of a midday sun white
/// point is accurately measured as a slightly chromatic blue by CAM16.
/// (roughly, hue 203, chroma 3, lightness 100)
///
/// This class caches intermediate values of the CAM16 conversion process that
/// depend only on viewing conditions, enabling speed ups.
class ViewingConditions {
  static final standard = sRgb;
  static final sRgb = ViewingConditions.make();

  final List<double> whitePoint;
  final double adaptingLuminance;
  final double backgroundLstar;
  final double surround;
  final bool discountingIlluminant;

  final double backgroundYTowhitePointY;
  final double aw;
  final double nbb;
  final double ncb;
  final double c;
  final double nC;
  final List<double> drgbInverse;
  final List<double> rgbD;
  final double fl;
  final double fLRoot;
  final double z;

  const ViewingConditions({
    required this.whitePoint,
    required this.adaptingLuminance,
    required this.backgroundLstar,
    required this.surround,
    required this.discountingIlluminant,
    required this.backgroundYTowhitePointY,
    required this.aw,
    required this.nbb,
    required this.ncb,
    required this.c,
    required this.nC,
    required this.drgbInverse,
    required this.rgbD,
    required this.fl,
    required this.fLRoot,
    required this.z,
  });

  /// Convenience constructor for [ViewingConditions].
  ///
  /// Parameters affecting color appearance include:
  /// [whitePoint]: coordinates of white in XYZ color space.
  /// [adaptingLuminance]: light strength, in lux.
  /// [backgroundLstar]: average luminance of 10 degrees around color.
  /// [surround]: brightness of the entire environment.
  /// [discountingIlluminant]: whether eyes have adjusted to lighting.
  factory ViewingConditions.make({
    List<double>? whitePoint,
    double adaptingLuminance = -1.0,
    double backgroundLstar = 50.0,
    double surround = 2.0,
    bool discountingIlluminant = false,
  }) {
    whitePoint ??= ColorUtils.whitePointD65();

    adaptingLuminance = (adaptingLuminance > 0.0)
        ? adaptingLuminance
        : (200.0 / math.pi * ColorUtils.yFromLstar(50.0) / 100.0);
    // A background of pure black is non-physical and leads to infinities that
    // represent the idea that any color viewed in pure black can't be seen.
    backgroundLstar = math.max(0.1, backgroundLstar);
    // Transform test illuminant white in XYZ to 'cone'/'rgb' responses
    final xyz = whitePoint;
    final rW = xyz[0] * 0.401288 + xyz[1] * 0.650173 + xyz[2] * -0.051461;
    final gW = xyz[0] * -0.250268 + xyz[1] * 1.204414 + xyz[2] * 0.045854;
    final bW = xyz[0] * -0.002079 + xyz[1] * 0.048952 + xyz[2] * 0.953127;

    // Scale input surround, domain (0, 2), to CAM16 surround, domain (0.8, 1.0)
    assert(surround >= 0.0 && surround <= 2.0);
    final f = 0.8 + (surround / 10.0);
    // "Exponential non-linearity"
    final c = (f >= 0.9)
        ? MathUtils.lerp(0.59, 0.69, (f - 0.9) * 10.0)
        : MathUtils.lerp(0.525, 0.59, (f - 0.8) * 10.0);
    // Calculate degree of adaptation to illuminant
    var d = discountingIlluminant
        ? 1.0
        : f *
              (1.0 -
                  ((1.0 / 3.6) * math.exp((-adaptingLuminance - 42.0) / 92.0)));
    // Per Li et al, if D is greater than 1 or less than 0, set it to 1 or 0.
    d = (d > 1.0)
        ? 1.0
        : (d < 0.0)
        ? 0.0
        : d;
    // chromatic induction factor
    final nc = f;

    // Cone responses to the whitePoint, r/g/b/W, adjusted for discounting.
    //
    // Why use 100.0 instead of the white point's relative luminance?
    //
    // Some papers and implementations, for both CAM02 and CAM16, use the Y
    // value of the reference white instead of 100. Fairchild's Color Appearance
    // Models (3rd edition) notes that this is in error: it was included in the
    // CIE 2004a report on CIECAM02, but, later parts of the conversion process
    // account for scaling of appearance relative to the white point relative
    // luminance. This part should simply use 100 as luminance.
    final rgbD = <double>[
      d * (100.0 / rW) + 1.0 - d,
      d * (100.0 / gW) + 1.0 - d,
      d * (100.0 / bW) + 1.0 - d,
    ];

    // Factor used in calculating meaningful factors
    final k = 1.0 / (5.0 * adaptingLuminance + 1.0);
    final k4 = k * k * k * k;
    final k4F = 1.0 - k4;

    // Luminance-level adaptation factor
    final fl =
        (k4 * adaptingLuminance) +
        (0.1 * k4F * k4F * math.pow(5.0 * adaptingLuminance, 1.0 / 3.0));
    // Intermediate factor, ratio of background relative luminance to white relative luminance
    final n = ColorUtils.yFromLstar(backgroundLstar) / whitePoint[1];

    // Base exponential nonlinearity
    // note Schlomer 2018 has a typo and uses 1.58, the correct factor is 1.48
    final z = 1.48 + math.sqrt(n);

    // Luminance-level induction factors
    final nbb = 0.725 / math.pow(n, 0.2);
    final ncb = nbb;

    // Discounted cone responses to the white point, adjusted for post-saturationtic
    // adaptation perceptual nonlinearities.
    final rgbAFactors = [
      math.pow(fl * rgbD[0] * rW / 100.0, 0.42),
      math.pow(fl * rgbD[1] * gW / 100.0, 0.42),
      math.pow(fl * rgbD[2] * bW / 100.0, 0.42),
    ];

    final rgbA = [
      (400.0 * rgbAFactors[0]) / (rgbAFactors[0] + 27.13),
      (400.0 * rgbAFactors[1]) / (rgbAFactors[1] + 27.13),
      (400.0 * rgbAFactors[2]) / (rgbAFactors[2] + 27.13),
    ];

    final aw = (40.0 * rgbA[0] + 20.0 * rgbA[1] + rgbA[2]) / 20.0 * nbb;

    return ViewingConditions(
      whitePoint: whitePoint,
      adaptingLuminance: adaptingLuminance,
      backgroundLstar: backgroundLstar,
      surround: surround,
      discountingIlluminant: discountingIlluminant,
      backgroundYTowhitePointY: n,
      aw: aw,
      nbb: nbb,
      ncb: ncb,
      c: c,
      nC: nc,
      drgbInverse: [0.0, 0.0, 0.0],
      rgbD: rgbD,
      fl: fl,
      fLRoot: math.pow(fl, 0.25).toDouble(),
      z: z,
    );
  }
}

// ---- hct/cam16.dart ----

/// CAM16, a color appearance model. Colors are not just defined by their hex
/// code, but rather, a hex code and viewing conditions.
///
/// CAM16 instances also have coordinates in the CAM16-UCS space, called J*, a*,
/// b*, or jstar, astar, bstar in code. CAM16-UCS is included in the CAM16
/// specification, and should be used when measuring distances between colors.
///
/// In traditional color spaces, a color can be identified solely by the
/// observer's measurement of the color. Color appearance models such as CAM16
/// also use information about the environment where the color was
/// observed, known as the viewing conditions.
///
/// For example, white under the traditional assumption of a midday sun white
/// point is accurately measured as a slightly chromatic blue by CAM16.
/// (roughly, hue 203, chroma 3, lightness 100)
/// CAM16, a color appearance model. Colors are not just defined by their hex
/// code, but rather, a hex code and viewing conditions.
///
/// CAM16 instances also have coordinates in the CAM16-UCS space, called J*, a*,
/// b*, or jstar, astar, bstar in code. CAM16-UCS is included in the CAM16
/// specification, and should be used when measuring distances between colors.
///
/// In traditional color spaces, a color can be identified solely by the
/// observer's measurement of the color. Color appearance models such as CAM16
/// also use information about the environment where the color was
/// observed, known as the viewing conditions.
///
/// For example, white under the traditional assumption of a midday sun white
/// point is accurately measured as a slightly chromatic blue by CAM16.
/// (roughly, hue 203, chroma 3, lightness 100)
class Cam16 {
  /// Like red, orange, yellow, green, etc.
  final double hue;

  /// Informally, colorfulness / color intensity. Like saturation in HSL,
  /// except perceptually accurate.
  final double chroma;

  /// Lightness
  final double j;

  /// Brightness; ratio of lightness to white point's lightness
  final double q;

  /// Colorfulness
  final double m;

  /// Saturation; ratio of chroma to white point's chroma
  final double s;

  /// CAM16-UCS J coordinate
  final double jstar;

  /// CAM16-UCS a coordinate
  final double astar;

  /// CAM16-UCS b coordinate
  final double bstar;

  /// All of the CAM16 dimensions can be calculated from 3 of the dimensions, in
  /// the following combinations:
  ///     -  {j or q} and {c, m, or s} and hue
  ///     - jstar, astar, bstar
  /// Prefer using a static method that constructs from 3 of those dimensions.
  /// This constructor is intended for those methods to use to return all
  /// possible dimensions.
  Cam16(
    this.hue,
    this.chroma,
    this.j,
    this.q,
    this.m,
    this.s,
    this.jstar,
    this.astar,
    this.bstar,
  );

  /// CAM16 instances also have coordinates in the CAM16-UCS space, called J*,
  /// a*, b*, or jstar, astar, bstar in code. CAM16-UCS is included in the CAM16
  /// specification, and should be used when measuring distances between colors.
  double distance(Cam16 other) {
    final dJ = jstar - other.jstar;
    final dA = astar - other.astar;
    final dB = bstar - other.bstar;
    final dEPrime = math.sqrt(dJ * dJ + dA * dA + dB * dB);
    final dE = 1.41 * math.pow(dEPrime, 0.63);
    return dE;
  }

  /// Convert [argb] to CAM16, assuming the color was viewed in default viewing
  /// conditions.
  static Cam16 fromInt(int argb) {
    return fromIntInViewingConditions(argb, ViewingConditions.sRgb);
  }

  /// Given [viewingConditions], convert [argb] to CAM16.
  static Cam16 fromIntInViewingConditions(
    int argb,
    ViewingConditions viewingConditions,
  ) {
    // Transform ARGB int to XYZ
    final xyz = ColorUtils.xyzFromArgb(argb);
    final x = xyz[0];
    final y = xyz[1];
    final z = xyz[2];
    return fromXyzInViewingConditions(x, y, z, viewingConditions);
  }

  /// Given color expressed in XYZ and viewed in [viewingConditions], convert to
  /// CAM16.
  static Cam16 fromXyzInViewingConditions(
    double x,
    double y,
    double z,
    ViewingConditions viewingConditions,
  ) {
    // Transform XYZ to 'cone'/'rgb' responses

    final rC = 0.401288 * x + 0.650173 * y - 0.051461 * z;
    final gC = -0.250268 * x + 1.204414 * y + 0.045854 * z;
    final bC = -0.002079 * x + 0.048952 * y + 0.953127 * z;

    // Discount illuminant
    final rD = viewingConditions.rgbD[0] * rC;
    final gD = viewingConditions.rgbD[1] * gC;
    final bD = viewingConditions.rgbD[2] * bC;

    // chromatic adaptation
    final rAF = math
        .pow(viewingConditions.fl * rD.abs() / 100.0, 0.42)
        .toDouble();
    final gAF = math
        .pow(viewingConditions.fl * gD.abs() / 100.0, 0.42)
        .toDouble();
    final bAF = math
        .pow(viewingConditions.fl * bD.abs() / 100.0, 0.42)
        .toDouble();
    final rA = MathUtils.signum(rD) * 400.0 * rAF / (rAF + 27.13);
    final gA = MathUtils.signum(gD) * 400.0 * gAF / (gAF + 27.13);
    final bA = MathUtils.signum(bD) * 400.0 * bAF / (bAF + 27.13);

    // redness-greenness
    final a = (11.0 * rA + -12.0 * gA + bA) / 11.0;
    // yellowness-blueness
    final b = (rA + gA - 2.0 * bA) / 9.0;

    // auxiliary components
    final u = (20.0 * rA + 20.0 * gA + 21.0 * bA) / 20.0;
    final p2 = (40.0 * rA + 20.0 * gA + bA) / 20.0;

    // hue
    final atan2 = math.atan2(b, a);
    final atanDegrees = atan2 * 180.0 / math.pi;
    final hue = atanDegrees < 0
        ? atanDegrees + 360.0
        : atanDegrees >= 360
        ? atanDegrees - 360
        : atanDegrees;
    final hueRadians = hue * math.pi / 180.0;
    assert(hue >= 0 && hue < 360, 'hue was really $hue');

    // achromatic response to color
    final ac = p2 * viewingConditions.nbb;

    // CAM16 lightness and brightness
    final J =
        100.0 *
        math.pow(
          ac / viewingConditions.aw,
          viewingConditions.c * viewingConditions.z,
        );
    final Q =
        (4.0 / viewingConditions.c) *
        math.sqrt(J / 100.0) *
        (viewingConditions.aw + 4.0) *
        (viewingConditions.fLRoot);

    final huePrime = (hue < 20.14) ? hue + 360 : hue;
    final eHue =
        (1.0 / 4.0) * (math.cos(huePrime * math.pi / 180.0 + 2.0) + 3.8);
    final p1 =
        50000.0 / 13.0 * eHue * viewingConditions.nC * viewingConditions.ncb;
    final t = p1 * math.sqrt(a * a + b * b) / (u + 0.305);
    final alpha =
        math.pow(t, 0.9) *
        math.pow(
          1.64 - math.pow(0.29, viewingConditions.backgroundYTowhitePointY),
          0.73,
        );
    // CAM16 chroma, colorfulness, chroma
    final C = alpha * math.sqrt(J / 100.0);
    final M = C * viewingConditions.fLRoot;
    final s =
        50.0 *
        math.sqrt((alpha * viewingConditions.c) / (viewingConditions.aw + 4.0));

    // CAM16-UCS components
    final jstar = (1.0 + 100.0 * 0.007) * J / (1.0 + 0.007 * J);
    final mstar = math.log(1.0 + 0.0228 * M) / 0.0228;
    final astar = mstar * math.cos(hueRadians);
    final bstar = mstar * math.sin(hueRadians);
    return Cam16(hue, C, J, Q, M, s, jstar, astar, bstar);
  }

  /// Create a CAM16 color from lightness [j], chroma [c], and hue [h],
  /// assuming the color was viewed in default viewing conditions.
  static Cam16 fromJch(double j, double c, double h) {
    return fromJchInViewingConditions(j, c, h, ViewingConditions.sRgb);
  }

  /// Create a CAM16 color from lightness [j], chroma [C], and hue [h],
  /// in [viewingConditions].
  static Cam16 fromJchInViewingConditions(
    double J,
    double C,
    double h,
    ViewingConditions viewingConditions,
  ) {
    final Q =
        (4.0 / viewingConditions.c) *
        math.sqrt(J / 100.0) *
        (viewingConditions.aw + 4.0) *
        (viewingConditions.fLRoot);
    final M = C * viewingConditions.fLRoot;
    final alpha = C / math.sqrt(J / 100.0);
    final s =
        50.0 *
        math.sqrt((alpha * viewingConditions.c) / (viewingConditions.aw + 4.0));

    final hueRadians = h * math.pi / 180.0;
    final jstar = (1.0 + 100.0 * 0.007) * J / (1.0 + 0.007 * J);
    final mstar = 1.0 / 0.0228 * math.log(1.0 + 0.0228 * M);
    final astar = mstar * math.cos(hueRadians);
    final bstar = mstar * math.sin(hueRadians);
    return Cam16(h, C, J, Q, M, s, jstar, astar, bstar);
  }

  /// Create a CAM16 color from CAM16-UCS coordinates [jstar], [astar], [bstar].
  /// assuming the color was viewed in default viewing conditions.
  static Cam16 fromUcs(double jstar, double astar, double bstar) {
    return fromUcsInViewingConditions(
      jstar,
      astar,
      bstar,
      ViewingConditions.standard,
    );
  }

  /// Create a CAM16 color from CAM16-UCS coordinates [jstar], [astar], [bstar].
  /// in [viewingConditions].
  static Cam16 fromUcsInViewingConditions(
    double jstar,
    double astar,
    double bstar,
    ViewingConditions viewingConditions,
  ) {
    final a = astar;
    final b = bstar;
    final m = math.sqrt(a * a + b * b);
    final M = (math.exp(m * 0.0228) - 1.0) / 0.0228;
    final c = M / viewingConditions.fLRoot;
    var h = math.atan2(b, a) * (180.0 / math.pi);
    if (h < 0.0) {
      h += 360.0;
    }
    final j = jstar / (1 - (jstar - 100) * 0.007);

    return Cam16.fromJchInViewingConditions(j, c, h, viewingConditions);
  }

  /// ARGB representation of color, assuming the color was viewed in default
  /// viewing conditions.
  int toInt() {
    return viewed(ViewingConditions.sRgb);
  }

  // Avoid allocations during conversion by pre-allocating an array.
  final _viewedArray = <double>[0, 0, 0];

  /// ARGB representation of a color, given the color was viewed in
  /// [viewingConditions]
  int viewed(ViewingConditions viewingConditions) {
    final xyz = xyzInViewingConditions(viewingConditions, array: _viewedArray);
    final argb = ColorUtils.argbFromXyz(xyz[0], xyz[1], xyz[2]);
    return argb;
  }

  /// XYZ representation of CAM16 seen in [viewingConditions].
  List<double> xyzInViewingConditions(
    ViewingConditions viewingConditions, {
    List<double>? array,
  }) {
    final alpha = (chroma == 0.0 || j == 0.0)
        ? 0.0
        : chroma / math.sqrt(j / 100.0);

    final t = math.pow(
      alpha /
          math.pow(
            1.64 - math.pow(0.29, viewingConditions.backgroundYTowhitePointY),
            0.73,
          ),
      1.0 / 0.9,
    );
    final hRad = hue * math.pi / 180.0;

    final eHue = 0.25 * (math.cos(hRad + 2.0) + 3.8);
    final ac =
        viewingConditions.aw *
        math.pow(j / 100.0, 1.0 / viewingConditions.c / viewingConditions.z);
    final p1 =
        eHue * (50000.0 / 13.0) * viewingConditions.nC * viewingConditions.ncb;

    final p2 = ac / viewingConditions.nbb;

    final hSin = math.sin(hRad);
    final hCos = math.cos(hRad);

    final gamma =
        23.0 *
        (p2 + 0.305) *
        t /
        (23.0 * p1 + 11 * t * hCos + 108.0 * t * hSin);
    final a = gamma * hCos;
    final b = gamma * hSin;
    final rA = (460.0 * p2 + 451.0 * a + 288.0 * b) / 1403.0;
    final gA = (460.0 * p2 - 891.0 * a - 261.0 * b) / 1403.0;
    final bA = (460.0 * p2 - 220.0 * a - 6300.0 * b) / 1403.0;

    final rCBase = math.max(0, (27.13 * rA.abs()) / (400.0 - rA.abs()));
    final rC =
        MathUtils.signum(rA) *
        (100.0 / viewingConditions.fl) *
        math.pow(rCBase, 1.0 / 0.42);
    final gCBase = math.max(0, (27.13 * gA.abs()) / (400.0 - gA.abs()));
    final gC =
        MathUtils.signum(gA) *
        (100.0 / viewingConditions.fl) *
        math.pow(gCBase, 1.0 / 0.42);
    final bCBase = math.max(0, (27.13 * bA.abs()) / (400.0 - bA.abs()));
    final bC =
        MathUtils.signum(bA) *
        (100.0 / viewingConditions.fl) *
        math.pow(bCBase, 1.0 / 0.42);
    final rF = rC / viewingConditions.rgbD[0];
    final gF = gC / viewingConditions.rgbD[1];
    final bF = bC / viewingConditions.rgbD[2];

    final x = 1.86206786 * rF - 1.01125463 * gF + 0.14918677 * bF;
    final y = 0.38752654 * rF + 0.62144744 * gF - 0.00897398 * bF;
    final z = -0.01584150 * rF - 0.03412294 * gF + 1.04996444 * bF;

    if (array != null) {
      array[0] = x;
      array[1] = y;
      array[2] = z;
      return array;
    } else {
      return [x, y, z];
    }
  }
}

// ---- hct/src/hct_solver.dart ----

/// A class that solves the HCT equation.
class HctSolver {
  static const _scaledDiscountFromLinrgb = [
    [0.001200833568784504, 0.002389694492170889, 0.0002795742885861124],
    [0.0005891086651375999, 0.0029785502573438758, 0.0003270666104008398],
    [0.00010146692491640572, 0.0005364214359186694, 0.0032979401770712076],
  ];

  static const _linrgbFromScaledDiscount = [
    [1373.2198709594231, -1100.4251190754821, -7.278681089101213],
    [-271.815969077903, 559.6580465940733, -32.46047482791194],
    [1.9622899599665666, -57.173814538844006, 308.7233197812385],
  ];

  static const _yFromLinrgb = [0.2126, 0.7152, 0.0722];

  static const _criticalPlanes = [
    0.015176349177441876,
    0.045529047532325624,
    0.07588174588720938,
    0.10623444424209313,
    0.13658714259697685,
    0.16693984095186062,
    0.19729253930674434,
    0.2276452376616281,
    0.2579979360165119,
    0.28835063437139563,
    0.3188300904430532,
    0.350925934958123,
    0.3848314933096426,
    0.42057480301049466,
    0.458183274052838,
    0.4976837250274023,
    0.5391024159806381,
    0.5824650784040898,
    0.6277969426914107,
    0.6751227633498623,
    0.7244668422128921,
    0.775853049866786,
    0.829304845476233,
    0.8848452951698498,
    0.942497089126609,
    1.0022825574869039,
    1.0642236851973577,
    1.1283421258858297,
    1.1946592148522128,
    1.2631959812511864,
    1.3339731595349034,
    1.407011200216447,
    1.4823302800086415,
    1.5599503113873272,
    1.6398909516233677,
    1.7221716113234105,
    1.8068114625156377,
    1.8938294463134073,
    1.9832442801866852,
    2.075074464868551,
    2.1693382909216234,
    2.2660538449872063,
    2.36523901573795,
    2.4669114995532007,
    2.5710888059345764,
    2.6777882626779785,
    2.7870270208169257,
    2.898822059350997,
    3.0131901897720907,
    3.1301480604002863,
    3.2497121605402226,
    3.3718988244681087,
    3.4967242352587946,
    3.624204428461639,
    3.754355295633311,
    3.887192587735158,
    4.022731918402185,
    4.160988767090289,
    4.301978482107941,
    4.445716283538092,
    4.592217266055746,
    4.741496401646282,
    4.893568542229298,
    5.048448422192488,
    5.20615066083972,
    5.3666897647573375,
    5.5300801301023865,
    5.696336044816294,
    5.865471690767354,
    6.037501145825082,
    6.212438385869475,
    6.390297286737924,
    6.571091626112461,
    6.7548350853498045,
    6.941541251256611,
    7.131223617812143,
    7.323895587840543,
    7.5195704746346665,
    7.7182615035334345,
    7.919981813454504,
    8.124744458384042,
    8.332562408825165,
    8.543448553206703,
    8.757415699253682,
    8.974476575321063,
    9.194643831691977,
    9.417930041841839,
    9.644347703669503,
    9.873909240696694,
    10.106627003236781,
    10.342513269534024,
    10.58158024687427,
    10.8238400726681,
    11.069304815507364,
    11.317986476196008,
    11.569896988756009,
    11.825048221409341,
    12.083451977536606,
    12.345119996613247,
    12.610063955123938,
    12.878295467455942,
    13.149826086772048,
    13.42466730586372,
    13.702830557985108,
    13.984327217668513,
    14.269168601521828,
    14.55736596900856,
    14.848930523210871,
    15.143873411576273,
    15.44220572664832,
    15.743938506781891,
    16.04908273684337,
    16.35764934889634,
    16.66964922287304,
    16.985093187232053,
    17.30399201960269,
    17.62635644741625,
    17.95219714852476,
    18.281524751807332,
    18.614349837764564,
    18.95068293910138,
    19.290534541298456,
    19.633915083172692,
    19.98083495742689,
    20.331304511189067,
    20.685334046541502,
    21.042933821039977,
    21.404114048223256,
    21.76888489811322,
    22.137256497705877,
    22.50923893145328,
    22.884842241736916,
    23.264076429332462,
    23.6469514538663,
    24.033477234264016,
    24.42366364919083,
    24.817520537484558,
    25.21505769858089,
    25.61628489293138,
    26.021211842414342,
    26.429848230738664,
    26.842203703840827,
    27.258287870275353,
    27.678110301598522,
    28.10168053274597,
    28.529008062403893,
    28.96010235337422,
    29.39497283293396,
    29.83362889318845,
    30.276079891419332,
    30.722335150426627,
    31.172403958865512,
    31.62629557157785,
    32.08401920991837,
    32.54558406207592,
    33.010999283389665,
    33.4802739966603,
    33.953417292456834,
    34.430438229418264,
    34.911345834551085,
    35.39614910352207,
    35.88485700094671,
    36.37747846067349,
    36.87402238606382,
    37.37449765026789,
    37.87891309649659,
    38.38727753828926,
    38.89959975977785,
    39.41588851594697,
    39.93615253289054,
    40.460400508064545,
    40.98864111053629,
    41.520882981230194,
    42.05713473317016,
    42.597404951718396,
    43.141702194811224,
    43.6900349931913,
    44.24241185063697,
    44.798841244188324,
    45.35933162437017,
    45.92389141541209,
    46.49252901546552,
    47.065252796817916,
    47.64207110610409,
    48.22299226451468,
    48.808024568002054,
    49.3971762874833,
    49.9904556690408,
    50.587870934119984,
    51.189430279724725,
    51.79514187861014,
    52.40501387947288,
    53.0190544071392,
    53.637271562750364,
    54.259673423945976,
    54.88626804504493,
    55.517063457223934,
    56.15206766869424,
    56.79128866487574,
    57.43473440856916,
    58.08241284012621,
    58.734331877617365,
    59.39049941699807,
    60.05092333227251,
    60.715611475655585,
    61.38457167773311,
    62.057811747619894,
    62.7353394731159,
    63.417162620860914,
    64.10328893648692,
    64.79372614476921,
    65.48848194977529,
    66.18756403501224,
    66.89098006357258,
    67.59873767827808,
    68.31084450182222,
    69.02730813691093,
    69.74813616640164,
    70.47333615344107,
    71.20291564160104,
    71.93688215501312,
    72.67524319850172,
    73.41800625771542,
    74.16517879925733,
    74.9167682708136,
    75.67278210128072,
    76.43322770089146,
    77.1981124613393,
    77.96744375590167,
    78.74122893956174,
    79.51947534912904,
    80.30219030335869,
    81.08938110306934,
    81.88105503125999,
    82.67721935322541,
    83.4778813166706,
    84.28304815182372,
    85.09272707154808,
    85.90692527145302,
    86.72564993000343,
    87.54890820862819,
    88.3767072518277,
    89.2090541872801,
    90.04595612594655,
    90.88742016217518,
    91.73345337380438,
    92.58406282226491,
    93.43925555268066,
    94.29903859396902,
    95.16341895893969,
    96.03240364439274,
    96.9059996312159,
    97.78421388448044,
    98.6670533535366,
    99.55452497210776,
  ];

  /// Sanitizes a small enough angle in radians.
  ///
  /// [angle] An angle in radians; must not deviate too much from 0.
  /// Returns A coterminal angle between 0 and 2pi.
  static double _sanitizeRadians(double angle) {
    return (angle + pi * 8) % (pi * 2);
  }

  /// Delinearizes an RGB component, returning a floating-point
  /// number.
  ///
  /// 0.0 <= [rgbComponent] <= 100.0 represents linear R/G/B channel.
  /// 0.0 <= output <= 255.0, color channel converted to regular RGB
  /// space.
  static double _trueDelinearized(double rgbComponent) {
    final normalized = rgbComponent / 100.0;
    var delinearized = 0.0;
    if (normalized <= 0.0031308) {
      delinearized = normalized * 12.92;
    } else {
      delinearized = 1.055 * pow(normalized, 1.0 / 2.4).toDouble() - 0.055;
    }
    return delinearized * 255.0;
  }

  static double _chromaticAdaptation(double component) {
    final af = pow(component.abs(), 0.42).toDouble();
    return MathUtils.signum(component) * 400.0 * af / (af + 27.13);
  }

  /// Returns the hue of [linrgb], a linear RGB color, in CAM16, in
  /// radians.
  static double _hueOf(List<double> linrgb) {
    final scaledDiscount = MathUtils.matrixMultiply(
      linrgb,
      _scaledDiscountFromLinrgb,
    );
    final rA = _chromaticAdaptation(scaledDiscount[0]);
    final gA = _chromaticAdaptation(scaledDiscount[1]);
    final bA = _chromaticAdaptation(scaledDiscount[2]);
    // redness-greenness
    final a = (11.0 * rA + -12.0 * gA + bA) / 11.0;
    // yellowness-blueness
    final b = (rA + gA - 2.0 * bA) / 9.0;
    return atan2(b, a);
  }

  static bool _areInCyclicOrder(double a, double b, double c) {
    final deltaAB = _sanitizeRadians(b - a);
    final deltaAC = _sanitizeRadians(c - a);
    return deltaAB < deltaAC;
  }

  /// Solves the lerp equation.
  ///
  /// Returns a number t such that lerp([source], [target], t) =
  /// [mid].
  static double _intercept(double source, double mid, double target) {
    return (mid - source) / (target - source);
  }

  static List<double> _lerpPoint(
    List<double> source,
    double t,
    List<double> target,
  ) {
    return [
      source[0] + (target[0] - source[0]) * t,
      source[1] + (target[1] - source[1]) * t,
      source[2] + (target[2] - source[2]) * t,
    ];
  }

  /// Intersects a segment with a plane.
  ///
  /// Returns the intersection point of:
  /// - the segment with [source] and [target] as its endpoints, and
  /// - the plane
  /// ... R = [coordinate] if [axis] == 0
  /// ... G = [coordinate] if [axis] == 1
  /// ... B = [coordinate] if [axis] == 2
  static List<double> _setCoordinate(
    List<double> source,
    double coordinate,
    List<double> target,
    int axis,
  ) {
    final t = _intercept(source[axis], coordinate, target[axis]);
    return _lerpPoint(source, t, target);
  }

  static bool _isBounded(double x) {
    return 0.0 <= x && x <= 100.0;
  }

  /// Returns the nth possible vertex of the polygonal intersection.
  ///
  /// Given a plane Y = [y] and an zero-based index [n] such that 0
  /// <= [n] <= 11, returns the nth possible vertex of the polygonal
  /// intersection of the plane and the RGB cube, in linear RGB
  /// coordinates, if it exists.
  /// If this possible vertex lies outside of the cube, [-1.0, -1.0,
  /// -1.0] is returned.
  static List<double> _nthVertex(double y, int n) {
    final kR = _yFromLinrgb[0];
    final kG = _yFromLinrgb[1];
    final kB = _yFromLinrgb[2];
    final coordA = n % 4 <= 1 ? 0.0 : 100.0;
    final coordB = n.isEven ? 0.0 : 100.0;
    if (n < 4) {
      final g = coordA;
      final b = coordB;
      final r = (y - g * kG - b * kB) / kR;
      if (_isBounded(r)) {
        return [r, g, b];
      } else {
        return [-1.0, -1.0, -1.0];
      }
    } else if (n < 8) {
      final b = coordA;
      final r = coordB;
      final g = (y - r * kR - b * kB) / kG;
      if (_isBounded(g)) {
        return [r, g, b];
      } else {
        return [-1.0, -1.0, -1.0];
      }
    } else {
      final r = coordA;
      final g = coordB;
      final b = (y - r * kR - g * kG) / kB;
      if (_isBounded(b)) {
        return [r, g, b];
      } else {
        return [-1.0, -1.0, -1.0];
      }
    }
  }

  /// Finds the segment containing the desired color.
  ///
  /// Given a plane Y = [y] and a desired [targetHue], returns the
  /// segment containing the desired color, represented as an array of
  /// its two endpoints.
  static List<List<double>> _bisectToSegment(double y, double targetHue) {
    var left = [-1.0, -1.0, -1.0];
    var right = left;
    var leftHue = 0.0;
    var rightHue = 0.0;
    var initialized = false;
    var uncut = true;
    for (var n = 0; n < 12; n++) {
      final mid = _nthVertex(y, n);
      if (mid[0] < 0) {
        continue;
      }
      final midHue = _hueOf(mid);
      if (!initialized) {
        left = mid;
        right = mid;
        leftHue = midHue;
        rightHue = midHue;
        initialized = true;
        continue;
      }
      if (uncut || _areInCyclicOrder(leftHue, midHue, rightHue)) {
        uncut = false;
        if (_areInCyclicOrder(leftHue, targetHue, midHue)) {
          right = mid;
          rightHue = midHue;
        } else {
          left = mid;
          leftHue = midHue;
        }
      }
    }
    return [left, right];
  }

  static List<double> _midpoint(List<double> a, List<double> b) {
    return [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2, (a[2] + b[2]) / 2];
  }

  static int _criticalPlaneBelow(double x) {
    return (x - 0.5).floor();
  }

  static int _criticalPlaneAbove(double x) {
    return (x - 0.5).ceil();
  }

  /// Finds a color with the given Y and hue on the boundary of the
  /// cube.
  ///
  /// Returns the color with the desired Y value [y] and hue
  /// [targetHue], in linear RGB coordinates.
  static List<double> _bisectToLimit(double y, double targetHue) {
    final segment = _bisectToSegment(y, targetHue);
    var left = segment[0];
    var leftHue = _hueOf(left);
    var right = segment[1];
    for (var axis = 0; axis < 3; axis++) {
      if (left[axis] != right[axis]) {
        var lPlane = -1;
        var rPlane = 255;
        if (left[axis] < right[axis]) {
          lPlane = _criticalPlaneBelow(_trueDelinearized(left[axis]));
          rPlane = _criticalPlaneAbove(_trueDelinearized(right[axis]));
        } else {
          lPlane = _criticalPlaneAbove(_trueDelinearized(left[axis]));
          rPlane = _criticalPlaneBelow(_trueDelinearized(right[axis]));
        }
        for (var i = 0; i < 8; i++) {
          if ((rPlane - lPlane).abs() <= 1) {
            break;
          } else {
            final mPlane = ((lPlane + rPlane) / 2.0).floor();
            final midPlaneCoordinate = _criticalPlanes[mPlane];
            final mid = _setCoordinate(left, midPlaneCoordinate, right, axis);
            final midHue = _hueOf(mid);
            if (_areInCyclicOrder(leftHue, targetHue, midHue)) {
              right = mid;
              rPlane = mPlane;
            } else {
              left = mid;
              leftHue = midHue;
              lPlane = mPlane;
            }
          }
        }
      }
    }
    return _midpoint(left, right);
  }

  static double _inverseChromaticAdaptation(double adapted) {
    final adaptedAbs = adapted.abs();
    final base = max(0, 27.13 * adaptedAbs / (400.0 - adaptedAbs));
    return MathUtils.signum(adapted) * pow(base, 1.0 / 0.42).toDouble();
  }

  /// Finds a color with the given hue, chroma, and Y.
  ///
  /// Returns a color with the desired [hueRadians], [chroma], and
  /// [y] as a hexadecimal integer, if found; and returns 0 otherwise.
  static int _findResultByJ(double hueRadians, double chroma, double y) {
    // Initial estimate of j.
    var j = sqrt(y) * 11.0;
    // ===========================================================
    // Operations inlined from Cam16 to avoid repeated calculation
    // ===========================================================
    final viewingConditions = ViewingConditions.standard;
    final tInnerCoeff =
        1 /
        pow(
          1.64 -
              pow(0.29, viewingConditions.backgroundYTowhitePointY).toDouble(),
          0.73,
        ).toDouble();
    final eHue = 0.25 * (cos(hueRadians + 2.0) + 3.8);
    final p1 =
        eHue * (50000.0 / 13.0) * viewingConditions.nC * viewingConditions.ncb;
    final hSin = sin(hueRadians);
    final hCos = cos(hueRadians);
    for (var iterationRound = 0; iterationRound < 5; iterationRound++) {
      // ===========================================================
      // Operations inlined from Cam16 to avoid repeated calculation
      // ===========================================================
      final jNormalized = j / 100.0;
      final alpha = chroma == 0.0 || j == 0.0
          ? 0.0
          : chroma / sqrt(jNormalized);
      final t = pow(alpha * tInnerCoeff, 1.0 / 0.9).toDouble();
      final ac =
          viewingConditions.aw *
          pow(
            jNormalized,
            1.0 / viewingConditions.c / viewingConditions.z,
          ).toDouble();
      final p2 = ac / viewingConditions.nbb;
      final gamma =
          23.0 *
          (p2 + 0.305) *
          t /
          (23.0 * p1 + 11 * t * hCos + 108.0 * t * hSin);
      final a = gamma * hCos;
      final b = gamma * hSin;
      final rA = (460.0 * p2 + 451.0 * a + 288.0 * b) / 1403.0;
      final gA = (460.0 * p2 - 891.0 * a - 261.0 * b) / 1403.0;
      final bA = (460.0 * p2 - 220.0 * a - 6300.0 * b) / 1403.0;
      final rCScaled = _inverseChromaticAdaptation(rA);
      final gCScaled = _inverseChromaticAdaptation(gA);
      final bCScaled = _inverseChromaticAdaptation(bA);
      final linrgb = MathUtils.matrixMultiply([
        rCScaled,
        gCScaled,
        bCScaled,
      ], _linrgbFromScaledDiscount);
      // ===========================================================
      // Operations inlined from Cam16 to avoid repeated calculation
      // ===========================================================
      if (linrgb[0] < 0 || linrgb[1] < 0 || linrgb[2] < 0) {
        return 0;
      }
      final kR = _yFromLinrgb[0];
      final kG = _yFromLinrgb[1];
      final kB = _yFromLinrgb[2];
      final fnj = kR * linrgb[0] + kG * linrgb[1] + kB * linrgb[2];
      if (fnj <= 0) {
        return 0;
      }
      if (iterationRound == 4 || (fnj - y).abs() < 0.002) {
        if (linrgb[0] > 100.01 || linrgb[1] > 100.01 || linrgb[2] > 100.01) {
          return 0;
        }
        return ColorUtils.argbFromLinrgb(linrgb);
      }
      // Iterates with Newton method,
      // Using 2 * fn(j) / j as the approximation of fn'(j)
      j = j - (fnj - y) * j / (2 * fnj);
    }
    return 0;
  }

  /// Finds an sRGB color with the given hue, chroma, and L*, if
  /// possible.
  ///
  /// Returns a hexadecimal representing a sRGB color with its hue,
  /// chroma, and L* sufficiently close to [hueDegrees], [chroma], and
  /// [lstar], respectively. If it is impossible to satisfy all three
  /// constraints, the hue and L* will be sufficiently close, and the
  /// chroma will be maximized.
  static int solveToInt(double hueDegrees, double chroma, double lstar) {
    if (chroma < 0.0001 || lstar < 0.0001 || lstar > 99.9999) {
      return ColorUtils.argbFromLstar(lstar);
    }
    hueDegrees = MathUtils.sanitizeDegreesDouble(hueDegrees);
    final hueRadians = hueDegrees / 180 * pi;
    final y = ColorUtils.yFromLstar(lstar);
    final exactAnswer = _findResultByJ(hueRadians, chroma, y);
    if (exactAnswer != 0) {
      return exactAnswer;
    }
    final linrgb = _bisectToLimit(y, hueRadians);
    return ColorUtils.argbFromLinrgb(linrgb);
  }

  /// Finds a CAM16 object with the given hue, chroma, and L*, if
  /// possible.
  ///
  /// Returns a CAM16 object representing a sRGB color with its hue,
  /// chroma, and L* sufficiently close to [hueDegrees], [chroma], and
  /// [lstar], respectively. If it is impossible to satisfy all three
  /// constraints, the hue and L* will be sufficiently close, and the
  /// chroma will be maximized.
  static Cam16 solveToCam(double hueDegrees, double chroma, double lstar) {
    return Cam16.fromInt(solveToInt(hueDegrees, chroma, lstar));
  }
}

// ---- hct/hct.dart ----

/// HCT, hue, chroma, and tone. A color system that provides a perceptually
/// accurate color measurement system that can also accurately render what
/// colors will appear as in different lighting environments.
class Hct {
  late double _hue;
  late double _chroma;
  late double _tone;
  late int _argb;

  /// 0 <= [hue] < 360; invalid values are corrected.
  /// 0 <= [chroma] <= ?; Informally, colorfulness. The color returned may be
  ///    lower than the requested chroma. Chroma has a different maximum for any
  ///    given hue and tone.
  /// 0 <= [tone] <= 100; informally, lightness. Invalid values are corrected.
  static Hct from(double hue, double chroma, double tone) {
    final argb = HctSolver.solveToInt(hue, chroma, tone);
    return Hct._(argb);
  }

  @override
  bool operator ==(Object other) {
    if (other is! Hct) {
      return false;
    }
    return other._argb == _argb;
  }

  @override
  int get hashCode => _argb.hashCode;

  @override
  String toString() {
    return 'H${hue.round().toString()} C${chroma.round()} T${tone.round().toString()}';
  }

  /// HCT representation of [argb].
  static Hct fromInt(int argb) {
    return Hct._(argb);
  }

  int toInt() {
    return _argb;
  }

  /// A number, in degrees, representing ex. red, orange, yellow, etc.
  /// Ranges from 0 <= [hue] < 360
  double get hue {
    return _hue;
  }

  /// 0 <= [newHue] < 360; invalid values are corrected.
  /// After setting hue, the color is mapped from HCT to the more
  /// limited sRGB gamut for display. This will change its ARGB/integer
  /// representation. If the HCT color is outside of the sRGB gamut, chroma
  /// will decrease until it is inside the gamut.
  set hue(double newHue) {
    _argb = HctSolver.solveToInt(newHue, chroma, tone);
    final cam16 = Cam16.fromInt(_argb);
    _hue = cam16.hue;
    _chroma = cam16.chroma;
    _tone = ColorUtils.lstarFromArgb(_argb);
  }

  double get chroma {
    return _chroma;
  }

  /// 0 <= [newChroma] <= ?
  /// After setting chroma, the color is mapped from HCT to the more
  /// limited sRGB gamut for display. This will change its ARGB/integer
  /// representation. If the HCT color is outside of the sRGB gamut, chroma
  /// will decrease until it is inside the gamut.
  set chroma(double newChroma) {
    _argb = HctSolver.solveToInt(hue, newChroma, tone);
    final cam16 = Cam16.fromInt(_argb);
    _hue = cam16.hue;
    _chroma = cam16.chroma;
    _tone = ColorUtils.lstarFromArgb(_argb);
  }

  /// Lightness. Ranges from 0 to 100.
  double get tone {
    return _tone;
  }

  /// 0 <= [newTone] <= 100; invalid values are corrected.
  /// After setting tone, the color is mapped from HCT to the more
  /// limited sRGB gamut for display. This will change its ARGB/integer
  /// representation. If the HCT color is outside of the sRGB gamut, chroma
  /// will decrease until it is inside the gamut.
  set tone(double newTone) {
    _argb = HctSolver.solveToInt(hue, chroma, newTone);
    final cam16 = Cam16.fromInt(_argb);
    _hue = cam16.hue;
    _chroma = cam16.chroma;
    _tone = ColorUtils.lstarFromArgb(_argb);
  }

  Hct._(int argb) {
    _argb = argb;
    final cam16 = Cam16.fromInt(argb);
    _hue = cam16.hue;
    _chroma = cam16.chroma;
    _tone = ColorUtils.lstarFromArgb(_argb);
  }

  /// Translate a color into different [ViewingConditions].
  ///
  /// Colors change appearance. They look different with lights on versus off,
  /// the same color, as in hex code, on white looks different when on black.
  /// This is called color relativity, most famously explicated by Josef Albers
  /// in Interaction of Color.
  ///
  /// In color science, color appearance models can account for this and
  /// calculate the appearance of a color in different settings. HCT is based on
  /// CAM16, a color appearance model, and uses it to make these calculations.
  ///
  /// See [ViewingConditions.make] for parameters affecting color appearance.
  Hct inViewingConditions(ViewingConditions vc) {
    // 1. Use CAM16 to find XYZ coordinates of color in specified VC.
    final cam16 = Cam16.fromInt(toInt());
    final viewedInVc = cam16.xyzInViewingConditions(vc);

    // 2. Create CAM16 of those XYZ coordinates in default VC.
    final recastInVc = Cam16.fromXyzInViewingConditions(
      viewedInVc[0],
      viewedInVc[1],
      viewedInVc[2],
      ViewingConditions.make(),
    );

    // 3. Create HCT from:
    // - CAM16 using default VC with XYZ coordinates in specified VC.
    // - L* converted from Y in XYZ coordinates in specified VC.
    final recastHct = Hct.from(
      recastInVc.hue,
      recastInVc.chroma,
      ColorUtils.lstarFromY(viewedInVc[1]),
    );
    return recastHct;
  }
}

// ---- contrast/contrast.dart ----

/// Utility methods for calculating contrast given two colors, or calculating a
/// color given one color and a contrast ratio.
///
/// Contrast ratio is calculated using XYZ's Y. When linearized to match human
/// perception, Y becomes HCT's tone and L*a*b*'s' L*. Informally, this is the
/// lightness of a color.
///
/// Methods refer to tone, T in the the HCT color space.
/// Tone is equivalent to L* in the L*a*b* color space, or L in the LCH color
/// space.
class Contrast {
  /// Returns a contrast ratio, which ranges from 1 to 21.
  /// [toneA] Tone between 0 and 100. Values outside will be clamped.
  /// [toneB] Tone between 0 and 100. Values outside will be clamped.
  static double ratioOfTones(double toneA, double toneB) {
    toneA = MathUtils.clampDouble(0.0, 100.0, toneA);
    toneB = MathUtils.clampDouble(0.0, 100.0, toneB);
    return _ratioOfYs(
      ColorUtils.yFromLstar(toneA),
      ColorUtils.yFromLstar(toneB),
    );
  }

  static double _ratioOfYs(double y1, double y2) {
    final lighter = y1 > y2 ? y1 : y2;
    final darker = (lighter == y2) ? y1 : y2;
    return (lighter + 5.0) / (darker + 5.0);
  }

  /// Returns a tone >= [tone] that ensures [ratio].
  /// Return value is between 0 and 100.
  /// Returns -1 if [ratio] cannot be achieved with [tone].
  ///
  /// [tone] Tone return value must contrast with.
  /// Range is 0 to 100. Invalid values will result in -1 being returned.
  /// [ratio] Contrast ratio of return value and [tone].
  /// Range is 1 to 21, invalid values have undefined behavior.
  static double lighter({required double tone, required double ratio}) {
    if (tone < 0.0 || tone > 100.0) {
      return -1.0;
    }

    final darkY = ColorUtils.yFromLstar(tone);
    final lightY = ratio * (darkY + 5.0) - 5.0;
    final realContrast = _ratioOfYs(lightY, darkY);
    final delta = (realContrast - ratio).abs();
    if (realContrast < ratio && delta > 0.04) {
      return -1;
    }

    // Ensure gamut mapping, which requires a 'range' on tone, will still result
    // the correct ratio by darkening slightly.
    final returnValue = ColorUtils.lstarFromY(lightY) + 0.4;
    if (returnValue < 0 || returnValue > 100) {
      return -1;
    }
    return returnValue;
  }

  /// Returns a tone <= [tone] that ensures [ratio].
  /// Return value is between 0 and 100.
  /// Returns -1 if [ratio] cannot be achieved with [tone].
  ///
  /// [tone] Tone return value must contrast with.
  /// Range is 0 to 100. Invalid values will result in -1 being returned.
  /// [ratio] Contrast ratio of return value and [tone].
  /// Range is 1 to 21, invalid values have undefined behavior.
  static double darker({required double tone, required double ratio}) {
    if (tone < 0.0 || tone > 100.0) {
      return -1.0;
    }

    final lightY = ColorUtils.yFromLstar(tone);
    final darkY = ((lightY + 5.0) / ratio) - 5.0;
    final realContrast = _ratioOfYs(lightY, darkY);

    final delta = (realContrast - ratio).abs();
    if (realContrast < ratio && delta > 0.04) {
      return -1;
    }

    // Ensure gamut mapping, which requires a 'range' on tone, will still result
    // the correct ratio by darkening slightly.
    final returnValue = ColorUtils.lstarFromY(darkY) - 0.4;
    if (returnValue < 0 || returnValue > 100) {
      return -1;
    }
    return returnValue;
  }

  /// Returns a tone >= [tone] that ensures [ratio].
  /// Return value is between 0 and 100.
  /// Returns 100 if [ratio] cannot be achieved with [tone].
  ///
  /// This method is unsafe because the returned value is guaranteed to be in
  /// bounds for tone, i.e. between 0 and 100. However, that value may not reach
  /// the [ratio] with [tone]. For example, there is no color lighter than T100.
  ///
  /// [tone] Tone return value must contrast with.
  /// Range is 0 to 100. Invalid values will result in 100 being returned.
  /// [ratio] Desired contrast ratio of return value and tone parameter.
  /// Range is 1 to 21, invalid values have undefined behavior.
  static double lighterUnsafe({required double tone, required double ratio}) {
    final lighterSafe = lighter(tone: tone, ratio: ratio);
    return (lighterSafe < 0.0) ? 100.0 : lighterSafe;
  }

  /// Returns a tone <= [tone] that ensures [ratio].
  /// Return value is between 0 and 100.
  /// Returns 0 if [ratio] cannot be achieved with [tone].
  ///
  /// This method is unsafe because the returned value is guaranteed to be in
  /// bounds for tone, i.e. between 0 and 100. However, that value may not reach
  /// the [ratio] with [tone]. For example, there is no color darker than T0.
  ///
  /// [tone] Tone return value must contrast with.
  /// Range is 0 to 100. Invalid values will result in 0 being returned.
  /// [ratio] Desired contrast ratio of return value and tone parameter.
  /// Range is 1 to 21, invalid values have undefined behavior.
  static double darkerUnsafe({required double tone, required double ratio}) {
    final darkerSafe = darker(tone: tone, ratio: ratio);
    return (darkerSafe < 0.0) ? 0.0 : darkerSafe;
  }
}
