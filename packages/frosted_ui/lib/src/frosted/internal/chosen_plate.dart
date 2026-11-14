import 'package:flutter/widgets.dart';

import '../theme.dart';
import 'css_shadow.dart';
import 'face.dart';

/// How Frosted says "chosen" (the chosen chip, segment, tab, sidebar link):
/// the glass under the choice is thicker and brighter than the glass it
/// stands on, raised off it. By day it is a near-white platter, by night
/// the night glass lit a few steps; its light runs along its top edge, its
/// own glass edge holds it (the lit hairline by day, the night glass's rim
/// by night), and a soft lift stands under it. By day it draws no dark
/// outline: the look raises the glass instead of drawing round it.
/// Plumbing of the components.
class FrostedChosenPlate extends StatelessWidget {
  /// Creates a [FrostedChosenPlate].
  const FrostedChosenPlate({
    required this.radius,
    this.shape,
    this.padding = EdgeInsets.zero,
    this.child,
    this.painted = false,
    super.key,
  });

  /// Paint the plate, blurring nothing: on a solid band (the tab bar on
  /// the media ground), where no glass passes under it.
  final bool painted;

  /// The plate's corners.
  final BorderRadius radius;

  /// The plate's outline when a style cuts it to one.
  final OutlinedBorder? shape;

  /// The room inside the plate round its child.
  final EdgeInsets padding;

  /// What stands on the plate (the chosen link's glyph and word); null for
  /// a plate that slides under its cells.
  final Widget? child;

  /// The plate's fill: by day white at nearly its whole strength, by night
  /// white at a sixth, over the strip's own glass.
  static Color fillOf(FrostedThemeData t) =>
      t.isDark ? const Color(0x29FFFFFF) : t.glass.plane.withValues(alpha: .94);

  /// The light along the plate's top edge: whiter than the plate by day,
  /// a third of white by night.
  static Color lightOf(FrostedThemeData t) =>
      t.isDark ? const Color(0x52FFFFFF) : const Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return FrostedFace(
      material: painted ? FrostedMaterial.paint : FrostedMaterial.pane,
      radius: radius,
      shape: shape,
      color: fillOf(t),
      sheen: lightOf(t),
      // By night the plate keeps the night glass's rim.
      ring: t.isDark ? t.controlEdge : null,
      padding: padding,
      shadows: shadowsOf(t),
      child: child,
    );
  }

  /// What holds the plate off the glass under it: its own faint glass edge,
  /// the raised step's shadow and a soft lift, thicker glass standing a
  /// little further off.
  static List<BoxShadow> shadowsOf(FrostedThemeData t) => [
    frostedShadow(color: t.glass.edge, spread: FrostedStrokes.regular),
    ...t.shadows.raised,
    BoxShadow(
      color: t.isDark ? const Color(0x47000000) : const Color(0x1F2A2464),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -4,
    ),
  ];
}
