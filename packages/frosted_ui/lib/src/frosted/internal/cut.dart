// A gap cut, never painted (Frosted's law: nothing pretends to be the
// ground). Plumbing of the components.
import 'package:flutter/widgets.dart';

/// Clips its child clear of a hole, so what lies under the child (its glass,
/// the backdrop) shows through the gap. [hole] gives the hole's outline,
/// already grown by the gap, in the child's coordinates for the child's size;
/// [signature] holds whatever the outline depends on besides the size, so
/// the clip is redrawn only when it changes.
///
/// The outline is cut by the even-odd rule (a field round the child and the
/// hole), not `Path.combine`, whose difference the web renderer does not cut
/// in Flutter 3.47. The field reaches [reach] past the child's box, so only
/// the hole is taken: the child's shadow, the touch target a
/// `FrostedHitSlop` spans round it and the node a screen reader outlines
/// all keep their room.
class FrostedCutClipper extends CustomClipper<Path> {
  /// Clips clear of [hole]; [signature] is what the hole depends on.
  const FrostedCutClipper(this.hole, this.signature);

  /// The hole's outline for the child's size.
  final Path Function(Size size) hole;

  /// What [hole] depends on besides the size.
  final Object signature;

  /// How far past the child's box the clip leaves it whole.
  static const double reach = 96;

  @override
  Path getClip(Size size) => Path()
    ..fillType = PathFillType.evenOdd
    ..addRect((Offset.zero & size).inflate(reach))
    ..addPath(hole(size), Offset.zero);

  // What the semantics tree clips its nodes to: by default the child's own
  // box, which would shrink a target's node to its face.
  @override
  Rect getApproximateClipRect(Size size) => (Offset.zero & size).inflate(reach);

  @override
  bool shouldReclip(FrostedCutClipper oldClipper) =>
      oldClipper.signature != signature;
}
