// The relief a surface casts at a moment: the theme's depth (`NeumorphicThemeData.shapeScheme`), and how much of its
// shadows show while a part rises, sinks or fades. Parts pass it to the painters; no page reads it.
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

import '../theme.dart';

/// How far a surface's light and shadow stand off it and how wide they blur ([depth], 1 as the look was designed), and
/// how much of them shows ([strength], from none to all, as a part rises, sinks or fades).
@immutable
class NeumorphicReliefDepth {
  /// A relief of [depth], [strength] of its shadows showing.
  const NeumorphicReliefDepth({this.depth = 1, this.strength = 1})
    : assert(depth >= 0),
      assert(strength >= 0 && strength <= 1);

  /// Offset and blur multiplier.
  final double depth;

  /// Opacity multiplier; never changes the face or its printed boundary.
  final double strength;

  /// A copy replacing the supplied multipliers.
  NeumorphicReliefDepth copyWith({double? depth, double? strength}) =>
      NeumorphicReliefDepth(
        depth: depth ?? this.depth,
        strength: strength ?? this.strength,
      );

  /// Blends both multipliers.
  static NeumorphicReliefDepth lerp(
    NeumorphicReliefDepth a,
    NeumorphicReliefDepth b,
    double t,
  ) => a == b
      ? a
      : NeumorphicReliefDepth(
          depth: lerpDouble(a.depth, b.depth, t)!,
          strength: lerpDouble(a.strength, b.strength, t)!,
        );

  @override
  bool operator ==(Object other) =>
      other is NeumorphicReliefDepth &&
      other.depth == depth &&
      other.strength == strength;

  @override
  int get hashCode => Object.hash(depth, strength);
}

/// The relief a theme casts: its [NeumorphicThemeData.shapeScheme]'s depth, every shadow showing.
extension NeumorphicThemeRelief on NeumorphicThemeData {
  /// The theme's relief.
  NeumorphicReliefDepth get relief =>
      NeumorphicReliefDepth(depth: shapeScheme.depth ?? 1);
}
